import Foundation
import simd

extension World {

    // MARK: Acoes — um verbo, uma tecla (Bloco 13, sistema de foco unico)
    func stepActions() {
        for (pid, action) in takeActions() {
            guard let p = players[pid] else { continue }
            switch action {
            case .toggleLantern:
                if p.hands == .lantern { mutate(pid) { $0.lanternOn.toggle() } }
            case .pullLever:
                handleLever(pid)
            case .interact:
                guard p.canAct else { continue }
                handleInteract(pid)
            }
        }
    }

    private func handleLever(_ pid: PlayerID) {
        guard let p = players[pid], p.canAct else { return }
        guard planarDistance(p.position, farm.leverPosition) < 2.6 else { return }
        if leverCountdown != nil {
            setLever(nil)
            emit(.leverAborted)
        } else {
            setLever(Balance.leverCountdown)
            emit(.leverPulled)
        }
    }

    private func handleInteract(_ pid: PlayerID) {
        guard let p = players[pid] else { return }

        // Ja tem algo nas maos: soltar.
        switch p.hands {
        case .cow(let cid):
            dropCow(cid, by: pid, slipped: false)
            return
        case .hay(let hid):
            mutate(pid) { $0.hands = .empty }
            if let i = farm.hay.firstIndex(where: { $0.id == hid }) {
                farm.hay[i].carriedBy = nil
                farm.hay[i].position = p.position + p.forward * 1.0
            }
            emit(.hayDropped(hid))
            return
        case .lantern:
            // Solta a lanterna so se nao houver nada melhor por perto.
            if nearestPickup(for: p) == nil {
                mutate(pid) { $0.hands = .empty }
                farm.lanternSpawn = p.position + p.forward * 0.9
                emit(.lanternDropped)
                return
            }
        case .empty:
            break
        }

        guard let target = nearestPickup(for: p) else { return }
        switch target {
        case .gate(let index):
            let open = !farm.fences[index].isOpen
            farm.fences[index].isOpen = open
            addAlert(Balance.alertGateSlammed)
            disturb(at: farm.fences[index].midpoint3, radius: Balance.noiseRadius, amount: 0.5, cap: 0.6)
            emit(.gateToggled(index: index, open: open))
        case .lantern:
            mutate(pid) { $0.hands = .lantern; $0.lanternOn = true }
            emit(.lanternPicked)
        case .hay(let hid):
            dropHandsIfLantern(pid)
            mutate(pid) { $0.hands = .hay(hid) }
            if let i = farm.hay.firstIndex(where: { $0.id == hid }) { farm.hay[i].carriedBy = pid }
            emit(.hayPicked(hid))
        case .cow(let cid):
            guard let c = cows[cid], c.isOnGround, !c.isCarried else { return }
            dropHandsIfLantern(pid)
            mutate(pid) { $0.liftingCow = cid; $0.liftTimer = c.size.liftTime }
        }
    }

    private func dropHandsIfLantern(_ pid: PlayerID) {
        guard let p = players[pid], p.hands == .lantern else { return }
        mutate(pid) { $0.hands = .empty }
        farm.lanternSpawn = p.position + p.forward * 0.8
        emit(.lanternDropped)
    }

    enum Pickup {
        case cow(CowID)
        case lantern
        case hay(Int)
        case gate(Int)
    }

    /// Sistema de foco unico: o que voce esta OLHANDO ganha de o que esta mais perto.
    /// Sem isso, uma vaca largada ao lado da porteira torna a porteira inalcancavel.
    func nearestPickup(for p: Player) -> Pickup? {
        var best: (score: Float, pick: Pickup)?
        let aim = p.aimForward

        func consider(_ point: Vec3, _ radius: Float, _ pick: Pickup) {
            let d = planarDistance(p.position, point) - radius
            guard d < Balance.interactReach else { return }
            let toward = normalizedOrZero((point - p.position).flat)
            let align = simd_length(toward) > 0.001 ? simd_dot(toward, aim) : 1
            guard align > 0 || d < 0.4 else { return }
            let score = max(0, d) - align * 1.2
            if best == nil || score < best!.score { best = (score, pick) }
        }

        for c in Array(cows.values) where c.isOnGround && !c.isCarried {
            consider(c.position, c.size.bodyRadius, .cow(c.id))
        }
        if p.hands != .lantern {
            consider(farm.lanternSpawn, 0, .lantern)
        }
        for h in farm.hay where h.carriedBy == nil {
            consider(h.position, 0.3, .hay(h.id))
        }
        for (i, f) in farm.fences.enumerated() where f.isGate {
            consider(f.midpoint3, 0.6, .gate(i))
        }
        return best?.pick
    }

    /// Solta a vaca. Bloco 2: derrubar custa +8 de alerta e acorda as vizinhas.
    func dropCow(_ cid: CowID, by pid: PlayerID, slipped: Bool) {
        guard let p = players[pid], let c = cows[cid] else { return }
        mutate(pid) { $0.hands = .empty; if slipped { $0.stumbleTimer = 1.3 } }
        // Ao lado, nao na frente: largada bem no meio do caminho ela bloqueia
        // qualquer outra interacao (porteira, alavanca) e trava o jogador.
        let side = Vec3(cos(p.yaw), 0, -sin(p.yaw))
        let landing = p.position + p.forward * 0.5 + side * 0.85
        mutate(cid) { cow in
            cow.carriers.removeAll { $0 == pid }
            if cow.carriers.isEmpty {
                cow.position = Vec3(landing.x, 0, landing.z)
                cow.behavior = .alerta
                cow.behaviorTimer = 1.6
                // Cap abaixo do limiar de panico: derrubar assusta, nao faz fugir.
                cow.alarm = min(max(0.65, cow.alarm), cow.alarm + 0.35)
                cow.velocity = .zero
            }
        }
        addAlert(Balance.alertCowDropped)
        disturb(at: c.position, radius: Balance.noiseRadius, amount: 0.6, cap: 0.6)
        emit(.cowDropped(cid))
        if slipped { emit(.playerSlipped(pid)) }
    }

    func knockDown(_ pid: PlayerID) {
        guard let p = players[pid], !p.isDown else { return }
        if let cid = p.hands.cowID { dropCow(cid, by: pid, slipped: false) }
        mutate(pid) { player in
            player.isDown = true
            player.downTimer = Balance.knockdownDuration
            player.hands = .empty
            player.liftingCow = nil
            player.liftTimer = 0
            player.velocity = .zero
        }
        emit(.playerKnocked(pid))
    }

    /// Acorda e agita as vacas dentro do raio.
    /// `cap` limita ate onde este tipo de barulho consegue levar o alarme: barulho
    /// ambiente (passos) acorda e agita, mas so eventos fortes empurram para o panico.
    func disturb(at point: Vec3, radius: Float, amount: Float, cap: Float = 1) {
        for c in Array(cows.values) where c.isOnGround {
            let d = planarDistance(c.position, point)
            guard d < radius else { continue }
            let falloff = 1 - d / radius
            mutate(c.id) { cow in
                cow.alarm = min(max(cap, cow.alarm), cow.alarm + amount * falloff)
                if cow.behavior == .dormindo && cow.alarm > 0.25 {
                    cow.behavior = .alerta
                    cow.behaviorTimer = 1.5
                }
                if cow.alarm >= 0.95 && cow.behavior != .panico {
                    cow.behavior = .panico
                    cow.behaviorTimer = Balance.cowPanicDuration
                    cow.fleeFrom = point
                    self.emit(.cowPanicked(cow.id))
                }
            }
        }
    }

    // MARK: Movimento
    /// Retorna a taxa de alerta por segundo gerada pelos jogadores neste frame.
    func stepPlayers(dt: Float) -> Float {
        var noise: Float = 0

        for pid in playerOrder {
            guard var p = players[pid] else { continue }
            let cmd = input(for: pid)
            p.aimYaw = cmd.aimYaw
            p.wantsSprint = cmd.sprint
            p.wantsCrouch = cmd.crouch

            if p.isDown {
                p.downTimer -= dt
                p.velocity = .zero
                if p.downTimer <= 0 { p.isDown = false }
                players[pid] = p
                continue
            }
            if p.stumbleTimer > 0 {
                p.stumbleTimer -= dt
                p.velocity *= max(0, 1 - 6 * dt)
                p.position = farm.resolveFences(p.position + p.velocity * dt, radius: Balance.playerRadius)
                players[pid] = p
                continue
            }

            // Erguendo uma vaca: quase parado.
            if let lifting = p.liftingCow {
                p.liftTimer -= dt
                if p.liftTimer <= 0 {
                    if let c = cows[lifting], c.isOnGround, !c.isCarried {
                        p.hands = .cow(lifting)
                        mutate(lifting) { cow in
                            cow.behavior = .carregada
                            cow.carriers = [pid]
                            cow.velocity = .zero
                            cow.struggleTimer = 0.8
                        }
                        emit(.cowLifted(lifting))
                    }
                    p.liftingCow = nil
                    p.liftTimer = 0
                }
            }

            let carriedCow = p.hands.cowID.flatMap { cows[$0] }
            let inMud = farm.isInMud(p.position)

            // Velocidade final
            var speed = Balance.walkSpeed
            var canSprint = p.wantsSprint
            if let c = carriedCow {
                speed *= c.carryFactor
                if !c.size.allowsSprintWhileCarried { canSprint = false }
            } else if p.hands.hayID != nil {
                speed *= 0.7
            }
            if p.wantsCrouch { speed *= Balance.crouchMultiplier; canSprint = false }
            if inMud { speed *= carriedCow != nil ? Balance.mudSpeedMultiplierCarrying : Balance.mudSpeedMultiplier }
            if canSprint { speed *= Balance.sprintMultiplier }
            if p.liftingCow != nil { speed *= 0.15 }

            // Direcao no espaco da camera
            let m = cmd.move
            let sy = sin(p.aimYaw), cy = cos(p.aimYaw)
            let dir = Vec3(m.x * cy + m.y * sy, 0, -m.x * sy + m.y * cy)
            let desired = normalizedOrZero(dir) * speed

            let accel = Balance.acceleration * (inMud ? 0.5 : 1)
            p.velocity.x = approach(p.velocity.x, desired.x, rate: accel, dt: dt)
            p.velocity.z = approach(p.velocity.z, desired.z, rate: accel, dt: dt)

            // Corpo gira atras da camera, mais devagar carregando algo pesado
            let turn = Balance.turnRate * (carriedCow?.size.carryTurnFactor ?? 1)
            p.yaw += clampf(wrapAngle(p.aimYaw - p.yaw), -turn * dt, turn * dt)

            p.position = farm.resolveFences(p.position + p.velocity * dt, radius: Balance.playerRadius)

            // Lama + peso = escorregao
            if inMud, let c = carriedCow {
                let chance = Balance.mudSlipChancePerSecond * c.size.struggle * dt
                if random() < chance {
                    players[pid] = p
                    dropCow(c.id, by: pid, slipped: true)
                    continue
                }
            }

            // Barulho: correr perto do rebanho. Vaca dormindo tambem se assusta —
            // contar so as ja acordadas criava um impasse: elas nunca acordavam.
            if canSprint && simd_length(p.velocity) > 1 && !p.wantsCrouch {
                var heard: Float = 0
                for cow in Array(cows.values) where cow.isOnGround {
                    guard planarDistance(cow.position, p.position) < Balance.noiseRadius else { continue }
                    heard += cow.isAwake ? 1 : 0.5
                }
                noise += min(4, heard * Balance.alertSprintNearCow)
                disturb(at: p.position, radius: Balance.noiseRadius * 0.75, amount: 0.8 * dt, cap: 0.65)
            }

            // Barulho: lanterna apontada para vaca
            if p.hasLanternLit {
                var lit: Float = 0
                let fwd = p.aimForward
                for cow in Array(cows.values) where cow.isOnGround {
                    let delta = cow.position - p.position
                    let d = simd_length(delta.flat)
                    guard d < Balance.lanternRange, d > 0.1 else { continue }
                    let cosang = simd_dot(normalizedOrZero(delta.flat), fwd)
                    if cosang > cos(Balance.lanternHalfAngle) {
                        lit += 1
                        mutate(cow.id) { $0.alarm = min(max(0.8, $0.alarm), $0.alarm + 0.25 * dt) }
                    }
                }
                if lit > 0 { noise += min(8, Balance.alertLanternOnCow + (lit - 1)) }
            }

            players[pid] = p
        }
        return noise
    }
}

extension FenceSegment {
    var midpoint3: Vec3 { Vec3(midpoint.x, 0, midpoint.y) }
}
