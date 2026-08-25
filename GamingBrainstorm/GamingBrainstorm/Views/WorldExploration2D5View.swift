//
//  WorldExploration2D5View.swift
//  GamingBrainstorm
//
//  Created by Gabriel Barbosa on 25/08/26.
//

import SwiftUI
import Combine

public struct WorldExploration2D5View: View {
    @Bindable var session: GameSession
    @State private var showingTransformWheel = false
    @State private var isMoving = false
    @State private var isFacingLeft = false
    @State private var windPhase: Double = 0.0
    @State private var zoomScale: CGFloat = 1.35
    
    // Ambient Simulation & Movement Loop
    private let tickTimer = Timer.publish(every: 2.0, on: .main, in: .common).autoconnect()
    private let animationTimer = Timer.publish(every: 0.03, on: .main, in: .common).autoconnect()
    
    public var body: some View {
        let env = BiomeEnvironmentSet.environment(for: session.currentBiome)
        
        ZStack {
            // 1. Sky & Ambient Lighting Background
            LinearGradient(
                colors: [
                    env.groundBaseColor.opacity(0.85),
                    env.groundAccentColor.opacity(0.95),
                    Color.black.opacity(0.8)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // 2. Main 2.5D World Viewport
            GeometryReader { geo in
                let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                let cameraOffset = session.playerPosition
                
                ZStack {
                    // 2.1 Organic Ground Terrain Canvas
                    groundTerrainCanvas(size: geo.size, center: center, cameraOffset: cameraOffset, env: env)
                    
                    // 2.2 Depth-Sorted In-World Billboard Entities
                    inWorldDepthSortedEntities(center: center, cameraOffset: cameraOffset, env: env)
                    
                    // 2.3 Atmospheric Volumetric Lighting (God Rays & Canopy Shadow)
                    canopyVolumetricLighting(size: geo.size, env: env)
                    
                    // 2.4 Floating Atmospheric Spores & Leaves
                    ambientParticlesOverlay(size: geo.size)
                }
                .scaleEffect(zoomScale)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
            }
            
            // 3. Vignette Ambient Shade
            RadialGradient(
                colors: [.clear, .black.opacity(0.45)],
                center: .center,
                startRadius: 280,
                endRadius: 700
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)
            
            // 4. Overlaid HUD & Top Navigation
            VStack {
                topNavigationBar(env: env)
                Spacer()
                bottomInteractiveHUD
            }
            
            // 5. Metamorphosis Wheel Modal
            if showingTransformWheel {
                TransformationWheelView(session: session, isPresented: $showingTransformWheel)
                    .transition(.opacity.combined(with: .scale(0.95)))
                    .zIndex(9999)
            }
        }
        .onReceive(tickTimer) { _ in
            session.simulationTick()
        }
        .onReceive(animationTimer) { _ in
            windPhase += 0.04
        }
    }
    
    // MARK: - Top Navigation Bar
    private func topNavigationBar(env: BiomeEnvironmentSet) -> some View {
        HStack(alignment: .center, spacing: 14) {
            // Biome Selector Menu
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
                        Text(session.currentBiome.rawValue)
                            .font(.headline.bold())
                            .foregroundStyle(.white)
                        Text(session.currentBiome.description)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.7))
                            .lineLimit(1)
                    }
                    
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(.leading, 4)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(session.currentBiome.primaryColor.opacity(0.4), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Alterar bioma. Atual: \(session.currentBiome.rawValue)")
            
            Spacer()
            
            // Zoom Controls
            HStack(spacing: 8) {
                Button {
                    zoomScale = max(0.9, zoomScale - 0.15)
                } label: {
                    Image(systemName: "minus.magnifyingglass")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(6)
                        .background(Circle().fill(.ultraThinMaterial))
                }
                .buttonStyle(.plain)
                
                Button {
                    zoomScale = min(1.8, zoomScale + 0.15)
                } label: {
                    Image(systemName: "plus.magnifyingglass")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(6)
                        .background(Circle().fill(.ultraThinMaterial))
                }
                .buttonStyle(.plain)
            }
            
            // Transformation State & Morph Wheel Button
            Button {
                showingTransformWheel = true
            } label: {
                HStack(spacing: 8) {
                    if let species = session.activeSpecies {
                        Image(systemName: species.avatarSymbol)
                            .font(.headline)
                            .foregroundStyle(.yellow)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(species.commonName)
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                            Text(species.transformationPerk)
                                .font(.caption2)
                                .foregroundStyle(.yellow)
                        }
                    } else {
                        Image(systemName: "sparkles")
                            .font(.headline)
                            .foregroundStyle(.yellow)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Guardião Macaco")
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                            Text("Metamorfose [T]")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThickMaterial))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.yellow.opacity(0.8), lineWidth: 1.5))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Abrir câmara de metamorfose")
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }
    
    // MARK: - Ground Terrain Canvas
    private func groundTerrainCanvas(
        size: CGSize,
        center: CGPoint,
        cameraOffset: CGPoint,
        env: BiomeEnvironmentSet
    ) -> some View {
        Canvas { context, canvasSize in
            let worldOffsetX = center.x - cameraOffset.x * 2.8
            let worldOffsetY = center.y - cameraOffset.y * 2.0
            
            context.translateBy(x: worldOffsetX, y: worldOffsetY)
            
            // Base Ground Soil Plane
            let groundRect = CGRect(x: -900, y: -700, width: 1800, height: 1400)
            context.fill(Path(groundRect), with: .color(env.groundBaseColor))
            
            // Organic Grass / Earth Color Patches
            let biomeIndex = abs(session.currentBiome.rawValue.hashValue % 100)
            for i in 0..<24 {
                let px = Double(((biomeIndex + i * 17) * 31) % 1200) - 600.0
                let py = Double(((biomeIndex + i * 23) * 47) % 900) - 450.0
                let patchW = Double(90 + (i * 17) % 120)
                let patchH = Double(50 + (i * 13) % 70)
                
                let patchPath = Path(ellipseIn: CGRect(x: px - patchW/2, y: py - patchH/2, width: patchW, height: patchH))
                context.fill(patchPath, with: .color(env.groundAccentColor.opacity(0.65)))
            }
            
            // Natural River / Stream Path
            var riverPath = Path()
            riverPath.move(to: CGPoint(x: -800, y: -250))
            riverPath.addCurve(
                to: CGPoint(x: 800, y: 350),
                control1: CGPoint(x: -200, y: 100),
                control2: CGPoint(x: 300, y: -300)
            )
            
            // River Bed Outline & Water Flow
            context.stroke(riverPath, with: .color(Color(red: 0.1, green: 0.35, blue: 0.45).opacity(0.4)), lineWidth: 42)
            context.stroke(riverPath, with: .color(Color(red: 0.18, green: 0.62, blue: 0.76).opacity(0.85)), lineWidth: 28)
            // Animated flowing river current and foam streaks
            context.stroke(riverPath, with: .color(Color.white.opacity(0.45)), style: StrokeStyle(lineWidth: 4, dash: [16, 28], dashPhase: CGFloat(windPhase * 55)))
            context.stroke(riverPath, with: .color(Color.cyan.opacity(0.35)), style: StrokeStyle(lineWidth: 10, dash: [35, 55], dashPhase: CGFloat(windPhase * 35)))
            
            // Ground Dirt Pathways
            var dirtTrail = Path()
            dirtTrail.move(to: CGPoint(x: -400, y: 400))
            dirtTrail.addQuadCurve(to: CGPoint(x: 400, y: -300), control: CGPoint(x: 50, y: 50))
            context.stroke(dirtTrail, with: .color(Color.brown.opacity(0.25)), lineWidth: 32)
        }
    }
    
    // MARK: - In-World Depth-Sorted Entities (Z-Sorted Billboards)
    private func inWorldDepthSortedEntities(
        center: CGPoint,
        cameraOffset: CGPoint,
        env: BiomeEnvironmentSet
    ) -> some View {
        ZStack {
            // 1. Ground Foliage (below tree bases)
            ForEach(env.foliage) { item in
                let sx = center.x + (item.x - cameraOffset.x) * 2.8
                let sy = center.y + (item.y - cameraOffset.y) * 2.0
                
                VStack(spacing: 0) {
                    Image(systemName: item.symbolName)
                        .font(.system(size: item.size))
                        .foregroundStyle(item.tintColor)
                        .shadow(color: .black.opacity(0.3), radius: 2)
                        .offset(y: -item.size / 2)
                    
                    Ellipse()
                        .fill(Color.black.opacity(0.25))
                        .frame(width: item.size * 1.2, height: item.size * 0.4)
                }
                .position(x: sx, y: sy)
                .zIndex(item.y)
            }
            
            // 2. Bushes & Native Flora
            ForEach(env.bushes) { bush in
                let sx = center.x + (bush.x - cameraOffset.x) * 2.8
                let sy = center.y + (bush.y - cameraOffset.y) * 2.0
                let rustle = sin(windPhase * 1.4 + Double(bush.x)) * 1.5
                
                bushBillboardView(bush: bush, rustleAngle: rustle)
                    .position(x: sx, y: sy)
                    .zIndex(bush.y)
            }
            
            // 3. Interactive World Points (Animals in distress, Clues, Rescues)
            let pointsInBiome = session.worldPoints.filter { $0.biome == session.currentBiome }
            ForEach(pointsInBiome) { point in
                let sx = center.x + (point.x - cameraOffset.x) * 2.8
                let sy = center.y + (point.y - cameraOffset.y) * 2.0
                
                worldPointInteractiveBillboard(point: point)
                    .position(x: sx, y: sy)
                    .zIndex(point.y) // Depth Y-Sort
            }
            
            // 4. Tree Billboards (TreeImage from Tree.xcassets)
            ForEach(env.trees) { tree in
                let sx = center.x + (tree.x - cameraOffset.x) * 2.8
                let sy = center.y + (tree.y - cameraOffset.y) * 2.0
                let swayAngle = sin(windPhase * 1.4 + tree.swayOffset * 4.0) * 2.2
                let scaleW = 1.0 + sin(windPhase * 1.2 + tree.swayOffset * 2.0) * 0.02
                let scaleH = 1.0 + cos(windPhase * 1.2 + tree.swayOffset * 2.0) * 0.015
                
                treeBillboardView(tree: tree, swayAngle: swayAngle, scaleW: scaleW, scaleH: scaleH)
                    .position(x: sx, y: sy)
                    .zIndex(tree.y) // Depth Y-Sort: Player walks behind or in front!
            }
            
            // 5. Player Animated Character (Monkey.xcassets)
            CharacterSpriteView(
                isMoving: isMoving,
                isFacingLeft: isFacingLeft,
                activeSpecies: session.activeSpecies,
                energy: session.playerTransformation.energy
            )
            .position(x: center.x, y: center.y)
            .zIndex(session.playerPosition.y) // Dynamic Player Depth
        }
    }
    
    // MARK: - Bush Billboard View (Using BushImage asset)
    private func bushBillboardView(bush: BushItem, rustleAngle: Double) -> some View {
        VStack(spacing: 0) {
            // Standing Bush Sprite Billboard
            Image("BushImage")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 85 * bush.scale, height: 68 * bush.scale)
                .rotationEffect(.degrees(rustleAngle), anchor: .bottom)
                .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
                .offset(y: -26 * bush.scale) // Anchor bottom base to ground position
            
            // Ground Contact Shadow
            Ellipse()
                .fill(Color.black.opacity(0.35))
                .frame(width: 55 * bush.scale, height: 14 * bush.scale)
                .offset(y: -6)
        }
    }
    
    // MARK: - Tree Billboard View (Using TreeImage asset)
    private func treeBillboardView(tree: TreeBillboardItem, swayAngle: Double, scaleW: Double, scaleH: Double) -> some View {
        VStack(spacing: 0) {
            // Standing Tree Sprite Billboard
            Image("TreeImage")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 140 * tree.scale, height: 190 * tree.scale)
                .scaleEffect(x: scaleW, y: scaleH, anchor: .bottom)
                .rotationEffect(.degrees(swayAngle), anchor: .bottom)
                .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
                .offset(y: -85 * tree.scale) // Anchor bottom trunk to ground position
            
            // Ground Trunk Contact Shadow
            Ellipse()
                .fill(Color.black.opacity(0.45))
                .frame(width: 75 * tree.scale, height: 24 * tree.scale)
                .offset(y: -12)
        }
    }
    
    // MARK: - World Point Interactive Billboard
    private func worldPointInteractiveBillboard(point: WorldPoint) -> some View {
        VStack(spacing: 0) {
            ZStack {
                if !point.isResolved {
                    // Pulsing beacon aura
                    Circle()
                        .stroke(point.interactionType == .animalInDistress ? Color.red : Color.yellow, lineWidth: 3)
                        .frame(width: 60, height: 60)
                        .scaleEffect(1.0 + sin(windPhase * 3) * 0.15)
                        .opacity(0.8)
                }
                
                // Outer Badge
                Circle()
                    .fill(
                        point.isResolved
                        ? LinearGradient(colors: [.gray, .secondary], startPoint: .top, endPoint: .bottom)
                        : (point.interactionType == .animalInDistress
                           ? LinearGradient(colors: [.red, Color(red: 0.8, green: 0.1, blue: 0.1)], startPoint: .top, endPoint: .bottom)
                           : LinearGradient(colors: [.orange, .yellow], startPoint: .top, endPoint: .bottom))
                    )
                    .frame(width: 48, height: 48)
                    .shadow(color: point.interactionType == .animalInDistress ? .red.opacity(0.7) : .yellow.opacity(0.5), radius: 8)
                
                // Icon
                Image(systemName: pointIcon(for: point.interactionType))
                    .font(.title3.bold())
                    .foregroundStyle(.white)
            }
            .offset(y: -24)
            
            // Ground Contact Shadow
            Ellipse()
                .fill(Color.black.opacity(0.35))
                .frame(width: 38, height: 12)
        }
    }
    
    private func pointIcon(for type: WorldInteractionType) -> String {
        switch type {
        case .animalInDistress: return "heart.fill"
        case .ecologicalClue: return "magnifyingglass"
        case .terrainObstacle: return "exclamationmark.triangle.fill"
        case .resourceCache: return "bag.fill"
        }
    }
    
    // MARK: - Canopy Volumetric Lighting (God Rays)
    private func canopyVolumetricLighting(size: CGSize, env: BiomeEnvironmentSet) -> some View {
        Canvas { context, canvasSize in
            // Draw soft diagonal sunlight beams through the trees
            let rayCount = 5
            for i in 0..<rayCount {
                let startX = CGFloat(i) * (canvasSize.width / CGFloat(rayCount)) + 40
                var rayPath = Path()
                rayPath.move(to: CGPoint(x: startX, y: 0))
                rayPath.addLine(to: CGPoint(x: startX + 180, y: canvasSize.height))
                rayPath.addLine(to: CGPoint(x: startX + 240, y: canvasSize.height))
                rayPath.addLine(to: CGPoint(x: startX + 40, y: 0))
                rayPath.closeSubpath()
                
                context.fill(
                    rayPath,
                    with: .linearGradient(
                        Gradient(colors: [
                            Color.yellow.opacity(0.12),
                            Color.white.opacity(0.04),
                            .clear
                        ]),
                        startPoint: CGPoint(x: startX, y: 0),
                        endPoint: CGPoint(x: startX + 200, y: canvasSize.height)
                    )
                )
            }
        }
        .allowsHitTesting(false)
    }
    
    // MARK: - Ambient Particles (Falling Leaves & Spores)
    private func ambientParticlesOverlay(size: CGSize) -> some View {
        Canvas { context, canvasSize in
            let particleCount = 18
            for i in 0..<particleCount {
                let phase = windPhase + Double(i * 13)
                let px = (sin(phase * 0.7) * 0.5 + 0.5) * Double(canvasSize.width)
                let py = (phase.truncatingRemainder(dividingBy: 10.0) / 10.0) * Double(canvasSize.height)
                
                let leafRect = CGRect(x: px, y: py, width: 8, height: 5)
                context.fill(
                    Path(ellipseIn: leafRect),
                    with: .color(session.currentBiome.primaryColor.opacity(0.4))
                )
            }
        }
        .allowsHitTesting(false)
    }
    
    // MARK: - Bottom Interactive HUD
    private var bottomInteractiveHUD: some View {
        VStack(spacing: 12) {
            // Proximity Context Alert Box
            if let nearby = session.getNearbyPoint() {
                HStack(spacing: 14) {
                    Circle()
                        .fill(nearby.interactionType == .animalInDistress ? Color.red : Color.orange)
                        .frame(width: 44, height: 44)
                        .overlay {
                            Image(systemName: pointIcon(for: nearby.interactionType))
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
                        
                        if let perk = nearby.requiredPerk {
                            HStack(spacing: 4) {
                                Image(systemName: "sparkles")
                                Text("Requer: \(perk)")
                            }
                            .font(.caption2.bold())
                            .foregroundStyle(.yellow)
                        }
                    }
                    
                    Spacer()
                    
                    Button {
                        session.interactWithNearbyPoint()
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
                        .shadow(color: .green.opacity(0.5), radius: 6)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Interagir e resgatar animal")
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 20).fill(.ultraThickMaterial))
                .padding(.horizontal)
            }
            
            // Movement & Controls Bar
            HStack(alignment: .center) {
                // Keyboard Guide & Energy
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .foregroundStyle(.yellow)
                        Text("\(Int(session.playerTransformation.energy))%")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(.ultraThinMaterial))
                    
                    Text("WASD / Setas para mover • T para Metamorfose")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }
                .padding(.leading)
                
                Spacer()
                
                // Directional D-Pad Controls
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
            .padding(.bottom, 6)
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
        if dx < 0 { isFacingLeft = true }
        if dx > 0 { isFacingLeft = false }
        isMoving = true
        session.movePlayer(dx: dx, dy: dy)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            isMoving = false
        }
    }
}
