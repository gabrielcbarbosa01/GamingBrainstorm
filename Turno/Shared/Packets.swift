//
//  Packets.swift
//  Compartilhado entre TurnoMac e TurnoControle.
//
//  Protocolo UDP simples (JSON) entre o iPhone (controle) e o Mac (jogo).
//  O iPhone manda ControllerPacket a ~60 Hz; o Mac responde com FeedbackPacket
//  quando algo muda (ferramenta, dica, mensagem do delegado, háptica).
//

import Foundation

enum TurnoNet {
    static let bonjourType = "_turno._udp"
    static let port: UInt16 = 47321
    static let detectiveName = "Delegado Nunes"
}

/// Estado bruto do controle enviado pelo iPhone.
struct ControllerPacket: Codable {
    var seq: UInt32 = 0
    /// Attitude do CMDeviceMotion (x, y, z, w). Vazio quando não há sensores (simulador).
    var q: [Float] = []
    /// rotationRate (rad/s) — "esforço" do movimento.
    var rot: [Float] = [0, 0, 0]
    /// Joystick virtual, -1...1.
    var jx: Float = 0
    var jy: Float = 0
    /// Botão "Usar" (segurado).
    var use: Bool = false
    /// Botões de borda: contador que incrementa a cada toque, para não perder toques entre pacotes.
    var actCount: UInt16 = 0
    var backCount: UInt16 = 0
    var recalCount: UInt16 = 0
    var mapCount: UInt16 = 0
    var hello: Bool = false
    var name: String = ""
}

enum ToolKind: String, Codable, CaseIterable {
    case none, rodo, vassoura, pano, flanela, ouvido, camera

    var title: String {
        switch self {
        case .none: return "Mãos livres"
        case .rodo: return "Rodo de vidro"
        case .vassoura: return "Vassoura"
        case .pano: return "Pano e spray"
        case .flanela: return "Flanela de lustrar"
        case .ouvido: return "Escutando"
        case .camera: return "Câmera de provas"
        }
    }

    var motionHint: String {
        switch self {
        case .none: return "Aponte o iPhone para olhar. Use o joystick para andar."
        case .rodo: return "iPhone na vertical. Puxe de cima para baixo, faixa por faixa."
        case .vassoura: return "Segure como cabo de vassoura. Varra de um lado ao outro."
        case .pano: return "Segure USAR e esfregue em círculos, várias passadas."
        case .flanela: return "Movimentos curtos e cruzados, sem pressa, até o brilho aparecer."
        case .ouvido: return "Encoste o iPhone na orelha. Fique parada."
        case .camera: return "Aponte para a prova e toque em AÇÃO para fotografar."
        }
    }

    var icon: String {
        switch self {
        case .rodo: return "square.and.line.vertical.and.square"
        case .vassoura: return "wind"
        case .pano: return "drop.fill"
        case .flanela: return "sparkle"
        case .ouvido: return "ear"
        case .camera: return "camera"
        case .none: return "figure.walk"
        }
    }
}

struct TaskStatus: Codable, Identifiable {
    var id: String
    var title: String
    var progress: Float
    var area: String
}

struct ControllerState: Codable {
    var tool: ToolKind = .none
    var inToolMode: Bool = false
    var prompt: String = ""
    var suspicion: Float = 0
    var managerNear: Bool = false
    var managerWarning: Bool = false
    var shiftSecondsLeft: Int = 0
    var tasks: [TaskStatus] = []
    var evidenceCount: Int = 0
    var evidenceTotal: Int = 0
    var phase: String = "menu"
    var night: Int = 1
    var nightTitle: String = ""
    var role: String = ""
    var area: String = ""
    var stars: Int = 0
    var trust: Float = 0.5
}

enum HapticKind: String, Codable {
    case tick, stroke, success, heartbeat, alarm, shock, warning
}

struct ChatMessage: Codable, Identifiable, Equatable {
    var id: String
    var from: String
    var text: String
}

struct EvidenceCard: Codable, Identifiable, Equatable {
    var id: String
    var title: String
    var detail: String
}

enum FeedbackPacket: Codable {
    case state(ControllerState)
    case haptic(HapticKind)
    case message(ChatMessage)
    case evidence(EvidenceCard)
    case welcome(String)
}
