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
        "Monkey_0",
        "Monkey_1",
        "Monkey_2",
        "Monkey_3",
        "Monkey_4",
        "Monkey_5",
        "Monkey_6"
    ]
    
    // Smooth natural cadence timer (~11 FPS)
    private let animationTimer = Timer.publish(every: 0.09, on: .main, in: .common).autoconnect()
    
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
            // Main Character Sprite & Gentle Movement Effects
            ZStack {
                // Subtle Footstep Dust
                if isMoving {
                    HStack(spacing: 3) {
                        Circle()
                            .fill(Color.white.opacity(0.20))
                            .frame(width: 6, height: 6)
                        Circle()
                            .fill(Color.white.opacity(0.12))
                            .frame(width: 4, height: 4)
                    }
                    .offset(x: isFacingLeft ? 20 : -20, y: 14)
                    .opacity(isMoving ? 0.6 : 0.0)
                    .animation(.easeOut(duration: 0.3), value: currentFrameIndex)
                }
                
                if let species = activeSpecies {
                    // Metamorphosed Animal Form with Subtle Aura
                    ZStack {
                        // Mystic Metamorphosis Aura
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        species.nativeBiome.primaryColor.opacity(0.45),
                                        species.nativeBiome.primaryColor.opacity(0.10),
                                        .clear
                                    ],
                                    center: .center,
                                    startRadius: 4,
                                    endRadius: 32
                                )
                            )
                            .frame(width: 68, height: 68)
                            .scaleEffect(isMoving ? 1.05 : 1.0)
                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isMoving)
                        
                        // Animal Icon Avatar
                        Circle()
                            .fill(species.nativeBiome.primaryColor)
                            .frame(width: 50, height: 50)
                            .shadow(color: species.nativeBiome.primaryColor.opacity(0.4), radius: 6)
                        
                        Image(systemName: species.avatarSymbol)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .rotationEffect(.degrees(isMoving ? (isFacingLeft ? -2.0 : 2.0) : 0))
                    .offset(y: isMoving ? -abs(sin(Double(currentFrameIndex) * .pi / 3.0)) * 3.5 : -sin(idlePhase) * 1.5)
                    
                } else {
                    // Default Monkey Guardian Character (Subtle Animation Cadence)
                    Image(monkeyFrames[currentFrameIndex])
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 74, height: 74)
                        // Directional Flip + Subtle Squash/Stretch
                        .scaleEffect(
                            x: isFacingLeft ? -1.0 : 1.0,
                            y: isMoving ? (1.0 + sin(Double(currentFrameIndex) * .pi / 3.0) * 0.025) : 1.0
                        )
                        // Gentle Movement Lean
                        .rotationEffect(.degrees(isMoving ? (isFacingLeft ? -2.5 : 2.5) : 0))
                        // Subtle Vertical Step Stride
                        .offset(y: isMoving ? -abs(sin(Double(currentFrameIndex) * .pi / 3.5)) * 3.5 : -sin(idlePhase) * 1.5)
                        .shadow(color: .black.opacity(0.22), radius: 3, y: 2)
                }
            }
            .offset(y: -26) // Elevate above ground contact point
            
            // Dynamic Ground Contact Shadow (Soft & Subtle)
            Ellipse()
                .fill(Color.black.opacity(0.38))
                .frame(
                    width: isMoving ? 38 + cos(Double(currentFrameIndex) * 1.2) * 3.0 : 40,
                    height: isMoving ? 11 : 12
                )
                .offset(y: -6)
        }
        .onReceive(animationTimer) { _ in
            if isMoving {
                currentFrameIndex = (currentFrameIndex + 1) % monkeyFrames.count
            } else {
                currentFrameIndex = 0
                idlePhase += 0.08
            }
        }
    }
}
