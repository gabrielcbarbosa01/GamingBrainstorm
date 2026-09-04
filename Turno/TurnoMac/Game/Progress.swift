//
//  Progress.swift
//  TurnoMac
//
//  Progressão que sobrevive entre as noites: provas no mural, confiança da
//  equipe, estrelas do turno e melhorias compradas. Salvo em JSON no container
//  do app.
//

import Foundation

struct CampaignProgress: Codable {
    /// Próxima noite a jogar (1...5). Passa de 5 quando a campanha acaba.
    var night: Int = 1
    /// Ids de provas já registradas no mural, em qualquer noite.
    var evidence: [String] = []
    /// Confiança da equipe/gerência, 0...1. Começa neutra.
    var trust: Float = 0.5
    /// Estrelas não gastas.
    var stars: Int = 0
    /// Estrelas ganhas por noite, para o relatório.
    var starsByNight: [String: Int] = [:]
    var upgrades: [String] = []
    var lastRole: String = Role.camareira.rawValue
    /// Noites em que a policial foi descoberta (a gerência fica mais atenta).
    var timesCaught: Int = 0
    var finished: Bool = false

    var role: Role {
        get { Role(rawValue: lastRole) ?? .camareira }
        set { lastRole = newValue.rawValue }
    }

    func has(_ evidenceID: String) -> Bool { evidence.contains(evidenceID) }
    func hasUpgrade(_ id: String) -> Bool { upgrades.contains(id) }

    /// Provas desta noite que já estão no mural.
    func evidenceCount(night n: Int) -> Int {
        Campaign.evidence.filter { $0.night == n && has($0.id) }.count
    }

    static func totalEvidence(night n: Int) -> Int {
        Campaign.evidence.filter { $0.night == n }.count
    }

    var canBuy: [UpgradeSpec] {
        Campaign.upgrades.filter { !hasUpgrade($0.id) }
    }

    /// Vigilância extra da gerência conforme o histórico.
    var managerAlertness: Float {
        var v: Float = 1
        v += Float(timesCaught) * 0.25
        v += max(0, 0.5 - trust) * 0.8
        if hasUpgrade("luvas") { v -= 0.25 }
        return max(0.5, v)
    }
}

@MainActor
enum ProgressStore {
    private static var url: URL {
        let dir = (try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true))
            ?? FileManager.default.temporaryDirectory
        return dir.appendingPathComponent("turno-progresso.json")
    }

    static func load() -> CampaignProgress {
        guard ProcessInfo.processInfo.environment["TURNO_FRESH"] != "1",
              let data = try? Data(contentsOf: url),
              let p = try? JSONDecoder().decode(CampaignProgress.self, from: data) else {
            return CampaignProgress()
        }
        return p
    }

    static func save(_ p: CampaignProgress) {
        guard let data = try? JSONEncoder().encode(p) else { return }
        try? data.write(to: url, options: .atomic)
    }

    static func reset() {
        try? FileManager.default.removeItem(at: url)
    }
}
