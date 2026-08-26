//
//  Corrida.swift
//  Guardiões dos Biomas
//
//  As provas arcade. Cada bioma tem uma corrida com regras próprias — pista
//  de três faixas, fuga do fogo, voo por corredor, travessia de troncos e
//  túnel — jogadas em cena separada, com câmera travada e rolagem contínua.
//

import SpriteKit

enum ModoCorrida: String, Codable {
    case pistas      // Mata Atlântica: três faixas, salta e troca de faixa
    case fuga        // Cerrado: a mesma pista, mas com uma parede de fogo atrás
    case voo         // Pantanal: sobe e desce, passa pelos vãos
    case travessia   // Amazônia: pula de tronco em jacaré sobre o rio
    case tunel       // Pampa: túnel escuro, lâminas descendo

    var nome: String {
        switch self {
        case .pistas: return "Corrida na copa"
        case .fuga: return "Fuga do fogo"
        case .voo: return "Voo entre os manduvis"
        case .travessia: return "Travessia dos jacarés"
        case .tunel: return "Galeria sob o arado"
        }
    }
}

struct Corrida {
    let bioma: BiomeID
    let modo: ModoCorrida
    let titulo: String
    let chamada: String
    let comoJogar: [String]
    let forma: AnimalForm
    /// Metros a percorrer para completar a prova.
    let meta: CGFloat
    let velocidadeBase: CGFloat
    let aceleracao: CGFloat
    let vidas: Int

    static let catalogo: [BiomeID: Corrida] = {
        var m: [BiomeID: Corrida] = [:]
        for c in lista { m[c.bioma] = c }
        return m
    }()

    static subscript(_ b: BiomeID) -> Corrida? { catalogo[b] }

    static let lista: [Corrida] = [
        Corrida(bioma: .mataAtlantica, modo: .pistas,
                titulo: "Corrida na copa",
                chamada: "O corredor de mata é estreito e a estrada corta tudo. Atravesse pelo alto, sem tocar o chão.",
                comoJogar: ["A ← → D trocam de galho",
                            "ESPAÇO salta sobre o que for baixo",
                            "O que for alto demais, desvie trocando de faixa",
                            "Frutos de juçara recuperam fôlego e valem pontos"],
                forma: .micoLeaoDourado, meta: 900,
                velocidadeBase: 430, aceleracao: 11, vidas: 3),

        Corrida(bioma: .cerrado, modo: .fuga,
                titulo: "Fuga do fogo",
                chamada: "A frente de fogo veio com o vento. Não dá para apagar: dá para correr mais rápido que ela.",
                comoJogar: ["A ← → D trocam de faixa",
                            "ESPAÇO salta cupinzeiro e tronco",
                            "Cada batida deixa o fogo ganhar terreno",
                            "Se o fogo alcançar você, acabou — não há vidas aqui"],
                forma: .loboGuara, meta: 1000,
                velocidadeBase: 470, aceleracao: 14, vidas: 1),

        Corrida(bioma: .pantanal, modo: .voo,
                titulo: "Voo entre os manduvis",
                chamada: "Os ninhos ficam do outro lado da baía. Entre as árvores há vão — em quase todas.",
                comoJogar: ["Segure ESPAÇO para subir, solte para descer",
                            "Passe pelos vãos entre os manduvis",
                            "Encostar em galho ou no chão custa uma pena",
                            "Coletar ninhos rende pontos"],
                forma: .araraAzul, meta: 850,
                velocidadeBase: 400, aceleracao: 9, vidas: 3),

        Corrida(bioma: .amazonia, modo: .travessia,
                titulo: "Travessia dos jacarés",
                chamada: "O lago está cheio e o barco não passa. Troncos e jacarés são a única ponte.",
                comoJogar: ["A ← → D andam sobre o tronco",
                            "ESPAÇO pula para a fileira seguinte",
                            "Troncos e jacarés se movem — leia o ritmo antes de saltar",
                            "Jacaré afunda se você demorar em cima dele"],
                forma: .pirarucu, meta: 26,
                velocidadeBase: 0, aceleracao: 0, vidas: 3),

        Corrida(bioma: .pampa, modo: .tunel,
                titulo: "Galeria sob o arado",
                chamada: "A lâmina passa por cima e a galeria desaba atrás de você. Corra até a saída.",
                comoJogar: ["A ← → D trocam de galeria",
                            "ESPAÇO salta raiz e pedra",
                            "As lâminas descem com aviso — leia a marca antes",
                            "Aqui embaixo se enxerga pouco: reaja rápido"],
                forma: .tucoTuco, meta: 950,
                velocidadeBase: 445, aceleracao: 13, vidas: 3)
    ]
}

/// Fase da prova. A cena só simula durante `.correndo`.
enum FaseCorrida: Equatable {
    case instrucoes
    case correndo
    case fim(sucesso: Bool)
}

/// Estado vivo de uma prova. Os números são publicados com folga pela cena.
struct CorridaSessao {
    let config: Corrida
    var fase: FaseCorrida = .instrucoes
    var progresso: CGFloat = 0      // metros (ou fileiras, na travessia)
    var coletados: Int = 0
    var vidas: Int
    /// Só na fuga do fogo: distância da frente de fogo, 0…1.
    var folga: CGFloat = 1
    var recorde: Int = 0

    init(config: Corrida, recorde: Int) {
        self.config = config
        self.vidas = config.vidas
        self.recorde = recorde
    }

    var fracao: CGFloat { min(1, progresso / config.meta) }
}
