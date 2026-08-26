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

    var nome: String {
        switch self {
        case .rastro: return "Vestígios"
        case .resgate: return "Resgates"
        case .restauro: return "Restauração"
        case .ameaca: return "Contenção"
        }
    }

    var verbo: String {
        switch self {
        case .rastro: return "Registrar"
        case .resgate: return "Libertar"
        case .restauro: return "Recuperar"
        case .ameaca: return "Conter"
        }
    }

    var icone: String {
        switch self {
        case .rastro: return "pawprint.fill"
        case .resgate: return "hand.raised.fill"
        case .restauro: return "leaf.arrow.trianglehead.clockwise"
        case .ameaca: return "exclamationmark.shield.fill"
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
                QuestStage(kind: .resgate, titulo: "Fragmentos isolados",
                           descricao: "A estrada partiu a mata ao meio. Liberte os micos presos em armadilhas e gaiolas deixadas por traficantes.",
                           alvo: 4, dica: "Só a forma humana abre armadilhas: destransforme antes de interagir."),
                QuestStage(kind: .restauro, titulo: "Corredor da copa",
                           descricao: "Plante mudas nos focos degradados para reconectar os fragmentos de floresta.",
                           alvo: 5, dica: "Focos ficam em clareiras abertas pelo desmatamento.")
            ])

        case .cerrado:
            return QuestChain(biome: .cerrado, titulo: "As pernas do horizonte", etapas: [
                QuestStage(kind: .rastro, titulo: "Pegadas na poeira",
                           descricao: "O lobo-guará caminha quilômetros por noite. Registre pegadas e restos de lobeira para traçar sua rota.",
                           alvo: 7, dica: "Use a forma de mico para cortar caminho pelos cipoais."),
                QuestStage(kind: .ameaca, titulo: "Aceiro contra o fogo",
                           descricao: "A queimada avança. Abra aceiros nos focos de fogo antes que fechem os corredores do lobo.",
                           alvo: 5, dica: "O fogo se alastra: contenha os focos mais próximos primeiro."),
                QuestStage(kind: .resgate, titulo: "Travessia da rodovia",
                           descricao: "Atropelamentos são a maior causa de morte da espécie. Guie os lobos feridos até os pontos de travessia segura.",
                           alvo: 4, dica: "Aproxime-se devagar, em forma humana.")
            ])

        case .pantanal:
            return QuestChain(biome: .pantanal, titulo: "Sombra sobre o pasto", etapas: [
                QuestStage(kind: .rastro, titulo: "Marcas nos barrancos",
                           descricao: "A onça marca território arranhando troncos e barrancos às margens dos corixos. Registre as marcas para mapear o corredor que ela ainda usa.",
                           alvo: 8, dica: "A investida do lobo-guará abre os espinheiros do caminho."),
                QuestStage(kind: .ameaca, titulo: "Fogo na pastagem",
                           descricao: "Queimadas de manejo mal controladas empurram a onça para perto do gado, e o conflito vira bala. Contenha os focos de fogo antes que fechem os últimos corredores.",
                           alvo: 6, dica: "O fogo se alastra: contenha os focos mais próximos primeiro."),
                QuestStage(kind: .restauro, titulo: "Corredor da cheia",
                           descricao: "Restaure a mata ciliar que liga os retiros de cheia aos corredores secos, para a onça atravessar a fazenda sem cruzar o pasto aberto.",
                           alvo: 6, dica: "Os focos ficam do outro lado do matagal denso — o Passo Invisível atravessa sem espantar o gado.")
            ])

        case .caatinga:
            return QuestChain(biome: .caatinga, titulo: "Ninho na pedra seca", etapas: [
                QuestStage(kind: .rastro, titulo: "Ninhos na caraibeira",
                           descricao: "A ararinha-azul só nidifica em ocos de caraibeiras centenárias, à beira dos riachos secos da Caatinga. Registre as árvores-ninho que ainda restam ao longo do leito.",
                           alvo: 8, dica: "O Passo Invisível atravessa o matagal denso sem espantar quem ainda está por perto."),
                QuestStage(kind: .resgate, titulo: "Gaiolas no sertão",
                           descricao: "Traficantes ainda armam gaiolas nos poucos ocos que restam. Liberte cada ararinha antes que ela vire mercadoria.",
                           alvo: 5, dica: "Só a forma humana abre gaiolas: destransforme antes de interagir."),
                QuestStage(kind: .restauro, titulo: "Voo de volta",
                           descricao: "A espécie já foi extinta na natureza. Ajude a devolver o que resta plantando caraibeiras e instalando ninhos artificiais para os indivíduos reintroduzidos.",
                           alvo: 6, dica: "Focos ficam nos paredões acima do leito seco — voar ajuda a alcançar.")
            ])

        case .amazonia:
            return QuestChain(biome: .amazonia, titulo: "O gigante do lago", etapas: [
                QuestStage(kind: .rastro, titulo: "Contagem de bodecos",
                           descricao: "O pirarucu sobe para respirar. Conte as subidas nos lagos para estimar a população — é assim que o manejo comunitário funciona de verdade.",
                           alvo: 9, dica: "Planando como arara você enxerga muito mais lago."),
                QuestStage(kind: .ameaca, titulo: "Redes de malha fina",
                           descricao: "Retire as redes ilegais que capturam pirarucus antes da primeira desova.",
                           alvo: 6, dica: "Nade até as redes e retire uma a uma."),
                QuestStage(kind: .restauro, titulo: "Lagos de manejo",
                           descricao: "Reabra os canais que ligam os lagos ao rio para os cardumes voltarem a circular.",
                           alvo: 6, dica: "Alguns canais estão entupidos de terra compactada.")
            ])

        case .pampa:
            return QuestChain(biome: .pampa, titulo: "A cidade sob as dunas", etapas: [
                QuestStage(kind: .rastro, titulo: "Ouvir o chão",
                           descricao: "O tuco-tuco é ouvido antes de ser visto. Registre montículos e galerias ativas nas dunas.",
                           alvo: 8, dica: "Ele vive só no litoral gaúcho — em nenhum outro lugar do mundo."),
                QuestStage(kind: .ameaca, titulo: "Linha do arado",
                           descricao: "O maquinário revira a duna e desmorona as galerias. Marque e detenha as frentes de lavra.",
                           alvo: 7, dica: "Escave para cruzar a terra compactada sem ser visto."),
                QuestStage(kind: .restauro, titulo: "Dunas vivas",
                           descricao: "Refixe a vegetação das dunas para que as galerias voltem a se sustentar.",
                           alvo: 7, dica: "Restaurar duna é devolver casa a uma espécie que só existe aqui.")
            ])
        }
    }

    /// Missão infinita gerada após a conclusão da cadeia principal.
    static func expedicao(biome: BiomeID, nivel: Int, seed: UInt64) -> QuestStage {
        var rng = SeededRandom(seed: seed &+ UInt64(nivel &* 7919))
        let kinds: [ObjectiveKind] = [.rastro, .resgate, .restauro, .ameaca]
        let kind = kinds[rng.int(0, kinds.count - 1)]
        let alvo = 5 + Int(Double(nivel) * 1.6) + rng.int(0, 3)
        let b = Biome[biome]
        let titulos: [ObjectiveKind: String] = [
            .rastro: "Monitoramento nº \(nivel)",
            .resgate: "Operação resgate nº \(nivel)",
            .restauro: "Mutirão de restauro nº \(nivel)",
            .ameaca: "Contenção nº \(nivel)"
        ]
        let descricoes: [ObjectiveKind: String] = [
            .rastro: "A população de \(b.animal.nome.lowercased()) precisa de censo contínuo. Registre novos vestígios pelo território.",
            .resgate: "Chegaram denúncias de novos animais presos em \(b.nome). Vá até lá e liberte cada um.",
            .restauro: "Novas clareiras se abriram. Recupere os focos degradados antes que virem deserto.",
            .ameaca: "\(b.ameaca.nome) voltou a avançar. Contenha as frentes ativas."
        ]
        return QuestStage(kind: kind,
                          titulo: titulos[kind] ?? "Expedição",
                          descricao: descricoes[kind] ?? "",
                          alvo: alvo,
                          dica: "Dificuldade \(nivel) — o território fica mais hostil a cada expedição.")
    }
}
