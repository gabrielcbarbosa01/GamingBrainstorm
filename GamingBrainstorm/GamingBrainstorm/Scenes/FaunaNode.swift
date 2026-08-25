//
//  FaunaNode.swift
//  Guardiões dos Biomas
//
//  Bicho de fundo: perambula, foge de quem chega perto e pode ser observado.
//  Chegar perto de um animal arisco é um problema de jogo — na forma humana
//  ele dispara, mas quem está enterrado ou submerso passa despercebido.
//

import SpriteKit

final class FaunaNode: WorldEntity {
    let spec: FaunaSpec
    private let sprite: SKSpriteNode
    private let rotulo: SKLabelNode
    private var alvo: CGPoint
    private var fugindo = false
    private var tempoAteNovoAlvo: TimeInterval = 0
    private var observadoAgora = false

    override var consumivel: Bool { false }
    override var raioInteracao: CGFloat { 96 }

    init(tile: GridPoint, spec: FaunaSpec) {
        self.spec = spec
        self.sprite = SKSpriteNode(texture: FaunaArt.quadros(spec)[0])
        self.alvo = WorldMetrics.center(of: tile)
        self.rotulo = SKLabelNode(text: spec.nome)
        super.init(tile: tile)

        sprite.size = CGSize(width: FaunaArt.canvas, height: FaunaArt.canvas)
        addChild(sprite)
        sprite.run(.repeatForever(.animate(with: FaunaArt.quadros(spec),
                                           timePerFrame: 0.22, resize: false, restore: false)))

        rotulo.fontName = "Avenir Next Demi Bold"
        rotulo.fontSize = 12
        rotulo.fontColor = Palette.parchment
        rotulo.position = CGPoint(x: 0, y: 40)
        rotulo.alpha = 0
        addChild(rotulo)
        zPosition = 120
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) não usado") }

    override func atualizar(delta: TimeInterval, jogador: CGPoint,
                            estado: GameState, cena: GameScene) {
        let dx = jogador.x - position.x, dy = jogador.y - position.y
        let dist = hypot(dx, dy)

        // Quem está no subsolo ou submerso não assusta ninguém; quem está em
        // forma animal assusta menos que gente.
        let disfarce: CGFloat
        if cena.jogadorEscondido { disfarce = 0 }
        else if estado.formaAtual == .humano { disfarce = 1.0 }
        else { disfarce = 0.5 }
        let raioFuga = spec.arisco * disfarce

        if raioFuga > 0 && dist < raioFuga {
            if !fugindo {
                fugindo = true
                rotulo.run(.fadeOut(withDuration: 0.2))
            }
            // Corre para longe do jogador.
            let n = max(dist, 1)
            alvo = CGPoint(x: position.x - dx / n * 400, y: position.y - dy / n * 400)
        } else if fugindo && dist > raioFuga * 1.6 {
            fugindo = false
        }

        // Nome aparece quando você consegue chegar perto sem espantar.
        let deveMostrar = !fugindo && dist < raioInteracao
        if deveMostrar != observadoAgora {
            observadoAgora = deveMostrar
            rotulo.run(.fadeAlpha(to: deveMostrar ? 0.9 : 0, duration: 0.25))
        }

        tempoAteNovoAlvo -= delta
        if tempoAteNovoAlvo <= 0 && !fugindo {
            tempoAteNovoAlvo = Double.random(in: 2.5...6.0)
            let r = CGFloat.random(in: 60...260)
            let a = Double.random(in: 0..<(.pi * 2))
            alvo = CGPoint(x: position.x + cos(a) * r, y: position.y + sin(a) * r)
        }

        // Passo em direção ao alvo, respeitando o terreno da espécie.
        let vx = alvo.x - position.x, vy = alvo.y - position.y
        let d = hypot(vx, vy)
        guard d > 4 else { return }
        let v = spec.velocidade * (fugindo ? 1.6 : 0.45) * CGFloat(delta)
        let passo = CGPoint(x: position.x + vx / d * v, y: position.y + vy / d * v)
        if aceita(terreno: cena.terreno(em: passo)) {
            position = passo
            if abs(vx) > 1 { sprite.xScale = vx < 0 ? -1 : 1 }
        } else {
            tempoAteNovoAlvo = 0
        }
    }

    /// Peixe e boto ficam na água; os outros, fora dela.
    private func aceita(terreno t: Terrain) -> Bool {
        if spec.aquatico { return t == .agua || t == .charco || t == .areia }
        return t.livre && t != .agua
    }

    override func checar(estado: GameState) -> Interacao {
        if fugindo { return Interacao(pode: false, dica: "\(spec.nome) — assustado, se afastando") }
        let jaVisto = estado.save.codex.contains("fauna_" + spec.id)
        return Interacao(pode: true, dica: jaVisto ? "Anotar avistamento" : "Registrar \(spec.nome)")
    }

    override func interagir(estado: GameState, cena: GameScene) -> Bool {
        let chave = "fauna_" + spec.id
        if estado.save.codex.contains(chave) {
            estado.somarPontos(15)
            estado.avisar("\(spec.nome) — avistamento anotado.", icone: "binoculars.fill", cor: .neutro)
        } else {
            estado.descobrirCodex(chave)
            estado.somarPontos(140)
            estado.ganharSementes(1)
            estado.avisar("Primeiro registro: \(spec.nome). \(spec.nota)",
                          icone: "sparkle.magnifyingglass", cor: .conquista)
            cena.efeitoConquista(em: position, cor: spec.corDetalhe)
        }
        return false
    }
}
