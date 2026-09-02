import SceneKit
import GameCore

/// Modelos que nao vieram prontos: cerca, porteira, lamacal, fardo de feno,
/// lanterna, alavanca, feixe, chao e tufos de mato. Tudo geometria primitiva,
/// pensada para ser trocada por arte depois sem mexer no resto.
enum Prop {

    // MARK: Materiais
    static func mat(_ color: NSColor,
                    roughness: CGFloat = 0.9,
                    metalness: CGFloat = 0,
                    emission: NSColor? = nil) -> SCNMaterial {
        let m = SCNMaterial()
        m.lightingModel = .physicallyBased
        m.diffuse.contents = color
        m.roughness.contents = roughness
        m.metalness.contents = metalness
        if let emission { m.emission.contents = emission }
        return m
    }

    static func node(_ geometry: SCNGeometry, _ material: SCNMaterial) -> SCNNode {
        geometry.materials = [material]
        return SCNNode(geometry: geometry)
    }

    // MARK: Paleta noturna
    static let grassColor = NSColor(calibratedRed: 0.10, green: 0.20, blue: 0.12, alpha: 1)
    static let woodColor  = NSColor(calibratedRed: 0.30, green: 0.23, blue: 0.17, alpha: 1)
    static let mudColor   = NSColor(calibratedRed: 0.17, green: 0.13, blue: 0.09, alpha: 1)
    static let hayColor   = NSColor(calibratedRed: 0.62, green: 0.51, blue: 0.24, alpha: 1)
    static let beamColor  = NSColor(calibratedRed: 0.35, green: 0.85, blue: 0.80, alpha: 1)
    static let alienColor = NSColor(calibratedRed: 0.45, green: 0.78, blue: 0.52, alpha: 1)

    // MARK: Chao
    static func ground() -> SCNNode {
        let floor = SCNFloor()
        floor.reflectivity = 0
        floor.firstMaterial = mat(grassColor, roughness: 1)
        let n = SCNNode(geometry: floor)
        n.name = "ground"
        return n
    }

    /// Tufos de mato espalhados: dao referencia de velocidade e escala.
    static func grassTufts(count: Int, bounds: Float, seed: UInt64 = 7) -> SCNNode {
        var rng = Rand(seed: seed)
        let root = SCNNode()
        root.name = "grass"
        let geo = SCNCone(topRadius: 0, bottomRadius: 0.030, height: 0.14)
        geo.radialSegmentCount = 3
        let m = mat(NSColor(calibratedRed: 0.14, green: 0.26, blue: 0.15, alpha: 1), roughness: 1)
        geo.materials = [m]
        for _ in 0..<count {
            let n = SCNNode(geometry: geo)
            n.position = SCNVector3(rng.float(-bounds, bounds), 0.1, rng.float(-bounds, bounds))
            n.eulerAngles.y = CGFloat(rng.angle())
            let s = rng.float(0.6, 1.4)
            n.scale = SCNVector3(s, s * rng.float(0.8, 1.2), s)
            root.addChildNode(n)
        }
        // Achatar em uma geometria so: 3 mil nos soltos derrubariam o frame rate.
        let flat = root.flattenedClone()
        flat.name = "grass"
        return flat
    }

    // MARK: Cerca e porteira
    static func fence(from a: Vec2, to b: Vec2) -> SCNNode {
        let root = SCNNode()
        let dx = b.x - a.x, dz = b.y - a.y
        let length = (dx * dx + dz * dz).squareRoot()
        guard length > 0.01 else { return root }
        let angle = atan2(dx, dz)

        let postGeo = SCNBox(width: 0.14, height: 1.25, length: 0.14, chamferRadius: 0.01)
        let postMat = mat(woodColor, roughness: 0.95)
        let spacing: Float = 2.4
        let count = max(2, Int(length / spacing) + 1)
        for i in 0..<count {
            let t = Float(i) / Float(count - 1)
            let p = SCNNode(geometry: postGeo)
            p.geometry?.materials = [postMat]
            p.position = SCNVector3(a.x + dx * t, 0.62, a.y + dz * t)
            root.addChildNode(p)
        }

        for (h, thick) in [(Float(0.95), CGFloat(0.09)), (Float(0.55), CGFloat(0.08))] {
            let rail = SCNBox(width: 0.06, height: thick, length: CGFloat(length), chamferRadius: 0.01)
            let n = node(rail, postMat)
            n.position = SCNVector3((a.x + b.x) / 2, h, (a.y + b.y) / 2)
            n.eulerAngles.y = CGFloat(angle)
            root.addChildNode(n)
        }
        root.name = "fence"
        return root
    }

    /// A porteira gira em torno do poste esquerdo. Abrir e um ato fisico e barulhento.
    static func gate(from a: Vec2, to b: Vec2) -> SCNNode {
        let hinge = SCNNode()
        hinge.position = SCNVector3(a.x, 0, a.y)
        hinge.name = "gateHinge"

        let dx = b.x - a.x, dz = b.y - a.y
        let length = (dx * dx + dz * dz).squareRoot()
        let angle = atan2(dx, dz)

        let leaf = SCNNode()
        leaf.eulerAngles.y = CGFloat(angle)
        let m = mat(NSColor(calibratedRed: 0.38, green: 0.30, blue: 0.21, alpha: 1), roughness: 0.9)
        for h in [Float(0.95), Float(0.55)] {
            let rail = SCNBox(width: 0.07, height: 0.1, length: CGFloat(length), chamferRadius: 0.01)
            let n = node(rail, m)
            n.position = SCNVector3(0, h, length / 2)
            leaf.addChildNode(n)
        }
        let diag = SCNBox(width: 0.05, height: 0.08, length: CGFloat(length * 1.05), chamferRadius: 0)
        let d = node(diag, m)
        d.position = SCNVector3(0, 0.75, length / 2)
        d.eulerAngles.x = 0.32
        leaf.addChildNode(d)

        let post = SCNBox(width: 0.16, height: 1.35, length: 0.16, chamferRadius: 0.01)
        let p = node(post, mat(woodColor))
        p.position = SCNVector3(0, 0.67, 0)
        hinge.addChildNode(p)
        hinge.addChildNode(leaf)
        leaf.name = "leaf"
        return hinge
    }

    // MARK: Lamacal
    static func mud(radius: Float) -> SCNNode {
        let disc = SCNCylinder(radius: CGFloat(radius), height: 0.04)
        disc.radialSegmentCount = 28
        let m = mat(mudColor, roughness: 0.35)
        m.diffuse.contents = mudColor
        let n = node(disc, m)
        n.position.y = 0.02
        n.name = "mud"
        return n
    }

    // MARK: Fardo de feno
    static func hayBale() -> SCNNode {
        let geo = SCNCylinder(radius: 0.46, height: 0.95)
        geo.radialSegmentCount = 14
        let n = node(geo, mat(hayColor, roughness: 1))
        n.eulerAngles.z = .pi / 2
        let holder = SCNNode()
        holder.addChildNode(n)
        n.position.y = 0.46
        holder.name = "hay"
        return holder
    }

    // MARK: Lanterna
    static func lantern() -> SCNNode {
        let root = SCNNode()
        let body = node(SCNBox(width: 0.16, height: 0.22, length: 0.16, chamferRadius: 0.03),
                        mat(NSColor(calibratedWhite: 0.22, alpha: 1), roughness: 0.5, metalness: 0.6))
        body.position.y = 0.11
        let lens = node(SCNSphere(radius: 0.075),
                        mat(NSColor(calibratedRed: 1, green: 0.95, blue: 0.78, alpha: 1),
                            roughness: 0.2,
                            emission: NSColor(calibratedRed: 1, green: 0.93, blue: 0.72, alpha: 1)))
        lens.position = SCNVector3(0, 0.2, 0.05)
        root.addChildNode(body)
        root.addChildNode(lens)
        lens.name = "lens"
        root.name = "lantern"
        return root
    }

    // MARK: Alavanca de Subida
    static func lever() -> SCNNode {
        let root = SCNNode()
        let base = node(SCNCylinder(radius: 0.55, height: 0.35),
                        mat(NSColor(calibratedRed: 0.20, green: 0.20, blue: 0.28, alpha: 1),
                            roughness: 0.4, metalness: 0.7))
        base.position.y = 0.17
        root.addChildNode(base)

        let pivot = SCNNode()
        pivot.position = SCNVector3(0, 0.35, 0)
        pivot.name = "leverPivot"
        let shaft = node(SCNCylinder(radius: 0.055, height: 1.0),
                         mat(NSColor(calibratedWhite: 0.55, alpha: 1), roughness: 0.3, metalness: 0.8))
        shaft.position.y = 0.5
        let knob = node(SCNSphere(radius: 0.14),
                        mat(NSColor(calibratedRed: 0.95, green: 0.35, blue: 0.20, alpha: 1),
                            roughness: 0.4,
                            emission: NSColor(calibratedRed: 0.5, green: 0.12, blue: 0.04, alpha: 1)))
        knob.position.y = 1.0
        pivot.addChildNode(shaft)
        pivot.addChildNode(knob)
        pivot.eulerAngles.x = -0.35
        root.addChildNode(pivot)
        root.name = "lever"
        return root
    }

    // MARK: Feixe de extracao
    static func beam(radius: Float, height: Float) -> SCNNode {
        let geo = SCNCone(topRadius: CGFloat(radius) * 0.38,
                          bottomRadius: CGFloat(radius),
                          height: CGFloat(height))
        geo.radialSegmentCount = 32
        let m = SCNMaterial()
        m.lightingModel = .constant
        m.diffuse.contents = beamColor.withAlphaComponent(0.05)
        m.emission.contents = beamColor.withAlphaComponent(0.13)
        m.blendMode = .add
        m.isDoubleSided = true
        m.writesToDepthBuffer = false
        m.readsFromDepthBuffer = true
        geo.materials = [m]
        let n = SCNNode(geometry: geo)
        n.position.y = CGFloat(height) / 2
        n.categoryBitMask = 2
        n.name = "beam"

        let ring = SCNNode(geometry: SCNTorus(ringRadius: CGFloat(radius), pipeRadius: 0.06))
        let rm = SCNMaterial()
        rm.lightingModel = .constant
        rm.emission.contents = beamColor.withAlphaComponent(0.75)
        rm.diffuse.contents = beamColor
        ring.geometry?.materials = [rm]
        ring.position.y = CGFloat(-height / 2) + 0.05
        n.addChildNode(ring)

        let spin = SCNAction.repeatForever(.rotateBy(x: 0, y: .pi, z: 0, duration: 6))
        n.runAction(spin)
        return n
    }

    // MARK: Adornos (Bloco 1: insignias de patente, aos olhos do Conselho)
    /// A malha da vaca aponta para +X, entao o anel fica no plano YZ e desloca em +X.
    static func adornment(_ kind: Adornment, bodyRadius: Float, bodyHeight: Float) -> SCNNode {
        let root = SCNNode()
        // Raio maior que o corpo: o adorno tem que ler a distancia, sem interface.
        let r = CGFloat(bodyRadius) * 1.15

        func ring(_ pipe: CGFloat, _ color: NSColor, metal: CGFloat = 0) -> SCNNode {
            let n = node(SCNTorus(ringRadius: r, pipeRadius: pipe),
                         mat(color, roughness: 0.7, metalness: metal))
            n.eulerAngles.z = .pi / 2
            return n
        }

        switch kind {
        case .sino:
            root.addChildNode(ring(0.035, NSColor(calibratedRed: 0.30, green: 0.22, blue: 0.13, alpha: 1)))
            let bell = node(SCNSphere(radius: 0.10),
                            mat(NSColor(calibratedRed: 0.88, green: 0.72, blue: 0.26, alpha: 1),
                                roughness: 0.25, metalness: 0.9,
                                emission: NSColor(calibratedRed: 0.22, green: 0.16, blue: 0.03, alpha: 1)))
            bell.position = SCNVector3(0, -Float(r) * 0.95, 0)
            root.addChildNode(bell)
        case .coleira:
            root.addChildNode(ring(0.05, NSColor(calibratedRed: 0.58, green: 0.14, blue: 0.14, alpha: 1)))
        case .faixa:
            root.addChildNode(ring(0.10, NSColor(calibratedRed: 0.78, green: 0.68, blue: 0.22, alpha: 1)))
        case .brinco:
            let n = node(SCNSphere(radius: 0.055),
                         mat(NSColor(calibratedRed: 0.92, green: 0.86, blue: 0.38, alpha: 1),
                             roughness: 0.2, metalness: 0.9))
            n.position = SCNVector3(Float(r) * 0.5, Float(r) * 0.85, Float(r) * 0.5)
            root.addChildNode(n)
        }

        root.position = SCNVector3(bodyRadius * 0.45, bodyHeight * 0.5, 0)
        return root
    }

    // MARK: Fallbacks caso um .usdz falte
    static func alienFallback() -> SCNNode {
        let root = SCNNode()
        let body = node(SCNCapsule(capRadius: 0.28, height: 1.15), mat(alienColor, roughness: 0.7))
        body.position.y = 0.58
        let head = node(SCNSphere(radius: 0.32), mat(alienColor, roughness: 0.7))
        head.position.y = 1.35
        head.scale = SCNVector3(1, 1.25, 0.9)
        root.addChildNode(body)
        root.addChildNode(head)
        return root
    }

    static func cowFallback() -> SCNNode {
        let root = SCNNode()
        let body = node(SCNBox(width: 0.75, height: 0.85, length: 1.55, chamferRadius: 0.22),
                        mat(NSColor(calibratedWhite: 0.86, alpha: 1), roughness: 0.85))
        body.position.y = 0.95
        root.addChildNode(body)
        for sx in [Float(-0.26), Float(0.26)] {
            for sz in [Float(-0.55), Float(0.55)] {
                let leg = node(SCNBox(width: 0.15, height: 0.55, length: 0.15, chamferRadius: 0.04),
                               mat(NSColor(calibratedWhite: 0.25, alpha: 1)))
                leg.position = SCNVector3(sx, 0.27, sz)
                root.addChildNode(leg)
            }
        }
        let head = node(SCNBox(width: 0.4, height: 0.4, length: 0.5, chamferRadius: 0.12),
                        mat(NSColor(calibratedWhite: 0.82, alpha: 1)))
        head.position = SCNVector3(0, 1.1, 0.95)
        root.addChildNode(head)
        return root
    }

    static func shipFallback() -> SCNNode {
        let root = SCNNode()
        let hull = node(SCNCylinder(radius: 6.5, height: 1.1),
                        mat(NSColor(calibratedRed: 0.24, green: 0.24, blue: 0.32, alpha: 1),
                            roughness: 0.3, metalness: 0.8))
        let dome = node(SCNSphere(radius: 2.6),
                        mat(NSColor(calibratedRed: 0.35, green: 0.85, blue: 0.80, alpha: 0.6),
                            roughness: 0.1,
                            emission: NSColor(calibratedRed: 0.1, green: 0.3, blue: 0.3, alpha: 1)))
        dome.position.y = 0.8
        root.addChildNode(hull)
        root.addChildNode(dome)
        return root
    }
}
