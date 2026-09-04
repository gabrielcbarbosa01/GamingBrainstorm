//
//  GameEngine.swift
//  TurnoMac
//
//  Junta estado, mundo, entrada, rede e áudio. A view SwiftUI só conversa com ele.
//

import Foundation
import RealityKit
import SwiftUI

@MainActor
final class GameEngine {
    let state = GameState()
    let input = InputState()
    let world: GameWorld
    let loop: GameLoop
    let audio = ProceduralAudio()
    let keyboard: KeyboardMouseInput
    let server: ControllerServer
    let coop = CoopSession()
    var subscription: EventSubscription?

    init() {
        do { world = try GameWorld() }
        catch { fatalError("Não foi possível montar o hotel: \(error)") }
        keyboard = KeyboardMouseInput(input: input)
        server = ControllerServer(input: input)
        loop = GameLoop(state: state, world: world, input: input, audio: audio)
        loop.server = server
        loop.coop = coop
        state.progress = ProgressStore.load()
        state.role = state.progress.role
        state.night = Campaign.night(min(state.progress.night, Campaign.count))

        server.onConnected = { [weak self] name in
            guard let self else { return }
            self.state.controllerName = name
            self.state.showToast("\(name) conectado como controle")
            self.loop.pushControllerState(force: true)
            for m in self.state.messages { self.server.send(.message(m)) }
            for e in self.state.boardEvidence { self.server.send(.evidence(e)) }
        }
        server.onDisconnected = { [weak self] in
            self?.state.controllerName = ""
            self?.state.showToast("iPhone desconectado — teclado ativo")
        }
        state.onMessage = { [weak self] m in self?.server.send(.message(m)) }
        state.onEvidence = { [weak self] e in self?.server.send(.evidence(e)) }
        state.onHaptic = { [weak self] h in self?.server.send(.haptic(h)) }

        coop.onPeersChanged = { [weak self] n in
            guard let self else { return }
            self.state.coopPeerNames = self.coop.peers.map(\.displayName)
            self.state.showToast(n > 0 ? "Equipe: \(n + 1) pessoas no turno" : "Você está sozinha no turno")
        }
        coop.onPeerLost = { [weak self] name in
            self?.state.coopPeers[name] = nil
            self?.world.peerAvatars[name]?.isEnabled = false
        }
        coop.onMessage = { [weak self] peer, m in self?.loop.handleCoop(m, from: peer) }

        server.start()
        coop.start()
    }

    func attach(_ content: inout RealityViewCameraContent) {
        content.camera = .virtual
        content.add(world.root)
        subscription = content.subscribe(to: SceneEvents.Update.self) { [weak self] event in
            guard let self else { return }
            self.loop.update(dt: Float(event.deltaTime))
        }
    }
}
