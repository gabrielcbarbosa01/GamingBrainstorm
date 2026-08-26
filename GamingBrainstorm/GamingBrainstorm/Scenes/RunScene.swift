//
//  RunScene.swift
//  Guardiões dos Biomas
//
//  Motor das provas arcade. Cena própria, câmera travada, rolagem contínua.
//  Cinco modos partilham o mesmo laço: pista de faixas, fuga com parede de
//  fogo atrás, voo por vãos, travessia de troncos e túnel escuro.
//

import SpriteKit

@MainActor
final class RunScene: SKScene {

    weak var estado: GameState?
    private let config: Corrida
    private var modo: ModoCorrida { config.modo }

    // O layout deriva do tamanho real da cena. Com tamanho virtual fixo e
    // aspectFill, numa janela larga sobrava pouca altura visível e o corredor
    // ficava fora da tela — era isso que sumia com o mico.
    /// Interno de propósito: é o número que precisa ser verificável.
    var yJogador: CGFloat { -size.height / 2 + 200 }
    private var yNascimento: CGFloat { size.height / 2 + 140 }
    private var yMorte: CGFloat { -size.height / 2 - 170 }
    var limiteVoo: CGFloat { size.height / 2 - 80 }
    private let faixasX: [CGFloat] = [-155, 0, 155]

    private let fundo = SKNode()
    private let mundo = SKNode()
    private let jogador = PlayerNode()
    private var vinheta: SKSpriteNode?
    private var paredeFogo: SKSpriteNode?

    private var ultimoTempo: TimeInterval = 0
    private var faixa = 1
    private var velocidade: CGFloat = 0
    private var progresso: CGFloat = 0
    private var vidas: Int
    private var coletados = 0
    private var folga: CGFloat = 1
    private var invulneravel: TimeInterval = 0
    private var distanciaDesdeSpawn: CGFloat = 0
    private var ultimoDX: CGFloat = 0
    private var publicarEm: TimeInterval = 0

    // Voo
    private var vy: CGFloat = 0

    // Travessia
    private var fileiraAtual = 0
    private var fileiras: [FileiraTravessia] = []
    private var pulando = false
    private var plataformaAtual: SKSpriteNode?
    private var tempoNaPlataforma: TimeInterval = 0

    // MARK: Tipos internos

    private enum TipoObstaculo { case baixo, alto, premio, lamina }

    private final class Obstaculo: SKSpriteNode {
        var tipo: TipoObstaculo = .baixo
        var faixa: Int = 1
        var fatorVelocidade: CGFloat = 1
    }

    private struct FileiraTravessia {
        var indice: Int
        var y: CGFloat
        var tipoJacare: Bool
        var seguro: Bool
        var plataformas: [SKSpriteNode]
        var velocidade: CGFloat
    }

    // MARK: Ciclo de vida

    init(config: Corrida, estado: GameState) {
        self.config = config
        self.estado = estado
        self.vidas = config.vidas
        super.init(size: CGSize(width: 900, height: 700))
        // resizeFill: a cena assume o tamanho da janela, e o layout acompanha.
        scaleMode = .resizeFill
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) não usado") }

    private var montado = false

    override func didMove(to view: SKView) {
        InputManager.shared.start()
        guard !montado else {
            InputManager.shared.limparTeclas()
            return
        }
        montado = true

        backgroundColor = Biome[config.bioma].palette.sky
        addChild(fundo)
        addChild(mundo)

        montarFundo()

        jogador.saltoLivre = true
        jogador.aplicarForma(config.forma, forcar: true)
        jogador.position = CGPoint(x: 0, y: yJogador)
        jogador.zPosition = 500
        jogador.setScale(1.35)
        addChild(jogador)

        if modo == .tunel {
            let v = SKSpriteNode(texture: RunArt.vinheta())
            v.size = CGSize(width: 1700, height: 1700)
            v.zPosition = 800
            v.alpha = 0.96
            addChild(v)
            vinheta = v
        }

        if modo == .fuga {
            let f = SKSpriteNode(texture: RunArt.paredeDeFogo())
            f.size = CGSize(width: 1200, height: 360)
            f.zPosition = 400
            f.position = CGPoint(x: 0, y: yJogador - 400)
            addChild(f)
            paredeFogo = f
        }

        if modo == .voo { jogador.position = .zero }
        if modo == .travessia { montarTravessia() }
        velocidade = config.velocidadeBase
        InputManager.shared.start()
    }

    private func montarFundo() {
        let textura = modo == .travessia ? RunArt.rio(config.bioma) : RunArt.pista(config.bioma)
        for i in 0..<6 {
            let s = SKSpriteNode(texture: textura)
            s.size = CGSize(width: 1800, height: 560)
            s.position = CGPoint(x: 0, y: CGFloat(i) * 560 - 560)
            s.zPosition = -100
            fundo.addChild(s)
        }
    }

    // MARK: Laço principal

    override func update(_ currentTime: TimeInterval) {
        guard let estado, let sessao = estado.corrida else { return }
        let delta = ultimoTempo == 0 ? 1.0 / 60.0 : min(currentTime - ultimoTempo, 1.0 / 20.0)
        ultimoTempo = currentTime

        processarTeclas(estado: estado, sessao: sessao)
        guard sessao.fase == .correndo else { return }

        invulneravel = max(0, invulneravel - delta)

        switch modo {
        case .pistas, .fuga, .tunel: atualizarPista(delta: delta, estado: estado)
        case .voo: atualizarVoo(delta: delta, estado: estado)
        case .travessia: atualizarTravessia(delta: delta, estado: estado)
        }

        publicarEm += delta
        if publicarEm > 0.1 {
            publicarEm = 0
            publicar(estado)
        }
    }

    private func processarTeclas(estado: GameState, sessao: CorridaSessao) {
        for acao in InputManager.shared.consumirAcoes() {
            switch (sessao.fase, acao) {
            case (.instrucoes, .interagir), (.instrucoes, .habilidade):
                estado.corrida?.fase = .correndo
            case (.fim, .interagir), (.fim, .habilidade):
                estado.encerrarCorrida()
            case (_, .menu):
                estado.encerrarCorrida()
            case (.correndo, .habilidade):
                if modo == .travessia { pularFileira() }
                else if modo != .voo { jogador.saltar(direcao: .zero) }
            default:
                break
            }
        }
    }

    /// Detecta o toque em A/D (e setas) uma vez, não a cada frame.
    private func trocaDeFaixa() -> Int {
        let dx = InputManager.shared.direcao.dx
        defer { ultimoDX = dx }
        guard ultimoDX == 0, dx != 0 else { return 0 }
        return dx < 0 ? -1 : 1
    }

    // MARK: Modo pista (Mata Atlântica, Cerrado, Pampa)

    private func atualizarPista(delta: TimeInterval, estado: GameState) {
        velocidade = config.velocidadeBase + config.aceleracao * progresso / 20
        let avanco = velocidade * CGFloat(delta)
        progresso += avanco / 40

        rolarFundo(avanco)

        // Troca de faixa
        let t = trocaDeFaixa()
        if t != 0 { faixa = max(0, min(2, faixa + t)) }
        let alvoX = faixasX[faixa]
        jogador.position.x += (alvoX - jogador.position.x) * CGFloat(min(1, delta * 14))
        // Mantém o corredor na faixa inferior visível, mesmo se a janela mudar.
        jogador.position.y = yJogador
        jogador.simular(delta: delta, andando: true)

        // Rolagem e limpeza
        for caso in mundo.children {
            guard let o = caso as? Obstaculo else { continue }
            o.position.y -= avanco * o.fatorVelocidade
            if o.position.y < yMorte { o.removeFromParent() }
        }

        // Nascimento de obstáculos, mais apertado conforme acelera.
        distanciaDesdeSpawn += avanco
        let intervalo: CGFloat = max(240, 460 - progresso * 0.32)
        if distanciaDesdeSpawn > intervalo {
            distanciaDesdeSpawn = 0
            nascerLinha()
        }

        checarColisaoPista(estado: estado)

        if modo == .fuga { atualizarFogo(delta: delta, estado: estado) }

        if progresso >= config.meta { terminar(sucesso: true, estado: estado) }
    }

    private func nascerLinha() {
        var rng = SeededRandom(seed: UInt64(progresso * 97) &+ 13)
        // Nunca fecha as três faixas: sempre há uma saída.
        let livre = rng.int(0, 2)
        for f in 0..<3 where f != livre {
            guard rng.chance(0.78) else { continue }
            let alto = rng.chance(modo == .tunel ? 0.35 : 0.42)
            let lamina = modo == .tunel && rng.chance(0.25)
            let o = Obstaculo(texture: lamina ? RunArt.lamina()
                                              : (alto ? RunArt.alto(config.bioma)
                                                      : RunArt.baixo(config.bioma)))
            o.tipo = lamina ? .lamina : (alto ? .alto : .baixo)
            o.faixa = f
            o.fatorVelocidade = lamina ? 1.5 : 1
            o.size = lamina ? CGSize(width: 130, height: 90)
                            : (alto ? CGSize(width: 120, height: 150)
                                    : CGSize(width: 120, height: 64))
            o.position = CGPoint(x: faixasX[f], y: yNascimento)
            o.zPosition = 200
            mundo.addChild(o)
            if lamina {
                // Aviso: um brilho vermelho que desce à frente da lâmina.
                let aviso = SKSpriteNode(color: Palette.danger.withAlphaComponent(0.30),
                                         size: CGSize(width: 130, height: 34))
                aviso.position = CGPoint(x: faixasX[f], y: yNascimento + 90)
                aviso.zPosition = 199
                mundo.addChild(aviso)
                aviso.run(.sequence([.fadeOut(withDuration: 1.4), .removeFromParent()]))
            }
        }
        // Prêmio na faixa que ficou livre.
        if rng.chance(0.65) {
            let p = Obstaculo(texture: RunArt.premio(config.bioma))
            p.tipo = .premio
            p.faixa = livre
            p.size = CGSize(width: 48, height: 48)
            p.position = CGPoint(x: faixasX[livre], y: yNascimento + 40)
            p.zPosition = 210
            mundo.addChild(p)
        }
    }

    private func checarColisaoPista(estado: GameState) {
        for caso in mundo.children {
            guard let o = caso as? Obstaculo else { continue }
            guard abs(o.position.y - yJogador) < 46, o.faixa == faixa else { continue }

            if o.tipo == .premio {
                coletados += 1
                estado.somarPontos(20)
                o.removeFromParent()
                continue
            }
            guard invulneravel == 0 else { continue }
            // Saltar limpa o que é baixo; o que é alto tem que ser desviado.
            if o.tipo == .baixo && jogador.altura > 34 { continue }
            bater(estado: estado)
        }
    }

    // MARK: Fuga do fogo (Cerrado)

    private func atualizarFogo(delta: TimeInterval, estado: GameState) {
        folga = min(1, folga + CGFloat(delta) * 0.055)
        paredeFogo?.position.y = yJogador - 150 - folga * 330
        if folga <= 0 { terminar(sucesso: false, estado: estado) }
    }

    // MARK: Voo (Pantanal)

    private func atualizarVoo(delta: TimeInterval, estado: GameState) {
        velocidade = config.velocidadeBase + config.aceleracao * progresso / 20
        let avanco = velocidade * CGFloat(delta)
        progresso += avanco / 40
        rolarFundo(avanco)

        // Subir segurando espaço, cair soltando.
        if InputManager.shared.habilidadeSegurada {
            vy += 2400 * CGFloat(delta)
        } else {
            vy -= 1750 * CGFloat(delta)
        }
        vy = max(-560, min(560, vy))
        jogador.position.y += vy * CGFloat(delta)

        // Deriva lateral livre
        jogador.position.x += InputManager.shared.direcao.dx * 430 * CGFloat(delta)
        jogador.position.x = max(-(size.width / 2 - 60), min(size.width / 2 - 60, jogador.position.x))

        let limite = limiteVoo
        if jogador.position.y > limite { jogador.position.y = limite; vy = 0 }
        if jogador.position.y < -limite {
            jogador.position.y = -limite
            vy = 0
            if invulneravel == 0 { bater(estado: estado) }
        }
        jogador.simular(delta: delta, andando: true)
        jogador.entrar(.planando)

        for caso in mundo.children {
            guard let o = caso as? Obstaculo else { continue }
            o.position.y -= avanco
            if o.position.y < yMorte { o.removeFromParent(); continue }
            let perto = abs(o.position.y - jogador.position.y) < 52
                && abs(o.position.x - jogador.position.x) < (o.size.width / 2 + 22)
            guard perto else { continue }
            if o.tipo == .premio {
                coletados += 1
                estado.somarPontos(25)
                o.removeFromParent()
            } else if invulneravel == 0 {
                bater(estado: estado)
            }
        }

        distanciaDesdeSpawn += avanco
        if distanciaDesdeSpawn > max(300, 520 - progresso * 0.3) {
            distanciaDesdeSpawn = 0
            nascerBarreiraDeVoo()
        }

        if progresso >= config.meta { terminar(sucesso: true, estado: estado) }
    }

    /// Parede de manduvis com um vão por onde passar.
    private func nascerBarreiraDeVoo() {
        var rng = SeededRandom(seed: UInt64(progresso * 89) &+ 7)
        let centroVao = rng.cg(-260, 260)
        let meioVao: CGFloat = max(110, 190 - progresso * 0.06)

        for lado in [CGFloat(-1), 1] {
            let borda: CGFloat = lado < 0 ? -520 : 520
            let interno = centroVao + lado * meioVao
            let largura = abs(borda - interno)
            guard largura > 40 else { continue }
            let o = Obstaculo(texture: RunArt.alto(config.bioma))
            o.tipo = .alto
            o.size = CGSize(width: largura, height: 150)
            o.position = CGPoint(x: (borda + interno) / 2, y: yNascimento)
            o.zPosition = 200
            mundo.addChild(o)
        }
        let p = Obstaculo(texture: RunArt.premio(config.bioma))
        p.tipo = .premio
        p.size = CGSize(width: 48, height: 48)
        p.position = CGPoint(x: centroVao, y: yNascimento)
        p.zPosition = 210
        mundo.addChild(p)
    }

    // MARK: Travessia (Amazônia)

    private func montarTravessia() {
        jogador.position = CGPoint(x: 0, y: yJogador)
        for i in 0...30 { criarFileira(i) }
    }

    private func criarFileira(_ i: Int) {
        let y = yJogador + CGFloat(i) * 120
        let seguro = i % 9 == 0
        var rng = SeededRandom(seed: UInt64(i) &* 7717 &+ 3)
        var fila = FileiraTravessia(indice: i, y: y, tipoJacare: rng.chance(0.42),
                                    seguro: seguro, plataformas: [], velocidade: 0)

        if seguro {
            let banco = SKSpriteNode(color: Biome[.amazonia].palette.sand,
                                     size: CGSize(width: 1200, height: 96))
            banco.position = CGPoint(x: 0, y: y)
            banco.zPosition = 100
            mundo.addChild(banco)
            fila.plataformas = [banco]
        } else {
            let direcao: CGFloat = rng.chance(0.5) ? 1 : -1
            fila.velocidade = direcao * rng.cg(70, 150)
            let quantidade = rng.int(2, 3)
            for k in 0..<quantidade {
                let largura = fila.tipoJacare ? 150 : Int(rng.cg(190, 280))
                let no: SKSpriteNode
                if fila.tipoJacare, let spec = FaunaSpec.porId("jacare") {
                    no = SKSpriteNode(texture: FaunaArt.quadros(spec)[0])
                    no.size = CGSize(width: 170, height: 130)
                } else {
                    no = SKSpriteNode(texture: RunArt.troncoFlutuante(largura))
                    no.size = CGSize(width: CGFloat(largura), height: 70)
                }
                no.position = CGPoint(x: -520 + CGFloat(k) * 420 + rng.cg(-60, 60), y: y)
                no.zPosition = 100
                mundo.addChild(no)
                fila.plataformas.append(no)
            }
        }
        fileiras.append(fila)
    }

    private func pularFileira() {
        guard !pulando else { return }
        pulando = true
        plataformaAtual = nil
        tempoNaPlataforma = 0
        fileiraAtual += 1
        progresso = CGFloat(fileiraAtual)
        if fileiraAtual + 12 > fileiras.count { criarFileira(fileiras.count) }
        jogador.saltar(direcao: .zero)
    }

    private func atualizarTravessia(delta: TimeInterval, estado: GameState) {
        // Plataformas deslizam e dão a volta.
        for i in fileiras.indices where !fileiras[i].seguro {
            for p in fileiras[i].plataformas {
                p.position.x += fileiras[i].velocidade * CGFloat(delta)
                if p.position.x > 700 { p.position.x = -700 }
                if p.position.x < -700 { p.position.x = 700 }
            }
        }

        jogador.position.x += InputManager.shared.direcao.dx * 320 * CGFloat(delta)
        jogador.simular(delta: delta, andando: true)

        // A câmera acompanha a fileira em que o jogador está.
        guard fileiras.indices.contains(fileiraAtual) else { return }
        let alvoY = fileiras[fileiraAtual].y
        let deslocamento = (yJogador - alvoY) - mundo.position.y
        mundo.position.y += deslocamento * CGFloat(min(1, delta * 9))
        fundo.position.y = mundo.position.y * 0.4

        // Enquanto está no ar, nada é decidido.
        if jogador.altura > 2 { return }
        if pulando {
            pulando = false
            avaliarPouso(estado: estado)
        }

        // Em cima de plataforma, o jogador é carregado junto.
        if let p = plataformaAtual {
            jogador.position.x += fileiras[fileiraAtual].velocidade * CGFloat(delta)
            tempoNaPlataforma += delta
            // Jacaré não é ponte: afunda se você demorar.
            if fileiras[fileiraAtual].tipoJacare && tempoNaPlataforma > 2.4 {
                p.run(.sequence([.fadeAlpha(to: 0.15, duration: 0.35),
                                 .wait(forDuration: 1.6),
                                 .fadeAlpha(to: 1, duration: 0.3)]))
                plataformaAtual = nil
                cair(estado: estado)
            }
        }

        if abs(jogador.position.x) > 470 { cair(estado: estado) }
        if CGFloat(fileiraAtual) >= config.meta { terminar(sucesso: true, estado: estado) }
    }

    private func avaliarPouso(estado: GameState) {
        guard fileiras.indices.contains(fileiraAtual) else { return }
        let fila = fileiras[fileiraAtual]
        if fila.seguro {
            plataformaAtual = fila.plataformas.first
            tempoNaPlataforma = 0
            estado.somarPontos(30)
            return
        }
        for p in fila.plataformas where p.alpha > 0.5 {
            if abs(p.position.x - jogador.position.x) < p.size.width / 2 + 10 {
                plataformaAtual = p
                tempoNaPlataforma = 0
                coletados += 1
                estado.somarPontos(25)
                return
            }
        }
        cair(estado: estado)
    }

    private func cair(estado: GameState) {
        guard invulneravel == 0 else { return }
        // Volta para o último banco de areia.
        var destino = 0
        var i = fileiraAtual
        while i >= 0 {
            if fileiras.indices.contains(i), fileiras[i].seguro { destino = i; break }
            i -= 1
        }
        fileiraAtual = destino
        progresso = CGFloat(destino)
        jogador.position.x = 0
        plataformaAtual = fileiras.indices.contains(destino) ? fileiras[destino].plataformas.first : nil
        bater(estado: estado)
    }

    // MARK: Comum

    private func rolarFundo(_ avanco: CGFloat) {
        for s in fundo.children {
            s.position.y -= avanco
            if s.position.y < -size.height / 2 - 560 { s.position.y += 560 * 6 }
        }
    }

    private func bater(estado: GameState) {
        invulneravel = 1.3
        jogador.run(.repeat(.sequence([.fadeAlpha(to: 0.25, duration: 0.09),
                                       .fadeAlpha(to: 1, duration: 0.09)]), count: 7))
        run(.sequence([.run { [weak self] in self?.tremer() }]))

        if modo == .fuga {
            folga -= 0.3
            if folga <= 0 { terminar(sucesso: false, estado: estado) }
            return
        }
        vidas -= 1
        if vidas <= 0 { terminar(sucesso: false, estado: estado) }
    }

    private func tremer() {
        let n = SKAction.sequence([
            .moveBy(x: 14, y: 0, duration: 0.04), .moveBy(x: -26, y: 0, duration: 0.06),
            .moveBy(x: 12, y: 0, duration: 0.04)
        ])
        mundo.run(n)
        fundo.run(n)
    }

    private func terminar(sucesso: Bool, estado: GameState) {
        guard estado.corrida?.fase == .correndo else { return }
        estado.corrida?.fase = .fim(sucesso: sucesso)
        publicar(estado)
        estado.concluirCorrida(sucesso: sucesso,
                               progresso: Int(progresso),
                               coletados: coletados)
    }

    private func publicar(_ estado: GameState) {
        estado.corrida?.progresso = progresso
        estado.corrida?.coletados = coletados
        estado.corrida?.vidas = vidas
        estado.corrida?.folga = folga
    }
}
