import SceneKit

/// Carrega os .usdz do bundle e normaliza escala e pivo.
/// Os modelos vem do Sketchfab em CC-BY-4.0 — a atribuicao esta em Creditos.swift.
enum AssetLoader {

    private static var cache: [String: SCNNode] = [:]

    /// Retorna um clone pronto para uso, com a base em y = 0 e a altura pedida.
    static func model(_ name: String, height: CGFloat, fallback: () -> SCNNode) -> SCNNode {
        let template: SCNNode
        if let cached = cache[name] {
            template = cached
        } else if let loaded = loadUSDZ(name) {
            cache[name] = loaded
            template = loaded
        } else {
            let node = fallback()
            node.name = "fallback-\(name)"
            return node
        }

        let container = SCNNode()
        for child in template.childNodes { container.addChildNode(child.clone()) }
        normalize(container, toHeight: height, label: name)
        return container
    }

    private static func loadUSDZ(_ name: String) -> SCNNode? {
        let url = Bundle.main.url(forResource: name, withExtension: "usdz", subdirectory: "Assets3D")
            ?? Bundle.main.url(forResource: name, withExtension: "usdz")
        guard let url, let scene = try? SCNScene(url: url, options: [.checkConsistency: false]) else {
            NSLog("[AssetLoader] nao encontrei \(name).usdz — usando geometria procedural")
            return nil
        }
        let root = SCNNode()
        for child in scene.rootNode.childNodes { root.addChildNode(child) }
        return root
    }

    /// Escala uniformemente para a altura desejada e apoia a base em y = 0.
    static func normalize(_ node: SCNNode, toHeight height: CGFloat, label: String = "?") {
        guard let box = worldBounds(of: node) else {
            Debug.log("normalize[\(label)] SEM BOUNDS — modelo fica na escala original!")
            return
        }
        let current = box.max.y - box.min.y
        Debug.log(String(format: "normalize[%@] bbox %.2f x %.2f x %.2f -> escala %.4f",
                         label,
                         box.max.x - box.min.x, current, box.max.z - box.min.z,
                         current > 0.0001 ? Float(height) / Float(current) : -1))
        guard current > 0.0001 else { return }
        let scale = height / current
        node.scale = SCNVector3(scale, scale, scale)
        node.position.y = -box.min.y * scale
    }

    static func worldBounds(of root: SCNNode) -> (min: SCNVector3, max: SCNVector3)? {
        var lo = SCNVector3(Float.greatestFiniteMagnitude, .greatestFiniteMagnitude, .greatestFiniteMagnitude)
        var hi = SCNVector3(-Float.greatestFiniteMagnitude, -.greatestFiniteMagnitude, -.greatestFiniteMagnitude)
        var found = false

        root.enumerateHierarchy { node, _ in
            guard node.geometry != nil else { return }
            let b = node.boundingBox
            guard b.min.x != b.max.x || b.min.y != b.max.y || b.min.z != b.max.z else { return }
            found = true
            for x in [b.min.x, b.max.x] {
                for y in [b.min.y, b.max.y] {
                    for z in [b.min.z, b.max.z] {
                        let p = node.convertPosition(SCNVector3(x, y, z), to: root)
                        lo.x = Swift.min(lo.x, p.x); lo.y = Swift.min(lo.y, p.y); lo.z = Swift.min(lo.z, p.z)
                        hi.x = Swift.max(hi.x, p.x); hi.y = Swift.max(hi.y, p.y); hi.z = Swift.max(hi.z, p.z)
                    }
                }
            }
        }
        return found ? (lo, hi) : nil
    }
}
