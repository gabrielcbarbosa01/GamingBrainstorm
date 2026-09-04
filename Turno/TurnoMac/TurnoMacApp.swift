//
//  TurnoMacApp.swift
//  TurnoMac
//

import SwiftUI

@main
struct TurnoMacApp: App {
    init() {
        setvbuf(stdout, nil, _IOLBF, 0)
        _ = DebugCapture.runIfRequested()
    }

    var body: some Scene {
        WindowGroup("Turno da Noite") {
            ContentView()
                .frame(minWidth: 960, minHeight: 600)
        }
        .defaultSize(width: 1280, height: 800)
    }
}
