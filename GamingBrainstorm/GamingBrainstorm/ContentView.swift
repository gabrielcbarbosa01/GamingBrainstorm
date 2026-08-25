//
//  ContentView.swift
//  Guardiões dos Biomas
//

import SwiftUI

struct ContentView: View {
    @StateObject private var estado = GameState()

    var body: some View {
        GameView(st: estado)
            .frame(minWidth: 1024, minHeight: 680)
            .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
