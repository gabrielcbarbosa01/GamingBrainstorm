//
//  WorldGenerator.swift
//  Guardiões dos Biomas
//
//  O mundo é infinito: nada é pré-construído. Chunks de 16x16 tiles são
//  gerados sob demanda a partir da semente do bioma + suas coordenadas, e
//  descartados quando ficam longe. Andar 10 km para o norte funciona.
//

import Foundation
import CoreGraphics

/// O que pode nascer num tile além do terreno.
enum SpawnKind: Equatable {
    case objetivo          // ponto de missão (o tipo é decidido pelo estado do jogo)
    case essencia          // recupera essência
    case ameaca            // caçador / fogo / máquina, conforme o bioma
    case segredo           // cache escondido, só revelado pelo faro
    case npc(String)       // habitantes do Refúgio
    case portal(BiomeID)   // viagem entre biomas
    case placa(String)     // painel de leitura
    case canteiro(Int)     // viveiro do Refúgio
    case pesca             // cais do açude
    case oficina           // bancada de melhorias
    case harpia            // a lendária, no fim do jogo
}

struct Spawn {
    let kind: SpawnKind
    let tile: GridPoint
}

/// Um pedaço do mundo, pronto para ser desenhado.
struct ChunkData {
    let coord: GridPoint
    /// tiles[y][x], y e x de 0 a chunkTiles-1.
    var tiles: [[Terrain]]
    var spawns: [Spawn]

    func terrain(localX: Int, localY: Int) -> Terrain {
        tiles[localY][localX]
    }
}

struct WorldGenerator {
    let biome: Biome
    let dificuldade: Int          // nível de expedição: escala a hostilidade
    private let relevo: ValueNoise
    private let umidade: ValueNoise
    private let veio: ValueNoise
    private let seed: UInt64

    init(biome: Biome, dificuldade: Int = 1) {
        self.biome = biome
        self.dificuldade = max(1, dificuldade)
        self.seed = biome.semente
        self.relevo = ValueNoise(seed: biome.semente)
        self.umidade = ValueNoise(seed: biome.semente &+ 7717)
        self.veio = ValueNoise(seed: biome.semente &+ 3313)
    }

    // MARK: - Terreno

    /// Raio (em tiles) da clareira segura em torno da origem de cada bioma.
    private var raioClareira: Double { biome.id == .refugio ? 11 : 5 }

    func terrain(at t: GridPoint) -> Terrain {
        let r = rules
        let dist = (Double(t.x) * Double(t.x) + Double(t.y) * Double(t.y)).squareRoot()

        // Açude do Refúgio: fica a sudoeste da praça, ao lado do cais.
        if biome.id == .refugio {
            let ax = Double(t.x) + 10, ay = Double(t.y) + 7
            let dAcude = (ax * ax + ay * ay).squareRoot()
            if dAcude < 3.6 { return .agua }
            if dAcude < 4.6 { return .areia }
        }

        // Área de chegada sempre limpa e conectada.
        if dist < raioClareira {
            if biome.id == .refugio {
                return dist < 2.2 ? .pedraChao : (dist < 6 ? .trilha : .grama)
            }
            return dist < 2.0 ? .trilha : r.chaoBase
        }

        let x = Double(t.x), y = Double(t.y)
        let h = relevo.fbm(x * r.escalaRelevo, y * r.escalaRelevo, octaves: 4)
        let m = umidade.fbm(x * r.escalaRelevo * 1.9 + 40, y * r.escalaRelevo * 1.9 - 25, octaves: 3)

        // Água e charco vêm do relevo.
        if h < r.limiarAgua { return .agua }
        if h < r.limiarCharco { return .charco }

        // Veios: barreiras sinuosas que só um amuleto abre. Finos de propósito —
        // uma barreira precisa dar volta, não fechar o mapa.
        let v = veio.fbm(x * 0.021, y * 0.021, octaves: 3)
        let largura = r.densidadeEspecial * 0.30
        if largura > 0, abs(v) < largura {
            // Brechas periódicas garantem que nenhum veio feche o mapa.
            let brecha = Hashing.unit(t.x / 3, t.y / 3, seed &+ 91)
            if brecha > 0.26 {
                let v2 = veio.fbm(x * 0.037 - 90, y * 0.037 + 55, octaves: 2)
                return v2 > 0.15 ? r.terrenoEspecialSecundario : r.terrenoEspecial
            }
        }

        // Obstáculos permanentes e vegetação.
        var rng = Hashing.rng(t.x, t.y, seed &+ 5)
        let densidadeMata = r.densidadeArvore * (0.55 + (m + 1) * 0.5)
        if rng.chance(r.densidadeRocha) && h > 0.25 { return .rocha }
        if rng.chance(densidadeMata) { return .tronco }
        if rng.chance(r.densidadeGramaAlta) { return .gramaAlta }

        // Chão base variando com a umidade. Os limiares são largos de propósito:
        // o solo precisa ler como uma superfície contínua, não como xadrez.
        if h > 0.50 { return .pedraChao }
        if m > 0.10 { return r.chaoBase }
        if m < -0.46 { return .areia }
        return r.chaoAlternativo
    }

    private var rules: BiomeTerrainRules { biome.rules }

    // MARK: - Chunks

    func generate(chunk coord: GridPoint) -> ChunkData {
        let n = WorldMetrics.chunkTiles
        var tiles = [[Terrain]](repeating: [Terrain](repeating: .grama, count: n), count: n)
        var livres: [GridPoint] = []

        for ly in 0..<n {
            for lx in 0..<n {
                let world = GridPoint(x: coord.x * n + lx, y: coord.y * n + ly)
                let t = terrain(at: world)
                tiles[ly][lx] = t
                if t.livre { livres.append(world) }
            }
        }

        var spawns: [Spawn] = []
        if biome.id == .refugio {
            spawns = refugioSpawns(chunk: coord, livres: livres)
        } else {
            spawns = biomaSpawns(chunk: coord, livres: livres)
        }

        return ChunkData(coord: coord, tiles: tiles, spawns: spawns)
    }

    // MARK: Spawns dos biomas exploráveis

    private func biomaSpawns(chunk coord: GridPoint, livres: [GridPoint]) -> [Spawn] {
        guard !livres.isEmpty else { return [] }
        var rng = Hashing.rng(coord.x, coord.y, seed &+ 777)
        var spawns: [Spawn] = []
        var usados = Set<GridPoint>()

        func pegarLivre(minDist: Double = 3) -> GridPoint? {
            for _ in 0..<12 {
                let p = livres[rng.int(0, livres.count - 1)]
                if usados.contains(p) { continue }
                let d = (Double(p.x * p.x + p.y * p.y)).squareRoot()
                if d < minDist { continue }
                usados.insert(p)
                return p
            }
            return nil
        }

        // 2 a 4 pontos de missão por chunk mantêm o ritmo de exploração alto.
        let objetivos = rng.int(2, 4)
        for _ in 0..<objetivos {
            if let p = pegarLivre(minDist: 4) { spawns.append(Spawn(kind: .objetivo, tile: p)) }
        }

        // Essência: recurso que limita quanto tempo se fica transformado.
        for _ in 0..<rng.int(1, 3) {
            if let p = pegarLivre() { spawns.append(Spawn(kind: .essencia, tile: p)) }
        }

        // Ameaças escalam com o nível de expedição — o mundo endurece sem fim.
        let ameacas = min(5, rng.int(0, 1) + dificuldade / 2)
        for _ in 0..<ameacas {
            if let p = pegarLivre(minDist: 9) { spawns.append(Spawn(kind: .ameaca, tile: p)) }
        }

        // Segredos: raros, invisíveis até o faro do lobo-guará passar perto.
        if rng.chance(0.28), let p = pegarLivre(minDist: 6) {
            spawns.append(Spawn(kind: .segredo, tile: p))
        }

        // Placas de leitura espalhadas pelo território.
        if rng.chance(0.12), let p = pegarLivre(minDist: 6) {
            spawns.append(Spawn(kind: .placa(placaTexto(&rng)), tile: p))
        }

        return spawns
    }

    private func placaTexto(_ rng: inout SeededRandom) -> String {
        let textos: [String]
        switch biome.id {
        case .mataAtlantica:
            textos = ["Corredor ecológico em implantação — não retire as mudas.",
                      "Área de soltura de micos-leões. Silêncio, por favor.",
                      "Atenção: travessia de fauna nos próximos 2 km."]
        case .cerrado:
            textos = ["Aceiro de contenção. Fogo fora de época mata o que o fogo natural preserva.",
                      "Nascente protegida — aqui começa a água de milhões de pessoas.",
                      "Passagem de fauna sob a rodovia: 800 m à frente."]
        case .pantanal:
            textos = ["Ninho artificial nº \(rng.int(10, 340)) — monitorado desde a última cheia.",
                      "Manduvi centenário. Uma árvore, um berçário.",
                      "Denuncie o tráfico de animais silvestres."]
        case .amazonia:
            textos = ["Lago de manejo comunitário. Pesca permitida somente na cota acordada.",
                      "Área de desova — captura proibida o ano inteiro.",
                      "Contagem anual de pirarucu: feita por quem mora aqui."]
        case .pampa:
            textos = ["Duna fixa em recuperação. Proibido o tráfego de veículos.",
                      "Ctenomys flamarioni ocorre somente nesta faixa litorânea.",
                      "Campo nativo não é terra vaga."]
        case .refugio:
            textos = ["Refúgio Raízes — desde 1994."]
        }
        return rng.pick(textos)
    }

    // MARK: Spawns do Refúgio

    private func refugioSpawns(chunk coord: GridPoint, livres: [GridPoint]) -> [Spawn] {
        // Todo o hub é emitido de uma vez pelo chunk que contém a origem;
        // as posições são em coordenadas de mundo, então podem cair fora dele.
        guard coord == GridPoint(x: 0, y: 0) else { return [] }
        _ = livres

        var spawns: [Spawn] = [
            Spawn(kind: .npc("iara"), tile: GridPoint(x: -3, y: 3)),
            Spawn(kind: .npc("teo"), tile: GridPoint(x: 3, y: 3)),
            Spawn(kind: .placa("Refúgio Raízes — estação de campo. Aqui você está seguro."),
                  tile: GridPoint(x: 0, y: -2)),
            Spawn(kind: .oficina, tile: GridPoint(x: 7, y: 1)),
            Spawn(kind: .pesca, tile: GridPoint(x: -6, y: -6)),
            Spawn(kind: .harpia, tile: GridPoint(x: 0, y: -9))
        ]

        // Viveiro: dez lugares, mas só os construídos ficam utilizáveis.
        for i in 0..<10 {
            let linha = i / 5
            let coluna = i % 5
            spawns.append(Spawn(kind: .canteiro(i),
                                tile: GridPoint(x: 3 + coluna, y: -5 - linha * 2)))
        }

        // Cinco portais em arco ao norte da praça central.
        let raio: Double = 8.0
        for (i, id) in BiomeID.exploraveis.enumerated() {
            let ang = Double.pi * (0.18 + 0.16 * Double(i))
            let tx = Int((cos(ang) * raio).rounded())
            let ty = Int((sin(ang) * raio).rounded())
            spawns.append(Spawn(kind: .portal(id), tile: GridPoint(x: tx, y: ty)))
        }
        return spawns
    }
}
