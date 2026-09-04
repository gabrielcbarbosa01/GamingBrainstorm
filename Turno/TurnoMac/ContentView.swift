//
//  ContentView.swift
//  TurnoMac
//
//  Cena RealityKit + HUD SwiftUI: menu, turno, dedução e finais.
//

import SwiftUI
import RealityKit

struct ContentView: View {
    @State private var engine = GameEngine()

    var body: some View {
        let state = engine.state
        ZStack {
            GeometryReader { geo in
                RealityView { content in
                    engine.attach(&content)
                }
                .onContinuousHover(coordinateSpace: .local) { phase in
                    if case .active(let p) = phase {
                        engine.keyboard.setPointer(u: Float(p.x / geo.size.width), v: Float(1 - p.y / geo.size.height))
                    }
                }
            }
            .ignoresSafeArea()

            switch state.phase {
            case .menu:
                MenuView(state: state) { engine.loop.startShift() }
            case .playing:
                HUDView(state: state)
            case .deduction:
                DeductionView(state: state)
            case .ending(let e):
                EndingView(state: state, ending: e) { engine.state.reset() }
            }
        }
        .background(Color.black)
    }
}

// MARK: - Menu

struct MenuView: View {
    let state: GameState
    let start: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(colors: [.black.opacity(0.85), .black.opacity(0.35)], startPoint: .top, endPoint: .bottom)
            VStack(spacing: 18) {
                Spacer()
                Text("TURNO DA NOITE").font(.system(size: 54, weight: .black, design: .serif)).tracking(6)
                    .foregroundStyle(Color(red: 0.95, green: 0.82, blue: 0.55))
                Text("\(Story.hotel) · \(Story.floor)").font(.title3.smallCaps()).foregroundStyle(.white.opacity(0.8))
                Text("Uma camareira que limpa mal chama atenção. Uma que limpa bem vê tudo.")
                    .italic().foregroundStyle(.white.opacity(0.6)).padding(.top, 4)
                Spacer().frame(height: 20)
                Button(action: start) {
                    Text("Começar o turno").font(.title2.bold()).padding(.horizontal, 36).padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent).tint(Color(red: 0.55, green: 0.15, blue: 0.15))
                .keyboardShortcut(.defaultAction)
                VStack(spacing: 6) {
                    HStack(spacing: 8) {
                        Circle().fill(state.controllerConnected ? .green : .orange).frame(width: 10, height: 10)
                        Text(state.controllerConnected ? "iPhone conectado: \(state.controllerName)" : "Aguardando o iPhone (app Turno Controle, mesma rede Wi-Fi)")
                    }
                    HStack(spacing: 8) {
                        Circle().fill(state.coopPeers > 0 ? .green : .gray).frame(width: 10, height: 10)
                        Text(state.coopPeers > 0 ? "Co-op: \(state.coopPeers) Mac(s) no turno" : "Co-op: procurando outros Macs na rede")
                    }
                    Text("Teclado: W A S D anda · setas olham · espaço/mouse usa · E ação · Esc sai · R recalibra")
                        .font(.caption).foregroundStyle(.white.opacity(0.5)).padding(.top, 8)
                }
                .font(.callout).foregroundStyle(.white.opacity(0.85))
                Spacer()
            }
            .padding(40)
        }
    }
}

// MARK: - HUD

struct HUDView: View {
    let state: GameState

    private var minutes: String {
        String(format: "%d:%02d", state.shiftSecondsLeft / 60, state.shiftSecondsLeft % 60)
    }

    var body: some View {
        ZStack {
            if state.lightsFlicker {
                Color.black.opacity(0.35).ignoresSafeArea()
            }
            VStack {
                HStack(alignment: .top) {
                    // tarefas
                    VStack(alignment: .leading, spacing: 6) {
                        Text("TURNO · \(minutes)").font(.caption.bold()).tracking(2).foregroundStyle(.white.opacity(0.7))
                        ForEach(state.tasks) { t in
                            HStack(spacing: 8) {
                                Image(systemName: t.done ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(t.done ? .green : .white.opacity(0.7))
                                Text(t.title).strikethrough(t.done).foregroundStyle(.white)
                                ProgressView(value: Double(min(1, t.progress))).frame(width: 70).tint(.orange)
                                Text("\(Int(t.progress * 100))%").font(.caption.monospacedDigit()).foregroundStyle(.white.opacity(0.7))
                            }
                        }
                        HStack(spacing: 8) {
                            Image(systemName: "doc.text.magnifyingglass").foregroundStyle(.yellow)
                            Text("Provas: \(state.foundEvidence.count)/4").foregroundStyle(.white)
                        }
                        .padding(.top, 4)
                    }
                    .padding(12)
                    .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 10))
                    Spacer()
                    // suspeita
                    VStack(alignment: .trailing, spacing: 6) {
                        HStack(spacing: 8) {
                            Text(suspicionLabel).font(.caption.bold()).foregroundStyle(.white)
                            Image(systemName: state.managerSees ? "eye.fill" : (state.managerNear ? "eye" : "eye.slash"))
                                .foregroundStyle(state.managerSees ? .red : .white.opacity(0.7))
                        }
                        ProgressView(value: Double(state.suspicion)).frame(width: 160)
                            .tint(state.suspicion > 0.6 ? .red : .orange)
                        Text(state.managerNear ? "Dona Celeste por perto" : "Corredor tranquilo")
                            .font(.caption).foregroundStyle(.white.opacity(0.7))
                        HStack(spacing: 6) {
                            Image(systemName: state.controllerConnected ? "iphone.radiowaves.left.and.right" : "keyboard")
                            Text(state.controllerConnected ? state.controllerName : "teclado")
                        }
                        .font(.caption).foregroundStyle(.white.opacity(0.5)).padding(.top, 4)
                    }
                    .padding(12)
                    .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 10))
                }
                Spacer()
                if !state.toast.isEmpty {
                    Text(state.toast).font(.headline).padding(10)
                        .background(.yellow.opacity(0.9), in: Capsule()).foregroundStyle(.black)
                        .transition(.opacity)
                }
                if !state.subtitle.isEmpty {
                    Text(state.subtitle).font(.title3).multilineTextAlignment(.center)
                        .padding(.horizontal, 16).padding(.vertical, 8)
                        .background(.black.opacity(0.7), in: RoundedRectangle(cornerRadius: 8))
                        .foregroundStyle(.white).frame(maxWidth: 700)
                }
                if !state.prompt.isEmpty {
                    HStack(spacing: 10) {
                        Image(systemName: toolIcon).foregroundStyle(.orange)
                        Text(state.prompt)
                    }
                    .font(.callout.bold()).padding(.horizontal, 16).padding(.vertical, 10)
                    .background(.black.opacity(0.65), in: Capsule()).foregroundStyle(.white)
                    .padding(.top, 6)
                }
                // mira
                Circle().stroke(.white.opacity(state.inToolMode ? 0 : 0.7), lineWidth: 1.5).frame(width: 8, height: 8)
                    .padding(.bottom, 24)
            }
            .padding(18)
        }
        .animation(.easeInOut(duration: 0.2), value: state.toast)
    }

    private var suspicionLabel: String {
        switch state.suspicion {
        case ..<0.25: return "SUSPEITA · baixa"
        case ..<0.6: return "SUSPEITA · atenção"
        default: return "SUSPEITA · ALTA"
        }
    }

    private var toolIcon: String {
        switch state.currentTool {
        case .rodo: return "square.and.line.vertical.and.square"
        case .vassoura: return "wind"
        case .pano: return "drop.fill"
        case .ouvido: return "ear"
        case .camera: return "camera"
        case .none: return "hand.point.up.left"
        }
    }
}

// MARK: - Dedução

struct DeductionView: View {
    let state: GameState
    @State private var choice: String? = nil

    var body: some View {
        ZStack {
            Color.black.opacity(0.88).ignoresSafeArea()
            VStack(spacing: 20) {
                Text("FIM DO TURNO").font(.caption.bold()).tracking(4).foregroundStyle(.white.opacity(0.6))
                Text("\(Story.detective): quem foi?").font(.largeTitle.bold()).foregroundStyle(.white)
                HStack(alignment: .top, spacing: 24) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Provas registradas").font(.headline).foregroundStyle(.yellow)
                        ForEach(state.foundEvidence) { e in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(e.title).bold().foregroundStyle(.white)
                                Text(e.detail).font(.callout).foregroundStyle(.white.opacity(0.75))
                            }
                        }
                    }
                    .frame(width: 420, alignment: .leading)
                    VStack(spacing: 12) {
                        ForEach(Story.suspects) { s in
                            Button {
                                choice = s.id
                            } label: {
                                VStack(alignment: .leading) {
                                    Text(s.name).font(.title3.bold())
                                    Text(s.role).font(.callout)
                                }
                                .frame(width: 260, alignment: .leading).padding(12)
                            }
                            .buttonStyle(.bordered).tint(choice == s.id ? .red : .gray)
                        }
                        Button("Acusar") { if let c = choice { state.accuse(c) } }
                            .buttonStyle(.borderedProminent).tint(.red).disabled(choice == nil)
                            .padding(.top, 8)
                    }
                }
            }
            .padding(40)
        }
    }
}

// MARK: - Final

struct EndingView: View {
    let state: GameState
    let ending: Ending
    let restart: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.9).ignoresSafeArea()
            VStack(spacing: 18) {
                Text(Story.endingTitle(ending)).font(.system(size: 44, weight: .black, design: .serif))
                    .foregroundStyle(ending == .casoResolvido ? Color(red: 0.95, green: 0.82, blue: 0.55) : .red)
                Text(Story.endingText(ending)).font(.title3).multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.85)).frame(maxWidth: 640)
                HStack(spacing: 24) {
                    Label("\(state.tasksDone)/3 tarefas", systemImage: "checkmark.circle")
                    Label("\(state.foundEvidence.count)/4 provas", systemImage: "doc.text.magnifyingglass")
                }
                .foregroundStyle(.white.opacity(0.7)).padding(.top, 8)
                Button("Voltar ao início") { restart() }.buttonStyle(.borderedProminent).padding(.top, 12)
            }
            .padding(40)
        }
    }
}
