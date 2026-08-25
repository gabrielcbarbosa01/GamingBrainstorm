//
//  MainGameView.swift
//  GamingBrainstorm
//
//  Created by Gabriel Barbosa on 25/08/26.
//

import SwiftUI

public enum GameNavigationTab: String, CaseIterable, Identifiable {
    case exploration3D = "Exploração 3D"
    case exploration2D5 = "Modo 2.5D"
    case sanctuary = "Santuário"
    case catalog = "Catálogo & Mapa"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .exploration3D: return "cube.fill"
        case .exploration2D5: return "map.fill"
        case .sanctuary: return "house.lodge.fill"
        case .catalog: return "books.vertical.fill"
        }
    }
}

public struct MainGameView: View {
    @State private var session = GameSession()
    @State private var selectedTab: GameNavigationTab = .exploration3D
    @FocusState private var isViewFocused: Bool
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Notification Toast Banner
            if let notification = session.recentNotification {
                HStack(spacing: 8) {
                    Image(systemName: "bell.fill")
                        .foregroundStyle(.yellow)
                    Text(notification)
                        .font(.subheadline.bold())
                        .lineLimit(2)
                    Spacer()
                    Button {
                        session.recentNotification = nil
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.accentColor.opacity(0.9))
                .foregroundStyle(.white)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // Main Content Area
            Group {
                switch selectedTab {
                case .exploration3D:
                    WorldExploration3DView(session: session)
                case .exploration2D5:
                    WorldExploration2D5View(session: session)
                case .sanctuary:
                    SanctuaryManagementView(session: session)
                case .catalog:
                    AnimalCatalogView(session: session)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Bottom Segmented Tab Bar
            Divider()
            
            HStack(spacing: 24) {
                ForEach(GameNavigationTab.allCases) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: tab.iconName)
                                .font(.title3)
                            Text(tab.rawValue)
                                .font(.caption.bold())
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .foregroundStyle(selectedTab == tab ? Color.accentColor : Color.secondary)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selectedTab == tab ? Color.accentColor.opacity(0.12) : Color.clear)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Aba \(tab.rawValue)")
                }
            }
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .background(Material.ultraThick)
        }
        .frame(minWidth: 980, minHeight: 680)
        .focusable()
        .focused($isViewFocused)
        .onAppear {
            isViewFocused = true
        }
        .onKeyPress { press in
            guard selectedTab == .exploration3D || selectedTab == .exploration2D5 else { return .ignored }
            
            if press.key == .space {
                _ = session.interactWithNearbyPoint()
                return .handled
            } else if press.characters == "w" || press.characters == "W" || press.key == .upArrow {
                session.movePlayer(dx: 0, dy: -1.8)
                return .handled
            } else if press.characters == "s" || press.characters == "S" || press.key == .downArrow {
                session.movePlayer(dx: 0, dy: 1.8)
                return .handled
            } else if press.characters == "a" || press.characters == "A" || press.key == .leftArrow {
                session.movePlayer(dx: -1.8, dy: 0)
                return .handled
            } else if press.characters == "d" || press.characters == "D" || press.key == .rightArrow {
                session.movePlayer(dx: 1.8, dy: 0)
                return .handled
            }
            return .ignored
        }
    }
}
