//
//  WorldPoint.swift
//  GamingBrainstorm
//
//  Created by Gabriel Barbosa on 25/08/26.
//

import Foundation

public enum WorldInteractionType: String, Codable, Sendable {
    case animalInDistress
    case ecologicalClue
    case terrainObstacle
    case resourceCache
}

public struct WorldPoint: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public let biome: BiomeType
    public var x: Double // -100 to 100
    public var y: Double // -100 to 100
    public let interactionType: WorldInteractionType
    public let title: String
    public let description: String
    public let associatedSpeciesId: String?
    public let requiredPerk: String?
    public var isResolved: Bool
    
    public init(
        id: UUID = UUID(),
        biome: BiomeType,
        x: Double,
        y: Double,
        interactionType: WorldInteractionType,
        title: String,
        description: String,
        associatedSpeciesId: String? = nil,
        requiredPerk: String? = nil,
        isResolved: Bool = false
    ) {
        self.id = id
        self.biome = biome
        self.x = x
        self.y = y
        self.interactionType = interactionType
        self.title = title
        self.description = description
        self.associatedSpeciesId = associatedSpeciesId
        self.requiredPerk = requiredPerk
        self.isResolved = isResolved
    }
}
