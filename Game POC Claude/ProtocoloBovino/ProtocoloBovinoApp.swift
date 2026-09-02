import SwiftUI

@main
struct ProtocoloBovinoApp: App {
    init() {
        // Modos headless (--render / --soak / --haul): produzem saida e saem,
        // sem precisar de janela nem de sessao grafica.
        if OfflineRenderer.runIfRequested() { exit(0) }
    }

    var body: some Scene {
        WindowGroup("Protocolo Bovino") {
            ContentView()
        }
        .defaultSize(width: 1440, height: 860)
    }
}

enum Debug {
    static var enabled: Bool {
        CommandLine.arguments.contains("--render") || CommandLine.arguments.contains("--snapshot")
    }
    static func mark(_ name: String) { log(name) }
    static func log(_ text: String) {
        guard enabled else { return }
        FileHandle.standardError.write("[pb] \(text)\n".data(using: .utf8)!)
    }
}
