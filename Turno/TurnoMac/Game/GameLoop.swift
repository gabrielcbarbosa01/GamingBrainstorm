//
//  GameLoop.swift
//  TurnoMac
//
//  Regras por frame: movimento em primeira pessoa, modo ferramenta (rodo,
//  vassoura, pano), escuta na porta, gerente e suspeita, sustos e fim de turno.
//

import Foundation
import RealityKit
import simd
import CoreGraphics

@MainActor
final class GameLoop {
    let state: GameState
    let world: GameWorld
    let input: InputState
    let audio: ProceduralAudio
    var server: ControllerServer?
    var coop: CoopSession?

    // Jogador
    private var yaw: Float = 0            // rad, 0 = olhando para -z
    private var pitch: Float = 0
    private var phoneYawRef: Float = 0
    private var phonePitchRef: Float = 0
    private var phoneRefValid = false
    private var lastPhoneYaw: Float = 0
    private var edgeTurnBase: Float = 0

    // Modo ferramenta
    private var activeSurface: CleaningSurface?
    private var savedPose: (SIMD3<Float>, Float, Float)?
    private var toolLerp: Float = 0
    private var toolUV = SIMD2<Float>(0.5, 0.5)
    private var toolPhoneRef: (Float, Float)?
    private var scrubLevel: Float = 0

    // Escuta na porta
    private var listening = false
    private var listenLine = 0
    private var listenTimer: Float = 0

    // Gerente
    private var managerZ: Float = -3
    private var managerDir: Float = -1
    private var managerPause: Float = 0
    private var managerRng = SplitMix(seed: 99)

    // Sustos
    private var silhouetteTimer: Float = -1
    private var flickerTimer: Float = -1
    private var heartbeat = false

    // Tempo
    private var elapsed: Double = 0
    private var lastSecond = 0
    private var stateSendAccum: Float = 0
    private var poseSendAccum: Float = 0
    private var lastSentState: ControllerState?

    init(state: GameState, world: GameWorld, input: InputState, audio: ProceduralAudio) {
        self.state = state
        self.world = world
        self.input = input
        self.audio = audio
    }

    // MARK: - Ciclo

    func startShift() {
        state.reset()
        state.phase = .playing
        world.player.position = [0, 0, -1.5]
        yaw = 0; pitch = 0
        elapsed = 0; lastSecond = 0
        managerZ = -3; managerDir = -1; managerPause = 0
        activeSurface = nil; listening = false
        world.silhouette.isEnabled = false
        applyCamera()
        state.fire("intro")
        audio.setAmbient(true)
        coop?.send(.start)
    }

    func update(dt dtRaw: Float) {
        let dt = min(dtRaw, 0.05)
        let now = Date().timeIntervalSince1970
        state.tick(now: now)
        guard state.phase == .playing else {
            world.flushSurfaces()
            return
        }
        elapsed += Double(dt)
        let sec = Int(elapsed)
        if sec != lastSecond {
            lastSecond = sec
            state.shiftSecondsLeft = max(0, Story.shiftSeconds - sec)
            if state.shiftSecondsLeft == 0 { endShift() ; return }
        }

        if input.consumeRecal() { phoneRefValid = false; toolPhoneRef = nil; state.showToast("Controle recalibrado") }

        if let s = activeSurface {
            updateTool(s, dt: dt)
        } else if listening {
            updateListening(dt: dt)
        } else {
            updateFreeMovement(dt: dt)
        }

        updateManager(dt: dt)
        updateScares(dt: dt)
        updateNetwork(dt: dt)

        audio.scrub = scrubLevel
        audio.heartbeat = heartbeat
        scrubLevel = max(0, scrubLevel - dt * 4)
        world.flushSurfaces()
    }

    private func endShift() {
        exitTool()
        listening = false
        state.inToolMode = false
        state.currentTool = .none
        audio.setAmbient(false)
        if state.foundEvidence.count >= 2 {
            state.phase = .deduction
            state.fire("fim")
        } else {
            state.phase = .ending(.semProvas)
        }
        pushControllerState(force: true)
    }

    private func caught() {
        exitTool()
        listening = false
        state.phase = .ending(.descoberto)
        state.fire("descoberto")
        state.onHaptic?(.alarm)
        audio.setAmbient(false)
        pushControllerState(force: true)
    }

    /// Só para o modo de captura/teste.
    func debugSetPose(position: SIMD3<Float>, yaw: Float, pitch: Float) {
        world.player.position = position
        self.yaw = yaw
        self.pitch = pitch
        applyCamera()
    }

    // MARK: - Movimento livre

    private func phoneYawUnwrapped() -> Float {
        var y = input.phoneYaw
        // desembrulha em relação ao último valor para evitar salto em ±π
        while y - lastPhoneYaw > .pi { y -= 2 * .pi }
        while y - lastPhoneYaw < -.pi { y += 2 * .pi }
        lastPhoneYaw = y
        return y
    }

    private func updateFreeMovement(dt: Float) {
        // Olhar
        if input.source == .phone && input.hasPhoneAttitude {
            let py = phoneYawUnwrapped()
            if !phoneRefValid {
                phoneYawRef = py; phonePitchRef = 0; phoneRefValid = true; edgeTurnBase = yaw
            }
            let rel = py - phoneYawRef
            let gain: Float = 1.7
            // giro contínuo quando aponta bem para o lado
            if abs(rel) > 0.75 {
                edgeTurnBase -= (rel > 0 ? 1 : -1) * 1.6 * dt
            }
            yaw = edgeTurnBase - rel * gain
            pitch = max(-1.1, min(1.1, input.phonePitch * 1.2))
        } else {
            yaw -= input.keyYaw * 1.8 * dt
            pitch = max(-1.1, min(1.1, pitch + input.keyPitch * 1.2 * dt))
        }

        // Andar (relativo ao yaw)
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

        // Interação
        let (target, promptText) = findInteraction()
        state.prompt = promptText
        state.currentTool = target?.tool ?? .none
        if input.consumeAct(), let t = target {
            switch t.kind {
            case .surface(let s): enterTool(s)
            case .door7: startListening()
            case .elevator: endShift()
            }
        }
        _ = input.consumeBack()
    }

    private struct Interaction {
        enum Kind { case surface(CleaningSurface), door7, elevator }
        let kind: Kind
        let tool: ToolKind
    }

    private func findInteraction() -> (Interaction?, String) {
        let eye = world.player.position + SIMD3(0, GameWorld.eyeHeight, 0)
        let forward = SIMD3<Float>(-sin(yaw) * cos(pitch), sin(pitch), -cos(yaw) * cos(pitch))
        func facing(_ target: SIMD3<Float>, maxDist: Float, minDot: Float = 0.6) -> Bool {
            let d = target - eye
            let dist = simd_length(d)
            guard dist < maxDist else { return false }
            return simd_dot(simd_normalize(d), forward) > minDot
        }
        var best: (Interaction, String, Float)? = nil
        for s in world.surfaces {
            let target = s.origin + (s.tool == .rodo ? SIMD3(0, 0, 0) : SIMD3(0, 0.3, 0))
            if facing(target, maxDist: s.tool == .rodo ? 2.6 : 3.2, minDot: 0.45) {
                let dist = simd_length(target - eye)
                let done = s.mask.cleanFraction >= 0.9
                let text = done ? "\(s.promptVerb) (concluído)  ·  AÇÃO para retocar" : "\(s.promptVerb)  ·  AÇÃO  ·  \(s.tool.title)"
                if best == nil || dist < best!.2 { best = (Interaction(kind: .surface(s), tool: s.tool), text, dist) }
            }
        }
        let door7 = GameWorld.door7 + SIMD3(0, 1.2, 0)
        if facing(door7, maxDist: 2.0, minDot: 0.5) {
            let dist = simd_length(door7 - eye)
            let has = state.hasEvidence("conversa")
            let text = has ? "Suíte 7 · lacrada pela gerência" : "Escutar atrás da porta  ·  AÇÃO  ·  cuidado com a gerente"
            if best == nil || dist < best!.2 { best = (Interaction(kind: .door7, tool: .ouvido), text, dist) }
        }
        let elev = SIMD3<Float>(0, 1.2, GameWorld.elevatorZ)
        if facing(elev, maxDist: 2.2, minDot: 0.5) {
            let dist = simd_length(elev - eye)
            let text = "Encerrar o turno e descer  ·  AÇÃO  ·  provas: \(state.foundEvidence.count)/4"
            if best == nil || dist < best!.2 { best = (Interaction(kind: .elevator, tool: .none), text, dist) }
        }
        return (best?.0, best?.1 ?? "")
    }

    private func applyCamera() {
        world.player.orientation = simd_quatf(angle: yaw, axis: [0, 1, 0])
        world.camera.orientation = simd_quatf(angle: pitch, axis: [1, 0, 0])
    }

    // MARK: - Modo ferramenta

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
        pushControllerState(force: true)
    }

    private func exitTool() {
        guard let s = activeSurface else { return }
        s.toolTip.isEnabled = false
        if let (p, y, pi) = savedPose { world.player.position = p; yaw = y; pitch = pi }
        applyCamera()
        activeSurface = nil
        state.inToolMode = false
        state.currentTool = .none
        toolPhoneRef = nil
        pushControllerState(force: true)
    }

    private func updateTool(_ s: CleaningSurface, dt: Float) {
        // câmera desliza para a pose da ferramenta
        toolLerp = min(1, toolLerp + dt * 3.5)
        let camTarget = s.toolCameraPosition - SIMD3(0, GameWorld.eyeHeight, 0)
        let look = s.toolLookAt - s.toolCameraPosition
        let targetYaw = atan2(-look.x, -look.z)
        let targetPitch = asin(max(-1, min(1, look.y / simd_length(look))))
        if let (p, y, pi) = savedPose {
            let t = toolLerp * toolLerp * (3 - 2 * toolLerp)
            world.player.position = simd_mix(p, camTarget, SIMD3(repeating: t))
            yaw = y + (targetYaw - y) * t
            pitch = pi + (targetPitch - pi) * t
            applyCamera()
        }

        // posição da ponta
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
        s.toolTip.orientation = simd_quatf(angle: s.tool == .rodo ? 0 : atan2(delta.x, max(abs(delta.y), 0.001)) * 0.3, axis: s.normal)

        // limpar
        let speed = simd_length(delta) / max(dt, 0.001)
        if input.use && toolLerp > 0.7 {
            let effort: Float = input.source == .phone ? max(0.5, min(1.6, input.phoneEffort / 2.5)) : 1
            if speed > 0.05 && s.gestureMatches(delta: delta) {
                let b = s.brush
                let from = s.lastUV ?? uv
                s.mask.clean(from: from, to: uv, halfW: b.halfW, halfH: b.halfH, amount: b.amount * effort, round: b.round)
                coop?.send(.clean(surface: s.index, u0: from.x, v0: from.y, u1: uv.x, v1: uv.y, tool: s.tool, amount: b.amount * effort), reliable: false)
                s.strokeDistance += simd_length(delta)
                scrubLevel = min(1, speed * 1.5)
                if s.strokeDistance > 0.18 { s.strokeDistance = 0; state.onHaptic?(.stroke) }
                state.suspicion = max(0, state.suspicion - dt * 0.05)
            } else if speed > 0.05 {
                // gesto errado: feedback, não limpa
                scrubLevel = 0.2
            }
            s.lastUV = uv
        } else {
            s.lastUV = nil
        }

        let frac = s.mask.cleanFraction
        state.setTask(s.taskID, progress: frac)
        if s.mask.cleanFraction > 0.001 { coop?.send(.task(s.taskID, frac), reliable: false) }

        // prova revelada
        var promptText = "\(s.tool.title)  ·  segure USAR e mova  ·  SAIR para voltar"
        if let ev = s.evidenceID, !state.hasEvidence(ev) {
            if s.isRevealed {
                promptText = "Tem algo aqui embaixo  ·  AÇÃO para fotografar  ·  SAIR para voltar"
                if ev == "mao" { state.fire("mao") }
            }
        }
        state.prompt = promptText

        if input.consumeAct() {
            if let ev = s.evidenceID, !state.hasEvidence(ev), s.isRevealed {
                state.addEvidence(ev)
                coop?.send(.evidence(ev))
                if state.managerSees { state.suspicion = min(1, state.suspicion + 0.2) }
            }
        }
        if input.consumeBack() { exitTool() }
    }

    // MARK: - Escuta

    private func startListening() {
        listening = true
        listenLine = 0
        listenTimer = 0
        state.currentTool = .ouvido
        state.prompt = "Escutando...  ·  SAIR para se afastar"
        state.showSubtitle("(vozes abafadas atrás da porta)", seconds: 3)
        state.onHaptic?(.tick)
        pushControllerState(force: true)
    }

    private func updateListening(dt: Float) {
        // encosta a câmera na porta
        let target = SIMD3<Float>(1.0, 0, GameWorld.door7.z)
        world.player.position = simd_mix(world.player.position, target, SIMD3(repeating: min(1, dt * 4)))
        let targetYaw: Float = -.pi / 2
        yaw += (targetYaw - yaw) * min(1, dt * 4)
        pitch += (0.1 - pitch) * min(1, dt * 4)
        applyCamera()

        listenTimer += dt
        if listenTimer > 2.8 {
            listenTimer = 0
            if listenLine < Story.door7Transcript.count {
                state.showSubtitle(Story.door7Transcript[listenLine], seconds: 3.5)
                state.pushMessage(from: "Porta 7", text: Story.door7Transcript[listenLine])
                listenLine += 1
            } else {
                state.addEvidence("conversa")
                coop?.send(.evidence("conversa"))
                listening = false
                state.currentTool = .none
            }
        }
        // escutar é a ação mais suspeita
        if state.managerSees { state.suspicion = min(1, state.suspicion + dt * 0.16) }
        if input.consumeBack() || input.consumeAct() {
            listening = false
            state.currentTool = .none
        }
        _ = input.consumeAct()
    }

    // MARK: - Gerente

    private func updateManager(dt: Float) {
        let isHost = coop?.isHost ?? true
        if isHost {
            if managerPause > 0 {
                managerPause -= dt
            } else {
                managerZ += managerDir * 0.9 * dt
                if managerZ < -13.5 { managerZ = -13.5; managerDir = 1; managerPause = 2.5 }
                if managerZ > -1.5 { managerZ = -1.5; managerDir = -1; managerPause = 3.5 }
                if managerRng.next() < 0.004 { managerPause = 1.5 + Float(managerRng.next()) * 2 }
            }
        }
        world.manager.position = [0.55, 0, managerZ]
        world.managerDirection = managerDir
        world.manager.orientation = simd_quatf(angle: managerDir < 0 ? 0 : .pi, axis: [0, 1, 0])

        // visão: jogador no corredor, à frente da gerente, até 7 m
        let p = world.player.position
        let inCorridor = p.x > -1.3 && p.x < 1.3
        let toPlayer = p.z - managerZ
        let dist = abs(toPlayer)
        let ahead = (managerDir < 0 && toPlayer < 0.3) || (managerDir > 0 && toPlayer > -0.3)
        state.managerNear = dist < 4.5 && inCorridor
        let seesNow = inCorridor && ahead && dist < 7.5
        state.managerSees = seesNow

        // Comportamento suspeito: parada sem ferramenta na mão perto da suíte 7, ou escutando (tratado na escuta).
        let idleNearSuite7 = activeSurface == nil && !listening && inCorridor && abs(p.z - GameWorld.door7.z) < 2.0
        if seesNow && idleNearSuite7 && dist < 5 {
            state.suspicion = min(1, state.suspicion + dt * 0.08)
        }
        // Limpar perto dela é o disfarce funcionando.
        if activeSurface != nil && input.use { state.suspicion = max(0, state.suspicion - dt * 0.02) }

        heartbeat = (listening || (idleNearSuite7 && seesNow)) && dist < 5
        if state.suspicion >= 1 { caught() }
    }

    // MARK: - Sustos

    private func updateScares(dt: Float) {
        let window = world.surfaces[0]
        if silhouetteTimer < 0 && window.mask.cleanFraction > 0.85 && !silhouetteShown {
            silhouetteTimer = 0
            flickerTimer = 0
            world.silhouette.isEnabled = true
            state.onHaptic?(.shock)
            state.fire("silhueta")
            audio.stinger()
            silhouetteShown = true
        }
        if silhouetteTimer >= 0 {
            silhouetteTimer += dt
            if silhouetteTimer > 1.4 { world.silhouette.isEnabled = false }
            if silhouetteTimer > 30 { silhouetteTimer = -1 }
        }
        if flickerTimer >= 0 {
            flickerTimer += dt
            let on = flickerTimer > 2.4 || (Int(flickerTimer * 14) % 3 != 0)
            for l in world.lights { l.isEnabled = on }
            state.lightsFlicker = flickerTimer <= 2.4
            if flickerTimer > 2.4 { flickerTimer = -1; state.lightsFlicker = false }
        }
    }
    private var silhouetteShown = false

    // MARK: - Rede

    private func updateNetwork(dt: Float) {
        stateSendAccum += dt
        if stateSendAccum > 0.12 { stateSendAccum = 0; pushControllerState(force: false) }
        poseSendAccum += dt
        if poseSendAccum > 0.05 {
            poseSendAccum = 0
            let p = world.player.position
            coop?.send(.pose(x: p.x, y: p.y, z: p.z, yaw: yaw, tool: state.currentTool), reliable: false)
            if coop?.isHost ?? false {
                coop?.send(.manager(z: managerZ, dir: managerDir, paused: managerPause > 0), reliable: false)
                coop?.send(.suspicion(state.suspicion), reliable: false)
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
            && a.shiftSecondsLeft == b.shiftSecondsLeft && a.evidenceCount == b.evidenceCount
            && zip(a.tasks, b.tasks).allSatisfy { abs($0.progress - $1.progress) < 0.02 }
    }

    /// Mensagens do outro Mac.
    func handleCoop(_ m: CoopMessage) {
        switch m {
        case .pose(let x, let y, let z, let yaw, _):
            world.ghost.isEnabled = true
            world.ghost.position = [x, y, z]
            world.ghost.orientation = simd_quatf(angle: yaw, axis: [0, 1, 0])
        case .clean(let idx, let u0, let v0, let u1, let v1, _, let amount):
            guard idx < world.surfaces.count else { return }
            let s = world.surfaces[idx]
            let b = s.brush
            s.mask.clean(from: SIMD2(u0, v0), to: SIMD2(u1, v1), halfW: b.halfW, halfH: b.halfH, amount: amount, round: b.round)
        case .evidence(let id):
            state.addEvidence(id)
        case .task(let id, let p):
            state.setTask(id, progress: p)
        case .manager(let z, let dir, let paused):
            if !(coop?.isHost ?? true) { managerZ = z; managerDir = dir; managerPause = paused ? 1 : 0 }
        case .suspicion(let s):
            if !(coop?.isHost ?? true) { state.suspicion = s }
        case .start:
            if state.phase == .menu { startShift() }
        }
    }
}
