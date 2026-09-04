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
    var buildError: String?

    init() {
        do {
            world = try GameWorld()
        } catch {
            fatalError("Não foi possível montar o mundo: \(error)")
        }
        keyboard = KeyboardMouseInput(input: input)
        server = ControllerServer(input: input)
        loop = GameLoop(state: state, world: world, input: input, audio: audio)
        loop.server = server
        loop.coop = coop

        server.onConnected = { [weak self] name in
            guard let self else { return }
            self.state.controllerName = name
            self.state.showToast("\(name) conectado como controle")
            self.loop.pushControllerState(force: true)
            for m in self.state.messages { self.server.send(.message(m)) }
            for e in self.state.foundEvidence { self.server.send(.evidence(e)) }
        }
        server.onDisconnected = { [weak self] in
            self?.state.controllerName = ""
            self?.state.showToast("iPhone desconectado — teclado ativo")
        }
        state.onMessage = { [weak self] m in self?.server.send(.message(m)) }
        state.onEvidence = { [weak self] e in self?.server.send(.evidence(e)) }
        state.onHaptic = { [weak self] h in self?.server.send(.haptic(h)) }

        coop.onPeersChanged = { [weak self] n in
            self?.state.coopPeers = n
            self?.state.showToast(n > 0 ? "Co-op: \(n) Mac(s) conectado(s)" : "Co-op: sozinha no turno")
        }
        coop.onMessage = { [weak self] _, m in self?.loop.handleCoop(m) }

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
