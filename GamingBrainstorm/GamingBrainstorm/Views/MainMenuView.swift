//
//  MainMenuView.swift
//  GamingBrainstorm
//
//  Created by Gabriel Barbosa on 25/08/26.
//

import SwiftUI
import SceneKit

public enum MenuModalSection: String, Identifiable, Sendable {
    case options = "Configurações"
    case biomesGuide = "Guia dos Biomas"
    case credits = "Créditos"
    
    public var id: String { rawValue }
}

public struct MainMenuView: View {
    @Bindable var session: GameSession
    var onStartGame: () -> Void
    var onNewGame: () -> Void
    
    @State private var activeModal: MenuModalSection?
    @State private var menuScene = SCNScene()
    @State private var cameraNode = SCNNode()
    @State private var logoPulse = false
    
    public init(session: GameSession, onStartGame: @escaping () -> Void, onNewGame: @escaping () -> Void) {
        self.session = session
        self.onStartGame = onStartGame
        self.onNewGame = onNewGame
    }
    
    public var body: some View {
        ZStack {
            // 1. 3D Atmospheric Background Viewport
            SceneView(
                scene: menuScene,
                pointOfView: cameraNode,
                options: [.rendersContinuously]
            )
            .ignoresSafeArea()
            
            // Dark Gradient Overlay for Readability
            LinearGradient(
                colors: [
                    Color.black.opacity(0.85),
                    Color.black.opacity(0.40),
                    Color.black.opacity(0.80)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // 2. Main Menu Interactive Interface
            HStack {
                VStack(alignment: .leading, spacing: 28) {
                    Spacer()
                    
                    // Game Title & Emblem
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 12) {
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(.green)
                                .scaleEffect(logoPulse ? 1.15 : 0.95)
                                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: logoPulse)
                            
                            Text("GUARDIÃO DOS BIOMAS")
                                .font(.system(size: 38, weight: .black, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.white, Color(red: 0.85, green: 0.95, blue: 0.88)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .shadow(color: .green.opacity(0.5), radius: 12)
                        }
                        
                        Text("O Despertar da Floresta • Salve a Natureza Brasileira")
                            .font(.title3.weight(.medium))
                            .foregroundStyle(.yellow)
                            .shadow(color: .black, radius: 4)
                        
                        Text("Explore 6 biomas contínuos em 3D, transforme-se em espécies ameaçadas e purifique os Totens Ancestrais.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.85))
                            .frame(maxWidth: 480, alignment: .leading)
                    }
                    .padding(.bottom, 10)
                    
                    // Menu Buttons
                    VStack(alignment: .leading, spacing: 14) {
                        menuButton(
                            title: "Continuar Jornada",
                            subtitle: "Retornar à exploração ativa",
                            icon: "play.fill",
                            primary: true
                        ) {
                            onStartGame()
                        }
                        
                        menuButton(
                            title: "Novo Jogo",
                            subtitle: "Reiniciar história e progresso",
                            icon: "arrow.clockwise",
                            primary: false
                        ) {
                            onNewGame()
                        }
                        
                        menuButton(
                            title: "Guia dos 6 Biomas",
                            subtitle: "Espécies, totens e fauna nativa",
                            icon: "book.pages.fill",
                            primary: false
                        ) {
                            activeModal = .biomesGuide
                        }
                        
                        menuButton(
                            title: "Opções & Áudio",
                            subtitle: "Volumes e atalhos de controle",
                            icon: "slider.horizontal.3",
                            primary: false
                        ) {
                            activeModal = .options
                        }
                        
                        menuButton(
                            title: "Créditos",
                            subtitle: "Sobre o projeto e conservação",
                            icon: "info.circle.fill",
                            primary: false
                        ) {
                            activeModal = .credits
                        }
                    }
                    
                    Spacer()
                    
                    // Version & Platform Badge
                    HStack(spacing: 8) {
                        Text("Versão 1.5.0 (3D SceneKit + SwiftUI)")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.6))
                        Text("•")
                            .foregroundStyle(.white.opacity(0.4))
                        Text("Apple Academy Challenge")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
                .padding(.leading, 60)
                .padding(.vertical, 40)
                
                Spacer()
            }
            
            // 3. Modal Overlays
            if let modal = activeModal {
                modalOverlay(section: modal)
            }
        }
        .onAppear {
            setupMenuScene()
            logoPulse = true
        }
    }
    
    // MARK: - Menu Button Component
    private func menuButton(
        title: String,
        subtitle: String,
        icon: String,
        primary: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(primary ? Color.green : Color.white.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.title3.bold())
                        .foregroundStyle(primary ? .black : .white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.4))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .frame(width: 380)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(primary ? Color.green.opacity(0.25) : Color.black.opacity(0.45))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(primary ? Color.green : Color.white.opacity(0.15), lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Modal Overlay View
    private func modalOverlay(section: MenuModalSection) -> some View {
        ZStack {
            Color.black.opacity(0.75)
                .ignoresSafeArea()
                .onTapGesture {
                    activeModal = nil
                }
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Label(section.rawValue, systemImage: modalIcon(for: section))
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    Spacer()
                    Button {
                        activeModal = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                }
                .padding(20)
                .background(Color.black.opacity(0.6))
                
                Divider()
                
                // Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        switch section {
                        case .options:
                            optionsView
                        case .biomesGuide:
                            biomesGuideView
                        case .credits:
                            creditsView
                        }
                    }
                    .padding(24)
                }
            }
            .frame(width: 640, height: 500)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(red: 0.08, green: 0.12, blue: 0.10))
                    .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.green.opacity(0.4), lineWidth: 1.5))
            )
            .shadow(color: .black.opacity(0.8), radius: 24)
        }
    }
    
    private func modalIcon(for section: MenuModalSection) -> String {
        switch section {
        case .options: return "slider.horizontal.3"
        case .biomesGuide: return "book.pages.fill"
        case .credits: return "info.circle.fill"
        }
    }
    
    // MARK: - Options & Audio Settings
    private var optionsView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Configurações de Áudio Procedural")
                .font(.headline)
                .foregroundStyle(.green)
            
            Toggle("Silenciar Todos os Sons", isOn: Binding(
                get: { SoundManager.shared.isMuted },
                set: { SoundManager.shared.isMuted = $0 }
            ))
            .toggleStyle(.switch)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Volume dos Efeitos Sonoros (SFX): \(Int(SoundManager.shared.sfxVolume * 100))%")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
                Slider(value: Binding(
                    get: { Double(SoundManager.shared.sfxVolume) },
                    set: { SoundManager.shared.sfxVolume = Float($0) }
                ), in: 0...1)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Volume dos Passos (Footsteps): \(Int(SoundManager.shared.footstepVolume * 100))%")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
                Slider(value: Binding(
                    get: { Double(SoundManager.shared.footstepVolume) },
                    set: { SoundManager.shared.footstepVolume = Float($0) }
                ), in: 0...1)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Volume da Trilha Sonora Procedural: \(Int(SoundManager.shared.musicVolume * 100))%")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
                Slider(value: Binding(
                    get: { Double(SoundManager.shared.musicVolume) },
                    set: { SoundManager.shared.musicVolume = Float($0) }
                ), in: 0...1)
            }
            
            Divider()
            
            Text("Guia Rápido de Teclado & Controles")
                .font(.headline)
                .foregroundStyle(.yellow)
            
            VStack(alignment: .leading, spacing: 8) {
                keyRow(keys: "W, A, S, D / Setas", action: "Movimentar o Guardião pelo mundo aberto")
                keyRow(keys: "Espaço", action: "Interagir / Resgatar / Purificar Totem / Falar com NPC")
                keyRow(keys: "1 a 6", action: "Metamorfose instantânea em animal")
                keyRow(keys: "0", action: "Retornar à forma humana")
                keyRow(keys: "T", action: "Abrir Roda de Metamorfose")
                keyRow(keys: "Esc", action: "Abrir Menu Principal / Pausa")
            }
        }
    }
    
    private func keyRow(keys: String, action: String) -> some View {
        HStack(spacing: 12) {
            Text(keys)
                .font(.system(.caption, design: .monospaced).bold())
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.15)))
                .foregroundStyle(.yellow)
                .frame(width: 140, alignment: .leading)
            
            Text(action)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.85))
        }
    }
    
    // MARK: - Biomes Guide
    private var biomesGuideView: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Os 6 Grandes Biomas Brasileiros")
                .font(.headline)
                .foregroundStyle(.green)
            
            ForEach(BiomeType.allCases, id: \.self) { biome in
                HStack(spacing: 14) {
                    Circle()
                        .fill(biome.primaryColor.opacity(0.3))
                        .frame(width: 36, height: 36)
                        .overlay {
                            Image(systemName: biome.iconName)
                                .foregroundStyle(biome.primaryColor)
                        }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(biome.rawValue)
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                        Text(biome.description)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
            }
        }
    }
    
    // MARK: - Credits
    private var creditsView: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Guardião dos Biomas")
                .font(.title3.bold())
                .foregroundStyle(.green)
            
            Text("Um jogo desenvolvido como tributo à rica biodiversidade dos biomas brasileiros, combinando exploração 3D em tempo real, mecânicas de metamorfose animal, gestão ecológica de santuário e síntese sonora procedural nativa.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
            
            Divider()
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Tecnologias Utilizadas:")
                    .font(.subheadline.bold())
                    .foregroundStyle(.yellow)
                Text("• SwiftUI para interface nativa reativa e declarativa")
                    .font(.caption)
                Text("• SceneKit para mundo aberto 3D contínuo, sombras, luzes e partículas")
                    .font(.caption)
                Text("• AVAudioEngine para síntese sonora procedural e passos adaptativos")
                    .font(.caption)
                Text("• Observation framework com arquitetura orientada a domínio")
                    .font(.caption)
            }
            .foregroundStyle(.white.opacity(0.8))
        }
    }
    
    // MARK: - 3D Menu Background Setup
    private func setupMenuScene() {
        menuScene = SCNScene()
        
        // 1. Camera Node (Slow orbit)
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 8, 22)
        cameraNode.eulerAngles = SCNVector3(-0.25, 0, 0)
        
        let orbit = SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 45.0)
        let cameraPivot = SCNNode()
        cameraPivot.addChildNode(cameraNode)
        cameraPivot.runAction(SCNAction.repeatForever(orbit))
        menuScene.rootNode.addChildNode(cameraPivot)
        
        // 2. Sunlight
        let sunNode = SCNNode()
        let sun = SCNLight()
        sun.type = .directional
        sun.color = NSColor(red: 1.0, green: 0.85, blue: 0.60, alpha: 1.0)
        sun.castsShadow = true
        sunNode.light = sun
        sunNode.position = SCNVector3(20, 30, 20)
        sunNode.eulerAngles = SCNVector3(-0.6, 0.4, 0)
        menuScene.rootNode.addChildNode(sunNode)
        
        // 3. Ambient Light
        let ambientNode = SCNNode()
        let ambient = SCNLight()
        ambient.type = .ambient
        ambient.color = NSColor(red: 0.25, green: 0.35, blue: 0.30, alpha: 1.0)
        ambientNode.light = ambient
        menuScene.rootNode.addChildNode(ambientNode)
        
        // 4. Forest Ground
        let groundGeo = SCNCylinder(radius: 35, height: 1.0)
        let groundMat = SCNMaterial()
        groundMat.diffuse.contents = NSColor(red: 0.12, green: 0.28, blue: 0.15, alpha: 1.0)
        groundGeo.materials = [groundMat]
        let groundNode = SCNNode(geometry: groundGeo)
        groundNode.position = SCNVector3(0, -0.5, 0)
        menuScene.rootNode.addChildNode(groundNode)
        
        // 5. Decorative 3D Trees & Ancient Totem in Background
        for i in 0..<18 {
            let angle = Double(i) * (Double.pi * 2 / 18.0)
            let radius = Double.random(in: 12...28)
            let tx = cos(angle) * radius
            let tz = sin(angle) * radius
            
            let trunkGeo = SCNCylinder(radius: 0.35, height: 4.5)
            let trunkMat = SCNMaterial()
            trunkMat.diffuse.contents = NSColor(red: 0.40, green: 0.25, blue: 0.15, alpha: 1.0)
            trunkGeo.materials = [trunkMat]
            let trunkNode = SCNNode(geometry: trunkGeo)
            trunkNode.position = SCNVector3(tx, 2.25, tz)
            
            let foliageGeo = SCNCone(topRadius: 0.1, bottomRadius: 2.2, height: 4.0)
            let foliageMat = SCNMaterial()
            foliageMat.diffuse.contents = NSColor(red: 0.15, green: 0.45, blue: 0.22, alpha: 1.0)
            foliageGeo.materials = [foliageMat]
            let foliageNode = SCNNode(geometry: foliageGeo)
            foliageNode.position = SCNVector3(0, 3.2, 0)
            trunkNode.addChildNode(foliageNode)
            
            menuScene.rootNode.addChildNode(trunkNode)
        }
        
        // 6. Glowing Bioluminescent Fireflies Particle System
        let pNode = SCNNode()
        let ps = SCNParticleSystem()
        ps.particleColor = NSColor(red: 0.95, green: 1.0, blue: 0.35, alpha: 0.85)
        ps.particleSize = 0.3
        ps.birthRate = 20
        ps.particleLifeSpan = 4.0
        ps.emitterShape = SCNBox(width: 30, height: 10, length: 30, chamferRadius: 0)
        ps.acceleration = SCNVector3(0, 0.3, 0)
        pNode.position = SCNVector3(0, 4, 0)
        pNode.addParticleSystem(ps)
        menuScene.rootNode.addChildNode(pNode)
    }
}
