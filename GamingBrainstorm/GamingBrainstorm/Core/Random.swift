//
//  Random.swift
//  Guardiões dos Biomas
//
//  Aleatoriedade determinística: o mundo é infinito, então cada chunk precisa
//  ser reconstruível a partir apenas da semente e das suas coordenadas.
//

import Foundation
import CoreGraphics

/// Gerador splitmix64 — rápido, determinístico e sem estado global.
struct SeededRandom {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed &* 0x9E3779B97F4A7C15 &+ 0xDEADBEEF
        _ = next()
    }

    mutating func next() -> UInt64 {
        state = state &+ 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    /// Valor uniforme em [0, 1).
    mutating func unit() -> Double {
        Double(next() >> 11) * (1.0 / 9007199254740992.0)
    }

    mutating func double(_ lo: Double, _ hi: Double) -> Double {
        lo + unit() * (hi - lo)
    }

    mutating func cg(_ lo: CGFloat, _ hi: CGFloat) -> CGFloat {
        CGFloat(double(Double(lo), Double(hi)))
    }

    mutating func int(_ lo: Int, _ hi: Int) -> Int {
        guard hi > lo else { return lo }
        return lo + Int(next() % UInt64(hi - lo + 1))
    }

    mutating func chance(_ p: Double) -> Bool { unit() < p }

    mutating func pick<T>(_ items: [T]) -> T {
        items[int(0, items.count - 1)]
    }
}

/// Hash determinístico de coordenadas — a base do ruído e do espalhamento
/// de props. Duas execuções sempre produzem o mesmo mundo.
enum Hashing {
    static func hash(_ x: Int, _ y: Int, _ seed: UInt64) -> UInt64 {
        var h = seed &+ 0x9E3779B97F4A7C15
        h ^= UInt64(bitPattern: Int64(x)) &* 0xFF51AFD7ED558CCD
        h = (h ^ (h >> 33)) &* 0xC4CEB9FE1A85EC53
        h ^= UInt64(bitPattern: Int64(y)) &* 0xC2B2AE3D27D4EB4F
        h = (h ^ (h >> 29)) &* 0x165667B19E3779F9
        return h ^ (h >> 32)
    }

    /// Valor pseudo-aleatório em [0, 1) para uma coordenada da grade.
    static func unit(_ x: Int, _ y: Int, _ seed: UInt64) -> Double {
        Double(hash(x, y, seed) >> 11) * (1.0 / 9007199254740992.0)
    }

    /// Gerador semeado por tile, para decidir props sem guardar estado.
    static func rng(_ x: Int, _ y: Int, _ seed: UInt64) -> SeededRandom {
        SeededRandom(seed: hash(x, y, seed))
    }
}

/// Ruído de valor com interpolação suave + fBm. Simples o bastante para rodar
/// milhares de vezes por frame de geração, orgânico o bastante para relevo.
struct ValueNoise {
    let seed: UInt64

    private func lattice(_ xi: Int, _ yi: Int) -> Double {
        Hashing.unit(xi, yi, seed) * 2.0 - 1.0
    }

    private func smooth(_ t: Double) -> Double {
        t * t * t * (t * (t * 6 - 15) + 10)
    }

    /// Amostra em [-1, 1].
    func sample(_ x: Double, _ y: Double) -> Double {
        let xi = Int(floor(x)), yi = Int(floor(y))
        let xf = x - Double(xi), yf = y - Double(yi)
        let u = smooth(xf), v = smooth(yf)

        let a = lattice(xi, yi)
        let b = lattice(xi + 1, yi)
        let c = lattice(xi, yi + 1)
        let d = lattice(xi + 1, yi + 1)

        let top = a + (b - a) * u
        let bottom = c + (d - c) * u
        return top + (bottom - top) * v
    }

    /// Soma de oitavas — dá vales largos com detalhe fino por cima.
    func fbm(_ x: Double, _ y: Double, octaves: Int = 4,
             lacunarity: Double = 2.0, gain: Double = 0.5) -> Double {
        var amplitude = 1.0
        var frequency = 1.0
        var sum = 0.0
        var norm = 0.0
        for _ in 0..<octaves {
            sum += sample(x * frequency, y * frequency) * amplitude
            norm += amplitude
            amplitude *= gain
            frequency *= lacunarity
        }
        return norm > 0 ? sum / norm : 0
    }
}
