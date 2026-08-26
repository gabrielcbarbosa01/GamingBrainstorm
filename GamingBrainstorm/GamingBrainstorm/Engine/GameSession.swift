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
    // Current Active Biome Region (Dynamically calculated based on coordinates)
    public var currentBiome: BiomeType = .mataAtlantica
    
    // Player In-World Coordinates (-350 to +350 across vast open world)
    public var playerPosition: CGPoint = CGPoint(x: 50.0, y: 140.0) // Start in Mata Atlântica
    public var playerFacingAngle: Double = 0.0
    
    // Core States
    public var playerTransformation: PlayerTransformationState
    public var sanctuary: SanctuaryState
    public var worldPoints: [WorldPoint]
    public var storyEngine: StoryEngine = StoryEngine()
    public var atmosphere: AtmosphereState = AtmosphereState()
    public var ambientFauna: AmbientFaunaEngine = AmbientFaunaEngine()
    
    // Active Mystical Portals (Refúgio Raízes Arc & Biome Return Portals)
    public var activePortals: [BiomePortal] = []
    
    // UI Event Notification & Biome Announcements
    public var recentNotification: String?
    
    public init() {
        // Start with Mico-Leão-Dourado unlocked for the initial demo
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
        
        // Generate World Points and Portals across the unified grand map
        self.worldPoints = GameSession.generateInitialWorldPoints()
        self.activePortals = GameSession.generateInitialPortals()
        self.currentBiome = GameSession.biomeForPosition(x: playerPosition.x, y: playerPosition.y)
        
        // Start Chapter 1 intro dialogue
        if let intro = self.storyEngine.currentQuest?.introDialogue {
            self.storyEngine.startDialogue(lines: intro)
        }
    }
    
    // MARK: - Open World Seamless Biome Detection
    public static func biomeForPosition(x: Double, y: Double) -> BiomeType {
        if y < -80 {
            return x < 0 ? .amazonia : .caatinga
        } else if y < 80 {
            return x < -30 ? .pantanal : .cerrado
        } else if y < 220 {
            return x < -60 ? .pantanal : .mataAtlantica
        } else {
            return .pampa
        }
    }
    
    // MARK: - Exploration & Movement
    public func changeBiome(to biome: BiomeType) {
        currentBiome = biome
        switch biome {
        case .amazonia: playerPosition = CGPoint(x: -160.0, y: -200.0)
        case .caatinga: playerPosition = CGPoint(x: 160.0, y: -200.0)
        case .pantanal: playerPosition = CGPoint(x: -160.0, y: 0.0)
        case .cerrado: playerPosition = CGPoint(x: 130.0, y: 0.0)
        case .mataAtlantica: playerPosition = CGPoint(x: 50.0, y: 140.0)
        case .pampa: playerPosition = CGPoint(x: 0.0, y: 280.0)
        }
        recentNotification = "Entrou no bioma: \(biome.rawValue)"
    }
    
    public func movePlayer(dx: Double, dy: Double) {
        let speed = (playerTransformation.activeSpeciesId != nil) ? 4.8 : 3.2
        let newX = min(max(playerPosition.x + dx * speed, -350), 350)
        let newY = min(max(playerPosition.y + dy * speed, -350), 350)
        
        if dx != 0 || dy != 0 {
            playerFacingAngle = atan2(dy, dx)
            #if !TEST_RUNNER
            SoundManager.shared.playFootstep(at: CGPoint(x: newX, y: newY), biome: currentBiome)
            SoundManager.shared.updateRiverProximity(playerPos: CGPoint(x: newX, y: newY))
            SoundManager.shared.updateBiomeMusic(for: currentBiome)
            #endif
        }
        
        playerPosition = CGPoint(x: newX, y: newY)
        
        // Update Ambient Wild Fauna wandering and reaction
        ambientFauna.update(deltaTime: 0.1, playerPos: playerPosition, enemies: storyEngine.enemies)
        
        // Enemy AI Patrol & Stealth Checks (with Night stealth bonus)
        let time = ProcessInfo.processInfo.systemUptime
        let activePerk = activeSpecies?.transformationPerk
        let isNightStealth = atmosphere.currentTimeOfDay == .night && (activeSpecies?.id == "onca-pintada" || activeSpecies?.id == "lobo-guara")
        
        if let alerted = storyEngine.updateEnemyPatrols(
            delta: 0.1,
            time: time,
            playerPos: playerPosition,
            activePerk: isNightStealth ? "Furtivo" : activePerk,
            isHumanForm: activeSpecies == nil
        ) {
            #if !TEST_RUNNER
            switch alerted.type {
            case .surveillanceDrone: SoundManager.shared.playDroneAlarm()
            case .poacher, .nestPoacher: SoundManager.shared.playPoacherWhistle()
            case .wildfireEntity: SoundManager.shared.playFireCrackle()
            case .chainsawCrew: SoundManager.shared.playChainsaw()
            case .malhadeiraNet, .plowTractor: SoundManager.shared.playDroneAlarm()
            }
            #endif
            
            // If player is in unprotected human form, drain energy slightly
            if activeSpecies == nil {
                playerTransformation.energy = max(0, playerTransformation.energy - 1.5)
                recentNotification = "⚠️ Alerta! \(alerted.type.rawValue) detectou você! Transforme-se em um animal para se esquivar."
            }
        }
        
        // Dynamic Biome update based on open world location
        let detectedBiome = GameSession.biomeForPosition(x: newX, y: newY)
        if detectedBiome != currentBiome {
            currentBiome = detectedBiome
            recentNotification = "🌿 Explorando o bioma: \(detectedBiome.rawValue)"
            #if !TEST_RUNNER
            SoundManager.shared.updateBiomeMusic(for: detectedBiome)
            #endif
        }
    }
    
    // MARK: - Quick Numeric Metamorphosis Shortcuts (Keys 1-6 & 0)
    @discardableResult
    public func morphQuick(index: Int) -> Bool {
        let speciesKeys = [
            1: "mico-leao-dourado",
            2: "lobo-guara",
            3: "tatu-bola",
            4: "onca-pintada",
            5: "ariranha",
            6: "tamandua-bandeira"
        ]
        
        if index == 0 {
            return transform(into: nil)
        } else if let targetSpecies = speciesKeys[index] {
            return transform(into: targetSpecies)
        }
        return false
    }
    
    // MARK: - Transformation
    @discardableResult
    public func transform(into speciesId: String?) -> Bool {
        let success = playerTransformation.morph(into: speciesId)
        if success {
            #if !TEST_RUNNER
            SoundManager.shared.playMetamorphosis()
            #endif
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
    
    // MARK: - World Interaction, Story & Rescue
    public func getNearbyNPC() -> GameNPC? {
        let radius: Double = 28.0
        return storyEngine.npcs.first { npc in
            hypot(npc.position.x - playerPosition.x, npc.position.y - playerPosition.y) <= radius
        }
    }
    
    public func getNearbyTotem() -> BiomeTotem? {
        let radius: Double = 30.0
        return storyEngine.totems.first { totem in
            !totem.isPurified && hypot(totem.position.x - playerPosition.x, totem.position.y - playerPosition.y) <= radius
        }
    }
    
    public func getNearbyEnemy() -> WorldEnemy? {
        let radius: Double = 28.0
        return storyEngine.enemies.first { enemy in
            !enemy.isNeutralized && hypot(enemy.position.x - playerPosition.x, enemy.position.y - playerPosition.y) <= radius
        }
    }
    
    public func getNearbyPoint() -> WorldPoint? {
        let interactionRadius: Double = 26.0
        return worldPoints.first { point in
            guard !point.isResolved else { return false }
            let dist = hypot(point.x - playerPosition.x, point.y - playerPosition.y)
            return dist <= interactionRadius
        }
    }
    
    public func getNearbyPortal() -> BiomePortal? {
        let radius: Double = 26.0
        var closest: (portal: BiomePortal, dist: Double)? = nil
        for portal in activePortals {
            let d = Double(hypot(portal.position.x - playerPosition.x, portal.position.y - playerPosition.y))
            if d <= radius {
                if closest == nil || d < closest!.dist {
                    closest = (portal, d)
                }
            }
        }
        return closest?.portal
    }
    
    @discardableResult
    public func teleportThroughPortal(_ portal: BiomePortal) -> (success: Bool, message: String) {
        playerPosition = portal.targetPosition
        currentBiome = GameSession.biomeForPosition(x: playerPosition.x, y: playerPosition.y)
        #if !TEST_RUNNER
        SoundManager.shared.playPortalTeleport()
        SoundManager.shared.updateBiomeMusic(for: currentBiome)
        #endif
        let msg = portal.isReturnPortal ?
            "🌀 Você atravessou o portal e retornou em segurança ao Refúgio Raízes!" :
            "🌀 Você viajou através do \(portal.portalName) até o bioma \(portal.targetBiome.rawValue)!"
        recentNotification = msg
        return (true, msg)
    }
    
    @discardableResult
    public func interactWithNearbyPoint() -> (success: Bool, message: String) {
        // 0. Check Portal Proximity (Priority when closest)
        let nearbyPortal = getNearbyPortal()
        let nearbyNPC = getNearbyNPC()
        let initialPoint = getNearbyPoint()
        
        let distPortal = nearbyPortal != nil ? hypot(nearbyPortal!.position.x - playerPosition.x, nearbyPortal!.position.y - playerPosition.y) : Double.infinity
        let distNPC = nearbyNPC != nil ? hypot(nearbyNPC!.position.x - playerPosition.x, nearbyNPC!.position.y - playerPosition.y) : Double.infinity
        let distPointInitial = initialPoint != nil ? hypot(initialPoint!.x - playerPosition.x, initialPoint!.y - playerPosition.y) : Double.infinity
        
        if let portal = nearbyPortal, distPortal <= min(distNPC, distPointInitial) {
            return teleportThroughPortal(portal)
        }
        
        // 1. Check NPC Interaction (with proximity priority over world points)
        if let npc = nearbyNPC, distNPC <= distPointInitial {
            #if !TEST_RUNNER
            SoundManager.shared.playDialogueBeep()
            #endif
            let lines = [
                DialogueLine(speakerName: npc.name, speakerIcon: npc.iconSymbol, text: "Olá Guardião! Fique atento às redondezas de \(npc.nativeBiome.rawValue). As ameaças ecológicas exigem nossa união.", tone: "Informativo"),
                DialogueLine(speakerName: "Muri", speakerIcon: "leaf.fill", text: "Obrigado, \(npc.name)! Cumprirei os objetivos e restaurarei o equilíbrio!", tone: "Confiante")
            ]
            storyEngine.startDialogue(lines: lines)
            
            // Check quest objectives for talking to NPC
            let _ = storyEngine.completeObjective(withId: "obj_talk_poti")
            let _ = storyEngine.completeObjective(withId: "obj_talk_mae_mata")
            
            let msg = "Conversou com \(npc.name)."
            recentNotification = msg
            return (true, msg)
        }
        
        // 1b. Check Harpia Ancestral Interaction (Climax)
        if storyEngine.isHarpiaSummoned {
            let distToCenter = hypot(playerPosition.x - 0.0, playerPosition.y - 0.0)
            if distToCenter <= 30.0 {
                let _ = storyEngine.completeObjective(withId: "obj_harpia_falar")
                if let intro = storyEngine.currentQuest?.introDialogue, !intro.isEmpty {
                    storyEngine.startDialogue(lines: intro)
                }
                let msg = "👑 Você se aproximou da Harpia Ancestral e recebeu a Bênção dos Céus!"
                recentNotification = msg
                return (true, msg)
            }
        }
        
        // 2. Check Totem Purification
        if let totem = getNearbyTotem() {
            if let idx = storyEngine.totems.firstIndex(where: { $0.id == totem.id }) {
                storyEngine.totems[idx].isPurified = true
                #if !TEST_RUNNER
                SoundManager.shared.playTotemPurified()
                #endif
                sanctuary.resources.carePoints += 100
                playerTransformation.regenerateEnergy(amount: 50.0)
                
                // Complete story objectives for all biomes
                let _ = storyEngine.completeObjective(withId: "obj_mat_totem")
                let _ = storyEngine.completeObjective(withId: "obj_cer_totem")
                let _ = storyEngine.completeObjective(withId: "obj_pan_totem")
                let _ = storyEngine.completeObjective(withId: "obj_amz_totem")
                let _ = storyEngine.completeObjective(withId: "obj_pam_totem")
                
                let msg = "✨ Você purificou o \(totem.title)! (+100 Pontos de Cuidado, +50 Energia). A floresta volta a florescer!"
                recentNotification = msg
                return (true, msg)
            }
        }
        
        // 3. Check Enemy vs World Point Proximity Priority
        let nearbyEnemy = getNearbyEnemy()
        let nearbyPoint = getNearbyPoint()
        
        let distEnemy = nearbyEnemy != nil ? hypot(nearbyEnemy!.position.x - playerPosition.x, nearbyEnemy!.position.y - playerPosition.y) : Double.infinity
        let distPoint = nearbyPoint != nil ? hypot(nearbyPoint!.x - playerPosition.x, nearbyPoint!.y - playerPosition.y) : Double.infinity
        
        if let enemy = nearbyEnemy, distEnemy <= distPoint {
            let result = storyEngine.disarmThreat(
                enemyId: enemy.id,
                isHumanForm: activeSpecies == nil,
                activePerk: activeSpecies?.transformationPerk
            )
            
            if result.success {
                #if !TEST_RUNNER
                if enemy.type == .malhadeiraNet {
                    SoundManager.shared.playNetCut()
                } else {
                    SoundManager.shared.playRescueFanfare()
                }
                #endif
                sanctuary.resources.carePoints += 50
                
                // Complete Gumgum challenges
                let _ = storyEngine.completeObjective(withId: "obj_pan_vigilia")
                let _ = storyEngine.completeObjective(withId: "obj_amz_malhadeiras")
                let _ = storyEngine.completeObjective(withId: "obj_pam_arado")
                let _ = storyEngine.completeObjective(withId: "obj_cer_aceiro")
                let _ = storyEngine.completeObjective(withId: "obj_mat_travessia")
                if let expId = storyEngine.currentQuest?.objectives.first?.id {
                    let _ = storyEngine.completeObjective(withId: expId)
                }
                
                let msg = "⚡ \(result.feedback) (+50 Pontos de Cuidado)"
                recentNotification = msg
                return (true, msg)
            } else {
                recentNotification = result.feedback
                return (false, result.feedback)
            }
        }
        
        // 4. Standard World Points (Animal Distress & Clues)
        guard let point = nearbyPoint else {
            return (false, "Nenhum ponto de interesse, NPC ou ameaça próxima.")
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
                #if !TEST_RUNNER
                SoundManager.shared.playRescueFanfare()
                #endif
                
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
                
                // Complete story objectives (Gumgum Inspired)
                let _ = storyEngine.completeObjective(withId: "obj_cer_rodovia")
                let _ = storyEngine.completeObjective(withId: "obj_pan_ninhos")
                if let expId = storyEngine.currentQuest?.objectives.first?.id {
                    let _ = storyEngine.completeObjective(withId: expId)
                }
                
                let msg = "🎉 Você resgatou um \(species.commonName)! Ele foi levado ao Santuário e sua forma de metamorfose foi DESBLOQUEADA!"
                recentNotification = msg
                return (true, msg)
            }
            
        case .ecologicalClue:
            #if !TEST_RUNNER
            SoundManager.shared.playUIClick()
            #endif
            sanctuary.resources.carePoints += 30
            playerTransformation.regenerateEnergy(amount: 25.0)
            
            // Complete clue/rastro and restoration objectives
            let _ = storyEngine.completeObjective(withId: "obj_mat_rastro")
            let _ = storyEngine.completeObjective(withId: "obj_mat_restauro")
            let _ = storyEngine.completeObjective(withId: "obj_cer_rastro")
            let _ = storyEngine.completeObjective(withId: "obj_pan_rastro")
            let _ = storyEngine.completeObjective(withId: "obj_amz_rastro")
            let _ = storyEngine.completeObjective(withId: "obj_amz_canais")
            let _ = storyEngine.completeObjective(withId: "obj_pam_rastro")
            let _ = storyEngine.completeObjective(withId: "obj_pam_dunas")
            if let expId = storyEngine.currentQuest?.objectives.first?.id {
                let _ = storyEngine.completeObjective(withId: expId)
            }
            let msg = "🔍 Pista ecológica investigada: \(point.description) (+30 Pontos de Cuidado, +25 Energia)"
            recentNotification = msg
            return (true, msg)
            
        case .terrainObstacle:
            #if !TEST_RUNNER
            SoundManager.shared.playUIClick()
            #endif
            sanctuary.resources.wood += 20
            sanctuary.resources.stone += 15
            let msg = "Obstáculo superado com sua forma animal! Coletados materiais para o santuário."
            recentNotification = msg
            return (true, msg)
            
        case .resourceCache:
            #if !TEST_RUNNER
            SoundManager.shared.playUIClick()
            #endif
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
    
    // MARK: - Simulation Tick
    public func simulationTick() {
        playerTransformation.regenerateEnergy(amount: 5.0)
        atmosphere.advanceTime(delta: 0.005)
        
        // Update Sanctuary animals & generate care points
        for i in 0..<sanctuary.rescuedAnimals.count {
            sanctuary.rescuedAnimals[i].hunger = min(100.0, sanctuary.rescuedAnimals[i].hunger + 2.0)
            
            if let habId = sanctuary.rescuedAnimals[i].habitatId,
               let habitat = sanctuary.habitats.first(where: { $0.id == habId }) {
                let species = AnimalSpecies.allSpecies.first(where: { $0.id == sanctuary.rescuedAnimals[i].speciesId })
                let isBiomeMatch = species?.nativeBiome == habitat.biome
                
                if isBiomeMatch && sanctuary.rescuedAnimals[i].hunger < 50 {
                    sanctuary.rescuedAnimals[i].rehabilitationProgress = min(100.0, sanctuary.rescuedAnimals[i].rehabilitationProgress + 2.0)
                    sanctuary.resources.carePoints += 2
                }
            } else {
                sanctuary.rescuedAnimals[i].happiness = max(0, sanctuary.rescuedAnimals[i].happiness - 3.0)
            }
        }
    }
    
    // MARK: - World Points Generator Across the Grand Continuous Map
    private static func generateInitialWorldPoints() -> [WorldPoint] {
        return [
            // Amazônia (Noroeste: X < 0, Y < -80)
            WorldPoint(
                biome: .amazonia,
                x: -180.0,
                y: -220.0,
                interactionType: .animalInDistress,
                title: "Família de Ariranhas Isolada",
                description: "Troncos caídos bloquearam o igarapé onde a ariranha caçava peixes.",
                associatedSpeciesId: "ariranha",
                requiredPerk: "Garras Rompedoras"
            ),
            WorldPoint(
                biome: .amazonia,
                x: -120.0,
                y: -160.0,
                interactionType: .resourceCache,
                title: "Castanhal Centenário",
                description: "Árvores gigantes com castanhas e frutos nativos para o santuário.",
                requiredPerk: nil
            ),
            
            // Caatinga (Nordeste: X >= 0, Y < -80)
            WorldPoint(
                biome: .caatinga,
                x: 180.0,
                y: -200.0,
                interactionType: .animalInDistress,
                title: "Tatu-Bola sob Rocha Quebradiça",
                description: "Um tatu-bola precisa de ajuda para desobstruir uma fenda no solo pedregoso.",
                associatedSpeciesId: "tatu-bola",
                requiredPerk: nil
            ),
            WorldPoint(
                biome: .caatinga,
                x: 120.0,
                y: -140.0,
                interactionType: .ecologicalClue,
                title: "Mandacaru Florido",
                description: "Raras flores noturnas de mandacaru revelam rotas de fauna resiliente.",
                requiredPerk: nil
            ),
            
            // Pantanal (Centro-Oeste: X < -30, Y in -80...80)
            WorldPoint(
                biome: .pantanal,
                x: -180.0,
                y: -20.0,
                interactionType: .animalInDistress,
                title: "Onça-Pintada em Ilha de Seca",
                description: "Uma onça jovem isolada após alteração no curso d'água das baías.",
                associatedSpeciesId: "onca-pintada",
                requiredPerk: "Nado Veloz"
            ),
            WorldPoint(
                biome: .pantanal,
                x: -120.0,
                y: 35.0,
                interactionType: .resourceCache,
                title: "Lagoa dos Aguapés",
                description: "Águas cristalinas ricas em peixes frescos e plantas aquáticas.",
                requiredPerk: nil
            ),
            
            // Cerrado (Centro-Leste: X >= -30, Y in -80...80)
            WorldPoint(
                biome: .cerrado,
                x: 130.0,
                y: 0.0,
                interactionType: .animalInDistress,
                title: "Lobo-Guará Encurralado",
                description: "Um lobo-guará ferido está cercado por fendas no solo. Aproxime-se para resgatá-lo.",
                associatedSpeciesId: "lobo-guara",
                requiredPerk: nil
            ),
            WorldPoint(
                biome: .cerrado,
                x: 70.0,
                y: -40.0,
                interactionType: .ecologicalClue,
                title: "Arbusto de Lobeira",
                description: "Frutos maduros de lobeira caídos indicam trilhas de mamíferos do cerrado.",
                requiredPerk: "Faro Rastreador"
            ),
            
            // Mata Atlântica (Sudeste: X >= -60, Y in 80...220)
            WorldPoint(
                biome: .mataAtlantica,
                x: 50.0,
                y: 140.0,
                interactionType: .ecologicalClue,
                title: "Pegadas de Primatas no Dossel",
                description: "Marcas de garras e cascas de frutos roídas indicam passagem de micos.",
                requiredPerk: "Escalada Ágil"
            ),
            WorldPoint(
                biome: .mataAtlantica,
                x: -20.0,
                y: 170.0,
                interactionType: .resourceCache,
                title: "Bosque de Bromélias Nativas",
                description: "Bromélias com frutos ricos em néctar e água pura.",
                requiredPerk: nil
            ),
            
            // Pampa (Sul: Y >= 220)
            WorldPoint(
                biome: .pampa,
                x: 20.0,
                y: 280.0,
                interactionType: .animalInDistress,
                title: "Tamanduá-Bandeira Preso em Ravina",
                description: "Tamanduá-bandeira precisa de auxílio para retornar aos campos abertos do sul.",
                associatedSpeciesId: "tamandua-bandeira",
                requiredPerk: nil
            ),
            WorldPoint(
                biome: .pampa,
                x: -70.0,
                y: 300.0,
                interactionType: .ecologicalClue,
                title: "Coxilha dos Ventos",
                description: "Gramíneas ondulantes com rastros de formigueiros gigantes.",
                requiredPerk: nil
            )
        ]
    }
    
    // MARK: - Initial Biome Portals (Refúgio Raízes Arc & Biome Return Portals)
    public static func generateInitialPortals() -> [BiomePortal] {
        return [
            // Outbound from Refúgio Raízes Arc (to North of central plaza)
            BiomePortal(
                id: "portal_to_mata_atlantica",
                portalName: "Portal da Mata Atlântica",
                sourceBiome: .mataAtlantica,
                targetBiome: .mataAtlantica,
                position: CGPoint(x: -24.0, y: -26.0),
                targetPosition: CGPoint(x: 55.0, y: 155.0),
                colorHex: "#34C759",
                description: "Conduz à Estação das Copas e aos cipoais montanhosos da Mata Atlântica."
            ),
            BiomePortal(
                id: "portal_to_cerrado",
                portalName: "Portal do Cerrado",
                sourceBiome: .cerrado,
                targetBiome: .cerrado,
                position: CGPoint(x: -12.0, y: -30.0),
                targetPosition: CGPoint(x: 125.0, y: -20.0),
                colorHex: "#FF9500",
                description: "Conduz ao Posto dos Brigadistas e às planícies de capim seco do Cerrado."
            ),
            BiomePortal(
                id: "portal_to_pantanal",
                portalName: "Portal do Pantanal",
                sourceBiome: .pantanal,
                targetBiome: .pantanal,
                position: CGPoint(x: 0.0, y: -32.0),
                targetPosition: CGPoint(x: -135.0, y: 30.0),
                colorHex: "#5AC8FA",
                description: "Conduz ao Bosque dos Manduvis Centenários e às várzeas alagadas do Pantanal."
            ),
            BiomePortal(
                id: "portal_to_amazonia",
                portalName: "Portal da Amazônia",
                sourceBiome: .amazonia,
                targetBiome: .amazonia,
                position: CGPoint(x: 12.0, y: -30.0),
                targetPosition: CGPoint(x: -155.0, y: -205.0),
                colorHex: "#007AFF",
                description: "Conduz ao Lago de Manejo Comunitário e às águas fartas da Amazônia."
            ),
            BiomePortal(
                id: "portal_to_pampa",
                portalName: "Portal do Pampa",
                sourceBiome: .pampa,
                targetBiome: .pampa,
                position: CGPoint(x: 24.0, y: -26.0),
                targetPosition: CGPoint(x: 22.0, y: 235.0),
                colorHex: "#AF52DE",
                description: "Conduz aos campos de dunas vivas e às galerias subterrâneas do Pampa."
            ),
            
            // Inbound Return Portals located within each Biome
            BiomePortal(
                id: "portal_return_mata_atlantica",
                portalName: "Portal de Retorno ao Refúgio",
                sourceBiome: .mataAtlantica,
                targetBiome: .mataAtlantica,
                position: CGPoint(x: 52.0, y: 165.0),
                targetPosition: CGPoint(x: -22.0, y: -20.0),
                colorHex: "#E5E5EA",
                isReturnPortal: true,
                description: "Retorne instantaneamente à segurança do Refúgio Raízes."
            ),
            BiomePortal(
                id: "portal_return_cerrado",
                portalName: "Portal de Retorno ao Refúgio",
                sourceBiome: .cerrado,
                targetBiome: .cerrado,
                position: CGPoint(x: 120.0, y: -10.0),
                targetPosition: CGPoint(x: -10.0, y: -22.0),
                colorHex: "#E5E5EA",
                isReturnPortal: true,
                description: "Retorne instantaneamente à segurança do Refúgio Raízes."
            ),
            BiomePortal(
                id: "portal_return_pantanal",
                portalName: "Portal de Retorno ao Refúgio",
                sourceBiome: .pantanal,
                targetBiome: .pantanal,
                position: CGPoint(x: -128.0, y: 38.0),
                targetPosition: CGPoint(x: 0.0, y: -24.0),
                colorHex: "#E5E5EA",
                isReturnPortal: true,
                description: "Retorne instantaneamente à segurança do Refúgio Raízes."
            ),
            BiomePortal(
                id: "portal_return_amazonia",
                portalName: "Portal de Retorno ao Refúgio",
                sourceBiome: .amazonia,
                targetBiome: .amazonia,
                position: CGPoint(x: -148.0, y: -200.0),
                targetPosition: CGPoint(x: 10.0, y: -22.0),
                colorHex: "#E5E5EA",
                isReturnPortal: true,
                description: "Retorne instantaneamente à segurança do Refúgio Raízes."
            ),
            BiomePortal(
                id: "portal_return_pampa",
                portalName: "Portal de Retorno ao Refúgio",
                sourceBiome: .pampa,
                targetBiome: .pampa,
                position: CGPoint(x: 28.0, y: 228.0),
                targetPosition: CGPoint(x: 22.0, y: -20.0),
                colorHex: "#E5E5EA",
                isReturnPortal: true,
                description: "Retorne instantaneamente à segurança do Refúgio Raízes."
            )
        ]
    }
}
