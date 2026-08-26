//
//  GameScene.swift
//  Guardiões dos Biomas
//
//  A cena de jogo. Faz streaming de chunks em volta do jogador (o mundo é
//  infinito), resolve colisão contra a grade de tiles conforme a forma atual,
//  move as ameaças e cuida das interações.
//

import SpriteKit

final class GameScene: SKScene {

    // MARK: Estado

    private(set) var biomaID: BiomeID = .refugio
    private var biome: Biome { Biome[biomaID] }
    private var gerador: WorldGenerator!
    weak var estado: GameState?

    private struct ChunkCarregado {
        let dados: ChunkData
        let terreno: SKSpriteNode
        var entidades: [WorldEntity]
    }

    private var chunks: [GridPoint: ChunkCarregado] = [:]
    private var filaGeracao: [GridPoint] = []

    private let mundo = SKNode()
    private let camadaTerreno = SKNode()
    private let camadaEntidades = SKNode()
    private let jogador = PlayerNode()
    private let cam = SKCameraNode()

    private var ultimoUpdate: TimeInterval = 0
    private var formaDesenhada: AnimalForm = .humano
    private var pendentes: [ObjectiveKind] = []
    private var ultimoAvisoBloqueio: TimeInterval = 0
    private var ultimoAvisoAmeaca: TimeInterval = 0
    private var recargaInvestida: TimeInterval = 0
    /// Tiles modificados em tempo de jogo (aceiros abertos, chão queimado).
    private var alteracoes: [GridPoint: Terrain] = [:]
    private var marcasDeTerreno: [GridPoint: SKNode] = [:]
    private let escuridao = SKSpriteNode()
    private var operacao: OperacaoDirector?
    private var avisoVerbo: TimeInterval = 0
    private var tempoAndando: TimeInterval = 0
    private var tempoPublicacao: TimeInterval = 0
    private var entidadeFoco: WorldEntity?

    /// Raio de chunks mantidos carregados em volta do jogador.
    private let raioCarga = 2
    private let raioDescarga = 4

    // MARK: Ciclo de vida

    /// A cena é reapresentada toda vez que o jogador volta de uma corrida.
    /// Sem esta trava, didMove tentava adicionar de novo nós que já têm pai —
    /// e o SpriteKit levanta NSInvalidArgumentException, derrubando o app.
    private var montado = false

    override func didMove(to view: SKView) {
        InputManager.shared.start()
        guard !montado else {
            InputManager.shared.limparTeclas()
            return
        }
        montado = true

        scaleMode = .resizeFill
        addChild(mundo)
        mundo.addChild(camadaTerreno)
        mundo.addChild(camadaEntidades)
        camadaTerreno.zPosition = -100
        camadaEntidades.zPosition = 0

        mundo.addChild(jogador)

        escuridao.texture = Self.texturaEscuridao
        escuridao.size = CGSize(width: 2600, height: 2600)
        escuridao.zPosition = 800
        escuridao.alpha = 0
        cam.addChild(escuridao)

        addChild(cam)
        camera = cam
        InputManager.shared.start()
        configurar(bioma: estado?.biomaCarregado ?? .refugio)
    }

    override func willMove(from view: SKView) {
        InputManager.shared.limparTeclas()
    }

    /// (Re)constrói o mundo para um bioma. Chamado na entrada e a cada viagem.
    func configurar(bioma id: BiomeID) {
        biomaID = id
        let nivel = estado?.save.biome(id).nivelExpedicao ?? 1
        gerador = WorldGenerator(biome: Biome[id], dificuldade: nivel)
        backgroundColor = Biome[id].palette.sky

        for (_, c) in chunks {
            c.terreno.removeFromParent()
            c.entidades.forEach { $0.removeFromParent() }
        }
        chunks.removeAll()
        filaGeracao.removeAll()
        alteracoes.removeAll()
        marcasDeTerreno.values.forEach { $0.removeFromParent() }
        marcasDeTerreno.removeAll()

        // Nos biomas o jogador chega na borda segura do território; no Refúgio,
        // no centro da praça.
        jogador.position = id == .refugio ? WorldMetrics.center(of: GridPoint(x: 0, y: 0))
                                          : Territorio.chegada
        pendentes = estado?.objetivosPendentes(id) ?? []

        // Monta a frente do bioma, se ainda há operação a fazer aqui.
        operacao?.desmontar()
        operacao = nil
        estado?.operacao = nil
        atualizarStreaming(imediato: false)
        gerarChunksPendentes(orcamento: 9)
        jogador.aplicarForma(estado?.formaAtual ?? .humano, forcar: true)
        formaDesenhada = estado?.formaAtual ?? .humano
        cam.position = jogador.position

        if let estado, id != .refugio, let cfg = Operacao[id],
           pendentes.contains(.acesso) || pendentes.contains(.desafio) || estado.ato(id) == .livre {
            let d = OperacaoDirector(config: cfg, ritmo: estado.ritmoDaFrente(id))
            d.montar(cena: self, estado: estado)
            operacao = d
        }
    }

    // MARK: Loop

    override func update(_ currentTime: TimeInterval) {
        guard let estado else { return }
        let delta = ultimoUpdate == 0 ? 1.0 / 60.0 : min(currentTime - ultimoUpdate, 1.0 / 20.0)
        ultimoUpdate = currentTime

        // Uma troca de bioma pedida pela UI recarrega tudo.
        if estado.biomaCarregado != biomaID {
            configurar(bioma: estado.biomaCarregado)
            return
        }

        processarAcoes(estado)

        // Com diálogo aberto o mundo congela: a conversa é a cena.
        let balanco = estado.operacao?.encerrada ?? false
        guard estado.dialogo == nil, estado.pesca == nil, estado.corrida == nil,
              estado.painelRefugio == nil, !balanco, estado.tela == .jogo else {
            gerarChunksPendentes(orcamento: 1)
            return
        }

        estado.atualizar(delta: delta)
        atualizarJogador(delta: delta, estado: estado)
        atualizarSpriteJogador(forcar: false)
        atualizarEntidades(delta: delta, estado: estado)
        atualizarFoco(estado)
        atualizarStreaming(imediato: false)
        gerarChunksPendentes(orcamento: 1)
        atualizarCamera(delta: delta, estado: estado)
        verificarTrocaDeObjetivo(estado)
        verificarCinematicaDaHarpia(estado, delta: delta)
        operacao?.atualizar(delta: delta, jogador: jogador.position, estado: estado, cena: self)
        publicarHUD(delta: delta, estado: estado)
    }

    // MARK: Ações do teclado

    private func processarAcoes(_ estado: GameState) {
        for acao in InputManager.shared.consumirAcoes() {
            // A pesca fica com a tecla de ação enquanto o minigame roda.
            if estado.pesca != nil {
                switch acao {
                case .interagir, .habilidade: estado.confirmarPesca()
                case .menu: estado.encerrarPesca()
                default: break
                }
                continue
            }
            // Painel do Refúgio aberto: só ESC fecha.
            if estado.painelRefugio != nil {
                if case .menu = acao { estado.painelRefugio = nil }
                continue
            }
            // Diálogo aberto: ele fica com o teclado inteiro.
            if let sessao = estado.dialogo {
                switch acao {
                case .interagir, .habilidade:
                    if !sessao.mostrandoEscolhas { estado.avancarDialogo() }
                case .forma(let n):
                    // Nas encruzilhadas, 1..3 escolhem a resposta.
                    if sessao.mostrandoEscolhas, sessao.atual.escolhas.indices.contains(n - 1) {
                        estado.avancarDialogo(escolha: n - 1)
                    }
                default:
                    break
                }
                continue
            }

            switch acao {
            case .interagir:
                guard estado.tela == .jogo else { break }
                interagirComFoco(estado)

            case .habilidade:
                guard estado.tela == .jogo else { break }
                acionarVerbo(estado)

            case .jornal:
                if estado.tela == .jogo { estado.tela = .jornal }
                else if estado.tela == .jornal { estado.tela = .jogo }

            case .mapa:
                if estado.tela == .jogo { estado.tela = .mapa }
                else if estado.tela == .mapa { estado.tela = .jogo }

            case .menu:
                switch estado.tela {
                case .jogo:
                    estado.salvar()
                    estado.tela = .menu
                case .jornal, .mapa:
                    estado.tela = .jogo
                case .creditos:
                    estado.tela = .menu
                case .menu:
                    // Do título só se sai para uma partida que já existe.
                    if estado.temPartidaSalva { estado.tela = .jogo }
                }

            case .humano:
                guard estado.tela == .jogo else { break }
                estado.trocarForma(.humano)

            case .forma(let n):
                guard estado.tela == .jogo else { break }
                let ordem = AnimalForm.vestiveis
                if ordem.indices.contains(n - 1) { estado.trocarForma(ordem[n - 1]) }

            case .expedicao:
                guard estado.tela == .jogo, biomaID != .refugio else { break }
                estado.iniciarExpedicao(biomaID)
            }
        }
    }

    private func interagirComFoco(_ estado: GameState) {
        guard let alvo = entidadeFoco else { return }
        let check = alvo.checar(estado: estado)
        guard check.pode else {
            estado.avisar(check.dica, icone: "hand.raised.slash.fill", cor: .alerta)
            return
        }
        let remover = alvo.interagir(estado: estado, cena: self)
        if remover && alvo.consumivel {
            alvo.removeFromParent()
            for (coord, var c) in chunks where c.entidades.contains(where: { $0 === alvo }) {
                c.entidades.removeAll { $0 === alvo }
                chunks[coord] = c
            }
            entidadeFoco = nil
            estado.dicaInteracao = nil
        }
    }

    // MARK: Movimento, verbos e colisão

    private func atualizarJogador(delta: TimeInterval, estado: GameState) {
        recargaInvestida = max(0, recargaInvestida - delta)
        let dir = InputManager.shared.direcao
        let forma = estado.formaAtual

        manterVerbo(segurando: InputManager.shared.habilidadeSegurada,
                    forma: forma, estado: estado, delta: delta)

        jogador.aplicarForma(forma)
        let andando = dir.dx != 0 || dir.dy != 0
        jogador.simular(delta: delta, andando: andando)

        // Velocidade final: base da forma × terreno × estado do corpo.
        let tileAtual = terreno(em: jogador.position)
        var vel = forma.velocidade * tileAtual.fatorVelocidade(para: forma)
        switch jogador.estado {
        case .mergulhado: vel *= 1.45
        case .cavando: vel *= 0.92
        case .voando: vel *= 1.25
        case .planando: vel *= 1.15
        case .pulando: vel *= 0.85   // no ar você dirige menos
        default: break
        }

        let passoX = (dir.dx * vel + jogador.impulso.dx) * CGFloat(delta)
        let passoY = (dir.dy * vel + jogador.impulso.dy) * CGFloat(delta)

        // Eixos separados: escorrega ao longo das paredes em vez de travar.
        let alvoX = CGPoint(x: jogador.position.x + passoX, y: jogador.position.y)
        if podeOcupar(alvoX, forma: forma) {
            jogador.position.x = alvoX.x
        } else {
            avisarBloqueio(em: alvoX, forma: forma, estado: estado)
        }
        let alvoY = CGPoint(x: jogador.position.x, y: jogador.position.y + passoY)
        if podeOcupar(alvoY, forma: forma) {
            jogador.position.y = alvoY.y
        } else {
            avisarBloqueio(em: alvoY, forma: forma, estado: estado)
        }

        jogador.olharPara(dx: passoX)
        cobrarEssenciaDoVerbo(estado: estado, delta: delta)
        atualizarFolego(estado: estado, delta: delta)
        atualizarEscuridao(delta: delta)
        resolverPousoInvalido(forma: forma, estado: estado)
    }

    /// Verbos de apertar uma vez: salto e investida.
    private func acionarVerbo(_ estado: GameState) {
        let forma = estado.formaAtual
        let dir = InputManager.shared.direcao

        switch forma.verbo {
        case .pulo:
            guard estado.essencia > 5 else { return }
            if jogador.saltar(direcao: dir) {
                estado.essencia -= 4
                poeiraDeImpulso(cor: forma.corPrimaria)
            }

        case .investida:
            guard recargaInvestida == 0 else { return }
            guard estado.essencia > 8 else { return }
            recargaInvestida = 1.1
            estado.essencia -= 7
            jogador.investir(direcao: dir)
            espantarAmeacas(raio: 260)
            poeiraDeImpulso(cor: forma.corSecundaria)

        case .nenhum:
            let agora = CACurrentMediaTime()
            if agora - avisoVerbo > 4 {
                avisoVerbo = agora
                estado.avisar("A forma humana não tem movimento especial — vista um amuleto.",
                              icone: "figure.walk", cor: .neutro)
            }

        case .planar, .voo, .escavar, .arranco:
            break   // contínuos: tratados enquanto a tecla fica pressionada
        }
    }

    /// Verbos de manter pressionado: planar, voar, cavar e mergulhar.
    private func manterVerbo(segurando: Bool, forma: AnimalForm,
                             estado: GameState, delta: TimeInterval) {
        let tile = terreno(em: jogador.position)

        // Trocar de forma no meio de um voo ou de um túnel não pode deixar o
        // corpo preso num estado que a nova forma nem sabe fazer.
        if !estadoCombinaCom(forma) {
            jogador.entrar(jogador.estado.noAr ? .pulando : .andando)
        }

        switch forma.verbo {
        case .planar:
            if segurando && estado.essencia > 3 {
                jogador.entrar(.planando)
            } else if jogador.estado == .planando {
                jogador.entrar(.pulando)   // deixa a gravidade trazer de volta
            }

        case .voo:
            if segurando && estado.essencia > 3 {
                jogador.entrar(.voando)
            } else if jogador.estado == .voando {
                jogador.entrar(.pulando)
            }

        case .escavar:
            // Não dá para cavar dentro d'água nem no vazio de um abismo.
            let podeCavar = tile != .agua && tile != .abismo
            if segurando && podeCavar {
                jogador.entrar(.cavando)
            } else if jogador.estado == .cavando {
                // Só emerge onde a superfície aceita o corpo.
                if tile.passavel(para: forma) {
                    jogador.entrar(.andando)
                } else if !segurando {
                    estado.avisar("Não dá para emergir aqui — continue escavando.",
                                  icone: "arrow.up.circle", cor: .alerta)
                }
            }

        case .arranco:
            let naAgua = tile == .agua || tile == .charco
            if segurando && naAgua {
                jogador.entrar(.mergulhado)
            } else if jogador.estado == .mergulhado {
                jogador.entrar(.andando)
            }

        default:
            break
        }
    }

    /// O estado atual do corpo pertence ao verbo desta forma?
    private func estadoCombinaCom(_ forma: AnimalForm) -> Bool {
        switch jogador.estado {
        case .andando, .pulando: return true      // salto e queda valem para todos
        case .investindo: return forma.verbo == .investida
        case .planando: return forma.verbo == .planar
        case .voando: return forma.verbo == .voo
        case .cavando: return forma.verbo == .escavar
        case .mergulhado: return forma.verbo == .arranco
        }
    }

    /// O pirarucu respira ar. Submerso o fôlego cai; à tona, volta depressa.
    private func atualizarFolego(estado: GameState, delta: TimeInterval) {
        if jogador.estado == .mergulhado {
            estado.folego = max(0, estado.folego - CGFloat(delta) * 15)
            if estado.folego <= 0 {
                jogador.entrar(.andando)
                estado.avisar("Sem fôlego — você veio à tona.", icone: "wind", cor: .alerta)
            }
        } else if estado.folego < estado.folegoMaximo {
            estado.folego = min(estado.folegoMaximo, estado.folego + CGFloat(delta) * 45)
        }
    }

    /// No subsolo o mundo fecha: sobra um círculo de visão em volta do corpo.
    private func atualizarEscuridao(delta: TimeInterval) {
        let alvo: CGFloat = jogador.estado == .cavando ? 1.0 : 0
        escuridao.alpha += (alvo - escuridao.alpha) * CGFloat(min(1, delta * 4))
    }

    private func cobrarEssenciaDoVerbo(estado: GameState, delta: TimeInterval) {
        let extra: CGFloat
        switch jogador.estado {
        case .planando: extra = 5.0
        case .voando: extra = 7.5
        case .cavando: extra = 1.2
        case .mergulhado: extra = 0
        default: extra = 0
        }
        guard extra > 0 else { return }
        estado.essencia = max(0, estado.essencia - extra * CGFloat(delta))
    }

    /// Se o corpo terminou o salto/voo sobre terreno impossível, empurra para o
    /// tile livre mais próximo. Sem isto o jogador ficaria preso dentro da água.
    private func resolverPousoInvalido(forma: AnimalForm, estado: GameState) {
        guard jogador.estado == .andando, jogador.altura <= 0 else { return }
        guard !podeOcupar(jogador.position, forma: forma) else { return }

        var melhor: CGPoint?
        var melhorDist = CGFloat.greatestFiniteMagnitude
        let centro = WorldMetrics.tile(at: jogador.position)
        for raio in 1...6 {
            for dy in -raio...raio {
                for dx in -raio...raio where abs(dx) == raio || abs(dy) == raio {
                    let t = GridPoint(x: centro.x + dx, y: centro.y + dy)
                    let ponto = WorldMetrics.center(of: t)
                    guard podeOcupar(ponto, forma: forma) else { continue }
                    let d = hypot(ponto.x - jogador.position.x, ponto.y - jogador.position.y)
                    if d < melhorDist { melhorDist = d; melhor = ponto }
                }
            }
            if melhor != nil { break }
        }
        if let melhor {
            jogador.position = melhor
            estado.avisar("Terreno instável — você escorregou de volta.",
                          icone: "arrow.uturn.down", cor: .neutro)
        }
    }

    /// Meia-largura da caixa de colisão do jogador.
    private let meiaCaixa: CGFloat = 13

    /// Quais terrenos o corpo aceita AGORA — depende da forma e do estado.
    /// É aqui que salto, voo e escavação viram travessia de verdade.
    private func travessiaPermite(_ t: Terrain, forma: AnimalForm) -> Bool {
        switch jogador.estado {
        case .pulando, .planando:
            // No ar você passa por cima de tudo, menos paredão de rocha.
            return t != .rocha
        case .voando:
            return true
        case .cavando:
            // No subsolo passa por quase tudo; água e abismo, não.
            return t != .agua && t != .abismo
        case .mergulhado:
            return t == .agua || t == .charco || t.passavel(para: forma)
        case .investindo:
            // A investida rompe espinheiro.
            return t == .espinheiro || t.passavel(para: forma)
        case .andando:
            return t.passavel(para: forma)
        }
    }

    private func podeOcupar(_ p: CGPoint, forma: AnimalForm) -> Bool {
        let cantos = [
            CGPoint(x: p.x - meiaCaixa, y: p.y - meiaCaixa),
            CGPoint(x: p.x + meiaCaixa, y: p.y - meiaCaixa),
            CGPoint(x: p.x - meiaCaixa, y: p.y + meiaCaixa),
            CGPoint(x: p.x + meiaCaixa, y: p.y + meiaCaixa)
        ]
        return cantos.allSatisfy { travessiaPermite(terreno(em: $0), forma: forma) }
    }

    func terreno(em p: CGPoint) -> Terrain {
        terrenoNoTile(WorldMetrics.tile(at: p))
    }

    /// Terreno efetivo de um tile: o gerado, salvo se o jogo o tiver alterado.
    func terrenoNoTile(_ g: GridPoint) -> Terrain {
        alteracoes[g] ?? gerador.terrain(at: g)
    }

    /// Modifica o mundo em tempo real — é assim que o aceiro existe.
    func alterarTerreno(_ g: GridPoint, para t: Terrain, aceiro: Bool) {
        guard alteracoes[g] != t else { return }
        alteracoes[g] = t
        marcasDeTerreno[g]?.removeFromParent()
        let marca = SKSpriteNode(color: aceiro ? SKColor(hex: 0x8A6A42) : SKColor(hex: 0x2E241C),
                                 size: CGSize(width: WorldMetrics.tileSize,
                                              height: WorldMetrics.tileSize))
        marca.position = WorldMetrics.center(of: g)
        marca.zPosition = aceiro ? -50 : -49
        marca.alpha = aceiro ? 0.92 : 0.85
        camadaEntidades.addChild(marca)
        marcasDeTerreno[g] = marca
    }

    /// Nó solto controlado por um desafio (baliza, chama, marcador).
    func adicionarAuxiliar(_ n: SKNode) {
        camadaEntidades.addChild(n)
    }


    var jogadorInvestindo: Bool { jogador.estado == .investindo }
    var jogadorSubmerso: Bool { jogador.estado == .mergulhado }

    /// Máscara circular usada quando o jogador está no subsolo.
    private static let texturaEscuridao: SKTexture = Draw.texture(width: 512, height: 512) { ctx in
        let c = CGPoint(x: 256, y: 256)
        // Escuro nas bordas, aberto no centro: degradê feito em anéis.
        for i in stride(from: 256, through: 90, by: -3) {
            let t = (CGFloat(i) - 90) / (256 - 90)
            Draw.circle(ctx, c, CGFloat(i), SKColor(white: 0.02, alpha: 0.055 * t))
        }
    }

    /// O jogador está fora de vista (subsolo ou submerso)?
    var jogadorEscondido: Bool { jogador.estado.enterrado }
    var posicaoDoJogador: CGPoint { jogador.position }

    /// Busca em largura a partir do jogador, andando só por onde um humano
    /// passa. Sem isto o guia podia parar do outro lado de um rio e travar o
    /// ato 1 — e os vestígios podiam cair em lugar inalcançável.
    func tilesAlcancaveis(limite: Int = 1200) -> [GridPoint] {
        let inicio = WorldMetrics.tile(at: jogador.position)
        var vistos: Set<GridPoint> = [inicio]
        var ordem: [GridPoint] = [inicio]
        var i = 0
        let vizinhos = [GridPoint(x: 1, y: 0), GridPoint(x: -1, y: 0),
                        GridPoint(x: 0, y: 1), GridPoint(x: 0, y: -1)]
        while i < ordem.count, ordem.count < limite {
            let g = ordem[i]; i += 1
            for d in vizinhos {
                let n = g + d
                guard !vistos.contains(n) else { continue }
                guard terrenoNoTile(n).passavel(para: .humano) else { continue }
                vistos.insert(n)
                ordem.append(n)
            }
        }
        return ordem
    }

    /// Um tile alcançável a mais ou menos `distancia` pontos do jogador.
    func tileAlcancavel(distancia: CGFloat, rng: inout SeededRandom) -> GridPoint? {
        let candidatos = tilesAlcancaveis()
        guard candidatos.count > 1 else { return nil }
        let inicio = WorldMetrics.tile(at: jogador.position)
        func passos(_ g: GridPoint) -> CGFloat {
            hypot(CGFloat(g.x - inicio.x), CGFloat(g.y - inicio.y))
        }
        let alvo = distancia / WorldMetrics.tileSize
        let faixa = candidatos.filter { abs(passos($0) - alvo) < 3.5 }
        if !faixa.isEmpty { return faixa[rng.int(0, faixa.count - 1)] }
        // O bolso alcançável é menor que a distância pedida: usa o ponto mais
        // distante que existe, em vez de mandar o guia para fora do mapa andável.
        return candidatos.max { passos($0) < passos($1) }
    }

    func terrenoLivreParaAmeaca(_ p: CGPoint) -> Bool {
        terreno(em: p).passavel(para: .humano)
    }

    private func avisarBloqueio(em p: CGPoint, forma: AnimalForm, estado: GameState) {
        let t = terreno(em: WorldMetrics.center(of: WorldMetrics.tile(at: p)))
        guard let necessaria = t.formaNecessaria, necessaria != forma else { return }
        let agora = CACurrentMediaTime()
        guard agora - ultimoAvisoBloqueio > 3.0 else { return }
        ultimoAvisoBloqueio = agora
        if estado.temAmuleto(necessaria) {
            estado.avisar("\(t.nome.capitalized): vire \(necessaria.nome) para passar.",
                          icone: "arrow.triangle.2.circlepath", cor: .neutro)
        } else {
            estado.avisar("\(t.nome.capitalized) — exige o \(necessaria.amuleto).",
                          icone: "lock.fill", cor: .alerta)
        }
    }

    /// Nuvem de poeira no impulso — dá peso ao salto e à investida.
    private func poeiraDeImpulso(cor: SKColor) {
        for i in 0..<7 {
            let p = SKSpriteNode(texture: Objects.essencia())
            p.color = cor
            p.colorBlendFactor = 0.9
            p.position = jogador.position
            p.zPosition = 480
            p.setScale(0.3)
            mundo.addChild(p)
            let a = Double(i) / 7.0 * .pi * 2
            p.run(.sequence([
                .group([
                    .moveBy(x: CGFloat(cos(a)) * 34, y: CGFloat(sin(a)) * 18 - 6, duration: 0.34),
                    .fadeOut(withDuration: 0.34),
                    .scale(to: 0.9, duration: 0.34)
                ]),
                .removeFromParent()
            ]))
        }
    }

    /// A investida do lobo-guará empurra quem estiver por perto.
    private func espantarAmeacas(raio: CGFloat) {
        for (_, chunk) in chunks {
            for e in chunk.entidades where e is AmeacaNode {
                let dx = e.position.x - jogador.position.x
                let dy = e.position.y - jogador.position.y
                let d = hypot(dx, dy)
                guard d < raio, d > 0.5 else { continue }
                let destino = CGPoint(x: e.position.x + dx / d * 220,
                                      y: e.position.y + dy / d * 220)
                if terrenoLivreParaAmeaca(destino) {
                    e.run(.move(to: destino, duration: 0.28))
                }
            }
        }
    }

    // MARK: Sprite e câmera

    /// Flash ao trocar de forma. O sprite em si é responsabilidade do PlayerNode.
    private func atualizarSpriteJogador(forcar: Bool) {
        guard let estado else { return }
        guard forcar || estado.formaAtual != formaDesenhada else { return }
        formaDesenhada = estado.formaAtual
        jogador.aplicarForma(formaDesenhada, forcar: true)
        guard !forcar else { return }

        let brilho = SKSpriteNode(texture: Objects.essencia())
        brilho.position = jogador.position
        brilho.zPosition = 499
        brilho.setScale(0.6)
        mundo.addChild(brilho)
        brilho.run(.sequence([
            .group([.scale(to: 3.2, duration: 0.35), .fadeOut(withDuration: 0.35)]),
            .removeFromParent()
        ]))
    }

    private func atualizarCamera(delta: TimeInterval, estado: GameState) {
        let alvo = jogador.position
        let suavidade = CGFloat(min(1, delta * 7))
        cam.position.x += (alvo.x - cam.position.x) * suavidade
        cam.position.y += (alvo.y - cam.position.y) * suavidade

        let escalaAlvo = estado.formaAtual.zoomCamera
        let atual = cam.xScale
        cam.setScale(atual + (escalaAlvo - atual) * CGFloat(min(1, delta * 4)))
    }

    // MARK: Entidades

    private func atualizarEntidades(delta: TimeInterval, estado: GameState) {
        let pos = jogador.position
        for (coord, chunk) in chunks {
            for e in chunk.entidades {
                // Só processa o que está por perto.
                let dx = e.position.x - pos.x, dy = e.position.y - pos.y
                guard abs(dx) < 1400 && abs(dy) < 1400 else { continue }
                e.atualizar(delta: delta, jogador: pos, estado: estado, cena: self)

                // Essência é recolhida por contato.
                if let ess = e as? EssenciaNode,
                   (dx * dx + dy * dy).squareRoot() < ess.raioInteracao {
                    ess.coletar(estado: estado, cena: self)
                    var c = chunk
                    c.entidades.removeAll { $0 === ess }
                    chunks[coord] = c
                }
            }
        }
    }

    private func atualizarFoco(_ estado: GameState) {
        let pos = jogador.position
        var melhor: WorldEntity?
        var melhorDist = CGFloat.greatestFiniteMagnitude

        for (_, chunk) in chunks {
            for e in chunk.entidades where !(e is EssenciaNode) {
                let dx = e.position.x - pos.x, dy = e.position.y - pos.y
                let d = (dx * dx + dy * dy).squareRoot()
                if d < e.raioInteracao && d < melhorDist {
                    melhor = e
                    melhorDist = d
                }
            }
        }

        entidadeFoco = melhor
        if let melhor {
            let check = melhor.checar(estado: estado)
            estado.dicaInteracao = check.pode ? "E · \(check.dica)" : check.dica
        } else if estado.dicaInteracao != nil {
            estado.dicaInteracao = nil
        }
    }

    /// Quando um estilhaço é concluído, os marcadores daquele tipo somem do
    /// mundo e os dos tipos que ainda faltam continuam.
    private func verificarTrocaDeObjetivo(_ estado: GameState) {
        let atual = estado.objetivosPendentes(biomaID)
        guard atual != pendentes else { return }
        pendentes = atual

        for (coord, var chunk) in chunks {
            chunk.entidades.filter { $0 is ObjetivoNode || $0 is LargadaNode }
                .forEach { $0.removeFromParent() }
            chunk.entidades.removeAll { $0 is ObjetivoNode || $0 is LargadaNode }
            for spawn in chunk.dados.spawns where spawn.kind == .objetivo {
                if let n = criarEntidade(spawn) {
                    camadaEntidades.addChild(n)
                    chunk.entidades.append(n)
                }
            }

            chunks[coord] = chunk
        }
    }

    // MARK: Streaming de chunks

    private func atualizarStreaming(imediato: Bool) {
        let chunkAtual = WorldMetrics.chunk(containing: WorldMetrics.tile(at: jogador.position))

        // Descarrega o que ficou para trás.
        for (coord, c) in chunks {
            if abs(coord.x - chunkAtual.x) > raioDescarga || abs(coord.y - chunkAtual.y) > raioDescarga {
                c.terreno.removeFromParent()
                c.entidades.forEach { $0.removeFromParent() }
                chunks.removeValue(forKey: coord)
            }
        }

        // Enfileira o que falta, do mais próximo para o mais distante.
        var pendentes: [GridPoint] = []
        for dy in -raioCarga...raioCarga {
            for dx in -raioCarga...raioCarga {
                let c = GridPoint(x: chunkAtual.x + dx, y: chunkAtual.y + dy)
                if chunks[c] == nil && !filaGeracao.contains(c) { pendentes.append(c) }
            }
        }
        pendentes.sort {
            let a = abs($0.x - chunkAtual.x) + abs($0.y - chunkAtual.y)
            let b = abs($1.x - chunkAtual.x) + abs($1.y - chunkAtual.y)
            return a < b
        }
        filaGeracao.append(contentsOf: pendentes)

        if imediato {
            gerarChunksPendentes(orcamento: filaGeracao.count)
        }
    }

    /// Gera no máximo `orcamento` chunks por frame — desenhar a textura de um
    /// chunk custa alguns milissegundos, então espalhamos o trabalho.
    private func gerarChunksPendentes(orcamento: Int) {
        var feitos = 0
        while feitos < orcamento, !filaGeracao.isEmpty {
            let coord = filaGeracao.removeFirst()
            if chunks[coord] != nil { continue }
            construir(chunk: coord)
            feitos += 1
        }
    }

    private func construir(chunk coord: GridPoint) {
        let dados = gerador.generate(chunk: coord)
        let textura = TerrainRenderer.chunkTexture(chunk: dados, generator: gerador)

        let sprite = SKSpriteNode(texture: textura)
        sprite.anchorPoint = .zero
        sprite.position = CGPoint(x: CGFloat(coord.x) * WorldMetrics.chunkSize,
                                  y: CGFloat(coord.y) * WorldMetrics.chunkSize)
        sprite.size = CGSize(width: WorldMetrics.chunkSize, height: WorldMetrics.chunkSize)
        camadaTerreno.addChild(sprite)

        var entidades: [WorldEntity] = []
        for spawn in dados.spawns {
            if let n = criarEntidade(spawn) {
                camadaEntidades.addChild(n)
                entidades.append(n)
            }
        }

        // Portal de retorno junto ao ponto de chegada de cada bioma.
        if biomaID != .refugio && coord == GridPoint(x: 0, y: 0) {
            let n = PortalRetornoNode(tile: GridPoint(x: 0, y: -4))
            camadaEntidades.addChild(n)
            entidades.append(n)

        }

        chunks[coord] = ChunkCarregado(dados: dados, terreno: sprite, entidades: entidades)
    }

    private func criarEntidade(_ spawn: Spawn) -> WorldEntity? {
        switch spawn.kind {
        case .objetivo:
            guard !pendentes.isEmpty else { return nil }
            // Cada ponto do mundo assume um dos objetivos que ainda faltam —
            // assim os três estilhaços convivem no mesmo território.
            // Acesso e desafio agora são a operação; no mundo só ficam a
            // largada da prova e os objetivos das expedições.
            let espalhaveis = pendentes.filter { $0 != .acesso && $0 != .desafio }
            guard !espalhaveis.isEmpty else { return nil }
            let i = Int(Hashing.hash(spawn.tile.x, spawn.tile.y, 2024) % UInt64(espalhaveis.count))
            let kind = espalhaveis[i]
            if kind == .corrida {
                // A largada é única no chunk: a prova é um evento, não um item.
                guard Hashing.unit(spawn.tile.x, spawn.tile.y, 8080) < 0.4 else { return nil }
                return LargadaNode(tile: spawn.tile, bioma: biomaID)
            }
            if kind == .desafio {
                // Desafios ocupam muito espaço e atenção: no máximo um por chunk.
                guard Hashing.unit(spawn.tile.x, spawn.tile.y, 4242) < 0.34 else { return nil }
                return desafioDoBioma(tile: spawn.tile)
            }
            return ObjetivoNode(tile: spawn.tile, kind: kind, bioma: biomaID)
        case .essencia:
            return EssenciaNode(tile: spawn.tile)
        case .ameaca:
            let nivel = estado?.save.biome(biomaID).nivelExpedicao ?? 1
            return AmeacaNode(tile: spawn.tile, kind: biome.ameaca, dificuldade: nivel)
        case .segredo:
            return SegredoNode(tile: spawn.tile)
        case .npc(let chave):
            return NPCNode(tile: spawn.tile, chave: chave)
        case .portal(let destino):
            return PortalNode(tile: spawn.tile, destino: destino)
        case .placa(let texto):
            return PlacaNode(tile: spawn.tile, texto: texto)
        case .canteiro(let i):
            return CanteiroNode(tile: spawn.tile, indice: i)
        case .pesca:
            return PescaNode(tile: spawn.tile)
        case .oficina:
            return OficinaNode(tile: spawn.tile)
        case .harpia:
            return HarpiaNode(tile: spawn.tile)
        case .fauna(let id):
            guard let spec = FaunaSpec.porId(id) else { return nil }
            return FaunaNode(tile: spawn.tile, spec: spec)
        }
    }

    /// A HUD não precisa de 60 Hz: publicar 5x por segundo evita redesenhar
    /// a árvore SwiftUI a cada frame do SpriteKit.
    private func publicarHUD(delta: TimeInterval, estado: GameState) {
        tempoPublicacao += delta
        guard tempoPublicacao > 0.2 else { return }
        tempoPublicacao = 0

        let tile = WorldMetrics.tile(at: jogador.position)
        if tile != estado.jogadorTile { estado.jogadorTile = tile }

        // Bússola: aponta para o ponto de missão mais próximo já carregado.
        var melhor: CGFloat = .greatestFiniteMagnitude
        var vetor: CGVector?
        for (_, chunk) in chunks {
            for e in chunk.entidades where e is ObjetivoNode {
                let dx = e.position.x - jogador.position.x
                let dy = e.position.y - jogador.position.y
                let d = (dx * dx + dy * dy).squareRoot()
                if d < melhor { melhor = d; vetor = CGVector(dx: dx / max(d, 1), dy: dy / max(d, 1)) }
            }
        }
        estado.bussola = vetor
        estado.distanciaObjetivo = vetor == nil ? nil : melhor
    }

    /// Cada bioma resolve o seu desafio com uma mecânica própria.
    private func desafioDoBioma(tile: GridPoint) -> WorldEntity? {
        switch biomaID {
        case .mataAtlantica: return ComitivaNode(tile: tile)
        case .cerrado: return FocoDeIncendioNode(tile: tile)
        case .pantanal: return NinhoNode(tile: tile)
        case .amazonia:
            // A malhadeira está no fundo: precisa de água de verdade sob ela.
            guard let agua = aguaProxima(de: tile) else { return nil }
            return RedeNode(tile: agua)
        case .pampa: return GaleriaNode(tile: tile)
        case .refugio: return nil
        }
    }

    /// Procura um tile de água perto de um ponto, para ancorar a rede.
    private func aguaProxima(de g: GridPoint, raio: Int = 7) -> GridPoint? {
        for r in 0...raio {
            for dy in -r...r {
                for dx in -r...r where abs(dx) == r || abs(dy) == r || r == 0 {
                    let t = GridPoint(x: g.x + dx, y: g.y + dy)
                    if terrenoNoTile(t) == .agua { return t }
                }
            }
        }
        return nil
    }

    // MARK: A sombra da Harpia

    /// A abertura: uma sombra grande demais atravessa a clareira, a luz cai
    /// por um instante, e sobra uma pena no chão. Nenhuma fala.
    /// Contagem até a pena tocar o chão. Fica no laço de update, e não numa
    /// SKAction, porque SKAction só avança enquanto a view renderiza — a pena
    /// é obrigatória para a partida começar e não pode depender disso.
    private var contagemPena: TimeInterval = -1
    private var origemSobrevoo: CGPoint = .zero

    private func verificarCinematicaDaHarpia(_ estado: GameState, delta: TimeInterval) {
        if contagemPena > 0 {
            contagemPena -= delta
            if contagemPena <= 0 {
                contagemPena = -1
                largarPena(perto: origemSobrevoo, estado: estado)
            }
        }
        guard biomaID == .refugio,
              estado.temFlag("aguardando_sombra"),
              !estado.temFlag("sombra_passou") else { return }
        estado.ligarFlag("sombra_passou")
        rodarSobrevoo(estado)
    }

    private func rodarSobrevoo(_ estado: GameState) {
        let origem = jogador.position

        // Escurece de leve: alguma coisa passou na frente do sol.
        let penumbra = SKSpriteNode(color: .black, size: CGSize(width: 6000, height: 6000))
        penumbra.alpha = 0
        penumbra.zPosition = 700
        penumbra.position = origem
        mundo.addChild(penumbra)
        penumbra.run(.sequence([
            .wait(forDuration: 0.5),
            .fadeAlpha(to: 0.40, duration: 0.7),
            .wait(forDuration: 0.5),
            .fadeAlpha(to: 0, duration: 1.1),
            .removeFromParent()
        ]))

        // A sombra em si: entra por um lado da clareira e sai pelo outro.
        let sombra = SKSpriteNode(texture: Objects.sombraDeAsas())
        sombra.size = CGSize(width: 1500, height: 640)
        sombra.zPosition = 690
        sombra.alpha = 0
        sombra.position = CGPoint(x: origem.x - 1500, y: origem.y + 620)
        mundo.addChild(sombra)
        sombra.run(.sequence([
            .wait(forDuration: 0.4),
            .group([
                .fadeAlpha(to: 0.85, duration: 0.5),
                .move(to: CGPoint(x: origem.x + 1500, y: origem.y - 500), duration: 2.6),
                // Bater de asas: a sombra "respira" enquanto atravessa.
                .repeat(.sequence([.scaleX(to: 1.06, y: 0.9, duration: 0.42),
                                   .scaleX(to: 0.94, y: 1.08, duration: 0.42)]), count: 3)
            ]),
            .fadeOut(withDuration: 0.4),
            .removeFromParent()
        ]))

        // Tremor curto quando ela passa mais perto.
        run(.sequence([.wait(forDuration: 1.3), .run { [weak self] in
            guard let self else { return }
            self.cam.run(.sequence([
                .moveBy(x: 6, y: -4, duration: 0.05),
                .moveBy(x: -12, y: 8, duration: 0.07),
                .moveBy(x: 6, y: -4, duration: 0.05)
            ]))
        }]))

        estado.avisar("Alguma coisa grande demais passou por cima da clareira.",
                      icone: "eye.fill", cor: .alerta)

        // E então a pena, descendo devagar até o chão.
        origemSobrevoo = origem
        contagemPena = 2.4
    }

    private func largarPena(perto origem: CGPoint, estado: GameState) {
        // Procura um tile livre logo à frente do jogador.
        var destino = WorldMetrics.tile(at: CGPoint(x: origem.x + 90, y: origem.y + 60))
        for r in 0...5 {
            let t = GridPoint(x: destino.x + r, y: destino.y)
            if terrenoNoTile(t).livre { destino = t; break }
        }

        // A pena de verdade já nasce no lugar certo e interagível: a queda é
        // um enfeite por cima, não a mecânica.
        let pena = PenaNode(tile: destino)
        camadaEntidades.addChild(pena)
        if var chunk = chunks[WorldMetrics.chunk(containing: destino)] {
            chunk.entidades.append(pena)
            chunks[WorldMetrics.chunk(containing: destino)] = chunk
        }

        let queda = SKSpriteNode(texture: Objects.pena())
        queda.position = CGPoint(x: pena.position.x, y: pena.position.y + 520)
        queda.zPosition = 260
        camadaEntidades.addChild(queda)
        queda.run(.sequence([
            .group([
                .moveTo(y: pena.position.y, duration: 3.2),
                .sequence([
                    .moveBy(x: 34, y: 0, duration: 0.8), .moveBy(x: -40, y: 0, duration: 0.8),
                    .moveBy(x: 30, y: 0, duration: 0.8), .moveBy(x: -24, y: 0, duration: 0.8)
                ]),
                .repeat(.sequence([.rotate(byAngle: 0.5, duration: 0.8),
                                   .rotate(byAngle: -0.5, duration: 0.8)]), count: 2)
            ]),
            .fadeOut(withDuration: 0.25),
            .removeFromParent()
        ]))

        estado.avisar("Uma pena caiu na clareira. Vá até ela (E).",
                      icone: "sparkles", cor: .conquista)
    }

    // MARK: Efeitos e reações

    func efeitoConquista(em ponto: CGPoint, cor: SKColor) {
        for i in 0..<10 {
            let p = SKSpriteNode(texture: Objects.essencia())
            p.color = cor
            p.colorBlendFactor = 0.85
            p.position = ponto
            p.zPosition = 600
            p.setScale(0.35)
            mundo.addChild(p)
            let a = Double(i) / 10.0 * .pi * 2
            let dist = CGFloat.random(in: 40...80)
            p.run(.sequence([
                .group([
                    .moveBy(x: CGFloat(cos(a)) * dist, y: CGFloat(sin(a)) * dist, duration: 0.55),
                    .fadeOut(withDuration: 0.55),
                    .scale(to: 0.05, duration: 0.55)
                ]),
                .removeFromParent()
            ]))
        }
    }

    func alertaAmeaca(_ kind: HazardKind) {
        let agora = CACurrentMediaTime()
        guard agora - ultimoAvisoAmeaca > 8 else { return }
        ultimoAvisoAmeaca = agora
        estado?.avisar("\(kind.nome) detectou você!", icone: "exclamationmark.triangle.fill", cor: .alerta)
    }

    /// Contato com uma ameaça: sem morte — o jogador é empurrado para longe e
    /// perde essência e pontos. Conservação não é jogo de tiro.
    func jogadorAfugentado(por kind: HazardKind) {
        guard let estado else { return }
        estado.essencia = max(0, estado.essencia - 35)
        estado.save.pontos = max(0, estado.save.pontos - 40)
        if estado.formaAtual != .humano && estado.essencia < 12 {
            estado.formaAtual = .humano
        }
        estado.avisar("Você foi afugentado pela \(kind.nome.lowercased()). −40 pontos.",
                      icone: "figure.run", cor: .alerta)

        // Empurrão até um tile seguro atrás do jogador.
        var destino = jogador.position
        for tentativa in stride(from: CGFloat(140), through: 520, by: 60) {
            let angulo = Double(tentativa) * 0.7
            let candidato = CGPoint(x: jogador.position.x + CGFloat(cos(angulo)) * tentativa,
                                    y: jogador.position.y + CGFloat(sin(angulo)) * tentativa)
            if podeOcupar(candidato, forma: estado.formaAtual) { destino = candidato; break }
        }
        jogador.position = destino
        cam.position = destino

        let flash = SKSpriteNode(color: Palette.danger.withAlphaComponent(0.35),
                                 size: CGSize(width: 4000, height: 4000))
        flash.zPosition = 900
        flash.position = destino
        mundo.addChild(flash)
        flash.run(.sequence([.fadeOut(withDuration: 0.5), .removeFromParent()]))
    }
}
