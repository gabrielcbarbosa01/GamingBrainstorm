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
    private var kindObjetivoAtual: ObjectiveKind?
    private var ultimoAvisoBloqueio: TimeInterval = 0
    private var ultimoAvisoAmeaca: TimeInterval = 0
    private var recargaInvestida: TimeInterval = 0
    private var avisoVerbo: TimeInterval = 0
    private var tempoAndando: TimeInterval = 0
    private var tempoPublicacao: TimeInterval = 0
    private var entidadeFoco: WorldEntity?

    /// Raio de chunks mantidos carregados em volta do jogador.
    private let raioCarga = 2
    private let raioDescarga = 4

    // MARK: Ciclo de vida

    override func didMove(to view: SKView) {
        scaleMode = .resizeFill
        addChild(mundo)
        mundo.addChild(camadaTerreno)
        mundo.addChild(camadaEntidades)
        camadaTerreno.zPosition = -100
        camadaEntidades.zPosition = 0

        mundo.addChild(jogador)

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

        jogador.position = WorldMetrics.center(of: GridPoint(x: 0, y: 0))
        kindObjetivoAtual = estado?.etapaAtual(id)?.kind
        atualizarStreaming(imediato: false)
        gerarChunksPendentes(orcamento: 9)
        jogador.aplicarForma(estado?.formaAtual ?? .humano, forcar: true)
        formaDesenhada = estado?.formaAtual ?? .humano
        cam.position = jogador.position
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
        guard estado.dialogo == nil, estado.pesca == nil,
              estado.painelRefugio == nil, estado.tela == .jogo else {
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
        gerador.terrain(at: WorldMetrics.tile(at: p))
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

    /// Se a etapa mudou, os pontos de missão espalhados pelo mundo mudam de tipo.
    private func verificarTrocaDeObjetivo(_ estado: GameState) {
        let atual = estado.etapaAtual(biomaID)?.kind
        guard atual != kindObjetivoAtual else { return }
        kindObjetivoAtual = atual

        for (coord, var chunk) in chunks {
            chunk.entidades.filter { $0 is ObjetivoNode }.forEach { $0.removeFromParent() }
            chunk.entidades.removeAll { $0 is ObjetivoNode }
            if let kind = atual {
                for spawn in chunk.dados.spawns where spawn.kind == .objetivo {
                    let n = ObjetivoNode(tile: spawn.tile, kind: kind, bioma: biomaID)
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
            guard let kind = kindObjetivoAtual else { return nil }
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
