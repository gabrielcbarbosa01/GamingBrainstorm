//
//  ControllerView.swift
//  TurnoControle
//
//  Tela do controle: joystick, botões, ferramenta atual e as abas de
//  mensagens do delegado e provas — o celular é também o celular da policial.
//

import SwiftUI

struct ControllerView: View {
    @State private var client = ControllerClient()
    @State private var tab = 0
    @State private var manualHost = ""

    var body: some View {
        TabView(selection: $tab) {
            controlTab.tabItem { Label("Controle", systemImage: "gamecontroller") }.tag(0)
            messagesTab.tabItem { Label("Mensagens", systemImage: "message") }.tag(1)
                .badge(client.unreadMessages)
            evidenceTab.tabItem { Label("Provas", systemImage: "doc.text.magnifyingglass") }.tag(2)
                .badge(client.evidence.count)
        }
        .tint(Color(red: 0.95, green: 0.8, blue: 0.5))
        .onAppear { client.start() }
        .onChange(of: tab) { _, new in if new == 1 { client.unreadMessages = 0 } }
    }

    // MARK: Controle

    private var controlTab: some View {
        VStack(spacing: 12) {
            header
            if client.connectedTo == nil {
                connectPanel
            } else {
                toolPanel
                Spacer(minLength: 0)
                HStack(alignment: .bottom, spacing: 16) {
                    Joystick(value: $client.joystick)
                    VStack(spacing: 10) {
                        HoldButton(title: "USAR", subtitle: "segure", color: Color(red: 0.55, green: 0.15, blue: 0.15), pressed: $client.usePressed)
                        HStack(spacing: 10) {
                            TapButton(title: "AÇÃO", systemImage: "hand.tap") { client.act() }
                            TapButton(title: "SAIR", systemImage: "arrow.uturn.backward") { client.back() }
                        }
                        Button { client.recalibrate() } label: {
                            Label("Recalibrar", systemImage: "scope").font(.caption)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.horizontal)
                shiftStrip
            }
        }
        .padding(.top, 8)
        .background(Color(red: 0.07, green: 0.05, blue: 0.06).ignoresSafeArea())
    }

    private var header: some View {
        let s = client.state
        return VStack(spacing: 2) {
            Text("TURNO DA NOITE").font(.headline.weight(.black)).tracking(3)
                .foregroundStyle(Color(red: 0.95, green: 0.8, blue: 0.5))
            if client.connectedTo != nil && s.night > 0 && !s.nightTitle.isEmpty {
                Text("Noite \(s.night) · \(s.nightTitle)").font(.caption.bold()).foregroundStyle(.white.opacity(0.8))
                Text("\(s.role)\(s.area.isEmpty ? "" : " · " + s.area)").font(.caption2).foregroundStyle(.secondary)
            } else {
                Text(client.status).font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private var connectPanel: some View {
        VStack(spacing: 14) {
            Spacer()
            ProgressView()
            Text("Abra o Turno da Noite no Mac, na mesma rede Wi-Fi.").multilineTextAlignment(.center)
            if !client.hosts.isEmpty {
                ForEach(client.hosts) { h in
                    Button(h.name) { client.connect(to: h) }.buttonStyle(.borderedProminent)
                }
            }
            HStack {
                TextField("IP do Mac (ex.: 192.168.0.12)", text: $manualHost)
                    .textFieldStyle(.roundedBorder).keyboardType(.decimalPad)
                Button("Conectar") { client.connectManually(host: manualHost) }.disabled(manualHost.isEmpty)
            }
            .padding(.horizontal)
            if !client.motion.available {
                Text("Sem sensores de movimento neste aparelho: só joystick e botões.")
                    .font(.caption).foregroundStyle(.orange)
            }
            Spacer()
        }
    }

    private var toolPanel: some View {
        let s = client.state
        return VStack(spacing: 8) {
            Image(systemName: toolIcon(s.tool)).font(.system(size: 54)).foregroundStyle(.white)
                .symbolEffect(.pulse, isActive: s.inToolMode)
            Text(s.tool.title).font(.title3.bold())
            Text(s.tool.motionHint).font(.callout).foregroundStyle(.secondary).multilineTextAlignment(.center)
                .frame(maxWidth: 320)
            if !s.prompt.isEmpty {
                Text(s.prompt).font(.caption.bold()).padding(8)
                    .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            }
            HStack(spacing: 8) {
                Image(systemName: s.managerNear ? "eye.fill" : "eye.slash").foregroundStyle(s.managerNear ? .red : .secondary)
                Text(suspicionLabel(s.suspicion)).font(.caption.bold())
                ProgressView(value: Double(s.suspicion)).tint(s.suspicion > 0.6 ? .red : .orange).frame(width: 120)
            }
            if s.managerWarning {
                Label("rádio: Dona Celeste está no andar", systemImage: "antenna.radiowaves.left.and.right")
                    .font(.caption2.bold()).foregroundStyle(.orange)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    @ViewBuilder
    private var shiftStrip: some View {
        let s = client.state
        if s.phase != "playing" {
            Text(waitingLine).font(.caption).foregroundStyle(.secondary)
                .padding(.bottom, 8)
        } else {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                ForEach(s.tasks) { t in
                    HStack(spacing: 3) {
                        Image(systemName: t.progress >= 0.9 ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(t.progress >= 0.9 ? .green : .secondary)
                        Text(t.area).font(.caption2)
                    }
                }
            }
            HStack {
                Text(String(format: "Turno %d:%02d", s.shiftSecondsLeft / 60, s.shiftSecondsLeft % 60)).monospacedDigit()
                Spacer()
                Label("\(s.stars)", systemImage: "star.fill").foregroundStyle(.yellow)
                Spacer()
                Text("Provas \(s.evidenceCount)/\(max(1, s.evidenceTotal))")
            }
        }
        .font(.caption).padding(.horizontal, 20).padding(.bottom, 6)
        }
    }

    private var waitingLine: String {
        switch client.state.phase {
        case "hub": return "Vestiário — escolha o disfarce no Mac"
        case "report": return "Relatório da noite no Mac"
        case "deduction": return "Hora de responder ao delegado"
        case "ending": return "Fim da campanha"
        default: return "Aguardando o turno começar no Mac"
        }
    }

    // MARK: Mensagens

    private var messagesTab: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        if client.messages.isEmpty {
                            Text("Sem mensagens ainda. O delegado avisa quando o turno começar.")
                                .foregroundStyle(.secondary).padding()
                        }
                        ForEach(client.messages) { m in
                            VStack(alignment: .leading, spacing: 3) {
                                Text(m.from).font(.caption.bold()).foregroundStyle(m.from == TurnoNet.detectiveName ? .blue : .orange)
                                Text(m.text)
                            }
                            .padding(10)
                            .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                            .id(m.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: client.messages.count) { _, _ in
                    if let last = client.messages.last { withAnimation { proxy.scrollTo(last.id) } }
                }
            }
            .navigationTitle("Mensagens")
        }
    }

    // MARK: Provas

    private var evidenceTab: some View {
        NavigationStack {
            List {
                if client.evidence.isEmpty {
                    Text("Nenhuma prova ainda. Limpe bem e olhe embaixo da sujeira.").foregroundStyle(.secondary)
                } else {
                    Text("O mural fica com você entre as noites.").font(.caption).foregroundStyle(.secondary)
                }
                ForEach(client.evidence) { e in
                    VStack(alignment: .leading, spacing: 4) {
                        Label(e.title, systemImage: "camera.fill").font(.headline)
                        Text(e.detail).font(.callout).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Provas \(client.evidence.count)")
        }
    }

    private func toolIcon(_ t: ToolKind) -> String { t.icon }

    private func suspicionLabel(_ s: Float) -> String {
        s < 0.25 ? "Suspeita baixa" : (s < 0.6 ? "Suspeita: atenção" : "SUSPEITA ALTA")
    }
}

// MARK: - Componentes

struct Joystick: View {
    @Binding var value: SIMD2<Float>
    @State private var knob = CGSize.zero
    private let radius: CGFloat = 60

    var body: some View {
        ZStack {
            Circle().fill(.white.opacity(0.08)).frame(width: radius * 2 + 30, height: radius * 2 + 30)
            Circle().stroke(.white.opacity(0.2)).frame(width: radius * 2 + 30, height: radius * 2 + 30)
            Circle().fill(Color(red: 0.95, green: 0.8, blue: 0.5)).frame(width: 52, height: 52).offset(knob)
                .shadow(radius: 4)
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { g in
                    var t = g.translation
                    let len = sqrt(t.width * t.width + t.height * t.height)
                    if len > radius { t.width *= radius / len; t.height *= radius / len }
                    knob = t
                    value = SIMD2(Float(t.width / radius), Float(-t.height / radius))
                }
                .onEnded { _ in
                    knob = .zero
                    value = .zero
                }
        )
        .padding(.leading, 6)
    }
}

struct HoldButton: View {
    let title: String
    let subtitle: String
    let color: Color
    @Binding var pressed: Bool

    var body: some View {
        VStack(spacing: 2) {
            Text(title).font(.title2.weight(.black))
            Text(subtitle).font(.caption2)
        }
        .frame(width: 180, height: 84)
        .background(pressed ? color : color.opacity(0.55), in: RoundedRectangle(cornerRadius: 18))
        .foregroundStyle(.white)
        .scaleEffect(pressed ? 0.96 : 1)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in if !pressed { pressed = true } }
                .onEnded { _ in pressed = false }
        )
        .animation(.easeOut(duration: 0.08), value: pressed)
    }
}

struct TapButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage).font(.title3)
                Text(title).font(.caption.bold())
            }
            .frame(width: 85, height: 60)
        }
        .buttonStyle(.bordered)
    }
}
