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
        VStack(spacing: 2) {
            Text("TURNO DA NOITE").font(.headline.weight(.black)).tracking(3)
                .foregroundStyle(Color(red: 0.95, green: 0.8, blue: 0.5))
            Text(client.status).font(.caption).foregroundStyle(.secondary)
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
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    private var shiftStrip: some View {
        let s = client.state
        return HStack {
            Text(String(format: "Turno %d:%02d", s.shiftSecondsLeft / 60, s.shiftSecondsLeft % 60)).monospacedDigit()
            Spacer()
            ForEach(s.tasks) { t in
                Image(systemName: t.progress >= 0.9 ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(t.progress >= 0.9 ? .green : .secondary)
            }
            Spacer()
            Text("Provas \(s.evidenceCount)/4")
        }
        .font(.caption).padding(.horizontal, 20).padding(.bottom, 6)
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
                }
                ForEach(client.evidence) { e in
                    VStack(alignment: .leading, spacing: 4) {
                        Label(e.title, systemImage: "camera.fill").font(.headline)
                        Text(e.detail).font(.callout).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Provas \(client.evidence.count)/4")
        }
    }

    private func toolIcon(_ t: ToolKind) -> String {
        switch t {
        case .rodo: return "square.and.line.vertical.and.square"
        case .vassoura: return "wind"
        case .pano: return "drop.fill"
        case .ouvido: return "ear"
        case .camera: return "camera"
        case .none: return "figure.walk"
        }
    }

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
