//
//  MainGameView.swift
//  GamingBrainstorm
//
//  Created by Gabriel Barbosa on 25/08/26.
//

import SwiftUI

public enum GameNavigationTab: String, CaseIterable, Identifiable {
    case exploration = "Exploração"
    case sanctuary = "Santuário"
    case catalog = "Catálogo & Mapa"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .exploration: return "cube.fill"
        case .sanctuary: return "house.lodge.fill"
        case .catalog: return "books.vertical.fill"
        }
    }
}

public struct MainGameView: View {
    @State private var session = GameSession()
    @State private var selectedTab: GameNavigationTab = .exploration
    @State private var isShowingMainMenu: Bool = true
    @State private var isShowingPauseModal: Bool = false
    @FocusState private var isViewFocused: Bool
    
    public init() {}
    
    public var body: some View {
        ZStack {
            if isShowingMainMenu {
                MainMenuView(
                    session: session,
                    onStartGame: {
                        isShowingMainMenu = false
                    },
                    onNewGame: {
                        session = GameSession()
                        isShowingMainMenu = false
                    }
                )
            } else {
                gameplayView
            }
            
            // In-Game Pause & Settings Modal Overlay
            if isShowingPauseModal {
                pauseModalOverlay
                    .zIndex(10000)
            }
        }
        .frame(minWidth: 980, minHeight: 680)
        .focusable()
        .focused($isViewFocused)
        .onAppear {
            isViewFocused = true
        }
        .onKeyPress { press in
            if press.key == .escape {
                if !isShowingMainMenu {
                    isShowingPauseModal.toggle()
                    return .handled
                }
            }
            
            guard selectedTab == .exploration && !isShowingMainMenu && !isShowingPauseModal else { return .ignored }
            
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
            } else if let char = press.characters.first, let digit = Int(String(char)), (0...6).contains(digit) {
                _ = session.morphQuick(index: digit)
                return .handled
            }
            return .ignored
        }
    }
    
    // MARK: - Active Gameplay View
    private var gameplayView: some View {
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
                case .exploration:
                    WorldExploration3DView(session: session, onOpenMenu: {
                        isShowingPauseModal = true
                    })
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
    }
    
    // MARK: - Pause & Settings Modal Overlay
    private var pauseModalOverlay: some View {
        ZStack {
            Color.black.opacity(0.70)
                .ignoresSafeArea()
                .onTapGesture {
                    isShowingPauseModal = false
                }
            
            VStack(spacing: 22) {
                HStack {
                    Image(systemName: "pause.circle.fill")
                        .font(.title)
                        .foregroundStyle(.yellow)
                    Text("Jogo Pausado")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    Spacer()
                    Button {
                        isShowingPauseModal = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                }
                
                Divider()
                
                VStack(spacing: 12) {
                    pauseButton(title: "Retomar Jogo", icon: "play.fill", primary: true) {
                        isShowingPauseModal = false
                    }
                    
                    pauseButton(title: "Menu Principal", icon: "house.fill", primary: false) {
                        isShowingPauseModal = false
                        isShowingMainMenu = true
                    }
                }
            }
            .padding(24)
            .frame(width: 380)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(red: 0.08, green: 0.12, blue: 0.10))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.green.opacity(0.4), lineWidth: 1.5))
            )
            .shadow(color: .black.opacity(0.8), radius: 20)
        }
    }
    
    private func pauseButton(title: String, icon: String, primary: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundStyle(primary ? .black : .white)
                Text(title)
                    .font(.headline.bold())
                    .foregroundStyle(primary ? .black : .white)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(primary ? Color.green : Color.white.opacity(0.12))
            )
        }
        .buttonStyle(.plain)
    }
}
