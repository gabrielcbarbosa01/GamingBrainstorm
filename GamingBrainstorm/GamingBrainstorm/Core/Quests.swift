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
    case desafio     // a mecânica própria daquele bioma

    var nome: String {
        switch self {
        case .rastro: return "Vestígios"
        case .resgate: return "Resgates"
        case .restauro: return "Restauração"
        case .ameaca: return "Contenção"
        case .desafio: return "Desafio do bioma"
        }
    }

    var verbo: String {
        switch self {
        case .rastro: return "Registrar"
        case .resgate: return "Libertar"
        case .restauro: return "Recuperar"
        case .ameaca: return "Conter"
        case .desafio: return "Resolver"
        }
    }

    var icone: String {
        switch self {
        case .rastro: return "pawprint.fill"
        case .resgate: return "hand.raised.fill"
        case .restauro: return "leaf.arrow.trianglehead.clockwise"
        case .ameaca: return "exclamationmark.shield.fill"
        case .desafio: return "flame.circle.fill"
        }
    }
}

struct QuestStage {
    let kind: ObjectiveKind
    let titulo: String
    let descricao: String
    let alvo: Int
    /// Amuleto que ajuda (ou é indispensável) nesta etapa — usado nas dicas.
    let dica: String
}

struct QuestChain {
    let biome: BiomeID
    let titulo: String
    let etapas: [QuestStage]
}

enum Quests {
    static func chain(for biome: BiomeID) -> QuestChain {
        switch biome {
        case .refugio:
            return QuestChain(biome: .refugio, titulo: "Primeiros passos", etapas: [
                QuestStage(kind: .rastro, titulo: "Calibrar o rastreador",
                           descricao: "Colete três amostras ao redor do Refúgio para calibrar o rastreador de campo.",
                           alvo: 3, dica: "Ande até os pontos brilhantes e pressione E.")
            ])

        case .mataAtlantica:
            return QuestChain(biome: .mataAtlantica, titulo: "O grito dourado", etapas: [
                QuestStage(kind: .rastro, titulo: "Seguir o grupo",
                           descricao: "Micos-leões vivem em grupos familiares. Registre vestígios — frutos mordidos, pelos em galhos, marcas de garra — para mapear o território do grupo.",
                           alvo: 6, dica: "Vestígios se escondem no capim alto e sob as copas."),
                QuestStage(kind: .desafio, titulo: "Travessia da copa",
                           descricao: "A estrada partiu a mata em dois. Grupos de micos ficaram presos de um lado e não descem ao chão de jeito nenhum — ali embaixo é onde eles morrem. Vire mico, ganhe a confiança do grupo e leve a comitiva saltando até o outro fragmento.",
                           alvo: 3, dica: "Só na forma de mico eles seguem você. Se ficar longe demais, o grupo entra em pânico e se dispersa."),
                QuestStage(kind: .restauro, titulo: "Corredor da copa",
                           descricao: "Plante mudas nos focos degradados para reconectar os fragmentos de floresta.",
                           alvo: 5, dica: "Focos ficam em clareiras abertas pelo desmatamento.")
            ])

        case .cerrado:
            return QuestChain(biome: .cerrado, titulo: "As pernas do horizonte", etapas: [
                QuestStage(kind: .rastro, titulo: "Pegadas na poeira",
                           descricao: "O lobo-guará caminha quilômetros por noite. Registre pegadas e restos de lobeira para traçar sua rota.",
                           alvo: 7, dica: "Use a forma de mico para cortar caminho pelos cipoais."),
                QuestStage(kind: .desafio, titulo: "Aceiro contra o fogo",
                           descricao: "O fogo corre pelo capim seco, tile por tile, e dobra de tamanho se você hesitar. Não dá para apagar: dá para cercar. Abra aceiros — faixas de terra nua — até o fogo não ter para onde ir.",
                           alvo: 3, dica: "A investida do lobo-guará raspa o chão e abre aceiro em linha. Corte à frente das chamas, não atrás."),
                QuestStage(kind: .resgate, titulo: "Travessia da rodovia",
                           descricao: "Atropelamentos são a maior causa de morte da espécie. Guie os lobos feridos até os pontos de travessia segura.",
                           alvo: 4, dica: "Aproxime-se devagar, em forma humana.")
            ])

        case .pantanal:
            return QuestChain(biome: .pantanal, titulo: "Azul contra o céu", etapas: [
                QuestStage(kind: .rastro, titulo: "Mapa dos ninhos",
                           descricao: "Araras-azuis só nidificam em ocos de manduvi centenários. Registre as árvores-ninho da planície.",
                           alvo: 8, dica: "A investida do lobo-guará abre os espinheiros do caminho."),
                QuestStage(kind: .desafio, titulo: "Vigília dos ninhos",
                           descricao: "Cada manduvi com oco é um berçário, e há saqueadores caminhando na direção deles agora. Chegue antes. Voar é o único jeito de cobrir a distância a tempo — mas instalar a proteção exige mão humana.",
                           alvo: 4, dica: "Plane até o ninho como arara, pouse e volte a ser gente (Q) para instalar a proteção."),
                QuestStage(kind: .restauro, titulo: "Ninhos artificiais",
                           descricao: "Instale ninhos artificiais nos manduvis ocos para devolver à arara o lugar de criar.",
                           alvo: 6, dica: "Focos ficam do outro lado dos barrancos — voar ajuda.")
            ])

        case .amazonia:
            return QuestChain(biome: .amazonia, titulo: "O gigante do lago", etapas: [
                QuestStage(kind: .rastro, titulo: "Contagem de bodecos",
                           descricao: "O pirarucu sobe para respirar. Conte as subidas nos lagos para estimar a população — é assim que o manejo comunitário funciona de verdade.",
                           alvo: 9, dica: "Planando como arara você enxerga muito mais lago."),
                QuestStage(kind: .desafio, titulo: "Malhadeiras",
                           descricao: "As redes ilegais estão no fundo, e o pirarucu tem um problema que nenhum outro peixe grande tem: ele respira ar. Mergulhe, corte a rede segurando E — e volte à tona antes que o fôlego acabe.",
                           alvo: 4, dica: "Segure ESPAÇO para submergir. O fôlego cai enquanto você está embaixo e só volta na superfície."),
                QuestStage(kind: .restauro, titulo: "Lagos de manejo",
                           descricao: "Reabra os canais que ligam os lagos ao rio para os cardumes voltarem a circular.",
                           alvo: 6, dica: "Alguns canais estão entupidos de terra compactada.")
            ])

        case .pampa:
            return QuestChain(biome: .pampa, titulo: "A cidade sob as dunas", etapas: [
                QuestStage(kind: .rastro, titulo: "Ouvir o chão",
                           descricao: "O tuco-tuco é ouvido antes de ser visto. Registre montículos e galerias ativas nas dunas.",
                           alvo: 8, dica: "Ele vive só no litoral gaúcho — em nenhum outro lugar do mundo."),
                QuestStage(kind: .desafio, titulo: "Sob o arado",
                           descricao: "O arado avança em linha reta sobre a duna e desaba tudo que houver embaixo. As galerias com bicho dentro estão no caminho. Escave até cada uma e tire os tuco-tucos antes da lâmina chegar.",
                           alvo: 4, dica: "Só se chega às galerias por baixo. Segure ESPAÇO para escavar — mas embaixo da terra você quase não enxerga."),
                QuestStage(kind: .restauro, titulo: "Dunas vivas",
                           descricao: "Refixe a vegetação das dunas para que as galerias voltem a se sustentar.",
                           alvo: 7, dica: "Restaurar duna é devolver casa a uma espécie que só existe aqui.")
            ])
        }
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
        let kinds: [ObjectiveKind] = [.rastro, .resgate, .restauro, .ameaca, .desafio, .desafio]
        let kind = kinds[rng.int(0, kinds.count - 1)]
        let alvo = 5 + Int(Double(nivel) * 1.6) + rng.int(0, 3)
        let b = Biome[biome]
        let titulos: [ObjectiveKind: String] = [
            .rastro: "Monitoramento nº \(nivel)",
            .resgate: "Operação resgate nº \(nivel)",
            .restauro: "Mutirão de restauro nº \(nivel)",
            .ameaca: "Contenção nº \(nivel)",
            .desafio: "\(Biome[biome].animal.nome) nº \(nivel)"
        ]
        let descricoes: [ObjectiveKind: String] = [
            .rastro: "A população de \(b.animal.nome.lowercased()) precisa de censo contínuo. Registre novos vestígios pelo território.",
            .resgate: "Chegaram denúncias de novos animais presos em \(b.nome). Vá até lá e liberte cada um.",
            .restauro: "Novas clareiras se abriram. Recupere os focos degradados antes que virem deserto.",
            .ameaca: "\(b.ameaca.nome) voltou a avançar. Contenha as frentes ativas.",
            .desafio: desafioTexto(biome)
        ]
        return QuestStage(kind: kind,
                          titulo: titulos[kind] ?? "Expedição",
                          descricao: descricoes[kind] ?? "",
                          alvo: alvo,
                          dica: "Dificuldade \(nivel) — o território fica mais hostil a cada expedição.")
    }
}
