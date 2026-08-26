//
//  Quests.swift
//  Guardiões dos Biomas
//
//  Cada bioma tem uma cadeia de três missões que termina no encontro com o
//  Guardião e na conquista do amuleto. Depois disso o bioma passa a gerar
//  expedições infinitas, com dificuldade e recompensa crescentes.
//

import Foundation

enum ObjectiveKind: String, Codable, CaseIterable {
    case rastro      // encontrar vestígios do animal
    case resgate     // libertar animais presos
    case restauro    // recuperar focos degradados
    case ameaca      // neutralizar a ameaça do bioma
    case desafio     // a mecânica própria daquele bioma, no mundo aberto
    case corrida     // a prova arcade daquele bioma
    case acesso      // ato 1: conquistar o amuleto, ainda sem ele

    var nome: String {
        switch self {
        case .rastro: return "Vestígios"
        case .resgate: return "Resgates"
        case .restauro: return "Restauração"
        case .ameaca: return "Contenção"
        case .desafio: return "Desafio do bioma"
        case .corrida: return "Prova"
        case .acesso: return "Prova de acesso"
        }
    }

    var verbo: String {
        switch self {
        case .rastro: return "Registrar"
        case .resgate: return "Libertar"
        case .restauro: return "Recuperar"
        case .ameaca: return "Conter"
        case .desafio: return "Resolver"
        case .corrida: return "Correr"
        case .acesso: return "Acompanhar"
        }
    }

    var icone: String {
        switch self {
        case .rastro: return "pawprint.fill"
        case .resgate: return "hand.raised.fill"
        case .restauro: return "leaf.arrow.trianglehead.clockwise"
        case .ameaca: return "exclamationmark.shield.fill"
        case .desafio: return "flame.circle.fill"
        case .corrida: return "figure.run"
        case .acesso: return "pawprint.circle.fill"
        }
    }
}

/// Um pedaço do amuleto. Cada bioma tem três, conquistados de formas
/// diferentes — e em qualquer ordem: é o jogador que decide o caminho.
struct Fragmento: Identifiable {
    let kind: ObjectiveKind
    let nome: String
    let descricao: String
    let dica: String
    let alvo: Int
    var id: String { kind.rawValue }
}

/// Mantido para as expedições infinitas, que continuam sendo tarefa avulsa.
struct QuestStage {
    let kind: ObjectiveKind
    let titulo: String
    let descricao: String
    let alvo: Int
    let dica: String
}

enum Quests {

    // MARK: Ato 1 — a prova de acesso

    /// O ato 1 de cada bioma: aguentar uma frente inteira e salvar o bastante
    /// para o Guardião entender que você serve.
    static func acesso(for biome: BiomeID) -> Fragmento? {
        guard let o = Operacao[biome] else { return nil }
        return Fragmento(
            kind: .acesso,
            nome: "Operação: \(o.frente.lowercased())",
            descricao: o.chamada,
            dica: "Salve pelo menos \(o.meta) de \(o.quantidade) \(o.focoPlural) antes de a linha atravessar. Segure E no foco; grupos em fuga têm de ser escoltados até a borda sul.",
            alvo: 1)
    }

    // MARK: Ato 2 — a prova de mérito

    /// Depois do amuleto: usar o poder do bicho para valer.
    static func merito(for biome: BiomeID) -> [Fragmento] {
        guard biome != .refugio, let c = Corrida[biome] else { return [] }
        let animal = Biome[biome].animal
        let corrida = Fragmento(
            kind: .corrida, nome: c.titulo,
            descricao: c.chamada,
            dica: "Vista o amuleto (\(animal.nome)) e ache a largada no bioma.", alvo: 1)

        let o = Operacao[biome]
        let campo = Fragmento(
            kind: .desafio,
            nome: "Segunda operação",
            descricao: "A frente voltou, e mais rápida. Só que agora você tem o corpo do bicho: alcança o que antes estava do outro lado da água, do cipó, do abismo. \(segundaOperacaoTexto(biome))",
            dica: "Mesma regra, menos tempo: salve \(o?.meta ?? 6) \(o?.focoPlural ?? "focos"). Use o amuleto para cortar caminho.",
            alvo: 1)

        return [corrida, campo]
    }

    private static func segundaOperacaoTexto(_ b: BiomeID) -> String {
        switch b {
        case .mataAtlantica: return "Saltando pela copa você chega a fragmento que a pé não tem acesso."
        case .cerrado: return "Na investida você cruza o espinheiro em vez de contorná-lo."
        case .pantanal: return "Planando, a baía deixa de ser desvio e vira atalho."
        case .amazonia: return "Submerso, o lago inteiro passa a ser caminho."
        case .pampa: return "Pelo subsolo você passa por baixo da própria linha do arado."
        case .refugio: return ""
        }
    }

    /// Todos os objetivos do bioma, na ordem dos atos.
    static func fragmentos(for biome: BiomeID) -> [Fragmento] {
        guard let a = acesso(for: biome) else { return [] }
        return [a] + merito(for: biome)
    }

    /// Resumo do desafio característico de cada bioma, para as expedições.
    static func desafioTexto(_ b: BiomeID) -> String {
        switch b {
        case .mataAtlantica: return "Novos grupos de micos ficaram isolados. Leve cada comitiva pela copa até o fragmento vizinho."
        case .cerrado: return "Focos de incêndio reacenderam no capim seco. Abra aceiros e cerque o fogo antes que ele corra."
        case .pantanal: return "Saqueadores voltaram à planície. Chegue aos ninhos de manduvi antes deles."
        case .amazonia: return "Novas malhadeiras foram armadas no fundo dos lagos. Mergulhe e corte cada uma."
        case .pampa: return "O arado abriu nova linha sobre as dunas. Evacue as galerias no caminho da lâmina."
        case .refugio: return ""
        }
    }

    /// Missão infinita gerada após a conclusão da cadeia principal.
    static func expedicao(biome: BiomeID, nivel: Int, seed: UInt64) -> QuestStage {
        var rng = SeededRandom(seed: seed &+ UInt64(nivel &* 7919))
        let kinds: [ObjectiveKind] = [.rastro, .resgate, .restauro, .ameaca, .desafio, .corrida]
        let kind = kinds[rng.int(0, kinds.count - 1)]
        var alvo = 5 + Int(Double(nivel) * 1.6) + rng.int(0, 3)
        // A prova arcade é uma só: o que cresce é a dificuldade dentro dela.
        if kind == .corrida { alvo = 1 }
        let b = Biome[biome]
        let titulos: [ObjectiveKind: String] = [
            .rastro: "Monitoramento nº \(nivel)",
            .resgate: "Operação resgate nº \(nivel)",
            .restauro: "Mutirão de restauro nº \(nivel)",
            .ameaca: "Contenção nº \(nivel)",
            .desafio: "\(Biome[biome].animal.nome) nº \(nivel)",
            .corrida: "\(Corrida[biome]?.titulo ?? "Prova") — repescagem \(nivel)"
        ]
        let descricoes: [ObjectiveKind: String] = [
            .rastro: "A população de \(b.animal.nome.lowercased()) precisa de censo contínuo. Registre novos vestígios pelo território.",
            .resgate: "Chegaram denúncias de novos animais presos em \(b.nome). Vá até lá e liberte cada um.",
            .restauro: "Novas clareiras se abriram. Recupere os focos degradados antes que virem deserto.",
            .ameaca: "\(b.ameaca.nome) voltou a avançar. Contenha as frentes ativas.",
            .desafio: desafioTexto(biome),
            .corrida: Corrida[biome]?.chamada ?? ""
        ]
        return QuestStage(kind: kind,
                          titulo: titulos[kind] ?? "Expedição",
                          descricao: descricoes[kind] ?? "",
                          alvo: alvo,
                          dica: "Dificuldade \(nivel) — o território fica mais hostil a cada expedição.")
    }
}
