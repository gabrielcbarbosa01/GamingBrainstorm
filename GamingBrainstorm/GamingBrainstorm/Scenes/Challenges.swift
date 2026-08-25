//
//  Challenges.swift
//  Guardiões dos Biomas
//
//  O desafio característico de cada bioma. Não são cinco variações do mesmo
//  "aperte E": são cinco laços de jogo diferentes — escolta, incêndio que se
//  alastra, corrida contra saqueadores, mergulho com fôlego e escavação às
//  cegas contra o arado.
//

import SpriteKit

class DesafioNode: WorldEntity {
    private(set) var concluido = false

    /// Barra fina exibida acima do nó (confiança, tempo, corte…).
    let barra = SKSpriteNode(color: Palette.gold, size: CGSize(width: 60, height: 5))
    private let barraFundo = SKSpriteNode(color: SKColor(white: 0, alpha: 0.55),
                                          size: CGSize(width: 60, height: 5))

    override var consumivel: Bool { false }

    override init(tile: GridPoint) {
        super.init(tile: tile)
        barraFundo.position = CGPoint(x: 0, y: 46)
        barraFundo.zPosition = 10
        barra.position = CGPoint(x: -30, y: 46)
        barra.anchorPoint = CGPoint(x: 0, y: 0.5)
        barra.zPosition = 11
        addChild(barraFundo)
        addChild(barra)
        mostrarBarra(false)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) não usado") }

    func mostrarBarra(_ visivel: Bool) {
        barra.isHidden = !visivel
        barraFundo.isHidden = !visivel
    }

    func ajustarBarra(_ fracao: CGFloat, cor: SKColor) {
        barra.xScale = max(0.001, min(1, fracao))
        barra.color = cor
    }

    func concluir(estado: GameState, cena: GameScene) {
        guard !concluido else { return }
        concluido = true
        mostrarBarra(false)
        estado.registrarObjetivo(.desafio, em: cena.biomaID)
        cena.efeitoConquista(em: position, cor: Biome[cena.biomaID].palette.accent)
        run(.sequence([.fadeOut(withDuration: 0.8), .removeFromParent()]))
    }
}

// MARK: - Mata Atlântica: a comitiva pela copa

/// Escolta. O grupo de micos segue o rastro do jogador com atraso e entra em
/// pânico se ficar para trás — só funciona em forma de mico.
final class ComitivaNode: DesafioNode {
    private var ativo = false
    private var confianca: CGFloat = 100
    private var seguidores: [SKSpriteNode] = []
    private var rastro: [CGPoint] = []
    private var destino: CGPoint?
    private weak var baliza: SKNode?

    override var raioInteracao: CGFloat { 74 }

    override init(tile: GridPoint) {
        super.init(tile: tile)
        let textura = Creatures.quadros(.micoLeaoDourado, .parado)[0]
        for i in 0..<3 {
            let s = SKSpriteNode(texture: textura)
            s.size = CGSize(width: 46, height: 46)
            s.position = CGPoint(x: CGFloat(i - 1) * 18, y: CGFloat(i % 2) * 8)
            s.zPosition = CGFloat(3 - i)
            addChild(s)
            seguidores.append(s)
            s.run(.repeatForever(.sequence([
                .moveBy(x: 0, y: 4, duration: 0.7 + Double(i) * 0.1),
                .moveBy(x: 0, y: -4, duration: 0.7 + Double(i) * 0.1)
            ])))
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) não usado") }

    override func checar(estado: GameState) -> Interacao {
        if ativo { return Interacao(pode: false, dica: "A comitiva está com você — chegue ao fragmento") }
        guard estado.formaAtual == .micoLeaoDourado else {
            return Interacao(pode: false, dica: "Eles não seguem gente. Vista o Amuleto da Copa (1)")
        }
        return Interacao(pode: true, dica: "Reunir a comitiva")
    }

    override func interagir(estado: GameState, cena: GameScene) -> Bool {
        guard !ativo, estado.formaAtual == .micoLeaoDourado else { return false }
        ativo = true
        confianca = 100
        rastro = [position]
        mostrarBarra(true)
        seguidores.forEach { $0.removeAllActions() }
        criarDestino(cena: cena)
        estado.avisar("A comitiva confia em você. Guie-a saltando até o fragmento marcado.",
                      icone: "figure.walk.motion", cor: .bom)
        return false
    }

    private func criarDestino(cena: GameScene) {
        // Procura um ponto livre a uns 12 tiles daqui.
        var rng = Hashing.rng(tileMundo.x, tileMundo.y, 5150)
        for _ in 0..<40 {
            let a = rng.double(0, .pi * 2)
            let r = rng.double(10, 15)
            let t = GridPoint(x: tileMundo.x + Int(cos(a) * r),
                              y: tileMundo.y + Int(sin(a) * r))
            if cena.terrenoNoTile(t).livre {
                let p = WorldMetrics.center(of: t)
                destino = p
                let marca = SKNode()
                marca.position = p
                marca.zPosition = 150
                let anel = SKSpriteNode(texture: Objects.essencia())
                anel.color = SKColor(hex: 0x6EE39A)
                anel.colorBlendFactor = 0.9
                anel.setScale(2.2)
                marca.addChild(anel)
                let rotulo = SKLabelNode(text: "fragmento seguro")
                rotulo.fontName = "Avenir Next Demi Bold"
                rotulo.fontSize = 13
                rotulo.fontColor = Palette.parchment
                rotulo.position = CGPoint(x: 0, y: 34)
                marca.addChild(rotulo)
                anel.run(.repeatForever(.sequence([
                    .group([.scale(to: 3.4, duration: 1.0), .fadeAlpha(to: 0.2, duration: 1.0)]),
                    .group([.scale(to: 2.2, duration: 0.01), .fadeAlpha(to: 0.9, duration: 0.01)])
                ])))
                cena.adicionarAuxiliar(marca)
                baliza = marca
                return
            }
        }
    }

    override func atualizar(delta: TimeInterval, jogador: CGPoint,
                            estado: GameState, cena: GameScene) {
        guard ativo, !concluido else { return }

        // O grupo se desfaz se você deixar de ser mico.
        if estado.formaAtual != .micoLeaoDourado {
            dispersar(estado: estado, motivo: "Você deixou de ser mico — o grupo se dispersou.")
            return
        }

        // Trilha de migalhas: cada seguidor ocupa uma posição atrasada dela.
        rastro.append(jogador)
        if rastro.count > 260 { rastro.removeFirst(rastro.count - 260) }
        for (i, s) in seguidores.enumerated() {
            let atraso = (i + 1) * 16
            let idx = max(0, rastro.count - 1 - atraso)
            let alvo = rastro[idx]
            s.position = CGPoint(x: alvo.x - position.x, y: alvo.y - position.y)
        }

        let dist = hypot(jogador.x - position.x, jogador.y - position.y)
        if dist > 260 {
            confianca -= CGFloat(delta) * 26
        } else {
            confianca = min(100, confianca + CGFloat(delta) * 12)
        }
        ajustarBarra(confianca / 100, cor: confianca > 45 ? Palette.essence : Palette.danger)
        // A barra acompanha o grupo, que está longe do nó de origem.
        barra.position = CGPoint(x: (rastro.last?.x ?? position.x) - position.x - 30,
                                 y: (rastro.last?.y ?? position.y) - position.y + 52)

        if confianca <= 0 {
            dispersar(estado: estado, motivo: "Você se afastou demais. A comitiva entrou em pânico.")
            return
        }

        if let d = destino, hypot(jogador.x - d.x, jogador.y - d.y) < 76 {
            baliza?.removeFromParent()
            estado.avisar("Comitiva entregue no fragmento. Um grupo a menos isolado.",
                          icone: "checkmark.seal.fill", cor: .conquista)
            concluir(estado: estado, cena: cena)
        }
    }

    private func dispersar(estado: GameState, motivo: String) {
        ativo = false
        mostrarBarra(false)
        baliza?.removeFromParent()
        destino = nil
        seguidores.enumerated().forEach { i, s in
            s.position = CGPoint(x: CGFloat(i - 1) * 18, y: CGFloat(i % 2) * 8)
        }
        estado.somarPontos(-30)
        estado.avisar(motivo, icone: "exclamationmark.triangle.fill", cor: .alerta)
    }
}

// MARK: - Cerrado: o fogo que corre

/// Simulação de propagação. O fogo pula de tile em tile pelo capim seco; a
/// única defesa é abrir aceiro — faixa de terra nua — à frente dele.
final class FocoDeIncendioNode: DesafioNode {
    private var queimando: [GridPoint: TimeInterval] = [:]
    private var queimado: Set<GridPoint> = []
    private var chamas: [GridPoint: SKSpriteNode] = [:]
    private var ativo = false
    private var relogioAlastra: TimeInterval = 0
    private var tempoVivo: TimeInterval = 0

    override var raioInteracao: CGFloat { 90 }

    private let limiteFracasso = 85
    private let intervaloAlastra: TimeInterval = 0.85
    private let duracaoChama: TimeInterval = 4.5

    override func checar(estado: GameState) -> Interacao {
        if ativo {
            return Interacao(pode: false,
                             dica: "Fogo ativo: \(queimando.count) focos · investida do lobo abre aceiro")
        }
        return Interacao(pode: true, dica: "Enfrentar o foco de incêndio")
    }

    override func interagir(estado: GameState, cena: GameScene) -> Bool {
        guard !ativo else { return false }
        ativo = true
        tempoVivo = 0
        acender(tileMundo, cena: cena)
        for d in [GridPoint(x: 1, y: 0), GridPoint(x: 0, y: 1)] {
            acender(tileMundo + d, cena: cena)
        }
        mostrarBarra(true)
        estado.avisar("O fogo pegou. Abra aceiro à frente das chamas — a investida raspa o chão.",
                      icone: "flame.fill", cor: .alerta)
        return false
    }

    private func inflamavel(_ g: GridPoint, cena: GameScene) -> Bool {
        guard !queimado.contains(g), queimando[g] == nil else { return false }
        switch cena.terrenoNoTile(g) {
        case .grama, .gramaAlta, .folhagem, .espinheiro: return true
        default: return false
        }
    }

    private func acender(_ g: GridPoint, cena: GameScene) {
        guard inflamavel(g, cena: cena) else { return }
        queimando[g] = 0
        let s = SKSpriteNode(texture: Objects.ameaca(.queimada))
        s.position = WorldMetrics.center(of: g)
        s.zPosition = 300
        s.setScale(0.7)
        cena.adicionarAuxiliar(s)
        s.run(.repeatForever(.sequence([
            .scaleX(to: 0.8, y: 0.62, duration: 0.22),
            .scaleX(to: 0.62, y: 0.8, duration: 0.22)
        ])))
        chamas[g] = s
    }

    private func apagar(_ g: GridPoint, cena: GameScene) {
        queimando.removeValue(forKey: g)
        chamas[g]?.removeFromParent()
        chamas.removeValue(forKey: g)
        queimado.insert(g)
        // Chão queimado vira terra: não pega fogo de novo.
        cena.alterarTerreno(g, para: .terra, aceiro: false)
    }

    override func atualizar(delta: TimeInterval, jogador: CGPoint,
                            estado: GameState, cena: GameScene) {
        guard ativo, !concluido else { return }
        tempoVivo += delta

        // A investida do lobo-guará raspa o chão e abre aceiro.
        if cena.jogadorInvestindo {
            let g = WorldMetrics.tile(at: jogador)
            for dy in -1...1 {
                for dx in -1...1 {
                    let alvo = GridPoint(x: g.x + dx, y: g.y + dy)
                    if queimando[alvo] == nil && !queimado.contains(alvo) {
                        cena.alterarTerreno(alvo, para: .terra, aceiro: true)
                    }
                }
            }
        }

        // Envelhecimento das chamas
        for (g, idade) in queimando {
            queimando[g] = idade + delta
            if idade + delta > duracaoChama { apagar(g, cena: cena) }
        }

        // Quem fica em cima do fogo se queima.
        let gj = WorldMetrics.tile(at: jogador)
        if queimando[gj] != nil && !cena.jogadorEscondido {
            estado.essencia = max(0, estado.essencia - CGFloat(delta) * 22)
        }

        // Alastramento
        relogioAlastra += delta
        if relogioAlastra >= intervaloAlastra {
            relogioAlastra = 0
            var novos: [GridPoint] = []
            for (g, _) in queimando {
                for d in [GridPoint(x: 1, y: 0), GridPoint(x: -1, y: 0),
                          GridPoint(x: 0, y: 1), GridPoint(x: 0, y: -1)] {
                    let alvo = g + d
                    if inflamavel(alvo, cena: cena),
                       Hashing.unit(alvo.x, alvo.y, UInt64(tempoVivo * 7) &+ 31) < 0.55 {
                        novos.append(alvo)
                    }
                }
            }
            novos.forEach { acender($0, cena: cena) }
        }

        ajustarBarra(CGFloat(queimado.count) / CGFloat(limiteFracasso),
                     cor: queimado.count > limiteFracasso / 2 ? Palette.danger : Palette.gold)

        if queimado.count > limiteFracasso {
            fracassar(estado: estado, cena: cena)
        } else if queimando.isEmpty && tempoVivo > 2 {
            estado.avisar("Fogo cercado. \(queimado.count) tiles queimados — o resto do campo ficou de pé.",
                          icone: "checkmark.shield.fill", cor: .conquista)
            concluir(estado: estado, cena: cena)
        }
    }

    private func fracassar(estado: GameState, cena: GameScene) {
        ativo = false
        Array(queimando.keys).forEach { apagar($0, cena: cena) }
        mostrarBarra(false)
        estado.somarPontos(-120)
        estado.avisar("O fogo passou dos aceiros e correu pelo campo. Vai levar anos.",
                      icone: "flame.fill", cor: .alerta)
        // Volta a ser possível tentar depois de um tempo.
        run(.sequence([.wait(forDuration: 18), .run { [weak self] in
            self?.queimado.removeAll()
            self?.tempoVivo = 0
        }]))
    }
}

// MARK: - Pantanal: vigília dos ninhos

/// Corrida contra o saqueador. Voar é o único jeito de chegar a tempo, mas
/// instalar a proteção exige mão humana — obriga a alternar em pleno voo.
final class NinhoNode: DesafioNode {
    private var tempoRestante: TimeInterval = 40
    private let tempoTotal: TimeInterval = 40
    private var contando = false
    private var perdido = false
    private let saqueador = SKSpriteNode(texture: Objects.ameaca(.trafico))
    private var origemSaqueador = CGPoint.zero

    override var raioInteracao: CGFloat { 70 }

    override init(tile: GridPoint) {
        super.init(tile: tile)
        // O saqueador vem de fora, andando na direção do ninho.
        var rng = Hashing.rng(tile.x, tile.y, 8899)
        let a = rng.double(0, .pi * 2)
        origemSaqueador = CGPoint(x: cos(a) * 620, y: sin(a) * 620)
        saqueador.position = origemSaqueador
        saqueador.zPosition = 140
        saqueador.alpha = 0
        addChild(saqueador)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) não usado") }

    override func checar(estado: GameState) -> Interacao {
        if perdido { return Interacao(pode: false, dica: "Ninho saqueado — perdido") }
        guard estado.formaAtual == .humano else {
            return Interacao(pode: false, dica: "Instalar proteção exige mãos — volte a ser gente (Q)")
        }
        return Interacao(pode: true, dica: "Instalar proteção no ninho")
    }

    override func interagir(estado: GameState, cena: GameScene) -> Bool {
        guard !perdido, estado.formaAtual == .humano else { return false }
        saqueador.run(.sequence([.move(to: origemSaqueador, duration: 1.2), .fadeOut(withDuration: 0.4)]))
        estado.avisar("Ninho protegido com \(Int(tempoRestante))s de sobra.",
                      icone: "checkmark.shield.fill", cor: .conquista)
        concluir(estado: estado, cena: cena)
        return false
    }

    override func atualizar(delta: TimeInterval, jogador: CGPoint,
                            estado: GameState, cena: GameScene) {
        guard !concluido, !perdido else { return }
        let dist = hypot(jogador.x - position.x, jogador.y - position.y)

        // O relógio só começa quando o jogador entra na área — senão os ninhos
        // do mapa inteiro estariam correndo ao mesmo tempo.
        if !contando {
            guard dist < 900 else { return }
            contando = true
            mostrarBarra(true)
            saqueador.run(.fadeIn(withDuration: 0.5))
            estado.avisar("Saqueador a caminho de um ninho. \(Int(tempoTotal))s.",
                          icone: "timer", cor: .alerta)
        }

        tempoRestante -= delta
        let f = CGFloat(tempoRestante / tempoTotal)
        ajustarBarra(f, cor: f > 0.35 ? Palette.gold : Palette.danger)
        // O saqueador caminha até o ninho na mesma proporção do relógio.
        saqueador.position = CGPoint(x: origemSaqueador.x * f, y: origemSaqueador.y * f)

        if tempoRestante <= 0 {
            perdido = true
            mostrarBarra(false)
            estado.somarPontos(-80)
            estado.avisar("O saqueador chegou primeiro. Os filhotes se foram.",
                          icone: "xmark.octagon.fill", cor: .alerta)
            saqueador.run(.sequence([.move(to: origemSaqueador, duration: 2.0),
                                     .fadeOut(withDuration: 0.4)]))
        }
    }
}

// MARK: - Amazônia: malhadeira e fôlego

/// Só se corta a rede submerso, e submerso o fôlego acaba. É a vulnerabilidade
/// real da espécie virada regra de jogo.
final class RedeNode: DesafioNode {
    private var corte: CGFloat = 0
    private let tempoCorte: CGFloat = 2.0
    override var raioInteracao: CGFloat { 66 }

    override init(tile: GridPoint) {
        super.init(tile: tile)
        let s = SKSpriteNode(texture: Objects.ameaca(.pescaIlegal))
        s.zPosition = 5
        addChild(s)
        alpha = 0.85
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) não usado") }

    override func checar(estado: GameState) -> Interacao {
        guard estado.formaAtual == .pirarucu else {
            return Interacao(pode: false, dica: "A rede está no fundo — vista o Amuleto das Águas (4)")
        }
        return Interacao(pode: false, dica: "Submerja (ESPAÇO) e segure E para cortar a rede")
    }

    override func atualizar(delta: TimeInterval, jogador: CGPoint,
                            estado: GameState, cena: GameScene) {
        guard !concluido else { return }
        let dist = hypot(jogador.x - position.x, jogador.y - position.y)
        let podeCortar = dist < raioInteracao && cena.jogadorSubmerso
            && InputManager.shared.interagirSegurado

        if podeCortar {
            corte += CGFloat(delta) / tempoCorte
            mostrarBarra(true)
            ajustarBarra(corte, cor: Palette.essence)
            if corte >= 1 {
                estado.avisar("Malhadeira retirada. Os juvenis passam.",
                              icone: "scissors", cor: .conquista)
                estado.ganharSementes(1)
                concluir(estado: estado, cena: cena)
            }
        } else if corte > 0 {
            // Voltar à tona interrompe o corte: dá para retomar, não para trapacear.
            corte = max(0, corte - CGFloat(delta) * 0.5)
            mostrarBarra(corte > 0.02)
            ajustarBarra(corte, cor: Palette.danger)
        }
    }
}

// MARK: - Pampa: galerias sob o arado

/// Escavação às cegas contra um relógio. Embaixo da terra a visão fecha, e a
/// lâmina do arado avança em linha reta até a galeria.
final class GaleriaNode: DesafioNode {
    private var tempoRestante: TimeInterval = 45
    private let tempoTotal: TimeInterval = 45
    private var contando = false
    private var perdido = false
    private let arado = SKSpriteNode(texture: Objects.ameaca(.monocultura))
    private var origemArado = CGPoint.zero

    override var raioInteracao: CGFloat { 66 }

    override init(tile: GridPoint) {
        super.init(tile: tile)
        var rng = Hashing.rng(tile.x, tile.y, 3131)
        let a = rng.double(0, .pi * 2)
        origemArado = CGPoint(x: cos(a) * 700, y: sin(a) * 700)
        arado.position = origemArado
        arado.zPosition = 140
        arado.alpha = 0
        addChild(arado)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) não usado") }

    override func checar(estado: GameState) -> Interacao {
        if perdido { return Interacao(pode: false, dica: "Galeria desabada") }
        guard estado.formaAtual == .tucoTuco else {
            return Interacao(pode: false, dica: "Só se entra na galeria por baixo — Amuleto do Subsolo (5)")
        }
        return Interacao(pode: true, dica: "Evacuar a galeria")
    }

    override func interagir(estado: GameState, cena: GameScene) -> Bool {
        guard !perdido, estado.formaAtual == .tucoTuco else { return false }
        guard cena.jogadorEscondido else {
            estado.avisar("Você precisa estar escavando: segure ESPAÇO para entrar no subsolo.",
                          icone: "arrow.down.circle", cor: .alerta)
            return false
        }
        arado.run(.fadeOut(withDuration: 0.5))
        estado.avisar("Galeria evacuada antes da lâmina. Ninguém ficou embaixo.",
                      icone: "checkmark.shield.fill", cor: .conquista)
        concluir(estado: estado, cena: cena)
        return false
    }

    override func atualizar(delta: TimeInterval, jogador: CGPoint,
                            estado: GameState, cena: GameScene) {
        guard !concluido, !perdido else { return }
        let dist = hypot(jogador.x - position.x, jogador.y - position.y)
        if !contando {
            guard dist < 900 else { return }
            contando = true
            mostrarBarra(true)
            arado.run(.fadeIn(withDuration: 0.5))
            estado.avisar("O arado abriu linha nesta duna. \(Int(tempoTotal))s até a galeria.",
                          icone: "timer", cor: .alerta)
        }

        tempoRestante -= delta
        let f = CGFloat(tempoRestante / tempoTotal)
        ajustarBarra(f, cor: f > 0.35 ? Palette.gold : Palette.danger)
        arado.position = CGPoint(x: origemArado.x * f, y: origemArado.y * f)

        if tempoRestante <= 0 {
            perdido = true
            mostrarBarra(false)
            estado.somarPontos(-80)
            estado.avisar("A lâmina passou. A galeria desabou com bicho dentro.",
                          icone: "xmark.octagon.fill", cor: .alerta)
            arado.run(.fadeOut(withDuration: 1.5))
        }
    }
}
