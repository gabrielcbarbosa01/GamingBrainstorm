//
//  GameView.swift
//  Guardiões dos Biomas
//
//  Junta o SpriteKit (o mundo) com o SwiftUI (a interface) e roteia entre
//  as telas do jogo.
//

import SwiftUI
import SpriteKit

/// Mantém a cena do santuário viva enquanto o jogador está dentro dele.
struct SantuarioHost: View {
    @ObservedObject var st: GameState
    @State private var cena: SantuarioScene

    init(st: GameState) {
        self.st = st
        let s = SantuarioScene(size: CGSize(width: 900, height: 720))
        s.estado = st
        _cena = State(wrappedValue: s)
    }

    var body: some View {
        SpriteView(scene: cena, preferredFramesPerSecond: 60)
            .ignoresSafeArea()
    }
}

struct GameView: View {
    @ObservedObject var st: GameState
    @State private var cena: GameScene

    init(st: GameState) {
        self.st = st
        let s = GameScene(size: CGSize(width: 1280, height: 800))
        s.scaleMode = .resizeFill
        s.estado = st
        _cena = State(wrappedValue: s)
    }

    var body: some View {
        ZStack {
            // Durante uma prova arcade a cena de exploração dá lugar à corrida.
            if let prova = st.corrida {
                CorridaHost(st: st, config: prova.config)
                    .id(prova.config.bioma.rawValue)
                CorridaView(st: st, sessao: prova)
            } else {
                exploracao
            }
        }
        .animation(.easeInOut(duration: 0.2), value: st.tela)
        .onAppear { InputManager.shared.start() }
    }

    private var exploracao: some View {
        ZStack {
            // O Refúgio é mundo aberto; os biomas são santuários de salas.
            if st.biomaCarregado == .refugio {
                SpriteView(scene: cena, preferredFramesPerSecond: 60)
                    .ignoresSafeArea()
            } else {
                SantuarioHost(st: st)
                    .id("\(st.biomaCarregado.rawValue)_\(st.geracaoMundo)")
            }

            switch st.tela {
            case .menu:
                MenuView(st: st).transition(.opacity)
            case .creditos:
                ComoSeJogaView(st: st).transition(.opacity)
            case .jornal:
                JournalView(st: st).transition(.opacity)
            case .mapa:
                MapView(st: st).transition(.opacity)
            case .jogo:
                HUDView(st: st)
                if let sessao = st.dialogo {
                    Color.black.opacity(0.25).ignoresSafeArea().allowsHitTesting(false)
                    DialogueView(st: st, sessao: sessao)
                }
                if let op = st.operacao, op.encerrada {
                    OperacaoResultado(st: st, sessao: op)
                }
                if let pescaria = st.pesca {
                    PescaView(st: st, sessao: pescaria)
                }
                switch st.painelRefugio {
                case .viveiro(let i): ViveiroView(st: st, canteiro: i)
                case .oficina: OficinaView(st: st)
                case .harpia: HarpiaView(st: st)
                case nil: EmptyView()
                }
            }
        }
    }
}
