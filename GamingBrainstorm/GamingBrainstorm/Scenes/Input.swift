//
//  Input.swift
//  Guardiões dos Biomas
//
//  Teclado no macOS. Um monitor local de NSEvent alimenta um conjunto de
//  teclas pressionadas; a cena lê esse estado a cada frame. Ações pontuais
//  (interagir, abrir o códice) são consumidas uma única vez.
//

import AppKit
import SpriteKit

enum GameAction: Hashable {
    case interagir
    case habilidade
    case jornal
    case mapa
    case menu
    case forma(Int)     // 1 a 5
    case humano
    case expedicao
}

final class InputManager {
    static let shared = InputManager()

    private var teclas = Set<UInt16>()
    private var acoesPendentes: [GameAction] = []
    private var monitor: Any?

    // Códigos de tecla do macOS (independentes de layout para setas e teclas de ação).
    private enum Key {
        static let w: UInt16 = 13, a: UInt16 = 0, s: UInt16 = 1, d: UInt16 = 2
        static let left: UInt16 = 123, right: UInt16 = 124, down: UInt16 = 125, up: UInt16 = 126
        static let e: UInt16 = 14, q: UInt16 = 12, m: UInt16 = 46, r: UInt16 = 15
        static let tab: UInt16 = 48, space: UInt16 = 49, esc: UInt16 = 53
        static let n1: UInt16 = 18, n2: UInt16 = 19, n3: UInt16 = 20, n4: UInt16 = 21
        static let n5: UInt16 = 23, n6: UInt16 = 22
    }

    private init() {}

    func start() {
        guard monitor == nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp]) { [weak self] event in
            guard let self else { return event }
            if event.type == .keyDown {
                if event.isARepeat { return nil }
                self.teclas.insert(event.keyCode)
                if let acao = Self.acao(para: event.keyCode) {
                    self.acoesPendentes.append(acao)
                }
            } else {
                self.teclas.remove(event.keyCode)
            }
            // Engole a tecla para o macOS não emitir o "bip" de tecla inválida.
            return Self.interessante(event.keyCode) ? nil : event
        }
    }

    func stop() {
        if let m = monitor { NSEvent.removeMonitor(m) }
        monitor = nil
        teclas.removeAll()
        acoesPendentes.removeAll()
    }

    /// Chamado quando o jogo perde o foco, para não travar o personagem andando.
    func limparTeclas() { teclas.removeAll() }

    private static func acao(para code: UInt16) -> GameAction? {
        switch code {
        case Key.e: return .interagir
        case Key.space: return .habilidade
        case Key.tab: return .jornal
        case Key.m: return .mapa
        case Key.esc: return .menu
        case Key.q: return .humano
        case Key.r: return .expedicao
        case Key.n1: return .forma(1)
        case Key.n2: return .forma(2)
        case Key.n3: return .forma(3)
        case Key.n4: return .forma(4)
        case Key.n5: return .forma(5)
        case Key.n6: return .forma(6)
        default: return nil
        }
    }

    private static func interessante(_ code: UInt16) -> Bool {
        acao(para: code) != nil || [Key.w, Key.a, Key.s, Key.d,
                                    Key.left, Key.right, Key.up, Key.down].contains(code)
    }

    /// Vetor de movimento normalizado, do teclado.
    var direcao: CGVector {
        var dx: CGFloat = 0, dy: CGFloat = 0
        if teclas.contains(Key.a) || teclas.contains(Key.left) { dx -= 1 }
        if teclas.contains(Key.d) || teclas.contains(Key.right) { dx += 1 }
        if teclas.contains(Key.s) || teclas.contains(Key.down) { dy -= 1 }
        if teclas.contains(Key.w) || teclas.contains(Key.up) { dy += 1 }
        let len = (dx * dx + dy * dy).squareRoot()
        guard len > 0 else { return .zero }
        return CGVector(dx: dx / len, dy: dy / len)
    }

    /// A barra de espaço é lida como estado contínuo: planar, cavar e voar
    /// dependem de manter pressionado, não de apertar uma vez.
    var habilidadeSegurada: Bool { teclas.contains(Key.space) }

    /// Retira e devolve as ações acumuladas desde o último frame.
    func consumirAcoes() -> [GameAction] {
        let a = acoesPendentes
        acoesPendentes.removeAll()
        return a
    }
}
