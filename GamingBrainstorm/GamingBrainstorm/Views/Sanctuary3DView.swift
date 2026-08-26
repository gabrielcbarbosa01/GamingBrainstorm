//
//  Sanctuary3DView.swift
//  GamingBrainstorm
//
//  Created by Gabriel Barbosa on 25/08/26.
//

import SwiftUI
import SceneKit
import Combine

public struct Sanctuary3DView: View {
    @Bindable var session: GameSession
    
    @State private var scene = SCNScene()
    @State private var cameraNode = SCNNode()
    @State private var animalsRootNode = SCNNode()
    @State private var habitatsRootNode = SCNNode()
    @State private var selectedAnimal: RescuedAnimal?
    
    private let tickTimer = Timer.publish(every: 1.5, on: .main, in: .common).autoconnect()
    
    public init(session: GameSession) {
        self.session = session
    }
    
    public var body: some View {
        ZStack {
            // 1. SceneKit 3D Sanctuary Viewport
            SceneView(
                scene: scene,
                pointOfView: cameraNode,
                options: [.rendersContinuously]
            )
            .ignoresSafeArea()
            
            // 2. Overlay HUD & Controls
            VStack {
                // Sanctuary Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Image(systemName: "house.lodge.fill")
                                .foregroundStyle(.green)
                            Text("Santuário de Preservação 3D")
                                .font(.title3.bold())
                                .foregroundStyle(.white)
                        }
                        
                        Text("\(session.sanctuary.habitats.count) Habitats Ativos • \(session.sanctuary.rescuedAnimals.count) Animais em Reabilitação")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    // Resource Badges
                    HStack(spacing: 12) {
                        resourcePill(icon: "sparkles", value: "\(session.sanctuary.resources.carePoints)", color: .yellow)
                        resourcePill(icon: "drop.fill", value: "\(session.sanctuary.resources.cleanWater)", color: .cyan)
                        resourcePill(icon: "apple.logo", value: "\(session.sanctuary.inventory.fruits)", color: .orange)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.green.opacity(0.4), lineWidth: 1))
                )
                .padding(.horizontal, 18)
                .padding(.top, 10)
                
                Spacer()
                
                // Animal Care Card (If Selected)
                if let animal = selectedAnimal, let species = AnimalSpecies.allSpecies.first(where: { $0.id == animal.speciesId }) {
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(animal.nickname)
                                    .font(.headline.bold())
                                    .foregroundStyle(.yellow)
                                Text("(\(species.commonName))")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                            
                            HStack(spacing: 14) {
                                Label("Saúde: \(Int(animal.health))%", systemImage: "heart.fill")
                                    .foregroundStyle(.green)
                                    .font(.caption2)
                                Label("Fome: \(Int(animal.hunger))%", systemImage: "fork.knife")
                                    .foregroundStyle(.orange)
                                    .font(.caption2)
                                Label("Reabilitação: \(Int(animal.rehabilitationProgress))%", systemImage: "sparkles")
                                    .foregroundStyle(.cyan)
                                    .font(.caption2)
                            }
                        }
                        
                        Spacer()
                        
                        Button {
                            let _ = session.feedAnimal(animalId: animal.id)
                            selectedAnimal = session.sanctuary.rescuedAnimals.first { $0.id == animal.id }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "leaf.fill")
                                Text("Alimentar (+Cuidado)")
                            }
                            .font(.caption.bold())
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(Color.green))
                            .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(.ultraThickMaterial)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.yellow.opacity(0.5), lineWidth: 1))
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                }
            }
        }
        .onAppear {
            setup3DSanctuaryScene()
        }
        .onReceive(tickTimer) { _ in
            updateSanctuary3DAnimals()
        }
    }
    
    private func resourcePill(icon: String, value: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(color)
            Text(value)
                .font(.caption.bold())
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(Color.black.opacity(0.4)))
    }
    
    // MARK: - SceneKit 3D Sanctuary Setup
    private func setup3DSanctuaryScene() {
        scene = SCNScene()
        
        // 1. Camera Node (Angled overview)
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 24, 42)
        cameraNode.eulerAngles = SCNVector3(-0.52, 0, 0)
        scene.rootNode.addChildNode(cameraNode)
        
        // 2. Sunlight
        let sunNode = SCNNode()
        let sun = SCNLight()
        sun.type = .directional
        sun.color = NSColor(red: 1.0, green: 0.98, blue: 0.88, alpha: 1.0)
        sun.castsShadow = true
        sunNode.light = sun
        sunNode.position = SCNVector3(40, 60, 40)
        sunNode.eulerAngles = SCNVector3(-0.95, 0.55, 0)
        scene.rootNode.addChildNode(sunNode)
        
        // 3. Ambient Light
        let ambientNode = SCNNode()
        let ambient = SCNLight()
        ambient.type = .ambient
        ambient.color = NSColor(red: 0.45, green: 0.50, blue: 0.45, alpha: 1.0)
        ambientNode.light = ambient
        scene.rootNode.addChildNode(ambientNode)
        
        // 4. Ground Floor
        let groundGeo = SCNBox(width: 140, height: 1.0, length: 140, chamferRadius: 0.2)
        let groundMat = SCNMaterial()
        groundMat.diffuse.contents = NSColor(red: 0.16, green: 0.38, blue: 0.22, alpha: 1.0)
        groundGeo.materials = [groundMat]
        let groundNode = SCNNode(geometry: groundGeo)
        groundNode.position = SCNVector3(0, -0.5, 0)
        scene.rootNode.addChildNode(groundNode)
        
        // 5. Central Water Pool
        let poolGeo = SCNCylinder(radius: 12, height: 0.3)
        let poolMat = SCNMaterial()
        poolMat.diffuse.contents = NSColor(red: 0.15, green: 0.55, blue: 0.75, alpha: 0.9)
        poolGeo.materials = [poolMat]
        let poolNode = SCNNode(geometry: poolGeo)
        poolNode.position = SCNVector3(0, 0.1, 0)
        scene.rootNode.addChildNode(poolNode)
        
        // 6. Habitats Enclosures
        habitatsRootNode = SCNNode()
        scene.rootNode.addChildNode(habitatsRootNode)
        build3DHabitats()
        
        // 7. Rescued Animals Nodes
        animalsRootNode = SCNNode()
        scene.rootNode.addChildNode(animalsRootNode)
        updateSanctuary3DAnimals()
    }
    
    private func build3DHabitats() {
        habitatsRootNode.childNodes.forEach { $0.removeFromParentNode() }
        
        let habitatPositions: [CGPoint] = [
            CGPoint(x: -30, y: -20),
            CGPoint(x: 30, y: -20),
            CGPoint(x: -30, y: 20),
            CGPoint(x: 30, y: 20)
        ]
        
        for (index, habitat) in session.sanctuary.habitats.enumerated() {
            let pos = habitatPositions[index % habitatPositions.count]
            let habNode = SCNNode()
            habNode.position = SCNVector3(pos.x, 0, pos.y)
            
            // Wooden Fence Posts
            let fenceGeo = SCNCylinder(radius: 0.3, height: 2.2)
            let fenceMat = SCNMaterial()
            fenceMat.diffuse.contents = NSColor(red: 0.45, green: 0.30, blue: 0.18, alpha: 1.0)
            fenceGeo.materials = [fenceMat]
            
            for angle in stride(from: 0.0, to: Double.pi * 2, by: Double.pi / 4) {
                let postNode = SCNNode(geometry: fenceGeo)
                postNode.position = SCNVector3(cos(angle) * 14, 1.1, sin(angle) * 14)
                habNode.addChildNode(postNode)
            }
            
            // Habitat Shelter Canopy
            let shelterGeo = SCNCone(topRadius: 0.2, bottomRadius: 6.0, height: 3.5)
            let shelterMat = SCNMaterial()
            shelterMat.diffuse.contents = NSColor(red: 0.35, green: 0.25, blue: 0.15, alpha: 1.0)
            shelterGeo.materials = [shelterMat]
            let shelterNode = SCNNode(geometry: shelterGeo)
            shelterNode.position = SCNVector3(0, 4.0, 0)
            habNode.addChildNode(shelterNode)
            
            habitatsRootNode.addChildNode(habNode)
        }
    }
    
    private func updateSanctuary3DAnimals() {
        animalsRootNode.childNodes.forEach { $0.removeFromParentNode() }
        
        for (index, animal) in session.sanctuary.rescuedAnimals.enumerated() {
            let animalNode = SCNNode()
            animalNode.name = animal.id.uuidString
            let angle = (Double(index) / Double(max(session.sanctuary.rescuedAnimals.count, 1))) * Double.pi * 2
            let radius = 10.0 + Double(index % 3) * 4.0
            let ax = cos(angle) * radius
            let az = sin(angle) * radius
            animalNode.position = SCNVector3(ax, 1.0, az)
            
            // Billboard Sprite / 3D Sphere for animal
            let sphereGeo = SCNSphere(radius: 1.4)
            let sphereMat = SCNMaterial()
            sphereMat.diffuse.contents = NSColor.systemOrange
            sphereMat.emission.contents = NSColor.systemYellow.withAlphaComponent(0.3)
            sphereGeo.materials = [sphereMat]
            let bodyNode = SCNNode(geometry: sphereGeo)
            
            let hopUp = SCNAction.moveBy(x: 0, y: 0.3, z: 0, duration: 0.6)
            let hopDown = SCNAction.moveBy(x: 0, y: -0.3, z: 0, duration: 0.6)
            bodyNode.runAction(SCNAction.repeatForever(SCNAction.sequence([hopUp, hopDown])))
            animalNode.addChildNode(bodyNode)
            
            animalsRootNode.addChildNode(animalNode)
        }
    }
}
