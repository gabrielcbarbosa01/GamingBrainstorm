//
//  Operacao.swift
//  Guardiões dos Biomas
//
//  A frente avança, o relógio corre, e os focos de vida que ficam atrás dela
//  se perdem. O jogo é escolher a rota — não dá para salvar todos.
//

import SpriteKit

// MARK: - Foco de vida

final class FocoNode: WorldEntity {

    enum Estado { case aguardando, escoltando, salvo, perdido }

    let movel: Bool
    private(set) var estadoFoco: Estado = .aguardando
    private let config: Operacao
    private let sprite: SKSpriteNode
    private let barra = SKSpriteNode(color: Palette.essence, size: CGSize(width: 46, height: 5))
    private let barraFundo = SKSpriteNode(color: SKColor(white: 0, alpha: 0.5),
                                          size: CGSize(width: 46, height: 5))
    private var progresso: CGFloat = 0
    private var rastro: [CGPoint] = []

    override var consumivel: Bool { false }
    override var raioInteracao: CGFloat { 70 }

    init(tile: GridPoint, config: Operacao, movel: Bool) {
        self.config = config
        self.movel = movel
        let animal = Biome[config.bioma].animal
        self.sprite = SKSpriteNode(texture: Creatures.quadros(animal, .parado)[0])
        super.init(tile: tile)

        sprite.size = CGSize(width: 54, height: 54)
        addChild(sprite)
        // Grupos em fuga levam companhia; ninhos ficam parados.
        if movel {
            for i in 0..<2 {
                let f = SKSpriteNode(texture: Creatures.quadros(animal, .parado)[0])
                f.size = CGSize(width: 38, height: 38)
                f.position = CGPoint(x: CGFloat(i * 2 - 1) * 22, y: -10)
                f.alpha = 0.9
                addChild(f)
            }
        }

        barraFundo.position = CGPoint(x: 0, y: 40)
        barra.position = CGPoint(x: -23, y: 40)
        barra.anchorPoint = CGPoint(x: 0, y: 0.5)
        barra.xScale = 0.001
        addChild(barraFundo); addChild(barra)
        barraFundo.isHidden = true; barra.isHidden = true

        // Halo para achar de longe.
        let halo = SKSpriteNode(texture: Objects.essencia())
        halo.color = Biome[config.bioma].palette.accent
        halo.colorBlendFactor = 0.9
        halo.setScale(2.4)
        halo.alpha = 0.30
        halo.zPosition = -1
        addChild(halo)
        halo.run(.repeatForever(.sequence([
            .group([.scale(to: 3.2, duration: 1.1), .fadeAlpha(to: 0.10, duration: 1.1)]),
            .group([.scale(to: 2.4, duration: 0.01), .fadeAlpha(to: 0.30, duration: 0.01)])
        ])))
        zPosition = 300
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) não usado") }

    // MARK: Interação

    override func checar(estado: GameState) -> Interacao {
        switch estadoFoco {
        case .salvo, .perdido: return Interacao(pode: false, dica: "")
        case .escoltando:
            return Interacao(pode: false, dica: "Leve o grupo até a borda sul")
        case .aguardando:
            if let f = config.formaResgate, estado.formaAtual != f {
                return Interacao(pode: false,
                                 dica: f == .humano ? "Precisa de mãos — volte à forma humana (Q)"
                                                    : "Exige a forma de \(f.nome)")
            }
            return Interacao(pode: false, dica: "Segure E · \(config.verbo)")
        }
    }

    // MARK: Ciclo

    func avancar(delta: TimeInterval, jogador: CGPoint, yFrente: CGFloat,
                 estado: GameState, cena: GameScene) -> Estado {
        guard estadoFoco != .salvo, estadoFoco != .perdido else { return estadoFoco }

        // A frente alcançou este ponto.
        if position.y >= yFrente {
            perder(cena: cena)
            return .perdido
        }

        let dist = hypot(jogador.x - position.x, jogador.y - position.y)

        switch estadoFoco {
        case .aguardando:
            // Grupo em fuga recua — mas mais devagar que a máquina. Bicho corre;
            // a linha não cansa. Se fugisse mais rápido, se salvaria sozinho e
            // não haveria decisão nenhuma a tomar.
            if movel {
                let piso = -CGFloat(Territorio.raioTiles - 2) * WorldMetrics.tileSize
                position.y = max(piso, position.y - 7 * CGFloat(delta))
            }

            let formaOK = config.formaResgate == nil || estado.formaAtual == config.formaResgate
            let segurando = InputManager.shared.interagirSegurado
            if dist < raioInteracao && formaOK && segurando {
                progresso += CGFloat(delta) / CGFloat(config.tempoResgate)
                barraFundo.isHidden = false; barra.isHidden = false
                barra.xScale = max(0.001, min(1, progresso))
                if progresso >= 1 {
                    if movel {
                        estadoFoco = .escoltando
                        rastro = [jogador]
                        barraFundo.isHidden = true; barra.isHidden = true
                        estado.avisar("O grupo confia em você. Leve-os para o sul, longe da linha.",
                                      icone: "figure.walk.motion", cor: .bom)
                    } else {
                        salvar(estado: estado, cena: cena)
                        return .salvo
                    }
                }
            } else if progresso > 0 {
                progresso = max(0, progresso - CGFloat(delta) * 0.6)
                barra.xScale = max(0.001, progresso)
                if progresso <= 0 { barraFundo.isHidden = true; barra.isHidden = true }
            }

        case .escoltando:
            // Segue o rastro do jogador, com atraso.
            rastro.append(jogador)
            if rastro.count > 90 { rastro.removeFirst(rastro.count - 90) }
            let alvo = rastro[max(0, rastro.count - 40)]
            let dx = alvo.x - position.x, dy = alvo.y - position.y
            let d = hypot(dx, dy)
            if d > 6 {
                let v = min(CGFloat(delta) * 230, d)
                position = CGPoint(x: position.x + dx / d * v, y: position.y + dy / d * v)
            }
            // Chegou à faixa segura ao sul.
            if position.y < -CGFloat(Territorio.raioTiles - 4) * WorldMetrics.tileSize {
                salvar(estado: estado, cena: cena)
                return .salvo
            }

        default: break
        }
        return estadoFoco
    }

    private func salvar(estado: GameState, cena: GameScene) {
        estadoFoco = .salvo
        estado.somarPontos(180)
        cena.efeitoConquista(em: position, cor: Biome[config.bioma].palette.accent)
        // Somem correndo para o sul.
        run(.sequence([
            .group([.moveBy(x: 0, y: -260, duration: 1.1), .fadeOut(withDuration: 1.1)]),
            .removeFromParent()
        ]))
    }

    private func perder(cena: GameScene) {
        estadoFoco = .perdido
        barraFundo.isHidden = true; barra.isHidden = true
        sprite.colorBlendFactor = 0.85
        sprite.color = SKColor(hex: 0x2A2018)
        run(.sequence([.fadeAlpha(to: 0.25, duration: 0.5),
                       .wait(forDuration: 0.6),
                       .fadeOut(withDuration: 0.8),
                       .removeFromParent()]))
    }
}

// MARK: - A frente

@MainActor
final class OperacaoDirector {

    private let config: Operacao
    private var focos: [FocoNode] = []
    private let frenteNo = SKNode()
    private let consumido = SKSpriteNode()
    private var yFrente: CGFloat
    private var decorrido: TimeInterval = 0
    private let velocidade: CGFloat
    /// Multiplicador de dificuldade das expedições repetidas.
    private let ritmo: CGFloat
    private var encerrada = false
    private var avisoBorda: TimeInterval = 0

    init(config: Operacao, ritmo: CGFloat) {
        self.config = config
        self.ritmo = ritmo
        self.yFrente = Territorio.yFrenteInicial
        let percurso = Territorio.yFrenteInicial - Territorio.yFrenteFinal
        self.velocidade = percurso / CGFloat(config.duracao) * ritmo
    }

    // MARK: Montagem

    func montar(cena: GameScene, estado: GameState) {
        // A faixa já destruída, atrás da linha.
        consumido.color = SKColor(hex: 0x1A1410, alpha: 0.72)
        consumido.size = CGSize(width: Territorio.largura + 800, height: 4000)
        consumido.anchorPoint = CGPoint(x: 0.5, y: 0)
        consumido.position = CGPoint(x: 0, y: yFrente)
        consumido.zPosition = 400
        cena.adicionarAuxiliar(consumido)

        // A linha em si: uma fileira de máquinas/chamas atravessando o território.
        let passo: CGFloat = 190
        let n = Int(Territorio.largura / passo) + 3
        for i in 0..<n {
            let s = SKSpriteNode(texture: Objects.ameaca(config.ameaca))
            s.position = CGPoint(x: -Territorio.largura / 2 + CGFloat(i) * passo, y: 0)
            s.setScale(1.15)
            frenteNo.addChild(s)
            s.run(.repeatForever(.sequence([
                .scaleX(to: 1.24, y: 1.06, duration: 0.3 + Double(i % 4) * 0.05),
                .scaleX(to: 1.06, y: 1.24, duration: 0.3 + Double(i % 4) * 0.05)
            ])))
        }
        frenteNo.position = CGPoint(x: 0, y: yFrente)
        frenteNo.zPosition = 410
        cena.adicionarAuxiliar(frenteNo)

        // Focos espalhados em faixas: os do norte caem primeiro.
        var rng = SeededRandom(seed: Biome[config.bioma].semente
                               &+ UInt64(estado.save.biome(config.bioma).expedicoesConcluidas))
        let alcancaveis = cena.tilesAlcancaveis(limite: 4000)
        let dentro = alcancaveis.filter {
            Territorio.dentro(WorldMetrics.center(of: $0))
                && WorldMetrics.center(of: $0).y < Territorio.yFrenteInicial - 200
        }
        guard !dentro.isEmpty else { return }

        for i in 0..<config.quantidade {
            // Distribui do sul para o norte, para haver sempre algo mais arriscado.
            let faixa = CGFloat(i) / CGFloat(max(1, config.quantidade - 1))
            let yAlvo = -CGFloat(Territorio.raioTiles - 8) * WorldMetrics.tileSize
                + faixa * CGFloat(Territorio.raioTiles * 2 - 12) * WorldMetrics.tileSize
            let candidatos = dentro.filter {
                abs(WorldMetrics.center(of: $0).y - yAlvo) < 220
            }
            let tile = candidatos.isEmpty
                ? dentro[rng.int(0, dentro.count - 1)]
                : candidatos[rng.int(0, candidatos.count - 1)]

            // Um terço são grupos em fuga: têm de ser escoltados até o sul.
            let movel = rng.chance(0.34)
            let f = FocoNode(tile: tile, config: config, movel: movel)
            cena.adicionarAuxiliar(f)
            focos.append(f)
        }

        var sessao = OperacaoSessao(config: config)
        sessao.restantes = focos.count
        estado.operacao = sessao
        estado.avisar("\(config.frente) avançando pelo norte. \(focos.count) \(config.focoPlural) no caminho.",
                      icone: config.ameaca.icone, cor: .alerta)
    }

    // MARK: Passo

    func atualizar(delta: TimeInterval, jogador: CGPoint, estado: GameState, cena: GameScene) {
        guard !encerrada else { return }
        decorrido += delta
        yFrente -= velocidade * CGFloat(delta)
        frenteNo.position.y = yFrente
        consumido.position.y = yFrente

        var salvos = 0, perdidos = 0, restantes = 0
        var escoltando = false
        for f in focos {
            let e = f.avancar(delta: delta, jogador: jogador, yFrente: yFrente,
                              estado: estado, cena: cena)
            switch e {
            case .salvo: salvos += 1
            case .perdido: perdidos += 1
            case .escoltando: restantes += 1; escoltando = true
            case .aguardando: restantes += 1
            }
        }

        // Ficar atrás da linha custa caro.
        if jogador.y > yFrente - 40 {
            estado.essencia = max(0, estado.essencia - CGFloat(delta) * 30)
            let agora = CACurrentMediaTime()
            if agora - avisoBorda > 3 {
                avisoBorda = agora
                estado.avisar("Você está dentro da frente. Saia para o sul.",
                              icone: "exclamationmark.triangle.fill", cor: .alerta)
            }
        }

        estado.operacao?.salvos = salvos
        estado.operacao?.perdidos = perdidos
        estado.operacao?.restantes = restantes
        estado.operacao?.tempoRestante = max(0, Double(yFrente - Territorio.yFrenteFinal)
                                             / Double(velocidade))
        estado.operacao?.proximidadeDaFrente =
            max(0, min(1, (yFrente - jogador.y) / (Territorio.largura * 0.5)))
        _ = escoltando

        if yFrente <= Territorio.yFrenteFinal || restantes == 0 {
            encerrar(estado: estado)
        }
    }

    private func encerrar(estado: GameState) {
        encerrada = true
        estado.operacao?.encerrada = true
        frenteNo.run(.fadeOut(withDuration: 1.2))
        consumido.run(.fadeAlpha(to: 0.45, duration: 1.2))
        estado.concluirOperacao()
    }

    func desmontar() {
        focos.forEach { $0.removeFromParent() }
        focos.removeAll()
        frenteNo.removeFromParent()
        consumido.removeFromParent()
    }
}
