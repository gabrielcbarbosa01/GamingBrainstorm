//
//  GameLoop.swift
//  TurnoMac
//
//  Regras por frame: movimento, modo ferramenta, interações, a ronda da
//  gerente, os sustos de cada noite e o fim do turno.
//

import Foundation
import RealityKit
import simd
import CoreGraphics
import AppKit

@MainActor
final class GameLoop {
    let state: GameState
    let world: GameWorld
    let input: InputState
    let audio: ProceduralAudio
    var server: ControllerServer?
    var coop: CoopSession?

    // Câmera
    private var yaw: Float = 0
    private var pitch: Float = 0
    private var phoneYawRef: Float = 0
    private var phoneRefValid = false
    private var lastPhoneYaw: Float = 0
    private var edgeTurnBase: Float = 0

    // Ferramenta
    private var activeSurface: CleaningSurface?
    private var savedPose: (SIMD3<Float>, Float, Float)?
    private var toolLerp: Float = 0
    private var toolUV = SIMD2<Float>(0.5, 0.5)
    private var toolPhoneRef: (Float, Float)?
    private var scrubLevel: Float = 0
    private var hintEntity: ModelEntity?

    // Interação (escuta, exame, conversa)
    private var activeInteraction: InteractionSpec?
    private var interactionLine = 0
    private var interactionTimer: Float = 0
    private var interactionElapsed: Float = 0
    /// Quanto de cada conversa já foi ouvido, para poder retomar depois de parar.
    private var interactionProgress: [String: Int] = [:]

    // Gerente
    private var managerT: Float = 0
    private var managerDir: Float = -1
    private var managerPause: Float = 0
    private var managerRng = SplitMix(seed: 99)
    private var managerArea: AreaID = .corredor7

    // Sustos e fantasma
    private var scareFired = false
    private var scareTimer: Float = -1
    private var flickerTimer: Float = -1
    private var ambientGhostTimer: Float = 40
    private var heartbeat = false

    private var nearElevator = false

    // Tempo e rede
    private var elapsed: Double = 0
    private var lastSecond = 0
    private var stateSendAccum: Float = 0
    private var poseSendAccum: Float = 0
    private var lastSentState: ControllerState?
    private var fadeTarget: Float = 0

    init(state: GameState, world: GameWorld, input: InputState, audio: ProceduralAudio) {
        self.state = state
        self.world = world
        self.input = input
        self.audio = audio
    }

    // MARK: - Fluxo da campanha

    func openHub() {
        state.progress = ProgressStore.load()
        state.role = state.progress.role
        state.night = Campaign.night(min(state.progress.night, Campaign.count))
        state.phase = .hub
        audio.setAmbient(false)
        pushControllerState(force: true)
    }

    func startNight() {
        let spec = Campaign.night(min(state.progress.night, Campaign.count))
        state.beginNight(spec, role: state.role)
        do { try world.buildNight(spec, progress: state.progress) }
        catch { print("buildNight: \(error)") }

        state.phase = .playing
        let firstArea = spec.areas.first ?? .corredor7
        world.player.position = GameWorld.spawn(firstArea)
        state.currentArea = firstArea
        yaw = 0; pitch = 0
        phoneRefValid = false
        applyCamera()
        elapsed = 0; lastSecond = 0
        managerT = 0.5; managerDir = -1; managerPause = 1.5
        managerArea = firstArea
        activeSurface = nil; activeInteraction = nil
        scareFired = false; scareTimer = -1; flickerTimer = -1
        ambientGhostTimer = Float.random(in: 35...70)
        world.ghost.isEnabled = false
        state.fade = 0
        fadeTarget = 0
        placeNPC(for: spec)
        state.fire("n\(spec.number)-intro")
        audio.setAmbient(true)
        coop?.send(.startNight(spec.number))
        pushControllerState(force: true)
    }

    private func placeNPC(for spec: NightSpec) {
        if let inter = spec.interactions.first(where: { $0.kind == .conversa }) {
            world.npc.isEnabled = true
            world.npc.position = inter.position + GameWorld.offset(inter.area) - SIMD3(0, 1.2, 0)
            world.npc.orientation = simd_quatf(angle: .pi, axis: [0, 1, 0])
        } else {
            world.npc.isEnabled = false
        }
    }

    private func endShift(caught: Bool) {
        exitTool()
        activeInteraction = nil
        state.inToolMode = false
        state.currentTool = .none
        audio.setAmbient(false)
        world.ghost.isEnabled = false
        world.manager.isEnabled = false
        world.npc.isEnabled = false

        var p = state.progress
        if caught {
            p.timesCaught += 1
            p.trust = max(0, p.trust - 0.2)
            state.reportCaught = true
            state.reportStars = 0
            state.fire("descoberto")
            state.onHaptic?(.alarm)
        } else {
            let stars = state.computeStars()
            state.reportStars = stars
            p.stars += stars
            p.starsByNight["\(state.night.number)"] = stars
            p.trust = min(1, p.trust + 0.06 * Float(state.tasksDone))
            p.night = min(Campaign.count + 1, state.night.number + 1)
        }
        state.progress = p
        ProgressStore.save(p)
        state.phase = .report
        pushControllerState(force: true)
    }

    /// Chamado pela UI ao fechar o relatório.
    func afterReport() {
        if state.progress.night > Campaign.count {
            state.phase = .deduction
        } else {
            openHub()
        }
        pushControllerState(force: true)
    }

    // MARK: - Frame

    func update(dt dtRaw: Float) {
        let dt = min(dtRaw, 0.05)
        let now = Date().timeIntervalSince1970
        state.tick(now: now)
        state.fade += (fadeTarget - state.fade) * min(1, dt * 6)

        guard state.phase == .playing else {
            world.flushSurfaces()
            return
        }

        elapsed += Double(dt)
        let sec = Int(elapsed)
        if sec != lastSecond {
            lastSecond = sec
            state.shiftSecondsLeft = max(0, state.night.seconds - sec)
            if state.shiftSecondsLeft == 0 { endShift(caught: false); return }
            if state.shiftSecondsLeft == 60 {
                state.pushMessage(from: Campaign.detective, text: "Um minuto. Volte para o elevador.")
            }
        }

        if input.consumeRecal() {
            phoneRefValid = false
            toolPhoneRef = nil
            state.showToast("Controle recalibrado")
        }

        if let s = activeSurface {
            updateTool(s, dt: dt)
        } else if activeInteraction != nil {
            updateInteraction(dt: dt)
        } else {
            updateFreeMovement(dt: dt)
        }

        state.currentArea = world.area(at: world.player.position)
        updateManager(dt: dt)
        updateScares(dt: dt)
        updateNetwork(dt: dt)

        audio.scrub = scrubLevel
        audio.heartbeat = heartbeat
        scrubLevel = max(0, scrubLevel - dt * 4)
        world.flushSurfaces()
    }

    // MARK: - Movimento

    private func phoneYawUnwrapped() -> Float {
        var y = input.phoneYaw
        while y - lastPhoneYaw > .pi { y -= 2 * .pi }
        while y - lastPhoneYaw < -.pi { y += 2 * .pi }
        lastPhoneYaw = y
        return y
    }

    private func updateFreeMovement(dt: Float) {
        if input.source == .phone && input.hasPhoneAttitude {
            let py = phoneYawUnwrapped()
            if !phoneRefValid { phoneYawRef = py; phoneRefValid = true; edgeTurnBase = yaw }
            let rel = py - phoneYawRef
            if abs(rel) > 0.75 { edgeTurnBase -= (rel > 0 ? 1 : -1) * 1.6 * dt }
            yaw = edgeTurnBase - rel * 1.7
            pitch = max(-1.1, min(1.1, input.phonePitch * 1.2))
        } else {
            yaw -= input.keyYaw * 1.8 * dt
            pitch = max(-1.1, min(1.1, pitch + input.keyPitch * 1.2 * dt))
        }

        let speed: Float = 2.1
        let forward = SIMD3<Float>(-sin(yaw), 0, -cos(yaw))
        let rightV = SIMD3<Float>(cos(yaw), 0, -sin(yaw))
        var move = forward * input.moveY + rightV * input.moveX
        if simd_length(move) > 1 { move = simd_normalize(move) }
        var p = world.player.position
        let nx = p.x + move.x * speed * dt
        let nz = p.z + move.z * speed * dt
        if world.canWalk(x: nx, z: p.z) { p.x = nx }
        if world.canWalk(x: p.x, z: nz) { p.z = nz }
        world.player.position = p
        applyCamera()

        let (target, promptText) = findInteraction()
        state.prompt = promptText
        if case .surface(let s)? = target?.kind { state.currentTool = s.tool } else { state.currentTool = .none }

        if input.consumeAct(), let t = target {
            switch t.kind {
            case .surface(let s): enterTool(s)
            case .interaction(let spec): startInteraction(spec)
            case .travel(let area): travel(to: area)
            case .finish: endShift(caught: false)
            }
        }
        if input.consumeBack() && nearElevator { endShift(caught: false) }
    }

    private struct Interaction {
        enum Kind {
            case surface(CleaningSurface)
            case interaction(InteractionSpec)
            case travel(AreaID)
            case finish
        }
        let kind: Kind
    }

    private func findInteraction() -> (Interaction?, String) {
        let eye = world.player.position + SIMD3(0, GameWorld.eyeHeight, 0)
        let forward = SIMD3<Float>(-sin(yaw) * cos(pitch), sin(pitch), -cos(yaw) * cos(pitch))
        func facing(_ target: SIMD3<Float>, maxDist: Float, minDot: Float) -> Float? {
            let d = target - eye
            let dist = simd_length(d)
            guard dist < maxDist, dist > 0.001 else { return nil }
            return simd_dot(simd_normalize(d), forward) > minDot ? dist : nil
        }

        var best: (Interaction, String, Float)? = nil
        func offer(_ kind: Interaction.Kind, _ text: String, _ dist: Float) {
            if best == nil || dist < best!.2 { best = (Interaction(kind: kind), text, dist) }
        }

        for s in world.surfaces {
            let anchor = s.spec.isHorizontal ? s.origin + SIMD3(0, 0.35, 0) : s.origin
            let reach = 2.5 + max(s.width, s.height) * 0.35
            if let d = facing(anchor, maxDist: reach, minDot: 0.4) {
                let eff = state.role.efficiency(for: s.tool)
                let speedNote = eff >= 1 ? "" : "  ·  não é a sua ferramenta"
                let text = s.isDone
                    ? "\(s.promptVerb) (feito)  ·  AÇÃO para retocar"
                    : "\(s.promptVerb)  ·  AÇÃO  ·  \(s.tool.title)\(speedNote)"
                offer(.surface(s), text, d)
            }
        }
        for spec in state.night.interactions {
            guard let marker = world.interactionMarkers[spec.id] else { continue }
            if let d = facing(marker.position, maxDist: 2.2, minDot: 0.45) {
                let done = spec.evidenceID.map { state.hasEvidence($0) } ?? false
                let text = done ? "\(spec.prompt) (já anotado)" : "\(spec.prompt)  ·  AÇÃO"
                offer(.interaction(spec), text, d)
            }
        }

        // elevador de serviço: AÇÃO viaja para a próxima área, SAIR encerra o turno
        nearElevator = false
        let regions = orderedRegions()
        let here = GameWorld.region(state.currentArea)
        if let anchorArea = state.night.areas.first(where: { GameWorld.region($0) == here }) {
            let point = GameWorld.travelPoint(anchorArea)
            if let d = facing(point, maxDist: 2.4, minDot: 0.4) {
                nearElevator = true
                let n = state.progress.evidenceCount(night: state.night.number)
                let t = CampaignProgress.totalEvidence(night: state.night.number)
                if regions.count > 1, let next = nextRegionArea() {
                    offer(.travel(next), "Elevador de serviço  ·  AÇÃO ir para \(next.name)  ·  SAIR encerrar o turno (provas \(n)/\(t))", d)
                } else {
                    offer(.finish, "Encerrar o turno  ·  AÇÃO  ·  provas \(n)/\(t)", d)
                }
            }
        }
        return (best?.0, best?.1 ?? "")
    }

    /// Regiões distintas desta noite, na ordem em que aparecem.
    private func orderedRegions() -> [AreaID] {
        var seen = Set<String>()
        var out: [AreaID] = []
        for a in state.night.areas {
            let r = GameWorld.region(a)
            if !seen.contains(r) { seen.insert(r); out.append(a) }
        }
        return out
    }

    private func nextRegionArea() -> AreaID? {
        let regions = orderedRegions()
        guard regions.count > 1 else { return nil }
        let here = GameWorld.region(state.currentArea)
        let i = regions.firstIndex { GameWorld.region($0) == here } ?? 0
        return regions[(i + 1) % regions.count]
    }

    private func travel(to area: AreaID) {
        fadeTarget = 1
        state.showToast("Indo para \(area.name)")
        let dest = GameWorld.spawn(area)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { [weak self] in
            guard let self, self.state.phase == .playing else { return }
            self.world.player.position = dest
            self.yaw = 0; self.pitch = 0
            self.phoneRefValid = false
            self.applyCamera()
            self.state.currentArea = area
            self.managerArea = area
            self.managerT = 0.2
            self.managerPause = 3
            self.fadeTarget = 0
        }
    }

    private func applyCamera() {
        world.player.orientation = simd_quatf(angle: yaw, axis: [0, 1, 0])
        world.camera.orientation = simd_quatf(angle: pitch, axis: [1, 0, 0])
    }

    func debugSetPose(position: SIMD3<Float>, yaw y: Float, pitch p: Float) {
        world.player.position = position
        yaw = y
        pitch = p
        state.currentArea = world.area(at: position)
        applyCamera()
    }

    // MARK: - Ferramenta

    private func enterTool(_ s: CleaningSurface) {
        activeSurface = s
        savedPose = (world.player.position, yaw, pitch)
        toolLerp = 0
        toolUV = SIMD2(0.5, 0.5)
        toolPhoneRef = nil
        s.lastUV = nil
        s.toolTip.isEnabled = true
        state.inToolMode = true
        state.currentTool = s.tool
        state.onHaptic?(.tick)
        showHint(for: s)
        pushControllerState(force: true)
    }

    private func exitTool() {
        guard let s = activeSurface else { return }
        s.toolTip.isEnabled = false
        hintEntity?.isEnabled = false
        if let (p, y, pi) = savedPose { world.player.position = p; yaw = y; pitch = pi }
        applyCamera()
        activeSurface = nil
        state.inToolMode = false
        state.currentTool = .none
        toolPhoneRef = nil
        pushControllerState(force: true)
    }

    /// Spray revelador: marca de leve onde ainda há algo escondido.
    private func showHint(for s: CleaningSurface) {
        guard state.progress.hasUpgrade("spray"), let region = s.revealRegion,
              let ev = s.evidenceID, !state.hasEvidence(ev) else {
            hintEntity?.isEnabled = false
            return
        }
        let e = hintEntity ?? {
            let m = ModelEntity(mesh: .generatePlane(width: 1, height: 1),
                                materials: [UnlitMaterial(color: NSColor(calibratedRed: 1, green: 0.9, blue: 0.4, alpha: 0.18))])
            world.nightRoot.addChild(m)
            hintEntity = m
            return m
        }()
        let cx = Float(region.midX), cy = Float(region.midY)
        e.position = s.worldPoint(u: cx, v: cy, lift: 0.006)
        e.orientation = s.dirtEntity.orientation
        e.scale = [Float(region.width) * s.width * 1.2, Float(region.height) * s.height * 1.2, 1]
        if s.spec.isHorizontal { e.scale = [Float(region.width) * s.width * 1.2, 1, Float(region.height) * s.height * 1.2] }
        e.isEnabled = true
    }

    private func updateTool(_ s: CleaningSurface, dt: Float) {
        toolLerp = min(1, toolLerp + dt * 3.5)
        let camTarget = s.toolCameraPosition - SIMD3(0, GameWorld.eyeHeight, 0)
        let look = s.toolLookAt - s.toolCameraPosition
        let targetYaw = atan2(-look.x, -look.z)
        let targetPitch = asin(max(-1, min(1, look.y / max(simd_length(look), 0.001))))
        if let (p, y, pi) = savedPose {
            let t = toolLerp * toolLerp * (3 - 2 * toolLerp)
            world.player.position = simd_mix(p, camTarget, SIMD3(repeating: t))
            yaw = y + (targetYaw - y) * t
            pitch = pi + (targetPitch - pi) * t
            applyCamera()
        }

        var uv = toolUV
        if input.source == .phone && input.hasPhoneAttitude {
            let py = phoneYawUnwrapped()
            if toolPhoneRef == nil { toolPhoneRef = (py, input.phonePitch) }
            let ref = toolPhoneRef!
            uv.x = 0.5 + (py - ref.0) / s.phoneYawRange
            uv.y = 0.5 + (input.phonePitch - ref.1) / s.phonePitchRange
        } else if let p = input.pointer {
            uv = p
        } else {
            uv.x += input.moveX * dt * 0.8 - input.keyYaw * dt * 0.8
            uv.y += input.moveY * dt * 0.8 + input.keyPitch * dt * 0.8
        }
        uv.x = max(0, min(1, uv.x)); uv.y = max(0, min(1, uv.y))
        let delta = uv - toolUV
        toolUV = uv

        let lift: Float = s.tool == .rodo ? 0.02 : 0.04
        s.toolTip.position = s.worldPoint(u: uv.x, v: uv.y, lift: lift)

        let speed = simd_length(delta) / max(dt, 0.001)
        if input.use && toolLerp > 0.7 {
            let effort: Float = input.source == .phone ? max(0.5, min(1.6, input.phoneEffort / 2.5)) : 1
            let roleEff = state.role.efficiency(for: s.tool)
            if speed > 0.05 && s.gestureMatches(delta: delta) {
                let b = s.brush
                let from = s.lastUV ?? uv
                let amount = b.amount * effort * roleEff
                s.mask.clean(from: from, to: uv, halfW: b.halfW, halfH: b.halfH, amount: amount, round: b.round)
                coop?.send(.clean(surface: s.index, u0: from.x, v0: from.y, u1: uv.x, v1: uv.y, amount: amount), reliable: false)
                s.strokeDistance += simd_length(delta)
                scrubLevel = min(1, speed * 1.5)
                if s.strokeDistance > 0.18 { s.strokeDistance = 0; state.onHaptic?(.stroke) }
                state.suspicion = max(0, state.suspicion - dt * 0.05)
            } else if speed > 0.05 {
                scrubLevel = 0.2
            }
            s.lastUV = uv
        } else {
            s.lastUV = nil
        }

        let frac = s.mask.cleanFraction
        state.setTask(s.taskID, progress: frac)
        if frac > 0.001 { coop?.send(.task(s.taskID, frac), reliable: false) }

        var promptText = "\(s.tool.title)  ·  segure USAR e mova  ·  SAIR para voltar"
        if let ev = s.evidenceID, !state.hasEvidence(ev), s.isRevealed {
            promptText = "Tem algo aqui embaixo  ·  AÇÃO para fotografar"
            hintEntity?.isEnabled = false
        }
        state.prompt = promptText

        if input.consumeAct() {
            if let ev = s.evidenceID, !state.hasEvidence(ev), s.isRevealed {
                state.addEvidence(ev)
                coop?.send(.evidence(ev))
                if state.managerSees { state.suspicion = min(1, state.suspicion + 0.15) }
            }
        }
        if input.consumeBack() { exitTool() }
    }

    // MARK: - Interações

    private func startInteraction(_ spec: InteractionSpec) {
        if let ev = spec.evidenceID, state.hasEvidence(ev) { return }
        activeInteraction = spec
        interactionLine = interactionProgress[spec.id] ?? 0
        interactionTimer = 2.2
        interactionElapsed = 0
        state.currentTool = spec.kind == .escuta ? .ouvido : .none
        state.prompt = spec.kind == .escuta ? "Escutando…  ·  SAIR para se afastar" : "\(spec.prompt)  ·  SAIR para parar"
        state.onHaptic?(.tick)
        pushControllerState(force: true)
    }

    private func updateInteraction(dt: Float) {
        guard let spec = activeInteraction, let marker = world.interactionMarkers[spec.id] else {
            activeInteraction = nil
            return
        }
        // aproxima e encara o alvo
        let target = marker.position
        let stand = target + simd_normalize(world.player.position - target + SIMD3(0.001, 0, 0.001)) * 0.9
        var p = world.player.position
        p = simd_mix(p, SIMD3(stand.x, 0, stand.z), SIMD3(repeating: min(1, dt * 3)))
        world.player.position = p
        let d = target - (p + SIMD3(0, GameWorld.eyeHeight, 0))
        let ty = atan2(-d.x, -d.z)
        var diff = ty - yaw
        while diff > .pi { diff -= 2 * .pi }
        while diff < -.pi { diff += 2 * .pi }
        yaw += diff * min(1, dt * 4)
        pitch += (0.05 - pitch) * min(1, dt * 4)
        applyCamera()

        interactionElapsed += dt
        // Se ela olhar, você endireita o corpo e volta a trabalhar. O preço é
        // proporcional ao tempo que você já estava parada ali.
        if spec.risky && state.managerSees && interactionElapsed > 0.5 {
            interactionProgress[spec.id] = interactionLine
            activeInteraction = nil
            state.currentTool = .none
            state.suspicion = min(1, state.suspicion + min(0.18, 0.02 + interactionElapsed * 0.02) * suspicionRate)
            state.showToast("Dona Celeste olhou. Você endireitou o corpo e voltou ao trabalho.")
            state.onHaptic?(.warning)
            return
        }

        interactionTimer += dt
        if interactionTimer > 2.2 {
            interactionTimer = 0
            if interactionLine < spec.lines.count {
                state.pushMessage(from: spec.speaker, text: spec.lines[interactionLine])
                interactionLine += 1
            } else {
                if let ev = spec.evidenceID {
                    state.addEvidence(ev)
                    coop?.send(.evidence(ev))
                }
                interactionProgress[spec.id] = spec.lines.count
                activeInteraction = nil
                state.currentTool = .none
                return
            }
        }
        if input.consumeBack() {
            interactionProgress[spec.id] = interactionLine
            activeInteraction = nil
            state.currentTool = .none
        }
        _ = input.consumeAct()
    }

    // MARK: - Gerente

    private var suspicionRate: Float {
        state.progress.managerAlertness * (state.progress.hasUpgrade("luvas") ? 0.75 : 1.0)
    }

    /// Trecho que a gerente percorre em cada área, em coordenadas de mundo.
    private func managerPath(_ area: AreaID) -> (SIMD3<Float>, SIMD3<Float>)? {
        let o = GameWorld.offset(area)
        switch GameWorld.region(area) {
        case "andar7": return (o + [0.55, 0, -1.5], o + [0.55, 0, -13.5])
        case "lobby": return (o + [-3.2, 0, -5.5], o + [3.2, 0, -12.5])
        case "porao": return (o + [-0.6, 0, -1.2], o + [-0.6, 0, -7.6])
        case "andar8": return (o + [0.4, 0, -1.2], o + [0.4, 0, -12.5])
        default: return nil   // na fachada ninguém te alcança
        }
    }

    /// Nos quartos, na gôndola e atrás do balcão você está fora de vista.
    private var inCover: Bool {
        world.isInCover(world.player.position) || (activeSurface.map { world.isInCover($0.toolCameraPosition) } ?? false)
    }

    private func updateManager(dt: Float) {
        let area = state.currentArea
        guard let (a, b) = managerPath(area) else {
            world.manager.isEnabled = false
            state.managerNear = false
            state.managerSees = false
            state.managerWarning = false
            heartbeat = false
            return
        }
        if managerArea != area {
            managerArea = area
            managerT = 0
            managerPause = 2.5
        }

        // no oitavo andar ela só sobe no fim do turno
        let lateNight = state.night.number == Campaign.count && state.shiftSecondsLeft < 100
        if area == .andar8 && !lateNight {
            world.manager.isEnabled = false
            state.managerNear = false
            state.managerSees = false
            heartbeat = false
            return
        }

        world.manager.isEnabled = true
        let isHost = coop?.isHost ?? true
        if isHost {
            if managerPause > 0 {
                managerPause -= dt
            } else {
                let speed: Float = 0.16 * suspicionRate
                managerT += managerDir * speed * dt
                if managerT <= 0 { managerT = 0; managerDir = 1; managerPause = 3.0 }
                if managerT >= 1 { managerT = 1; managerDir = -1; managerPause = 2.2 }
                if managerRng.next() < 0.004 { managerPause = 1.5 + Float(managerRng.next()) * 2.5 }
            }
        }
        let pos = simd_mix(a, b, SIMD3(repeating: managerT))
        world.manager.position = pos
        let facing = simd_normalize((b - a) * managerDir + SIMD3(0.0001, 0, 0.0001))
        world.manager.orientation = simd_quatf(angle: atan2(facing.x, facing.z), axis: [0, 1, 0])

        let player = world.player.position
        let toPlayer = player - pos
        let dist = simd_length(toPlayer)
        let cover = inCover
        let ahead = simd_dot(simd_normalize(toPlayer + SIMD3(0.0001, 0, 0.0001)), facing) > 0.1
        state.managerNear = dist < 5.0 && !cover
        state.managerSees = !cover && ahead && dist < 8.0
        state.managerWarning = state.progress.hasUpgrade("radio") && dist < 12 && !cover

        // Parada onde não devia, à vista dela: perto de uma porta lacrada, de
        // um telefone que não é seu, ou num andar que oficialmente não existe.
        let idle = activeSurface == nil && activeInteraction == nil
        let nearHotspot = state.night.interactions.contains { spec in
            guard spec.risky, let m = world.interactionMarkers[spec.id] else { return false }
            return simd_length(player - m.position) < 3.2
        } || area == .andar8
        if state.managerSees && idle && nearHotspot {
            state.suspicion = min(1, state.suspicion + dt * 0.05 * suspicionRate)
        }
        // Trabalhando ou fora de vista, a desconfiança esfria.
        if activeSurface != nil && input.use {
            state.suspicion = max(0, state.suspicion - dt * 0.05)
        } else if !state.managerSees {
            state.suspicion = max(0, state.suspicion - dt * 0.03)
        }
        heartbeat = (state.managerSees && dist < 5) || (activeInteraction?.risky == true && state.managerSees)
        if state.suspicion >= 1 { endShift(caught: true) }
    }

    // MARK: - Sustos

    private func updateScares(dt: Float) {
        // susto da noite: dispara quando a primeira tarefa fecha
        if !scareFired && state.tasksDone >= 1 {
            scareFired = true
            fireScare(state.night.scare)
        }
        if scareTimer >= 0 {
            scareTimer += dt
            if scareTimer > 1.6 { world.ghost.isEnabled = false }
            if scareTimer > 25 { scareTimer = -1 }
        }
        if flickerTimer >= 0 {
            flickerTimer += dt
            let on = flickerTimer > 2.4 || (Int(flickerTimer * 14) % 3 != 0)
            world.flicker(on, area: state.currentArea)
            state.lightsFlicker = flickerTimer <= 2.4
            if flickerTimer > 2.4 {
                flickerTimer = -1
                state.lightsFlicker = false
                world.flicker(true, area: state.currentArea)
            }
        }
        // presença ambiente do Osvaldo
        ambientGhostTimer -= dt
        if ambientGhostTimer <= 0 {
            ambientGhostTimer = Float.random(in: 50...95)
            if let line = Campaign.osvaldoLines.randomElement() {
                state.showSubtitle(line, seconds: 4)
                state.onHaptic?(.warning)
            }
        }
    }

    private func fireScare(_ kind: String) {
        flickerTimer = 0
        audio.stinger()
        state.onHaptic?(.shock)
        scareTimer = 0
        let area = state.currentArea
        let o = GameWorld.offset(area)
        switch kind {
        case "silhueta":
            world.ghost.position = o + [0.1, 0, GameWorld.corridorEnd - 0.5]
            world.ghost.isEnabled = true
            state.showSubtitle("Tem alguém do lado de fora do vidro. No sétimo andar.", seconds: 4)
        case "quadro":
            world.ghost.position = o + [-5.4, 0, -6.5]
            world.ghost.isEnabled = true
            state.showSubtitle("O quadro de 1974 tem uma fileira de janelas a mais que o prédio de hoje.", seconds: 5)
        case "espelho":
            world.ghost.position = o + [6.0, 0, -13.6]
            world.ghost.isEnabled = true
            state.showSubtitle("O espelho embaçou sozinho, com o box seco.", seconds: 4)
        case "incinerador":
            world.ghost.position = o + [-3.4, 0, -7.4]
            world.ghost.isEnabled = true
            state.showSubtitle("O incinerador acendeu sozinho e apagou.", seconds: 4)
        default:
            world.ghost.position = o + [0, 0, -12.6]
            world.ghost.isEnabled = true
            state.showSubtitle("Alguém está passando o rodo no vidro. Do lado de fora do oitavo andar.", seconds: 5)
        }
        state.showToast(state.night.closer)
    }

    // MARK: - Rede

    private func updateNetwork(dt: Float) {
        stateSendAccum += dt
        if stateSendAccum > 0.12 { stateSendAccum = 0; pushControllerState(force: false) }
        poseSendAccum += dt
        if poseSendAccum > 0.05 {
            poseSendAccum = 0
            let p = world.player.position
            coop?.send(.pose(x: p.x, y: p.y, z: p.z, yaw: yaw, role: state.role), reliable: false)
            if coop?.isHost ?? false {
                coop?.send(.manager(t: managerT, dir: managerDir, area: state.currentArea.rawValue), reliable: false)
            }
        }
    }

    func pushControllerState(force: Bool) {
        let s = state.controllerState
        if force || lastSentState == nil || !same(s, lastSentState!) {
            lastSentState = s
            server?.send(.state(s))
        }
    }

    private func same(_ a: ControllerState, _ b: ControllerState) -> Bool {
        a.tool == b.tool && a.inToolMode == b.inToolMode && a.prompt == b.prompt && a.phase == b.phase
            && abs(a.suspicion - b.suspicion) < 0.02 && a.managerNear == b.managerNear
            && a.managerWarning == b.managerWarning && a.shiftSecondsLeft == b.shiftSecondsLeft
            && a.evidenceCount == b.evidenceCount && a.area == b.area && a.night == b.night
            && zip(a.tasks, b.tasks).allSatisfy { abs($0.progress - $1.progress) < 0.02 }
    }

    func handleCoop(_ m: CoopMessage, from peer: String) {
        switch m {
        case .pose(let x, let y, let z, let yaw, let role):
            let e = world.avatar(for: peer, role: role)
            e.isEnabled = true
            e.position = [x, y, z]
            e.orientation = simd_quatf(angle: yaw, axis: [0, 1, 0])
            state.coopPeers[peer] = role
        case .clean(let idx, let u0, let v0, let u1, let v1, let amount):
            guard idx < world.surfaces.count else { return }
            let s = world.surfaces[idx]
            let b = s.brush
            s.mask.clean(from: SIMD2(u0, v0), to: SIMD2(u1, v1), halfW: b.halfW, halfH: b.halfH, amount: amount, round: b.round)
        case .evidence(let id):
            state.addEvidence(id)
        case .task(let id, let p):
            state.setTask(id, progress: p)
        case .manager(let t, let dir, _):
            if !(coop?.isHost ?? true) { managerT = t; managerDir = dir }
        case .startNight(let n):
            if state.phase != .playing {
                state.progress.night = n
                startNight()
            }
        }
    }
}
