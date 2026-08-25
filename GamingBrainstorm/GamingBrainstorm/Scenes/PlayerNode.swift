//
//  PlayerNode.swift
//  Guardiões dos Biomas
//
//  O jogador tem altura real. O nó raiz fica no chão (é ele que colide contra
//  a grade); o sprite sobe e desce sobre ele, e a sombra encolhe conforme o
//  bicho se afasta do solo. É isso que faz o salto do mico ser legível.
//

import SpriteKit

enum EstadoCorpo: Equatable {
    case andando
    case pulando      // mico: em arco
    case investindo   // lobo: disparada curta
    case planando     // arara: sustentando altura
    case voando       // harpia: voo livre
    case mergulhado   // pirarucu: submerso
    case cavando      // tuco-tuco: no subsolo

    /// O corpo está acima do chão?
    var noAr: Bool {
        self == .pulando || self == .planando || self == .voando
    }

    /// O corpo está abaixo do chão (invisível para ameaças)?
    var enterrado: Bool {
        self == .cavando || self == .mergulhado
    }
}

@MainActor
final class PlayerNode: SKNode {

    // MARK: Física vertical

    private(set) var altura: CGFloat = 0
    private(set) var velZ: CGFloat = 0
    private(set) var estado: EstadoCorpo = .andando
    private(set) var tempoNoEstado: TimeInterval = 0
    /// Saltos ainda disponíveis antes de tocar o chão de novo.
    private(set) var saltosRestantes: Int = 0

    private let gravidade: CGFloat = 1500
    private let forcaSalto: CGFloat = 360
    private let alturaPlanar: CGFloat = 62
    private let alturaVoo: CGFloat = 96
    private let profundidade: CGFloat = -12

    /// Impulso horizontal aplicado por investida e salto, decai sozinho.
    private(set) var impulso: CGVector = .zero

    // MARK: Nós

    private let sombra = SKSpriteNode()
    private let sprite = SKSpriteNode()
    private var formaDesenhada: AnimalForm = .humano
    private var animAtual: Creatures.Anim = .parado
    private var espelhado = false

    override init() {
        super.init()
        zPosition = 500

        sombra.texture = Self.texturaSombra
        sombra.size = CGSize(width: 40, height: 15)
        sombra.zPosition = -1
        sombra.position = CGPoint(x: 0, y: -22)
        addChild(sombra)

        sprite.size = CGSize(width: Creatures.canvas, height: Creatures.canvas)
        addChild(sprite)

        aplicarForma(.humano, forcar: true)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) não usado") }

    private static let texturaSombra: SKTexture = Draw.texture(width: 64, height: 26) { ctx in
        Draw.ellipse(ctx, CGRect(x: 0, y: 0, width: 64, height: 26),
                     SKColor(white: 0, alpha: 0.30))
    }

    // MARK: Forma e animação

    func aplicarForma(_ f: AnimalForm, forcar: Bool = false) {
        guard forcar || f != formaDesenhada else { return }
        formaDesenhada = f
        // Harpia é maior que os outros: a envergadura precisa aparecer.
        let escala: CGFloat = f == .harpia ? 1.3 : 1.0
        sprite.size = CGSize(width: Creatures.canvas * escala,
                             height: Creatures.canvas * escala)
        animAtual = .parado
        tocar(.parado, forcar: true)
    }

    private func tocar(_ anim: Creatures.Anim, forcar: Bool = false) {
        guard forcar || anim != animAtual else { return }
        animAtual = anim
        let quadros = Creatures.quadros(formaDesenhada, anim)
        sprite.removeAction(forKey: "anim")
        sprite.texture = quadros[0]
        guard quadros.count > 1 else { return }
        sprite.run(.repeatForever(.animate(with: quadros,
                                           timePerFrame: anim.passoTempo,
                                           resize: false, restore: false)),
                   withKey: "anim")
    }

    func olharPara(dx: CGFloat) {
        guard dx != 0 else { return }
        let novo = dx < 0
        guard novo != espelhado else { return }
        espelhado = novo
        sprite.xScale = novo ? -1 : 1
    }

    // MARK: Verbos

    /// Salto do mico. Devolve false se não havia salto disponível.
    @discardableResult
    func saltar(direcao: CGVector) -> Bool {
        guard saltosRestantes > 0 else { return false }
        saltosRestantes -= 1
        velZ = saltosRestantes == 0 ? forcaSalto * 0.86 : forcaSalto
        estado = .pulando
        tempoNoEstado = 0
        // O impulso à frente é o que transforma o pulo em travessia.
        impulso = CGVector(dx: direcao.dx * 190, dy: direcao.dy * 190)
        return true
    }

    func investir(direcao: CGVector) {
        estado = .investindo
        tempoNoEstado = 0
        let d = (direcao.dx == 0 && direcao.dy == 0)
            ? CGVector(dx: espelhado ? -1 : 1, dy: 0) : direcao
        impulso = CGVector(dx: d.dx * 520, dy: d.dy * 520)
    }

    func entrar(_ novo: EstadoCorpo) {
        guard estado != novo else { return }
        estado = novo
        tempoNoEstado = 0
        if novo == .andando { velZ = 0 }
    }

    // MARK: Passo de simulação

    /// Integra a altura e escolhe a animação. O movimento horizontal e a
    /// colisão ficam na cena, que é quem conhece o terreno.
    func simular(delta: TimeInterval, andando: Bool) {
        let d = CGFloat(delta)
        tempoNoEstado += delta

        switch estado {
        case .pulando:
            velZ -= gravidade * d
            altura += velZ * d
            if altura <= 0 {
                altura = 0
                velZ = 0
                aterrissar()
            }

        case .planando:
            altura += (alturaPlanar - altura) * min(1, d * 5)
            velZ = 0

        case .voando:
            altura += (alturaVoo - altura) * min(1, d * 4)
            velZ = 0

        case .cavando, .mergulhado:
            altura += (profundidade - altura) * min(1, d * 8)
            velZ = 0

        case .andando, .investindo:
            if altura > 0 {
                velZ -= gravidade * d
                altura = max(0, altura + velZ * d)
                if altura == 0 { velZ = 0; aterrissar() }
            } else {
                altura = 0
                saltosRestantes = max(saltosRestantes, formaDesenhada.verbo == .pulo ? 2 : 0)
            }
            if estado == .investindo && tempoNoEstado > 0.34 { entrar(.andando) }
        }

        // O impulso decai — sem isso a investida nunca acabaria.
        let decaimento = CGFloat(pow(0.0016, delta))
        impulso.dx *= decaimento
        impulso.dy *= decaimento
        if abs(impulso.dx) < 4 { impulso.dx = 0 }
        if abs(impulso.dy) < 4 { impulso.dy = 0 }

        atualizarVisual(andando: andando)
    }

    private func aterrissar() {
        if formaDesenhada.verbo == .pulo { saltosRestantes = 2 }
        if estado == .pulando {
            entrar(.andando)
            // Amortecimento: o sprite achata um instante ao tocar o chão.
            sprite.removeAction(forKey: "pouso")
            sprite.run(.sequence([
                .scaleX(to: 1.18, y: 0.82, duration: 0.06),
                .scaleX(to: 1.0, y: 1.0, duration: 0.12)
            ]), withKey: "pouso")
            sprite.xScale = espelhado ? -1 : 1
        }
    }

    private func atualizarVisual(andando: Bool) {
        sprite.position = CGPoint(x: 0, y: altura)

        // Sombra: encolhe e clareia com a altura; some no subsolo.
        let f = max(0, min(1, altura / 110))
        sombra.setScale(1 - f * 0.55)
        sombra.alpha = altura < 0 ? 0 : (1 - f * 0.65)

        // Submerso ou enterrado, o corpo fica parcialmente escondido.
        switch estado {
        case .mergulhado:
            sprite.alpha = 0.55
            sprite.colorBlendFactor = 0.35
            sprite.color = SKColor(hex: 0x2E5E62)
        case .cavando:
            sprite.alpha = 0.45
            sprite.colorBlendFactor = 0.45
            sprite.color = SKColor(hex: 0x4A3A28)
        default:
            sprite.alpha = 1
            sprite.colorBlendFactor = 0
        }

        // Escolha da animação
        switch estado {
        case .andando:
            tocar(andando ? .andar : .parado)
        case .pulando, .investindo, .planando, .voando, .cavando, .mergulhado:
            tocar(.especial)
        }
    }
}
