//
//  StoryQuest.swift
//  GamingBrainstorm
//
//  Created by Gabriel Barbosa on 25/08/26.
//

import Foundation
import SwiftUI

// MARK: - NPC & Characters
public struct GameNPC: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let role: String
    public let iconSymbol: String
    public let primaryColorHex: String
    public let position: CGPoint
    public let nativeBiome: BiomeType
    
    public init(id: String, name: String, role: String, iconSymbol: String, primaryColorHex: String, position: CGPoint, nativeBiome: BiomeType) {
        self.id = id
        self.name = name
        self.role = role
        self.iconSymbol = iconSymbol
        self.primaryColorHex = primaryColorHex
        self.position = position
        self.nativeBiome = nativeBiome
    }
}

public struct DialogueLine: Identifiable, Sendable {
    public let id: UUID
    public let speakerName: String
    public let speakerIcon: String
    public let text: String
    public let tone: String
    
    public init(id: UUID = UUID(), speakerName: String, speakerIcon: String, text: String, tone: String = "Normal") {
        self.id = id
        self.speakerName = speakerName
        self.speakerIcon = speakerIcon
        self.text = text
        self.tone = tone
    }
}

// MARK: - Quests & Objectives
public enum QuestObjectiveType: String, Sendable {
    case talkToNPC = "Conversar com Aliado"
    case rastro = "Rastrear Vestígios e Pegadas"
    case canopyCrossing = "Travessia da Copa"
    case fireBreak = "Aceiro contra o Fogo"
    case nestWatch = "Vigília dos Ninhos"
    case netCutting = "Corte de Malhadeiras Submersas"
    case burrowEvacuation = "Evacuação sob o Arado"
    case restoration = "Restauro & Plantio de Mudas"
    case roadRescue = "Travessia da Rodovia"
    case rescueSpecies = "Resgatar Animal Ameaçado"
    case confrontThreat = "Contenção de Ameaça"
    case purifyTotem = "Purificar Totem Ancestral"
    case expedition = "Expedição de Monitoramento"
}

public struct QuestObjective: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let description: String
    public let type: QuestObjectiveType
    public let targetBiome: BiomeType
    public let targetPosition: CGPoint
    public var isCompleted: Bool
    public let rewardCarePoints: Int
    public var targetCount: Int
    public var currentCount: Int
    public let hint: String
    public var timeLimitSeconds: Double?
    
    public init(
        id: String,
        title: String,
        description: String,
        type: QuestObjectiveType,
        targetBiome: BiomeType,
        targetPosition: CGPoint,
        isCompleted: Bool = false,
        rewardCarePoints: Int = 50,
        targetCount: Int = 1,
        currentCount: Int = 0,
        hint: String = "",
        timeLimitSeconds: Double? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.type = type
        self.targetBiome = targetBiome
        self.targetPosition = targetPosition
        self.isCompleted = isCompleted
        self.rewardCarePoints = rewardCarePoints
        self.targetCount = targetCount
        self.currentCount = currentCount
        self.hint = hint
        self.timeLimitSeconds = timeLimitSeconds
    }
}

public struct StoryQuest: Identifiable, Sendable {
    public let id: String
    public let chapterNumber: Int
    public let title: String
    public let narrativeSummary: String
    public var objectives: [QuestObjective]
    public let introDialogue: [DialogueLine]
    public let completionDialogue: [DialogueLine]
    public var isCompleted: Bool
    
    public init(id: String, chapterNumber: Int, title: String, narrativeSummary: String, objectives: [QuestObjective], introDialogue: [DialogueLine], completionDialogue: [DialogueLine], isCompleted: Bool = false) {
        self.id = id
        self.chapterNumber = chapterNumber
        self.title = title
        self.narrativeSummary = narrativeSummary
        self.objectives = objectives
        self.introDialogue = introDialogue
        self.completionDialogue = completionDialogue
        self.isCompleted = isCompleted
    }
    
    public var isAllObjectivesDone: Bool {
        objectives.allSatisfy { $0.isCompleted }
    }
}

// MARK: - Enemies & Threats in Open World
public enum EnemyType: String, Sendable {
    case poacher = "Caçador Clandestino"
    case nestPoacher = "Saqueador de Ninhos"
    case chainsawCrew = "Frente de Desmatamento"
    case wildfireEntity = "Foco de Incêndio"
    case malhadeiraNet = "Rede Malhadeira Predatória"
    case plowTractor = "Arado Mecânico da Monocultura"
    case surveillanceDrone = "Drone de Queimada"
    
    public var iconSymbol: String {
        switch self {
        case .poacher: return "figure.walk.motion"
        case .nestPoacher: return "shippingbox.fill"
        case .chainsawCrew: return "hammer.fill"
        case .wildfireEntity: return "flame.fill"
        case .malhadeiraNet: return "water.waves"
        case .plowTractor: return "gearshape.2.fill"
        case .surveillanceDrone: return "airplane.circle.fill"
        }
    }
    
    public var dangerColor: Color {
        switch self {
        case .poacher: return .red
        case .nestPoacher: return .orange
        case .chainsawCrew: return .brown
        case .wildfireEntity: return .yellow
        case .malhadeiraNet: return .cyan
        case .plowTractor: return .purple
        case .surveillanceDrone: return .red
        }
    }
}

public struct WorldEnemy: Identifiable, Sendable {
    public let id: String
    public let type: EnemyType
    public var position: CGPoint
    public var patrolOrigin: CGPoint
    public var patrolRadius: Double
    public var visionRadius: Double
    public var isAlerted: Bool
    public var isNeutralized: Bool
    public var requiredCounterPerk: String?
    
    // Suporte a Desafios Contra o Relógio (Gumgum Inspired)
    public var countdownTimer: Double?
    public var maxCountdown: Double?
    public var targetEntityPos: CGPoint?
    public var targetEntityName: String?
    public var isExpired: Bool
    
    public init(
        id: String,
        type: EnemyType,
        position: CGPoint,
        patrolRadius: Double = 35.0,
        visionRadius: Double = 28.0,
        isAlerted: Bool = false,
        isNeutralized: Bool = false,
        requiredCounterPerk: String? = nil,
        countdownTimer: Double? = nil,
        maxCountdown: Double? = nil,
        targetEntityPos: CGPoint? = nil,
        targetEntityName: String? = nil,
        isExpired: Bool = false
    ) {
        self.id = id
        self.type = type
        self.position = position
        self.patrolOrigin = position
        self.patrolRadius = patrolRadius
        self.visionRadius = visionRadius
        self.isAlerted = isAlerted
        self.isNeutralized = isNeutralized
        self.requiredCounterPerk = requiredCounterPerk
        self.countdownTimer = countdownTimer
        self.maxCountdown = maxCountdown
        self.targetEntityPos = targetEntityPos
        self.targetEntityName = targetEntityName
        self.isExpired = isExpired
    }
}

// MARK: - Ancient Biome Totems
public struct BiomeTotem: Identifiable, Sendable {
    public let id: String
    public let biome: BiomeType
    public let title: String
    public let position: CGPoint
    public var isPurified: Bool
    public let loreSnippet: String
    
    public init(id: String, biome: BiomeType, title: String, position: CGPoint, isPurified: Bool = false, loreSnippet: String) {
        self.id = id
        self.biome = biome
        self.title = title
        self.position = position
        self.isPurified = isPurified
        self.loreSnippet = loreSnippet
    }
}
