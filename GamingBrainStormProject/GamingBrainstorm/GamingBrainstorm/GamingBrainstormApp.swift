//
//  GamingBrainstormApp.swift
//  Guardiões dos Biomas
//
//  Um jogo sobre cinco animais brasileiros ameaçados de extinção.
//

import SwiftUI

@main
struct GamingBrainstormApp: App {
    init() {
        #if DEBUG
        _ = GameEngineTests.runAllTests()
        #endif
    }
    
    var body: some Scene {
        WindowGroup("Guardiões dos Biomas") {
            ContentView()
        }
        .windowResizability(.contentMinSize)
        .defaultSize(width: 1440, height: 900)
    }
}
