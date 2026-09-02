import SwiftUI

@MainActor
struct ContentView: View {
    @StateObject private var controller = GameController()

    var body: some View {
        ZStack {
            GameView(controller: controller)
            HUDView(hud: controller.hud)
        }
        .frame(minWidth: 1024, minHeight: 640)
        .background(.black)
        .ignoresSafeArea()
    }
}
