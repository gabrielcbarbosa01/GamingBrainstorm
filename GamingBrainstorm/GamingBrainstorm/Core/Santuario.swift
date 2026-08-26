//
//  Santuario.swift
//  Guardiões dos Biomas
//
//  A masmorra de cada bioma, à moda dos Zelda antigos: um grafo de salas com
//  portas trancadas, chaves espalhadas, baús, um item no meio do caminho — o
//  amuleto — e o Guardião no fim, atrás de uma porta que só o item abre.
//

import Foundation
import CoreGraphics

enum Direcao: Int, CaseIterable {
    case norte, sul, leste, oeste

    var oposta: Direcao {
        switch self {
        case .norte: return .sul
        case .sul: return .norte
        case .leste: return .oeste
        case .oeste: return .leste
        }
    }

    var passo: (x: Int, y: Int) {
        switch self {
        case .norte: return (0, 1)
        case .sul: return (0, -1)
        case .leste: return (1, 0)
        case .oeste: return (-1, 0)
        }
    }
}

enum TipoPorta {
    case aberta
    case trancada      // pede uma chave pequena
    case selada        // só o amuleto do bioma abre
    case doGuardiao    // pede a Chave do Guardião — é a porta do chefe
    case fechada       // abre quando a sala é limpa
}

enum ConteudoSala {
    case entrada
    case vazia
    case inimigos(Int)
    case chave(Int)        // inimigos que soltam a chave ao serem afugentados
    case bau(Tesouro)
    case amuleto
    case chefe
    case puzzle            // interruptores a acionar
}

enum Tesouro {
    case coracao            // um coração a mais, para sempre
    case chave
    case mapa               // revela a planta do santuário
    case bussola            // marca baús e o chefe na planta
    case chaveDoGuardiao    // abre a porta do chefe
    case essencia(Int)

    var nome: String {
        switch self {
        case .coracao: return "Fruto do Vigor"
        case .chave: return "Chave pequena"
        case .mapa: return "Planta do santuário"
        case .bussola: return "Bússola do zelador"
        case .chaveDoGuardiao: return "Chave do Guardião"
        case .essencia: return "Cacho de essência"
        }
    }

    var icone: String {
        switch self {
        case .coracao: return "heart.fill"
        case .chave: return "key.fill"
        case .mapa: return "map.fill"
        case .bussola: return "location.north.circle.fill"
        case .chaveDoGuardiao: return "key.horizontal.fill"
        case .essencia: return "bolt.fill"
        }
    }
}

struct Sala {
    let coord: GridPoint
    var portas: [Direcao: TipoPorta] = [:]
    var conteudo: ConteudoSala = .vazia
    /// Distância em salas desde a entrada — usada para escalar a dificuldade.
    var profundidade: Int = 0
}

struct Santuario {
    let bioma: BiomeID
    let nome: String
    var salas: [GridPoint: Sala] = [:]
    var entrada: GridPoint = GridPoint(x: 0, y: 0)
    var chefe: GridPoint = GridPoint(x: 0, y: 0)
    var salaDoAmuleto: GridPoint = GridPoint(x: 0, y: 0)
    var salaDaChaveDoGuardiao: GridPoint = GridPoint(x: 0, y: 0)
    var totalChaves: Int = 0

    static func nome(de b: BiomeID) -> String {
        switch b {
        case .refugio: return "Refúgio"
        case .mataAtlantica: return "Santuário da Copa"
        case .cerrado: return "Santuário das Veredas"
        case .pantanal: return "Santuário dos Ocos"
        case .amazonia: return "Santuário dos Lagos"
        case .pampa: return "Santuário das Dunas"
        }
    }

    /// Constrói a masmorra do bioma. Determinístico: a mesma semente dá sempre
    /// o mesmo santuário, mas cada bioma tem o seu.
    static func gerar(bioma: BiomeID, seed: UInt64) -> Santuario {
        // Tenta algumas sementes até sair um traçado com tamanho decente. É mais
        // barato que consertar um caminho ruim depois.
        for tentativa in 0..<40 {
            if let s = tentar(bioma: bioma, seed: seed &+ UInt64(tentativa) &* 7919),
               s.salas.count >= 10,
               s.salas.values.contains(where: { $0.portas.values.contains(.selada) }) {
                return s
            }
        }
        return tentar(bioma: bioma, seed: seed) ?? Santuario(bioma: bioma, nome: nome(de: bioma))
    }

    private static func tentar(bioma: BiomeID, seed: UInt64) -> Santuario? {
        var s = Santuario(bioma: bioma, nome: nome(de: bioma))
        var rng = SeededRandom(seed: seed &* 31 &+ 7)
        let largura = 5, altura = 4

        // --- 1. Caminho principal: passeio que só anda para casa VIZINHA livre ---
        var ocupadas: Set<GridPoint> = []
        var caminho: [GridPoint] = []
        var atual = GridPoint(x: rng.int(0, largura - 1), y: 0)
        s.entrada = atual
        ocupadas.insert(atual)
        caminho.append(atual)

        while caminho.count < 9 {
            // Norte entra duas vezes na urna: o traçado sobe, mas serpenteia.
            var opcoes: [Direcao] = []
            for d in [Direcao.norte, .norte, .leste, .oeste] {
                let p = GridPoint(x: atual.x + d.passo.x, y: atual.y + d.passo.y)
                guard p.x >= 0, p.x < largura, p.y >= 0, p.y < altura,
                      !ocupadas.contains(p) else { continue }
                opcoes.append(d)
            }
            guard !opcoes.isEmpty else { break }
            let d = opcoes[rng.int(0, opcoes.count - 1)]
            let prox = GridPoint(x: atual.x + d.passo.x, y: atual.y + d.passo.y)
            ocupadas.insert(prox)
            caminho.append(prox)
            atual = prox
        }
        // Curto demais não cabe porta selada + porta do Guardião.
        guard caminho.count >= 7 else { return nil }
        s.chefe = caminho[caminho.count - 1]

        // --- 2. Liga o caminho: cada par consecutivo é vizinho por construção ---
        for (i, c) in caminho.enumerated() {
            var sala = s.salas[c] ?? Sala(coord: c)
            sala.profundidade = i
            if i > 0 {
                let ant = caminho[i - 1]
                let d = direcao(de: ant, para: c)
                s.salas[ant]?.portas[d] = .aberta
                sala.portas[d.oposta] = .aberta
            }
            s.salas[c] = sala
        }

        // --- 3. Ramos laterais, guardando de qual ponto do caminho saem ---
        var ramos: [(coord: GridPoint, base: Int)] = []
        // Nada de ramos saindo da sala do chefe: tudo que nascesse ali ficaria
        // atrás da porta que ainda nem foi aberta.
        for (i, base) in caminho.enumerated() where i > 0 && i < caminho.count - 1
                                                   && rng.chance(0.8) {
            for d in Direcao.allCases.shuffledBy(&rng) {
                let p = GridPoint(x: base.x + d.passo.x, y: base.y + d.passo.y)
                guard p.x >= 0, p.x < largura, p.y >= 0, p.y < altura,
                      !ocupadas.contains(p) else { continue }
                ocupadas.insert(p)
                var nova = Sala(coord: p)
                nova.profundidade = i
                nova.portas[d.oposta] = .aberta
                s.salas[p] = nova
                s.salas[base]?.portas[d] = .aberta
                ramos.append((p, i))
                break
            }
        }

        // --- 4. Conteúdo do caminho ---
        s.salas[s.entrada]?.conteudo = .entrada
        s.salas[s.chefe]?.conteudo = .chefe

        // O item fica no meio: sem ele não se passa da porta selada do chefe.
        let idxItem = max(1, caminho.count / 2)
        s.salaDoAmuleto = caminho[min(idxItem, caminho.count - 2)]
        s.salas[s.salaDoAmuleto]?.conteudo = .amuleto

        // Porta do chefe: só a Chave do Guardião abre.
        let antesDoChefe = caminho[caminho.count - 2]
        let dChefe = direcao(de: antesDoChefe, para: s.chefe)
        s.salas[antesDoChefe]?.portas[dChefe] = .doGuardiao
        s.salas[s.chefe]?.portas[dChefe.oposta] = .doGuardiao

        // E uma porta selada no meio do caminho, logo depois do item: é ela que
        // faz o amuleto valer como chave de mapa, e não só como poder.
        if idxItem + 1 <= caminho.count - 3 {
            let a = caminho[idxItem], b = caminho[idxItem + 1]
            let d = direcao(de: a, para: b)
            s.salas[a]?.portas[d] = .selada
            s.salas[b]?.portas[d.oposta] = .selada
        }

        // --- 5. Uma porta trancada, sempre DEPOIS de um ramo que tenha chave ---
        let idxCadeado = min(caminho.count - 3, max(2, idxItem + 1))
        let ramosAntes = ramos.filter { $0.base < idxCadeado }
        if idxCadeado >= 1, idxCadeado + 1 <= caminho.count - 2, let chaveRamo = ramosAntes.first {
            let a = caminho[idxCadeado], b = caminho[idxCadeado + 1]
            let d = direcao(de: a, para: b)
            s.salas[a]?.portas[d] = .trancada
            s.salas[b]?.portas[d.oposta] = .trancada
            s.salas[chaveRamo.coord]?.conteudo = .chave(rng.int(2, 4))
            s.totalChaves = 1
        }

        // --- 6. Tesouros de santuário: planta, bússola e Chave do Guardião ---
        var livres = ramos.filter {
            if case .chave = s.salas[$0.coord]?.conteudo ?? .vazia { return false }
            return true
        }.sorted { $0.base < $1.base }

        // Planta e bússola cedo — servem para orientar, não para travar. Se não
        // sobrar sala lateral, vão para o caminho principal: nenhum santuário
        // pode ficar sem elas.
        func colocar(_ t: Tesouro, indiceReserva: Int) {
            if let r = livres.first {
                s.salas[r.coord]?.conteudo = .bau(t)
                livres.removeFirst()
            } else if caminho.indices.contains(indiceReserva) {
                s.salas[caminho[indiceReserva]]?.conteudo = .bau(t)
            }
        }
        colocar(.mapa, indiceReserva: 1)
        colocar(.bussola, indiceReserva: 2)
        // A Chave do Guardião: no ramo mais profundo que ainda esteja DO LADO DE
        // CÁ da porta do chefe. Se não houver ramo servível, ela vai para a
        // última sala do caminho antes do chefe — nunca pode faltar.
        let limite = caminho.count - 2
        let candidatos = livres.filter { $0.base <= limite }
        if let g = candidatos.last(where: { $0.base > idxItem }) ?? candidatos.last {
            s.salas[g.coord]?.conteudo = .bau(.chaveDoGuardiao)
            s.salaDaChaveDoGuardiao = g.coord
            livres.removeAll { $0.coord == g.coord }
        } else {
            let sala = caminho[limite]
            s.salas[sala]?.conteudo = .bau(.chaveDoGuardiao)
            s.salaDaChaveDoGuardiao = sala
        }

        for r in livres {
            let sorte = rng.unit()
            if sorte < 0.40 {
                s.salas[r.coord]?.conteudo = .bau(rng.chance(0.5) ? .coracao
                                                                  : .essencia(rng.int(25, 45)))
            } else if sorte < 0.66 {
                s.salas[r.coord]?.conteudo = .puzzle
            } else {
                s.salas[r.coord]?.conteudo = .inimigos(rng.int(2, 4))
            }
        }
        for c in caminho {
            if case .vazia = s.salas[c]?.conteudo ?? .vazia {
                s.salas[c]?.conteudo = .inimigos(rng.int(1, 3))
            }
        }
        return s
    }

    private static func direcao(de a: GridPoint, para b: GridPoint) -> Direcao {
        if b.y > a.y { return .norte }
        if b.y < a.y { return .sul }
        if b.x > a.x { return .leste }
        return .oeste
    }
}

extension Array {
    /// Embaralhamento determinístico, para o santuário ser sempre o mesmo.
    func shuffledBy(_ rng: inout SeededRandom) -> [Element] {
        var a = self
        guard a.count > 1 else { return a }
        for i in stride(from: a.count - 1, to: 0, by: -1) {
            a.swapAt(i, rng.int(0, i))
        }
        return a
    }
}

/// Medidas de uma sala. Fixas, como nos Zelda antigos: a câmera enquadra uma
/// sala inteira e salta para a seguinte.
enum SalaMetrics {
    static let largura = 15      // tiles de piso
    static let altura = 11
    static let tile: CGFloat = 52
    /// Altura da face frontal da parede — é ela que dá o volume do 2.5D.
    static let faceParede: CGFloat = 78

    static var tamanho: CGSize {
        CGSize(width: CGFloat(largura) * tile, height: CGFloat(altura) * tile)
    }

    static func centro(_ c: GridPoint) -> CGPoint {
        CGPoint(x: CGFloat(c.x) * (tamanho.width + tile * 2),
                y: CGFloat(c.y) * (tamanho.height + tile * 2))
    }

    /// Posição de um tile de piso dentro da sala, em coordenadas de mundo.
    static func ponto(sala: GridPoint, tx: Int, ty: Int) -> CGPoint {
        let o = centro(sala)
        return CGPoint(x: o.x + (CGFloat(tx) - CGFloat(largura - 1) / 2) * tile,
                       y: o.y + (CGFloat(ty) - CGFloat(altura - 1) / 2) * tile)
    }
}
