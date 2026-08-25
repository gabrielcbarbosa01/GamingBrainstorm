//
//  CharacterSpriteView.swift
//  GamingBrainstorm
//
//  Created by Gabriel Barbosa on 25/08/26.
//

import SwiftUI
import Combine

public struct CharacterSpriteView: View {
    public let isMoving: Bool
    public let isFacingLeft: Bool
    public let activeSpecies: AnimalSpecies?
    public let energy: Double
    
    @State private var currentFrameIndex: Int = 0
    @State private var idlePhase: Double = 0.0
    
    // 7 Animation frames from Monkey.xcassets
    private let monkeyFrames = [
        "Image",
        "Image 1",
        "Image 2",
        "Image 3",
        "Image 4",
        "Image 5",
        "Image 6"
    ]
    
    // Animation timer for walk cycle (approx 12 FPS when moving)
    private let animationTimer = Timer.publish(every: 0.08, on: .main, in: .common).autoconnect()
    
    public init(
        isMoving: Bool,
        isFacingLeft: Bool,
        activeSpecies: AnimalSpecies? = nil,
        energy: Double = 100.0
    ) {
        self.isMoving = isMoving
        self.isFacingLeft = isFacingLeft
        self.activeSpecies = activeSpecies
        self.energy = energy
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Main Character Sprite
            ZStack {
                if let species = activeSpecies {
                    // Metamorphosed Animal Form with Aura
                    ZStack {
                        // Mystic Metamorphosis Aura
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        species.nativeBiome.primaryColor.opacity(0.6),
                                        species.nativeBiome.primaryColor.opacity(0.1),
                                        .clear
                                    ],
                                    center: .center,
                                    startRadius: 5,
                                    endRadius: 36
                                )
                            )
                            .frame(width: 72, height: 72)
                            .scaleEffect(isMoving ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isMoving)
                        
                        // Animal Icon Avatar
                        Circle()
                            .fill(species.nativeBiome.primaryColor)
                            .frame(width: 52, height: 52)
                            .shadow(color: species.nativeBiome.primaryColor.opacity(0.6), radius: 8)
                        
                        Image(systemName: species.avatarSymbol)
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .offset(y: isMoving ? -sin(idlePhase * 4) * 4 : -sin(idlePhase) * 2)
                    
                } else {
                    // Default Monkey Guardian Character (Animated Sprite Frames)
                    Image(monkeyFrames[currentFrameIndex])
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 74, height: 74)
                        .scaleEffect(x: isFacingLeft ? -1.0 : 1.0, y: 1.0) // Directional flip
                        .offset(y: isMoving ? -abs(sin(Double(currentFrameIndex) * .pi / 3.5)) * 6 : -sin(idlePhase) * 2)
                        .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
                }
            }
            .offset(y: -28) // Elevate above ground contact point
            
            // Dynamic Ground Contact Shadow (Projected onto floor)
            Ellipse()
                .fill(Color.black.opacity(0.45))
                .frame(
                    width: isMoving ? 38 + cos(Double(currentFrameIndex)) * 6 : 42,
                    height: isMoving ? 12 : 14
                )
                .offset(y: -6)
        }
        .onReceive(animationTimer) { _ in
            if isMoving {
                currentFrameIndex = (currentFrameIndex + 1) % monkeyFrames.count
            } else {
                currentFrameIndex = 0
                idlePhase += 0.15
            }
        }
    }
}
