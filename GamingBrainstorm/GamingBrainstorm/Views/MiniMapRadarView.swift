//
//  MiniMapRadarView.swift
//  GamingBrainstorm
//
//  Created by Gabriel Barbosa on 25/08/26.
//

import SwiftUI

public struct MiniMapRadarView: View {
    @Bindable var session: GameSession
    @State private var isExpanded: Bool = false
    
    public init(session: GameSession) {
        self.session = session
    }
    
    // Scale factor: world is 700x700 (-350 to +350)
    // Radar radius: 75px (diameter 150px)
    private var mapScale: Double {
        isExpanded ? 0.35 : 0.19
    }
    
    private var radarSize: CGFloat {
        isExpanded ? 240 : 140
    }
    
    public var body: some View {
        ZStack {
            // Radar Background Ring & Glow
            Circle()
                .fill(Color(red: 0.05, green: 0.12, blue: 0.08).opacity(0.85))
                .overlay(Circle().stroke(Color.green.opacity(0.4), lineWidth: 1.5))
                .shadow(color: .black.opacity(0.5), radius: 10)
            
            // Concentric Range Rings
            Circle()
                .stroke(Color.green.opacity(0.15), lineWidth: 1)
                .frame(width: radarSize * 0.65, height: radarSize * 0.65)
            
            Circle()
                .stroke(Color.green.opacity(0.25), lineWidth: 1)
                .frame(width: radarSize * 0.35, height: radarSize * 0.35)
            
            // Crosshairs
            Rectangle()
                .fill(Color.green.opacity(0.12))
                .frame(width: 1, height: radarSize)
            
            Rectangle()
                .fill(Color.green.opacity(0.12))
                .frame(width: radarSize, height: 1)
            
            // Radar Blips Layer (Centered on Player)
            let center = CGPoint(x: radarSize / 2, y: radarSize / 2)
            
            // 1. Continental River Segment
            let riverWorldX = -15.0
            let riverScreenX = center.x + CGFloat((riverWorldX - session.playerPosition.x) * mapScale)
            if riverScreenX >= 0 && riverScreenX <= radarSize {
                Rectangle()
                    .fill(Color.cyan.opacity(0.6))
                    .frame(width: 4, height: radarSize)
                    .position(x: riverScreenX, y: center.y)
                    .clipShape(Circle())
            }
            
            // 2. Ancient Biome Totems
            ForEach(session.storyEngine.totems) { totem in
                let relX = (totem.position.x - session.playerPosition.x) * mapScale
                let relY = (totem.position.y - session.playerPosition.y) * mapScale
                let dist = hypot(relX, relY)
                
                if dist < Double(radarSize / 2 - 8) {
                    ZStack {
                        Circle()
                            .fill(totem.isPurified ? Color.green : Color.purple)
                            .frame(width: 10, height: 10)
                            .shadow(color: totem.isPurified ? .green : .purple, radius: 4)
                        
                        Image(systemName: totem.isPurified ? "sparkles" : "flame.fill")
                            .font(.system(size: 6))
                            .foregroundStyle(.white)
                    }
                    .position(x: center.x + CGFloat(relX), y: center.y + CGFloat(relY))
                }
            }
            
            // 3. Enemies & Patrol Cones
            ForEach(session.storyEngine.enemies) { enemy in
                if !enemy.isNeutralized {
                    let relX = (enemy.position.x - session.playerPosition.x) * mapScale
                    let relY = (enemy.position.y - session.playerPosition.y) * mapScale
                    let dist = hypot(relX, relY)
                    
                    if dist < Double(radarSize / 2 - 8) {
                        Circle()
                            .fill(enemy.isAlerted ? Color.red : Color.orange)
                            .frame(width: 8, height: 8)
                            .shadow(color: enemy.isAlerted ? .red : .orange, radius: 5)
                            .position(x: center.x + CGFloat(relX), y: center.y + CGFloat(relY))
                    }
                }
            }
            
            // 4. World Points & Rescues
            ForEach(session.worldPoints) { point in
                if !point.isResolved {
                    let relX = (point.x - session.playerPosition.x) * mapScale
                    let relY = (point.y - session.playerPosition.y) * mapScale
                    let dist = hypot(relX, relY)
                    
                    if dist < Double(radarSize / 2 - 8) {
                        Circle()
                            .fill(point.interactionType == .animalInDistress ? Color.yellow : Color.mint)
                            .frame(width: 6, height: 6)
                            .position(x: center.x + CGFloat(relX), y: center.y + CGFloat(relY))
                    }
                }
            }
            
            // 5. Friendly NPCs
            ForEach(session.storyEngine.npcs) { npc in
                let relX = (npc.position.x - session.playerPosition.x) * mapScale
                let relY = (npc.position.y - session.playerPosition.y) * mapScale
                let dist = hypot(relX, relY)
                
                if dist < Double(radarSize / 2 - 8) {
                    Circle()
                        .fill(Color.teal)
                        .frame(width: 7, height: 7)
                        .position(x: center.x + CGFloat(relX), y: center.y + CGFloat(relY))
                }
            }
            
            // 6. Player Center Arrow
            ZStack {
                Circle()
                    .fill(Color.yellow)
                    .frame(width: 9, height: 9)
                    .shadow(color: .yellow, radius: 4)
                
                // Direction indicator
                Image(systemName: "location.north.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(.white)
                    .rotationEffect(.radians(session.playerFacingAngle + Double.pi / 2))
            }
            .position(x: center.x, y: center.y)
            
            // Compass Cardinal Markers
            VStack {
                Text("N")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.green.opacity(0.8))
                Spacer()
                Text("S")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.green.opacity(0.8))
            }
            .padding(4)
            
            HStack {
                Text("O")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.green.opacity(0.8))
                Spacer()
                Text("L")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.green.opacity(0.8))
            }
            .padding(4)
        }
        .frame(width: radarSize, height: radarSize)
        .overlay(alignment: .bottomTrailing) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    isExpanded.toggle()
                }
            } label: {
                Image(systemName: isExpanded ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 10, weight: .bold))
                    .padding(5)
                    .background(Circle().fill(.ultraThinMaterial))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .offset(x: 4, y: 4)
        }
    }
}
