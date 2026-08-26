//
//  StoryEngine.swift
//  GamingBrainstorm
//
//  Created by Gabriel Barbosa on 25/08/26.
//

import Foundation
import SwiftUI

@Observable
public final class StoryEngine: @unchecked Sendable {
    public var npcs: [GameNPC] = []
    public var totems: [BiomeTotem] = []
    public var enemies: [WorldEnemy] = []
    public var allQuests: [StoryQuest] = []
    public var currentQuestIndex: Int = 0
    
    // Active Dialogue State
    public var activeDialogue: [DialogueLine]? = nil
    public var currentDialogueIndex: Int = 0
    public var isDialoguePresented: Bool = false
    
    public init() {
        setupStoryElements()
    }
    
    public var currentQuest: StoryQuest? {
        guard currentQuestIndex < allQuests.count else { return nil }
        return allQuests[currentQuestIndex]
    }
    
    // MARK: - Setup Initial World Story Content
    private func setupStoryElements() {
        // 1. Friendly NPCs
        npcs = [
            GameNPC(
                id: "poti_arara",
                name: "Poti, a Arara Sábia",
                role: "Vigia Aérea dos Biomas",
                iconSymbol: "bird.fill",
                primaryColorHex: "#007AFF",
                position: CGPoint(x: -80, y: -190),
                nativeBiome: .amazonia
            ),
            GameNPC(
                id: "mae_da_mata",
                name: "Mãe da Mata",
                role: "Espírito Guardião Ancestral",
                iconSymbol: "sparkles",
                primaryColorHex: "#30D158",
                position: CGPoint(x: 70, y: 150),
                nativeBiome: .mataAtlantica
            ),
            GameNPC(
                id: "curumim_tupa",
                name: "Tupãzinho",
                role: "Protetor das Águas",
                iconSymbol: "figure.child",
                primaryColorHex: "#32ADE6",
                position: CGPoint(x: -110, y: 20),
                nativeBiome: .pantanal
            ),
            GameNPC(
                id: "dona_flora",
                name: "Dra. Flora",
                role: "Bióloga do Santuário",
                iconSymbol: "cross.case.fill",
                primaryColorHex: "#FF9F0A",
                position: CGPoint(x: 80, y: -20),
                nativeBiome: .cerrado
            )
        ]
        
        // 2. The 6 Ancient Biome Totems
        totems = [
            BiomeTotem(id: "totem_amazonia", biome: .amazonia, title: "Totem das Águas Doces", position: CGPoint(x: -200, y: -250), isPurified: false, loreSnippet: "Guarda a essência da floresta pluvial e dos grandes rios."),
            BiomeTotem(id: "totem_caatinga", biome: .caatinga, title: "Totem da Resistência Solar", position: CGPoint(x: 190, y: -230), isPurified: false, loreSnippet: "Guarda a força da vegetação xerófila e dos mandacarus."),
            BiomeTotem(id: "totem_pantanal", biome: .pantanal, title: "Totem das Várzeas Alagadas", position: CGPoint(x: -190, y: 30), isPurified: false, loreSnippet: "Guarda o berço aquático da maior biodiversidade úmida."),
            BiomeTotem(id: "totem_cerrado", biome: .cerrado, title: "Totem do Berço das Águas", position: CGPoint(x: 180, y: 20), isPurified: false, loreSnippet: "Guarda as raízes profundas que alimentam os aquíferos nacionais."),
            BiomeTotem(id: "totem_mata_atlantica", biome: .mataAtlantica, title: "Totem da Neblina Costeira", position: CGPoint(x: 120, y: 180), isPurified: false, loreSnippet: "Guarda a riqueza das encostas e bromélias da serra."),
            BiomeTotem(id: "totem_pampa", biome: .pampa, title: "Totem dos Ventos do Sul", position: CGPoint(x: 0, y: 300), isPurified: false, loreSnippet: "Guarda a imensidão dos campos abertos e coxilhas verdejantes.")
        ]
        
        // 3. Enemies Patrolling in Open World
        enemies = [
            // Amazônia Enemies
            WorldEnemy(id: "enemy_amz_poacher", type: .poacher, position: CGPoint(x: -140, y: -210), patrolRadius: 30, visionRadius: 26, requiredCounterPerk: "Ágil"),
            WorldEnemy(id: "enemy_amz_drone", type: .surveillanceDrone, position: CGPoint(x: -220, y: -180), patrolRadius: 40, visionRadius: 32, requiredCounterPerk: "Furtivo"),
            WorldEnemy(id: "enemy_amz_fire", type: .wildfireEntity, position: CGPoint(x: -95, y: -260), patrolRadius: 15, visionRadius: 22, requiredCounterPerk: "Nado"),
            
            // Caatinga Enemies
            WorldEnemy(id: "enemy_caa_poacher", type: .poacher, position: CGPoint(x: 140, y: -210), patrolRadius: 32, visionRadius: 26, requiredCounterPerk: "Casco"),
            WorldEnemy(id: "enemy_caa_fire", type: .wildfireEntity, position: CGPoint(x: 230, y: -190), patrolRadius: 15, visionRadius: 22, requiredCounterPerk: "Nado"),
            
            // Pantanal Enemies
            WorldEnemy(id: "enemy_pan_poacher", type: .poacher, position: CGPoint(x: -150, y: -20), patrolRadius: 28, visionRadius: 24, requiredCounterPerk: "Nado"),
            WorldEnemy(id: "enemy_pan_drone", type: .surveillanceDrone, position: CGPoint(x: -230, y: 40), patrolRadius: 38, visionRadius: 30, requiredCounterPerk: "Furtivo"),
            
            // Cerrado Enemies
            WorldEnemy(id: "enemy_cer_drone", type: .surveillanceDrone, position: CGPoint(x: 130, y: -30), patrolRadius: 35, visionRadius: 28, requiredCounterPerk: "Faro"),
            WorldEnemy(id: "enemy_cer_fire", type: .wildfireEntity, position: CGPoint(x: 210, y: 50), patrolRadius: 18, visionRadius: 22, requiredCounterPerk: "Nado"),
            
            // Mata Atlântica Enemies
            WorldEnemy(id: "enemy_mat_poacher", type: .poacher, position: CGPoint(x: 60, y: 130), patrolRadius: 30, visionRadius: 25, requiredCounterPerk: "Ágil"),
            WorldEnemy(id: "enemy_mat_harvester", type: .timberHarvester, position: CGPoint(x: 150, y: 190), patrolRadius: 22, visionRadius: 30, requiredCounterPerk: "Garras"),
            
            // Pampa Enemies
            WorldEnemy(id: "enemy_pam_drone", type: .surveillanceDrone, position: CGPoint(x: -70, y: 280), patrolRadius: 40, visionRadius: 32, requiredCounterPerk: "Furtivo"),
            WorldEnemy(id: "enemy_pam_poacher", type: .poacher, position: CGPoint(x: 100, y: 310), patrolRadius: 30, visionRadius: 26, requiredCounterPerk: "Ágil")
        ]
        
        // 4. Story Quests
        allQuests = [
            StoryQuest(
                id: "quest_ch1",
                chapterNumber: 1,
                title: "Capítulo 1: O Despertar do Guardião",
                narrativeSummary: "A corporação clandestina 'Consórcio Devastador' invadiu a Amazônia e o Pantanal. Fale com a Arara Poti, resgate o filhote em apuros e apague o primeiro foco de fogo!",
                objectives: [
                    QuestObjective(id: "obj_talk_poti", title: "Encontrar a Arara Poti", description: "Vá até o posto de observação na Amazônia e fale com a sábia ave.", type: .talkToNPC, targetBiome: .amazonia, targetPosition: CGPoint(x: -80, y: -190)),
                    QuestObjective(id: "obj_rescue_amz", title: "Resgatar o Filhote de Peixe-Boi", description: "Encontre o animal capturado nas margens da Amazônia e envie-o ao Santuário.", type: .rescueSpecies, targetBiome: .amazonia, targetPosition: CGPoint(x: -210, y: -230)),
                    QuestObjective(id: "obj_extinguish_amz", title: "Apagar Foco de Incêndio na Amazônia", description: "Use água do rio ou a forma aquática para extinguir a labareda invasora.", type: .extinguishFire, targetBiome: .amazonia, targetPosition: CGPoint(x: -95, y: -260)),
                    QuestObjective(id: "obj_purify_amz_totem", title: "Purificar o Totem da Amazônia", description: "Ative a bênção do Totem das Águas Doces com a forma do Peixe-Boi.", type: .purifyTotem, targetBiome: .amazonia, targetPosition: CGPoint(x: -200, y: -250))
                ],
                introDialogue: [
                    DialogueLine(speakerName: "Mãe da Mata", speakerIcon: "sparkles", text: "Muri, jovem Guardião! O equilíbrio dos nossos biomas está se rompendo. Máquinas de ferro e chamas sombrias foram acesas por forasteiros sem escrúpulos.", tone: "Urgente"),
                    DialogueLine(speakerName: "Muri", speakerIcon: "leaf.fill", text: "Eu sinto o chamado da floresta! Usarei o poder sagrado da metamorfose para proteger nossos irmãos animais.", tone: "Determinado"),
                    DialogueLine(speakerName: "Mãe da Mata", speakerIcon: "sparkles", text: "Procure a sábia Arara Poti perto do igarapé. Ela viu a movimentação das patrulhas inimigas.", tone: "Guia")
                ],
                completionDialogue: [
                    DialogueLine(speakerName: "Poti, a Arara Sábia", speakerIcon: "bird.fill", text: "Você conseguiu, Muri! As águas do Norte voltaram a respirar e o primeiro Totem brilha novamente!", tone: "Alegre"),
                    DialogueLine(speakerName: "Muri", speakerIcon: "leaf.fill", text: "Ainda há fumaça no horizonte... o Cerrado e a Caatinga precisam de nós agora!", tone: "Convicto")
                ]
            ),
            
            StoryQuest(
                id: "quest_ch2",
                chapterNumber: 2,
                title: "Capítulo 2: O Cerco na Savana e Sertão",
                narrativeSummary: "Drones de patrulha e caçadores armaram armadilhas no Cerrado e na Caatinga. Desative a vigilância aérea, desmonte as armadilhas e purifique os Totens.",
                objectives: [
                    QuestObjective(id: "obj_disable_drone_cer", title: "Desativar Drone no Cerrado", description: "Alcance o drone espião na chapada e desarme seu circuito de alarme.", type: .disableDrone, targetBiome: .cerrado, targetPosition: CGPoint(x: 130, y: -30)),
                    QuestObjective(id: "obj_rescue_tatu", title: "Libertar o Tatu-Bola na Caatinga", description: "Desarme a armadilha de rede e acolha o Tatu-Bola no Santuário.", type: .rescueSpecies, targetBiome: .caatinga, targetPosition: CGPoint(x: 180, y: -190)),
                    QuestObjective(id: "obj_purify_cer_totem", title: "Purificar o Totem do Cerrado", description: "Restaure a seiva do Totem do Berço das Águas.", type: .purifyTotem, targetBiome: .cerrado, targetPosition: CGPoint(x: 180, y: 20))
                ],
                introDialogue: [
                    DialogueLine(speakerName: "Dra. Flora", speakerIcon: "cross.case.fill", text: "Muri! O Cerrado está sob vigilância constante de drones automatizados, e armadilhas foram fincadas na terra seca da Caatinga.", tone: "Preocupada"),
                    DialogueLine(speakerName: "Muri", speakerIcon: "leaf.fill", text: "Com a agilidade do Lobo e a carapaça do Tatu, nenhuma armadilha ficará de pé!", tone: "Heroico")
                ],
                completionDialogue: [
                    DialogueLine(speakerName: "Dra. Flora", speakerIcon: "cross.case.fill", text: "Excelente trabalho! O Santuário agora abriga novas espécies seguras e as águas subterrâneas fluem sem bloqueio.", tone: "Aliviada")
                ]
            ),
            
            StoryQuest(
                id: "quest_ch3",
                chapterNumber: 3,
                title: "Capítulo 3: A Grande Restauração da Floresta",
                narrativeSummary: "A máquina principal de desmatamento avançou sobre o coração da Mata Atlântica e as coxilhas do Pampa. Desative a escavadeira e purifique todos os Totens para salvar a floresta!",
                objectives: [
                    QuestObjective(id: "obj_talk_mae_mata", title: "Abençoar-se com a Mãe da Mata", description: "Encontre o santuário da Mãe da Mata nas serras.", type: .talkToNPC, targetBiome: .mataAtlantica, targetPosition: CGPoint(x: 70, y: 150)),
                    QuestObjective(id: "obj_disable_harvester", title: "Neutralizar Escavadeira Predatória", description: "Enfrente o maquinário pesado que ameaça a encosta florestal.", type: .disableDrone, targetBiome: .mataAtlantica, targetPosition: CGPoint(x: 150, y: 190)),
                    QuestObjective(id: "obj_purify_all_totems", title: "Purificar os Totens da Mata Atlântica e Pampa", description: "Sintonize os últimos Totens sagrados para restabelecer a harmonia nacional.", type: .purifyTotem, targetBiome: .pampa, targetPosition: CGPoint(x: 0, y: 300))
                ],
                introDialogue: [
                    DialogueLine(speakerName: "Mãe da Mata", speakerIcon: "sparkles", text: "O momento final chegou, Muri. A grande máquina dos invasores está diante do coração das nossas serras.", tone: "Místico"),
                    DialogueLine(speakerName: "Muri", speakerIcon: "leaf.fill", text: "Todos os animais que resgatamos lutam conosco em espírito. A floresta jamais tombará!", tone: "Épico")
                ],
                completionDialogue: [
                    DialogueLine(speakerName: "Mãe da Mata", speakerIcon: "sparkles", text: "A floresta está salva! A harmonia dos 6 biomas foi restaurada pelo Guardião da Natureza!", tone: "Triunfante")
                ]
            )
        ]
    }
    
    // MARK: - Dialogue Management
    public func startDialogue(lines: [DialogueLine]) {
        self.activeDialogue = lines
        self.currentDialogueIndex = 0
        self.isDialoguePresented = true
    }
    
    public func advanceDialogue() {
        guard let dialog = activeDialogue else {
            isDialoguePresented = false
            return
        }
        if currentDialogueIndex + 1 < dialog.count {
            currentDialogueIndex += 1
        } else {
            // Finished
            isDialoguePresented = false
            activeDialogue = nil
            currentDialogueIndex = 0
        }
    }
    
    // MARK: - Quest Progress & Verification
    public func completeObjective(withId objectiveId: String) -> (didFinishQuest: Bool, questTitle: String?) {
        guard var quest = currentQuest else { return (false, nil) }
        
        if let idx = quest.objectives.firstIndex(where: { $0.id == objectiveId }) {
            quest.objectives[idx].isCompleted = true
            allQuests[currentQuestIndex] = quest
        }
        
        if quest.isAllObjectivesDone {
            allQuests[currentQuestIndex].isCompleted = true
            let title = quest.title
            
            // Advance quest
            if currentQuestIndex + 1 < allQuests.count {
                currentQuestIndex += 1
                if let nextIntro = currentQuest?.introDialogue, !nextIntro.isEmpty {
                    startDialogue(lines: nextIntro)
                }
            }
            return (true, title)
        }
        return (false, nil)
    }
    
    // MARK: - Enemy Simulation & AI Loop
    public func updateEnemyPatrols(time: Double, playerPos: CGPoint, activePerk: String?) -> WorldEnemy? {
        var alertedEnemy: WorldEnemy? = nil
        
        for i in 0..<enemies.count {
            guard !enemies[i].isNeutralized else { continue }
            
            // 1. Patrol Oscillation
            let angle = time * 0.85 + Double(i) * 1.5
            let ox = enemies[i].patrolOrigin.x + cos(angle) * enemies[i].patrolRadius * 0.6
            let oy = enemies[i].patrolOrigin.y + sin(angle) * enemies[i].patrolRadius * 0.6
            enemies[i].position = CGPoint(x: ox, y: oy)
            
            // 2. Vision / Proximity Detection
            let dist = hypot(playerPos.x - ox, playerPos.y - oy)
            if dist <= enemies[i].visionRadius {
                // If player does not have counter perk or is not in camouflage form, trigger alert
                var isSafe = false
                if let perk = activePerk, let counter = enemies[i].requiredCounterPerk {
                    if perk.contains(counter) || counter.contains(perk) {
                        isSafe = true
                    }
                }
                
                enemies[i].isAlerted = !isSafe
                if !isSafe && alertedEnemy == nil {
                    alertedEnemy = enemies[i]
                }
            } else {
                enemies[i].isAlerted = false
            }
        }
        
        return alertedEnemy
    }
}
