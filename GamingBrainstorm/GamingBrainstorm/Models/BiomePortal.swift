//
//  BiomePortal.swift
//  Guardiões dos Biomas
//
//  Estrutura de dados para os Portais Místicos do Refúgio Raízes e dos Biomas,
//  conectando o hub central às regiões de conservação.
//

import Foundation
import CoreGraphics
#if os(macOS)
import AppKit
#endif

public struct BiomePortal: Identifiable, Sendable, Equatable {
    public let id: String
    public let portalName: String
    public let sourceBiome: BiomeType
    public let targetBiome: BiomeType
    public let position: CGPoint
    public let targetPosition: CGPoint
    public let colorHex: String
    public let isReturnPortal: Bool
    public let description: String
    
    public init(
        id: String,
        portalName: String,
        sourceBiome: BiomeType,
        targetBiome: BiomeType,
        position: CGPoint,
        targetPosition: CGPoint,
        colorHex: String,
        isReturnPortal: Bool = false,
        description: String = ""
    ) {
        self.id = id
        self.portalName = portalName
        self.sourceBiome = sourceBiome
        self.targetBiome = targetBiome
        self.position = position
        self.targetPosition = targetPosition
        self.colorHex = colorHex
        self.isReturnPortal = isReturnPortal
        self.description = description
    }
    
    #if os(macOS)
    public var nsColor: NSColor {
        if isReturnPortal {
            return NSColor(red: 0.90, green: 0.92, blue: 0.95, alpha: 1.0)
        }
        switch targetBiome {
        case .mataAtlantica:
            return NSColor(red: 0.20, green: 0.78, blue: 0.35, alpha: 1.0)
        case .cerrado:
            return NSColor(red: 1.0, green: 0.58, blue: 0.0, alpha: 1.0)
        case .pantanal:
            return NSColor(red: 0.35, green: 0.78, blue: 0.98, alpha: 1.0)
        case .amazonia:
            return NSColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0)
        case .pampa:
            return NSColor(red: 0.69, green: 0.32, blue: 0.87, alpha: 1.0)
        case .caatinga:
            return NSColor(red: 0.88, green: 0.62, blue: 0.38, alpha: 1.0)
        }
    }
    #endif
}

