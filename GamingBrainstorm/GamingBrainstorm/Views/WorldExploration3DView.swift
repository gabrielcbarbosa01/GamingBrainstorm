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
    // 3D Perspective Depth Camera Configuration (Visão Afastada com Ângulo Baixo)
    @State private var cameraDistance: CGFloat = 29.0
    @State private var cameraHeight: CGFloat = 18.5
    @State private var cameraPitch: Float = -0.53
    @State private var isElevatedView: Bool = false
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
    @State private var refugioRootNode = SCNNode()
    @State private var portalsRootNode = SCNNode()
    @State private var biomeLandmarksRootNode = SCNNode()
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
        
        // 1. Camera Node (3D Perspective Depth Camera with Horizon Angle)
        cameraNode = SCNNode()
        let cam = SCNCamera()
        cam.usesOrthographicProjection = false
        cam.fieldOfView = 54.0
        cam.zNear = 0.5
        cam.zFar = 850.0
        cameraNode.camera = cam
        
        let targetX = CGFloat(session.playerPosition.x * 0.8)
        let targetZ = CGFloat(session.playerPosition.y * 0.8)
        
        cameraNode.position = SCNVector3(targetX, cameraHeight, targetZ + cameraDistance)
        cameraNode.eulerAngles = SCNVector3(cameraPitch, 0, 0)
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
        
        // 14. Refúgio Raízes Hub (Praça Central, Oficina, Cais de Pesca, Viveiro, Altar)
        refugioRootNode = SCNNode()
        scene.rootNode.addChildNode(refugioRootNode)
        build3DRefugioRaizes()
        
        // 15. Portais Místicos dos Biomas e de Retorno
        portalsRootNode = SCNNode()
        scene.rootNode.addChildNode(portalsRootNode)
        build3DPortals()
        
        // 16. Marcos e Lugares Temáticos dos Biomas
        biomeLandmarksRootNode = SCNNode()
        scene.rootNode.addChildNode(biomeLandmarksRootNode)
        build3DBiomeLandmarks()
        
        // 17. Player Character Node
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
            let hillGeo = SCNCone(topRadius: radius * 0.15, bottomRadius: radius, height: height)
            let hillMat = SCNMaterial()
            hillMat.diffuse.contents = color
            hillMat.roughness.contents = 0.95
            hillGeo.materials = [hillMat]
            
            let hillNode = SCNNode(geometry: hillGeo)
            hillNode.position = SCNVector3(hx, height / 2 - 0.5, hz)
            hillNode.castsShadow = true
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
            
            // 3D Solid Wooden Trunk
            let trunkH: CGFloat = 2.4 * CGFloat(tree.scale)
            let trunkR: CGFloat = 0.36 * CGFloat(tree.scale)
            let trunkGeo = SCNCylinder(radius: trunkR, height: trunkH)
            let trunkMat = SCNMaterial()
            trunkMat.diffuse.contents = NSColor(red: 0.26, green: 0.16, blue: 0.10, alpha: 1.0)
            trunkMat.roughness.contents = 0.92
            trunkGeo.materials = [trunkMat]
            let trunkNode = SCNNode(geometry: trunkGeo)
            trunkNode.position = SCNVector3(0, trunkH / 2, 0)
            trunkNode.castsShadow = true
            treeContainer.addChildNode(trunkNode)
            
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
    
    private func makeYBillboard() -> SCNBillboardConstraint {
        let bb = SCNBillboardConstraint()
        bb.freeAxes = .Y
        return bb
    }
    
    // MARK: - 2.5D Story Friendly NPCs (Billboard Sprites)
    private func build3DStoryNPCs() {
        storyNpcsRootNode.childNodes.forEach { $0.removeFromParentNode() }
        
        for npc in session.storyEngine.npcs {
            let npcNode = SCNNode()
            let nx = CGFloat(npc.position.x * 0.8)
            let nz = CGFloat(npc.position.y * 0.8)
            npcNode.position = SCNVector3(nx, 0.1, nz)
            
            let planeW: CGFloat = 3.6
            let planeH: CGFloat = 4.8
            let npcGeo = SCNPlane(width: planeW, height: planeH)
            let img = Sprite2DFactory.shared.npcImage(for: npc)
            let npcMat = SCNMaterial()
            npcMat.diffuse.contents = img
            npcMat.transparent.contents = img
            npcMat.isDoubleSided = true
            npcGeo.materials = [npcMat]
            
            let billboard = SCNNode(geometry: npcGeo)
            billboard.position = SCNVector3(0, planeH / 2, 0)
            billboard.constraints = [makeYBillboard()]
            billboard.castsShadow = true
            npcNode.addChildNode(billboard)
            
            storyNpcsRootNode.addChildNode(npcNode)
        }
    }
    
    // MARK: - 2.5D Ancient Biome Totems (Billboard Sprites)
    private func build3DBiomeTotems() {
        totemsRootNode.childNodes.forEach { $0.removeFromParentNode() }
        
        for totem in session.storyEngine.totems {
            let totemNode = SCNNode()
            let tx = CGFloat(totem.position.x * 0.8)
            let tz = CGFloat(totem.position.y * 0.8)
            totemNode.position = SCNVector3(tx, 0.1, tz)
            
            let planeW: CGFloat = 4.2
            let planeH: CGFloat = 6.4
            let totemGeo = SCNPlane(width: planeW, height: planeH)
            let img = Sprite2DFactory.shared.totemImage(for: totem)
            let mat = SCNMaterial()
            mat.diffuse.contents = img
            mat.transparent.contents = img
            mat.isDoubleSided = true
            if totem.isPurified {
                mat.emission.contents = NSColor.systemGreen.withAlphaComponent(0.3)
            }
            totemGeo.materials = [mat]
            
            let billboard = SCNNode(geometry: totemGeo)
            billboard.position = SCNVector3(0, planeH / 2, 0)
            billboard.constraints = [makeYBillboard()]
            billboard.castsShadow = true
            totemNode.addChildNode(billboard)
            
            totemsRootNode.addChildNode(totemNode)
        }
    }
    
    // MARK: - 2.5D Open World Enemies (Billboard Sprites)
    private func build3DEnemies() {
        enemiesRootNode.childNodes.forEach { $0.removeFromParentNode() }
        
        for enemy in session.storyEngine.enemies {
            let enemyNode = SCNNode()
            enemyNode.name = enemy.id
            let ex = CGFloat(enemy.position.x * 0.8)
            let ez = CGFloat(enemy.position.y * 0.8)
            enemyNode.position = SCNVector3(ex, 0.1, ez)
            
            let planeW: CGFloat = 4.6
            let planeH: CGFloat = 4.6
            let enemyGeo = SCNPlane(width: planeW, height: planeH)
            let img = Sprite2DFactory.shared.enemyImage(for: enemy)
            let mat = SCNMaterial()
            mat.diffuse.contents = img
            mat.transparent.contents = img
            mat.isDoubleSided = true
            enemyGeo.materials = [mat]
            
            let billboard = SCNNode(geometry: enemyGeo)
            billboard.position = SCNVector3(0, planeH / 2, 0)
            billboard.constraints = [makeYBillboard()]
            billboard.castsShadow = true
            enemyNode.addChildNode(billboard)
            
            // Suave oscilação de perigo
            let pulseAction = SCNAction.sequence([
                SCNAction.scale(to: 1.06, duration: 0.5),
                SCNAction.scale(to: 0.94, duration: 0.5)
            ])
            billboard.runAction(SCNAction.repeatForever(pulseAction))
            
            enemiesRootNode.addChildNode(enemyNode)
        }
        
        // Harpia Ancestral (se invocada) como colossal billboard 2.5D
        if session.storyEngine.isHarpiaSummoned {
            let harpiaNode = SCNNode()
            harpiaNode.name = "harpia_ancestral"
            harpiaNode.position = SCNVector3(0, 0.1, 0)
            
            let hPlane = SCNPlane(width: 8.5, height: 8.5)
            let hMat = SCNMaterial()
            let hImg = Sprite2DFactory.shared.harpiaAltarImage()
            hMat.diffuse.contents = hImg
            hMat.transparent.contents = hImg
            hMat.isDoubleSided = true
            hMat.emission.contents = NSColor.systemYellow.withAlphaComponent(0.4)
            hPlane.materials = [hMat]
            
            let billboard = SCNNode(geometry: hPlane)
            billboard.position = SCNVector3(0, 4.25, 0)
            billboard.constraints = [makeYBillboard()]
            billboard.castsShadow = true
            harpiaNode.addChildNode(billboard)
            
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
    
    // MARK: - Refúgio Raízes Hub 3D Scenery
    private func build3DRefugioRaizes() {
        refugioRootNode.childNodes.forEach { $0.removeFromParentNode() }
        
        // 1. Praça Central Empedrada (Cobblestone Circle)
        let plazaGeo = SCNCylinder(radius: 22.0, height: 0.12)
        let plazaMat = SCNMaterial()
        plazaMat.diffuse.contents = NSColor(red: 0.74, green: 0.72, blue: 0.66, alpha: 1.0)
        plazaMat.roughness.contents = 0.95
        plazaGeo.materials = [plazaMat]
        let plazaNode = SCNNode(geometry: plazaGeo)
        plazaNode.position = SCNVector3(0, 0.06, 0)
        plazaNode.castsShadow = false
        refugioRootNode.addChildNode(plazaNode)
        
        // Borda de pedra polida ao redor da praça
        let borderGeo = SCNTorus(ringRadius: 22.0, pipeRadius: 0.45)
        let borderMat = SCNMaterial()
        borderMat.diffuse.contents = NSColor(red: 0.52, green: 0.50, blue: 0.46, alpha: 1.0)
        borderGeo.materials = [borderMat]
        let borderNode = SCNNode(geometry: borderGeo)
        borderNode.position = SCNVector3(0, 0.22, 0)
        refugioRootNode.addChildNode(borderNode)
        
        // Tochas de Pedra Monumentais nos 4 pontos cardeais da praça
        let torchPositions: [(CGFloat, CGFloat)] = [
            (0, 18), (0, -18), (-18, 0), (18, 0)
        ]
        for (tx, tz) in torchPositions {
            let torchPost = SCNCylinder(radius: 0.35, height: 2.6)
            let torchMat = SCNMaterial()
            torchMat.diffuse.contents = NSColor(red: 0.42, green: 0.40, blue: 0.36, alpha: 1.0)
            torchPost.materials = [torchMat]
            let postNode = SCNNode(geometry: torchPost)
            postNode.position = SCNVector3(tx, 1.3, tz)
            postNode.castsShadow = true
            refugioRootNode.addChildNode(postNode)
            
            // Chama da tocha
            let flameGeo = SCNSphere(radius: 0.3)
            let flameMat = SCNMaterial()
            flameMat.diffuse.contents = NSColor(red: 1.0, green: 0.72, blue: 0.22, alpha: 1.0)
            flameMat.emission.contents = NSColor(red: 1.0, green: 0.65, blue: 0.15, alpha: 1.0)
            flameGeo.materials = [flameMat]
            let flameNode = SCNNode(geometry: flameGeo)
            flameNode.position = SCNVector3(tx, 2.7, tz)
            
            let pulseAction = SCNAction.sequence([
                SCNAction.scale(to: 1.25, duration: 0.35),
                SCNAction.scale(to: 0.85, duration: 0.35)
            ])
            flameNode.runAction(SCNAction.repeatForever(pulseAction))
            refugioRootNode.addChildNode(flameNode)
        }
        
        // 2. Placa Central do Refúgio ("Refúgio Raízes — estação de campo. Aqui você está seguro.")
        let signPlaneW: CGFloat = 3.6
        let signPlaneH: CGFloat = 3.4
        let signGeo = SCNPlane(width: signPlaneW, height: signPlaneH)
        let signMat = SCNMaterial()
        let signImg = Sprite2DFactory.shared.fieldSignImage()
        signMat.diffuse.contents = signImg
        signMat.transparent.contents = signImg
        signMat.isDoubleSided = true
        signGeo.materials = [signMat]
        let signBoardNode = SCNNode(geometry: signGeo)
        signBoardNode.position = SCNVector3(0, signPlaneH / 2, -1.6)
        signBoardNode.constraints = [makeYBillboard()]
        signBoardNode.castsShadow = true
        refugioRootNode.addChildNode(signBoardNode)
        
        // 3. Oficina de Campo (2.5D Billboard) em (11.2, 3.2)
        let ofX: CGFloat = 11.2
        let ofZ: CGFloat = 3.2
        let ofW: CGFloat = 6.8
        let ofH: CGFloat = 5.8
        let ofGeo = SCNPlane(width: ofW, height: ofH)
        let ofMat = SCNMaterial()
        let ofImg = Sprite2DFactory.shared.workshopImage()
        ofMat.diffuse.contents = ofImg
        ofMat.transparent.contents = ofImg
        ofMat.isDoubleSided = true
        ofGeo.materials = [ofMat]
        let workshopNode = SCNNode(geometry: ofGeo)
        workshopNode.position = SCNVector3(ofX, ofH / 2, ofZ)
        workshopNode.constraints = [makeYBillboard()]
        workshopNode.castsShadow = true
        refugioRootNode.addChildNode(workshopNode)
        
        // 4. Açude e Cais de Pesca em (-12.8, -6.4)
        let caisX: CGFloat = -12.8
        let caisZ: CGFloat = -6.4
        let pondGeo = SCNCylinder(radius: 9.5, height: 0.08)
        let pondMat = SCNMaterial()
        pondMat.diffuse.contents = NSColor(red: 0.12, green: 0.58, blue: 0.72, alpha: 0.88)
        pondMat.roughness.contents = 0.1
        pondGeo.materials = [pondMat]
        let pondNode = SCNNode(geometry: pondGeo)
        pondNode.position = SCNVector3(caisX, 0.04, caisZ)
        refugioRootNode.addChildNode(pondNode)
        
        // Cais 2.5D Billboard
        let caisW: CGFloat = 5.6
        let caisH: CGFloat = 4.8
        let caisGeo = SCNPlane(width: caisW, height: caisH)
        let caisMat = SCNMaterial()
        let caisImg = Sprite2DFactory.shared.fishingDockImage()
        caisMat.diffuse.contents = caisImg
        caisMat.transparent.contents = caisImg
        caisMat.isDoubleSided = true
        caisGeo.materials = [caisMat]
        let pierNode = SCNNode(geometry: caisGeo)
        pierNode.position = SCNVector3(caisX, caisH / 2, caisZ - 0.8)
        pierNode.constraints = [makeYBillboard()]
        pierNode.castsShadow = true
        refugioRootNode.addChildNode(pierNode)
        
        // 5. Viveiro de Mudas (10 Canteiros 2.5D Billboards) em (8.0, -9.6)
        let vivX: CGFloat = 8.0
        let vivZ: CGFloat = -9.6
        for i in 0..<10 {
            let col = CGFloat(i % 5)
            let row = CGFloat(i / 5)
            let bx = vivX + (col * 3.0) - 6.0
            let bz = vivZ + (row * 2.4)
            
            let bedW: CGFloat = 2.8
            let bedH: CGFloat = 2.2
            let bedGeo = SCNPlane(width: bedW, height: bedH)
            let bedMat = SCNMaterial()
            let bedImg = Sprite2DFactory.shared.seedlingBedImage(index: i)
            bedMat.diffuse.contents = bedImg
            bedMat.transparent.contents = bedImg
            bedMat.isDoubleSided = true
            bedGeo.materials = [bedMat]
            
            let bedNode = SCNNode(geometry: bedGeo)
            bedNode.position = SCNVector3(bx, bedH / 2, bz)
            bedNode.constraints = [makeYBillboard()]
            bedNode.castsShadow = true
            refugioRootNode.addChildNode(bedNode)
        }
        
        // 6. Altar Sagrado da Harpia Ancestral (2.5D Billboard) em (0.0, -11.2)
        let altZ: CGFloat = -11.2
        let altarW: CGFloat = 4.8
        let altarH: CGFloat = 6.0
        let altarGeo = SCNPlane(width: altarW, height: altarH)
        let altarMat = SCNMaterial()
        let altarImg = Sprite2DFactory.shared.harpiaAltarImage()
        altarMat.diffuse.contents = altarImg
        altarMat.transparent.contents = altarImg
        altarMat.isDoubleSided = true
        altarGeo.materials = [altarMat]
        let altarNode = SCNNode(geometry: altarGeo)
        altarNode.position = SCNVector3(0, altarH / 2, altZ)
        altarNode.constraints = [makeYBillboard()]
        altarNode.castsShadow = true
        refugioRootNode.addChildNode(altarNode)
    }
    
    // MARK: - 2.5D Mystical Portals (Arc of the 5 Biomes + 5 Return Portals)
    private func build3DPortals() {
        portalsRootNode.childNodes.forEach { $0.removeFromParentNode() }
        
        for portal in session.activePortals {
            let px = CGFloat(portal.position.x * 0.8)
            let pz = CGFloat(portal.position.y * 0.8)
            
            let portalContainer = SCNNode()
            portalContainer.name = portal.id
            portalContainer.position = SCNVector3(px, 0, pz)
            
            // 2D Billboard Plane Sprite
            let planeW: CGFloat = 5.6
            let planeH: CGFloat = 7.2
            let portalGeo = SCNPlane(width: planeW, height: planeH)
            let portalMat = SCNMaterial()
            let img = Sprite2DFactory.shared.portalImage(for: portal)
            portalMat.diffuse.contents = img
            portalMat.transparent.contents = img
            portalMat.isDoubleSided = true
            portalGeo.materials = [portalMat]
            
            let billboardNode = SCNNode(geometry: portalGeo)
            billboardNode.position = SCNVector3(0, planeH / 2, 0)
            billboardNode.constraints = [makeYBillboard()]
            billboardNode.castsShadow = true
            portalContainer.addChildNode(billboardNode)
            
            // Partículas Místicas Flutuantes ao Redor da Base
            let portalParticles = SCNParticleSystem()
            portalParticles.birthRate = 22
            portalParticles.particleLifeSpan = 1.6
            portalParticles.particleColor = portal.nsColor
            portalParticles.particleSize = 0.18
            portalParticles.emitterShape = SCNCylinder(radius: 1.4, height: 0.2)
            portalParticles.emissionDuration = 0
            portalParticles.loops = true
            portalParticles.spreadingAngle = 25
            portalParticles.speedFactor = 0.65
            portalParticles.acceleration = SCNVector3(0, 1.4, 0)
            portalContainer.addParticleSystem(portalParticles)
            
            portalsRootNode.addChildNode(portalContainer)
        }
    }
    
    // MARK: - 2.5D Landmarks Across the 5 Biomes
    private func build3DBiomeLandmarks() {
        biomeLandmarksRootNode.childNodes.forEach { $0.removeFromParentNode() }
        
        // 1. Mata Atlântica: Estação das Copas (Dossel Suspenso 2.5D)
        let mataX: CGFloat = 55.0 * 0.8
        let mataZ: CGFloat = 155.0 * 0.8
        let mataW: CGFloat = 5.6
        let mataH: CGFloat = 6.8
        let mataGeo = SCNPlane(width: mataW, height: mataH)
        let mataMat = SCNMaterial()
        let mataImg = Sprite2DFactory.shared.landmarkImage(id: "canopyPlatform")
        mataMat.diffuse.contents = mataImg
        mataMat.transparent.contents = mataImg
        mataMat.isDoubleSided = true
        mataGeo.materials = [mataMat]
        let mataNode = SCNNode(geometry: mataGeo)
        mataNode.position = SCNVector3(mataX, mataH / 2, mataZ)
        mataNode.constraints = [makeYBillboard()]
        mataNode.castsShadow = true
        biomeLandmarksRootNode.addChildNode(mataNode)
        
        // 2. Cerrado: Posto dos Brigadistas & Faixa de Aceiro
        let cerX: CGFloat = 125.0 * 0.8
        let cerZ: CGFloat = -20.0 * 0.8
        
        // Faixa de Solo Raspado (Aceiro de Contenção no solo)
        let firebreakGeo = SCNBox(width: 32.0, height: 0.08, length: 4.0, chamferRadius: 0.0)
        let firebreakMat = SCNMaterial()
        firebreakMat.diffuse.contents = NSColor(red: 0.44, green: 0.30, blue: 0.18, alpha: 1.0)
        firebreakGeo.materials = [firebreakMat]
        let firebreakNode = SCNNode(geometry: firebreakGeo)
        firebreakNode.position = SCNVector3(cerX, 0.04, cerZ + 6.0)
        biomeLandmarksRootNode.addChildNode(firebreakNode)
        
        // Tenda de Campanha dos Brigadistas (2.5D Billboard)
        let tentW: CGFloat = 5.2
        let tentH: CGFloat = 4.2
        let tentGeo = SCNPlane(width: tentW, height: tentH)
        let tentMat = SCNMaterial()
        let tentImg = Sprite2DFactory.shared.landmarkImage(id: "rangerTent")
        tentMat.diffuse.contents = tentImg
        tentMat.transparent.contents = tentImg
        tentMat.isDoubleSided = true
        tentGeo.materials = [tentMat]
        let tentNode = SCNNode(geometry: tentGeo)
        tentNode.position = SCNVector3(cerX, tentH / 2, cerZ)
        tentNode.constraints = [makeYBillboard()]
        tentNode.castsShadow = true
        biomeLandmarksRootNode.addChildNode(tentNode)
        
        // 3. Pantanal: Manduvi Gigante com Ninho Artificial de Arara (2.5D Billboard)
        let panX: CGFloat = -135.0 * 0.8
        let panZ: CGFloat = 30.0 * 0.8
        let panW: CGFloat = 7.6
        let panH: CGFloat = 10.5
        let panGeo = SCNPlane(width: panW, height: panH)
        let panMat = SCNMaterial()
        let panImg = Sprite2DFactory.shared.landmarkImage(id: "manduviTree")
        panMat.diffuse.contents = panImg
        panMat.transparent.contents = panImg
        panMat.isDoubleSided = true
        panGeo.materials = [panMat]
        let panNode = SCNNode(geometry: panGeo)
        panNode.position = SCNVector3(panX, panH / 2, panZ)
        panNode.constraints = [makeYBillboard()]
        panNode.castsShadow = true
        biomeLandmarksRootNode.addChildNode(panNode)
        
        // 4. Amazônia: Lago de Manejo Comunitário (Pier 2.5D Billboard)
        let amzX: CGFloat = -155.0 * 0.8
        let amzZ: CGFloat = -205.0 * 0.8
        let amzW: CGFloat = 5.8
        let amzH: CGFloat = 4.8
        let amzGeo = SCNPlane(width: amzW, height: amzH)
        let amzMat = SCNMaterial()
        let amzImg = Sprite2DFactory.shared.fishingDockImage()
        amzMat.diffuse.contents = amzImg
        amzMat.transparent.contents = amzImg
        amzMat.isDoubleSided = true
        amzGeo.materials = [amzMat]
        let amzNode = SCNNode(geometry: amzGeo)
        amzNode.position = SCNVector3(amzX, amzH / 2, amzZ)
        amzNode.constraints = [makeYBillboard()]
        amzNode.castsShadow = true
        biomeLandmarksRootNode.addChildNode(amzNode)
        
        // 5. Pampa: Colônia das Dunas e Galerias Subterrâneas de Tuco-Tuco
        let pamX: CGFloat = 22.0 * 0.8
        let pamZ: CGFloat = 235.0 * 0.8
        for mound in [(-2.5, -1.8), (2.2, 1.4), (0.0, 3.2)] as [(CGFloat, CGFloat)] {
            let moundGeo = SCNCone(topRadius: 0.3, bottomRadius: 1.8, height: 0.8)
            let sandMat = SCNMaterial()
            sandMat.diffuse.contents = NSColor(red: 0.76, green: 0.70, blue: 0.52, alpha: 1.0)
            moundGeo.materials = [sandMat]
            let mNode = SCNNode(geometry: moundGeo)
            mNode.position = SCNVector3(pamX + mound.0, 0.4, pamZ + mound.1)
            mNode.castsShadow = true
            biomeLandmarksRootNode.addChildNode(mNode)
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
        
        // Night sky background tint & Atmospheric Depth Fog
        scene.fogStartDistance = 65.0
        scene.fogEndDistance = 290.0
        scene.fogDensityExponent = 1.3
        
        if tod == .night {
            scene.background.contents = NSColor(red: 0.04, green: 0.06, blue: 0.12, alpha: 1.0)
            scene.fogColor = NSColor(red: 0.04, green: 0.06, blue: 0.14, alpha: 1.0)
        } else if tod == .sunset {
            scene.background.contents = NSColor(red: 0.22, green: 0.10, blue: 0.08, alpha: 1.0)
            scene.fogColor = NSColor(red: 0.38, green: 0.20, blue: 0.16, alpha: 1.0)
        } else {
            scene.background.contents = NSColor(red: 0.45, green: 0.65, blue: 0.85, alpha: 1.0)
            scene.fogColor = NSColor(red: 0.60, green: 0.76, blue: 0.88, alpha: 1.0)
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
        let billboard = SCNBillboardConstraint()
        billboard.freeAxes = .Y
        playerNode.constraints = [billboard]
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
        
        let camTargetPos = SCNVector3(targetX, cameraHeight, targetZ + cameraDistance)
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
            
            // 2.5D Isometric Angle Switcher
            // 3D Depth Angle Mode Switcher
            Button {
                isElevatedView.toggle()
                cameraHeight = isElevatedView ? 32.0 : 18.5
                cameraPitch = isElevatedView ? -0.82 : -0.53
                let targetX = CGFloat(session.playerPosition.x * 0.8)
                let targetZ = CGFloat(session.playerPosition.y * 0.8)
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.35
                cameraNode.position = SCNVector3(targetX, cameraHeight, targetZ + cameraDistance)
                cameraNode.eulerAngles = SCNVector3(cameraPitch, 0, 0)
                SCNTransaction.commit()
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: isElevatedView ? "eye.fill" : "mountain.2.fill")
                        .font(.caption)
                    Text(isElevatedView ? "Visão Aérea" : "Visão Padrão")
                        .font(.caption2.bold())
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(RoundedRectangle(cornerRadius: 10).fill(.ultraThinMaterial))
            }
            .buttonStyle(.plain)
            .help("Alternar entre ângulo padrão elevado e visão aérea ampla")
            
            // 3D Camera Distance Zoom (Closer / Farther)
            HStack(spacing: 8) {
                Button {
                    cameraDistance = min(44.0, cameraDistance + 3.0)
                    let targetX = CGFloat(session.playerPosition.x * 0.8)
                    let targetZ = CGFloat(session.playerPosition.y * 0.8)
                    SCNTransaction.begin()
                    SCNTransaction.animationDuration = 0.2
                    cameraNode.position = SCNVector3(targetX, cameraHeight, targetZ + cameraDistance)
                    SCNTransaction.commit()
                } label: {
                    Image(systemName: "minus.magnifyingglass")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(6)
                        .background(Circle().fill(.ultraThinMaterial))
                }
                .buttonStyle(.plain)
                .help("Afastar câmera")
                
                Button {
                    cameraDistance = max(14.0, cameraDistance - 3.0)
                    let targetX = CGFloat(session.playerPosition.x * 0.8)
                    let targetZ = CGFloat(session.playerPosition.y * 0.8)
                    SCNTransaction.begin()
                    SCNTransaction.animationDuration = 0.2
                    cameraNode.position = SCNVector3(targetX, cameraHeight, targetZ + cameraDistance)
                    SCNTransaction.commit()
                } label: {
                    Image(systemName: "plus.magnifyingglass")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(6)
                        .background(Circle().fill(.ultraThinMaterial))
                }
                .buttonStyle(.plain)
                .help("Aproximar câmera (mais perto)")
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
            } else if let portal = session.getNearbyPortal() {
                HStack(spacing: 14) {
                    Circle()
                        .fill(Color(nsColor: portal.nsColor))
                        .frame(width: 44, height: 44)
                        .overlay {
                            Image(systemName: "circle.circle.fill")
                                .font(.title3.bold())
                                .foregroundStyle(.white)
                        }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(portal.portalName)
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text(portal.description.isEmpty ? "Atravesse o portal místico para viajar instantaneamente." : portal.description)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    Spacer()
                    Button {
                        session.teleportThroughPortal(portal)
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "sparkles")
                            Text("Entrar [Espaço]")
                        }
                        .font(.headline.bold())
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color(nsColor: portal.nsColor)))
                        .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 20).fill(.ultraThickMaterial))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(nsColor: portal.nsColor), lineWidth: 1.5))
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
