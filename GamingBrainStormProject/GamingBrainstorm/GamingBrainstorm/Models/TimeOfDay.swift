//
//  TimeOfDay.swift
//  GamingBrainstorm
//
//  Created by Gabriel Barbosa on 25/08/26.
//

import SwiftUI
import AppKit

public enum TimeOfDay: String, CaseIterable, Sendable {
    case dawn = "Aurora Dourada"
    case noon = "Meio-Dia Solar"
    case sunset = "Entardecer Alaranjado"
    case night = "Noite Estrelada"
    
    public var iconSymbol: String {
        switch self {
        case .dawn: return "sunrise.fill"
        case .noon: return "sun.max.fill"
        case .sunset: return "sunset.fill"
        case .night: return "moon.stars.fill"
        }
    }
    
    public var sunColor: NSColor {
        switch self {
        case .dawn: return NSColor(red: 1.0, green: 0.85, blue: 0.65, alpha: 1.0)
        case .noon: return NSColor(red: 1.0, green: 0.98, blue: 0.90, alpha: 1.0)
        case .sunset: return NSColor(red: 1.0, green: 0.60, blue: 0.35, alpha: 1.0)
        case .night: return NSColor(red: 0.40, green: 0.50, blue: 0.75, alpha: 1.0)
        }
    }
    
    public var ambientColor: NSColor {
        switch self {
        case .dawn: return NSColor(red: 0.35, green: 0.38, blue: 0.35, alpha: 1.0)
        case .noon: return NSColor(red: 0.45, green: 0.48, blue: 0.45, alpha: 1.0)
        case .sunset: return NSColor(red: 0.40, green: 0.32, blue: 0.30, alpha: 1.0)
        case .night: return NSColor(red: 0.18, green: 0.22, blue: 0.32, alpha: 1.0)
        }
    }
    
    public var sunPitchAngle: CGFloat {
        switch self {
        case .dawn: return -0.55
        case .noon: return -1.10
        case .sunset: return -0.45
        case .night: return -0.80
        }
    }
    
    public var sunYawAngle: CGFloat {
        switch self {
        case .dawn: return 0.25
        case .noon: return 0.55
        case .sunset: return 1.15
        case .night: return -0.75
        }
    }
    
    public var stealthBonusActive: Bool {
        self == .night
    }
}

public enum BiomeWeather: String, CaseIterable, Sendable {
    case clear = "Tempo Aberto"
    case tropicalRain = "Chuva Tropical"
    case mountainMist = "Neblina de Serra"
    case heatHaze = "Mormaço Solar"
    case fireflies = "Enxame de Vagalumes"
    
    public var iconSymbol: String {
        switch self {
        case .clear: return "sun.max"
        case .tropicalRain: return "cloud.rain.fill"
        case .mountainMist: return "cloud.fog.fill"
        case .heatHaze: return "thermometer.sun.fill"
        case .fireflies: return "sparkles"
        }
    }
}

@Observable
public final class AtmosphereState {
    public var timeOfDayProgress: Double = 0.35 // 0.0 to 1.0
    public var isWeatherActive: Bool = true
    
    public init() {}
    
    public var currentTimeOfDay: TimeOfDay {
        if timeOfDayProgress < 0.22 {
            return .dawn
        } else if timeOfDayProgress < 0.55 {
            return .noon
        } else if timeOfDayProgress < 0.78 {
            return .sunset
        } else {
            return .night
        }
    }
    
    public func advanceTime(delta: Double = 0.005) {
        timeOfDayProgress = (timeOfDayProgress + delta).truncatingRemainder(dividingBy: 1.0)
    }
    
    public func weatherForBiome(_ biome: BiomeType) -> BiomeWeather {
        if currentTimeOfDay == .night {
            return .fireflies
        }
        
        switch biome {
        case .amazonia, .pantanal:
            return .tropicalRain
        case .mataAtlantica:
            return .mountainMist
        case .caatinga:
            return .heatHaze
        case .cerrado, .pampa:
            return .clear
        }
    }
}
