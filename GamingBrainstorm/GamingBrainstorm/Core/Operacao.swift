//
//  Operacao.swift
//  Guardiões dos Biomas
//
//  A mecânica central de cada bioma: uma frente de destruição avança sobre o
//  território num relógio visível, e à frente dela há focos de vida. Não dá
//  para salvar todos — dá para escolher. É triagem, não coleta.
//

import SpriteKit

struct Operacao {
    let bioma: BiomeID
    /// Nome da frente que avança.
    let frente: String
    let chamada: String
    let ameaca: HazardKind
    /// O que há para salvar, no singular e no plural.
    let foco: String
    let focoPlural: String
    let verbo: String
    /// Forma necessária para efetuar o resgate (nil = qualquer uma).
    let formaResgate: AnimalForm?
    /// Segundos que a frente leva para atravessar o território inteiro.
    let duracao: TimeInterval
    /// Segundos segurando E para completar um resgate.
    let tempoResgate: TimeInterval
    let quantidade: Int
    /// Quantos é preciso salvar para o Guardião considerar a operação um êxito.
    let meta: Int

    static let catalogo: [BiomeID: Operacao] = {
        var m: [BiomeID: Operacao] = [:]
        for o in lista { m[o.bioma] = o }
        return m
    }()

    static subscript(_ b: BiomeID) -> Operacao? { catalogo[b] }

    static let lista: [Operacao] = [
        Operacao(bioma: .mataAtlantica,
                 frente: "Frente de corte",
                 chamada: "As motosserras entraram pelo norte do fragmento e vêm descendo em linha. Cada árvore que cai leva junto um pedaço de território de grupo. Tire quem der para tirar antes da linha passar.",
                 ameaca: .desmatamento,
                 foco: "grupo de micos", focoPlural: "grupos",
                 verbo: "Guiar para fora",
                 formaResgate: nil,
                 duracao: 215, tempoResgate: 2.6, quantidade: 11, meta: 6),

        Operacao(bioma: .cerrado,
                 frente: "Frente de fogo",
                 chamada: "O fogo pegou o vento e virou uma linha só, atravessando o chapadão. Filhotes e ninhadas estão no caminho. Ninguém apaga isso — dá para chegar antes.",
                 ameaca: .queimada,
                 foco: "ninhada", focoPlural: "ninhadas",
                 verbo: "Retirar a ninhada",
                 formaResgate: nil,
                 duracao: 195, tempoResgate: 2.4, quantidade: 12, meta: 7),

        Operacao(bioma: .pantanal,
                 frente: "Linha de saqueadores",
                 chamada: "Uma turma entrou na planície derrubando ninho por ninho, de leste a oeste. Manduvi que perde o oco não volta a servir por décadas. Proteja os que der.",
                 ameaca: .trafico,
                 foco: "ninho de arara", focoPlural: "ninhos",
                 verbo: "Proteger o ninho",
                 formaResgate: .humano,
                 duracao: 205, tempoResgate: 3.0, quantidade: 10, meta: 6),

        Operacao(bioma: .amazonia,
                 frente: "Arrastão de malhadeiras",
                 chamada: "Uma linha de redes está sendo puxada lago adentro. O que ficar atrás dela sai inteiro do rio. Corte as seções que conseguir alcançar.",
                 ameaca: .pescaIlegal,
                 foco: "cardume", focoPlural: "cardumes",
                 verbo: "Cortar a rede",
                 formaResgate: nil,
                 duracao: 200, tempoResgate: 2.8, quantidade: 11, meta: 6),

        Operacao(bioma: .pampa,
                 frente: "Linha do arado",
                 chamada: "O maquinário abriu frente na duna e vem virando a areia de ponta a ponta. Debaixo do chão há galeria com bicho dentro, e daqui de cima não se vê nada disso.",
                 ameaca: .monocultura,
                 foco: "galeria", focoPlural: "galerias",
                 verbo: "Evacuar a galeria",
                 formaResgate: nil,
                 duracao: 185, tempoResgate: 2.2, quantidade: 12, meta: 7)
    ]
}

/// Estado vivo de uma operação, publicado para a interface.
struct OperacaoSessao {
    let config: Operacao
    var salvos: Int = 0
    var perdidos: Int = 0
    var restantes: Int
    var tempoRestante: TimeInterval
    var encerrada = false
    /// Distância da frente até o jogador, 0…1 (1 = longe, 0 = em cima).
    var proximidadeDaFrente: CGFloat = 1
    /// Resgate em andamento, 0…1.
    var resgateEmCurso: CGFloat = 0

    init(config: Operacao) {
        self.config = config
        self.restantes = config.quantidade
        self.tempoRestante = config.duracao
    }

    var total: Int { config.quantidade }
    var atingiuMeta: Bool { salvos >= config.meta }
    var fracaoTempo: CGFloat { CGFloat(max(0, tempoRestante) / config.duracao) }
}

/// Geometria do território de uma operação. O mundo continua infinito, mas a
/// operação acontece numa faixa com começo e fim — é isso que dá forma ao espaço.
enum Territorio {
    /// Meia-largura e meia-altura da área de operação, em tiles.
    static let raioTiles = 34

    static var largura: CGFloat { CGFloat(raioTiles) * 2 * WorldMetrics.tileSize }

    /// Onde o jogador chega: perto da borda segura, ao sul.
    static var chegada: CGPoint {
        CGPoint(x: 0, y: -CGFloat(raioTiles - 5) * WorldMetrics.tileSize)
    }

    static var yFrenteInicial: CGFloat { CGFloat(raioTiles + 3) * WorldMetrics.tileSize }
    static var yFrenteFinal: CGFloat { -CGFloat(raioTiles + 3) * WorldMetrics.tileSize }

    static func dentro(_ p: CGPoint) -> Bool {
        let lim = CGFloat(raioTiles) * WorldMetrics.tileSize
        return abs(p.x) < lim && abs(p.y) < lim
    }
}
