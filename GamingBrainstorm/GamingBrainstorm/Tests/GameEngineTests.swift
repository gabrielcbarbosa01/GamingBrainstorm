//
//  GameEngineTests.swift
//  GamingBrainstorm
//
//  Created by Gabriel Barbosa on 25/08/26.
//

import Foundation
import CoreGraphics

public struct GameEngineTests {
    public static func runAllTests() -> Bool {
        print("🧪 [TESTS] Iniciando bateria de testes do motor 'Guardião dos Biomas'...")
        var passedCount = 0
        var totalCount = 0
        
        func test(_ name: String, block: () throws -> Void) {
            totalCount += 1
            do {
                try block()
                print("  ✅ [PASS] \(name)")
                passedCount += 1
            } catch {
                print("  ❌ [FAIL] \(name): \(error)")
            }
        }
        
        // 1. Initial State
        test("Estado Inicial do Jogo e Santuário") {
            let session = GameSession()
            assert(session.currentBiome == .mataAtlantica, "Bioma inicial deve ser Mata Atlântica")
            assert(session.playerTransformation.isHuman, "Jogador deve iniciar em forma humana")
            assert(session.playerTransformation.unlockedSpeciesIds.contains("mico-leao-dourado"), "Mico-leão-dourado deve estar desbloqueado inicialmente")
            assert(session.sanctuary.habitats.count >= 1, "Santuário deve começar com pelo menos 1 habitat")
            assert(session.sanctuary.resources.wood >= 40, "Deve ter madeira suficiente")
        }
        
        // 2. Movement & Biome Change
        test("Movimentação e Mudança de Biomas") {
            let session = GameSession()
            session.movePlayer(dx: 2, dy: 3)
            assert(session.playerPosition.x != 0 || session.playerPosition.y != 0, "Jogador deve se mover no plano 2.5D")
            
            session.changeBiome(to: .pantanal)
            assert(session.currentBiome == .pantanal, "Bioma deve mudar para Pantanal")
            assert(session.playerPosition == .zero, "Posição deve ser resetada ao trocar de bioma")
        }
        
        // 3. Transformation Mechanics
        test("Mecânica de Metamorfose e Energia") {
            let session = GameSession()
            let initialEnergy = session.playerTransformation.energy
            
            // Try morphing into an unlocked animal
            let morphSuccess = session.transform(into: "mico-leao-dourado")
            assert(morphSuccess, "Deve conseguir se transformar no Mico-Leão-Dourado")
            assert(!session.playerTransformation.isHuman, "Não deve estar em forma humana")
            assert(session.playerTransformation.energy < initialEnergy, "Energia deve ser consumida na transformação")
            
            // Try morphing into a locked animal
            let lockedMorph = session.transform(into: "ariranha")
            assert(!lockedMorph, "Não deve conseguir se transformar em animal bloqueado")
            
            // Revert to human
            session.transform(into: nil)
            assert(session.playerTransformation.isHuman, "Deve retornar à forma humana")
        }
        
        // 4. World Interaction & Rescue
        test("Investigação e Resgate de Animais") {
            let session = GameSession()
            session.changeBiome(to: .cerrado)
            
            // Find the Lobo-Guará point at (30, 15)
            session.playerPosition = CGPoint(x: 30.0, y: 15.0)
            let nearby = session.getNearbyPoint()
            assert(nearby != nil, "Deve detectar o ponto do Lobo-Guará por proximidade")
            assert(nearby?.associatedSpeciesId == "lobo-guara", "Espécie associada deve ser lobo-guará")
            
            let rescueResult = session.interactWithNearbyPoint()
            assert(rescueResult.success, "Resgate deve ser bem-sucedido")
            assert(session.playerTransformation.unlockedSpeciesIds.contains("lobo-guara"), "Forma do Lobo-Guará deve ser desbloqueada")
            assert(session.sanctuary.rescuedAnimals.contains { $0.speciesId == "lobo-guara" }, "Animal resgatado deve estar no Santuário")
        }
        
        // 5. Sanctuary Habitat Management
        test("Construção e Upgrade de Habitats no Santuário") {
            let session = GameSession()
            let initialHabitatsCount = session.sanctuary.habitats.count
            let initialWood = session.sanctuary.resources.wood
            
            let buildSuccess = session.buildHabitat(name: "Santuário Pantaneiro", biome: .pantanal)
            assert(buildSuccess, "Construção de habitat deve ser bem-sucedida")
            assert(session.sanctuary.habitats.count == initialHabitatsCount + 1, "Contagem de habitats deve aumentar")
            assert(session.sanctuary.resources.wood < initialWood, "Madeira deve ser deduzida")
            
            // Upgrade habitat
            if let newHab = session.sanctuary.habitats.last {
                let initialCapacity = newHab.capacity
                session.sanctuary.resources.carePoints = 100
                let upgradeSuccess = session.upgradeHabitat(habitatId: newHab.id)
                assert(upgradeSuccess, "Upgrade de habitat deve funcionar")
                let upgradedHab = session.sanctuary.habitats.first { $0.id == newHab.id }
                assert(upgradedHab?.capacity == initialCapacity + 1, "Capacidade deve aumentar no upgrade")
            }
        }
        
        // 6. Sanctuary Feeding & Rehabilitation Simulation
        test("Alimentação e Reabilitação de Animais") {
            let session = GameSession()
            guard let animal = session.sanctuary.rescuedAnimals.first else {
                throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Animal não encontrado"])
            }
            
            let initialFruits = session.sanctuary.inventory.fruits
            let initialHunger = animal.hunger
            let initialRehab = animal.rehabilitationProgress
            
            let feedSuccess = session.feedAnimal(animalId: animal.id)
            assert(feedSuccess, "Alimentação do animal deve funcionar")
            assert(session.sanctuary.inventory.fruits < initialFruits, "Frutas devem ser consumidas do inventário")
            
            let fedAnimal = session.sanctuary.rescuedAnimals.first { $0.id == animal.id }
            assert((fedAnimal?.hunger ?? 0) < initialHunger, "Fome do animal deve diminuir")
            assert((fedAnimal?.rehabilitationProgress ?? 0) > initialRehab, "Progresso de reabilitação deve aumentar")
            
            // Simulation Tick
            session.simulationTick()
            assert(session.playerTransformation.energy > 0, "Energia deve regenerar com o tick")
        }
        
        // 7. Biodiversity & Biome Coverage
        test("Cobertura dos Biomas Brasileiros e Espécies Ameaçadas") {
            assert(BiomeType.allCases.count == 6, "Devem existir os 6 biomas brasileiros")
            assert(AnimalSpecies.allSpecies.count >= 6, "Devem existir todas as espécies catalogadas")
            for species in AnimalSpecies.allSpecies {
                assert(!species.transformationPerk.isEmpty, "Espécie \(species.commonName) deve ter habilidade de metamorfose")
                assert(!species.funFact.isEmpty, "Espécie \(species.commonName) deve ter fato educativo")
            }
        }
        
        print("🎯 [TESTS] Resultado: \(passedCount)/\(totalCount) testes passaram com sucesso!\n")
        return passedCount == totalCount
    }
}
