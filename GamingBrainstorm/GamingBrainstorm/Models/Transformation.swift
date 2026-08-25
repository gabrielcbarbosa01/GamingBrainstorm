//
//  Transformation.swift
//  GamingBrainstorm
//
//  Created by Gabriel Barbosa on 25/08/26.
//

import Foundation

public struct PlayerTransformationState: Codable, Sendable, Equatable {
    public var activeSpeciesId: String? // nil means default human guardian form
    public var energy: Double // 0.0 to 100.0
    public var maxEnergy: Double
    public var unlockedSpeciesIds: Set<String>
    
    public init(
        activeSpeciesId: String? = nil,
        energy: Double = 100.0,
        maxEnergy: Double = 100.0,
        unlockedSpeciesIds: Set<String> = []
    ) {
        self.activeSpeciesId = activeSpeciesId
        self.energy = energy
        self.maxEnergy = maxEnergy
        self.unlockedSpeciesIds = unlockedSpeciesIds
    }
    
    public var isHuman: Bool {
        return activeSpeciesId == nil
    }
    
    public mutating func unlock(speciesId: String) {
        unlockedSpeciesIds.insert(speciesId)
    }
    
    public mutating func morph(into speciesId: String?) -> Bool {
        if let id = speciesId {
            guard unlockedSpeciesIds.contains(id) else { return false }
            guard energy >= 15.0 else { return false }
            activeSpeciesId = id
            energy = max(0, energy - 10.0)
            return true
        } else {
            // Revert to human guardian
            activeSpeciesId = nil
            return true
        }
    }
    
    public mutating func regenerateEnergy(amount: Double) {
        energy = min(maxEnergy, energy + amount)
    }
}
