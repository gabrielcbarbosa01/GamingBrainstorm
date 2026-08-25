//
//  TransformationWheelView.swift
//  GamingBrainstorm
//
//  Created by Gabriel Barbosa on 25/08/26.
//

import SwiftUI

public struct TransformationWheelView: View {
    @Bindable var session: GameSession
    @Binding var isPresented: Bool
    
    public var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            VStack(spacing: 20) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.yellow)
                    Text("Câmara de Metamorfose")
                        .font(.title2.bold())
                    Spacer()
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Fechar câmara de metamorfose")
                }
                .padding(.horizontal)
                
                Text("Assuma a forma de um animal resgatado para herdar suas habilidades e investigar ameaças no bioma.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                
                // Energy Bar
                HStack {
                    Image(systemName: "bolt.fill")
                        .foregroundStyle(.yellow)
                    ProgressView(value: session.playerTransformation.energy, total: session.playerTransformation.maxEnergy)
                        .tint(.yellow)
                    Text("\(Int(session.playerTransformation.energy))%")
                        .font(.caption.monospacedDigit().bold())
                }
                .padding(.horizontal)
                
                // Grid of Forms
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 14) {
                    // Default Human Guardian Form
                    Button {
                        session.transform(into: nil)
                        isPresented = false
                    } label: {
                        VStack(spacing: 8) {
                            Circle()
                                .fill(session.playerTransformation.isHuman ? Color.blue : Color.gray.opacity(0.3))
                                .frame(width: 54, height: 54)
                                .overlay {
                                    Image(systemName: "figure.walk")
                                        .font(.title2)
                                        .foregroundStyle(.white)
                                }
                            Text("Guardião Humano")
                                .font(.headline)
                            Text("Forma padrão")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color(nsColor: .controlBackgroundColor).opacity(0.9)))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(session.playerTransformation.isHuman ? Color.blue : Color.clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                    
                    // Unlocked Animal Species
                    ForEach(AnimalSpecies.allSpecies) { species in
                        let isUnlocked = session.playerTransformation.unlockedSpeciesIds.contains(species.id)
                        let isActive = session.playerTransformation.activeSpeciesId == species.id
                        
                        Button {
                            if isUnlocked {
                                session.transform(into: species.id)
                                isPresented = false
                            }
                        } label: {
                            VStack(spacing: 8) {
                                Circle()
                                    .fill(isActive ? species.nativeBiome.primaryColor : (isUnlocked ? Color.gray.opacity(0.4) : Color.gray.opacity(0.15)))
                                    .frame(width: 54, height: 54)
                                    .overlay {
                                        if isUnlocked {
                                            Image(systemName: species.avatarSymbol)
                                                .font(.title2)
                                                .foregroundStyle(.white)
                                        } else {
                                            Image(systemName: "lock.fill")
                                                .font(.title3)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                
                                Text(species.commonName)
                                    .font(.headline)
                                    .lineLimit(1)
                                
                                Text(isUnlocked ? species.transformationPerk : "Resgate para desbloquear")
                                    .font(.caption2)
                                    .foregroundStyle(isUnlocked ? .primary : .secondary)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(RoundedRectangle(cornerRadius: 16).fill(Color(nsColor: .controlBackgroundColor).opacity(0.9)))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(isActive ? species.nativeBiome.primaryColor : Color.clear, lineWidth: 2)
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(!isUnlocked)
                        .opacity(isUnlocked ? 1.0 : 0.6)
                        .accessibilityLabel(isUnlocked ? "Transformar em \(species.commonName), habilidade: \(species.transformationPerk)" : "\(species.commonName), bloqueado")
                    }
                }
                .padding()
            }
            .padding()
            .frame(maxWidth: 640)
            .background(RoundedRectangle(cornerRadius: 24).fill(Material.ultraThick))
            .shadow(radius: 20)
            .padding()
        }
    }
}
