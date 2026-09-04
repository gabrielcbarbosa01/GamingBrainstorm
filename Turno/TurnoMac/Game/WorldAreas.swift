//
//  WorldAreas.swift
//  TurnoMac
//
//  As áreas que se abrem conforme a campanha avança: lobby, porão, a fachada
//  vista da gôndola e o oitavo andar que o hotel diz não existir.
//

import AppKit
import RealityKit
import simd

extension GameWorld {

    // MARK: - Lobby (noite 2)

    func buildLobby() {
        let o = GameWorld.offset(.lobby)
        let marble = GameWorld.color(0.72, 0.68, 0.6)
        let wood = GameWorld.color(0.32, 0.2, 0.12)
        let wall = GameWorld.color(0.78, 0.7, 0.56)

        box([12.4, 0.06, 14.4], at: o + [0, -0.03, -7], color: marble, roughness: 0.35)
        box([12.4, 0.06, 14.4], at: o + [0, 4.0, -7], color: GameWorld.color(0.9, 0.86, 0.78))
        box([0.12, 4.0, 14.4], at: o + [-6.1, 2.0, -7], color: wall)
        box([0.12, 4.0, 14.4], at: o + [6.1, 2.0, -7], color: wall)
        box([12.4, 4.0, 0.12], at: o + [0, 2.0, -14.1], color: wall)
        // fachada de entrada com porta giratória
        box([4.0, 4.0, 0.12], at: o + [-4.1, 2.0, 0.1], color: wall)
        box([4.0, 4.0, 0.12], at: o + [4.1, 2.0, 0.1], color: wall)
        box([4.4, 0.6, 0.12], at: o + [0, 3.7, 0.1], color: wall)
        let doorGlass = unlitPlane(width: 4.2, height: 3.2, color: GameWorld.color(0.16, 0.18, 0.22))
        doorGlass.position = o + [0, 1.7, 0.08]
        root.addChild(doorGlass)
        for i in 0..<3 {
            let a = Float(i) * .pi * 2 / 3
            let leaf = box([1.9, 3.0, 0.06], at: o + [0, 1.5, -0.9], color: GameWorld.color(0.45, 0.4, 0.34), roughness: 0.3)
            leaf.orientation = simd_quatf(angle: a, axis: [0, 1, 0])
        }

        // balcão de mármore
        box([3.2, 1.1, 1.0], at: o + [0, 0.55, -3.0], color: wood, roughness: 0.4)
        box([3.4, 0.08, 1.15], at: o + [0, 1.09, -3.0], color: GameWorld.color(0.85, 0.82, 0.75), roughness: 0.18)
        box([3.2, 2.2, 0.3], at: o + [0, 1.1, -4.2], color: wood, roughness: 0.5)
        for i in 0..<5 {
            box([0.5, 0.34, 0.24], at: o + [-1.2 + Float(i) * 0.6, 1.9, -4.05], color: GameWorld.color(0.25, 0.16, 0.1))
        }
        text("GRAND OXFORD", size: 0.16, color: GameWorld.color(0.85, 0.72, 0.4), at: o + [0, 2.6, -4.1], yaw: 0)
        // livro de registro e telefone
        box([0.5, 0.07, 0.36], at: o + [-0.9, 1.16, -3.1], color: GameWorld.color(0.45, 0.12, 0.12), roughness: 0.6)
        box([0.26, 0.1, 0.2], at: o + [1.3, 1.18, -3.4], color: GameWorld.color(0.12, 0.12, 0.14), roughness: 0.4)
        box([0.05, 0.05, 0.05], at: o + [1.3, 1.25, -3.4], color: GameWorld.color(0.8, 0.2, 0.2))

        // poltronas e mesa de centro
        for (x, z): (Float, Float) in [(-3.2, -7.0), (3.2, -7.0), (0, -9.4)] {
            box([1.0, 0.45, 1.0], at: o + [x, 0.25, z], color: GameWorld.color(0.35, 0.22, 0.24), roughness: 0.9)
            box([1.0, 0.6, 0.2], at: o + [x, 0.7, z - 0.4], color: GameWorld.color(0.32, 0.2, 0.22), roughness: 0.9)
        }
        box([1.1, 0.06, 1.1], at: o + [0, 0.45, -7.2], color: GameWorld.color(0.25, 0.16, 0.12), roughness: 0.3)

        // quadro de 1974 com um andar a mais
        box([0.06, 1.5, 2.2], at: o + [-6.0, 2.1, -6.5], color: GameWorld.color(0.5, 0.36, 0.16), roughness: 0.4)
        let photo = unlitPlane(width: 2.0, height: 1.3, color: GameWorld.color(0.42, 0.4, 0.34))
        photo.position = o + [-5.95, 2.1, -6.5]
        photo.orientation = simd_quatf(angle: .pi / 2, axis: [0, 1, 0])
        root.addChild(photo)
        for f in 0..<8 {
            for k in 0..<5 {
                let w = unlitPlane(width: 0.1, height: 0.1, color: GameWorld.color(0.62, 0.58, 0.46))
                w.position = o + [-5.93, 1.55 + Float(f) * 0.14, -7.0 + Float(k) * 0.26]
                w.orientation = simd_quatf(angle: .pi / 2, axis: [0, 1, 0])
                root.addChild(w)
            }
        }

        // elevador de serviço
        box([1.3, 2.3, 0.1], at: o + [4.6, 1.15, -0.9], color: GameWorld.color(0.55, 0.5, 0.4), roughness: 0.3, metallic: true)
        text("SERVIÇO", size: 0.1, color: GameWorld.color(0.9, 0.8, 0.5), at: o + [4.6, 2.5, -0.95], yaw: .pi)

        // lustre e luzes quentes
        box([1.2, 0.12, 1.2], at: o + [0, 3.7, -7], color: GameWorld.color(0.85, 0.75, 0.45), roughness: 0.25, metallic: true)
        lamp(at: o + [0, 3.2, -7], area: .lobby, color: GameWorld.color(1.0, 0.84, 0.58), intensity: 70000, radius: 22)
        lamp(at: o + [0, 2.2, -2.6], area: .lobby, color: GameWorld.color(1.0, 0.86, 0.6), intensity: 30000, radius: 14)
        lamp(at: o + [-4.4, 2.4, -10.5], area: .lobby, color: GameWorld.color(0.95, 0.78, 0.5), intensity: 22000, radius: 12)
        lamp(at: o + [0, 2.6, -12.6], area: .lobby, color: GameWorld.color(0.95, 0.8, 0.55), intensity: 20000, radius: 12)
        lamp(at: o + [0, 1.6, -6.0], area: .lobby, color: GameWorld.color(0.9, 0.75, 0.5), intensity: 9000, radius: 20)
        lamp(at: o + [4.4, 2.4, -10.5], area: .lobby, color: GameWorld.color(0.95, 0.78, 0.5), intensity: 22000, radius: 12)

        walk(-5.6, 5.6, -13.5, -0.6, .lobby)
        // de pé no balcão você parece estar trabalhando
        cover(-2.2, 2.2, -4.4, -2.1, .lobby)
    }

    // MARK: - Porão (noite 4)

    func buildBasement() {
        let o = GameWorld.offset(.porao)
        let concrete = GameWorld.color(0.38, 0.37, 0.35)
        let wall = GameWorld.color(0.44, 0.43, 0.4)

        box([10.4, 0.06, 9.4], at: o + [0, -0.03, -4.5], color: concrete, roughness: 1)
        box([10.4, 0.06, 9.4], at: o + [0, 2.9, -4.5], color: GameWorld.color(0.3, 0.29, 0.28))
        box([0.12, 2.9, 9.4], at: o + [-5.1, 1.45, -4.5], color: wall)
        box([0.12, 2.9, 9.4], at: o + [5.1, 1.45, -4.5], color: wall)
        box([10.4, 2.9, 0.12], at: o + [0, 1.45, -9.1], color: wall)
        box([10.4, 2.9, 0.12], at: o + [0, 1.45, 0.1], color: wall)

        // máquinas de lavar em fila
        for i in 0..<4 {
            let x = -4.0 + Float(i) * 1.5
            box([1.2, 1.3, 1.0], at: o + [x, 0.65, -1.4], color: GameWorld.color(0.7, 0.71, 0.72), roughness: 0.4)
            let door = ModelEntity(mesh: .generateSphere(radius: 0.26),
                                   materials: [SimpleMaterial(color: GameWorld.color(0.12, 0.14, 0.16), roughness: 0.1, isMetallic: true)])
            door.position = o + [x, 0.75, -0.92]
            root.addChild(door)
        }
        // varal e lençóis
        for i in 0..<5 {
            box([0.02, 0.02, 5.0], at: o + [-3.0 + Float(i) * 1.2, 2.2, -5.5], color: GameWorld.color(0.5, 0.48, 0.4))
            box([0.9, 1.1, 0.02], at: o + [-3.0 + Float(i) * 1.2, 1.65, -4.4 - Float(i) * 0.5], color: GameWorld.color(0.86, 0.85, 0.8), roughness: 1)
        }
        // incinerador
        box([1.8, 2.2, 1.0], at: o + [-3.4, 1.1, -8.4], color: GameWorld.color(0.24, 0.22, 0.2), roughness: 0.7)
        box([1.5, 1.1, 0.1], at: o + [-3.4, 1.3, -7.85], color: GameWorld.color(0.15, 0.14, 0.13), roughness: 0.5)
        box([0.3, 0.3, 0.3], at: o + [-3.4, 2.5, -8.4], color: GameWorld.color(0.3, 0.28, 0.26))
        box([0.3, 1.2, 0.3], at: o + [-3.4, 3.0, -8.4], color: GameWorld.color(0.3, 0.28, 0.26))
        // quadro de energia
        box([0.7, 0.9, 0.16], at: o + [0.4, 1.6, -8.9], color: GameWorld.color(0.35, 0.36, 0.32), roughness: 0.5)
        // basculante alto
        box([1.7, 0.06, 0.1], at: o + [3.6, 1.6, -8.9], color: GameWorld.color(0.3, 0.28, 0.24))
        box([1.7, 0.06, 0.1], at: o + [3.6, 2.4, -8.9], color: GameWorld.color(0.3, 0.28, 0.24))
        let sky = unlitPlane(width: 1.5, height: 0.7, color: GameWorld.color(0.08, 0.09, 0.14))
        sky.position = o + [3.6, 2.0, -8.95]
        root.addChild(sky)
        // escada de saída
        for i in 0..<6 {
            box([1.6, 0.16, 0.32], at: o + [4.0, 0.08 + Float(i) * 0.18, -0.6 - Float(i) * 0.3], color: GameWorld.color(0.42, 0.41, 0.39))
        }
        // prateleira com caixas velhas
        box([0.5, 2.0, 3.0], at: o + [4.7, 1.0, -5.0], color: GameWorld.color(0.36, 0.3, 0.24), roughness: 0.9)
        for i in 0..<4 {
            box([0.44, 0.4, 0.5], at: o + [4.6, 0.4 + Float(i) * 0.5, -4.0 - Float(i % 2) * 0.9], color: GameWorld.color(0.55, 0.45, 0.32), roughness: 1)
        }

        // luz fraca: duas lâmpadas nuas
        lamp(at: o + [-1.5, 2.6, -3.0], area: .porao, color: GameWorld.color(0.95, 0.85, 0.62), intensity: 9000, radius: 9)
        lamp(at: o + [2.4, 2.6, -7.0], area: .porao, color: GameWorld.color(0.85, 0.8, 0.7), intensity: 6000, radius: 8)
        box([0.14, 0.14, 0.14], at: o + [-1.5, 2.65, -3.0], color: GameWorld.color(1.0, 0.94, 0.7), roughness: 0.2)
        box([0.14, 0.14, 0.14], at: o + [2.4, 2.65, -7.0], color: GameWorld.color(1.0, 0.94, 0.7), roughness: 0.2)

        walk(-4.6, 4.6, -8.6, -0.6, .porao)
        // atrás da prateleira e ao lado do incinerador ninguém te enxerga
        cover(3.2, 4.6, -6.8, -3.2, .porao)
        cover(-4.6, -2.4, -8.6, -6.8, .porao)
    }

    // MARK: - Fachada e gôndola (noites 1 e 3)

    func buildFacade() {
        let o = GameWorld.offset(.fachada)
        // parede externa do hotel, vista de fora, com as janelas do sétimo
        let stone = GameWorld.color(0.42, 0.38, 0.33)
        box([16.0, 9.0, 0.4], at: o + [0, 1.5, -0.4], color: stone, roughness: 0.95)
        // cornija onde ele andou
        box([16.0, 0.22, 0.5], at: o + [0, 0.42, 0.05], color: GameWorld.color(0.5, 0.46, 0.4), roughness: 0.9)
        box([16.0, 0.18, 0.42], at: o + [0, 3.1, 0.02], color: GameWorld.color(0.5, 0.46, 0.4), roughness: 0.9)

        // três janelas: quarto 5, corredor, suíte 7
        for (i, x) in [Float(-4.2), 0, 4.2].enumerated() {
            let lit = i != 1
            box([2.1, 0.12, 0.16], at: o + [x, 0.66, 0.02], color: GameWorld.color(0.3, 0.2, 0.12))
            box([2.1, 0.12, 0.16], at: o + [x, 2.44, 0.02], color: GameWorld.color(0.3, 0.2, 0.12))
            box([0.12, 1.9, 0.16], at: o + [x - 1.0, 1.55, 0.02], color: GameWorld.color(0.3, 0.2, 0.12))
            box([0.12, 1.9, 0.16], at: o + [x + 1.0, 1.55, 0.02], color: GameWorld.color(0.3, 0.2, 0.12))
            // interior visto de fora
            let inner = unlitPlane(width: 1.9, height: 1.8,
                                   color: lit ? GameWorld.color(0.55, 0.4, 0.22) : GameWorld.color(0.12, 0.1, 0.1))
            inner.position = o + [x, 1.55, -0.15]
            root.addChild(inner)
            if lit {
                // móveis do quarto, em sombra, vistos de fora
                let sil = unlitPlane(width: 0.7, height: 0.5, color: GameWorld.color(0.16, 0.11, 0.08))
                sil.position = o + [x + 0.4, 1.1, -0.13]
                root.addChild(sil)
            }
        }
        // o número do andar pintado
        text("7", size: 0.4, color: GameWorld.color(0.6, 0.56, 0.5), at: o + [-6.6, 2.2, 0.06], yaw: 0)

        // gôndola: plataforma, guarda-corpo e cabos
        let g = GameWorld.color(0.45, 0.44, 0.4)
        box([4.6, 0.1, 1.4], at: o + [0, 0.0, 1.2], color: g, roughness: 0.6, metallic: true)
        box([4.6, 0.9, 0.08], at: o + [0, 0.5, 1.85], color: g, roughness: 0.6, metallic: true)
        box([0.08, 0.9, 1.4], at: o + [-2.25, 0.5, 1.2], color: g, roughness: 0.6, metallic: true)
        box([0.08, 0.9, 1.4], at: o + [2.25, 0.5, 1.2], color: g, roughness: 0.6, metallic: true)
        for x: Float in [-2.2, 2.2] {
            box([0.05, 8.0, 0.05], at: o + [x, 4.5, 1.5], color: GameWorld.color(0.3, 0.3, 0.3), metallic: true)
        }
        // balde e o rádio na plataforma
        box([0.3, 0.32, 0.3], at: o + [-1.8, 0.2, 1.4], color: GameWorld.color(0.3, 0.42, 0.48), roughness: 0.5)

        // céu, cidade e chão lá embaixo
        var rnd = SplitMix(seed: 42)
        let sky = unlitPlane(width: 60, height: 30, color: GameWorld.color(0.05, 0.06, 0.12))
        sky.position = o + [0, 6, 14]
        sky.orientation = simd_quatf(angle: .pi, axis: [0, 1, 0])
        root.addChild(sky)
        for _ in 0..<40 {
            let h = Float(rnd.range(3, 16))
            let bx = Float(rnd.range(-22, 22))
            let b = unlitPlane(width: Float(rnd.range(1.5, 4)), height: h, color: GameWorld.color(0.07, 0.08, 0.13))
            b.position = o + [bx, h / 2 - 6, 12]
            b.orientation = simd_quatf(angle: .pi, axis: [0, 1, 0])
            root.addChild(b)
            for _ in 0..<5 {
                let w = unlitPlane(width: 0.16, height: 0.2,
                                   color: rnd.next() > 0.5 ? GameWorld.color(0.9, 0.75, 0.4) : GameWorld.color(0.5, 0.6, 0.8))
                w.position = o + [bx + Float(rnd.range(-1, 1)), Float(rnd.range(-5, Double(h) - 6)), 11.9]
                w.orientation = simd_quatf(angle: .pi, axis: [0, 1, 0])
                root.addChild(w)
            }
        }
        let moon = ModelEntity(mesh: .generateSphere(radius: 0.7), materials: [UnlitMaterial(color: GameWorld.color(0.92, 0.92, 0.84))])
        moon.position = o + [8, 9, 11]
        root.addChild(moon)
        // luz fria de rua vindo de baixo
        lamp(at: o + [0, -1.5, 3.0], area: .fachada, color: GameWorld.color(0.6, 0.7, 0.95), intensity: 9000, radius: 14)
        lamp(at: o + [0, 2.6, 2.2], area: .fachada, color: GameWorld.color(0.75, 0.8, 0.95), intensity: 5000, radius: 8)

        walk(-2.2, 2.2, 0.6, 1.85, .fachada)
        cover(-2.4, 2.4, 0.4, 2.0, .fachada)
    }

    // MARK: - Oitavo andar (noite 5)

    func buildFloor8() {
        let o = GameWorld.offset(.andar8)
        let burnt = GameWorld.color(0.2, 0.18, 0.16)
        let wall = GameWorld.color(0.34, 0.31, 0.28)

        box([3.2, 0.05, 14.4], at: o + [0, -0.025, -7], color: burnt, roughness: 1)
        box([3.2, 0.05, 14.4], at: o + [0, 2.7, -7], color: GameWorld.color(0.16, 0.15, 0.14))
        for side: Float in [-1, 1] {
            box([0.1, 2.7, 14.4], at: o + [side * 1.55, 1.35, -7], color: wall)
        }
        box([3.2, 2.7, 0.1], at: o + [0, 1.35, 0.05], color: wall)
        // escada murada por onde você entra
        box([1.2, 2.1, 0.08], at: o + [-0.9, 1.05, -0.02], color: GameWorld.color(0.42, 0.38, 0.34), roughness: 0.9)
        text("8", size: 0.2, color: GameWorld.color(0.55, 0.5, 0.44), at: o + [-0.9, 2.4, -0.06], yaw: .pi)

        // portas queimadas
        for z: Float in [-4.0, -6.5, -9.0, -11.5] {
            box([0.06, 2.1, 1.0], at: o + [-1.48, 1.05, z], color: GameWorld.color(0.14, 0.12, 0.1), roughness: 0.95)
        }
        addFloor8Door(number: "803", at: o + [1.5, 0, -10.0])
        box([0.06, 2.1, 1.0], at: o + [1.48, 1.05, -5.0], color: GameWorld.color(0.14, 0.12, 0.1), roughness: 0.95)

        // janela selada com tábuas no fim
        box([3.2, 2.7, 0.1], at: o + [0, 1.35, -14.05], color: wall)
        let sky = unlitPlane(width: 1.4, height: 1.7, color: GameWorld.color(0.07, 0.09, 0.16))
        sky.position = o + [0, 1.5, -14.02]
        root.addChild(sky)
        for i in 0..<4 {
            let b = box([1.7, 0.16, 0.06], at: o + [0, 0.9 + Float(i) * 0.42, -13.95], color: GameWorld.color(0.3, 0.24, 0.18), roughness: 0.95)
            b.orientation = simd_quatf(angle: Float(i % 2 == 0 ? 0.08 : -0.06), axis: [0, 0, 1])
        }

        // quarto 803
        box([5.2, 0.05, 3.4], at: o + [3.9, -0.025, -10.0], color: burnt, roughness: 1)
        box([5.2, 0.05, 3.4], at: o + [3.9, 2.7, -10.0], color: GameWorld.color(0.16, 0.15, 0.14))
        box([0.1, 2.7, 3.4], at: o + [6.45, 1.35, -10.0], color: wall)
        box([5.2, 2.7, 0.1], at: o + [3.9, 1.35, -8.35], color: wall)
        box([5.2, 2.7, 0.1], at: o + [3.9, 1.35, -11.65], color: wall)
        box([0.1, 2.7, 1.1], at: o + [1.55, 1.35, -8.9], color: wall)
        box([0.1, 2.7, 1.1], at: o + [1.55, 1.35, -11.1], color: wall)
        box([0.1, 0.6, 1.2], at: o + [1.55, 2.4, -10.0], color: wall)
        // móveis queimados
        box([1.9, 0.45, 1.5], at: o + [5.2, 0.22, -9.3], color: GameWorld.color(0.13, 0.11, 0.1), roughness: 1)
        box([0.9, 1.1, 0.45], at: o + [5.9, 0.55, -11.2], color: GameWorld.color(0.15, 0.12, 0.1), roughness: 1)
        box([0.5, 0.06, 0.34], at: o + [5.9, 1.13, -11.2], color: GameWorld.color(0.25, 0.22, 0.18), roughness: 0.8)
        // a janela do 803, por onde a gôndola aparece
        let sky2 = unlitPlane(width: 1.2, height: 1.4, color: GameWorld.color(0.07, 0.09, 0.16))
        sky2.position = o + [6.42, 1.6, -9.8]
        sky2.orientation = simd_quatf(angle: .pi / 2, axis: [0, 1, 0])
        root.addChild(sky2)

        // quase sem luz: só o que vaza da escada e da janela
        lamp(at: o + [-0.6, 1.9, -1.2], area: .andar8, color: GameWorld.color(0.7, 0.72, 0.8), intensity: 3600, radius: 8)
        lamp(at: o + [0, 1.6, -13.2], area: .andar8, color: GameWorld.color(0.45, 0.55, 0.85), intensity: 7000, radius: 10)
        lamp(at: o + [0, 1.5, -7.0], area: .andar8, color: GameWorld.color(0.5, 0.52, 0.62), intensity: 2400, radius: 14)
        lamp(at: o + [5.9, 1.6, -9.8], area: .andar8, color: GameWorld.color(0.4, 0.5, 0.8), intensity: 2600, radius: 6)

        walk(-1.2, 1.2, -13.4, -0.6, .andar8)
        walk(1.2, 6.2, -11.4, -8.6, .andar8)
        walk(1.0, 1.6, -10.45, -9.55, .andar8)
        cover(1.7, 6.2, -11.4, -8.6, .andar8)
    }

    private func addFloor8Door(number: String, at p: SIMD3<Float>) {
        box([0.06, 2.1, 1.0], at: [p.x - 0.02, 1.05, p.z], color: GameWorld.color(0.16, 0.13, 0.11), roughness: 0.95)
        text(number, size: 0.12, color: GameWorld.color(0.62, 0.56, 0.46), at: [p.x - 0.08, 1.75, p.z], yaw: -.pi / 2)
    }
}
