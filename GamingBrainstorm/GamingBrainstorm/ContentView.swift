//
//  ContentView.swift
//  GamingBrainstorm
//
//  Created by Gabriel Barbosa on 25/08/26.
//

import SpriteKit
import SwiftUI

struct ContentView: View {
    @State private var sceneID = UUID()

    var body: some View {
        ZStack(alignment: .topTrailing) {
            SpriteView(scene: GameScene.makeScene(), options: [.ignoresSiblingOrder])
                .id(sceneID)
                .ignoresSafeArea()
            Button("Reiniciar jornada") { sceneID = UUID() }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.12, green: 0.35, blue: 0.24))
                .padding()
        }
        .frame(minWidth: 960, minHeight: 640)
        .background(Color.black)
    }
}
