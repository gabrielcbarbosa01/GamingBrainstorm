//
//  AnimalForm.swift
//  Guardiões dos Biomas
//
//  Os amuletos são o coração da progressão: cada um transforma o guardião em
//  um animal ameaçado e concede a travessia que abre o próximo bioma.
//

import SpriteKit

enum AnimalForm: String, CaseIterable, Codable, Identifiable {
    case humano
    case micoLeaoDourado
    case loboGuara
    case oncaPintada
    case araraAzul
    case pirarucu
    case tucoTuco
    case harpia

    var id: String { rawValue }

    /// Nome exibido em diálogos e HUD.
    var nome: String {
        switch self {
        case .humano: return "Guardiã(o)"
        case .micoLeaoDourado: return "Mico-leão-dourado"
        case .loboGuara: return "Lobo-guará"
        case .oncaPintada: return "Onça-pintada"
        case .araraAzul: return "Ararinha-azul"
        case .pirarucu: return "Pirarucu"
        case .tucoTuco: return "Tuco-tuco"
        case .harpia: return "Harpia"
        }
    }

    var nomeCientifico: String {
        switch self {
        case .humano: return "Homo sapiens"
        case .micoLeaoDourado: return "Leontopithecus rosalia"
        case .loboGuara: return "Chrysocyon brachyurus"
        case .oncaPintada: return "Panthera onca"
        case .araraAzul: return "Cyanopsitta spixii"
        case .pirarucu: return "Arapaima gigas"
        case .tucoTuco: return "Ctenomys flamarioni"
        case .harpia: return "Harpia harpyja"
        }
    }

    var amuleto: String {
        switch self {
        case .humano: return "Sem amuleto"
        case .micoLeaoDourado: return "Amuleto da Copa"
        case .loboGuara: return "Amuleto da Campina"
        case .oncaPintada: return "Amuleto da Sombra"
        case .araraAzul: return "Amuleto do Vento"
        case .pirarucu: return "Amuleto das Águas"
        case .tucoTuco: return "Amuleto do Subsolo"
        case .harpia: return "Coroa da Harpia"
        }
    }

    var habilidade: String {
        switch self {
        case .humano: return "Interagir e usar equipamentos"
        case .micoLeaoDourado: return "Escalar cipós e copas"
        case .loboGuara: return "Investida por espinheiros"
        case .oncaPintada: return "Passo Invisível pelo matagal denso"
        case .araraAzul: return "Voar sobre abismos"
        case .pirarucu: return "Nadar em águas profundas"
        case .tucoTuco: return "Escavar túneis na terra dura"
        case .harpia: return "Sobrevoar tudo e mergulhar"
        }
    }

    var descricaoHabilidade: String {
        switch self {
        case .humano:
            return "Só a forma humana conversa com pessoas, usa o rastreador e opera equipamentos de campo."
        case .micoLeaoDourado:
            return "Atravessa cipoais fechados. Ágil e rápido, mas frágil diante de ameaças."
        case .loboGuara:
            return "Rompe cerrados espinhosos em disparada e fareja esconderijos num raio amplo."
        case .oncaPintada:
            return "Atravessa matagal denso sem fazer barulho. Nenhuma ameaça percebe sua passagem, mas a habilidade não ataca — só reposiciona e observa."
        case .araraAzul:
            return "Voa sobre abismos e barrancos. No ar, a visão de campo se amplia."
        case .pirarucu:
            return "Nada em rios e lagos. Fora d'água, se arrasta com dificuldade."
        case .tucoTuco:
            return "Escava a terra compactada. No subsolo, fica invisível para caçadores."
        case .harpia:
            return "A forma final. Nenhuma barreira do mundo a detém, e do alto ela enxerga o território inteiro."
        }
    }

    /// Terreno especial que apenas esta forma consegue atravessar.
    var travessia: Terrain? {
        switch self {
        case .humano: return nil
        case .micoLeaoDourado: return .cipos
        case .loboGuara: return .espinheiro
        case .oncaPintada: return .matagalDenso
        case .araraAzul: return .abismo
        case .pirarucu: return .agua
        case .tucoTuco: return .terraDura
        case .harpia: return nil
        }
    }

    /// A harpia não abre uma barreira específica: ela passa por cima de todas.
    var atravessaTudo: Bool { self == .harpia }

    /// Velocidade base em pontos por segundo.
    var velocidade: CGFloat {
        switch self {
        case .humano: return 210
        case .micoLeaoDourado: return 260
        case .loboGuara: return 300
        case .oncaPintada: return 245
        case .araraAzul: return 280
        case .pirarucu: return 170
        case .tucoTuco: return 165
        case .harpia: return 330
        }
    }

    /// Essência gasta por segundo enquanto transformado.
    var custoEssencia: CGFloat {
        switch self {
        case .humano: return 0
        case .micoLeaoDourado: return 3.0
        case .loboGuara: return 3.6
        case .oncaPintada: return 3.8
        case .araraAzul: return 4.6
        case .pirarucu: return 3.2
        case .tucoTuco: return 3.4
        case .harpia: return 6.5
        }
    }

    /// Multiplicador de zoom da câmera — a arara enxerga mais longe.
    var zoomCamera: CGFloat {
        switch self {
        case .araraAzul: return 1.28
        case .harpia: return 1.55
        case .tucoTuco: return 0.92
        default: return 1.0
        }
    }

    /// Raio (em pontos) no qual a forma revela segredos escondidos no mapa.
    var raioFaro: CGFloat {
        switch self {
        case .loboGuara: return 520
        case .harpia: return 1100
        case .tucoTuco: return 300
        default: return 0
        }
    }

    /// Caçadores não percebem quem está no Passo Invisível ou escavando o subsolo.
    var invisivelParaAmeacas: Bool { self == .oncaPintada || self == .tucoTuco }

    var corPrimaria: SKColor {
        switch self {
        case .humano: return SKColor(hex: 0xE0C08A)
        case .micoLeaoDourado: return SKColor(hex: 0xE8952C)
        case .loboGuara: return SKColor(hex: 0xC96A2E)
        case .oncaPintada: return SKColor(hex: 0xD9A233)
        case .araraAzul: return SKColor(hex: 0x2F6FD8)
        case .pirarucu: return SKColor(hex: 0x4E6E62)
        case .tucoTuco: return SKColor(hex: 0x9A7A4E)
        case .harpia: return SKColor(hex: 0x585E68)
        }
    }

    var corSecundaria: SKColor {
        switch self {
        case .humano: return SKColor(hex: 0x3E6A4E)
        case .micoLeaoDourado: return SKColor(hex: 0xF6C860)
        case .loboGuara: return SKColor(hex: 0x2A2620)
        case .oncaPintada: return SKColor(hex: 0x2A1E14)
        case .araraAzul: return SKColor(hex: 0xF2D24E)
        case .pirarucu: return SKColor(hex: 0xC24A44)
        case .tucoTuco: return SKColor(hex: 0x5E4A32)
        case .harpia: return SKColor(hex: 0xE8C24E)
        }
    }

    /// Emoji usado como ícone rápido na roda de amuletos.
    var icone: String {
        switch self {
        case .humano: return "🧭"
        case .micoLeaoDourado: return "🐒"
        case .loboGuara: return "🐺"
        case .oncaPintada: return "🐆"
        case .araraAzul: return "🦜"
        case .pirarucu: return "🐟"
        case .tucoTuco: return "🐹"
        case .harpia: return "🦅"
        }
    }

    /// Os seis amuletos da história principal, na ordem dos atalhos 1..6.
    static var amuletos: [AnimalForm] {
        [.micoLeaoDourado, .loboGuara, .oncaPintada, .araraAzul, .pirarucu, .tucoTuco]
    }

    /// Tudo que o jogador pode vestir, incluindo a recompensa final no atalho 7.
    static var vestiveis: [AnimalForm] { amuletos + [.harpia] }

    // MARK: - Verbo ativo

    /// O que a barra de espaço faz nesta forma. É isto que diferencia jogar de
    /// mico e jogar de lobo: cada bicho tem um movimento próprio, não só uma cor.
    var verbo: FormVerb {
        switch self {
        case .humano: return .nenhum
        case .micoLeaoDourado: return .pulo
        case .loboGuara: return .investida
        case .oncaPintada: return .espreitar
        case .araraAzul: return .planar
        case .pirarucu: return .arranco
        case .tucoTuco: return .escavar
        case .harpia: return .voo
        }
    }
}

/// Movimento ativo de cada forma, acionado pela barra de espaço.
enum FormVerb {
    case nenhum
    case pulo        // mico: arco alto, atravessa qualquer barreira em pleno ar
    case investida   // lobo: disparada curta que rompe espinheiros e espanta ameaças
    case espreitar   // onça: passo silencioso que atravessa o matagal sem alertar ameaças
    case planar      // arara: mantém no ar enquanto houver essência
    case arranco     // pirarucu: mergulha e dispara embaixo d'água
    case escavar     // tuco-tuco: entra no subsolo e some do mapa
    case voo         // harpia: voo livre, sem barreira nenhuma

    var nome: String {
        switch self {
        case .nenhum: return "—"
        case .pulo: return "Salto"
        case .investida: return "Investida"
        case .espreitar: return "Espreita"
        case .planar: return "Planar"
        case .arranco: return "Arranco"
        case .escavar: return "Escavar"
        case .voo: return "Voo"
        }
    }

    var dica: String {
        switch self {
        case .nenhum: return "Esta forma não tem movimento especial."
        case .pulo: return "ESPAÇO salta em arco. No ar você passa por cima de água, cipó e abismo."
        case .investida: return "ESPAÇO dispara para frente, rompe espinheiros e afasta ameaças."
        case .espreitar: return "ESPAÇO avança em silêncio: atravessa o matagal denso e ameaças não notam."
        case .planar: return "Segure ESPAÇO para se manter no ar. Consome essência rápido."
        case .arranco: return "ESPAÇO mergulha: dentro d'água você fica veloz e invisível."
        case .escavar: return "Segure ESPAÇO para ir ao subsolo: atravessa quase tudo e ninguém te vê."
        case .voo: return "Segure ESPAÇO para voar. Nada neste mundo te barra."
        }
    }
}
