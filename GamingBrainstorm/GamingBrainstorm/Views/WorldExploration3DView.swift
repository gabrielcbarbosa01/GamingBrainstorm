//
//  WorldExploration3DView.swift
//  GamingBrainstorm
//
//  Created by Gabriel Barbosa on 25/08/26.
//

import SwiftUI
import SceneKit
import Combine

public struct WorldExploration3DView: View {
    @Bindable var session: GameSession
    @State private var showingTransformWheel = false
    @State private var isMoving = false
    @State private var isFacingLeft = false
    @State private var zoomDistance: CGFloat = 34.0
    @State private var previousPlayerPos: CGPoint = .zero
    
    // SceneKit Scene & Nodes
    @State private var scene = SCNScene()
    @State private var playerNode = SCNNode()
    @State private var playerPlaneGeometry = SCNPlane(width: 3.0, height: 3.0)
    @State private var cameraNode = SCNNode()
    @State private var sunLightNode = SCNNode()
    @State private var ambientLightNode = SCNNode()
    @State private var worldPointsRootNode = SCNNode()
    @State private var treesRootNode = SCNNode()
    @State private var bushesRootNode = SCNNode()
    @State private var storyNpcsRootNode = SCNNode()
    @State private var totemsRootNode = SCNNode()
    @State private var enemiesRootNode = SCNNode()
    @State private var ambientFaunaRootNode = SCNNode()
    @State private var weatherParticlesNode = SCNNode()
    @State private var currentFrameIndex = 0
    @State private var runBouncePhase: Double = 0.0
    
    // Monkey sprite frames from assets (Monkey_0 ... Monkey_6)
    private let monkeyFrames = [
        "Monkey_0",
        "Monkey_1",
        "Monkey_2",
        "Monkey_3",
        "Monkey_4",
        "Monkey_5",
        "Monkey_6"
    ]
    
    private let tickTimer = Timer.publish(every: 2.0, on: .main, in: .common).autoconnect()
    private let frameTimer = Timer.publish(every: 0.09, on: .main, in: .common).autoconnect()
    
    var onOpenMenu: (() -> Void)?
    
    public init(session: GameSession, onOpenMenu: (() -> Void)? = nil) {
        self.session = session
        self.onOpenMenu = onOpenMenu
    }
    
    public var body: some View {
        ZStack {
            // 1. SceneKit 3D Viewport
            SceneView(
                scene: scene,
                pointOfView: cameraNode,
                options: [.rendersContinuously]
            )
            .ignoresSafeArea()
            
            // 2. HUD & Overlays
            VStack {
                topUnifiedCompassBar
                
                // Timed Challenge Banner (Gumgum Inspired)
                if let challengeMsg = session.storyEngine.activeChallengeMessage,
                   let frac = session.storyEngine.activeChallengeFraction {
                    HStack(spacing: 12) {
                        Image(systemName: session.storyEngine.activeChallengeIcon ?? "timer")
                            .font(.title3.bold())
                            .foregroundStyle(session.storyEngine.isChallengeUrgent ? .red : .orange)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(challengeMsg)
                                .font(.subheadline.bold())
                                .foregroundStyle(.white)
                            
                            GeometryReader { g in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(Color.white.opacity(0.25))
                                    Capsule().fill(session.storyEngine.isChallengeUrgent ? Color.red : Color.orange)
                                        .frame(width: max(0, g.size.width * CGFloat(frac)))
                                }
                            }
                            .frame(height: 6)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 14).fill(.ultraThickMaterial))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(session.storyEngine.isChallengeUrgent ? Color.red : Color.orange, lineWidth: 1.5))
                    .padding(.top, 4)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                HStack(alignment: .top) {
                    StoryQuestTrackerCard(session: session)
                        .padding(.leading, 16)
                        .padding(.top, 6)
                    
                    Spacer()
                    
                    MiniMapRadarView(session: session)
                        .padding(.trailing, 16)
                        .padding(.top, 6)
                }
                
                Spacer()
                bottomInteractiveHUD
            }
            
            // 3. Story Dialogue Modal Overlay
            StoryDialogueView(session: session)
                .zIndex(9000)
            
            // 4. Transformation Wheel Modal
            if showingTransformWheel {
                TransformationWheelView(session: session, isPresented: $showingTransformWheel)
                    .transition(.opacity.combined(with: .scale(0.95)))
                    .zIndex(9999)
            }
        }
        .onAppear {
            setup3DScene()
        }
        .onChange(of: session.currentBiome) { _, newBiome in
            updateBiomeAtmosphere(for: newBiome)
            updateWeatherParticles(for: newBiome)
        }
        .onChange(of: session.playerPosition) { _, newPos in
            updatePlayer3DPosition(newPos)
        }
        .onChange(of: session.playerTransformation.activeSpeciesId) { _, _ in
            updatePlayerAppearance()
        }
        .onReceive(tickTimer) { _ in
            session.simulationTick()
            build3DWorldPoints()
            build3DBiomeTotems()
            updateLightingForTimeOfDay()
            updateWeatherParticles(for: session.currentBiome)
        }
        .onReceive(frameTimer) { _ in
            animateCharacterFrame()
            update3DEnemies()
            update3DAmbientFauna()
        }
    }
    
    // MARK: - SceneKit 3D Scene Initialization
    private func setup3DScene() {
        scene = SCNScene()
        
        // 1. Camera Node (Isometric follow angle)
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.zNear = 0.5
        cameraNode.camera?.zFar = 600.0
        let targetX = CGFloat(session.playerPosition.x * 0.8)
        let targetZ = CGFloat(session.playerPosition.y * 0.8)
        cameraNode.position = SCNVector3(targetX, 22, targetZ + zoomDistance)
        cameraNode.eulerAngles = SCNVector3(-0.64, 0, 0)
        scene.rootNode.addChildNode(cameraNode)
        
        // 2. Directional Sun Light with Shadows
        sunLightNode = SCNNode()
        let sun = SCNLight()
        sun.type = .directional
        sun.color = NSColor(red: 1.0, green: 0.98, blue: 0.88, alpha: 1.0)
        sun.castsShadow = true
        sun.shadowRadius = 4.5
        sun.shadowSampleCount = 16
        sun.shadowMapSize = CGSize(width: 2048, height: 2048)
        sunLightNode.light = sun
        sunLightNode.position = SCNVector3(80, 120, 80)
        sunLightNode.eulerAngles = SCNVector3(-0.95, 0.55, 0)
        scene.rootNode.addChildNode(sunLightNode)
        
        // 3. Ambient Light
        ambientLightNode = SCNNode()
        let ambient = SCNLight()
        ambient.type = .ambient
        ambient.color = NSColor(red: 0.38, green: 0.45, blue: 0.38, alpha: 1.0)
        ambientLightNode.light = ambient
        scene.rootNode.addChildNode(ambientLightNode)
        
        // 4. Grand Unified 3D Open World Multi-Biome Terrain
        buildUnified3DTerrain()
        
        // 5. Long Flowing Continental River System
        buildContinental3DRiver()
        
        // 6. Trees Across All Biomes
        treesRootNode = SCNNode()
        scene.rootNode.addChildNode(treesRootNode)
        build3DForest()
        
        // 7. Bushes Across All Biomes
        bushesRootNode = SCNNode()
        scene.rootNode.addChildNode(bushesRootNode)
        build3DBushes()
        
        // 8. Interactive World Points for All Biomes
        worldPointsRootNode = SCNNode()
        scene.rootNode.addChildNode(worldPointsRootNode)
        build3DWorldPoints()
        
        // 9. Friendly Story NPCs
        storyNpcsRootNode = SCNNode()
        scene.rootNode.addChildNode(storyNpcsRootNode)
        build3DStoryNPCs()
        
        // 10. Ancient Biome Totems
        totemsRootNode = SCNNode()
        scene.rootNode.addChildNode(totemsRootNode)
        build3DBiomeTotems()
        
        // 11. Open World Enemies
        enemiesRootNode = SCNNode()
        scene.rootNode.addChildNode(enemiesRootNode)
        build3DEnemies()
        
        // 12. Free Roaming Ambient Wild Fauna
        ambientFaunaRootNode = SCNNode()
        scene.rootNode.addChildNode(ambientFaunaRootNode)
        build3DAmbientFauna()
        
        // 13. Weather & Atmospheric Particles
        weatherParticlesNode = SCNNode()
        scene.rootNode.addChildNode(weatherParticlesNode)
        updateWeatherParticles(for: session.currentBiome)
        
        // 14. Player Character Node
        build3DPlayerNode()
        
        // Update atmosphere & lighting for initial player location
        updateBiomeAtmosphere(for: session.currentBiome)
        updateLightingForTimeOfDay()
    }
    
    // MARK: - Grand Unified Multi-Biome 3D Terrain
    private func buildUnified3DTerrain() {
        // Base continental floor (700 x 700 units)
        let mainGroundGeo = SCNBox(width: 650, height: 1.5, length: 650, chamferRadius: 0.5)
        let groundMat = SCNMaterial()
        groundMat.diffuse.contents = NSColor(red: 0.18, green: 0.34, blue: 0.20, alpha: 1.0)
        groundMat.roughness.contents = 0.92
        mainGroundGeo.materials = [groundMat]
        
        let groundNode = SCNNode(geometry: mainGroundGeo)
        groundNode.position = SCNVector3(0, -0.75, 0)
        groundNode.name = "ContinentalGround"
        scene.rootNode.addChildNode(groundNode)
        
        // Biome Terrain Sectors (Distinct Geological Formations)
        let biomeSectors: [(CGFloat, CGFloat, CGFloat, CGFloat, NSColor)] = [
            // Amazônia (Noroeste): Floresta equatorial densa
            (-150, -180, 200, 190, NSColor(red: 0.08, green: 0.28, blue: 0.16, alpha: 1.0)),
            // Caatinga (Nordeste): Sertão árido avermelhado
            (150, -180, 200, 190, NSColor(red: 0.52, green: 0.44, blue: 0.28, alpha: 1.0)),
            // Pantanal (Centro-Oeste): Bacia alagável verde-azulada
            (-150, 0, 200, 170, NSColor(red: 0.18, green: 0.36, blue: 0.32, alpha: 1.0)),
            // Cerrado (Centro-Leste): Savana de solo ocre
            (140, 0, 200, 170, NSColor(red: 0.45, green: 0.32, blue: 0.20, alpha: 1.0)),
            // Mata Atlântica (Sudeste): Relevo montanhoso exuberante
            (80, 140, 220, 140, NSColor(red: 0.14, green: 0.38, blue: 0.20, alpha: 1.0)),
            // Pampa (Sul): Coxilhas de campos abertos
            (0, 250, 320, 150, NSColor(red: 0.30, green: 0.42, blue: 0.22, alpha: 1.0))
        ]
        
        for (sx, sz, w, l, color) in biomeSectors {
            let sectorGeo = SCNBox(width: w, height: 1.6, length: l, chamferRadius: 1.0)
            let sectorMat = SCNMaterial()
            sectorMat.diffuse.contents = color
            sectorMat.roughness.contents = 0.90
            sectorGeo.materials = [sectorMat]
            
            let sectorNode = SCNNode(geometry: sectorGeo)
            sectorNode.position = SCNVector3(sx, -0.7, sz)
            scene.rootNode.addChildNode(sectorNode)
        }
        
        // Regional Elevation Hills & Mountain Formations
        let hillFormations: [(CGFloat, CGFloat, CGFloat, CGFloat, NSColor)] = [
            // Amazônia Hills
            (-180, -220, 28, 7.0, NSColor(red: 0.10, green: 0.32, blue: 0.18, alpha: 1.0)),
            (-110, -250, 32, 8.5, NSColor(red: 0.08, green: 0.30, blue: 0.16, alpha: 1.0)),
            // Caatinga Plateaus (Serrotes)
            (170, -220, 35, 9.0, NSColor(red: 0.58, green: 0.46, blue: 0.30, alpha: 1.0)),
            (210, -150, 26, 6.5, NSColor(red: 0.54, green: 0.42, blue: 0.26, alpha: 1.0)),
            // Cerrado Chapadas
            (160, -30, 30, 6.0, NSColor(red: 0.48, green: 0.35, blue: 0.22, alpha: 1.0)),
            (190, 40, 24, 5.5, NSColor(red: 0.44, green: 0.31, blue: 0.19, alpha: 1.0)),
            // Mata Atlântica Serras
            (110, 130, 36, 11.0, NSColor(red: 0.16, green: 0.42, blue: 0.22, alpha: 1.0)),
            (160, 170, 40, 13.0, NSColor(red: 0.12, green: 0.36, blue: 0.18, alpha: 1.0)),
            // Pampa Coxilhas (Colinas Suaves)
            (-80, 260, 38, 4.5, NSColor(red: 0.32, green: 0.46, blue: 0.24, alpha: 1.0)),
            (90, 290, 42, 5.0, NSColor(red: 0.28, green: 0.40, blue: 0.20, alpha: 1.0))
        ]
        
        for (hx, hz, radius, height, color) in hillFormations {
            let hillGeo = SCNCylinder(radius: radius, height: height)
            let hillMat = SCNMaterial()
            hillMat.diffuse.contents = color
            hillGeo.materials = [hillMat]
            
            let hillNode = SCNNode(geometry: hillGeo)
            hillNode.position = SCNVector3(hx, height / 2 - 0.5, hz)
            scene.rootNode.addChildNode(hillNode)
        }
    }
    
    // MARK: - Continental 3D Flowing River System
    private func buildContinental3DRiver() {
        let riverContainer = SCNNode()
        riverContainer.name = "ContinentalRiver"
        
        // Straight North-South River Running Flat on the Ground Across the Continent
        let riverLength: CGFloat = 650.0
        let riverWidth: CGFloat = 28.0
        let riverX: CGFloat = -15.0
        
        // 1. Riverbed Sand & Shoreline Trench (Flat on ground)
        let bedGeo = SCNPlane(width: riverWidth + 8.0, height: riverLength)
        let bedMat = SCNMaterial()
        bedMat.diffuse.contents = NSColor(red: 0.18, green: 0.30, blue: 0.24, alpha: 1.0)
        bedGeo.materials = [bedMat]
        let bedNode = SCNNode(geometry: bedGeo)
        bedNode.eulerAngles = SCNVector3(-CGFloat.pi / 2, 0, 0)
        bedNode.position = SCNVector3(riverX, 0.02, 0)
        riverContainer.addChildNode(bedNode)
        
        // 2. Translucent River Water Surface (Flat on ground)
        let riverGeo = SCNPlane(width: riverWidth, height: riverLength)
        let waterMat = SCNMaterial()
        waterMat.diffuse.contents = NSColor(red: 0.14, green: 0.65, blue: 0.82, alpha: 0.86)
        waterMat.specular.contents = NSColor.white
        waterMat.shininess = 95
        waterMat.isDoubleSided = true
        waterMat.transparency = 0.85
        riverGeo.materials = [waterMat]
        
        let riverNode = SCNNode(geometry: riverGeo)
        riverNode.eulerAngles = SCNVector3(-CGFloat.pi / 2, 0, 0)
        riverNode.position = SCNVector3(riverX, 0.06, 0)
        riverNode.name = "RiverWater"
        riverContainer.addChildNode(riverNode)
        
        // 3. Flowing Water Current & Foam Streaks (Downstream flow)
        for i in 0..<35 {
            let foamLength = CGFloat.random(in: 18...40)
            let foamWidth = CGFloat.random(in: 1.6...3.5)
            let foamGeo = SCNPlane(width: foamWidth, height: foamLength)
            let foamMat = SCNMaterial()
            foamMat.diffuse.contents = NSColor(red: 0.92, green: 0.98, blue: 1.0, alpha: 0.45)
            foamMat.isDoubleSided = true
            foamMat.transparency = 0.50
            foamGeo.materials = [foamMat]
            
            let foamNode = SCNNode(geometry: foamGeo)
            let offsetX = CGFloat.random(in: -10...10)
            let startY = CGFloat(-300 + Double(i) * 18.0)
            foamNode.position = SCNVector3(offsetX, startY, 0.02)
            
            // Continuous downstream flow
            let flowDistance: CGFloat = riverLength
            let duration: Double = Double.random(in: 6.0...9.0)
            let flowAction = SCNAction.moveBy(x: 0, y: flowDistance, z: 0, duration: duration)
            let resetAction = SCNAction.moveBy(x: 0, y: -flowDistance, z: 0, duration: 0)
            let loop = SCNAction.repeatForever(SCNAction.sequence([flowAction, resetAction]))
            foamNode.runAction(loop)
            
            riverNode.addChildNode(foamNode)
        }
        
        // 4. Stepping Stones Bridges (Horizontal Crossing Points across the straight river)
        let crossingZPositions: [CGFloat] = [-200.0, -70.0, 60.0, 190.0]
        
        for cz in crossingZPositions {
            for s in -3...3 {
                let stoneGeo = SCNCylinder(radius: 1.9, height: 0.55)
                let stoneMat = SCNMaterial()
                stoneMat.diffuse.contents = NSColor(red: 0.44, green: 0.42, blue: 0.38, alpha: 1.0)
                stoneGeo.materials = [stoneMat]
                
                let stoneNode = SCNNode(geometry: stoneGeo)
                stoneNode.position = SCNVector3(riverX + CGFloat(s) * 4.2, 0.16, cz)
                stoneNode.castsShadow = true
                riverContainer.addChildNode(stoneNode)
            }
        }
        
        scene.rootNode.addChildNode(riverContainer)
    }
    
    // MARK: - 3D Forest Distributed Across All Biomes
    private func build3DForest() {
        treesRootNode.childNodes.forEach { $0.removeFromParentNode() }
        
        let sharedTreeMat = SCNMaterial()
        if let image = NSImage(named: "TreeImage") {
            sharedTreeMat.diffuse.contents = image
        } else {
            sharedTreeMat.diffuse.contents = NSColor(red: 0.1, green: 0.5, blue: 0.2, alpha: 1.0)
        }
        sharedTreeMat.isDoubleSided = true
        sharedTreeMat.transparent.contents = sharedTreeMat.diffuse.contents
        
        for (index, tree) in UnifiedOpenWorldEnvironment.sharedTrees.enumerated() {
            let treeContainer = SCNNode()
            let tx = CGFloat(tree.x * 0.8)
            let tz = CGFloat(tree.y * 0.8)
            treeContainer.position = SCNVector3(tx, 0, tz)
            
            let planeW: CGFloat = 5.5 * CGFloat(tree.scale)
            let planeH: CGFloat = 7.5 * CGFloat(tree.scale)
            
            let treePlaneGeo = SCNPlane(width: planeW, height: planeH)
            treePlaneGeo.materials = [sharedTreeMat]
            
            // Plane 1
            let plane1 = SCNNode(geometry: treePlaneGeo)
            plane1.position = SCNVector3(0, planeH / 2, 0)
            plane1.castsShadow = true
            treeContainer.addChildNode(plane1)
            
            // Plane 2
            let plane2 = SCNNode(geometry: treePlaneGeo)
            plane2.position = SCNVector3(0, planeH / 2, 0)
            plane2.eulerAngles = SCNVector3(0, CGFloat.pi / 2, 0)
            plane2.castsShadow = true
            treeContainer.addChildNode(plane2)
            
            // Wind Swaying
            let swayZ: CGFloat = CGFloat(0.022 + Double((index % 5)) * 0.003)
            let swayDuration: Double = 2.8 + Double((index % 7)) * 0.25
            let swayRight = SCNAction.rotateTo(x: 0, y: 0, z: swayZ, duration: swayDuration)
            let swayLeft = SCNAction.rotateTo(x: 0, y: 0, z: -swayZ, duration: swayDuration)
            swayRight.timingMode = .easeInEaseOut
            swayLeft.timingMode = .easeInEaseOut
            let swaySequence = SCNAction.sequence([swayRight, swayLeft])
            treeContainer.runAction(SCNAction.repeatForever(swaySequence))
            
            treesRootNode.addChildNode(treeContainer)
        }
    }
    
    // MARK: - 3D Bushes Distributed Across All Biomes
    private func build3DBushes() {
        bushesRootNode.childNodes.forEach { $0.removeFromParentNode() }
        
        let sharedBushMat = SCNMaterial()
        if let image = NSImage(named: "BushImage") {
            sharedBushMat.diffuse.contents = image
        } else {
            sharedBushMat.diffuse.contents = NSColor(red: 0.16, green: 0.44, blue: 0.20, alpha: 1.0)
        }
        sharedBushMat.isDoubleSided = true
        sharedBushMat.transparent.contents = sharedBushMat.diffuse.contents
        
        for (index, bush) in UnifiedOpenWorldEnvironment.sharedBushes.enumerated() {
            let bushContainer = SCNNode()
            let bx = CGFloat(bush.x * 0.8)
            let bz = CGFloat(bush.y * 0.8)
            bushContainer.position = SCNVector3(bx, 0, bz)
            
            let planeW: CGFloat = 3.8 * CGFloat(bush.scale)
            let planeH: CGFloat = 3.0 * CGFloat(bush.scale)
            
            let bushPlaneGeo = SCNPlane(width: planeW, height: planeH)
            bushPlaneGeo.materials = [sharedBushMat]
            
            // Plane 1
            let plane1 = SCNNode(geometry: bushPlaneGeo)
            plane1.position = SCNVector3(0, planeH / 2, 0)
            plane1.castsShadow = true
            bushContainer.addChildNode(plane1)
            
            // Plane 2
            let plane2 = SCNNode(geometry: bushPlaneGeo)
            plane2.position = SCNVector3(0, planeH / 2, 0)
            plane2.eulerAngles = SCNVector3(0, CGFloat.pi / 2, 0)
            plane2.castsShadow = true
            bushContainer.addChildNode(plane2)
            
            // Rustle
            let rustleDuration = 2.5 + Double(index % 5) * 0.3
            let rustleRight = SCNAction.rotateTo(x: 0, y: 0, z: CGFloat(0.022), duration: rustleDuration)
            let rustleLeft = SCNAction.rotateTo(x: 0, y: 0, z: -CGFloat(0.022), duration: rustleDuration)
            rustleRight.timingMode = .easeInEaseOut
            rustleLeft.timingMode = .easeInEaseOut
            let rustleSeq = SCNAction.sequence([rustleRight, rustleLeft])
            bushContainer.runAction(SCNAction.repeatForever(rustleSeq))
            
            bushesRootNode.addChildNode(bushContainer)
        }
    }
    
    // MARK: - 3D Interactive World Points
    private func build3DWorldPoints() {
        worldPointsRootNode.childNodes.forEach { $0.removeFromParentNode() }
        
        for point in session.worldPoints {
            let pointNode = SCNNode()
            let wx = CGFloat(point.x * 0.8)
            let wz = CGFloat(point.y * 0.8)
            pointNode.position = SCNVector3(wx, 0.2, wz)
            
            // Floating beacon sphere
            let beaconGeo = SCNSphere(radius: 1.1)
            let beaconMat = SCNMaterial()
            let isDistress = point.interactionType == .animalInDistress
            beaconMat.diffuse.contents = point.isResolved ? NSColor.systemGray : (isDistress ? NSColor.systemRed : NSColor.systemOrange)
            beaconMat.emission.contents = point.isResolved ? NSColor.black : (isDistress ? NSColor.systemRed.withAlphaComponent(0.6) : NSColor.systemOrange.withAlphaComponent(0.6))
            beaconGeo.materials = [beaconMat]
            
            let beaconNode = SCNNode(geometry: beaconGeo)
            beaconNode.position = SCNVector3(0, 2.4, 0)
            
            let moveUp = SCNAction.moveBy(x: 0, y: 0.4, z: 0, duration: 1.2)
            let moveDown = SCNAction.moveBy(x: 0, y: -0.4, z: 0, duration: 1.2)
            let sequence = SCNAction.sequence([moveUp, moveDown])
            beaconNode.runAction(SCNAction.repeatForever(sequence))
            pointNode.addChildNode(beaconNode)
            
            // Ground Ring
            let ringGeo = SCNTorus(ringRadius: 2.0, pipeRadius: 0.09)
            let ringMat = SCNMaterial()
            ringMat.diffuse.contents = isDistress ? NSColor.systemRed : NSColor.systemYellow
            ringGeo.materials = [ringMat]
            let ringNode = SCNNode(geometry: ringGeo)
            pointNode.addChildNode(ringNode)
            
            worldPointsRootNode.addChildNode(pointNode)
        }
    }
    
    // MARK: - 3D Story Friendly NPCs
    private func build3DStoryNPCs() {
        storyNpcsRootNode.childNodes.forEach { $0.removeFromParentNode() }
        
        for npc in session.storyEngine.npcs {
            let npcNode = SCNNode()
            let nx = CGFloat(npc.position.x * 0.8)
            let nz = CGFloat(npc.position.y * 0.8)
            npcNode.position = SCNVector3(nx, 0.2, nz)
            
            // Glowing Sanctuary Pillar Base
            let baseGeo = SCNCylinder(radius: 1.5, height: 2.2)
            let baseMat = SCNMaterial()
            baseMat.diffuse.contents = NSColor.systemTeal.withAlphaComponent(0.8)
            baseMat.emission.contents = NSColor.systemTeal.withAlphaComponent(0.4)
            baseGeo.materials = [baseMat]
            let baseNode = SCNNode(geometry: baseGeo)
            baseNode.position = SCNVector3(0, 1.1, 0)
            npcNode.addChildNode(baseNode)
            
            // Hovering holographic orb
            let orbGeo = SCNSphere(radius: 0.9)
            let orbMat = SCNMaterial()
            orbMat.diffuse.contents = NSColor.systemYellow
            orbMat.emission.contents = NSColor.systemYellow.withAlphaComponent(0.6)
            orbGeo.materials = [orbMat]
            let orbNode = SCNNode(geometry: orbGeo)
            orbNode.position = SCNVector3(0, 3.2, 0)
            
            let floatUp = SCNAction.moveBy(x: 0, y: 0.3, z: 0, duration: 1.4)
            let floatDown = SCNAction.moveBy(x: 0, y: -0.3, z: 0, duration: 1.4)
            orbNode.runAction(SCNAction.repeatForever(SCNAction.sequence([floatUp, floatDown])))
            npcNode.addChildNode(orbNode)
            
            storyNpcsRootNode.addChildNode(npcNode)
        }
    }
    
    // MARK: - 3D Ancient Biome Totems
    private func build3DBiomeTotems() {
        totemsRootNode.childNodes.forEach { $0.removeFromParentNode() }
        
        for totem in session.storyEngine.totems {
            let totemNode = SCNNode()
            let tx = CGFloat(totem.position.x * 0.8)
            let tz = CGFloat(totem.position.y * 0.8)
            totemNode.position = SCNVector3(tx, 0.1, tz)
            
            // Ancient Stone Monolith
            let stoneGeo = SCNCylinder(radius: 2.2, height: 6.5)
            let stoneMat = SCNMaterial()
            stoneMat.diffuse.contents = totem.isPurified ? NSColor(red: 0.2, green: 0.6, blue: 0.3, alpha: 1.0) : NSColor(red: 0.35, green: 0.30, blue: 0.28, alpha: 1.0)
            stoneGeo.materials = [stoneMat]
            let stoneNode = SCNNode(geometry: stoneGeo)
            stoneNode.position = SCNVector3(0, 3.25, 0)
            totemNode.addChildNode(stoneNode)
            
            // Energy Aura Torus
            let auraGeo = SCNTorus(ringRadius: 3.2, pipeRadius: 0.25)
            let auraMat = SCNMaterial()
            auraMat.diffuse.contents = totem.isPurified ? NSColor.systemGreen : NSColor.systemPurple
            auraMat.emission.contents = totem.isPurified ? NSColor.systemGreen.withAlphaComponent(0.8) : NSColor.systemPurple.withAlphaComponent(0.7)
            auraGeo.materials = [auraMat]
            let auraNode = SCNNode(geometry: auraGeo)
            auraNode.position = SCNVector3(0, 4.5, 0)
            
            let rotateAura = SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 4.0)
            auraNode.runAction(SCNAction.repeatForever(rotateAura))
            totemNode.addChildNode(auraNode)
            
            totemsRootNode.addChildNode(totemNode)
        }
    }
    
    // MARK: - 3D Open World Enemies
    private func build3DEnemies() {
        enemiesRootNode.childNodes.forEach { $0.removeFromParentNode() }
        
        for enemy in session.storyEngine.enemies {
            let enemyNode = SCNNode()
            enemyNode.name = enemy.id
            let ex = CGFloat(enemy.position.x * 0.8)
            let ez = CGFloat(enemy.position.y * 0.8)
            enemyNode.position = SCNVector3(ex, 0.1, ez)
            
            switch enemy.type {
            case .poacher:
                // Humanoid body
                let bodyGeo = SCNCylinder(radius: 1.2, height: 3.2)
                let bodyMat = SCNMaterial()
                bodyMat.diffuse.contents = NSColor.systemBrown
                bodyGeo.materials = [bodyMat]
                let bodyNode = SCNNode(geometry: bodyGeo)
                bodyNode.position = SCNVector3(0, 1.6, 0)
                enemyNode.addChildNode(bodyNode)
                
                // Flashlight cone on ground
                let coneGeo = SCNCone(topRadius: 0.2, bottomRadius: 2.8, height: 6.0)
                let coneMat = SCNMaterial()
                coneMat.diffuse.contents = NSColor.systemYellow.withAlphaComponent(0.35)
                coneMat.isDoubleSided = true
                coneMat.transparency = 0.45
                coneGeo.materials = [coneMat]
                let coneNode = SCNNode(geometry: coneGeo)
                coneNode.eulerAngles = SCNVector3(CGFloat.pi / 2, 0, 0)
                coneNode.position = SCNVector3(0, 0.3, 3.5)
                enemyNode.addChildNode(coneNode)
                
            case .nestPoacher:
                // Saqueador de ninhos com caixa nas costas e círculo de alerta
                let bodyGeo = SCNCylinder(radius: 1.2, height: 3.2)
                let bodyMat = SCNMaterial()
                bodyMat.diffuse.contents = NSColor.systemOrange
                bodyGeo.materials = [bodyMat]
                let bodyNode = SCNNode(geometry: bodyGeo)
                bodyNode.position = SCNVector3(0, 1.6, 0)
                enemyNode.addChildNode(bodyNode)
                
                // Crate on back
                let crateGeo = SCNBox(width: 1.4, height: 1.4, length: 1.2, chamferRadius: 0.1)
                let crateMat = SCNMaterial()
                crateMat.diffuse.contents = NSColor.brown
                crateGeo.materials = [crateMat]
                let crateNode = SCNNode(geometry: crateGeo)
                crateNode.position = SCNVector3(0, 2.0, -1.0)
                enemyNode.addChildNode(crateNode)
                
                // Pulsing Warning Circle
                let ringGeo = SCNTorus(ringRadius: 3.5, pipeRadius: 0.12)
                let ringMat = SCNMaterial()
                ringMat.diffuse.contents = NSColor.systemOrange.withAlphaComponent(0.7)
                ringMat.emission.contents = NSColor.systemOrange.withAlphaComponent(0.5)
                ringGeo.materials = [ringMat]
                let ringNode = SCNNode(geometry: ringGeo)
                ringNode.position = SCNVector3(0, 0.1, 0)
                enemyNode.addChildNode(ringNode)
                
            case .chainsawCrew:
                // Madeireiro com motosserra
                let bodyGeo = SCNCylinder(radius: 1.2, height: 3.2)
                let bodyMat = SCNMaterial()
                bodyMat.diffuse.contents = NSColor.darkGray
                bodyGeo.materials = [bodyMat]
                let bodyNode = SCNNode(geometry: bodyGeo)
                bodyNode.position = SCNVector3(0, 1.6, 0)
                enemyNode.addChildNode(bodyNode)
                
                // Chainsaw blade
                let bladeGeo = SCNBox(width: 0.35, height: 0.6, length: 2.8, chamferRadius: 0.05)
                let bladeMat = SCNMaterial()
                bladeMat.diffuse.contents = NSColor.lightGray
                bladeMat.metalness.contents = 0.9
                bladeGeo.materials = [bladeMat]
                let bladeNode = SCNNode(geometry: bladeGeo)
                bladeNode.position = SCNVector3(0.8, 1.4, 1.6)
                enemyNode.addChildNode(bladeNode)
                
            case .wildfireEntity:
                // Blazing Flame Pillar
                let flameGeo = SCNCone(topRadius: 0.1, bottomRadius: 2.4, height: 4.5)
                let flameMat = SCNMaterial()
                flameMat.diffuse.contents = NSColor.systemOrange
                flameMat.emission.contents = NSColor.systemRed.withAlphaComponent(0.85)
                flameGeo.materials = [flameMat]
                let flameNode = SCNNode(geometry: flameGeo)
                flameNode.position = SCNVector3(0, 2.25, 0)
                
                let scaleUp = SCNAction.scale(to: 1.15, duration: 0.4)
                let scaleDown = SCNAction.scale(to: 0.85, duration: 0.4)
                flameNode.runAction(SCNAction.repeatForever(SCNAction.sequence([scaleUp, scaleDown])))
                enemyNode.addChildNode(flameNode)
                
            case .malhadeiraNet:
                // Rede predatória submersa no leito do rio
                let netGeo = SCNBox(width: 14.0, height: 0.06, length: 18.0, chamferRadius: 0.0)
                let netMat = SCNMaterial()
                netMat.diffuse.contents = NSColor(red: 0.1, green: 0.35, blue: 0.4, alpha: 0.75)
                netMat.isDoubleSided = true
                netMat.transparency = 0.75
                netGeo.materials = [netMat]
                let netNode = SCNNode(geometry: netGeo)
                netNode.position = SCNVector3(0, 0.04, 0)
                enemyNode.addChildNode(netNode)
                
                // 4 Floating buoy markers
                let buoyPositions: [(Float, Float)] = [(-6, -8), (6, -8), (-6, 8), (6, 8)]
                for (bx, bz) in buoyPositions {
                    let buoyGeo = SCNSphere(radius: 0.6)
                    let buoyMat = SCNMaterial()
                    buoyMat.diffuse.contents = NSColor.cyan
                    buoyMat.emission.contents = NSColor.cyan.withAlphaComponent(0.6)
                    buoyGeo.materials = [buoyMat]
                    let buoyNode = SCNNode(geometry: buoyGeo)
                    buoyNode.position = SCNVector3(bx, 0.4, bz)
                    enemyNode.addChildNode(buoyNode)
                }
                
            case .plowTractor:
                // Trator agrícola com lâmina de arado pesada
                let baseGeo = SCNBox(width: 4.8, height: 3.2, length: 5.8, chamferRadius: 0.4)
                let baseMat = SCNMaterial()
                baseMat.diffuse.contents = NSColor(red: 0.25, green: 0.35, blue: 0.22, alpha: 1.0)
                baseGeo.materials = [baseMat]
                let baseNode = SCNNode(geometry: baseGeo)
                baseNode.position = SCNVector3(0, 1.6, 0)
                enemyNode.addChildNode(baseNode)
                
                // Furrow Plow Blade in front
                let bladeGeo = SCNBox(width: 5.6, height: 1.6, length: 0.8, chamferRadius: 0.1)
                let bladeMat = SCNMaterial()
                bladeMat.diffuse.contents = NSColor.darkGray
                bladeMat.metalness.contents = 0.8
                bladeGeo.materials = [bladeMat]
                let bladeNode = SCNNode(geometry: bladeGeo)
                bladeNode.position = SCNVector3(0, 0.8, 3.4)
                enemyNode.addChildNode(bladeNode)
                
            case .surveillanceDrone:
                // Hovering Sphere with Red Scanner Cone
                let droneGeo = SCNSphere(radius: 1.2)
                let droneMat = SCNMaterial()
                droneMat.diffuse.contents = NSColor.systemGray
                droneMat.emission.contents = NSColor.systemRed.withAlphaComponent(0.7)
                droneGeo.materials = [droneMat]
                let droneBody = SCNNode(geometry: droneGeo)
                droneBody.position = SCNVector3(0, 4.2, 0)
                enemyNode.addChildNode(droneBody)
                
                // Red Scan Circle
                let scanGeo = SCNCylinder(radius: 3.5, height: 0.1)
                let scanMat = SCNMaterial()
                scanMat.diffuse.contents = NSColor.systemRed.withAlphaComponent(0.3)
                scanMat.emission.contents = NSColor.systemRed.withAlphaComponent(0.4)
                scanGeo.materials = [scanMat]
                let scanNode = SCNNode(geometry: scanGeo)
                scanNode.position = SCNVector3(0, 0.05, 0)
                enemyNode.addChildNode(scanNode)
            }
            
            enemiesRootNode.addChildNode(enemyNode)
        }
        
        // 4. Harpia Ancestral 3D Node (if summoned)
        if session.storyEngine.isHarpiaSummoned {
            let harpiaNode = SCNNode()
            harpiaNode.name = "harpia_ancestral"
            harpiaNode.position = SCNVector3(0, 0.1, 0)
            
            // Perch rock
            let rockGeo = SCNBox(width: 6.0, height: 3.0, length: 6.0, chamferRadius: 0.8)
            let rockMat = SCNMaterial()
            rockMat.diffuse.contents = NSColor.gray
            rockGeo.materials = [rockMat]
            let rockNode = SCNNode(geometry: rockGeo)
            rockNode.position = SCNVector3(0, 1.5, 0)
            harpiaNode.addChildNode(rockNode)
            
            // Royal Eagle Body
            let eagleGeo = SCNCylinder(radius: 1.6, height: 4.2)
            let eagleMat = SCNMaterial()
            eagleMat.diffuse.contents = NSColor(red: 0.28, green: 0.30, blue: 0.32, alpha: 1.0)
            eagleGeo.materials = [eagleMat]
            let eagleNode = SCNNode(geometry: eagleGeo)
            eagleNode.position = SCNVector3(0, 4.8, 0)
            harpiaNode.addChildNode(eagleNode)
            
            // Colossal Wings
            let wingsGeo = SCNBox(width: 8.5, height: 0.3, length: 3.0, chamferRadius: 0.1)
            let wingsMat = SCNMaterial()
            wingsMat.diffuse.contents = NSColor(red: 0.9, green: 0.8, blue: 0.4, alpha: 1.0)
            wingsMat.emission.contents = NSColor.yellow.withAlphaComponent(0.35)
            wingsGeo.materials = [wingsMat]
            let wingsNode = SCNNode(geometry: wingsGeo)
            wingsNode.position = SCNVector3(0, 5.5, 0)
            harpiaNode.addChildNode(wingsNode)
            
            enemiesRootNode.addChildNode(harpiaNode)
        }
    }
    
    private func update3DEnemies() {
        for enemy in session.storyEngine.enemies {
            if let node = enemiesRootNode.childNode(withName: enemy.id, recursively: false) {
                if enemy.isNeutralized {
                    node.isHidden = true
                } else {
                    node.isHidden = false
                    node.position = SCNVector3(CGFloat(enemy.position.x * 0.8), 0.1, CGFloat(enemy.position.y * 0.8))
                }
            }
        }
    }
    
    // MARK: - 3D Ambient Wild Fauna
    private func build3DAmbientFauna() {
        ambientFaunaRootNode.childNodes.forEach { $0.removeFromParentNode() }
        
        for animal in session.ambientFauna.wildFauna {
            let animalNode = SCNNode()
            animalNode.name = animal.id
            let ax = CGFloat(animal.position.x * 0.8)
            let az = CGFloat(animal.position.y * 0.8)
            let ay: CGFloat = animal.type.isAerial ? 8.5 : 0.6
            animalNode.position = SCNVector3(ax, ay, az)
            
            switch animal.type {
            case .macaw:
                // Aerial Macaw with Flapping Wings
                let bodyGeo = SCNCapsule(capRadius: 0.4, height: 1.4)
                let bodyMat = SCNMaterial()
                bodyMat.diffuse.contents = NSColor.systemBlue
                bodyGeo.materials = [bodyMat]
                let bodyNode = SCNNode(geometry: bodyGeo)
                bodyNode.eulerAngles.x = CGFloat.pi / 2
                animalNode.addChildNode(bodyNode)
                
                // Wings
                let wingGeo = SCNPlane(width: 2.2, height: 0.8)
                let wingMat = SCNMaterial()
                wingMat.diffuse.contents = NSColor.systemYellow
                wingMat.isDoubleSided = true
                wingGeo.materials = [wingMat]
                let wingNode = SCNNode(geometry: wingGeo)
                wingNode.position = SCNVector3(0, 0.2, 0)
                
                let flapUp = SCNAction.rotateTo(x: 0.35, y: 0, z: 0, duration: 0.15)
                let flapDown = SCNAction.rotateTo(x: -0.35, y: 0, z: 0, duration: 0.15)
                wingNode.runAction(SCNAction.repeatForever(SCNAction.sequence([flapUp, flapDown])))
                animalNode.addChildNode(wingNode)
                
            case .capybara:
                // Rounded Capybara Body
                let bodyGeo = SCNCapsule(capRadius: 0.7, height: 2.0)
                let bodyMat = SCNMaterial()
                bodyMat.diffuse.contents = NSColor(red: 0.48, green: 0.32, blue: 0.18, alpha: 1.0)
                bodyGeo.materials = [bodyMat]
                let bodyNode = SCNNode(geometry: bodyGeo)
                bodyNode.eulerAngles.x = CGFloat.pi / 2
                animalNode.addChildNode(bodyNode)
                
            case .butterfly:
                let bflyGeo = SCNPlane(width: 0.7, height: 0.7)
                let bflyMat = SCNMaterial()
                bflyMat.diffuse.contents = NSColor.systemTeal
                bflyMat.isDoubleSided = true
                bflyGeo.materials = [bflyMat]
                let bflyNode = SCNNode(geometry: bflyGeo)
                
                let flutter = SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 1.2)
                bflyNode.runAction(SCNAction.repeatForever(flutter))
                animalNode.addChildNode(bflyNode)
                
            case .armadillo:
                let armaGeo = SCNSphere(radius: 0.6)
                let armaMat = SCNMaterial()
                armaMat.diffuse.contents = NSColor(red: 0.55, green: 0.45, blue: 0.35, alpha: 1.0)
                armaGeo.materials = [armaMat]
                let armaNode = SCNNode(geometry: armaGeo)
                armaNode.scale = SCNVector3(1.2, 0.7, 1.4)
                animalNode.addChildNode(armaNode)
                
            case .rhea:
                let rheaGeo = SCNCylinder(radius: 0.5, height: 2.2)
                let rheaMat = SCNMaterial()
                rheaMat.diffuse.contents = NSColor.systemGray
                rheaGeo.materials = [rheaMat]
                let rheaNode = SCNNode(geometry: rheaGeo)
                rheaNode.position = SCNVector3(0, 1.1, 0)
                animalNode.addChildNode(rheaNode)
            }
            
            ambientFaunaRootNode.addChildNode(animalNode)
        }
    }
    
    private func update3DAmbientFauna() {
        for animal in session.ambientFauna.wildFauna {
            if let node = ambientFaunaRootNode.childNode(withName: animal.id, recursively: false) {
                let ax = CGFloat(animal.position.x * 0.8)
                let az = CGFloat(animal.position.y * 0.8)
                let ay: CGFloat = animal.type.isAerial ? (8.5 + CGFloat(sin(Double(animal.position.x) * 0.1) * 1.5)) : 0.6
                
                node.position = SCNVector3(ax, ay, az)
                node.eulerAngles.y = CGFloat(animal.wanderAngle)
            }
        }
    }
    
    // MARK: - Dynamic Day/Night Lighting & Sky
    private func updateLightingForTimeOfDay() {
        let tod = session.atmosphere.currentTimeOfDay
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 2.0
        
        sunLightNode.light?.color = tod.sunColor
        sunLightNode.eulerAngles = SCNVector3(tod.sunPitchAngle, tod.sunYawAngle, 0)
        ambientLightNode.light?.color = tod.ambientColor
        
        // Night sky background tint
        if tod == .night {
            scene.background.contents = NSColor(red: 0.04, green: 0.06, blue: 0.12, alpha: 1.0)
        } else if tod == .sunset {
            scene.background.contents = NSColor(red: 0.22, green: 0.10, blue: 0.08, alpha: 1.0)
        } else {
            scene.background.contents = NSColor(red: 0.45, green: 0.65, blue: 0.85, alpha: 1.0)
        }
        
        SCNTransaction.commit()
    }
    
    // MARK: - Weather & Atmospheric Particle Systems
    private func updateWeatherParticles(for biome: BiomeType) {
        weatherParticlesNode.childNodes.forEach { $0.removeFromParentNode() }
        let weather = session.atmosphere.weatherForBiome(biome)
        
        let pNode = SCNNode()
        let ps = SCNParticleSystem()
        
        switch weather {
        case .tropicalRain:
            ps.particleColor = NSColor(red: 0.65, green: 0.85, blue: 1.0, alpha: 0.55)
            ps.particleSize = 0.12
            ps.birthRate = 280
            ps.emissionDuration = 0 // Continuous
            ps.particleLifeSpan = 1.4
            ps.spreadingAngle = 10
            ps.emitterShape = SCNBox(width: 80, height: 1, length: 80, chamferRadius: 0)
            ps.acceleration = SCNVector3(0, -32, 0)
            pNode.position = SCNVector3(CGFloat(session.playerPosition.x * 0.8), 28, CGFloat(session.playerPosition.y * 0.8))
            
        case .mountainMist:
            ps.particleColor = NSColor(red: 0.90, green: 0.95, blue: 0.92, alpha: 0.18)
            ps.particleSize = 3.5
            ps.birthRate = 35
            ps.particleLifeSpan = 4.0
            ps.emitterShape = SCNBox(width: 90, height: 6, length: 90, chamferRadius: 0)
            ps.acceleration = SCNVector3(0.5, 0.1, 0)
            pNode.position = SCNVector3(CGFloat(session.playerPosition.x * 0.8), 4, CGFloat(session.playerPosition.y * 0.8))
            
        case .heatHaze:
            ps.particleColor = NSColor(red: 1.0, green: 0.80, blue: 0.40, alpha: 0.22)
            ps.particleSize = 0.8
            ps.birthRate = 45
            ps.particleLifeSpan = 2.5
            ps.acceleration = SCNVector3(0, 1.2, 0)
            pNode.position = SCNVector3(CGFloat(session.playerPosition.x * 0.8), 1, CGFloat(session.playerPosition.y * 0.8))
            
        case .fireflies:
            ps.particleColor = NSColor(red: 0.95, green: 1.0, blue: 0.35, alpha: 0.85)
            ps.particleSize = 0.35
            ps.birthRate = 25
            ps.particleLifeSpan = 3.5
            ps.acceleration = SCNVector3(0, 0.4, 0)
            pNode.position = SCNVector3(CGFloat(session.playerPosition.x * 0.8), 2, CGFloat(session.playerPosition.y * 0.8))
            
        case .clear:
            return
        }
        
        pNode.addParticleSystem(ps)
        weatherParticlesNode.addChildNode(pNode)
    }
    
    // MARK: - 3D Player Node
    private func build3DPlayerNode() {
        playerPlaneGeometry = SCNPlane(width: 3.0, height: 3.0)
        let playerMat = SCNMaterial()
        if let initialImg = NSImage(named: monkeyFrames[0]) {
            playerMat.diffuse.contents = initialImg
        }
        playerMat.isDoubleSided = true
        playerMat.transparent.contents = playerMat.diffuse.contents
        playerPlaneGeometry.materials = [playerMat]
        
        playerNode = SCNNode(geometry: playerPlaneGeometry)
        let targetX = CGFloat(session.playerPosition.x * 0.8)
        let targetZ = CGFloat(session.playerPosition.y * 0.8)
        playerNode.position = SCNVector3(targetX, 1.5, targetZ)
        playerNode.castsShadow = true
        scene.rootNode.addChildNode(playerNode)
    }
    
    // MARK: - Position & Camera Follow
    private func updatePlayer3DPosition(_ pos: CGPoint) {
        let targetX = CGFloat(pos.x * 0.8)
        let targetZ = CGFloat(pos.y * 0.8)
        
        if pos.x < previousPlayerPos.x {
            isFacingLeft = true
            playerNode.scale = SCNVector3(-1, 1, 1)
        } else if pos.x > previousPlayerPos.x {
            isFacingLeft = false
            playerNode.scale = SCNVector3(1, 1, 1)
        }
        previousPlayerPos = pos
        
        isMoving = true
        runBouncePhase += 0.8
        let bounceY = 1.5 + CGFloat(abs(sin(runBouncePhase)) * 0.07)
        
        let camTargetPos = SCNVector3(targetX, 22, targetZ + zoomDistance)
        let playerTargetPos = SCNVector3(targetX, bounceY, targetZ)
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.18
        playerNode.position = playerTargetPos
        playerNode.eulerAngles.z = isFacingLeft ? -0.035 : 0.035
        cameraNode.position = camTargetPos
        SCNTransaction.commit()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            if !isMoving {
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.20
                playerNode.position.y = 1.5
                playerNode.eulerAngles.z = 0
                SCNTransaction.commit()
            }
        }
    }
    
    private func animateCharacterFrame() {
        if isMoving && session.playerTransformation.isHuman {
            currentFrameIndex = (currentFrameIndex + 1) % monkeyFrames.count
            if let frameImg = NSImage(named: monkeyFrames[currentFrameIndex]) {
                playerPlaneGeometry.firstMaterial?.diffuse.contents = frameImg
            }
        } else if !isMoving && session.playerTransformation.isHuman {
            if currentFrameIndex != 0 {
                currentFrameIndex = 0
                if let frameImg = NSImage(named: monkeyFrames[0]) {
                    playerPlaneGeometry.firstMaterial?.diffuse.contents = frameImg
                }
            }
        }
    }
    
    private func updatePlayerAppearance() {
        if let species = session.activeSpecies {
            let morphMat = SCNMaterial()
            morphMat.diffuse.contents = species.nativeBiome.nsColor
            morphMat.emission.contents = species.nativeBiome.nsColor.withAlphaComponent(0.4)
            playerPlaneGeometry.materials = [morphMat]
        } else {
            let playerMat = SCNMaterial()
            if let initialImg = NSImage(named: monkeyFrames[currentFrameIndex]) {
                playerMat.diffuse.contents = initialImg
            }
            playerMat.isDoubleSided = true
            playerMat.transparent.contents = playerMat.diffuse.contents
            playerPlaneGeometry.materials = [playerMat]
        }
    }
    
    private func updateBiomeAtmosphere(for biome: BiomeType) {
        // Softly transition fog & ambient tint for current region
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 1.0
        scene.fogColor = biome.nsColor.withAlphaComponent(0.32)
        scene.fogStartDistance = 70.0
        scene.fogEndDistance = 220.0
        ambientLightNode.light?.color = biome.nsColor.withAlphaComponent(0.55)
        SCNTransaction.commit()
    }
    
    // MARK: - Top Unified Biome Compass Bar (No Menu Selector!)
    private var topUnifiedCompassBar: some View {
        HStack(spacing: 14) {
            // Live Dynamic Biome Radar Badge
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(session.currentBiome.primaryColor.opacity(0.3))
                        .frame(width: 36, height: 36)
                    Image(systemName: session.currentBiome.iconName)
                        .font(.headline)
                        .foregroundStyle(session.currentBiome.primaryColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("Região:")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.6))
                        Text(session.currentBiome.rawValue)
                            .font(.headline.bold())
                            .foregroundStyle(.white)
                        Text("Mundo Aberto 3D")
                            .font(.caption2.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.green.opacity(0.6)))
                            .foregroundStyle(.white)
                    }
                    
                    Text("Coordenadas: [X: \(Int(session.playerPosition.x)), Y: \(Int(session.playerPosition.y))] • \(session.currentBiome.description)")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.8))
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial))
            
            Spacer()
            
            // Time of Day & Weather Indicator Pill
            HStack(spacing: 8) {
                HStack(spacing: 5) {
                    Image(systemName: session.atmosphere.currentTimeOfDay.iconSymbol)
                        .foregroundStyle(session.atmosphere.currentTimeOfDay == .night ? .cyan : .yellow)
                    Text(session.atmosphere.currentTimeOfDay.rawValue)
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.black.opacity(0.4)))
                
                HStack(spacing: 5) {
                    Image(systemName: session.atmosphere.weatherForBiome(session.currentBiome).iconSymbol)
                        .foregroundStyle(.mint)
                    Text(session.atmosphere.weatherForBiome(session.currentBiome).rawValue)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.9))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.black.opacity(0.4)))
            }
            .padding(6)
            .background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial))
            
            // 3D Camera Zoom
            HStack(spacing: 8) {
                Button {
                    zoomDistance = min(55.0, zoomDistance + 4.0)
                    cameraNode.position.z = CGFloat(session.playerPosition.y * 0.8) + zoomDistance
                } label: {
                    Image(systemName: "minus.magnifyingglass")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(6)
                        .background(Circle().fill(.ultraThinMaterial))
                }
                .buttonStyle(.plain)
                
                Button {
                    zoomDistance = max(18.0, zoomDistance - 4.0)
                    cameraNode.position.z = CGFloat(session.playerPosition.y * 0.8) + zoomDistance
                } label: {
                    Image(systemName: "plus.magnifyingglass")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(6)
                        .background(Circle().fill(.ultraThinMaterial))
                }
                .buttonStyle(.plain)
            }
            
            // Audio Mute Toggle Button
            Button {
                SoundManager.shared.isMuted.toggle()
            } label: {
                Image(systemName: SoundManager.shared.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.caption.bold())
                    .foregroundStyle(SoundManager.shared.isMuted ? .gray : .white)
                    .padding(8)
                    .background(Circle().fill(.ultraThinMaterial))
            }
            .buttonStyle(.plain)
            .help("Ativar/Desativar Sons")
            
            // Main Menu Button
            Button {
                SoundManager.shared.playUIClick()
                onOpenMenu?()
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(8)
                    .background(Circle().fill(.ultraThinMaterial))
            }
            .buttonStyle(.plain)
            .help("Menu Principal [Esc]")
            
            // Morph Wheel Button
            Button {
                SoundManager.shared.playUIClick()
                showingTransformWheel = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.yellow)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(session.activeSpecies?.commonName ?? "Guardião Macaco")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                        Text("Metamorfose [T]")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThickMaterial))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.yellow.opacity(0.8), lineWidth: 1.5))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }
    
    // MARK: - Bottom Interactive HUD
    private var bottomInteractiveHUD: some View {
        VStack(spacing: 12) {
            // Proximity Action Banners
            if session.storyEngine.isHarpiaSummoned && hypot(session.playerPosition.x, session.playerPosition.y) <= 30.0 {
                HStack(spacing: 14) {
                    Circle()
                        .fill(Color.yellow)
                        .frame(width: 44, height: 44)
                        .overlay {
                            Image(systemName: "crown.fill")
                                .font(.title3.bold())
                                .foregroundStyle(.black)
                        }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("A Harpia Ancestral espera por você")
                            .font(.headline.bold())
                            .foregroundStyle(.yellow)
                        Text("Aproxime-se e receba o reconhecimento de Guardião Supremo dos Biomas!")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    Spacer()
                    Button {
                        session.interactWithNearbyPoint()
                    } label: {
                        Text("Receber Bênção [Espaço]")
                            .font(.headline.bold())
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color.yellow))
                            .foregroundStyle(.black)
                    }
                    .buttonStyle(.plain)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 20).fill(.ultraThickMaterial))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.yellow, lineWidth: 1.5))
                .padding(.horizontal)
            } else if let enemy = session.getNearbyEnemy(), !enemy.isNeutralized {
                HStack(spacing: 14) {
                    Circle()
                        .fill(enemy.type.dangerColor)
                        .frame(width: 44, height: 44)
                        .overlay {
                            Image(systemName: enemy.type.iconSymbol)
                                .font(.title3.bold())
                                .foregroundStyle(.white)
                        }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Ameaça: \(enemy.type.rawValue)")
                            .font(.headline.bold())
                            .foregroundStyle(.white)
                        if let perk = enemy.requiredCounterPerk {
                            Text("Requer habilidade: \(perk)")
                                .font(.caption.bold())
                                .foregroundStyle(Color.orange)
                        } else if enemy.type == .nestPoacher {
                            Text("Exige mãos humanas! Volte à forma humana (0) para blindar o ninho.")
                                .font(.caption.bold())
                                .foregroundStyle(Color.yellow)
                        } else {
                            Text("Aproxime-se para conter a ameaça.")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.85))
                        }
                    }
                    Spacer()
                    Button {
                        session.interactWithNearbyPoint()
                    } label: {
                        HStack(spacing: 6) {
                            Text("Conter / Desarmar")
                                .font(.headline.bold())
                            Text("[Espaço]")
                                .font(.caption.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(.white.opacity(0.25)))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 14).fill(enemy.type.dangerColor))
                        .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 20).fill(.ultraThickMaterial))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(enemy.type.dangerColor, lineWidth: 1.5))
                .padding(.horizontal)
            } else if let totem = session.getNearbyTotem(), !totem.isPurified {
                HStack(spacing: 14) {
                    Circle()
                        .fill(Color.purple)
                        .frame(width: 44, height: 44)
                        .overlay {
                            Image(systemName: "sparkles")
                                .font(.title3.bold())
                                .foregroundStyle(.white)
                        }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(totem.title)
                            .font(.headline.bold())
                            .foregroundStyle(.purple)
                        Text(totem.loreSnippet)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    Spacer()
                    Button {
                        session.interactWithNearbyPoint()
                    } label: {
                        Text("Purificar [Espaço]")
                            .font(.headline.bold())
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color.purple))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 20).fill(.ultraThickMaterial))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.purple, lineWidth: 1.5))
                .padding(.horizontal)
            } else if let nearby = session.getNearbyPoint() {
                HStack(spacing: 14) {
                    Circle()
                        .fill(nearby.interactionType == .animalInDistress ? Color.red : Color.orange)
                        .frame(width: 44, height: 44)
                        .overlay {
                            Image(systemName: nearby.interactionType == .animalInDistress ? "heart.fill" : "magnifyingglass")
                                .font(.title3.bold())
                                .foregroundStyle(.white)
                        }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(nearby.title)
                                .font(.headline.bold())
                                .foregroundStyle(.white)
                            Text("(\(nearby.biome.rawValue))")
                                .font(.caption2.bold())
                                .foregroundStyle(nearby.biome.primaryColor)
                        }
                        Text(nearby.description)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.85))
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    Button {
                        session.interactWithNearbyPoint()
                        build3DWorldPoints()
                    } label: {
                        HStack(spacing: 6) {
                            Text("Resgatar / Ajudar")
                                .font(.headline.bold())
                            Text("[Espaço]")
                                .font(.caption.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(.white.opacity(0.25)))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color.green))
                        .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 20).fill(.ultraThickMaterial))
                .padding(.horizontal)
            }
            
            // Movement Controls & Quick Morph Shortcuts
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.fill")
                            .foregroundStyle(.yellow)
                        Text("\(Int(session.playerTransformation.energy))%")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                        Text("• WASD / Setas para mover")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    
                    HStack(spacing: 4) {
                        Text("Metamorfose Rápida:")
                            .font(.caption2.bold())
                            .foregroundStyle(.yellow)
                        Text("[1] Mico • [2] Lobo • [3] Tatu • [4] Onça • [5] Ariranha • [6] Tamanduá • [0] Humano")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial))
                .padding(.leading)
                
                Spacer()
                
                // D-Pad Controls
                VStack(spacing: 3) {
                    controlDirectionButton(dx: 0, dy: -1.8, icon: "chevron.up")
                    HStack(spacing: 12) {
                        controlDirectionButton(dx: -1.8, dy: 0, icon: "chevron.left")
                        controlDirectionButton(dx: 1.8, dy: 0, icon: "chevron.right")
                    }
                    controlDirectionButton(dx: 0, dy: 1.8, icon: "chevron.down")
                }
                .padding(.trailing)
            }
            .padding(.bottom, 8)
        }
    }
    
    private func controlDirectionButton(dx: Double, dy: Double, icon: String) -> some View {
        Button {
            triggerMovement(dx: dx, dy: dy)
        } label: {
            Image(systemName: icon)
                .font(.title3.bold())
                .frame(width: 38, height: 38)
                .background(Circle().fill(.ultraThickMaterial))
                .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
    }
    
    private func triggerMovement(dx: Double, dy: Double) {
        isMoving = true
        session.movePlayer(dx: dx, dy: dy)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            isMoving = false
        }
    }
}
