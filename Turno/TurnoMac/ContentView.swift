//
//  ContentView.swift
//  TurnoMac
//
//  Cena RealityKit + as telas da campanha: título, vestiário (mural, papel,
//  melhorias), turno, relatório da noite, dedução e final.
//

import SwiftUI
import RealityKit

private enum Palette {
    static let ink = Color(red: 0.06, green: 0.05, blue: 0.06)
    static let paper = Color(red: 0.93, green: 0.89, blue: 0.80)
    static let brass = Color(red: 0.86, green: 0.72, blue: 0.42)
    static let blood = Color(red: 0.55, green: 0.14, blue: 0.15)
    static let dim = Color.white.opacity(0.62)
}

/// Barra simples, no lugar do ProgressView do sistema.
struct Meter: View {
    var value: Double
    var width: CGFloat = 120
    var height: CGFloat = 6
    var tint: Color = Palette.brass

    var body: some View {
        ZStack(alignment: .leading) {
            Capsule().fill(.white.opacity(0.15)).frame(width: width, height: height)
            Capsule().fill(tint).frame(width: max(0, min(1, value)) * width, height: height)
        }
        .frame(width: width, height: height)
    }
}

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

            Color.black.opacity(Double(state.fade)).ignoresSafeArea().allowsHitTesting(false)

            switch state.phase {
            case .menu:
                TitleView(state: state) { engine.loop.openHub() }
            case .hub:
                HubView(state: state) { engine.loop.startNight() }
            case .playing:
                HUDView(state: state)
            case .report:
                ReportView(state: state) { engine.loop.afterReport() }
            case .deduction:
                DeductionView(state: state) { engine.state.resolveVerdict() }
            case .ending(let e):
                EndingView(state: state, ending: e) {
                    if e == .descoberta {
                        engine.loop.openHub()
                    } else {
                        ProgressStore.reset()
                        engine.state.progress = CampaignProgress()
                        engine.state.phase = .menu
                    }
                }
            }
        }
        .background(Palette.ink)
    }
}

// MARK: - Título

struct TitleView: View {
    let state: GameState
    let start: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(colors: [.black.opacity(0.9), .black.opacity(0.4)], startPoint: .top, endPoint: .bottom)
            VStack(spacing: 14) {
                Spacer()
                Text("TURNO DA NOITE")
                    .font(.system(size: 58, weight: .black, design: .serif)).tracking(8)
                    .foregroundStyle(Palette.brass)
                Text(Campaign.hotel.uppercased()).font(.title3.smallCaps()).tracking(4).foregroundStyle(Palette.dim)
                Text("Cinco noites. Uma equipe de limpeza. Um hotel que não quer ser limpo.")
                    .italic().foregroundStyle(Palette.dim).padding(.top, 6)
                Spacer().frame(height: 26)
                Button(action: start) {
                    Text(state.progress.night > 1 ? "Continuar — noite \(min(state.progress.night, Campaign.count))" : "Bater o ponto")
                        .font(.title2.bold()).padding(.horizontal, 40).padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent).tint(Palette.blood).keyboardShortcut(.defaultAction)
                StatusLines(state: state)
                Spacer()
            }
            .padding(40)
        }
    }
}

struct StatusLines: View {
    let state: GameState
    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Circle().fill(state.controllerConnected ? .green : .orange).frame(width: 9, height: 9)
                Text(state.controllerConnected
                     ? "iPhone conectado: \(state.controllerName)"
                     : "Aguardando o iPhone (app Turno Controle, mesma rede)")
            }
            HStack(spacing: 8) {
                Circle().fill(state.coopPeerNames.isEmpty ? .gray : .green).frame(width: 9, height: 9)
                Text(state.coopPeerNames.isEmpty
                     ? "Equipe: procurando outros Macs na rede"
                     : "Equipe: \(state.coopPeerNames.joined(separator: ", "))")
            }
            Text("Teclado: W A S D anda · setas olham · espaço/mouse usa · E ação · Esc sai · R recalibra")
                .font(.caption).foregroundStyle(.white.opacity(0.45)).padding(.top, 6)
        }
        .font(.callout).foregroundStyle(.white.opacity(0.8)).padding(.top, 14)
    }
}

// MARK: - Vestiário

struct HubView: View {
    let state: GameState
    let start: () -> Void
    @State private var tab = 0

    private var night: NightSpec { state.night }

    var body: some View {
        ZStack {
            Color.black.opacity(0.93).ignoresSafeArea()
            VStack(spacing: 0) {
                header
                HStack(spacing: 8) {
                    ForEach(Array(["Briefing", "Mural de provas", "Armário"].enumerated()), id: \.offset) { i, name in
                        Button { tab = i } label: {
                            Text(name).font(.callout.bold())
                                .padding(.horizontal, 18).padding(.vertical, 7)
                        }
                        .buttonStyle(.plain)
                        .background(tab == i ? Palette.brass.opacity(0.22) : .white.opacity(0.05),
                                    in: Capsule())
                        .overlay(Capsule().stroke(tab == i ? Palette.brass : .white.opacity(0.12), lineWidth: 1))
                        .foregroundStyle(tab == i ? Palette.brass : Palette.dim)
                    }
                }
                .padding(.vertical, 12)

                Group {
                    switch tab {
                    case 0: briefing
                    case 1: CaseBoardView(state: state)
                    default: lockerRoom
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                Button(action: start) {
                    Text("Começar a noite \(night.number)").font(.title3.bold())
                        .padding(.horizontal, 34).padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent).tint(Palette.blood).keyboardShortcut(.defaultAction)
                .padding(.bottom, 18)
            }
            .padding(.horizontal, 30)
        }
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text("NOITE \(night.number) DE \(Campaign.count)").font(.caption.bold()).tracking(4).foregroundStyle(Palette.dim)
            Text(night.title).font(.system(size: 34, weight: .black, design: .serif)).foregroundStyle(Palette.brass)
            Text(night.epigraph).font(.callout).italic().foregroundStyle(Palette.dim)
            HStack(spacing: 22) {
                Label("\(state.progress.stars) estrelas", systemImage: "star.fill").foregroundStyle(.yellow)
                Label("\(state.boardEvidence.count)/\(Campaign.evidence.count) provas", systemImage: "doc.text.magnifyingglass")
                HStack(spacing: 6) {
                    Image(systemName: "hand.thumbsup")
                    Text("Confiança")
                    Meter(value: Double(state.progress.trust), width: 80,
                          tint: state.progress.trust > 0.6 ? .green : (state.progress.trust < 0.35 ? .red : .orange))
                }
            }
            .font(.caption).foregroundStyle(.white.opacity(0.8)).padding(.top, 8)
        }
        .padding(.top, 22)
    }

    private var briefing: some View {
        HStack(alignment: .top, spacing: 30) {
            VStack(alignment: .leading, spacing: 12) {
                Label("Recado do \(Campaign.detective)", systemImage: "envelope.fill")
                    .font(.headline).foregroundStyle(Palette.brass)
                ForEach(Array(night.briefing.enumerated()), id: \.offset) { _, line in
                    Text("— " + line).foregroundStyle(.white.opacity(0.88))
                }
                Divider().background(.white.opacity(0.2)).padding(.vertical, 4)
                Label("Onde você trabalha hoje", systemImage: "map").font(.headline).foregroundStyle(Palette.brass)
                ForEach(night.areas, id: \.self) { a in
                    Text("• \(a.name)").foregroundStyle(.white.opacity(0.8))
                }
                Label("Tarefas do turno", systemImage: "checklist").font(.headline).foregroundStyle(Palette.brass).padding(.top, 6)
                ForEach(night.surfaces, id: \.id) { s in
                    HStack(spacing: 8) {
                        Image(systemName: s.tool.icon).foregroundStyle(Palette.dim).frame(width: 18)
                        Text(s.taskTitle).foregroundStyle(.white.opacity(0.8))
                        Spacer()
                        Text(s.area.short).font(.caption).foregroundStyle(Palette.dim)
                    }
                }
            }
            .frame(maxWidth: 520, alignment: .leading)

            VStack(alignment: .leading, spacing: 10) {
                Label("Seu disfarce", systemImage: "person.badge.key.fill").font(.headline).foregroundStyle(Palette.brass)
                ForEach(Role.allCases) { r in
                    RoleCard(role: r, selected: state.role == r, takenBy: takenBy(r)) {
                        state.role = r
                        state.progress.role = r
                        ProgressStore.save(state.progress)
                    }
                }
                Text("Cada papel é rápido na sua ferramenta e devagar nas outras. Com quatro pessoas, uma noite dá para cobrir tudo. Sozinha, escolha o que importa e volte outra noite.")
                    .font(.caption).foregroundStyle(Palette.dim).padding(.top, 4)
            }
            .frame(maxWidth: 380, alignment: .leading)
        }
        .padding(.horizontal, 10)
    }

    private func takenBy(_ r: Role) -> String? {
        state.coopPeers.first { $0.value == r }?.key
    }

    private var lockerRoom: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Armário da governanta", systemImage: "cabinet").font(.headline).foregroundStyle(Palette.brass)
                Spacer()
                Label("\(state.progress.stars)", systemImage: "star.fill").foregroundStyle(.yellow)
            }
            Text("Turnos bem feitos viram estrelas, e estrelas viram material melhor.")
                .font(.caption).foregroundStyle(Palette.dim)
            ForEach(Campaign.upgrades) { u in
                let owned = state.progress.hasUpgrade(u.id)
                HStack(spacing: 14) {
                    Image(systemName: u.icon).font(.title2).frame(width: 34)
                        .foregroundStyle(owned ? .green : Palette.brass)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(u.name).font(.headline).foregroundStyle(.white)
                        Text(u.detail).font(.callout).foregroundStyle(Palette.dim)
                    }
                    Spacer()
                    if owned {
                        Label("no carrinho", systemImage: "checkmark.circle.fill").foregroundStyle(.green).font(.caption)
                    } else {
                        Button {
                            guard state.progress.stars >= u.cost else { return }
                            state.progress.stars -= u.cost
                            state.progress.upgrades.append(u.id)
                            ProgressStore.save(state.progress)
                        } label: {
                            Label("\(u.cost)", systemImage: "star.fill").padding(.horizontal, 6)
                        }
                        .buttonStyle(.bordered)
                        .disabled(state.progress.stars < u.cost)
                    }
                }
                .padding(10)
                .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
            }
            Spacer()
        }
        .frame(maxWidth: 720)
    }
}

struct RoleCard: View {
    let role: Role
    let selected: Bool
    let takenBy: String?
    let pick: () -> Void

    var body: some View {
        Button(action: pick) {
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(role.name).font(.headline)
                    Spacer()
                    Image(systemName: role.mainTool.icon).foregroundStyle(Palette.brass)
                }
                Text(role.cover).font(.caption).foregroundStyle(Palette.dim)
                Text(role.pitch).font(.caption).foregroundStyle(.white.opacity(0.7))
                if let t = takenBy {
                    Text("já escolhido por \(t)").font(.caption2).foregroundStyle(.orange)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading).padding(10)
        }
        .buttonStyle(.bordered)
        .tint(selected ? Palette.blood : .gray)
    }
}

// MARK: - Mural de provas

struct CaseBoardView: View {
    let state: GameState
    var scrolls: Bool = true

    private let columns = [GridItem(.adaptive(minimum: 250), spacing: 12)]

    var body: some View {
        if scrolls {
            ScrollView { content }
        } else {
            content
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 18) {
                ForEach(1...Campaign.count, id: \.self) { n in
                    let items = Campaign.evidence.filter { $0.night == n }
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Noite \(n) · \(Campaign.night(n).title)")
                                .font(.headline).foregroundStyle(Palette.brass)
                            Spacer()
                            Text("\(items.filter { state.hasEvidence($0.id) }.count)/\(items.count)")
                                .font(.caption).foregroundStyle(Palette.dim)
                        }
                        LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                            ForEach(items, id: \.id) { e in
                                EvidenceCardView(spec: e, found: state.hasEvidence(e.id))
                            }
                        }
                    }
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("O que ainda falta responder").font(.headline).foregroundStyle(Palette.brass)
                    ForEach(CaseQuestion.allCases, id: \.self) { q in
                        let n = state.answers(for: q).filter { !$0.requires.isEmpty }.count
                        HStack {
                            Image(systemName: n > 0 ? "questionmark.circle.fill" : "questionmark.circle")
                                .foregroundStyle(n > 0 ? .yellow : Palette.dim)
                            Text(q.text).foregroundStyle(.white.opacity(0.85))
                            Spacer()
                            Text(n > 0 ? "\(n) linha(s) de investigação" : "sem nada ainda")
                                .font(.caption).foregroundStyle(Palette.dim)
                        }
                    }
                }
            .padding(.top, 6)
        }
        .padding(.vertical, 6)
    }
}

struct EvidenceCardView: View {
    let spec: EvidenceSpec
    let found: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 6) {
                Image(systemName: found ? "photo.fill" : "questionmark.square.dashed")
                    .foregroundStyle(found ? Palette.brass : Palette.dim)
                Text(found ? spec.title : "não encontrado").font(.subheadline.bold())
                    .foregroundStyle(found ? .white : Palette.dim)
            }
            Text(found ? spec.detail : "Em \(spec.area.name).")
                .font(.caption).foregroundStyle(.white.opacity(found ? 0.75 : 0.4))
                .fixedSize(horizontal: false, vertical: true)
            if found {
                HStack(spacing: 4) {
                    ForEach(spec.unlocks, id: \.self) { q in
                        Text(q.rawValue).font(.caption2.bold()).padding(.horizontal, 5).padding(.vertical, 1)
                            .background(Palette.brass.opacity(0.25), in: Capsule()).foregroundStyle(Palette.brass)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(found ? Color.white.opacity(0.07) : Color.white.opacity(0.025),
                    in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10)
            .stroke(found ? Palette.brass.opacity(0.4) : .white.opacity(0.08), lineWidth: 1))
    }
}

// MARK: - HUD do turno

struct HUDView: View {
    let state: GameState

    private var clock: String {
        String(format: "%d:%02d", state.shiftSecondsLeft / 60, state.shiftSecondsLeft % 60)
    }

    var body: some View {
        ZStack {
            if state.lightsFlicker { Color.black.opacity(0.4).ignoresSafeArea() }
            VStack {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("NOITE \(state.night.number) · \(state.night.title.uppercased())")
                            .font(.caption.bold()).tracking(2).foregroundStyle(Palette.brass)
                        Text("\(state.currentArea.name)  ·  \(clock)")
                            .font(.caption).foregroundStyle(.white.opacity(0.7))
                        ForEach(state.tasks) { t in
                            HStack(spacing: 8) {
                                Image(systemName: t.done ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(t.done ? .green : .white.opacity(0.65))
                                Text(t.title).strikethrough(t.done).foregroundStyle(.white)
                                Meter(value: Double(t.progress), width: 60)
                                Text(t.area.short).font(.caption2).foregroundStyle(Palette.dim)
                            }
                        }
                        HStack(spacing: 8) {
                            Image(systemName: "doc.text.magnifyingglass").foregroundStyle(.yellow)
                            Text("Provas desta noite: \(state.progress.evidenceCount(night: state.night.number))/\(CampaignProgress.totalEvidence(night: state.night.number))")
                                .foregroundStyle(.white)
                        }
                        .padding(.top, 2)
                    }
                    .font(.callout)
                    .padding(12)
                    .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 10))

                    Spacer()

                    VStack(alignment: .trailing, spacing: 6) {
                        HStack(spacing: 8) {
                            Text(suspicionLabel).font(.caption.bold()).foregroundStyle(.white)
                            Image(systemName: state.managerSees ? "eye.fill" : (state.managerNear ? "eye" : "eye.slash"))
                                .foregroundStyle(state.managerSees ? .red : .white.opacity(0.7))
                        }
                        Meter(value: Double(state.suspicion), width: 150,
                              tint: state.suspicion > 0.6 ? .red : .orange)
                        Text(hidingLabel)
                            .font(.caption).foregroundStyle(state.managerWarning ? .orange : .white.opacity(0.65))
                        HStack(spacing: 6) {
                            Image(systemName: state.role.mainTool.icon)
                            Text(state.role.name)
                        }
                        .font(.caption).foregroundStyle(Palette.dim).padding(.top, 2)
                        if !state.coopPeerNames.isEmpty {
                            Label("\(state.coopPeerNames.count + 1) na equipe", systemImage: "person.2.fill")
                                .font(.caption2).foregroundStyle(Palette.dim)
                        }
                    }
                    .padding(12)
                    .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 10))
                }
                Spacer()
                if !state.toast.isEmpty {
                    Text(state.toast).font(.headline).padding(10)
                        .background(Palette.brass.opacity(0.92), in: Capsule()).foregroundStyle(.black)
                }
                if !state.subtitle.isEmpty {
                    Text(state.subtitle).font(.title3).multilineTextAlignment(.center)
                        .padding(.horizontal, 16).padding(.vertical, 8)
                        .background(.black.opacity(0.72), in: RoundedRectangle(cornerRadius: 8))
                        .foregroundStyle(.white).frame(maxWidth: 720)
                }
                if !state.prompt.isEmpty {
                    HStack(spacing: 10) {
                        Image(systemName: state.currentTool.icon).foregroundStyle(Palette.brass)
                        Text(state.prompt)
                    }
                    .font(.callout.bold()).padding(.horizontal, 16).padding(.vertical, 10)
                    .background(.black.opacity(0.65), in: Capsule()).foregroundStyle(.white)
                    .padding(.top, 6)
                }
                Circle().stroke(.white.opacity(state.inToolMode ? 0 : 0.7), lineWidth: 1.5)
                    .frame(width: 8, height: 8).padding(.bottom, 22)
            }
            .padding(18)
        }
        .animation(.easeInOut(duration: 0.2), value: state.toast)
    }

    private var hidingLabel: String {
        if state.managerSees { return "ela está te vendo" }
        if state.managerNear { return "Dona Celeste por perto" }
        if state.managerWarning { return "rádio: ela está no andar" }
        return "fora de vista"
    }

    private var suspicionLabel: String {
        switch state.suspicion {
        case ..<0.25: return "SUSPEITA · baixa"
        case ..<0.6: return "SUSPEITA · atenção"
        default: return "SUSPEITA · ALTA"
        }
    }
}

// MARK: - Relatório da noite

struct ReportView: View {
    let state: GameState
    let next: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.92).ignoresSafeArea()
            VStack(spacing: 16) {
                Text(state.reportCaught ? "TURNO INTERROMPIDO" : "FIM DO TURNO")
                    .font(.caption.bold()).tracking(4).foregroundStyle(Palette.dim)
                Text("Noite \(state.night.number) · \(state.night.title)")
                    .font(.system(size: 34, weight: .black, design: .serif))
                    .foregroundStyle(state.reportCaught ? .red : Palette.brass)

                if state.reportCaught {
                    Text("Dona Celeste percebeu que você não era da limpeza e chamou a segurança. O delegado te tirou de lá, mas a noite foi perdida. Amanhã ela vai estar mais atenta.")
                        .multilineTextAlignment(.center).foregroundStyle(.white.opacity(0.85)).frame(maxWidth: 620)
                } else {
                    Text(state.night.closer)
                        .italic().multilineTextAlignment(.center).foregroundStyle(.white.opacity(0.85)).frame(maxWidth: 620)
                }

                HStack(spacing: 34) {
                    VStack {
                        Text("\(state.tasksDone)/\(state.tasks.count)").font(.title.bold()).foregroundStyle(.white)
                        Text("tarefas").font(.caption).foregroundStyle(Palette.dim)
                    }
                    VStack {
                        Text("\(state.foundTonight.count)").font(.title.bold()).foregroundStyle(.yellow)
                        Text("provas novas").font(.caption).foregroundStyle(Palette.dim)
                    }
                    VStack {
                        HStack(spacing: 2) {
                            ForEach(0..<3, id: \.self) { i in
                                Image(systemName: i < state.reportStars ? "star.fill" : "star")
                                    .foregroundStyle(i < state.reportStars ? .yellow : Palette.dim)
                            }
                        }
                        Text("estrelas").font(.caption).foregroundStyle(Palette.dim)
                    }
                }
                .padding(.vertical, 4)

                if !state.foundTonight.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(state.foundTonight, id: \.self) { id in
                            let e = Campaign.evidence(id)
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "photo.fill").foregroundStyle(Palette.brass)
                                VStack(alignment: .leading) {
                                    Text(e.title).bold().foregroundStyle(.white)
                                    Text(e.detail).font(.caption).foregroundStyle(.white.opacity(0.7))
                                }
                            }
                        }
                    }
                    .frame(maxWidth: 620, alignment: .leading)
                    .padding(12)
                    .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
                }

                if !state.reportCaught && !state.night.unlockText.isEmpty {
                    Label(state.night.unlockText, systemImage: "key.fill")
                        .foregroundStyle(Palette.brass).padding(.top, 2)
                }

                Button(action: next) {
                    Text(state.progress.night > Campaign.count ? "Falar com o delegado" : "Continuar")
                        .font(.title3.bold()).padding(.horizontal, 30).padding(.vertical, 9)
                }
                .buttonStyle(.borderedProminent).tint(Palette.blood).keyboardShortcut(.defaultAction).padding(.top, 8)
            }
            .padding(40)
        }
    }
}

// MARK: - Dedução

struct DeductionView: View {
    let state: GameState
    let accuse: () -> Void
    var scrolls: Bool = true

    var body: some View {
        ZStack {
            Color.black.opacity(0.94).ignoresSafeArea()
            if scrolls { ScrollView { content } } else { content }
        }
    }

    private var content: some View {
        VStack(spacing: 18) {
                    Text("DELEGACIA · MANHÃ DE SEXTA").font(.caption.bold()).tracking(4).foregroundStyle(Palette.dim)
                    Text("Me conta o que você viu.").font(.system(size: 32, weight: .black, design: .serif))
                        .foregroundStyle(Palette.brass)
                    Text("Só aparece o que suas provas sustentam. O resto é palpite, e palpite não abre inquérito.")
                        .font(.callout).foregroundStyle(Palette.dim)

                    ForEach(CaseQuestion.allCases, id: \.self) { q in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(q.text).font(.title3.bold()).foregroundStyle(.white)
                            let options = state.answers(for: q)
                            if options.isEmpty {
                                Text("Você não trouxe nada que sustente uma resposta aqui.")
                                    .font(.callout).foregroundStyle(.red.opacity(0.8))
                            }
                            ForEach(options) { a in
                                Button {
                                    state.deductionChoice[q] = a.id
                                } label: {
                                    HStack {
                                        Image(systemName: state.deductionChoice[q] == a.id ? "largecircle.fill.circle" : "circle")
                                        Text(a.text)
                                        Spacer()
                                    }
                                    .padding(8)
                                }
                                .buttonStyle(.bordered)
                                .tint(state.deductionChoice[q] == a.id ? Palette.blood : .gray)
                            }
                        }
                        .frame(maxWidth: 640, alignment: .leading)
                        .padding(12)
                        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
                    }

                    Button(action: accuse) {
                        Text("Fechar o inquérito").font(.title3.bold())
                            .padding(.horizontal, 30).padding(.vertical, 9)
                    }
                    .buttonStyle(.borderedProminent).tint(Palette.blood)
                    .disabled(state.deductionChoice.count < CaseQuestion.allCases.count)
            .padding(.bottom, 30)
        }
        .padding(30)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Final

struct EndingView: View {
    let state: GameState
    let ending: Ending
    let close: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.95).ignoresSafeArea()
            VStack(spacing: 18) {
                Text(Campaign.endingTitle(ending))
                    .font(.system(size: 44, weight: .black, design: .serif))
                    .foregroundStyle(ending == .casoResolvido ? Palette.brass : .red)
                if ending == .casoResolvido || ending == .casoAberto {
                    Text("\(state.verdictCorrect) de 3 respostas certas")
                        .font(.headline).foregroundStyle(Palette.dim)
                    Text(Campaign.verdictText(correct: state.verdictCorrect))
                        .multilineTextAlignment(.leading).foregroundStyle(.white.opacity(0.88))
                        .frame(maxWidth: 680)
                }
                HStack(spacing: 26) {
                    Label("\(state.boardEvidence.count)/\(Campaign.evidence.count) provas", systemImage: "doc.text.magnifyingglass")
                    Label("\(state.progress.stars) estrelas", systemImage: "star.fill")
                    Label("\(state.progress.timesCaught) vezes descoberta", systemImage: "eye.fill")
                }
                .font(.caption).foregroundStyle(Palette.dim).padding(.top, 6)
                Button(action: close) {
                    Text(ending == .descoberta ? "Voltar ao vestiário" : "Fim").font(.title3.bold())
                        .padding(.horizontal, 30).padding(.vertical, 9)
                }
                .buttonStyle(.borderedProminent).tint(Palette.blood).keyboardShortcut(.defaultAction).padding(.top, 10)
            }
            .padding(40)
        }
    }
}
