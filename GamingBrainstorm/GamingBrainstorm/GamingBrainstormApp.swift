//
//  GamingBrainstormApp.swift
//  GamingBrainstorm
//
//  Created by Gabriel Barbosa on 25/08/26.
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
        WindowGroup {
            ContentView()
        }
    }
}
