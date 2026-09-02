import Foundation
import simd

/// Estado autoritativo da expedicao. Swift puro: nenhum framework de render aqui.
/// Bloco 10: o host roda esta mesma simulacao e envia snapshots.
public final class World {

    // MARK: Estado
    public internal(set) var players: [PlayerID: Player] = [:]
    public internal(set) var cows: [CowID: Cow] = [:]
    public internal(set) var farm: Farm

    /// Bloco 2: um unico medidor global de alerta da fazenda.
    public private(set) var alert: Float = 0
    /// Sobe quando o alerta estoura. Nunca desce durante a noite.
    public private(set) var vigilia: Int = 0
    public internal(set) var stampedeTimer: Float = 0
    public private(set) var elapsed: Float = 0

    public private(set) var leverCountdown: Float?
    public private(set) var isFinished = false
    public private(set) var summary: ExpeditionSummary?
    public private(set) var extractedIDs: [CowID] = []

    public var playerOrder: [PlayerID] = []

    // MARK: Interno
    private var inputs: [PlayerID: PlayerInput] = [:]
    private var pendingActions: [(PlayerID, PlayerAction)] = []
    private var events: [WorldEvent] = []
    private var rng: Rand
    private(set) var silenceElapsed: Float = 0
    private var maxVigiliaSeen = 0
    private var nextCowRaw = 0

    public init(seed: UInt64 = 0xC0FFEE) {
        self.rng = Rand(seed: seed)
        self.farm = Farm.mvp()
        spawnDefaultHerd()
        let p = Player(id: PlayerID(0), position: Vec3(-3, 0, 6))
        players[p.id] = p
        playerOrder = [p.id]
    }

    // MARK: API
    public func setInput(_ input: PlayerInput, for id: PlayerID) { inputs[id] = input }
    public func enqueue(_ action: PlayerAction, for id: PlayerID) { pendingActions.append((id, action)) }
    public func drainEvents() -> [WorldEvent] { defer { events.removeAll(keepingCapacity: true) }; return events }
    public func emit(_ e: WorldEvent) { events.append(e) }

    public func player(_ id: PlayerID) -> Player? { players[id] }
    public func cow(_ id: CowID) -> Cow? { cows[id] }
    public var allCows: [Cow] { Array(cows.values) }
    public var cowsOnField: [Cow] { cows.values.filter { $0.behavior != .extraida } }

    /// Vacas ja a bordo.
    public var cargoCount: Int { extractedIDs.count }
    public var cargoValue: Int { extractedIDs.compactMap { cows[$0]?.value }.reduce(0, +) }

    // MARK: Passo fixo
    public func step(dt: Float) {
        guard !isFinished else { return }
        elapsed += dt

        var noiseRate: Float = 0

        stepActions()
        noiseRate += stepPlayers(dt: dt)
        noiseRate += stepCarried(dt: dt)
        noiseRate += stepHerd(dt: dt)
        stepTrampling(dt: dt)
        stepBeam(dt: dt)
        stepAlert(dt: dt, noiseRate: noiseRate)
        stepLever(dt: dt)
    }

    // MARK: Mutadores internos usados pelos sistemas
    func mutate(_ id: PlayerID, _ body: (inout Player) -> Void) {
        guard var p = players[id] else { return }
        body(&p)
        players[id] = p
    }

    func mutate(_ id: CowID, _ body: (inout Cow) -> Void) {
        guard var c = cows[id] else { return }
        body(&c)
        cows[id] = c
    }

    func input(for id: PlayerID) -> PlayerInput { inputs[id] ?? .idle }
    func takeActions() -> [(PlayerID, PlayerAction)] {
        defer { pendingActions.removeAll(keepingCapacity: true) }
        return pendingActions
    }

    func addAlert(_ amount: Float) {
        alert = min(Balance.alertMax, alert + amount)
    }

    func decayAlert(_ amount: Float) {
        alert = max(0, alert - amount)
    }

    func resetSilence() { silenceElapsed = 0 }
    func advanceSilence(_ dt: Float) { silenceElapsed += dt }

    func random() -> Float { rng.float() }
    func randomAngle() -> Float { rng.angle() }
    func randomPoint(radius: Float, around c: Vec3) -> Vec3 { rng.point(inRadius: radius, around: c) }

    func markExtracted(_ id: CowID) {
        guard !extractedIDs.contains(id) else { return }
        extractedIDs.append(id)
    }

    func raiseVigilia() {
        vigilia = min(Balance.maxVigilia, vigilia + 1)
        maxVigiliaSeen = max(maxVigiliaSeen, vigilia)
        alert = Balance.alertAfterStampede
        stampedeTimer = Balance.stampedeDuration
        emit(.stampede(vigilia: vigilia))
        for c in Array(cows.values) where c.isOnGround && c.behavior != .carregada {
            mutate(c.id) { cow in
                cow.behavior = .panico
                cow.behaviorTimer = Balance.stampedeDuration
                cow.alarm = 1
                cow.fleeFrom = self.farm.shipAnchor
            }
        }
    }

    func finish() {
        guard !isFinished else { return }
        isFinished = true
        let items = extractedIDs.compactMap { id -> (name: String, size: CowSize, value: Int)? in
            guard let c = cows[id] else { return nil }
            return (c.name, c.size, c.value)
        }
        let s = ExpeditionSummary(extracted: items, duration: elapsed, maxVigilia: maxVigiliaSeen)
        summary = s
        emit(.expeditionEnded(s))
    }

    func setLever(_ value: Float?) { leverCountdown = value }

    // MARK: Rebanho inicial
    private func newCowID() -> CowID {
        defer { nextCowRaw += 1 }
        return CowID(nextCowRaw)
    }

    private func spawnDefaultHerd() {
        let names = ["Berenice", "Zuleica", "Aparecida", "Mafalda", "Genoveva",
                     "Otacilia", "Dorotéia", "Wanderleia", "Morango"]
        let plan: [(CowSize, Set<Adornment>, Vec3)] = [
            (.adulta,   [.sino],            Vec3(-8, 0, -25)),
            (.novilha,  [],                 Vec3(-5, 0, -31)),
            (.adulta,   [.brinco],          Vec3(9, 0, -27)),
            (.bezerro,  [],                 Vec3(10.5, 0, -29)),
            (.matrona,  [.sino, .coleira],  Vec3(18, 0, -36)),
            (.novilha,  [.faixa],           Vec3(-20, 0, -34)),
            (.adulta,   [],                 Vec3(-24, 0, -38)),
            (.colossal, [.sino, .faixa],    Vec3(2, 0, -39)),
            (.bezerro,  [],                 Vec3(24, 0, -22))
        ]
        for (i, entry) in plan.enumerated() {
            let id = newCowID()
            var c = Cow(id: id, name: names[i % names.count], size: entry.0,
                        adornments: entry.1, position: entry.2,
                        heading: rng.angle(), isCurio: names[i % names.count] == "Morango")
            c.wanderTarget = entry.2
            // Parte do rebanho comeca pastando: um campo totalmente imovel e morto.
            if i % 3 == 0 {
                c.behavior = .pastando
                c.wanderTarget = rng.point(inRadius: Balance.cowWanderRadius, around: entry.2)
            }
            cows[id] = c
        }
    }
}
