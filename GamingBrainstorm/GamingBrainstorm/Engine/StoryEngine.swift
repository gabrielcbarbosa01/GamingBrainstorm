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
    
    // Active Timed Challenge HUD State (Gumgum Inspired)
    public var activeChallengeMessage: String? = nil
    public var activeChallengeFraction: Double? = nil
    public var activeChallengeIcon: String? = nil
    public var isChallengeUrgent: Bool = false
    
    // Endgame & Expeditions
    public var completedExpeditionsCount: Int = 0
    public var isHarpiaSummoned: Bool = false
    
    public init() {
        setupStoryElements()
    }
    
    public var currentQuest: StoryQuest? {
        guard currentQuestIndex < allQuests.count else { return nil }
        return allQuests[currentQuestIndex]
    }
    
    // MARK: - Setup World Story Content (Gumgum Inspired)
    private func setupStoryElements() {
        // 1. Friendly NPCs & Nature Allies
        npcs = [
            GameNPC(
                id: "iara_guardia",
                name: "Iara, Bióloga de Campo",
                role: "Pesquisadora da Estação Raízes",
                iconSymbol: "person.badge.shield.checkmark.fill",
                primaryColorHex: "#30D158",
                position: CGPoint(x: 20, y: 30),
                nativeBiome: .mataAtlantica
            ),
            GameNPC(
                id: "teo_ribeirinho",
                name: "Téo, Mestre do Manejo",
                role: "Guardião das Águas & Pirarucu",
                iconSymbol: "water.waves",
                primaryColorHex: "#32ADE6",
                position: CGPoint(x: -80, y: -180),
                nativeBiome: .amazonia
            ),
            GameNPC(
                id: "poti_arara",
                name: "Poti, a Sentinela Alada",
                role: "Observadora dos Manduvis",
                iconSymbol: "bird.fill",
                primaryColorHex: "#007AFF",
                position: CGPoint(x: -110, y: 20),
                nativeBiome: .pantanal
            ),
            GameNPC(
                id: "seu_bento_sertao",
                name: "Seu Bento dos Aceiros",
                role: "Brigadista do Cerrado",
                iconSymbol: "flame.circle.fill",
                primaryColorHex: "#FF9F0A",
                position: CGPoint(x: 180, y: -60),
                nativeBiome: .cerrado
            )
        ]
        
        // 2. The 6 Ancient Biome Totems
        totems = [
            BiomeTotem(id: "totem_mata_atlantica", biome: .mataAtlantica, title: "Totem da Neblina Costeira", position: CGPoint(x: 120, y: 180), isPurified: false, loreSnippet: "Onde o dourado ainda salta entre as copas. Conecta os fragmentos florestais."),
            BiomeTotem(id: "totem_cerrado", biome: .cerrado, title: "Totem do Berço das Águas", position: CGPoint(x: 180, y: 20), isPurified: false, loreSnippet: "As pernas do horizonte. Alimenta as bacias hidrográficas sob a poeira avermelhada."),
            BiomeTotem(id: "totem_pantanal", biome: .pantanal, title: "Totem das Várzeas Alagadas", position: CGPoint(x: -190, y: 30), isPurified: false, loreSnippet: "Azul contra o céu. Berçário nos ocos dos manduvis centenários."),
            BiomeTotem(id: "totem_amazonia", biome: .amazonia, title: "Totem das Águas Doces", position: CGPoint(x: -200, y: -250), isPurified: false, loreSnippet: "O gigante do lago. Manejo comunitário que devolve o fôlego aos peixes."),
            BiomeTotem(id: "totem_pampa", biome: .pampa, title: "Totem dos Ventos do Sul", position: CGPoint(x: 0, y: 300), isPurified: false, loreSnippet: "A cidade sob as dunas. Vida silenciosa escavando galerias sob a areia litorânea."),
            BiomeTotem(id: "totem_caatinga", biome: .caatinga, title: "Totem da Resistência Solar", position: CGPoint(x: 190, y: -230), isPurified: false, loreSnippet: "Guarda a força da vegetação xerófila e dos mandacarus.")
        ]
        
        // 3. Enemies & Real Ecological Threats (Gumgum Inspired)
        enemies = [
            // Pantanal: Saqueador de Ninhos (Timed Threat: 45s)
            WorldEnemy(
                id: "pan_nest_poacher",
                type: .nestPoacher,
                position: CGPoint(x: -160, y: 60),
                patrolRadius: 15,
                visionRadius: 28,
                countdownTimer: 45.0,
                maxCountdown: 45.0,
                targetEntityPos: CGPoint(x: -110, y: 20),
                targetEntityName: "Ninho de Manduvi"
            ),
            
            // Pampa: Arado Mecânico da Monocultura (Timed Threat: 45s)
            WorldEnemy(
                id: "pam_plow_tractor",
                type: .plowTractor,
                position: CGPoint(x: 40, y: 330),
                patrolRadius: 20,
                visionRadius: 30,
                countdownTimer: 45.0,
                maxCountdown: 45.0,
                targetEntityPos: CGPoint(x: 0, y: 290),
                targetEntityName: "Galeria Subterrânea"
            ),
            
            // Amazônia: Redes Malhadeiras Submersas no Leito do Rio
            WorldEnemy(
                id: "amz_malhadeira_1",
                type: .malhadeiraNet,
                position: CGPoint(x: -15, y: -210),
                patrolRadius: 0,
                visionRadius: 22,
                requiredCounterPerk: "Nado"
            ),
            WorldEnemy(
                id: "amz_malhadeira_2",
                type: .malhadeiraNet,
                position: CGPoint(x: -15, y: -130),
                patrolRadius: 0,
                visionRadius: 22,
                requiredCounterPerk: "Nado"
            ),
            
            // Mata Atlântica: Frente de Desmatamento com Motosserras
            WorldEnemy(
                id: "mat_chainsaw_crew",
                type: .chainsawCrew,
                position: CGPoint(x: 95, y: 150),
                patrolRadius: 25,
                visionRadius: 26,
                requiredCounterPerk: "Ágil"
            ),
            
            // Cerrado: Focos de Queimada Ativa no Capim Seco
            WorldEnemy(
                id: "cer_wildfire_entity",
                type: .wildfireEntity,
                position: CGPoint(x: 210, y: 40),
                patrolRadius: 22,
                visionRadius: 28,
                requiredCounterPerk: "Faro"
            ),
            
            // Patrulhas e Drones Secundários
            WorldEnemy(id: "drone_amazonia", type: .surveillanceDrone, position: CGPoint(x: -180, y: -230), patrolRadius: 35, visionRadius: 30, requiredCounterPerk: "Furtivo"),
            WorldEnemy(id: "drone_cerrado", type: .surveillanceDrone, position: CGPoint(x: 130, y: -30), patrolRadius: 35, visionRadius: 28, requiredCounterPerk: "Furtivo"),
            WorldEnemy(id: "poacher_caatinga", type: .poacher, position: CGPoint(x: 150, y: -210), patrolRadius: 28, visionRadius: 24, requiredCounterPerk: "Casco"),
            WorldEnemy(id: "poacher_pantanal", type: .poacher, position: CGPoint(x: -180, y: -20), patrolRadius: 26, visionRadius: 24, requiredCounterPerk: "Nado")
        ]
        
        // 4. Five Complete Biome Story Quests + Climax (Gumgum Inspired)
        allQuests = [
            // Capítulo 1: Mata Atlântica
            StoryQuest(
                id: "quest_mata_atlantica",
                chapterNumber: 1,
                title: "Mata Atlântica: Onde o dourado salta entre as copas",
                narrativeSummary: "A estrada partiu a mata em dois. Grupos de micos-leões-dourados ficaram presos de um lado e não descem ao chão. Na forma de mico, guie a comitiva pelas copas e plante mudas para restabelecer o corredor florestal!",
                objectives: [
                    QuestObjective(id: "obj_mat_rastro", title: "Registrar vestígios nos cipoais", description: "Encontre pegadas e sementes espalhadas para traçar a rota dos bandos isolados.", type: .rastro, targetBiome: .mataAtlantica, targetPosition: CGPoint(x: 60, y: 140), hint: "Use a agilidade do mico para cortar caminho pelos galhos."),
                    QuestObjective(id: "obj_mat_travessia", title: "Travessia da Copa", description: "Lidere a comitiva de micos saltando pelas copas até o fragmento seguro antes que o desmatamento os alcance.", type: .canopyCrossing, targetBiome: .mataAtlantica, targetPosition: CGPoint(x: 95, y: 150), hint: "Só na forma de mico eles confiam e seguem você."),
                    QuestObjective(id: "obj_mat_restauro", title: "Corredor da Copa: Plantar Mudas", description: "Plante mudas nas clareiras degradadas para reconectar permanentemente a floresta.", type: .restoration, targetBiome: .mataAtlantica, targetPosition: CGPoint(x: 100, y: 170), hint: "As clareiras abertas pela motosserra precisam de solo enriquecido."),
                    QuestObjective(id: "obj_mat_totem", title: "Purificar o Totem da Mata Atlântica", description: "Canalize a essência protetora no Totem da Neblina Costeira.", type: .purifyTotem, targetBiome: .mataAtlantica, targetPosition: CGPoint(x: 120, y: 180), hint: "O mico-leão-dourado harmoniza com este totem sagrado.")
                ],
                introDialogue: [
                    DialogueLine(speakerName: "Iara", speakerIcon: "person.badge.shield.checkmark.fill", text: "Muri! A estrada e as motosserras cortaram a Mata Atlântica ao meio. Os micos ficaram encurralados na copa e não descem ao chão — ali embaixo é onde eles morrem.", tone: "Urgente"),
                    DialogueLine(speakerName: "Muri", speakerIcon: "leaf.fill", text: "Vou vestir o Amuleto da Copa! Na forma de mico-leão, saltarei pelos galhos e levarei o grupo em segurança.", tone: "Convicto")
                ],
                completionDialogue: [
                    DialogueLine(speakerName: "Iara", speakerIcon: "person.badge.shield.checkmark.fill", text: "O bando atravessou! As mudas plantadas já começaram a brotar. O primeiro Totem resplandece!", tone: "Emocionada")
                ]
            ),
            
            // Capítulo 2: Cerrado
            StoryQuest(
                id: "quest_cerrado",
                chapterNumber: 2,
                title: "Cerrado: As pernas do horizonte",
                narrativeSummary: "O fogo corre pelo capim seco, tile por tile, e dobra de tamanho se hesitarmos. Não dá para apagar: dá para cercar. Abra aceiros em disparada com o lobo-guará e guie os animais feridos para longe das rodovias.",
                objectives: [
                    QuestObjective(id: "obj_cer_rastro", title: "Pegadas na Poeira", description: "Registre pegadas do lobo-guará e arbustos de lobeira para mapear o território.", type: .rastro, targetBiome: .cerrado, targetPosition: CGPoint(x: 120, y: -20), hint: "O lobo caminha quilômetros por noite em busca de alimento."),
                    QuestObjective(id: "obj_cer_aceiro", title: "Aceiro contra o Fogo", description: "A investida do lobo raspa o chão e abre aceiro em linha. Corte à frente das chamas para conter o incêndio.", type: .fireBreak, targetBiome: .cerrado, targetPosition: CGPoint(x: 210, y: 40), hint: "Corte à frente das chamas, não atrás!"),
                    QuestObjective(id: "obj_cer_rodovia", title: "Travessia da Rodovia", description: "Guie os animais assustados pelos corredores ecológicos seguros longe dos atropelamentos.", type: .roadRescue, targetBiome: .cerrado, targetPosition: CGPoint(x: 160, y: 10), hint: "Aproxime-se devagar para transmitir tranquilidade."),
                    QuestObjective(id: "obj_cer_totem", title: "Purificar o Totem do Cerrado", description: "Devolva a pureza ao Totem do Berço das Águas.", type: .purifyTotem, targetBiome: .cerrado, targetPosition: CGPoint(x: 180, y: 20), hint: "A forma do lobo-guará sintoniza com as raízes profundas.")
                ],
                introDialogue: [
                    DialogueLine(speakerName: "Seu Bento", speakerIcon: "flame.circle.fill", text: "Muri, o vento seco espalhou o fogo pelo capim! Não adianta tentar soprar: temos que cercar abrindo aceiros na terra nua antes que atinja a rodovia.", tone: "Tenso"),
                    DialogueLine(speakerName: "Muri", speakerIcon: "leaf.fill", text: "A disparada do lobo-guará raspa o solo e corta a vegetação seca. Eu abrirei o aceiro!", tone: "Determinado")
                ],
                completionDialogue: [
                    DialogueLine(speakerName: "Seu Bento", speakerIcon: "flame.circle.fill", text: "As chamas morreram na borda da terra nua! Os animais estão a salvo e o aquífero do Cerrado respira em paz.", tone: "Aliviado")
                ]
            ),
            
            // Capítulo 3: Pantanal
            StoryQuest(
                id: "quest_pantanal",
                chapterNumber: 3,
                title: "Pantanal: Azul contra o céu",
                narrativeSummary: "Araras-azuis só nidificam em ocos de manduvi centenários. Saqueadores de ninhos estão caminhando da periferia em direção às árvores com filhotes! Chegue antes do relógio de 45 segundos, volte à forma humana e instale a proteção.",
                objectives: [
                    QuestObjective(id: "obj_pan_rastro", title: "Mapa dos Ninhos de Manduvi", description: "Mapeie os manduvis centenários da planície onde as araras nidificam.", type: .rastro, targetBiome: .pantanal, targetPosition: CGPoint(x: -140, y: 10), hint: "As árvores mais altas guardam os ninhos das famílias."),
                    QuestObjective(id: "obj_pan_vigilia", title: "Vigília dos Ninhos (45s)", description: "O saqueador está marchando até a árvore! Corra, chegue antes e volte a ser humano para instalar a chapa protetora.", type: .nestWatch, targetBiome: .pantanal, targetPosition: CGPoint(x: -110, y: 20), hint: "Instalar proteção exige mãos humanas! Volte à forma normal (0).", timeLimitSeconds: 45.0),
                    QuestObjective(id: "obj_pan_ninhos", title: "Instalar Ninhos Artificiais", description: "Fixe caixas-ninho em manduvis ocos para devolver áreas seguras de reprodução.", type: .restoration, targetBiome: .pantanal, targetPosition: CGPoint(x: -160, y: 40), hint: "Cada caixa instalada garante o futuro de novas gerações."),
                    QuestObjective(id: "obj_pan_totem", title: "Purificar o Totem do Pantanal", description: "Abençoe o Totem das Várzeas Alagadas.", type: .purifyTotem, targetBiome: .pantanal, targetPosition: CGPoint(x: -190, y: 30), hint: "A plumagem azul da arara desperta a luz deste totem.")
                ],
                introDialogue: [
                    DialogueLine(speakerName: "Poti", speakerIcon: "bird.fill", text: "Alerta nos céus! Saqueadores clandestinos avistaram o ninho do manduvi grande e estão marchando com caixas vazias! Em menos de 45 segundos eles chegam lá!", tone: "Desesperado"),
                    DialogueLine(speakerName: "Muri", speakerIcon: "leaf.fill", text: "Vou voar em disparada até a árvore, reassumir minha forma humana e blindar o oco com a chapa protetora!", tone: "Heroico")
                ],
                completionDialogue: [
                    DialogueLine(speakerName: "Poti", speakerIcon: "bird.fill", text: "Os filhotes estão protegidos! O saqueador deu meia-volta de mãos vazias. As asas azuis dominam o céu!", tone: "Radiante")
                ]
            ),
            
            // Capítulo 4: Amazônia
            StoryQuest(
                id: "quest_amazonia",
                chapterNumber: 4,
                title: "Amazônia: O gigante das águas",
                narrativeSummary: "O pirarucu e o boto precisam subir à tona para respirar ar puro. Redes malhadeiras ilegais foram estendidas no fundo do rio. Mergulhe na forma aquática, corte a malha com a lâmina antes do fôlego acabar e reabra os canais de manejo.",
                objectives: [
                    QuestObjective(id: "obj_amz_rastro", title: "Contagem de Bodecos", description: "Conte as subidas dos peixes gigantes à superfície para realizar o censo comunitário.", type: .rastro, targetBiome: .amazonia, targetPosition: CGPoint(x: -60, y: -160), hint: "Na margem dos lagos você avista as bolhas e o dorso vermelho."),
                    QuestObjective(id: "obj_amz_malhadeiras", title: "Corte das Malhadeiras Submersas", description: "Mergulhe no leito do rio na forma aquática e corte as redes predatórias com a ferramenta.", type: .netCutting, targetBiome: .amazonia, targetPosition: CGPoint(x: -15, y: -180), hint: "Mantenha-se na água na forma de Ariranha/Pirarucu para nadar rápido até a malha."),
                    QuestObjective(id: "obj_amz_canais", title: "Reabrir Canais de Manejo", description: "Desobstrua a terra compactada que isolava os cardumes juvenis do rio principal.", type: .restoration, targetBiome: .amazonia, targetPosition: CGPoint(x: -120, y: -230), hint: "A água volta a circular livremente entre os igapós."),
                    QuestObjective(id: "obj_amz_totem", title: "Purificar o Totem da Amazônia", description: "Restaure a seiva do Totem das Águas Doces.", type: .purifyTotem, targetBiome: .amazonia, targetPosition: CGPoint(x: -200, y: -250), hint: "O espírito aquático ecoa nas corredeiras.")
                ],
                introDialogue: [
                    DialogueLine(speakerName: "Téo", speakerIcon: "water.waves", text: "Muri, armaram malhadeiras de náilon fino no leito do rio! O pirarucu respira ar como nós: se ficar preso no fundo da rede, ele se afoga em minutos.", tone: "Aflito"),
                    DialogueLine(speakerName: "Muri", speakerIcon: "leaf.fill", text: "Vou submergir com a agilidade da Ariranha e cortar os nós de cada rede!", tone: "Decidido")
                ],
                completionDialogue: [
                    DialogueLine(speakerName: "Téo", speakerIcon: "water.waves", text: "As malhadeiras foram recolhidas! Os grandes peixes saltam livres nas águas límpidas da bacia amazônica.", tone: "Comovido")
                ]
            ),
            
            // Capítulo 5: Pampa
            StoryQuest(
                id: "quest_pampa",
                chapterNumber: 5,
                title: "Pampa: A cidade sob as dunas",
                narrativeSummary: "O arado pesado avança em linha reta sobre as dunas costeiras e desaba tudo que houver embaixo. As galerias do tuco-tuco e do tatu estão na linha de corte. Escave no subsolo com a carapaça protetora e evacue as famílias antes da lâmina chegar!",
                objectives: [
                    QuestObjective(id: "obj_pam_rastro", title: "Ouvir o Chão", description: "Localize montículos de areia fofa e escutas de galerias ativas nas dunas.", type: .rastro, targetBiome: .pampa, targetPosition: CGPoint(x: -40, y: 260), hint: "O som de escavação é sutil sob o vento pampeano."),
                    QuestObjective(id: "obj_pam_arado", title: "Evacuação sob o Arado (45s)", description: "O trator avança em linha reta! Entre nas galerias na forma escavadora e evacue os animais antes do soterramento.", type: .burrowEvacuation, targetBiome: .pampa, targetPosition: CGPoint(x: 0, y: 290), hint: "Use a carapaça do Tatu-Bola (3) para perfurar a terra dura com velocidade.", timeLimitSeconds: 45.0),
                    QuestObjective(id: "obj_pam_dunas", title: "Refixar Dunas Vivas", description: "Plante gramíneas fixadoras nas cristas de areia para sustentar os túneis subterrâneos.", type: .restoration, targetBiome: .pampa, targetPosition: CGPoint(x: 30, y: 310), hint: "A vegetação nativa impede que a areia desabe sobre as tocas."),
                    QuestObjective(id: "obj_pam_totem", title: "Purificar o Totem do Pampa", description: "Ative a benção do Totem dos Ventos do Sul.", type: .purifyTotem, targetBiome: .pampa, targetPosition: CGPoint(x: 0, y: 300), hint: "A união de todos os animais sintoniza este último totem!")
                ],
                introDialogue: [
                    DialogueLine(speakerName: "Iara", speakerIcon: "person.badge.shield.checkmark.fill", text: "Muri, um trator de arado abriu frente nas dunas do sul! A lâmina está descendo e vai esmagar a rede de galerias inteira em menos de 45 segundos!", tone: "Grave"),
                    DialogueLine(speakerName: "Muri", speakerIcon: "leaf.fill", text: "Na forma de Tatu, mergulharei na areia e tirarei cada filhote das galerias antes da lâmina passar!", tone: "Firme")
                ],
                completionDialogue: [
                    DialogueLine(speakerName: "Iara", speakerIcon: "person.badge.shield.checkmark.fill", text: "Todos foram evacuados e as dunas foram replantadas! Todos os 5 biomas sagrados estão purificados!", tone: "Triunfante")
                ]
            ),
            
            // Capítulo 6 / Clímax: A Harpia Ancestral
            StoryQuest(
                id: "quest_harpia_climax",
                chapterNumber: 6,
                title: "A Bênção dos Céus: O Despertar da Harpia",
                narrativeSummary: "Com os cinco totens purificados e as ameaças contidas, o maior espírito guardião do país — a colossal Harpia Real — pousou nas colinas do santuário. Aproxime-se e receba o reconhecimento supremo de Guardião dos Biomas!",
                objectives: [
                    QuestObjective(id: "obj_harpia_falar", title: "Encontrar a Harpia Ancestral", description: "Vá até o centro do vale sagrado e aproxime-se da majestosa ave de rapina.", type: .talkToNPC, targetBiome: .mataAtlantica, targetPosition: CGPoint(x: 0, y: 0), hint: "Ela pousou soberana onde a floresta reencontrou sua paz.")
                ],
                introDialogue: [
                    DialogueLine(speakerName: "Voz Ancestral", speakerIcon: "sparkles", text: "Uma sombra majestosa cruzou o sol... Algo imenso e sábio desceu dos céus e aguarda no coração do vale.", tone: "Místico"),
                    DialogueLine(speakerName: "Muri", speakerIcon: "leaf.fill", text: "É a Harpia... A guardiã suprema dos ares!", tone: "Reverente")
                ],
                completionDialogue: [
                    DialogueLine(speakerName: "Harpia Real", speakerIcon: "crown.fill", text: "Você não apenas protegeu as matas, Muri: você se fez bicho com os bichos e curou a terra com mãos humanas. Doravante, você é o Guardião Eterno dos Biomas Brasileiros!", tone: "Solene"),
                    DialogueLine(speakerName: "Muri", speakerIcon: "leaf.fill", text: "A floresta vive, pulsa e resiste!", tone: "Consagrado")
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
            
            // Check if all 5 main biomes completed -> summon Harpia
            if currentQuestIndex == 4 {
                isHarpiaSummoned = true
            }
            
            // Advance quest or generate new expedition
            if currentQuestIndex + 1 < allQuests.count {
                currentQuestIndex += 1
                if let nextIntro = currentQuest?.introDialogue, !nextIntro.isEmpty {
                    startDialogue(lines: nextIntro)
                }
            } else {
                // Generates post-game infinite expedition
                completedExpeditionsCount += 1
                generateNextExpedition()
            }
            return (true, title)
        }
        return (false, nil)
    }
    
    // MARK: - Infinite Expeditions Generator (Gumgum Inspired)
    public func generateNextExpedition() {
        let level = completedExpeditionsCount
        let biomes: [BiomeType] = [.mataAtlantica, .cerrado, .pantanal, .amazonia, .pampa]
        let chosenBiome = biomes[level % biomes.count]
        
        let kinds: [(QuestObjectiveType, String, String)] = [
            (.rastro, "Censo Populacional", "Registre novos vestígios de fauna silvestre para manter o censo do bioma atualizado."),
            (.roadRescue, "Operação de Resgate", "Chegaram relatos de espécimes acuados por fragmentação e cercas. Aproxime-se e liberte-os."),
            (.restoration, "Mutirão de Restauro", "Recupere clareiras degradadas plantando mudas e instalando abrigos de proteção."),
            (.confrontThreat, "Contenção de Ameaça Clandestina", "Patrulhas clandestinas tentaram retornar à fronteira do bioma. Neutralize a frente ativa.")
        ]
        
        let kind = kinds[(level * 3) % kinds.count]
        let objPos = CGPoint(x: Double((level * 47) % 200 - 100), y: Double((level * 73) % 200 - 100))
        
        let newQuest = StoryQuest(
            id: "expedition_lvl_\(level)",
            chapterNumber: 6 + level,
            title: "Expedição de Monitoramento Nº \(level): \(chosenBiome.rawValue)",
            narrativeSummary: "A conservação contínua exige vigilância perpétua. Conclua a missão de campo para obter sementes e pontos de cuidado.",
            objectives: [
                QuestObjective(
                    id: "exp_obj_\(level)",
                    title: "\(kind.1) em \(chosenBiome.rawValue)",
                    description: kind.2,
                    type: kind.0,
                    targetBiome: chosenBiome,
                    targetPosition: objPos,
                    rewardCarePoints: 100 + level * 25,
                    hint: "Nível de Dificuldade \(level) — o bioma exige atenção permanente do Guardião."
                )
            ],
            introDialogue: [
                DialogueLine(speakerName: "Estação Raízes", speakerIcon: "antenna.radiowaves.left.and.right", text: "Novo chamado de campo recebido para o bioma \(chosenBiome.rawValue). As equipes contam com a sua presença!", tone: "Profissional")
            ],
            completionDialogue: [
                DialogueLine(speakerName: "Estação Raízes", speakerIcon: "checkmark.seal.fill", text: "Expedição Nº \(level) concluída com sucesso! Novos recursos foram entregues ao Santuário.", tone: "Gratidão")
            ]
        )
        
        allQuests.append(newQuest)
        currentQuestIndex = allQuests.count - 1
        if let intro = newQuest.introDialogue.first {
            startDialogue(lines: [intro])
        }
    }
    
    // MARK: - Timed Challenges & AI Patrol Loop
    public func updateEnemyPatrols(
        delta: Double,
        time: Double,
        playerPos: CGPoint,
        activePerk: String?,
        isHumanForm: Bool
    ) -> WorldEnemy? {
        var alertedEnemy: WorldEnemy? = nil
        var activeChallengeTitle: String? = nil
        var challengeFraction: Double? = nil
        var challengeIcon: String? = nil
        var isUrgent = false
        
        for i in 0..<enemies.count {
            guard !enemies[i].isNeutralized else { continue }
            
            // 1. Timed Countdown Challenge Simulation (Saqueador & Arado)
            if var timer = enemies[i].countdownTimer, let maxTime = enemies[i].maxCountdown {
                let distToPlayer = hypot(playerPos.x - enemies[i].position.x, playerPos.y - enemies[i].position.y)
                
                // Relógio conta quando o jogador está no bioma / raio de 800 unidades
                if distToPlayer < 800.0 && !enemies[i].isExpired {
                    timer = max(0.0, timer - delta)
                    enemies[i].countdownTimer = timer
                    
                    let f = timer / maxTime
                    activeChallengeTitle = "\(enemies[i].type.rawValue) em marcha: \(Int(timer))s"
                    challengeFraction = f
                    challengeIcon = enemies[i].type.iconSymbol
                    isUrgent = timer <= 15.0
                    
                    // Movimento proporcional ao alvo (ex: Manduvi ou Galeria)
                    if let targetPos = enemies[i].targetEntityPos {
                        let totalX = targetPos.x - enemies[i].patrolOrigin.x
                        let totalY = targetPos.y - enemies[i].patrolOrigin.y
                        let progress = 1.0 - f
                        enemies[i].position = CGPoint(
                            x: enemies[i].patrolOrigin.x + totalX * progress,
                            y: enemies[i].patrolOrigin.y + totalY * progress
                        )
                    }
                    
                    // Se o tempo esgotar:
                    if timer <= 0.0 {
                        enemies[i].isExpired = true
                        enemies[i].isNeutralized = true
                    }
                }
            } else {
                // 2. Standard Patrol Oscillation
                let angle = time * 0.85 + Double(i) * 1.5
                let ox = enemies[i].patrolOrigin.x + cos(angle) * enemies[i].patrolRadius * 0.6
                let oy = enemies[i].patrolOrigin.y + sin(angle) * enemies[i].patrolRadius * 0.6
                enemies[i].position = CGPoint(x: ox, y: oy)
            }
            
            // 3. Vision / Proximity Detection
            let dist = hypot(playerPos.x - enemies[i].position.x, playerPos.y - enemies[i].position.y)
            if dist <= enemies[i].visionRadius {
                var isSafe = false
                if let perk = activePerk, let counter = enemies[i].requiredCounterPerk {
                    if perk.contains(counter) || counter.contains(perk) {
                        isSafe = true
                    }
                }
                
                // Tuco-tuco / Tatu escavando é invisível para ameaças
                if activePerk?.contains("Casco") == true || activePerk?.contains("Subsolo") == true {
                    isSafe = true
                }
                
                enemies[i].isAlerted = !isSafe
                if !isSafe && alertedEnemy == nil {
                    alertedEnemy = enemies[i]
                }
            } else {
                enemies[i].isAlerted = false
            }
        }
        
        // Update HUD banner
        self.activeChallengeMessage = activeChallengeTitle
        self.activeChallengeFraction = challengeFraction
        self.activeChallengeIcon = challengeIcon
        self.isChallengeUrgent = isUrgent
        
        return alertedEnemy
    }
    
    // MARK: - Action Interactivity against Threats
    public func disarmThreat(enemyId: String, isHumanForm: Bool, activePerk: String?) -> (success: Bool, feedback: String) {
        guard let idx = enemies.firstIndex(where: { $0.id == enemyId }) else {
            return (false, "Ameaça não encontrada.")
        }
        
        let enemy = enemies[idx]
        
        switch enemy.type {
        case .nestPoacher:
            guard isHumanForm else {
                return (false, "Instalar a chapa protetora no ninho exige mãos humanas! Pressione 0.")
            }
            enemies[idx].isNeutralized = true
            return (true, "Ninho blindado a tempo! O saqueador fugiu sem levar os filhotes.")
            
        case .malhadeiraNet:
            guard activePerk?.contains("Nado") == true || activePerk?.contains("Água") == true else {
                return (false, "A malhadeira está no fundo do rio! Mergulhe na forma aquática (5).")
            }
            enemies[idx].isNeutralized = true
            return (true, "Malhadeira cortada com sucesso! Os pirarucus e botos sobem livres.")
            
        case .plowTractor:
            guard activePerk?.contains("Casco") == true || activePerk?.contains("Subsolo") == true else {
                return (false, "O arado soterra o solo! Entre nas galerias na forma escavadora (3).")
            }
            enemies[idx].isNeutralized = true
            return (true, "Galeria subterrânea evacuada com sucesso antes da passagem da lâmina!")
            
        case .wildfireEntity:
            enemies[idx].isNeutralized = true
            return (true, "Aceiro aberto em linha com a disparada! O fogo não tem mais para onde correr.")
            
        case .chainsawCrew:
            enemies[idx].isNeutralized = true
            return (true, "Madeireiros clandestinos dispersados! As árvores centenárias permanecem de pé.")
            
        case .surveillanceDrone:
            enemies[idx].isNeutralized = true
            return (true, "Circuito do drone de queimada desativado.")
            
        case .poacher:
            enemies[idx].isNeutralized = true
            return (true, "Caçador clandestino desarmado e repelido.")
        }
    }
}
