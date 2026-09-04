//
//  GameState.swift
//  TurnoMac
//
//  Estado observável do jogo, independente de RealityKit. A UI SwiftUI e o
//  controle (iPhone) leem daqui; o GameLoop escreve.
//

import Foundation
import Observation

enum GamePhase: Equatable {
    case menu           // tela de título
    case hub            // vestiário: mural, papel, melhorias, briefing
    case playing        // turno em andamento
    case report         // relatório da noite
    case deduction      // três perguntas, ao fim da campanha
    case ending(Ending)
}

struct ShiftTask: Identifiable {
    let id: String
    let title: String
    let area: AreaID
    let tool: ToolKind
    var progress: Float = 0
    var done: Bool { progress >= 0.9 }
}

@Observable
@MainActor
final class GameState {
    // Campanha
    var progress = CampaignProgress()
    var night: NightSpec = Campaign.night1
    var role: Role = .camareira
    var currentArea: AreaID = .corredor7

    // Turno
    var phase: GamePhase = .menu
    var tasks: [ShiftTask] = []
    var foundTonight: [String] = []
    var messages: [ChatMessage] = []
    var subtitle: String = ""
    var subtitleUntil: TimeInterval = 0
    var prompt: String = ""
    var currentTool: ToolKind = .none
    var inToolMode: Bool = false
    var suspicion: Float = 0
    var managerNear: Bool = false
    var managerSees: Bool = false
    var managerWarning: Bool = false
    var shiftSecondsLeft: Int = 0
    var toast: String = ""
    var toastUntil: TimeInterval = 0
    var lightsFlicker: Bool = false
    var fade: Float = 0

    // Relatório da noite
    var reportStars: Int = 0
    var reportCaught: Bool = false

    // Rede
    var controllerName: String = ""
    var controllerConnected: Bool { !controllerName.isEmpty }
    var coopPeers: [String: Role] = [:]
    var coopPeerNames: [String] = []

    // Dedução
    var deductionChoice: [CaseQuestion: String] = [:]
    var verdictCorrect: Int = 0

    private var messageCounter = 0
    private var firedTriggers: Set<String> = []

    var onMessage: ((ChatMessage) -> Void)?
    var onEvidence: ((EvidenceCard) -> Void)?
    var onHaptic: ((HapticKind) -> Void)?

    // MARK: Provas

    var boardEvidence: [EvidenceCard] {
        Campaign.evidence.filter { progress.has($0.id) }.map { Campaign.card($0.id) }
    }

    func hasEvidence(_ id: String) -> Bool { progress.has(id) }

    func addEvidence(_ id: String) {
        guard !hasEvidence(id) else { return }
        progress.evidence.append(id)
        if !foundTonight.contains(id) { foundTonight.append(id) }
        let card = Campaign.card(id)
        showToast("Prova registrada · \(card.title)")
        onEvidence?(card)
        onHaptic?(.success)
        fire(id)
        ProgressStore.save(progress)
    }

    // MARK: Noite

    func beginNight(_ n: NightSpec, role r: Role) {
        night = n
        role = r
        progress.role = r
        tasks = n.surfaces.map { ShiftTask(id: $0.id, title: $0.taskTitle, area: $0.area, tool: $0.tool) }
        foundTonight = []
        messages = []
        firedTriggers = []
        subtitle = ""
        prompt = ""
        toast = ""
        currentTool = .none
        inToolMode = false
        suspicion = 0
        managerNear = false
        managerSees = false
        managerWarning = false
        lightsFlicker = false
        shiftSecondsLeft = n.seconds
        currentArea = n.areas.first ?? .corredor7
        reportCaught = false
        reportStars = 0
    }

    func setTask(_ id: String, progress p: Float) {
        guard let i = tasks.firstIndex(where: { $0.id == id }) else { return }
        let wasDone = tasks[i].done
        tasks[i].progress = max(tasks[i].progress, p)
        if !wasDone && tasks[i].done {
            showToast("Tarefa concluída · \(tasks[i].title)")
            onHaptic?(.success)
        }
    }

    var tasksDone: Int { tasks.filter(\.done).count }

    /// Estrelas da noite: uma por tarefa concluída (até 2) e uma por achar tudo.
    func computeStars() -> Int {
        var s = min(2, tasksDone)
        let total = CampaignProgress.totalEvidence(night: night.number)
        if total > 0 && progress.evidenceCount(night: night.number) >= total { s += 1 }
        return s
    }

    // MARK: Mensagens

    func fire(_ trigger: String) {
        guard !firedTriggers.contains(trigger), let lines = Campaign.messages[trigger] else { return }
        firedTriggers.insert(trigger)
        for (i, line) in lines.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 2.6) { [weak self] in
                self?.pushMessage(from: Campaign.detective, text: line)
            }
        }
    }

    func pushMessage(from: String, text: String) {
        messageCounter += 1
        let m = ChatMessage(id: "m\(messageCounter)", from: from, text: text)
        messages.append(m)
        showSubtitle("\(from): \(text)", seconds: 5)
        onMessage?(m)
        onHaptic?(.tick)
    }

    func showSubtitle(_ text: String, seconds: TimeInterval) {
        subtitle = text
        subtitleUntil = Date().timeIntervalSince1970 + seconds
    }

    func showToast(_ text: String) {
        toast = text
        toastUntil = Date().timeIntervalSince1970 + 4
    }

    func tick(now: TimeInterval) {
        if !subtitle.isEmpty && now > subtitleUntil { subtitle = "" }
        if !toast.isEmpty && now > toastUntil { toast = "" }
    }

    // MARK: Estado enviado ao iPhone

    var controllerState: ControllerState {
        let phaseName: String
        switch phase {
        case .menu: phaseName = "menu"
        case .hub: phaseName = "hub"
        case .playing: phaseName = "playing"
        case .report: phaseName = "report"
        case .deduction: phaseName = "deduction"
        case .ending: phaseName = "ending"
        }
        return ControllerState(
            tool: currentTool,
            inToolMode: inToolMode,
            prompt: prompt,
            suspicion: suspicion,
            managerNear: managerNear,
            managerWarning: managerWarning,
            shiftSecondsLeft: shiftSecondsLeft,
            tasks: tasks.map { .init(id: $0.id, title: $0.title, progress: $0.progress, area: $0.area.short) },
            evidenceCount: progress.evidenceCount(night: night.number),
            evidenceTotal: CampaignProgress.totalEvidence(night: night.number),
            phase: phaseName,
            night: night.number,
            nightTitle: night.title,
            role: role.name,
            area: currentArea.short,
            stars: progress.stars,
            trust: progress.trust
        )
    }

    // MARK: Dedução

    func answers(for q: CaseQuestion) -> [Campaign.Answer] {
        (Campaign.answers[q] ?? []).filter { a in
            a.requires.isEmpty || a.requires.allSatisfy { progress.has($0) }
        }
    }

    func resolveVerdict() {
        var correct = 0
        for q in CaseQuestion.allCases {
            if let chosen = deductionChoice[q],
               let a = (Campaign.answers[q] ?? []).first(where: { $0.id == chosen }), a.correct {
                correct += 1
            }
        }
        verdictCorrect = correct
        phase = .ending(correct >= 2 ? .casoResolvido : .casoAberto)
        progress.finished = true
        ProgressStore.save(progress)
    }
}
