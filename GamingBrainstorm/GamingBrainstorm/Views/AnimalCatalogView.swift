//
//  AnimalCatalogView.swift
//  GamingBrainstorm
//
//  Created by Gabriel Barbosa on 25/08/26.
//

import SwiftUI

public struct AnimalCatalogView: View {
    @Bindable var session: GameSession
    @State private var selectedBiomeFilter: BiomeType? = nil
    @State private var selectedSpecies: AnimalSpecies? = nil
    
    public var body: some View {
        HSplitView {
            // Left Column: Interactive Biome Map & Species List
            VStack(spacing: 0) {
                // Biome Filter Pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        Button {
                            selectedBiomeFilter = nil
                        } label: {
                            Text("Todos os Biomas")
                                .font(.caption.bold())
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(selectedBiomeFilter == nil ? Color.accentColor : Color.gray.opacity(0.2)))
                                .foregroundStyle(selectedBiomeFilter == nil ? .white : .primary)
                        }
                        .buttonStyle(.plain)
                        
                        ForEach(BiomeType.allCases) { biome in
                            Button {
                                selectedBiomeFilter = biome
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: biome.iconName)
                                    Text(biome.rawValue)
                                }
                                .font(.caption.bold())
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(selectedBiomeFilter == biome ? biome.primaryColor : Color.gray.opacity(0.2)))
                                .foregroundStyle(selectedBiomeFilter == biome ? .white : .primary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
                
                Divider()
                
                // List of Species
                List(selection: $selectedSpecies) {
                    let filtered = AnimalSpecies.allSpecies.filter { species in
                        if let filter = selectedBiomeFilter {
                            return species.nativeBiome == filter
                        }
                        return true
                    }
                    
                    ForEach(filtered) { species in
                        let isUnlocked = session.playerTransformation.unlockedSpeciesIds.contains(species.id)
                        let rescuedCount = session.sanctuary.rescuedAnimals.filter { $0.speciesId == species.id }.count
                        
                        HStack(spacing: 12) {
                            Circle()
                                .fill(isUnlocked ? species.nativeBiome.primaryColor.opacity(0.3) : Color.gray.opacity(0.2))
                                .frame(width: 40, height: 40)
                                .overlay {
                                    Image(systemName: isUnlocked ? species.avatarSymbol : "lock.fill")
                                        .foregroundStyle(isUnlocked ? species.nativeBiome.primaryColor : .secondary)
                                }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(species.commonName)
                                        .font(.headline)
                                    if !isUnlocked {
                                        Text("(Não avistado)")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Text(species.scientificName)
                                    .font(.caption.italic())
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            if rescuedCount > 0 {
                                Text("\(rescuedCount) no Santuário")
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Capsule().fill(Color.green.opacity(0.2)))
                                    .foregroundStyle(.green)
                            }
                        }
                        .tag(species)
                        .padding(.vertical, 4)
                    }
                }
            }
            .frame(minWidth: 320, maxWidth: 420)
            
            // Right Column: Detailed Animal Codex & Biome Insights
            if let species = selectedSpecies ?? AnimalSpecies.allSpecies.first {
                speciesDetailView(species: species)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Text("Selecione uma espécie para ver os dados ecológicos.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            if selectedSpecies == nil {
                selectedSpecies = AnimalSpecies.allSpecies.first
            }
        }
    }
    
    // MARK: - Species Detail View
    private func speciesDetailView(species: AnimalSpecies) -> some View {
        let isUnlocked = session.playerTransformation.unlockedSpeciesIds.contains(species.id)
        
        return ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Card
                HStack(spacing: 16) {
                    Circle()
                        .fill(species.nativeBiome.primaryColor.opacity(0.25))
                        .frame(width: 72, height: 72)
                        .overlay {
                            Image(systemName: isUnlocked ? species.avatarSymbol : "questionmark")
                                .font(.system(size: 32))
                                .foregroundStyle(species.nativeBiome.primaryColor)
                        }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(species.commonName)
                            .font(.title.bold())
                        Text(species.scientificName)
                            .font(.subheadline.italic())
                            .foregroundStyle(.secondary)
                        
                        HStack(spacing: 8) {
                            // Biome Badge
                            Label(species.nativeBiome.rawValue, systemImage: species.nativeBiome.iconName)
                                .font(.caption.bold())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(species.nativeBiome.primaryColor.opacity(0.2)))
                            
                            // Conservation Status Badge
                            Text(species.status.rawValue)
                                .font(.caption.bold())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color.orange.opacity(0.2)))
                        }
                    }
                    Spacer()
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 16).fill(Color(nsColor: .controlBackgroundColor)))
                
                // Metamorphic Power Card
                VStack(alignment: .leading, spacing: 8) {
                    Label("Habilidade de Metamorfose: \(species.transformationPerk)", systemImage: "sparkles")
                        .font(.headline)
                        .foregroundStyle(.yellow)
                    
                    Text(species.transformationDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color(nsColor: .controlBackgroundColor)))
                
                // Ecological Needs & Diet
                VStack(alignment: .leading, spacing: 14) {
                    Text("Requisitos Ecológicos")
                        .font(.headline)
                    
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Dieta Natural", systemImage: species.diet.iconName)
                                .font(.subheadline.bold())
                            Text(species.diet.rawValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Divider().frame(height: 36)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Habitat Ideal", systemImage: "leaf.fill")
                                .font(.subheadline.bold())
                            Text(species.habitatNeeds)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color(nsColor: .controlBackgroundColor)))
                
                // Educational Fact
                VStack(alignment: .leading, spacing: 8) {
                    Label("Você Sabia?", systemImage: "lightbulb.fill")
                        .font(.headline)
                        .foregroundStyle(.yellow)
                    
                    Text(species.funFact)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color(nsColor: .controlBackgroundColor)))
                
                // Biome Threats
                VStack(alignment: .leading, spacing: 8) {
                    Label("Ameaças ao Bioma (\(species.nativeBiome.rawValue))", systemImage: "exclamationmark.triangle.fill")
                        .font(.headline)
                        .foregroundStyle(.red)
                    
                    ForEach(species.nativeBiome.typicalHazards, id: \.self) { hazard in
                        HStack(spacing: 6) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 6))
                                .foregroundStyle(.red)
                            Text(hazard)
                                .font(.caption)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color(nsColor: .controlBackgroundColor)))
            }
            .padding()
        }
    }
}
