import simd

public typealias Vec2 = SIMD2<Float>
public typealias Vec3 = SIMD3<Float>

public extension Vec3 {
    var flat: Vec3 { Vec3(x, 0, z) }
    var xz: Vec2 { Vec2(x, z) }
    var planarLength: Float { simd_length(Vec2(x, z)) }
    static func fromPlanar(_ v: Vec2, y: Float = 0) -> Vec3 { Vec3(v.x, y, v.y) }
}

@inlinable public func normalizedOrZero(_ v: Vec3) -> Vec3 {
    let l = simd_length(v)
    return l > 1e-5 ? v / l : .zero
}

@inlinable public func normalizedOrZero(_ v: Vec2) -> Vec2 {
    let l = simd_length(v)
    return l > 1e-5 ? v / l : .zero
}

@inlinable public func clampf(_ v: Float, _ lo: Float, _ hi: Float) -> Float {
    min(max(v, lo), hi)
}

@inlinable public func lerpf(_ a: Float, _ b: Float, _ t: Float) -> Float {
    a + (b - a) * clampf(t, 0, 1)
}

/// Converge `current` para `target` a no maximo `rate` por segundo.
@inlinable public func approach(_ current: Float, _ target: Float, rate: Float, dt: Float) -> Float {
    let d = target - current
    let step = rate * dt
    if abs(d) <= step { return target }
    return current + (d > 0 ? step : -step)
}

/// Normaliza um angulo para (-pi, pi].
@inlinable public func wrapAngle(_ a: Float) -> Float {
    var x = a
    while x > .pi { x -= 2 * .pi }
    while x <= -.pi { x += 2 * .pi }
    return x
}

/// Distancia planar (ignora Y) entre dois pontos.
@inlinable public func planarDistance(_ a: Vec3, _ b: Vec3) -> Float {
    simd_length(Vec2(a.x - b.x, a.z - b.z))
}

/// Ponto mais proximo dentro do segmento AB.
public func closestPointOnSegment(_ p: Vec2, _ a: Vec2, _ b: Vec2) -> Vec2 {
    let ab = b - a
    let denom = simd_dot(ab, ab)
    if denom < 1e-6 { return a }
    let t = clampf(simd_dot(p - a, ab) / denom, 0, 1)
    return a + ab * t
}

/// Gerador deterministico (xorshift128+). Determinismo importa para o netcode do Bloco 10.
public struct Rand: RandomNumberGenerator {
    private var s0: UInt64
    private var s1: UInt64

    public init(seed: UInt64 = 0x9E3779B97F4A7C15) {
        s0 = seed &* 0xBF58476D1CE4E5B9 | 1
        s1 = seed &* 0x94D049BB133111EB | 1
    }

    public mutating func next() -> UInt64 {
        var x = s0
        let y = s1
        s0 = y
        x ^= x << 23
        s1 = x ^ y ^ (x >> 17) ^ (y >> 26)
        return s1 &+ y
    }

    public mutating func float(_ lo: Float = 0, _ hi: Float = 1) -> Float {
        let u = Float(next() >> 40) / Float(1 << 24)
        return lo + (hi - lo) * u
    }

    public mutating func angle() -> Float { float(-.pi, .pi) }

    public mutating func point(inRadius r: Float, around center: Vec3 = .zero) -> Vec3 {
        let a = angle()
        let d = r * sqrt(float())
        return Vec3(center.x + cos(a) * d, center.y, center.z + sin(a) * d)
    }
}
