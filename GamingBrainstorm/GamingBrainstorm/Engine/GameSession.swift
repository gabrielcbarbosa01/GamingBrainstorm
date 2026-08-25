//
//  GameSession.swift
//  GamingBrainstorm
//
//  Created by Gabriel Barbosa on 25/08/26.
//

import Foundation
import SwiftUI
import Observation

@Observable
public final class GameSession: @unchecked Sendable {
    // Current Active Exploration Biome
    public var currentBiome: BiomeType = .mataAtlantica
    
    // Player In-World Coordinates (-80 to 80)
    public var playerPosition: CGPoint = .zero
    public var playerFacingAngle: Double = 0.0
    
    // Core States
    public var playerTransformation: PlayerTransformationState
    public var sanctuary: SanctuaryState
    public var worldPoints: [WorldPoint]
    
    // UI Event Notification
    public var recentNotification: String?
    
    public init() {
        // Start with Mico-Leão-Dourado unlocked for the initial demo/prototype
        let initialUnlocked: Set<String> = ["mico-leao-dourado"]
        self.playerTransformation = PlayerTransformationState(
            activeSpeciesId: nil,
            energy: 100.0,
            maxEnergy: 100.0,
            unlockedSpeciesIds: initialUnlocked
        )
        
        // Initial Sanctuary setup
        let initialHabitat = SanctuaryHabitat(name: "Reserva da Mata Atlântica", biome: .mataAtlantica)
        let initialAnimal = RescuedAnimal(
            speciesId: "mico-leao-dourado",
            nickname: "Douradinho",
            health: 75.0,
            hunger: 30.0,
            happiness: 60.0,
            rehabilitationProgress: 40.0,
            habitatId: initialHabitat.id
        )
        
        self.sanctuary = SanctuaryState(
            habitats: [initialHabitat],
            rescuedAnimals: [initialAnimal],
            inventory: FoodInventory(fruits: 25, insects: 20, freshFish: 15, nativePlants: 30),
            resources: SanctuaryResources(wood: 120, stone: 80, cleanWater: 150, carePoints: 100)
        )
        
        // Generate World Points for each biome
        self.worldPoints = GameSession.generateInitialWorldPoints()
    }
    
    // MARK: - Exploration & Movement
    public func changeBiome(to biome: BiomeType) {
        currentBiome = biome
        playerPosition = .zero
        recentNotification = "Entrou no bioma: \(biome.rawValue)"
    }
    
    public func movePlayer(dx: Double, dy: Double) {
        let speed = (playerTransformation.activeSpeciesId != nil) ? 5.0 : 3.5
        let newX = min(max(playerPosition.x + dx * speed, -80), 80)
        let newY = min(max(playerPosition.y + dy * speed, -80), 80)
        
        if dx != 0 || dy != 0 {
            playerFacingAngle = atan2(dy, dx)
        }
        
        playerPosition = CGPoint(x: newX, y: newY)
    }
    
    // MARK: - Transformation
    @discardableResult
    public func transform(into speciesId: String?) -> Bool {
        let success = playerTransformation.morph(into: speciesId)
        if success {
            if let id = speciesId, let species = AnimalSpecies.allSpecies.first(where: { $0.id == id }) {
                recentNotification = "Metamorfose em \(species.commonName)! Habilidade: \(species.transformationPerk)"
            } else {
                recentNotification = "Retornou à forma humana do Guardião."
            }
        } else {
            recentNotification = "Energia insuficiente ou forma não desbloqueada!"
        }
        return success
    }
    
    public var activeSpecies: AnimalSpecies? {
        guard let id = playerTransformation.activeSpeciesId else { return nil }
        return AnimalSpecies.allSpecies.first(where: { $0.id == id })
    }
    
    // MARK: - World Interaction & Rescue
    public func getNearbyPoint() -> WorldPoint? {
        let interactionRadius: Double = 18.0
        return worldPoints.first { point in
            guard point.biome == currentBiome && !point.isResolved else { return false }
            let dist = hypot(point.x - playerPosition.x, point.y - playerPosition.y)
            return dist <= interactionRadius
        }
    }
    
    @discardableResult
    public func interactWithNearbyPoint() -> (success: Bool, message: String) {
        guard let point = getNearbyPoint() else {
            return (false, "Nenhum ponto de interesse próximo.")
        }
        
        // Check if a specific transformation perk is needed
        if let requiredPerk = point.requiredPerk {
            guard let active = activeSpecies, active.transformationPerk.contains(requiredPerk) || requiredPerk.contains(active.transformationPerk) else {
                let msg = "Ação bloqueada! É necessária a habilidade: \(requiredPerk). Transforme-se no animal correspondente para investigar."
                recentNotification = msg
                return (false, msg)
            }
        }
        
        // Resolve interaction
        if let idx = worldPoints.firstIndex(where: { $0.id == point.id }) {
            worldPoints[idx].isResolved = true
        }
        
        switch point.interactionType {
        case .animalInDistress:
            if let speciesId = point.associatedSpeciesId, let species = AnimalSpecies.allSpecies.first(where: { $0.id == speciesId }) {
                // Unlock transformation
                playerTransformation.unlock(speciesId: speciesId)
                
                // Add to Sanctuary
                let newAnimal = RescuedAnimal(
                    speciesId: speciesId,
                    nickname: "\(species.commonName) Resgatado",
                    health: 50.0,
                    hunger: 70.0,
                    happiness: 40.0,
                    rehabilitationProgress: 15.0
                )
                sanctuary.rescuedAnimals.append(newAnimal)
                sanctuary.resources.carePoints += 50
                
                let msg = "🎉 Você resgatou um \(species.commonName)! Ele foi levado ao Santuário e sua forma de metamorfose foi DESBLOQUEADA!"
                recentNotification = msg
                return (true, msg)
            }
            
        case .ecologicalClue:
            sanctuary.resources.carePoints += 30
            playerTransformation.regenerateEnergy(amount: 25.0)
            let msg = "🔍 Pista ecológica investigada: \(point.description) (+30 Pontos de Cuidado, +25 Energia)"
            recentNotification = msg
            return (true, msg)
            
        case .terrainObstacle:
            sanctuary.resources.wood += 20
            sanctuary.resources.stone += 15
            let msg = "Obstáculo superado com sua forma animal! Coletados materiais para o santuário."
            recentNotification = msg
            return (true, msg)
            
        case .resourceCache:
            sanctuary.inventory.fruits += 10
            sanctuary.inventory.nativePlants += 10
            sanctuary.inventory.freshFish += 5
            sanctuary.inventory.insects += 10
            let msg = "🌾 Provisões colhidas na natureza e enviadas ao Santuário!"
            recentNotification = msg
            return (true, msg)
        }
        
        return (true, "Interação concluída com sucesso.")
    }
    
    // MARK: - Sanctuary Management
    @discardableResult
    public func buildHabitat(name: String, biome: BiomeType) -> Bool {
        let woodCost = 40
        let stoneCost = 30
        guard sanctuary.resources.wood >= woodCost && sanctuary.resources.stone >= stoneCost else {
            recentNotification = "Recursos insuficientes para construir habitat! (Requer: \(woodCost) Madeira, \(stoneCost) Pedra)"
            return false
        }
        
        sanctuary.resources.wood -= woodCost
        sanctuary.resources.stone -= stoneCost
        let newHabitat = SanctuaryHabitat(name: name, biome: biome)
        sanctuary.habitats.append(newHabitat)
        recentNotification = "Novo habitat '\(name)' construído com sucesso!"
        return true
    }
    
    @discardableResult
    public func upgradeHabitat(habitatId: UUID) -> Bool {
        guard let idx = sanctuary.habitats.firstIndex(where: { $0.id == habitatId }) else { return false }
        let cost = sanctuary.habitats[idx].level * 40
        guard sanctuary.resources.carePoints >= cost else {
            recentNotification = "Pontos de Cuidado insuficientes para upgrade! (Requer: \(cost))"
            return false
        }
        
        sanctuary.resources.carePoints -= cost
        sanctuary.habitats[idx].level += 1
        sanctuary.habitats[idx].capacity += 1
        sanctuary.habitats[idx].cleanliness = 100.0
        recentNotification = "Habitat '\(sanctuary.habitats[idx].name)' aprimorado para Nível \(sanctuary.habitats[idx].level)!"
        return true
    }
    
    @discardableResult
    public func assignAnimal(animalId: UUID, to habitatId: UUID) -> Bool {
        guard let animalIdx = sanctuary.rescuedAnimals.firstIndex(where: { $0.id == animalId }),
              let habitat = sanctuary.habitats.first(where: { $0.id == habitatId }) else {
            return false
        }
        
        let currentCount = sanctuary.rescuedAnimals.filter { $0.habitatId == habitatId }.count
        guard currentCount < habitat.capacity else {
            recentNotification = "O habitat '\(habitat.name)' já atingiu a capacidade máxima (\(habitat.capacity))!"
            return false
        }
        
        sanctuary.rescuedAnimals[animalIdx].habitatId = habitatId
        recentNotification = "\(sanctuary.rescuedAnimals[animalIdx].nickname) foi acomodado em '\(habitat.name)'."
        return true
    }
    
    @discardableResult
    public func feedAnimal(animalId: UUID) -> Bool {
        guard let idx = sanctuary.rescuedAnimals.firstIndex(where: { $0.id == animalId }) else { return false }
        let speciesId = sanctuary.rescuedAnimals[idx].speciesId
        guard let species = AnimalSpecies.allSpecies.first(where: { $0.id == speciesId }) else { return false }
        
        let consumed = sanctuary.inventory.consume(for: species.diet, amount: 1)
        guard consumed else {
            recentNotification = "Sem comida do tipo \(species.diet.rawValue) disponível no inventário!"
            return false
        }
        
        sanctuary.rescuedAnimals[idx].hunger = max(0, sanctuary.rescuedAnimals[idx].hunger - 40.0)
        sanctuary.rescuedAnimals[idx].happiness = min(100.0, sanctuary.rescuedAnimals[idx].happiness + 25.0)
        sanctuary.rescuedAnimals[idx].health = min(100.0, sanctuary.rescuedAnimals[idx].health + 15.0)
        sanctuary.rescuedAnimals[idx].rehabilitationProgress = min(100.0, sanctuary.rescuedAnimals[idx].rehabilitationProgress + 10.0)
        
        sanctuary.resources.carePoints += 15
        recentNotification = "\(sanctuary.rescuedAnimals[idx].nickname) foi alimentado com \(species.diet.rawValue)! (+15 Pontos de Cuidado)"
        return true
    }
    
    @discardableResult
    public func cleanHabitat(habitatId: UUID) -> Bool {
        guard let idx = sanctuary.habitats.firstIndex(where: { $0.id == habitatId }) else { return false }
        guard sanctuary.resources.cleanWater >= 15 else {
            recentNotification = "Água limpa insuficiente! (Requer: 15L)"
            return false
        }
        sanctuary.resources.cleanWater -= 15
        sanctuary.habitats[idx].cleanliness = 100.0
        
        // Boost happiness of animals in this habitat
        for i in 0..<sanctuary.rescuedAnimals.count where sanctuary.rescuedAnimals[i].habitatId == habitatId {
            sanctuary.rescuedAnimals[i].happiness = min(100.0, sanctuary.rescuedAnimals[i].happiness + 15.0)
        }
        recentNotification = "Habitat '\(sanctuary.habitats[idx].name)' higienizado!"
        return true
    }
    
    // MARK: - Simulation Tick (Game Loop simulation)
    public func simulationTick() {
        playerTransformation.regenerateEnergy(amount: 5.0)
        
        // Update Sanctuary animals & generate care points
        for i in 0..<sanctuary.rescuedAnimals.count {
            // Hunger slowly increases
            sanctuary.rescuedAnimals[i].hunger = min(100.0, sanctuary.rescuedAnimals[i].hunger + 2.0)
            
            // Check habitat comfort
            if let habId = sanctuary.rescuedAnimals[i].habitatId,
               let habitat = sanctuary.habitats.first(where: { $0.id == habId }) {
                let species = AnimalSpecies.allSpecies.first(where: { $0.id == sanctuary.rescuedAnimals[i].speciesId })
                let isBiomeMatch = species?.nativeBiome == habitat.biome
                
                if isBiomeMatch && sanctuary.rescuedAnimals[i].hunger < 50 {
                    sanctuary.rescuedAnimals[i].rehabilitationProgress = min(100.0, sanctuary.rescuedAnimals[i].rehabilitationProgress + 2.0)
                    sanctuary.resources.carePoints += 2
                }
            } else {
                // Without a habitat, happiness drops
                sanctuary.rescuedAnimals[i].happiness = max(0, sanctuary.rescuedAnimals[i].happiness - 3.0)
            }
        }
    }
    
    // MARK: - World Points Generator
    private static func generateInitialWorldPoints() -> [WorldPoint] {
        return [
            // Mata Atlântica
            WorldPoint(
                biome: .mataAtlantica,
                x: 25.0,
                y: -30.0,
                interactionType: .ecologicalClue,
                title: "Pegadas de Primatas no Dossel",
                description: "Marcas de garras e cascas de frutos roídas indicam passagem de micos.",
                requiredPerk: "Escalada Ágil"
            ),
            WorldPoint(
                biome: .mataAtlantica,
                x: -35.0,
                y: 20.0,
                interactionType: .resourceCache,
                title: "Bosque de Bromélias Nativas",
                description: "Bromélias ricas em néctar e água acumulada.",
                requiredPerk: nil
            ),
            
            // Cerrado
            WorldPoint(
                biome: .cerrado,
                x: 30.0,
                y: 15.0,
                interactionType: .animalInDistress,
                title: "Lobo-Guará Encurralado",
                description: "Um lobo-guará ferido está cercado por queimadas recentes. Aproxime-se para resgatá-lo.",
                associatedSpeciesId: "lobo-guara",
                requiredPerk: nil
            ),
            WorldPoint(
                biome: .cerrado,
                x: -20.0,
                y: -25.0,
                interactionType: .ecologicalClue,
                title: "Arbusto de Lobeira",
                description: "Frutos maduros de lobeira caídos ao chão.",
                requiredPerk: "Faro Rastreador"
            ),
            
            // Pantanal
            WorldPoint(
                biome: .pantanal,
                x: -15.0,
                y: 35.0,
                interactionType: .animalInDistress,
                title: "Onça-Pintada em Ilha de Seca",
                description: "Uma onça jovem isolada após alteração no curso d'água.",
                associatedSpeciesId: "onca-pintada",
                requiredPerk: "Nado Veloz"
            ),
            
            // Caatinga
            WorldPoint(
                biome: .caatinga,
                x: 40.0,
                y: -10.0,
                interactionType: .animalInDistress,
                title: "Tatu-Bola sob Rocha Quebradiça",
                description: "Um tatu-bola precisa de ajuda para desobstruir uma fenda no solo pedregoso.",
                associatedSpeciesId: "tatu-bola",
                requiredPerk: nil
            ),
            
            // Amazônia
            WorldPoint(
                biome: .amazonia,
                x: -30.0,
                y: -30.0,
                interactionType: .animalInDistress,
                title: "Família de Ariranhas Isolada",
                description: "Troncos caídos bloquearam o igarapé onde a ariranha caçava peixes.",
                associatedSpeciesId: "ariranha",
                requiredPerk: "Garras Rompedoras"
            ),
            
            // Pampa
            WorldPoint(
                biome: .pampa,
                x: 20.0,
                y: 40.0,
                interactionType: .animalInDistress,
                title: "Tamanduá-Bandeira Preso em Cerca",
                description: "Tamanduá-bandeira precisa de auxílio para retornar aos campos abertos.",
                associatedSpeciesId: "tamandua-bandeira",
                requiredPerk: nil
            )
        ]
    }
}
