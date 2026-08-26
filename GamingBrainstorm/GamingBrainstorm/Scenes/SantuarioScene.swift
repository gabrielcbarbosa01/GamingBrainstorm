//
//  SantuarioScene.swift
//  Guardiões dos Biomas
//
//  A masmorra, à moda dos Zelda antigos: uma sala por vez, câmera enquadrando
//  a sala inteira, portas trancadas, baús, inimigos e o item no meio do
//  caminho. Em 2.5D — piso visto de cima, personagens em pé, sombra no chão.
//

import SpriteKit

// MARK: - Inimigo

final class InimigoNode: SKNode {
    private let sprite: SKSpriteNode
    private let sombra = SKSpriteNode()
    private var vida: Int
    private var recuo: CGVector = .zero
    private var invulneravel: TimeInterval = 0
    private(set) var afugentado = false
    private var rng: SeededRandom
    private var vaguear: CGVector = .zero
    private var trocaRumo: TimeInterval = 0

    let raio: CGFloat = 26

    init(kind: HazardKind, forca: Int, posicao: CGPoint, semente: UInt64) {
        sprite = SKSpriteNode(texture: Objects.ameaca(kind))
        vida = forca
        rng = SeededRandom(seed: semente)
        super.init()
        position = posicao

        sombra.texture = Objects.sombraChao()
        sombra.size = CGSize(width: 52, height: 20)
        sombra.position = CGPoint(x: 0, y: -22)
        sombra.zPosition = -1
        addChild(sombra)

        sprite.setScale(0.95)
        addChild(sprite)
        sprite.run(.repeatForever(.sequence([
            .scaleX(to: 1.02, y: 0.94, duration: 0.4),
            .scaleX(to: 0.92, y: 1.04, duration: 0.4)
        ])))
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) não usado") }

    /// Devolve true se encostou no jogador neste passo.
    func passo(delta: TimeInterval, jogador: CGPoint, limites: CGRect) -> Bool {
        guard !afugentado else { return false }
        invulneravel = max(0, invulneravel - delta)

        let dx = jogador.x - position.x, dy = jogador.y - position.y
        let d = hypot(dx, dy)

        var v = CGVector.zero
        if d < 300 {
            v = CGVector(dx: dx / max(d, 1), dy: dy / max(d, 1))
        } else {
            trocaRumo -= delta
            if trocaRumo <= 0 {
                trocaRumo = rng.double(1.2, 2.6)
                let a = rng.double(0, .pi * 2)
                vaguear = CGVector(dx: cos(a), dy: sin(a))
            }
            v = vaguear
        }

        let vel: CGFloat = d < 300 ? 118 : 52
        var p = CGPoint(x: position.x + (v.dx * vel + recuo.dx) * CGFloat(delta),
                        y: position.y + (v.dy * vel + recuo.dy) * CGFloat(delta))
        p.x = min(max(p.x, limites.minX + raio), limites.maxX - raio)
        p.y = min(max(p.y, limites.minY + raio), limites.maxY - raio)
        position = p
        sprite.xScale = dx < 0 ? -0.95 : 0.95

        let decai = CGFloat(pow(0.002, delta))
        recuo.dx *= decai; recuo.dy *= decai

        return d < raio + 20
    }

    /// Golpe recebido. Devolve true se foi afugentado de vez.
    @discardableResult
    func atingir(de origem: CGPoint, forca: CGFloat = 620) -> Bool {
        guard invulneravel == 0, !afugentado else { return false }
        invulneravel = 0.4
        vida -= 1
        let dx = position.x - origem.x, dy = position.y - origem.y
        let d = max(hypot(dx, dy), 1)
        recuo = CGVector(dx: dx / d * forca, dy: dy / d * forca)
        sprite.run(.sequence([.colorize(with: .white, colorBlendFactor: 0.9, duration: 0.05),
                              .colorize(withColorBlendFactor: 0, duration: 0.2)]))
        if vida <= 0 {
            afugentado = true
            run(.sequence([.group([.fadeOut(withDuration: 0.35),
                                   .scale(to: 0.4, duration: 0.35),
                                   .moveBy(x: dx / d * 90, y: dy / d * 90, duration: 0.35)]),
                           .removeFromParent()]))
            return true
        }
        return false
    }
}

// MARK: - A cena

@MainActor
final class SantuarioScene: SKScene {

    weak var estado: GameState?
    private(set) var bioma: BiomeID = .mataAtlantica
    private var santuario: Santuario!
    private var salaAtual = GridPoint(x: 0, y: 0)

    private let mundo = SKNode()
    private let jogador = PlayerNode()
    private let cam = SKCameraNode()
    private var pisoNo: SKSpriteNode?
    private var portas: [Direcao: SKSpriteNode] = [:]
    private var inimigos: [InimigoNode] = []
    private var interativos: [SKNode] = []
    private var montado = false

    private var ultimoTempo: TimeInterval = 0
    private var invulneravel: TimeInterval = 0
    private var recargaGolpe: TimeInterval = 0
    private var olhar = CGVector(dx: 0, dy: -1)
    private var transicionando = false
    private var bauAlvo: SKSpriteNode?
    private var saidaNo: SKSpriteNode?

    /// Área jogável da sala, em coordenadas de mundo.
    private var limites: CGRect {
        let o = SalaMetrics.centro(salaAtual)
        let t = SalaMetrics.tamanho
        return CGRect(x: o.x - t.width / 2 + 26, y: o.y - t.height / 2 + 26,
                      width: t.width - 52, height: t.height - 52)
    }

    // MARK: Ciclo de vida

    override func didMove(to view: SKView) {
        InputManager.shared.start()
        guard !montado else { InputManager.shared.limparTeclas(); return }
        montado = true
        // resizeFill: a cena assume o tamanho da janela e o enquadramento da
        // sala é feito pela ESCALA DA CÂMERA. Mexer no `size` da cena com
        // aspectFit deixava a SpriteView sem nada para desenhar.
        scaleMode = .resizeFill
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        addChild(mundo)
        addChild(cam)
        camera = cam
        jogador.zPosition = 500
        mundo.addChild(jogador)

        guard let estado else { return }
        bioma = estado.biomaCarregado
        backgroundColor = SKColor(hex: 0x070A06)
        santuario = estado.santuario(bioma)
        salaAtual = santuario.entrada
        montarSala(estado: estado)
        jogador.position = SalaMetrics.centro(salaAtual)
        jogador.aplicarForma(estado.formaAtual, forcar: true)
        cam.position = SalaMetrics.centro(salaAtual)
        ajustarCamera()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        ajustarCamera()
    }

    /// Enquadra a sala inteira, como nos Zelda antigos: a sala toda cabe na
    /// tela e a câmera só salta quando você troca de porta.
    private func ajustarCamera() {
        guard size.width > 1, size.height > 1 else { return }
        let alvo = SalaArt.tamanhoTextura
        let escala = max(alvo.width / size.width, alvo.height / size.height)
        cam.setScale(max(0.2, escala))
    }

    // MARK: Montagem de sala

    private func montarSala(estado: GameState) {
        pisoNo?.removeFromParent()
        portas.values.forEach { $0.removeFromParent() }
        portas.removeAll()
        inimigos.forEach { $0.removeFromParent() }
        inimigos.removeAll()
        interativos.forEach { $0.removeFromParent() }
        interativos.removeAll()
        bauAlvo = nil
        saidaNo?.removeFromParent()
        saidaNo = nil

        // Nunca deixar a cena vazia: sem sala, volta para a entrada.
        if santuario.salas[salaAtual] == nil { salaAtual = santuario.entrada }
        guard let sala = santuario.salas[salaAtual] else { return }
        estado.salaAtual = salaAtual
        estado.marcarSalaVisitada(bioma, salaAtual)

        let variante = abs(salaAtual.x * 7 + salaAtual.y * 13) % 5
        let piso = SKSpriteNode(texture: SalaArt.sala(bioma, variante: variante))
        piso.anchorPoint = SalaArt.ancoraInterior
        piso.position = SalaMetrics.centro(salaAtual)
        piso.zPosition = -1000
        mundo.addChild(piso)
        pisoNo = piso

        let limpa = estado.salaLimpa(bioma, salaAtual)

        for (dir, tipo) in sala.portas {
            var t = tipo
            if t == .fechada && limpa { t = .aberta }
            let s = SKSpriteNode(texture: SalaArt.porta(t, dir, bioma))
            s.position = posicaoDaPorta(dir)
            s.zPosition = t == .aberta ? -900 : 600
            mundo.addChild(s)
            portas[dir] = s
        }

        // Conteúdo
        switch sala.conteudo {
        case .inimigos(let n), .chave(let n):
            if !limpa { nascerInimigos(n, estado: estado) }
        case .bau(let tesouro):
            colocarBau(tesouro: tesouro, estado: estado)
        case .amuleto:
            colocarBau(tesouro: nil, estado: estado)
        case .chefe:
            if !estado.temAmuleto(Biome[bioma].animal) { break }
            if !limpa { nascerChefe(estado: estado) }
        case .puzzle:
            if !limpa { colocarPuzzle(estado: estado) }
        case .entrada, .vazia:
            break
        }

        // Saída: escada na entrada, sempre; portal no fundo, depois do Guardião.
        if case .entrada = sala.conteudo {
            let e = SKSpriteNode(texture: SalaArt.saida(bioma))
            e.position = CGPoint(x: SalaMetrics.centro(salaAtual).x,
                                 y: SalaMetrics.centro(salaAtual).y - SalaMetrics.tamanho.height / 2 + 70)
            e.zPosition = 350
            mundo.addChild(e)
            saidaNo = e
        } else if case .chefe = sala.conteudo, estado.save.biome(bioma).santuarioConcluido {
            let e = SKSpriteNode(texture: SalaArt.portalDeVolta(bioma))
            e.position = SalaMetrics.centro(salaAtual)
            e.zPosition = 350
            mundo.addChild(e)
            e.run(.repeatForever(.sequence([
                .group([.scale(to: 1.12, duration: 0.9), .rotate(byAngle: .pi / 6, duration: 0.9)]),
                .group([.scale(to: 0.94, duration: 0.9), .rotate(byAngle: .pi / 6, duration: 0.9)])
            ])))
            saidaNo = e
        }
    }

    private func posicaoDaPorta(_ d: Direcao) -> CGPoint {
        let o = SalaMetrics.centro(salaAtual)
        let t = SalaMetrics.tamanho
        switch d {
        case .norte: return CGPoint(x: o.x, y: o.y + t.height / 2 + SalaMetrics.tile * 0.4)
        case .sul: return CGPoint(x: o.x, y: o.y - t.height / 2 - SalaMetrics.tile * 0.4)
        case .leste: return CGPoint(x: o.x + t.width / 2 + SalaMetrics.tile * 0.4, y: o.y)
        case .oeste: return CGPoint(x: o.x - t.width / 2 - SalaMetrics.tile * 0.4, y: o.y)
        }
    }

    private func nascerInimigos(_ n: Int, estado: GameState) {
        var rng = Hashing.rng(salaAtual.x, salaAtual.y, Biome[bioma].semente)
        let prof = santuario.salas[salaAtual]?.profundidade ?? 0
        for i in 0..<n {
            let p = CGPoint(x: limites.minX + rng.cg(60, limites.width - 60),
                            y: limites.minY + rng.cg(60, limites.height - 60))
            let e = InimigoNode(kind: Biome[bioma].ameaca,
                                forca: 2 + prof / 3,
                                posicao: p,
                                semente: UInt64(i) &+ UInt64(abs(salaAtual.x * 31 + salaAtual.y)))
            mundo.addChild(e)
            inimigos.append(e)
        }
    }

    private func nascerChefe(estado: GameState) {
        let p = CGPoint(x: SalaMetrics.centro(salaAtual).x,
                        y: SalaMetrics.centro(salaAtual).y + 90)
        let chefe = InimigoNode(kind: Biome[bioma].ameaca, forca: 10,
                                posicao: p, semente: 999)
        chefe.setScale(1.9)
        mundo.addChild(chefe)
        inimigos.append(chefe)
        estado.avisar("A frente inteira se concentrou aqui. Afugente-a.",
                      icone: "exclamationmark.triangle.fill", cor: .alerta)
    }

    private func colocarBau(tesouro: Tesouro?, estado: GameState) {
        let aberto = estado.bauAberto(bioma, salaAtual)
        let b = SKSpriteNode(texture: SalaArt.bau(aberto: aberto))
        b.position = SalaMetrics.centro(salaAtual)
        b.zPosition = 400
        b.userData = NSMutableDictionary()
        b.userData?["tesouro"] = (tesouro == nil ? "amuleto" : "comum")
        mundo.addChild(b)
        interativos.append(b)
        bauAlvo = aberto ? nil : b
        if !aberto {
            b.run(.repeatForever(.sequence([.moveBy(x: 0, y: 4, duration: 0.9),
                                            .moveBy(x: 0, y: -4, duration: 0.9)])))
        }
    }

    private func colocarPuzzle(estado: GameState) {
        var rng = Hashing.rng(salaAtual.x, salaAtual.y, 4242)
        for i in 0..<3 {
            let s = SKSpriteNode(texture: SalaArt.interruptor(false))
            s.position = CGPoint(x: limites.minX + rng.cg(80, limites.width - 80),
                                 y: limites.minY + rng.cg(80, limites.height - 80))
            s.zPosition = 300
            s.userData = NSMutableDictionary()
            s.userData?["ligado"] = false
            s.userData?["i"] = i
            mundo.addChild(s)
            interativos.append(s)
        }
        estado.avisar("Três placas no chão. Pise em todas.", icone: "circle.grid.3x3.fill", cor: .neutro)
    }

    // MARK: Laço

    override func update(_ currentTime: TimeInterval) {
        guard let estado else { return }
        let delta = ultimoTempo == 0 ? 1.0 / 60 : min(currentTime - ultimoTempo, 1.0 / 20)
        ultimoTempo = currentTime

        processarTeclas(estado)
        guard estado.dialogo == nil, estado.tela == .jogo, !transicionando else { return }

        estado.atualizar(delta: delta)
        invulneravel = max(0, invulneravel - delta)
        recargaGolpe = max(0, recargaGolpe - delta)

        moverJogador(delta: delta, estado: estado)
        atualizarInimigos(delta: delta, estado: estado)
        atualizarPuzzle(estado: estado)
        atualizarDica(estado: estado)
        verificarLimpeza(estado: estado)
        verificarPortas(estado: estado)
        ordenarProfundidade()
    }

    private func processarTeclas(_ estado: GameState) {
        for acao in InputManager.shared.consumirAcoes() {
            if estado.dialogo != nil {
                if case .interagir = acao { estado.avancarDialogo() }
                if case .habilidade = acao { estado.avancarDialogo() }
                continue
            }
            switch acao {
            case .habilidade: golpearOuVerbo(estado)
            case .interagir: interagir(estado)
            case .humano: estado.trocarForma(.humano)
            case .forma(let n):
                let ordem = AnimalForm.vestiveis
                if ordem.indices.contains(n - 1) { estado.trocarForma(ordem[n - 1]) }
            case .menu: estado.tela = .menu
            case .jornal: estado.tela = .jornal
            case .mapa: estado.tela = .mapa
            case .expedicao: break
            }
        }
    }

    // MARK: Jogador

    private func moverJogador(delta: TimeInterval, estado: GameState) {
        let dir = InputManager.shared.direcao
        jogador.aplicarForma(estado.formaAtual)
        let andando = dir.dx != 0 || dir.dy != 0
        if andando { olhar = dir }
        jogador.simular(delta: delta, andando: andando)

        let vel = estado.formaAtual.velocidade
        var p = CGPoint(x: jogador.position.x + (dir.dx * vel + jogador.impulso.dx) * CGFloat(delta),
                        y: jogador.position.y + (dir.dy * vel + jogador.impulso.dy) * CGFloat(delta))

        // Paredes: só se sai pela porta.
        let l = limites
        if p.x < l.minX { p.x = podeSair(.oeste, p) ? p.x : l.minX }
        if p.x > l.maxX { p.x = podeSair(.leste, p) ? p.x : l.maxX }
        if p.y < l.minY { p.y = podeSair(.sul, p) ? p.y : l.minY }
        if p.y > l.maxY { p.y = podeSair(.norte, p) ? p.y : l.maxY }
        jogador.position = p
        jogador.olharPara(dx: dir.dx)

        // Atravessou a soleira: troca de sala.
        let folga: CGFloat = 40
        if p.y > l.maxY + folga { trocarSala(.norte, estado: estado) }
        else if p.y < l.minY - folga { trocarSala(.sul, estado: estado) }
        else if p.x > l.maxX + folga { trocarSala(.leste, estado: estado) }
        else if p.x < l.minX - folga { trocarSala(.oeste, estado: estado) }
    }

    /// A porta daquele lado deixa passar?
    private func podeSair(_ d: Direcao, _ p: CGPoint) -> Bool {
        guard let sala = santuario.salas[salaAtual], let tipo = sala.portas[d] else { return false }
        guard let estado else { return false }
        // Tem de estar alinhado com o vão, não em qualquer ponto da parede.
        let o = SalaMetrics.centro(salaAtual)
        let alinhado = (d == .norte || d == .sul) ? abs(p.x - o.x) < 60 : abs(p.y - o.y) < 60
        guard alinhado else { return false }

        switch tipo {
        case .aberta: return true
        case .fechada: return estado.salaLimpa(bioma, salaAtual)
        case .trancada: return false      // destrancada com E
        case .selada: return estado.temAmuleto(Biome[bioma].animal)
        case .doGuardiao: return estado.temChaveDoGuardiao(bioma)
        }
    }

    private func trocarSala(_ d: Direcao, estado: GameState) {
        let prox = GridPoint(x: salaAtual.x + d.passo.x, y: salaAtual.y + d.passo.y)
        guard santuario.salas[prox] != nil else { return }
        transicionando = true
        salaAtual = prox
        montarSala(estado: estado)

        // Entra pelo lado oposto da sala nova.
        let o = SalaMetrics.centro(prox)
        let t = SalaMetrics.tamanho
        switch d {
        case .norte: jogador.position = CGPoint(x: o.x, y: o.y - t.height / 2 + 60)
        case .sul: jogador.position = CGPoint(x: o.x, y: o.y + t.height / 2 - 60)
        case .leste: jogador.position = CGPoint(x: o.x - t.width / 2 + 60, y: o.y)
        case .oeste: jogador.position = CGPoint(x: o.x + t.width / 2 - 60, y: o.y)
        }
        cam.run(.move(to: o, duration: 0.32)) { [weak self] in self?.transicionando = false }
    }

    // MARK: Ação

    private func golpearOuVerbo(_ estado: GameState) {
        if estado.formaAtual == .loboGuara {
            jogador.investir(direcao: olhar)
            atingirNaFrente(alcance: 120, estado: estado)
            return
        }
        if estado.formaAtual == .micoLeaoDourado {
            jogador.saltoLivre = true
            jogador.saltar(direcao: olhar)
            return
        }
        guard recargaGolpe == 0 else { return }
        recargaGolpe = 0.34
        // Golpe do bastão de campo: um arco curto à frente.
        let arco = SKSpriteNode(texture: Objects.golpe())
        arco.position = CGPoint(x: jogador.position.x + olhar.dx * 44,
                                y: jogador.position.y + olhar.dy * 44)
        arco.zRotation = atan2(olhar.dy, olhar.dx)
        arco.zPosition = 550
        mundo.addChild(arco)
        let some: SKAction = .group([.scale(to: 1.25, duration: 0.16),
                                     .fadeOut(withDuration: 0.16)])
        arco.run(.sequence([some, .removeFromParent()]))
        atingirNaFrente(alcance: 96, estado: estado)
    }

    private func atingirNaFrente(alcance: CGFloat, estado: GameState) {
        for e in inimigos where !e.afugentado {
            let dx = e.position.x - jogador.position.x
            let dy = e.position.y - jogador.position.y
            let d = hypot(dx, dy)
            guard d < alcance else { continue }
            // Só acerta quem está do lado para onde você olha.
            let dot = (dx / max(d, 1)) * olhar.dx + (dy / max(d, 1)) * olhar.dy
            guard dot > 0.15 || d < 44 else { continue }
            if e.atingir(de: jogador.position) {
                estado.somarPontos(45)
            }
        }
    }

    private func interagir(_ estado: GameState) {
        // Porta trancada em frente?
        for (d, no) in portas {
            guard santuario.salas[salaAtual]?.portas[d] == .trancada else { continue }
            if hypot(no.position.x - jogador.position.x,
                     no.position.y - jogador.position.y) < 110 {
                if estado.gastarChave(bioma) {
                    var sala = santuario.salas[salaAtual]!
                    sala.portas[d] = .aberta
                    santuario.salas[salaAtual] = sala
                    let viz = GridPoint(x: salaAtual.x + d.passo.x, y: salaAtual.y + d.passo.y)
                    santuario.salas[viz]?.portas[d.oposta] = .aberta
                    montarSala(estado: estado)
                    estado.avisar("Porta destrancada.", icone: "lock.open.fill", cor: .bom)
                }
                return
            }
        }
        // Saída do santuário?
        if let e = saidaNo,
           hypot(e.position.x - jogador.position.x, e.position.y - jogador.position.y) < 96 {
            estado.avisar("Você deixou o \(santuario.nome).", icone: "figure.walk", cor: .neutro)
            estado.viajar(para: .refugio)
            return
        }
        // Baú?
        if let b = bauAlvo,
           hypot(b.position.x - jogador.position.x, b.position.y - jogador.position.y) < 90 {
            abrirBau(b, estado: estado)
        }
    }

    private func abrirBau(_ b: SKSpriteNode, estado: GameState) {
        guard let sala = santuario.salas[salaAtual] else { return }
        estado.marcarBauAberto(bioma, salaAtual)
        b.texture = SalaArt.bau(aberto: true)
        b.removeAllActions()
        bauAlvo = nil

        switch sala.conteudo {
        case .amuleto:
            // O item da masmorra: é ele que abre a porta selada do chefe.
            estado.conquistarAmuleto(Biome[bioma].animal)
            estado.iniciarDialogo(DialogueBook.itemDoSantuario(bioma), contexto: bioma)
        case .bau(let t):
            switch t {
            case .coracao: estado.ganharCoracao()
            case .chave: estado.ganharChave(bioma)
            case .mapa, .bussola, .chaveDoGuardiao:
                estado.ganharTesouroDeSantuario(t, em: bioma)
            case .essencia(let v):
                estado.ganharEssencia(CGFloat(v))
                estado.avisar("+\(v) de essência", icone: "bolt.fill", cor: .bom)
            }
        default: break
        }
        for i in 0..<10 {
            let p = SKSpriteNode(texture: Objects.essencia())
            p.position = b.position
            p.zPosition = 560
            p.setScale(0.4)
            mundo.addChild(p)
            let a = Double(i) / 10 * .pi * 2
            p.run(.sequence([.group([.moveBy(x: CGFloat(cos(a)) * 70, y: CGFloat(sin(a)) * 70,
                                             duration: 0.5),
                                     .fadeOut(withDuration: 0.5)]), .removeFromParent()]))
        }
    }

    // MARK: Inimigos, puzzle, portas

    private func atualizarInimigos(delta: TimeInterval, estado: GameState) {
        for e in inimigos where !e.afugentado {
            let encostou = e.passo(delta: delta, jogador: jogador.position, limites: limites)
            if encostou && invulneravel == 0 {
                invulneravel = 1.1
                estado.machucar(1)
                let dx = jogador.position.x - e.position.x
                let dy = jogador.position.y - e.position.y
                let d = max(hypot(dx, dy), 1)
                jogador.position.x += dx / d * 60
                jogador.position.y += dy / d * 60
                jogador.run(.repeat(.sequence([.fadeAlpha(to: 0.3, duration: 0.08),
                                               .fadeAlpha(to: 1, duration: 0.08)]), count: 6))
                if estado.vida <= 0 {
                    estado.desmaiar(bioma)
                    salaAtual = santuario.entrada
                    montarSala(estado: estado)
                    jogador.position = SalaMetrics.centro(salaAtual)
                    cam.position = jogador.position
                }
            }
        }
        inimigos.removeAll { $0.parent == nil }
    }

    /// Dica de contexto: o santuário não tem lista de comandos na tela.
    private func atualizarDica(estado: GameState) {
        var dica: String?
        if let e = saidaNo,
           hypot(e.position.x - jogador.position.x, e.position.y - jogador.position.y) < 96 {
            dica = "E · Sair do santuário"
        } else if let b = bauAlvo,
                  hypot(b.position.x - jogador.position.x, b.position.y - jogador.position.y) < 90 {
            dica = "E · Abrir o baú"
        } else {
            for (d, no) in portas where santuario.salas[salaAtual]?.portas[d] == .trancada {
                if hypot(no.position.x - jogador.position.x,
                         no.position.y - jogador.position.y) < 110 {
                    dica = estado.chaves(bioma) > 0 ? "E · Destrancar" : "Trancada — falta uma chave"
                }
            }
        }
        if estado.dicaInteracao != dica { estado.dicaInteracao = dica }
    }

    private func atualizarPuzzle(estado: GameState) {
        guard case .puzzle = santuario.salas[salaAtual]?.conteudo else { return }
        for no in interativos {
            guard let d = no.userData, (d["ligado"] as? Bool) == false else { continue }
            if hypot(no.position.x - jogador.position.x,
                     no.position.y - jogador.position.y) < 40 {
                d["ligado"] = true
                (no as? SKSpriteNode)?.texture = SalaArt.interruptor(true)
                estado.somarPontos(30)
            }
        }
    }

    private func verificarLimpeza(estado: GameState) {
        guard !estado.salaLimpa(bioma, salaAtual) else { return }
        guard let sala = santuario.salas[salaAtual] else { return }

        switch sala.conteudo {
        case .inimigos, .chave, .chefe:
            guard inimigos.allSatisfy({ $0.afugentado || $0.parent == nil }) else { return }
            guard !inimigos.isEmpty || estado.salaLimpa(bioma, salaAtual) else { return }
            estado.marcarSalaLimpa(bioma, salaAtual)
            if case .chave = sala.conteudo {
                estado.ganharChave(bioma)
            }
            if case .chefe = sala.conteudo {
                concluirSantuario(estado: estado)
                estado.avisar("Um portal se abriu. Pise nele para voltar ao Refúgio.",
                              icone: "sparkles", cor: .conquista)
            }
            montarSala(estado: estado)
        case .puzzle:
            let todos = interativos.allSatisfy { ($0.userData?["ligado"] as? Bool) == true }
            guard !interativos.isEmpty, todos else { return }
            estado.marcarSalaLimpa(bioma, salaAtual)
            estado.avisar("As placas cederam. As portas abriram.",
                          icone: "lock.open.fill", cor: .bom)
            montarSala(estado: estado)
        default: break
        }
    }

    private func verificarPortas(estado: GameState) {
        guard let sala = santuario.salas[salaAtual] else { return }
        for (d, tipo) in sala.portas {
            let liberada: Bool
            switch tipo {
            case .selada: liberada = estado.temAmuleto(Biome[bioma].animal)
            case .doGuardiao: liberada = estado.temChaveDoGuardiao(bioma)
            default: continue
            }
            guard let no = portas[d], liberada else { continue }
            if no.userData?["aberta"] == nil {
                no.userData = NSMutableDictionary()
                no.userData?["aberta"] = true
                no.texture = SalaArt.porta(.aberta, d, bioma)
                no.zPosition = -900
            }
        }
    }

    private func concluirSantuario(estado: GameState) {
        var b = estado.save.biome(bioma)
        guard !b.santuarioConcluido else { return }
        b.santuarioConcluido = true
        estado.save.setBiome(bioma, b)
        estado.ganharCanto(bioma)
        estado.registrarObjetivo(.acesso, em: bioma)
        estado.iniciarDialogo(DialogueBook.guardiao(de: bioma), contexto: bioma)
        estado.salvar()
    }

    /// Quem está mais ao sul aparece na frente — é o que faz o 2.5D funcionar.
    private func ordenarProfundidade() {
        jogador.zPosition = 500 - jogador.position.y * 0.01
        for e in inimigos { e.zPosition = 500 - e.position.y * 0.01 }
        for i in interativos { i.zPosition = 400 - i.position.y * 0.01 }
    }
}
