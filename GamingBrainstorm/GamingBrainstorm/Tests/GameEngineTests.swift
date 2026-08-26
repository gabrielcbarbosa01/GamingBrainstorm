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
        
        // 2. Movement & Dynamic Biome Transition
        test("Movimentação Contínua e Detecção Automática de Biomas") {
            let session = GameSession()
            let initialPos = session.playerPosition
            session.movePlayer(dx: 2, dy: 3)
            assert(session.playerPosition != initialPos, "Jogador deve se mover no plano do mundo aberto")
            
            // Walking into Amazon coordinates
            session.playerPosition = CGPoint(x: -160, y: -200)
            session.movePlayer(dx: 0, dy: -1)
            assert(session.currentBiome == .amazonia, "Bioma deve ser detectado automaticamente como Amazônia")
            
            // Walking into Caatinga coordinates
            session.playerPosition = CGPoint(x: 160, y: -200)
            session.movePlayer(dx: 1, dy: 0)
            assert(session.currentBiome == .caatinga, "Bioma deve ser detectado automaticamente como Caatinga")
            
            // Walking into Pampa coordinates
            session.playerPosition = CGPoint(x: 0, y: 280)
            session.movePlayer(dx: 0, dy: 1)
            assert(session.currentBiome == .pampa, "Bioma deve ser detectado automaticamente como Pampa")
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
            
            // Approach Lobo-Guará point in Cerrado at (130, 0)
            session.playerPosition = CGPoint(x: 130.0, y: 0.0)
            let nearby = session.getNearbyPoint()
            assert(nearby != nil, "Deve detectar o ponto do Lobo-Guará por proximidade no mundo aberto")
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
        
        // 8. Story Quests & NPC Dialogue
        test("Sistema Narrativo, Missões e Diálogos de NPCs") {
            let session = GameSession()
            assert(session.storyEngine.currentQuest != nil, "Deve existir uma missão de história ativa")
            assert(session.storyEngine.isDialoguePresented, "Diálogo introdutório do Capítulo 1 deve iniciar apresentado")
            
            // Advance dialogue
            session.storyEngine.advanceDialogue()
            
            // Talk to Poti Arara NPC
            session.playerPosition = CGPoint(x: -80, y: -190)
            let result = session.interactWithNearbyPoint()
            assert(result.success, "Deve conseguir conversar com a Arara Poti")
            
            let currentQuest = session.storyEngine.currentQuest
            let talkObj = currentQuest?.objectives.first { $0.id == "obj_talk_poti" }
            assert(talkObj?.isCompleted == true, "Objetivo de conversar com Poti deve ser concluído")
        }
        
        // 9. Enemies, Patrols and Totem Purification
        test("Encontros com Inimigos, Patrulha e Purificação de Totens") {
            let session = GameSession()
            
            // Unlock Ariranha with Nado Veloz perk for testing
            session.playerTransformation.unlock(speciesId: "ariranha")
            let morphOk = session.transform(into: "ariranha")
            assert(morphOk, "Transformação em Ariranha deve ser realizada com sucesso")
            assert(session.activeSpecies?.id == "ariranha", "Deve estar na forma de Ariranha")
            
            // Approach wildfire enemy in Amazon at (-95, -260)
            session.playerPosition = CGPoint(x: -95, y: -260)
            let enemyResult = session.interactWithNearbyPoint()
            assert(enemyResult.success, "Deve conseguir neutralizar a labareda usando a forma aquática")
            
            // Approach and Purify Amazon Totem at (-200, -250)
            session.playerPosition = CGPoint(x: -200, y: -250)
            let totemResult = session.interactWithNearbyPoint()
            assert(totemResult.success, "Deve conseguir purificar o Totem da Amazônia")
            
            let totem = session.storyEngine.totems.first { $0.id == "totem_amazonia" }
            assert(totem?.isPurified == true, "Totem da Amazônia deve estar purificado")
        }
        
        // 10. Day/Night Cycle, Weather and Quick Morph Shortcuts
        test("Ciclo Dia/Noite, Clima Dinâmico e Atalhos Numéricos de Metamorfose") {
            let session = GameSession()
            
            // Advance atmosphere clock through all phases
            assert(session.atmosphere.currentTimeOfDay == .noon, "Deve iniciar por volta do meio-dia")
            session.atmosphere.timeOfDayProgress = 0.85
            assert(session.atmosphere.currentTimeOfDay == .night, "Deve alternar para a Noite")
            assert(session.atmosphere.currentTimeOfDay.stealthBonusActive, "Bônus de furtividade deve estar ativo à noite")
            
            // Biome weather check
            assert(session.atmosphere.weatherForBiome(.amazonia) == .fireflies, "À noite deve ter vagalumes na Amazônia")
            session.atmosphere.timeOfDayProgress = 0.40
            assert(session.atmosphere.weatherForBiome(.amazonia) == .tropicalRain, "De dia deve ter chuva tropical na Amazônia")
            assert(session.atmosphere.weatherForBiome(.caatinga) == .heatHaze, "De dia deve ter calor na Caatinga")
            
            // Test Quick Morph Shortcuts (Keys 1-6 & 0)
            let morphMico = session.morphQuick(index: 1)
            assert(morphMico, "Tecla 1 deve metamorfosear no Mico-Leão-Dourado")
            assert(session.activeSpecies?.id == "mico-leao-dourado", "Espécie ativa deve ser mico")
            
            let morphHuman = session.morphQuick(index: 0)
            assert(morphHuman, "Tecla 0 deve retornar à forma humana")
            assert(session.playerTransformation.isHuman, "Deve estar humano")
        }
        
        // 11. Free Roaming Ambient Wild Fauna
        test("Fauna Silvestre Livre e Fuga Reativa") {
            let session = GameSession()
            assert(session.ambientFauna.wildFauna.count >= 10, "Devem existir animais selvagens livres no mapa")
            
            guard let initialCapy = session.ambientFauna.wildFauna.first(where: { $0.type == .capybara }) else {
                throw NSError(domain: "Test", code: 2, userInfo: [NSLocalizedDescriptionKey: "Capivara não encontrada"])
            }
            
            // Approach capybara with player
            session.playerPosition = initialCapy.position
            session.ambientFauna.update(deltaTime: 0.1, playerPos: session.playerPosition, enemies: session.storyEngine.enemies)
            
            let reactiveCapy = session.ambientFauna.wildFauna.first(where: { $0.id == initialCapy.id })
            assert(reactiveCapy?.isScattering == true, "Capivara deve se assustar e dispersar na presença de perigo")
        }
        
        print("🎯 [TESTS] Resultado: \(passedCount)/\(totalCount) testes passaram com sucesso!\n")
        return passedCount == totalCount
    }
}
