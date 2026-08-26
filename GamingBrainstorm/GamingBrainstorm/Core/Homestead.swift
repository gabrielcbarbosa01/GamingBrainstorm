//
//  Homestead.swift
//  Guardiões dos Biomas
//
//  O Refúgio deixou de ser só um saguão com portais: tem viveiro de mudas que
//  crescem com o tempo de jogo, um açude para pescar e uma oficina onde os
//  pontos de conservação viram melhorias permanentes.
//

import Foundation

// MARK: - Viveiro

/// Espécie que pode ser cultivada. Todas são plantas reais de restauração,
/// com o papel ecológico que realmente cumprem.
struct Especie: Identifiable, Hashable {
    let id: String
    let nome: String
    let cientifico: String
    let bioma: BiomeID
    /// Segundos de jogo até ficar pronta.
    let tempo: Double
    let custoSementes: Int
    let mudas: Int
    let pontos: Int
    let papel: String

    static let catalogo: [Especie] = [
        Especie(id: "jucara", nome: "Juçara", cientifico: "Euterpe edulis",
                bioma: .mataAtlantica, tempo: 75, custoSementes: 1, mudas: 1, pontos: 60,
                papel: "Palmeira cujo fruto sustenta tucanos, sabiás e o próprio mico-leão."),
        Especie(id: "lobeira", nome: "Lobeira", cientifico: "Solanum lycocarpum",
                bioma: .cerrado, tempo: 110, custoSementes: 1, mudas: 1, pontos: 90,
                papel: "A fruta-do-lobo: metade da dieta do lobo-guará vem daqui."),
        Especie(id: "manduvi", nome: "Manduvi", cientifico: "Sterculia apetala",
                bioma: .pantanal, tempo: 190, custoSementes: 2, mudas: 2, pontos: 220,
                papel: "Copa alta que sombreia os corredores ciliares por onde a onça se desloca sem cruzar o pasto."),
        Especie(id: "caraibeira", nome: "Caraibeira", cientifico: "Tabebuia aurea",
                bioma: .caatinga, tempo: 210, custoSementes: 2, mudas: 2, pontos: 260,
                papel: "Leva décadas para formar o oco onde a ararinha-azul faz ninho."),
        Especie(id: "castanheira", nome: "Castanheira", cientifico: "Bertholletia excelsa",
                bioma: .amazonia, tempo: 250, custoSementes: 3, mudas: 3, pontos: 320,
                papel: "Árvore protegida por lei; sustenta comunidades inteiras sem ser derrubada."),
        Especie(id: "capim", nome: "Capim-das-dunas", cientifico: "Panicum racemosum",
                bioma: .pampa, tempo: 60, custoSementes: 1, mudas: 1, pontos: 70,
                papel: "Fixa a duna. Sem ela a areia anda e as galerias do tuco-tuco desabam.")
    ]

    static func porId(_ id: String) -> Especie? { catalogo.first { $0.id == id } }
}

struct Canteiro: Codable, Identifiable {
    var id: Int
    var especie: String?
    /// Valor de `tempoJogado` no momento do plantio.
    var plantadoEm: Double = 0

    func pronto(agora: Double) -> Bool {
        guard let e = especie, let sp = Especie.porId(e) else { return false }
        return agora - plantadoEm >= sp.tempo
    }

    func progresso(agora: Double) -> Double {
        guard let e = especie, let sp = Especie.porId(e) else { return 0 }
        return min(1, (agora - plantadoEm) / sp.tempo)
    }
}

// MARK: - Pesca

struct Peixe: Identifiable, Hashable {
    let id: String
    let nome: String
    let cientifico: String
    let raridade: Int          // 1 comum … 4 raríssimo
    let pontos: Int
    let essencia: Int
    let nota: String
    /// Peixes que devem ser devolvidos à água valem mais do que os que ficam.
    let soltar: Bool

    static let catalogo: [Peixe] = [
        Peixe(id: "lambari", nome: "Lambari", cientifico: "Astyanax sp.", raridade: 1,
              pontos: 25, essencia: 10, nota: "Peixe pequeno e abundante, base da cadeia.",
              soltar: false),
        Peixe(id: "traira", nome: "Traíra", cientifico: "Hoplias malabaricus", raridade: 1,
              pontos: 35, essencia: 14, nota: "Predadora de emboscada, comum em açudes.",
              soltar: false),
        Peixe(id: "piau", nome: "Piau", cientifico: "Leporinus sp.", raridade: 2,
              pontos: 60, essencia: 18, nota: "Migra rio acima para desovar — barragens o afetam muito.",
              soltar: false),
        Peixe(id: "dourado", nome: "Dourado", cientifico: "Salminus brasiliensis", raridade: 3,
              pontos: 120, essencia: 26, nota: "Grande migrador; sofre com barramentos e sobrepesca.",
              soltar: true),
        Peixe(id: "pirarucu", nome: "Pirarucu jovem", cientifico: "Arapaima gigas", raridade: 4,
              pontos: 300, essencia: 40,
              nota: "Abaixo do tamanho mínimo. Devolver à água é o que faz o manejo funcionar.",
              soltar: true)
    ]

    /// Sorteia um peixe. Um cais melhor puxa a sorte para as espécies raras.
    static func sortear(nivelCais: Int, rng: inout SeededRandom) -> Peixe {
        let r = rng.unit() + Double(nivelCais) * 0.11
        switch r {
        case ..<0.36: return catalogo[0]
        case ..<0.64: return catalogo[1]
        case ..<0.85: return catalogo[2]
        case ..<0.96: return catalogo[3]
        default: return catalogo[4]
        }
    }
}

// MARK: - Melhorias

struct Melhoria: Identifiable {
    let id: String
    let nome: String
    let descricao: String
    let icone: String
    let nivelMaximo: Int
    /// Custo do próximo nível: (pontos, mudas, peixes).
    let custo: (Int) -> (pontos: Int, mudas: Int, peixes: Int)

    static let catalogo: [Melhoria] = [
        Melhoria(id: "viveiro", nome: "Viveiro",
                 descricao: "Mais canteiros no Refúgio. Cada nível abre 2 lugares para plantar.",
                 icone: "leaf.fill", nivelMaximo: 3,
                 custo: { n in (400 * n, 2 * n, 0) }),
        Melhoria(id: "alojamento", nome: "Alojamento",
                 descricao: "Camas, comida e descanso: +40 de essência máxima por nível.",
                 icone: "house.fill", nivelMaximo: 3,
                 custo: { n in (500 * n, 1 * n, 3 * n) }),
        Melhoria(id: "cais", nome: "Cais do açude",
                 descricao: "Estrutura melhor de pesca: aumenta a chance de espécies raras.",
                 icone: "figure.fishing", nivelMaximo: 2,
                 custo: { n in (350 * n, 2, 2 * n) }),
        Melhoria(id: "torre", nome: "Torre de observação",
                 descricao: "Enxerga longe em qualquer bioma: revela caches escondidos mesmo na forma humana.",
                 icone: "binoculars.fill", nivelMaximo: 1,
                 custo: { _ in (900, 4, 4) }),
        Melhoria(id: "oficina", nome: "Oficina de campo",
                 descricao: "Ferramenta boa rende mais: +25% de pontos por objetivo cumprido, por nível.",
                 icone: "wrench.and.screwdriver.fill", nivelMaximo: 2,
                 custo: { n in (600 * n, 3 * n, 1) })
    ]

    static func porId(_ id: String) -> Melhoria? { catalogo.first { $0.id == id } }
}

// MARK: - Estado persistido do Refúgio

struct RefugioSave: Codable {
    var canteiros: [Canteiro] = (0..<4).map { Canteiro(id: $0) }
    var sementes: Int = 5
    var mudas: Int = 0
    var peixes: Int = 0
    var mudasCultivadas: Int = 0       // total histórico, usado pela Harpia
    var peixesPescados: Int = 0
    var melhorias: [String: Int] = [:]
    var especiesCultivadas: [String] = []
    var peixesVistos: [String] = []

    func nivel(_ id: String) -> Int { melhorias[id] ?? 0 }
}
