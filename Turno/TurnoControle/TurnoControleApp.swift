//
//  TurnoControleApp.swift
//  TurnoControle — o iPhone como controle de movimento do Turno da Noite.
//

import SwiftUI

@main
struct TurnoControleApp: App {
    var body: some Scene {
        WindowGroup {
            ControllerView()
                .preferredColorScheme(.dark)
        }
    }
}
