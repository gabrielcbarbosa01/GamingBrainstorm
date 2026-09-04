//
//  KeyboardMouseInput.swift
//  TurnoMac
//
//  Fallback para testar sem iPhone: WASD anda, setas olham, espaço = usar,
//  E = ação, Esc = sair, R = recalibrar. O mouse vira o ponteiro da ferramenta.
//

import AppKit

final class KeyboardMouseInput {
    private let input: InputState
    private var monitors: [Any] = []
    private var down: Set<UInt16> = []

    init(input: InputState) {
        self.input = input
        monitors.append(NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] e in
            guard let self else { return e }
            if e.isARepeat { return nil }
            self.down.insert(e.keyCode)
            switch e.keyCode {
            case 14: self.input.actPressed = true        // E
            case 53: self.input.backPressed = true       // Esc
            case 15: self.input.recalPressed = true      // R
            default: break
            }
            self.refresh()
            return nil
        }!)
        monitors.append(NSEvent.addLocalMonitorForEvents(matching: [.keyUp]) { [weak self] e in
            self?.down.remove(e.keyCode)
            self?.refresh()
            return nil
        }!)
        monitors.append(NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown]) { [weak self] e in
            self?.mouseUse = true; self?.refresh(); return e
        }!)
        monitors.append(NSEvent.addLocalMonitorForEvents(matching: [.leftMouseUp]) { [weak self] e in
            self?.mouseUse = false; self?.refresh(); return e
        }!)
    }

    private var mouseUse = false

    deinit { monitors.forEach { NSEvent.removeMonitor($0) } }

    private func axis(_ neg: UInt16, _ pos: UInt16) -> Float {
        (down.contains(pos) ? 1 : 0) - (down.contains(neg) ? 1 : 0)
    }

    private func refresh() {
        // Só manda para o InputState se o teclado estiver ativo ou se houver alguma tecla.
        let keyboardActive = input.source == .keyboard || !down.isEmpty
        guard keyboardActive else { return }
        if !down.isEmpty { input.source = .keyboard }
        input.moveX = axis(0, 2)      // A / D
        input.moveY = axis(1, 13)     // S / W
        input.keyYaw = axis(124, 123) // → gira à direita (negativo), ← esquerda
        input.keyPitch = axis(125, 126)
        input.use = down.contains(49) || mouseUse
    }

    /// Chamado pela view com a posição do mouse normalizada.
    func setPointer(u: Float, v: Float) {
        if input.source == .keyboard { input.pointer = SIMD2(u, v) }
    }
}
