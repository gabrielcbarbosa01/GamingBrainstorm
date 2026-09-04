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
    case menu
    case playing
    case deduction
    case ending(Ending)
}

struct ShiftTask: Identifiable {
    let id: String
    let title: String
    var progress: Float = 0
    var done: Bool { progress >= 0.9 }
}

@Observable
final class GameState {
    var phase: GamePhase = .menu
    var tasks: [ShiftTask] = [
        .init(id: "vidro", title: "Limpar o vidro do fim do corredor"),
        .init(id: "chao", title: "Varrer o corredor da suíte 7"),
        .init(id: "mesa", title: "Limpar a mesa do quarto 5"),
    ]
    var foundEvidence: [EvidenceCard] = []
    var messages: [ChatMessage] = []
    var subtitle: String = ""
    var subtitleUntil: TimeInterval = 0
    var prompt: String = ""
    var currentTool: ToolKind = .none
    var inToolMode: Bool = false
    var suspicion: Float = 0
    var managerNear: Bool = false
    var managerSees: Bool = false
    var shiftSecondsLeft: Int = Story.shiftSeconds
    var toast: String = ""
    var toastUntil: TimeInterval = 0
    var controllerName: String = ""
    var controllerConnected: Bool { !controllerName.isEmpty }
    var coopPeers: Int = 0
    var lightsFlicker: Bool = false

    private var messageCounter = 0
    private var firedTriggers: Set<String> = []

    /// Eventos que a camada de rede/háptica quer observar.
    var onMessage: ((ChatMessage) -> Void)?
    var onEvidence: ((EvidenceCard) -> Void)?
    var onHaptic: ((HapticKind) -> Void)?

    func reset() {
        phase = .menu
        for i in tasks.indices { tasks[i].progress = 0 }
        foundEvidence = []
        messages = []
        subtitle = ""
        prompt = ""
        currentTool = .none
        inToolMode = false
        suspicion = 0
        managerNear = false
        managerSees = false
        shiftSecondsLeft = Story.shiftSeconds
        toast = ""
        firedTriggers = []
        lightsFlicker = false
    }

    func setTask(_ id: String, progress: Float) {
        guard let i = tasks.firstIndex(where: { $0.id == id }) else { return }
        let wasDone = tasks[i].done
        tasks[i].progress = max(tasks[i].progress, progress)
        if !wasDone && tasks[i].done {
            showToast("Tarefa concluída: \(tasks[i].title)")
            onHaptic?(.success)
        }
    }

    func hasEvidence(_ id: String) -> Bool {
        foundEvidence.contains { $0.id == id }
    }

    func addEvidence(_ id: String) {
        guard !hasEvidence(id) else { return }
        let card = Story.card(id)
        foundEvidence.append(card)
        showToast("Prova registrada: \(card.title)")
        onEvidence?(card)
        onHaptic?(.success)
        fire(id)
    }

    /// Dispara as mensagens do delegado de um gatilho, uma única vez.
    func fire(_ trigger: String) {
        guard !firedTriggers.contains(trigger), let lines = Story.messages[trigger] else { return }
        firedTriggers.insert(trigger)
        for (i, line) in lines.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 2.4) { [weak self] in
                self?.pushMessage(from: Story.detective, text: line)
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

    var tasksDone: Int { tasks.filter { $0.done }.count }

    var controllerState: ControllerState {
        var phaseName: String
        switch phase {
        case .menu: phaseName = "menu"
        case .playing: phaseName = "playing"
        case .deduction: phaseName = "deduction"
        case .ending: phaseName = "ending"
        }
        return ControllerState(
            tool: currentTool,
            inToolMode: inToolMode,
            prompt: prompt,
            suspicion: suspicion,
            managerNear: managerNear,
            shiftSecondsLeft: shiftSecondsLeft,
            tasks: tasks.map { .init(id: $0.id, title: $0.title, progress: $0.progress) },
            evidenceCount: foundEvidence.count,
            phase: phaseName
        )
    }

    /// Resolve a dedução final.
    func accuse(_ suspectID: String) {
        phase = .ending(suspectID == Story.culprit ? .casoResolvido : .casoErrado)
    }
}
