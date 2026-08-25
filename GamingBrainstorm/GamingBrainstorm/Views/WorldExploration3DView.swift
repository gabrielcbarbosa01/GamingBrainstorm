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
    @State private var zoomDistance: CGFloat = 28.0
    @State private var previousPlayerPos: CGPoint = .zero
    
    // SceneKit Scene & Nodes
    @State private var scene = SCNScene()
    @State private var playerNode = SCNNode()
    @State private var playerPlaneGeometry = SCNPlane(width: 2.8, height: 2.8)
    @State private var cameraNode = SCNNode()
    @State private var sunLightNode = SCNNode()
    @State private var ambientLightNode = SCNNode()
    @State private var worldPointsRootNode = SCNNode()
    @State private var treesRootNode = SCNNode()
    @State private var bushesRootNode = SCNNode()
    @State private var currentFrameIndex = 0
    @State private var runBouncePhase: Double = 0.0
    
    // Monkey sprite frames from assets
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
    // Subtle, smooth natural movement timer (~11 FPS)
    private let frameTimer = Timer.publish(every: 0.09, on: .main, in: .common).autoconnect()
    
    public init(session: GameSession) {
        self.session = session
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
                topNavigationBar
                Spacer()
                bottomInteractiveHUD
            }
            
            // 3. Transformation Wheel Modal
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
        }
        .onChange(of: session.playerPosition) { _, newPos in
            updatePlayer3DPosition(newPos)
        }
        .onChange(of: session.playerTransformation.activeSpeciesId) { _, _ in
            updatePlayerAppearance()
        }
        .onReceive(tickTimer) { _ in
            session.simulationTick()
        }
        .onReceive(frameTimer) { _ in
            animateCharacterFrame()
        }
    }
    
    // MARK: - SceneKit 3D Scene Initialization
    private func setup3DScene() {
        scene = SCNScene()
        
        // 1. Camera Node (3rd Person Isometric Angle)
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.zNear = 0.5
        cameraNode.camera?.zFar = 300.0
        cameraNode.position = SCNVector3(0, 18, zoomDistance)
        cameraNode.eulerAngles = SCNVector3(-0.62, 0, 0) // ~35 degree pitch down
        scene.rootNode.addChildNode(cameraNode)
        
        // 2. Directional Sun Light with Real-Time Soft Shadows
        sunLightNode = SCNNode()
        let sun = SCNLight()
        sun.type = .directional
        sun.color = NSColor(red: 1.0, green: 0.98, blue: 0.88, alpha: 1.0)
        sun.castsShadow = true
        sun.shadowRadius = 4.0
        sun.shadowSampleCount = 16
        sun.shadowMapSize = CGSize(width: 2048, height: 2048)
        sunLightNode.light = sun
        sunLightNode.position = SCNVector3(30, 50, 30)
        sunLightNode.eulerAngles = SCNVector3(-0.9, 0.6, 0)
        scene.rootNode.addChildNode(sunLightNode)
        
        // 3. Ambient Light
        ambientLightNode = SCNNode()
        let ambient = SCNLight()
        ambient.type = .ambient
        ambient.color = NSColor(red: 0.35, green: 0.45, blue: 0.38, alpha: 1.0)
        ambientLightNode.light = ambient
        scene.rootNode.addChildNode(ambientLightNode)
        
        // 4. Large 3D Terrain Ground Plane
        build3DTerrain()
        
        // 5. 3D Flowing River System (Translucent Water Plane, Riverbed & Currents)
        build3DRiver()
        
        // 6. 3D Forest with Volumetric Animated Trees
        treesRootNode = SCNNode()
        scene.rootNode.addChildNode(treesRootNode)
        build3DForest()
        
        // 7. 3D Bushes & Flora Layer
        bushesRootNode = SCNNode()
        scene.rootNode.addChildNode(bushesRootNode)
        build3DBushes()
        
        // 8. Interactive 3D World Points & Rescues
        worldPointsRootNode = SCNNode()
        scene.rootNode.addChildNode(worldPointsRootNode)
        build3DWorldPoints()
        
        // 9. 3D Animated Player Character Node
        build3DPlayerNode()
        
        // Update atmosphere colors for starting biome
        updateBiomeAtmosphere(for: session.currentBiome)
    }
    
    // MARK: - 3D Terrain Construction
    private func build3DTerrain() {
        let terrainGeo = SCNBox(width: 220, height: 1.0, length: 220, chamferRadius: 0.2)
        let terrainMat = SCNMaterial()
        terrainMat.diffuse.contents = NSColor(red: 0.16, green: 0.35, blue: 0.20, alpha: 1.0)
        terrainMat.roughness.contents = 0.9
        terrainGeo.materials = [terrainMat]
        
        let terrainNode = SCNNode(geometry: terrainGeo)
        terrainNode.position = SCNVector3(0, -0.5, 0)
        terrainNode.name = "Terrain"
        scene.rootNode.addChildNode(terrainNode)
        
        // Add rolling 3D hills / terrain elevations
        let hillCoords: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
            (-35, -40, 18, 5.0),
            (45, -35, 22, 6.5),
            (-50, 30, 20, 5.5),
            (55, 45, 26, 7.0),
            (-15, -60, 16, 4.0)
        ]
        
        for (hx, hz, radius, height) in hillCoords {
            let hillGeo = SCNCylinder(radius: radius, height: height)
            let hillMat = SCNMaterial()
            hillMat.diffuse.contents = NSColor(red: 0.20, green: 0.42, blue: 0.24, alpha: 1.0)
            hillGeo.materials = [hillMat]
            
            let hillNode = SCNNode(geometry: hillGeo)
            hillNode.position = SCNVector3(hx, height / 2 - 0.4, hz)
            scene.rootNode.addChildNode(hillNode)
        }
    }
    
    // MARK: - 3D Flowing River System
    private func build3DRiver() {
        let riverContainer = SCNNode()
        riverContainer.name = "RiverSystem"
        
        // 1. Riverbed Sand / Shoreline Trench
        let bedGeo = SCNPlane(width: 26, height: 230)
        let bedMat = SCNMaterial()
        bedMat.diffuse.contents = NSColor(red: 0.24, green: 0.36, blue: 0.30, alpha: 1.0)
        bedGeo.materials = [bedMat]
        let bedNode = SCNNode(geometry: bedGeo)
        bedNode.eulerAngles = SCNVector3(-CGFloat.pi / 2, 0, 0.22)
        bedNode.position = SCNVector3(12, 0.01, 0)
        riverContainer.addChildNode(bedNode)
        
        // 2. Translucent River Water Surface
        let riverGeo = SCNPlane(width: 22, height: 220)
        let waterMat = SCNMaterial()
        waterMat.diffuse.contents = NSColor(red: 0.14, green: 0.65, blue: 0.82, alpha: 0.84)
        waterMat.specular.contents = NSColor.white
        waterMat.shininess = 95
        waterMat.isDoubleSided = true
        waterMat.transparency = 0.86
        riverGeo.materials = [waterMat]
        
        let riverNode = SCNNode(geometry: riverGeo)
        riverNode.eulerAngles = SCNVector3(-CGFloat.pi / 2, 0, 0.22)
        riverNode.position = SCNVector3(12, 0.06, 0)
        riverNode.name = "RiverWater"
        riverContainer.addChildNode(riverNode)
        
        // 3. Flowing Water Current & Foam Streaks (Flowing Downstream)
        for i in 0..<14 {
            let foamLength = CGFloat.random(in: 14...32)
            let foamWidth = CGFloat.random(in: 1.2...2.8)
            let foamGeo = SCNPlane(width: foamWidth, height: foamLength)
            let foamMat = SCNMaterial()
            foamMat.diffuse.contents = NSColor(red: 0.90, green: 0.98, blue: 1.0, alpha: 0.40)
            foamMat.isDoubleSided = true
            foamMat.transparency = 0.50
            foamGeo.materials = [foamMat]
            
            let foamNode = SCNNode(geometry: foamGeo)
            let offsetX = CGFloat.random(in: -7...7)
            let startY = CGFloat(-100 + Double(i) * 16.0)
            foamNode.position = SCNVector3(offsetX, startY, 0.02)
            
            // Continuous downstream flow motion
            let flowDistance: CGFloat = 220.0
            let duration: Double = Double.random(in: 4.5...6.5)
            let flowAction = SCNAction.moveBy(x: 0, y: flowDistance, z: 0, duration: duration)
            let resetAction = SCNAction.moveBy(x: 0, y: -flowDistance, z: 0, duration: 0)
            let loop = SCNAction.repeatForever(SCNAction.sequence([flowAction, resetAction]))
            foamNode.runAction(loop)
            
            riverNode.addChildNode(foamNode)
        }
        
        // 4. Stepping Stones / Natural Bridge
        let stonePositions: [SCNVector3] = [
            SCNVector3(4, 0.15, -12),
            SCNVector3(8, 0.20, -10),
            SCNVector3(12, 0.22, -8),
            SCNVector3(16, 0.18, -6),
            SCNVector3(20, 0.12, -4)
        ]
        
        for pos in stonePositions {
            let stoneGeo = SCNCylinder(radius: 1.6, height: 0.6)
            let stoneMat = SCNMaterial()
            stoneMat.diffuse.contents = NSColor(red: 0.45, green: 0.42, blue: 0.38, alpha: 1.0)
            stoneGeo.materials = [stoneMat]
            
            let stoneNode = SCNNode(geometry: stoneGeo)
            stoneNode.position = pos
            stoneNode.castsShadow = true
            riverContainer.addChildNode(stoneNode)
        }
        
        scene.rootNode.addChildNode(riverContainer)
    }
    
    // MARK: - 3D Forest with Volumetric & Subtle Animated Trees
    private func build3DForest() {
        treesRootNode.childNodes.forEach { $0.removeFromParentNode() }
        
        // Tree coordinates spread over the expanded map
        let treePositions: [(CGFloat, CGFloat, CGFloat)] = [
            (-25, -20, 1.2), (-40, -15, 1.4), (-18, -35, 1.1), (-50, -45, 1.3),
            (35, -25, 1.3), (45, -10, 1.1), (30, -50, 1.4), (60, -40, 1.5),
            (-30, 20, 1.2), (-45, 35, 1.4), (-20, 45, 1.0), (-60, 25, 1.3),
            (35, 25, 1.1), (50, 35, 1.3), (25, 55, 1.2), (60, 50, 1.4),
            (-10, -55, 1.0), (0, 40, 1.2), (-65, -10, 1.3), (70, 15, 1.2),
            (-15, 15, 1.1), (28, -5, 1.2), (-35, -55, 1.4), (45, 60, 1.3)
        ]
        
        for (index, (tx, tz, scale)) in treePositions.enumerated() {
            let treeContainer = SCNNode()
            treeContainer.position = SCNVector3(tx, 0, tz)
            
            // Cross-billboard 3D Tree (2 intersecting planes for true 3D volume)
            let planeW: CGFloat = 5.5 * scale
            let planeH: CGFloat = 7.5 * scale
            
            let treePlaneGeo = SCNPlane(width: planeW, height: planeH)
            let treeMat = SCNMaterial()
            if let image = NSImage(named: "TreeImage") {
                treeMat.diffuse.contents = image
            } else {
                treeMat.diffuse.contents = NSColor(red: 0.1, green: 0.5, blue: 0.2, alpha: 1.0)
            }
            treeMat.isDoubleSided = true
            treeMat.transparent.contents = treeMat.diffuse.contents
            treePlaneGeo.materials = [treeMat]
            
            // Plane 1 (Facing Z)
            let plane1 = SCNNode(geometry: treePlaneGeo)
            plane1.position = SCNVector3(0, planeH / 2, 0)
            plane1.castsShadow = true
            treeContainer.addChildNode(plane1)
            
            // Plane 2 (Facing X - 90 deg rotated)
            let plane2 = SCNNode(geometry: treePlaneGeo)
            plane2.position = SCNVector3(0, planeH / 2, 0)
            plane2.eulerAngles = SCNVector3(0, CGFloat.pi / 2, 0)
            plane2.castsShadow = true
            treeContainer.addChildNode(plane2)
            
            // 🌿 Gentle & Elegant 3D Tree Wind Swaying Animation
            let swayZ: CGFloat = CGFloat(0.022 + Double((index % 5)) * 0.003)
            let swayDuration: Double = 2.8 + Double((index % 7)) * 0.25
            
            let swayRight = SCNAction.rotateTo(x: 0, y: 0, z: swayZ, duration: swayDuration)
            let swayLeft = SCNAction.rotateTo(x: 0, y: 0, z: -swayZ, duration: swayDuration)
            swayRight.timingMode = .easeInEaseOut
            swayLeft.timingMode = .easeInEaseOut
            
            let swaySequence = SCNAction.sequence([swayRight, swayLeft])
            treeContainer.runAction(SCNAction.repeatForever(swaySequence))
            
            // Subtle Leaf Canopy Breathing Scale Animation
            let breatheOut = SCNAction.scale(to: 1.015, duration: swayDuration * 0.9)
            let breatheIn = SCNAction.scale(to: 0.99, duration: swayDuration * 0.9)
            breatheOut.timingMode = .easeInEaseOut
            breatheIn.timingMode = .easeInEaseOut
            let breatheSequence = SCNAction.sequence([breatheOut, breatheIn])
            plane1.runAction(SCNAction.repeatForever(breatheSequence))
            plane2.runAction(SCNAction.repeatForever(breatheSequence))
            
            treesRootNode.addChildNode(treeContainer)
        }
    }
    
    // MARK: - 3D Bushes & Native Flora Construction
    private func build3DBushes() {
        bushesRootNode.childNodes.forEach { $0.removeFromParentNode() }
        
        let bushPositions: [(CGFloat, CGFloat, CGFloat, Bool)] = [
            (-18, -12, 1.1, true), (-32, -28, 0.9, false), (-48, -15, 1.2, true),
            (22, -18, 1.0, true), (38, -32, 1.15, false), (52, -12, 0.95, true),
            (-22, 12, 1.05, false), (-38, 24, 1.2, true), (-12, 32, 0.85, false),
            (24, 18, 1.1, true), (42, 28, 1.25, false), (18, 42, 1.0, true),
            // Along the riverbanks
            (2, -25, 0.9, true), (22, -20, 1.1, false), (3, 5, 1.05, true),
            (21, 10, 0.95, false), (4, 35, 1.15, true), (23, 40, 1.0, true),
            (-55, 10, 1.2, false), (62, 30, 1.1, true), (-5, -45, 0.95, true)
        ]
        
        for (index, (bx, bz, scale, _)) in bushPositions.enumerated() {
            let bushContainer = SCNNode()
            bushContainer.position = SCNVector3(bx, 0, bz)
            
            // Bush Textured 3D Cross-Billboard using "BushImage"
            let planeW: CGFloat = 3.8 * scale
            let planeH: CGFloat = 3.0 * scale
            
            let bushPlaneGeo = SCNPlane(width: planeW, height: planeH)
            let bushMat = SCNMaterial()
            if let image = NSImage(named: "BushImage") {
                bushMat.diffuse.contents = image
            } else {
                bushMat.diffuse.contents = NSColor(red: 0.16, green: 0.44, blue: 0.20, alpha: 1.0)
            }
            bushMat.isDoubleSided = true
            bushMat.transparent.contents = bushMat.diffuse.contents
            bushPlaneGeo.materials = [bushMat]
            
            // Plane 1 (Facing Z)
            let plane1 = SCNNode(geometry: bushPlaneGeo)
            plane1.position = SCNVector3(0, planeH / 2, 0)
            plane1.castsShadow = true
            bushContainer.addChildNode(plane1)
            
            // Plane 2 (Facing X - 90 deg rotated for true 3D volume)
            let plane2 = SCNNode(geometry: bushPlaneGeo)
            plane2.position = SCNVector3(0, planeH / 2, 0)
            plane2.eulerAngles = SCNVector3(0, CGFloat.pi / 2, 0)
            plane2.castsShadow = true
            bushContainer.addChildNode(plane2)
            
            // Gentle wind rustle animation
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
        
        let currentPoints = session.worldPoints.filter { $0.biome == session.currentBiome }
        for point in currentPoints {
            let pointNode = SCNNode()
            let wx = CGFloat(point.x * 0.8)
            let wz = CGFloat(point.y * 0.8)
            pointNode.position = SCNVector3(wx, 0.2, wz)
            
            // Floating beacon sphere
            let beaconGeo = SCNSphere(radius: 1.0)
            let beaconMat = SCNMaterial()
            let isDistress = point.interactionType == .animalInDistress
            beaconMat.diffuse.contents = point.isResolved ? NSColor.systemGray : (isDistress ? NSColor.systemRed : NSColor.systemOrange)
            beaconMat.emission.contents = point.isResolved ? NSColor.black : (isDistress ? NSColor.systemRed.withAlphaComponent(0.6) : NSColor.systemOrange.withAlphaComponent(0.6))
            beaconGeo.materials = [beaconMat]
            
            let beaconNode = SCNNode(geometry: beaconGeo)
            beaconNode.position = SCNVector3(0, 2.2, 0)
            
            // Glowing pulsing animation
            let moveUp = SCNAction.moveBy(x: 0, y: 0.4, z: 0, duration: 1.2)
            let moveDown = SCNAction.moveBy(x: 0, y: -0.4, z: 0, duration: 1.2)
            let sequence = SCNAction.sequence([moveUp, moveDown])
            beaconNode.runAction(SCNAction.repeatForever(sequence))
            
            pointNode.addChildNode(beaconNode)
            
            // Ground Indicator Ring
            let ringGeo = SCNTorus(ringRadius: 1.8, pipeRadius: 0.08)
            let ringMat = SCNMaterial()
            ringMat.diffuse.contents = isDistress ? NSColor.systemRed : NSColor.systemYellow
            ringGeo.materials = [ringMat]
            let ringNode = SCNNode(geometry: ringGeo)
            ringNode.eulerAngles = SCNVector3(0, 0, 0)
            pointNode.addChildNode(ringNode)
            
            worldPointsRootNode.addChildNode(pointNode)
        }
    }
    
    // MARK: - 3D Player Character Node
    private func build3DPlayerNode() {
        playerPlaneGeometry = SCNPlane(width: 2.8, height: 2.8)
        let playerMat = SCNMaterial()
        if let initialImg = NSImage(named: monkeyFrames[0]) {
            playerMat.diffuse.contents = initialImg
        }
        playerMat.isDoubleSided = true
        playerMat.transparent.contents = playerMat.diffuse.contents
        playerPlaneGeometry.materials = [playerMat]
        
        playerNode = SCNNode(geometry: playerPlaneGeometry)
        playerNode.position = SCNVector3(0, 1.4, 0)
        playerNode.castsShadow = true
        scene.rootNode.addChildNode(playerNode)
    }
    
    // MARK: - Position & Subtle Movement Updates
    private func updatePlayer3DPosition(_ pos: CGPoint) {
        let targetX = CGFloat(pos.x * 0.8)
        let targetZ = CGFloat(pos.y * 0.8)
        
        // Detect running direction & facing orientation
        if pos.x < previousPlayerPos.x {
            isFacingLeft = true
            playerNode.scale = SCNVector3(-1, 1, 1)
        } else if pos.x > previousPlayerPos.x {
            isFacingLeft = false
            playerNode.scale = SCNVector3(1, 1, 1)
        }
        previousPlayerPos = pos
        
        // Trigger subtle movement state with gentle bounce
        isMoving = true
        runBouncePhase += 0.8
        let bounceY = 1.4 + CGFloat(abs(sin(runBouncePhase)) * 0.07)
        
        // Smooth camera follow & character position
        let camTargetPos = SCNVector3(targetX, 18, targetZ + zoomDistance)
        let playerTargetPos = SCNVector3(targetX, bounceY, targetZ)
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.18
        playerNode.position = playerTargetPos
        // Subtle forward lean
        playerNode.eulerAngles.z = isFacingLeft ? -0.035 : 0.035
        cameraNode.position = camTargetPos
        SCNTransaction.commit()
        
        // Settle idle state smoothly when movement pauses
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            if !isMoving {
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.20
                playerNode.position.y = 1.4
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
            // Animal Morph Form
            let morphMat = SCNMaterial()
            morphMat.diffuse.contents = species.nativeBiome.nsColor
            morphMat.emission.contents = species.nativeBiome.nsColor.withAlphaComponent(0.4)
            playerPlaneGeometry.materials = [morphMat]
        } else {
            // Revert to Monkey
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
        // Update Fog & Ambient Light
        scene.fogColor = biome.nsColor.withAlphaComponent(0.35)
        scene.fogStartDistance = 45.0
        scene.fogEndDistance = 140.0
        scene.fogDensityExponent = 1.0
        
        ambientLightNode.light?.color = biome.nsColor.withAlphaComponent(0.6)
        
        // Refresh World Points & Bushes
        build3DWorldPoints()
        build3DBushes()
    }
    
    // MARK: - Top Navigation Bar
    private var topNavigationBar: some View {
        HStack(spacing: 14) {
            // Biome Picker
            Menu {
                ForEach(BiomeType.allCases) { biome in
                    Button {
                        session.changeBiome(to: biome)
                    } label: {
                        Label(biome.rawValue, systemImage: biome.iconName)
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: session.currentBiome.iconName)
                        .font(.title3)
                        .foregroundStyle(session.currentBiome.primaryColor)
                    
                    VStack(alignment: .leading, spacing: 1) {
                        HStack(spacing: 6) {
                            Text(session.currentBiome.rawValue)
                                .font(.headline.bold())
                                .foregroundStyle(.white)
                            Text("3D")
                                .font(.caption2.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.blue.opacity(0.6)))
                                .foregroundStyle(.white)
                        }
                        Text(session.currentBiome.description)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.7))
                            .lineLimit(1)
                    }
                    
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial))
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // 3D Camera Zoom
            HStack(spacing: 8) {
                Button {
                    zoomDistance = min(42.0, zoomDistance + 3.0)
                    cameraNode.position.z = zoomDistance
                } label: {
                    Image(systemName: "minus.magnifyingglass")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(6)
                        .background(Circle().fill(.ultraThinMaterial))
                }
                .buttonStyle(.plain)
                
                Button {
                    zoomDistance = max(16.0, zoomDistance - 3.0)
                    cameraNode.position.z = zoomDistance
                } label: {
                    Image(systemName: "plus.magnifyingglass")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(6)
                        .background(Circle().fill(.ultraThinMaterial))
                }
                .buttonStyle(.plain)
            }
            
            // Morph Wheel Button
            Button {
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
            // Proximity Action Banner
            if let nearby = session.getNearbyPoint() {
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
                        Text(nearby.title)
                            .font(.headline.bold())
                            .foregroundStyle(.white)
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
            
            // Movement Controls
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                        .foregroundStyle(.yellow)
                    Text("\(Int(session.playerTransformation.energy))%")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                    Text("• WASD / Setas para mover em 3D")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Capsule().fill(.ultraThinMaterial))
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
