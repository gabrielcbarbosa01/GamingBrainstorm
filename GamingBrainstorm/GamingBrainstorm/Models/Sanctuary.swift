//
//  Sanctuary.swift
//  GamingBrainstorm
//
//  Created by Gabriel Barbosa on 25/08/26.
//

import Foundation

public struct RescuedAnimal: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public let speciesId: String
    public var nickname: String
    public var health: Double // 0 to 100
    public var hunger: Double // 0 to 100 (0 = well fed, 100 = starving)
    public var happiness: Double // 0 to 100
    public var rehabilitationProgress: Double // 0 to 100 (100 = ready to thrive/released in safe sanctuary zone)
    public var habitatId: UUID?
    
    public init(
        id: UUID = UUID(),
        speciesId: String,
        nickname: String,
        health: Double = 60.0,
        hunger: Double = 50.0,
        happiness: Double = 50.0,
        rehabilitationProgress: Double = 10.0,
        habitatId: UUID? = nil
    ) {
        self.id = id
        self.speciesId = speciesId
        self.nickname = nickname
        self.health = health
        self.hunger = hunger
        self.happiness = happiness
        self.rehabilitationProgress = rehabilitationProgress
        self.habitatId = habitatId
    }
}

public struct SanctuaryHabitat: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public var name: String
    public let biome: BiomeType
    public var level: Int
    public var capacity: Int
    public var cleanliness: Double // 0 to 100
    
    public init(
        id: UUID = UUID(),
        name: String,
        biome: BiomeType,
        level: Int = 1,
        capacity: Int = 2,
        cleanliness: Double = 100.0
    ) {
        self.id = id
        self.name = name
        self.biome = biome
        self.level = level
        self.capacity = capacity
        self.cleanliness = cleanliness
    }
}

public struct FoodInventory: Codable, Sendable, Equatable {
    public var fruits: Int
    public var insects: Int
    public var freshFish: Int
    public var nativePlants: Int
    
    public init(
        fruits: Int = 15,
        insects: Int = 15,
        freshFish: Int = 10,
        nativePlants: Int = 20
    ) {
        self.fruits = fruits
        self.insects = insects
        self.freshFish = freshFish
        self.nativePlants = nativePlants
    }
    
    public func quantity(for diet: DietType) -> Int {
        switch diet {
        case .frugivore: return fruits
        case .insectivore: return insects
        case .carnivore: return freshFish
        case .herbivore: return nativePlants
        case .omnivore: return (fruits + nativePlants) / 2
        }
    }
    
    public mutating func consume(for diet: DietType, amount: Int = 1) -> Bool {
        switch diet {
        case .frugivore:
            guard fruits >= amount else { return false }
            fruits -= amount
            return true
        case .insectivore:
            guard insects >= amount else { return false }
            insects -= amount
            return true
        case .carnivore:
            guard freshFish >= amount else { return false }
            freshFish -= amount
            return true
        case .herbivore:
            guard nativePlants >= amount else { return false }
            nativePlants -= amount
            return true
        case .omnivore:
            if fruits >= amount {
                fruits -= amount
                return true
            } else if nativePlants >= amount {
                nativePlants -= amount
                return true
            }
            return false
        }
    }
}

public struct SanctuaryResources: Codable, Sendable, Equatable {
    public var wood: Int
    public var stone: Int
    public var cleanWater: Int
    public var carePoints: Int // Currency earned by keeping animals happy
    
    public init(
        wood: Int = 50,
        stone: Int = 30,
        cleanWater: Int = 100,
        carePoints: Int = 100
    ) {
        self.wood = wood
        self.stone = stone
        self.cleanWater = cleanWater
        self.carePoints = carePoints
    }
}

public struct SanctuaryState: Codable, Sendable, Equatable {
    public var habitats: [SanctuaryHabitat]
    public var rescuedAnimals: [RescuedAnimal]
    public var inventory: FoodInventory
    public var resources: SanctuaryResources
    
    public init(
        habitats: [SanctuaryHabitat] = [
            SanctuaryHabitat(name: "Bosque Mata Atlântica", biome: .mataAtlantica)
        ],
        rescuedAnimals: [RescuedAnimal] = [],
        inventory: FoodInventory = FoodInventory(),
        resources: SanctuaryResources = SanctuaryResources()
    ) {
        self.habitats = habitats
        self.rescuedAnimals = rescuedAnimals
        self.inventory = inventory
        self.resources = resources
    }
}
