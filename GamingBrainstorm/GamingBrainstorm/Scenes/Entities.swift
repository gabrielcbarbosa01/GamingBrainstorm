//
//  Entities.swift
//  Guardiões dos Biomas
//
//  Tudo com que o jogador interage no mundo. Cada entidade sabe dizer se
//  pode ser usada na forma atual — é isso que obriga a alternar entre bicho
//  e gente o tempo todo.
//

import SpriteKit

/// Resultado da checagem de interação: pode agir, e o que dizer se não puder.
struct Interacao {
    let pode: Bool
    let dica: String
}

class WorldEntity: SKNode {
    let tileMundo: GridPoint
    /// Distância em que o jogador percebe a entidade.
    var raioInteracao: CGFloat { 52 }
    /// Se true, some do mundo depois de usada.
    var consumivel: Bool { true }

    init(tile: GridPoint) {
        self.tileMundo = tile
        super.init()
        position = WorldMetrics.center(of: tile)
        zPosition = 100 + CGFloat(-tile.y) * 0.01
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) não usado") }

    func checar(estado: GameState) -> Interacao { Interacao(pode: true, dica: "") }

    /// Executa a interação. Retorna true se a entidade deve ser removida.
    @discardableResult
    func interagir(estado: GameState, cena: GameScene) -> Bool { false }

    /// Chamado a cada frame com a posição do jogador.
    func atualizar(delta: TimeInterval, jogador: CGPoint, estado: GameState, cena: GameScene) {}

    func pulsar() {
        run(.repeatForever(.sequence([
            .scale(to: 1.10, duration: 0.9),
            .scale(to: 0.95, duration: 0.9)
        ])))
    }
}

// MARK: - Ponto de missão

final class ObjetivoNode: WorldEntity {
    let kind: ObjectiveKind
    private let sprite: SKSpriteNode

    init(tile: GridPoint, kind: ObjectiveKind, bioma: BiomeID) {
        self.kind = kind
        self.sprite = SKSpriteNode(texture: Objects.objetivo(kind, bioma: bioma))
        super.init(tile: tile)
        addChild(sprite)
        pulsar()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) não usado") }

    /// Rastrear dá para fazer em qualquer forma; soltar bicho de armadilha,
    /// plantar muda ou desmontar uma frente de destruição exige mãos.
    override func checar(estado: GameState) -> Interacao {
        if kind == .rastro { return Interacao(pode: true, dica: "Registrar vestígio") }
        if estado.formaAtual == .humano {
            return Interacao(pode: true, dica: kind.verbo)
        }
        return Interacao(pode: false, dica: "Precisa de mãos — volte à forma humana (Q)")
    }

    override func interagir(estado: GameState, cena: GameScene) -> Bool {
        guard checar(estado: estado).pode else { return false }
        guard estado.registrarObjetivo(kind, em: cena.biomaID) else {
            estado.avisar("Isto não faz parte da tarefa atual.", icone: "questionmark.circle", cor: .neutro)
            return false
        }
        cena.efeitoConquista(em: position, cor: Biome[cena.biomaID].palette.accent)
        return true
    }
}

// MARK: - Essência

final class EssenciaNode: WorldEntity {
    override var raioInteracao: CGFloat { 34 }

    override init(tile: GridPoint) {
        super.init(tile: tile)
        let s = SKSpriteNode(texture: Objects.essencia())
        addChild(s)
        run(.repeatForever(.sequence([
            .moveBy(x: 0, y: 6, duration: 1.1),
            .moveBy(x: 0, y: -6, duration: 1.1)
        ])))
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) não usado") }

    /// Recolhida por contato, sem precisar apertar nada.
    func coletar(estado: GameState, cena: GameScene) {
        estado.ganharEssencia(30)
        estado.somarPontos(10)
        cena.efeitoConquista(em: position, cor: Palette.essence)
        removeFromParent()
    }
}

// MARK: - Ameaça

final class AmeacaNode: WorldEntity {
    private let kind: HazardKind
    private var direcao: CGVector
    private var velocidade: CGFloat
    private let origem: CGPoint
    private var perseguindo = false
    private var cooldown: TimeInterval = 0

    override var raioInteracao: CGFloat { 46 }
    override var consumivel: Bool { false }

    init(tile: GridPoint, kind: HazardKind, dificuldade: Int) {
        self.kind = kind
        var rng = Hashing.rng(tile.x, tile.y, 424242)
        let a = rng.double(0, .pi * 2)
        self.direcao = CGVector(dx: CGFloat(cos(a)), dy: CGFloat(sin(a)))
        self.velocidade = 62 + CGFloat(min(dificuldade, 12)) * 7
        self.origem = WorldMetrics.center(of: tile)
        super.init(tile: tile)
        let s = SKSpriteNode(texture: Objects.ameaca(kind))
        addChild(s)
        // O fogo pisca; máquinas e caçadores só andam.
        if kind == .queimada {
            s.run(.repeatForever(.sequence([
                .scaleX(to: 1.12, y: 0.94, duration: 0.35),
                .scaleX(to: 0.94, y: 1.12, duration: 0.35)
            ])))
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) não usado") }

    override func atualizar(delta: TimeInterval, jogador: CGPoint, estado: GameState, cena: GameScene) {
        cooldown = max(0, cooldown - delta)

        let dx = jogador.x - position.x, dy = jogador.y - position.y
        let dist = (dx * dx + dy * dy).squareRoot()
        let escondido = estado.formaAtual.invisivelParaAmeacas
        let raioDeteccao: CGFloat = 300

        if dist < raioDeteccao && !escondido {
            if !perseguindo {
                perseguindo = true
                cena.alertaAmeaca(kind)
            }
            direcao = CGVector(dx: dx / max(dist, 1), dy: dy / max(dist, 1))
        } else {
            perseguindo = false
            // Vagueia perto do ponto de origem.
            let ox = origem.x - position.x, oy = origem.y - position.y
            let dOrigem = (ox * ox + oy * oy).squareRoot()
            if dOrigem > 340 {
                direcao = CGVector(dx: ox / dOrigem, dy: oy / dOrigem)
            }
        }

        let passo = velocidade * CGFloat(delta) * (perseguindo ? 1.35 : 0.7)
        let alvo = CGPoint(x: position.x + direcao.dx * passo, y: position.y + direcao.dy * passo)
        if cena.terrenoLivreParaAmeaca(alvo) {
            position = alvo
        } else {
            // Bate e escolhe outro rumo.
            var rng = SeededRandom(seed: UInt64(abs(Int(position.x + position.y))) &+ 17)
            let a = rng.double(0, .pi * 2)
            direcao = CGVector(dx: CGFloat(cos(a)), dy: CGFloat(sin(a)))
        }

        // Contato: o jogador é afugentado.
        if dist < 40 && cooldown == 0 && !escondido {
            cooldown = 3.0
            cena.jogadorAfugentado(por: kind)
        }
    }
}

// MARK: - Segredo

final class SegredoNode: WorldEntity {
    private var revelado = false
    private let sprite: SKSpriteNode

    override init(tile: GridPoint) {
        sprite = SKSpriteNode(texture: Objects.segredo(revelado: false))
        super.init(tile: tile)
        addChild(sprite)
        alpha = 0.35
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) não usado") }

    override func atualizar(delta: TimeInterval, jogador: CGPoint, estado: GameState, cena: GameScene) {
        guard !revelado else { return }
        // A torre de observação do Refúgio revela caches mesmo sem o faro do lobo.
        let raio = max(estado.formaAtual.raioFaro, estado.faroPassivo)
        guard raio > 0 else { return }
        let dx = jogador.x - position.x, dy = jogador.y - position.y
        if (dx * dx + dy * dy).squareRoot() < raio {
            revelado = true
            sprite.texture = Objects.segredo(revelado: true)
            run(.fadeIn(withDuration: 0.4))
            pulsar()
            estado.avisar("O faro encontrou algo enterrado por aqui.", icone: "nose.fill", cor: .bom)
        }
    }

    override func checar(estado: GameState) -> Interacao {
        if !revelado { return Interacao(pode: false, dica: "Algo estranho no chão…") }
        if estado.formaAtual == .humano || estado.formaAtual == .tucoTuco {
            return Interacao(pode: true, dica: "Desenterrar")
        }
        return Interacao(pode: false, dica: "Só mãos ou garras escavam isto")
    }

    override func interagir(estado: GameState, cena: GameScene) -> Bool {
        guard checar(estado: estado).pode else { return false }
        estado.ganharEssencia(45)
        estado.somarPontos(220)
        estado.descobrirCodex("amuletos")
        estado.avisar("Cache de campo recuperado: +220 pontos, +45 essência.",
                      icone: "shippingbox.fill", cor: .conquista)
        cena.efeitoConquista(em: position, cor: Palette.gold)
        return true
    }
}

// MARK: - Portal

final class PortalNode: WorldEntity {
    let destino: BiomeID
    override var raioInteracao: CGFloat { 78 }
    override var consumivel: Bool { false }

    init(tile: GridPoint, destino: BiomeID) {
        self.destino = destino
        super.init(tile: tile)
        let s = SKSpriteNode(texture: Objects.portal(destino))
        s.anchorPoint = CGPoint(x: 0.5, y: 0.25)
        addChild(s)

        let rotulo = SKLabelNode(text: Biome[destino].nome)
        rotulo.fontName = "Avenir Next Demi Bold"
        rotulo.fontSize = 16
        rotulo.fontColor = Palette.parchment
        rotulo.position = CGPoint(x: 0, y: 118)
        rotulo.zPosition = 5
        addChild(rotulo)
        zPosition = 90
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) não usado") }

    override func checar(estado: GameState) -> Interacao {
        if estado.podeEntrar(destino) {
            return Interacao(pode: true, dica: "Viajar para \(Biome[destino].nome)")
        }
        let req = Biome[destino].requisito!
        return Interacao(pode: false, dica: "Selado — exige o \(req.amuleto)")
    }

    override func interagir(estado: GameState, cena: GameScene) -> Bool {
        guard checar(estado: estado).pode else {
            estado.avisar(checar(estado: estado).dica, icone: "lock.fill", cor: .alerta)
            return false
        }
        estado.viajar(para: destino)
        return false
    }
}

/// Largada da prova, encontrada dentro do próprio bioma.
final class LargadaNode: WorldEntity {
    private let bioma: BiomeID
    override var consumivel: Bool { false }
    override var raioInteracao: CGFloat { 72 }

    init(tile: GridPoint, bioma: BiomeID) {
        self.bioma = bioma
        super.init(tile: tile)
        addChild(SKSpriteNode(texture: Objects.objetivo(.corrida, bioma: bioma)))
        pulsar()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) não usado") }

    override func checar(estado: GameState) -> Interacao {
        guard let c = Corrida[bioma] else { return Interacao(pode: false, dica: "") }
        guard estado.temAmuleto(c.forma) else {
            return Interacao(pode: false, dica: "A prova exige o \(c.forma.amuleto)")
        }
        return Interacao(pode: true, dica: "Largada: \(c.titulo)")
    }

    override func interagir(estado: GameState, cena: GameScene) -> Bool {
        estado.iniciarCorrida(bioma)
        return false
    }
}

// MARK: - Portal de volta ao Refúgio

final class PortalRetornoNode: WorldEntity {
    override var raioInteracao: CGFloat { 78 }
    override var consumivel: Bool { false }

    override init(tile: GridPoint) {
        super.init(tile: tile)
        let s = SKSpriteNode(texture: Objects.portal(.refugio))
        s.anchorPoint = CGPoint(x: 0.5, y: 0.25)
        addChild(s)
        let rotulo = SKLabelNode(text: "Voltar ao Refúgio")
        rotulo.fontName = "Avenir Next Demi Bold"
        rotulo.fontSize = 16
        rotulo.fontColor = Palette.parchment
        rotulo.position = CGPoint(x: 0, y: 118)
        addChild(rotulo)
        zPosition = 90
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) não usado") }

    override func checar(estado: GameState) -> Interacao {
        Interacao(pode: true, dica: "Voltar ao Refúgio Raízes")
    }

    override func interagir(estado: GameState, cena: GameScene) -> Bool {
        estado.viajar(para: .refugio)
        return false
    }
}

// MARK: - Placa

final class PlacaNode: WorldEntity {
    private let texto: String
    override var consumivel: Bool { false }

    init(tile: GridPoint, texto: String) {
        self.texto = texto
        super.init(tile: tile)
        addChild(SKSpriteNode(texture: Objects.placa()))
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) não usado") }

    override func checar(estado: GameState) -> Interacao { Interacao(pode: true, dica: "Ler") }

    override func interagir(estado: GameState, cena: GameScene) -> Bool {
        estado.avisar(texto, icone: "text.book.closed.fill", cor: .neutro)
        return false
    }
}

// MARK: - NPC

final class NPCNode: WorldEntity {
    let chave: String
    override var consumivel: Bool { false }
    override var raioInteracao: CGFloat { 64 }

    init(tile: GridPoint, chave: String) {
        self.chave = chave
        super.init(tile: tile)
        let s = SKSpriteNode(texture: Creatures.npcTexture(chave))
        addChild(s)
        // Respiração leve, para o NPC não parecer estátua.
        s.run(.repeatForever(.sequence([
            .scaleY(to: 1.02, duration: 1.4),
            .scaleY(to: 0.99, duration: 1.4)
        ])))
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) não usado") }

    override func checar(estado: GameState) -> Interacao {
        if estado.formaAtual == .humano { return Interacao(pode: true, dica: "Conversar") }
        return Interacao(pode: false, dica: "Bicho não conversa com gente — volte a ser você (Q)")
    }

    override func interagir(estado: GameState, cena: GameScene) -> Bool {
        guard checar(estado: estado).pode else { return false }
        switch chave {
        case "iara": estado.iniciarDialogo(DialogueBook.iara(estado), contexto: .refugio)
        case "teo": estado.iniciarDialogo(DialogueBook.teo(estado), contexto: .refugio)
        default: break
        }
        return false
    }
}

// MARK: - Viveiro do Refúgio

final class CanteiroNode: WorldEntity {
    let indice: Int
    private let sprite: SKSpriteNode
    private var etapaDesenhada = -1
    override var consumivel: Bool { false }
    override var raioInteracao: CGFloat { 48 }

    init(tile: GridPoint, indice: Int) {
        self.indice = indice
        self.sprite = SKSpriteNode(texture: Objects.canteiro(3))
        super.init(tile: tile)
        addChild(sprite)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) não usado") }

    private func etapa(_ estado: GameState) -> Int {
        guard indice < estado.canteirosDisponiveis,
              estado.save.refugio.canteiros.indices.contains(indice) else { return 3 }
        let c = estado.save.refugio.canteiros[indice]
        guard c.especie != nil else { return 0 }
        return c.pronto(agora: estado.save.tempoJogado) ? 2 : 1
    }

    override func atualizar(delta: TimeInterval, jogador: CGPoint,
                            estado: GameState, cena: GameScene) {
        let e = etapa(estado)
        guard e != etapaDesenhada else { return }
        etapaDesenhada = e
        sprite.texture = Objects.canteiro(e)
        removeAction(forKey: "pronto")
        if e == 2 {
            // Muda pronta: um leve pulsar para o jogador notar de longe.
            run(.repeatForever(.sequence([
                .scale(to: 1.06, duration: 0.8),
                .scale(to: 0.98, duration: 0.8)
            ])), withKey: "pronto")
        } else {
            setScale(1)
        }
    }

    override func checar(estado: GameState) -> Interacao {
        guard indice < estado.canteirosDisponiveis else {
            return Interacao(pode: false, dica: "Canteiro por abrir — amplie o viveiro na oficina")
        }
        guard estado.formaAtual == .humano else {
            return Interacao(pode: false, dica: "Só de mãos se planta e se colhe (Q)")
        }
        switch etapa(estado) {
        case 0: return Interacao(pode: true, dica: "Plantar")
        case 1:
            let c = estado.save.refugio.canteiros[indice]
            let pct = Int(c.progresso(agora: estado.save.tempoJogado) * 100)
            let nome = Especie.porId(c.especie ?? "")?.nome ?? "muda"
            return Interacao(pode: false, dica: "\(nome) crescendo — \(pct)%")
        default: return Interacao(pode: true, dica: "Colher")
        }
    }

    override func interagir(estado: GameState, cena: GameScene) -> Bool {
        switch etapa(estado) {
        case 0: estado.painelRefugio = .viveiro(canteiro: indice)
        case 2:
            estado.colher(canteiro: indice)
            cena.efeitoConquista(em: position, cor: SKColor(hex: 0x6EA44C))
        default: break
        }
        return false
    }
}

// MARK: - Cais de pesca

final class PescaNode: WorldEntity {
    override var consumivel: Bool { false }
    override var raioInteracao: CGFloat { 62 }

    override init(tile: GridPoint) {
        super.init(tile: tile)
        let s = SKSpriteNode(texture: Objects.cais())
        addChild(s)
        // Reflexo na água, para o cais não parecer colado
        let brilho = SKSpriteNode(texture: Objects.essencia())
        brilho.position = CGPoint(x: 26, y: -18)
        brilho.alpha = 0.35
        brilho.setScale(0.5)
        addChild(brilho)
        brilho.run(.repeatForever(.sequence([
            .fadeAlpha(to: 0.12, duration: 1.4),
            .fadeAlpha(to: 0.40, duration: 1.4)
        ])))
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) não usado") }

    override func checar(estado: GameState) -> Interacao {
        estado.formaAtual == .humano
            ? Interacao(pode: true, dica: "Pescar no açude")
            : Interacao(pode: false, dica: "Bicho não segura vara — volte à forma humana (Q)")
    }

    override func interagir(estado: GameState, cena: GameScene) -> Bool {
        estado.iniciarPesca()
        return false
    }
}

// MARK: - Oficina

final class OficinaNode: WorldEntity {
    override var consumivel: Bool { false }
    override var raioInteracao: CGFloat { 62 }

    override init(tile: GridPoint) {
        super.init(tile: tile)
        addChild(SKSpriteNode(texture: Objects.oficina()))
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) não usado") }

    override func checar(estado: GameState) -> Interacao {
        estado.formaAtual == .humano
            ? Interacao(pode: true, dica: "Oficina de campo")
            : Interacao(pode: false, dica: "Ferramenta pede mão humana (Q)")
    }

    override func interagir(estado: GameState, cena: GameScene) -> Bool {
        estado.painelRefugio = .oficina
        return false
    }
}

// MARK: - A Harpia

final class HarpiaNode: WorldEntity {
    private let sprite: SKSpriteNode
    private var visivel = false
    override var consumivel: Bool { false }
    override var raioInteracao: CGFloat { 78 }

    override init(tile: GridPoint) {
        sprite = SKSpriteNode(texture: Creatures.npcTexture("harpia"))
        sprite.size = CGSize(width: Creatures.canvas * 1.5, height: Creatures.canvas * 1.5)
        super.init(tile: tile)
        // Galho seco onde ela pousa.
        let poleiro = SKSpriteNode(texture: Objects.placa())
        poleiro.alpha = 0
        addChild(poleiro)
        addChild(sprite)
        alpha = 0
        zPosition = 200
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) não usado") }

    override func atualizar(delta: TimeInterval, jogador: CGPoint,
                            estado: GameState, cena: GameScene) {
        // Ela só reaparece quando os cinco amuletos já estão com o jogador.
        let deveAparecer = estado.save.amuletos.count >= 5
        guard deveAparecer != visivel else { return }
        visivel = deveAparecer
        if deveAparecer {
            run(.fadeIn(withDuration: 1.2))
            sprite.run(.repeatForever(.sequence([
                .moveBy(x: 0, y: 5, duration: 1.6),
                .moveBy(x: 0, y: -5, duration: 1.6)
            ])))
            estado.avisar("Algo enorme pousou ao sul do Refúgio.",
                          icone: "eye.fill", cor: .conquista)
        } else {
            alpha = 0
        }
    }

    override func checar(estado: GameState) -> Interacao {
        guard visivel else { return Interacao(pode: false, dica: "") }
        if estado.save.amuletos.contains(.harpia) {
            return Interacao(pode: true, dica: "Falar com a Harpia")
        }
        return Interacao(pode: true, dica: estado.harpiaLiberada
                         ? "A Harpia espera por você"
                         : "A Harpia observa — ver o que ela exige")
    }

    override func interagir(estado: GameState, cena: GameScene) -> Bool {
        guard visivel else { return false }
        if estado.harpiaLiberada && !estado.save.amuletos.contains(.harpia) {
            estado.iniciarDialogo(DialogueBook.harpiaFinal(), contexto: .refugio)
        } else {
            estado.painelRefugio = .harpia
        }
        return false
    }
}

// MARK: - A pena da Harpia

/// Fica no chão depois do sobrevoo de abertura. Pegá-la é o que dá a partida.
final class PenaNode: WorldEntity {
    override var consumivel: Bool { true }
    override var raioInteracao: CGFloat { 64 }

    override init(tile: GridPoint) {
        super.init(tile: tile)
        let s = SKSpriteNode(texture: Objects.pena())
        addChild(s)
        zPosition = 250
        // Balanço leve, como pena assentando.
        s.run(.repeatForever(.sequence([
            .group([.rotate(byAngle: 0.10, duration: 1.3), .moveBy(x: 3, y: 4, duration: 1.3)]),
            .group([.rotate(byAngle: -0.10, duration: 1.3), .moveBy(x: -3, y: -4, duration: 1.3)])
        ])))
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) não usado") }

    override func checar(estado: GameState) -> Interacao {
        Interacao(pode: true, dica: "Pegar a pena")
    }

    override func interagir(estado: GameState, cena: GameScene) -> Bool {
        estado.ligarFlag("harpia_conheceu")
        estado.descobrirCodex("harpia")
        estado.iniciarDialogo(DialogueBook.penaDaHarpia(), contexto: .refugio)
        cena.efeitoConquista(em: position, cor: Palette.gold)
        return true
    }
}
