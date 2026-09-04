//
//  InputState.swift
//  TurnoMac
//
//  Entrada unificada: o GameLoop só lê daqui. Quem escreve é o teclado/mouse
//  (fallback de teste) ou o ControllerServer (iPhone).
//

import Foundation
import simd

final class InputState {
    enum Source { case keyboard, phone }

    var source: Source = .keyboard

    // Contínuos
    var moveX: Float = 0          // -1 esquerda ... 1 direita
    var moveY: Float = 0          // -1 trás ... 1 frente
    var use: Bool = false
    var keyYaw: Float = 0         // -1 ... 1 (setas)
    var keyPitch: Float = 0

    // Apontamento absoluto do iPhone (rad). Yaw tem drift; pitch é gravidade.
    var hasPhoneAttitude = false
    var phoneYaw: Float = 0
    var phonePitch: Float = 0
    var phoneEffort: Float = 0    // |rotationRate|

    // Ponteiro do mouse normalizado (u direita, v cima) sobre a view.
    var pointer: SIMD2<Float>? = nil

    // Bordas: setadas por quem lê o hardware, consumidas pelo loop.
    var actPressed = false
    var backPressed = false
    var recalPressed = false

    func consumeAct() -> Bool { defer { actPressed = false }; return actPressed }
    func consumeBack() -> Bool { defer { backPressed = false }; return backPressed }
    func consumeRecal() -> Bool { defer { recalPressed = false }; return recalPressed }
}
