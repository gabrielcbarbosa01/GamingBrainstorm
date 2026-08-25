//
//  SanctuaryManagementView.swift
//  GamingBrainstorm
//
//  Created by Gabriel Barbosa on 25/08/26.
//

import SwiftUI

public struct SanctuaryManagementView: View {
    @Bindable var session: GameSession
    @State private var showingBuildModal = false
    @State private var newHabitatName = ""
    @State private var selectedBiome: BiomeType = .cerrado
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Resources Overview Header
                resourcesHeader
                
                // Habitats Section
                habitatsSection
                
                // Rescued Animals Section
                rescuedAnimalsSection
                
                // Food Storage & Inventory Section
                foodInventorySection
            }
            .padding()
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .sheet(isPresented: $showingBuildModal) {
            buildHabitatSheet
        }
    }
    
    // MARK: - Resources Header
    private var resourcesHeader: some View {
        HStack(spacing: 12) {
            resourceBadge(title: "Pontos de Cuidado", value: "\(session.sanctuary.resources.carePoints)", icon: "heart.circle.fill", color: .pink)
            resourceBadge(title: "Madeira", value: "\(session.sanctuary.resources.wood)", icon: "shippingbox.fill", color: .brown)
            resourceBadge(title: "Pedra", value: "\(session.sanctuary.resources.stone)", icon: "circle.hexagongrid.fill", color: .gray)
            resourceBadge(title: "Água Limpa", value: "\(session.sanctuary.resources.cleanWater)L", icon: "drop.fill", color: .blue)
        }
    }
    
    private func resourceBadge(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.headline.bold())
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(nsColor: .controlBackgroundColor)))
    }
    
    // MARK: - Habitats Section
    private var habitatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Habitats Ecológicos", systemImage: "house.fill")
                    .font(.title2.bold())
                Spacer()
                Button {
                    showingBuildModal = true
                } label: {
                    Label("Construir Habitat", systemImage: "plus")
                        .font(.subheadline.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.accentColor))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 280))], spacing: 14) {
                ForEach(session.sanctuary.habitats) { habitat in
                    habitatCard(habitat: habitat)
                }
            }
        }
    }
    
    private func habitatCard(habitat: SanctuaryHabitat) -> some View {
        let currentAnimals = session.sanctuary.rescuedAnimals.filter { $0.habitatId == habitat.id }
        
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: habitat.biome.iconName)
                    .foregroundStyle(habitat.biome.primaryColor)
                VStack(alignment: .leading) {
                    Text(habitat.name)
                        .font(.headline)
                    Text("Bioma: \(habitat.biome.rawValue) • Nível \(habitat.level)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(currentAnimals.count)/\(habitat.capacity)")
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.gray.opacity(0.2)))
            }
            
            // Cleanliness Bar
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("Higiene do Habitat")
                        .font(.caption2)
                    Spacer()
                    Text("\(Int(habitat.cleanliness))%")
                        .font(.caption2.bold())
                }
                ProgressView(value: habitat.cleanliness, total: 100.0)
                    .tint(.teal)
            }
            
            Divider()
            
            HStack {
                Button {
                    session.cleanHabitat(habitatId: habitat.id)
                } label: {
                    Label("Limpar", systemImage: "sparkles")
                        .font(.caption)
                }
                
                Spacer()
                
                Button {
                    session.upgradeHabitat(habitatId: habitat.id)
                } label: {
                    Label("Upgrade (\(habitat.level * 40) Cuidado)", systemImage: "arrow.up.circle.fill")
                        .font(.caption)
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(nsColor: .controlBackgroundColor)))
    }
    
    // MARK: - Rescued Animals Section
    private var rescuedAnimalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Animais em Reabilitação (\(session.sanctuary.rescuedAnimals.count))", systemImage: "pawprint.fill")
                .font(.title2.bold())
            
            if session.sanctuary.rescuedAnimals.isEmpty {
                Text("Nenhum animal no santuário ainda. Explore os biomas para resgatar animais ameaçados!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(nsColor: .controlBackgroundColor)))
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 300))], spacing: 14) {
                    ForEach(session.sanctuary.rescuedAnimals) { animal in
                        rescuedAnimalCard(animal: animal)
                    }
                }
            }
        }
    }
    
    private func rescuedAnimalCard(animal: RescuedAnimal) -> some View {
        let species = AnimalSpecies.allSpecies.first(where: { $0.id == animal.speciesId })
        let speciesName = species?.commonName ?? animal.speciesId
        let currentHabitat = session.sanctuary.habitats.first(where: { $0.id == animal.habitatId })
        
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Circle()
                    .fill(species?.nativeBiome.primaryColor.opacity(0.3) ?? Color.gray.opacity(0.3))
                    .frame(width: 44, height: 44)
                    .overlay {
                        Image(systemName: species?.avatarSymbol ?? "pawprint")
                            .foregroundStyle(species?.nativeBiome.primaryColor ?? .primary)
                    }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(animal.nickname)
                        .font(.headline)
                    Text(speciesName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Status badge
                if let status = species?.status {
                    Text(status.rawValue)
                        .font(.caption2.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.orange.opacity(0.2)))
                }
            }
            
            // Stats: Hunger, Happiness & Rehabilitation
            VStack(spacing: 6) {
                statRow(label: "Fome (Dieta: \(species?.diet.rawValue ?? ""))", value: 100 - animal.hunger, color: .orange)
                statRow(label: "Felicidade", value: animal.happiness, color: .yellow)
                statRow(label: "Reabilitação", value: animal.rehabilitationProgress, color: .green)
            }
            
            Divider()
            
            HStack {
                // Habitat Selector
                Menu {
                    ForEach(session.sanctuary.habitats) { hab in
                        Button(hab.name) {
                            session.assignAnimal(animalId: animal.id, to: hab.id)
                        }
                    }
                } label: {
                    Text(currentHabitat?.name ?? "Designar Habitat")
                        .font(.caption)
                }
                
                Spacer()
                
                Button {
                    session.feedAnimal(animalId: animal.id)
                } label: {
                    Label("Alimentar", systemImage: species?.diet.iconName ?? "fork.knife")
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.green))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Alimentar \(animal.nickname)")
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(nsColor: .controlBackgroundColor)))
    }
    
    private func statRow(label: String, value: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack {
                Text(label)
                    .font(.caption2)
                Spacer()
                Text("\(Int(value))%")
                    .font(.caption2.bold())
            }
            ProgressView(value: value, total: 100.0)
                .tint(color)
        }
    }
    
    // MARK: - Food Storage Section
    private var foodInventorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Despensa e Alimentos", systemImage: "fork.knife.circle.fill")
                .font(.title2.bold())
            
            HStack(spacing: 12) {
                foodBadge(title: "Frutas e Néctar", qty: session.sanctuary.inventory.fruits, icon: "apple.logo", color: .red)
                foodBadge(title: "Insetos Vivos", qty: session.sanctuary.inventory.insects, icon: "ant.fill", color: .purple)
                foodBadge(title: "Peixes Frescos", qty: session.sanctuary.inventory.freshFish, icon: "fish.fill", color: .blue)
                foodBadge(title: "Plantas Nativas", qty: session.sanctuary.inventory.nativePlants, icon: "leaf.fill", color: .green)
            }
        }
    }
    
    private func foodBadge(title: String, qty: Int, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text("\(qty)")
                .font(.title3.bold())
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(nsColor: .controlBackgroundColor)))
    }
    
    // MARK: - Build Habitat Sheet
    private var buildHabitatSheet: some View {
        VStack(spacing: 20) {
            Text("Construir Novo Habitat")
                .font(.title2.bold())
            
            TextField("Nome do Habitat (ex: Recanto do Cerrado)", text: $newHabitatName)
                .textFieldStyle(.roundedBorder)
            
            Picker("Bioma de Referência", selection: $selectedBiome) {
                ForEach(BiomeType.allCases) { biome in
                    Text(biome.rawValue).tag(biome)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Custo de Construção:")
                    .font(.caption.bold())
                Text("• 40 Madeira (Possui: \(session.sanctuary.resources.wood))")
                    .font(.caption2)
                Text("• 30 Pedra (Possui: \(session.sanctuary.resources.stone))")
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.1)))
            
            HStack {
                Button("Cancelar") {
                    showingBuildModal = false
                }
                
                Spacer()
                
                Button("Construir") {
                    let name = newHabitatName.isEmpty ? "Habitat \(selectedBiome.rawValue)" : newHabitatName
                    session.buildHabitat(name: name, biome: selectedBiome)
                    newHabitatName = ""
                    showingBuildModal = false
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 380)
    }
}
