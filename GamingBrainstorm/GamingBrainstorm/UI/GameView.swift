//
//  GameView.swift
//  Guardiões dos Biomas
//
//  Junta o SpriteKit (o mundo) com o SwiftUI (a interface) e roteia entre
//  as telas do jogo.
//

import SwiftUI
import SpriteKit

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
            SpriteView(scene: cena, preferredFramesPerSecond: 60)
                .ignoresSafeArea()

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
        .animation(.easeInOut(duration: 0.2), value: st.tela)
        .onAppear { InputManager.shared.start() }
    }
}
