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
    case rescueSpecies = "Resgatar Animal Ameaçado"
    case extinguishFire = "Apagar Foco de Incêndio"
    case disableDrone = "Desativar Drone de Patrulha"
    case disarmTrap = "Desarmar Armadilha de Caçador"
    case purifyTotem = "Purificar Totem Ancestral"
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
    
    public init(id: String, title: String, description: String, type: QuestObjectiveType, targetBiome: BiomeType, targetPosition: CGPoint, isCompleted: Bool = false, rewardCarePoints: Int = 50) {
        self.id = id
        self.title = title
        self.description = description
        self.type = type
        self.targetBiome = targetBiome
        self.targetPosition = targetPosition
        self.isCompleted = isCompleted
        self.rewardCarePoints = rewardCarePoints
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
    case surveillanceDrone = "Drone de Queimada"
    case wildfireEntity = "Labareda de Fogo"
    case timberHarvester = "Escavadeira Predatória"
    
    public var iconSymbol: String {
        switch self {
        case .poacher: return "figure.walk.motion"
        case .surveillanceDrone: return "airplane.circle.fill"
        case .wildfireEntity: return "flame.fill"
        case .timberHarvester: return "gearshape.2.fill"
        }
    }
    
    public var dangerColor: Color {
        switch self {
        case .poacher: return .red
        case .surveillanceDrone: return .orange
        case .wildfireEntity: return .yellow
        case .timberHarvester: return .purple
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
    
    public init(id: String, type: EnemyType, position: CGPoint, patrolRadius: Double = 35.0, visionRadius: Double = 28.0, isAlerted: Bool = false, isNeutralized: Bool = false, requiredCounterPerk: String? = nil) {
        self.id = id
        self.type = type
        self.position = position
        self.patrolOrigin = position
        self.patrolRadius = patrolRadius
        self.visionRadius = visionRadius
        self.isAlerted = isAlerted
        self.isNeutralized = isNeutralized
        self.requiredCounterPerk = requiredCounterPerk
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
