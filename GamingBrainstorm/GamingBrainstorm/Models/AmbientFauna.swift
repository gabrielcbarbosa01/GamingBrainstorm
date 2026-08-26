//
//  AmbientFauna.swift
//  GamingBrainstorm
//
//  Created by Gabriel Barbosa on 25/08/26.
//

import Foundation
import CoreGraphics
import SwiftUI

public enum WildSpeciesType: String, CaseIterable, Sendable {
    case capybara = "Capivara"
    case macaw = "Arara-Canindé"
    case butterfly = "Borboleta-Azul"
    case armadillo = "Tatu-Mirim"
    case rhea = "Ema"
    
    public var iconSymbol: String {
        switch self {
        case .capybara: return "pawprint.fill"
        case .macaw: return "bird.fill"
        case .butterfly: return "sparkles"
        case .armadillo: return "shield.fill"
        case .rhea: return "figure.walk"
        }
    }
    
    public var baseSpeed: Double {
        switch self {
        case .capybara: return 0.6
        case .macaw: return 1.8
        case .butterfly: return 1.1
        case .armadillo: return 0.7
        case .rhea: return 1.4
        }
    }
    
    public var isAerial: Bool {
        self == .macaw || self == .butterfly
    }
}

public struct WildAnimal: Identifiable, Sendable {
    public let id: String
    public let type: WildSpeciesType
    public let nativeBiome: BiomeType
    public var position: CGPoint
    public var patrolOrigin: CGPoint
    public var patrolRadius: Double
    public var wanderAngle: Double
    public var isScattering: Bool
    public var scatterTimer: Double
    
    public init(
        id: String,
        type: WildSpeciesType,
        nativeBiome: BiomeType,
        position: CGPoint,
        patrolRadius: Double = 35.0
    ) {
        self.id = id
        self.type = type
        self.nativeBiome = nativeBiome
        self.position = position
        self.patrolOrigin = position
        self.patrolRadius = patrolRadius
        self.wanderAngle = Double.random(in: 0...(Double.pi * 2))
        self.isScattering = false
        self.scatterTimer = 0.0
    }
}
