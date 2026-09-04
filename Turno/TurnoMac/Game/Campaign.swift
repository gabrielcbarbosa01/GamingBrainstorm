//
//  Campaign.swift
//  TurnoMac
//
//  A campanha inteira como dados: cinco noites no Grand Oxford, os quatro
//  papéis da equipe de limpeza, as provas escondidas sob a sujeira, as
//  melhorias do armário e a dedução final. Sem regras aqui — só conteúdo.
//

import Foundation
import CoreGraphics
import simd

// MARK: - Papéis

enum Role: String, Codable, CaseIterable, Identifiable {
    case camareira, vidros, zelador, recepcao
    var id: String { rawValue }

    var name: String {
        switch self {
        case .camareira: return "Camareira"
        case .vidros: return "Limpadora de vidros"
        case .zelador: return "Zelador"
        case .recepcao: return "Recepção"
        }
    }

    var cover: String {
        switch self {
        case .camareira: return "Alícia, 3 meses de casa"
        case .vidros: return "Bete, terceirizada da fachada"
        case .zelador: return "Damião, manutenção noturna"
        case .recepcao: return "Íris, cobre a folga do porteiro"
        }
    }

    var pitch: String {
        switch self {
        case .camareira: return "Entra em todo quarto sem pedir licença. Pano, spray e vassoura na mão."
        case .vidros: return "Trabalha pendurada na fachada. Vê o hotel por fora, inclusive o que fecharam."
        case .zelador: return "Desce onde ninguém desce: porão, lavanderia, dutos e o quadro de energia."
        case .recepcao: return "Fica onde a informação passa: balcão, livro de registro, telefone e a boca dos hóspedes."
        }
    }

    /// Ferramenta em que este papel é rápido. As outras funcionam, mas rendem menos.
    var mainTool: ToolKind {
        switch self {
        case .camareira: return .pano
        case .vidros: return .rodo
        case .zelador: return .vassoura
        case .recepcao: return .flanela
        }
    }

    var secondaryTool: ToolKind {
        switch self {
        case .camareira: return .vassoura
        case .vidros: return .pano
        case .zelador: return .rodo
        case .recepcao: return .pano
        }
    }

    /// Multiplicador de rendimento da ferramenta.
    func efficiency(for tool: ToolKind) -> Float {
        if tool == mainTool { return 1.0 }
        if tool == secondaryTool { return 0.62 }
        return 0.4
    }

    var uniformColor: SIMD3<Float> {
        switch self {
        case .camareira: return [0.55, 0.30, 0.38]
        case .vidros: return [0.25, 0.45, 0.55]
        case .zelador: return [0.35, 0.36, 0.28]
        case .recepcao: return [0.30, 0.26, 0.42]
        }
    }
}

// MARK: - Áreas

enum AreaID: String, Codable, CaseIterable {
    case corredor7, quarto5, suite7, lobby, porao, fachada, andar8

    var name: String {
        switch self {
        case .corredor7: return "7º andar · corredor"
        case .quarto5: return "Quarto 5"
        case .suite7: return "Suíte 7"
        case .lobby: return "Lobby e recepção"
        case .porao: return "Porão e lavanderia"
        case .fachada: return "Fachada · gôndola"
        case .andar8: return "8º andar"
        }
    }

    var short: String {
        switch self {
        case .corredor7: return "Corredor"
        case .quarto5: return "Quarto 5"
        case .suite7: return "Suíte 7"
        case .lobby: return "Lobby"
        case .porao: return "Porão"
        case .fachada: return "Fachada"
        case .andar8: return "8º andar"
        }
    }

    /// Áreas escuras exigem a lanterna para render bem.
    var isDark: Bool { self == .porao || self == .andar8 }
}

// MARK: - Provas

/// A que pergunta da dedução final a prova responde.
enum CaseQuestion: String, Codable, CaseIterable {
    case quem, porque, como

    var text: String {
        switch self {
        case .quem: return "Quem matou Heitor Vilar?"
        case .porque: return "Por quê?"
        case .como: return "Como entrou na suíte 7?"
        }
    }
}

struct EvidenceSpec {
    let id: String
    let title: String
    let night: Int
    let area: AreaID
    let detail: String
    /// Perguntas que esta prova ajuda a responder.
    let unlocks: [CaseQuestion]
}

// MARK: - Superfícies limpáveis (dados)

enum DirtKind: String, Codable {
    case vidro, poeira, vinho, graxa, cinza, sangueVelho, mofo
}

enum RevealArt: String, Codable {
    case mao, cigarro, cartao, pagina, recibo, chave, cracha, bilhete, arranhao
    case uniforme, planta, ponto, carrinho, gondola, contrato, apolice, nada
}

struct SurfaceSpec {
    let id: String
    let area: AreaID
    let taskTitle: String
    let tool: ToolKind
    let promptVerb: String
    let dirt: DirtKind
    /// Centro, eixos e tamanho no espaço local da área.
    let origin: SIMD3<Float>
    let right: SIMD3<Float>
    let up: SIMD3<Float>
    let width: Float
    let height: Float
    let camera: SIMD3<Float>
    let lookAt: SIMD3<Float>
    let reveal: RevealArt
    let revealRegion: CGRect?
    let evidenceID: String?
    /// Superfície horizontal (chão/mesa) desenha o plano deitado.
    var isHorizontal: Bool { abs(up.y) < 0.5 }
}

// MARK: - Interações não-limpeza

enum InteractionKind: String, Codable {
    case escuta      // encostar o ouvido
    case examinar    // olhar de perto
    case conversa    // falar com alguém
}

struct InteractionSpec {
    let id: String
    let area: AreaID
    let kind: InteractionKind
    let position: SIMD3<Float>
    let prompt: String
    let lines: [String]
    let speaker: String
    let evidenceID: String?
    /// Escutar sob o olhar da gerente é o que mais levanta suspeita.
    let risky: Bool
}

// MARK: - Noites

struct NightSpec {
    let number: Int
    let title: String
    let epigraph: String
    let briefing: [String]
    let areas: [AreaID]
    let seconds: Int
    let surfaces: [SurfaceSpec]
    let interactions: [InteractionSpec]
    /// Texto do fecho da noite, mostrado no relatório.
    let closer: String
    /// Frase do susto desta noite.
    let scare: String
    let unlockText: String
}

// MARK: - Melhorias

struct UpgradeSpec: Identifiable {
    let id: String
    let name: String
    let cost: Int
    let icon: String
    let detail: String
}

// MARK: - Campanha

enum Campaign {
    static let hotel = "Grand Oxford Hotel"
    static let detective = "Delegado Nunes"
    static let victim = "Heitor Vilar"

    // MARK: Suspeitos e respostas

    struct Answer: Identifiable {
        let id: String
        let text: String
        /// Prova que precisa estar no mural para esta resposta aparecer.
        let requires: [String]
        let correct: Bool
    }

    static let answers: [CaseQuestion: [Answer]] = [
        .quem: [
            .init(id: "almeida", text: "Sr. Almeida, o hóspede do quarto 5", requires: ["cartao"], correct: true),
            .init(id: "celeste", text: "Dona Celeste, a gerente", requires: ["cigarro"], correct: false),
            .init(id: "rui", text: "Rui, da manutenção", requires: ["recibo"], correct: false),
            .init(id: "ninguem", text: "Ninguém. Foi mesmo um infarto.", requires: [], correct: false),
        ],
        .porque: [
            .init(id: "venda", text: "Vilar ia reprovar a apólice e derrubar a venda do hotel", requires: ["apolice", "contrato"], correct: true),
            .init(id: "divida", text: "Dívida de jogo entre os dois", requires: [], correct: false),
            .init(id: "incendio", text: "Para esconder o incêndio de 1974 e os quatro mortos", requires: ["planta", "ponto"], correct: false),
            .init(id: "briga", text: "Uma briga que saiu do controle", requires: [], correct: false),
        ],
        .como: [
            .init(id: "cornija", text: "Pela cornija: saiu pela janela do 5 e entrou pela do 7", requires: ["mao", "arranhao"], correct: true),
            .init(id: "mestra", text: "Com a chave mestra antiga do porão", requires: ["chave"], correct: false),
            .init(id: "porta", text: "Pela porta. Vilar o deixou entrar.", requires: [], correct: false),
            .init(id: "duto", text: "Pelo duto de ventilação", requires: [], correct: false),
        ],
    ]

    // MARK: Provas

    static let evidence: [EvidenceSpec] = [
        // Noite 1
        .init(id: "mao", title: "Marca de mão no vidro externo", night: 1, area: .fachada,
              detail: "Uma mão espalmada por FORA do vidro da suíte 7, no sétimo andar. A gôndola não sai do térreo desde segunda.",
              unlocks: [.como]),
        .init(id: "cigarro", title: "Bituca com batom vermelho", night: 1, area: .corredor7,
              detail: "Escondida na poeira do corredor, a dois passos da suíte 7. Dona Celeste fuma escondida na escada.",
              unlocks: [.quem]),
        .init(id: "cartao", title: "Cartão-chave da suíte 7", night: 1, area: .quarto5,
              detail: "Sob a mancha de vinho na mesa do quarto 5. O Sr. Almeida jurou nunca ter entrado na suíte 7.",
              unlocks: [.quem, .como]),
        .init(id: "conversa", title: "Conversa atrás da porta 7", night: 1, area: .corredor7,
              detail: "Celeste e Rui discutindo: Almeida pediu para trocar de quarto com Vilar na véspera, e ela deixou.",
              unlocks: [.quem, .como]),
        // Noite 2
        .init(id: "pagina", title: "Página arrancada do registro", night: 2, area: .lobby,
              detail: "O livro pula da noite 11 para a 13. A marca da caneta na página seguinte ainda mostra: troca 5 ↔ 7, autorizada por C.",
              unlocks: [.quem]),
        .init(id: "recibo", title: "Recibo da gôndola", night: 2, area: .lobby,
              detail: "Aluguel de uma gôndola de fachada pago há três semanas, com a devolução assinada no mesmo dia. Rui diz que ela nunca saiu do térreo.",
              unlocks: [.como]),
        .init(id: "chave", title: "Chave da escada de serviço", night: 2, area: .corredor7,
              detail: "Etiqueta desbotada: 8º ANDAR. A recepção jura que o hotel tem sete.",
              unlocks: [.porque]),
        .init(id: "telefonema", title: "Recado na secretária", night: 2, area: .lobby,
              detail: "Voz de Vilar, na véspera: \"Dona Celeste, eu subi pela escada dos fundos. A gente precisa falar sobre o oitavo andar antes que eu escreva o laudo.\"",
              unlocks: [.porque]),
        // Noite 3
        .init(id: "cracha", title: "Crachá de Heitor Vilar", night: 3, area: .suite7,
              detail: "Caído atrás do rodapé da suíte 7, com o cordão arrebentado. Perito de seguros, credencial vencendo no fim do mês.",
              unlocks: [.porque]),
        .init(id: "bilhete", title: "Bilhete no espelho", night: 3, area: .suite7,
              detail: "Só aparece quando o vapor embaça: OITO, escrito com o dedo por dentro do vidro. A letra não é de Vilar.",
              unlocks: [.porque]),
        .init(id: "arranhao", title: "Arranhões no peitoril", night: 3, area: .fachada,
              detail: "Marcas de sola de sapato social na cornija entre a janela do 5 e a da 7. Sapato de hóspede, não de manutenção.",
              unlocks: [.como]),
        .init(id: "confissao", title: "O que Celeste disse", night: 3, area: .corredor7,
              detail: "\"Minha mãe estava no 803 em 74. Eu não vou deixar arrancarem esse hotel de mim por causa de um laudo.\"",
              unlocks: [.porque]),
        // Noite 4
        .init(id: "uniforme", title: "Uniforme queimado pela metade", night: 4, area: .porao,
              detail: "Macacão de limpador de vidros, meio consumido pelo fogo, guardado num saco atrás do incinerador há cinquenta anos. Bordado: OSVALDO.",
              unlocks: [.porque]),
        .init(id: "planta", title: "Planta baixa original", night: 4, area: .porao,
              detail: "O prédio tem oito andares. O oitavo foi riscado a tinta em 1974, depois do incêndio, e a escada, murada.",
              unlocks: [.porque]),
        .init(id: "ponto", title: "Livro de ponto de 1974", night: 4, area: .porao,
              detail: "Quatro nomes com a saída em branco na noite do incêndio. Um deles, Osvaldo Braga, limpador de vidros, entrada às 22h.",
              unlocks: [.porque]),
        .init(id: "rui", title: "O que Rui confessou", night: 4, area: .porao,
              detail: "\"Me mandaram desativar a gôndola e assinar a devolução sem tirar do lugar. Eu só faço o que a Dona Celeste manda.\"",
              unlocks: [.como]),
        // Noite 5
        .init(id: "carrinho", title: "O carrinho de Osvaldo", night: 5, area: .andar8,
              detail: "Balde, rodo e pano parados no corredor do oitavo andar desde 1974. O rodo está limpo. Alguém continua usando.",
              unlocks: [.porque]),
        .init(id: "gondola", title: "A gôndola de 1974", night: 5, area: .andar8,
              detail: "Ainda pendurada na fachada do oitavo, presa por um cabo só. Foi dela que Osvaldo caiu para dentro do fogo.",
              unlocks: [.porque]),
        .init(id: "contrato", title: "Contrato de venda", night: 5, area: .andar8,
              detail: "Escondido no 803. Almeida assina como coproprietário oculto desde 1996. A venda só se fecha com a apólice aprovada.",
              unlocks: [.quem, .porque]),
        .init(id: "apolice", title: "Apólice com o parecer de Vilar", night: 5, area: .andar8,
              detail: "Parecer escrito à mão na margem: \"Andar não declarado. Risco estrutural. Recomendo NEGAR.\" Data: um dia antes da morte.",
              unlocks: [.porque, .quem]),
    ]

    static func evidence(_ id: String) -> EvidenceSpec {
        evidence.first { $0.id == id } ?? evidence[0]
    }

    static func card(_ id: String) -> EvidenceCard {
        let e = evidence(id)
        return EvidenceCard(id: e.id, title: e.title, detail: e.detail)
    }

    // MARK: Melhorias

    static let upgrades: [UpgradeSpec] = [
        .init(id: "rodo-largo", name: "Rodo largo", cost: 2, icon: "rectangle.compress.vertical",
              detail: "Uma faixa cobre o dobro do vidro. Menos passadas, menos tempo parada."),
        .init(id: "spray", name: "Spray revelador", cost: 3, icon: "sparkles",
              detail: "Marca com um brilho fraco o que ainda está escondido sob a sujeira."),
        .init(id: "lanterna", name: "Lanterna de cabeça", cost: 2, icon: "flashlight.on.fill",
              detail: "Porão e oitavo andar deixam de ser breu. Sem ela, você limpa quase às cegas."),
        .init(id: "luvas", name: "Luvas de borracha", cost: 2, icon: "hand.raised.fill",
              detail: "Trabalho silencioso. A gerente demora mais para desconfiar de você."),
        .init(id: "radio", name: "Rádio da equipe", cost: 3, icon: "antenna.radiowaves.left.and.right",
              detail: "Avisa no iPhone quando Dona Celeste entra no seu andar, mesmo fora de vista."),
    ]

    static func upgrade(_ id: String) -> UpgradeSpec { upgrades.first { $0.id == id }! }

    // MARK: Mensagens do delegado

    static let messages: [String: [String]] = [
        "n1-intro": [
            "Você está dentro. Turno das 22h, sétimo andar.",
            "Heitor Vilar, perito de seguros, morreu na suíte 7 ontem. A gerente chamou de infarto e barrou a perícia.",
            "Faça o serviço direito. Uma camareira que limpa mal chama atenção. Uma que limpa bem vê tudo.",
        ],
        "n2-intro": [
            "Segunda noite. O sétimo está lacrado, então te puseram no lobby.",
            "Melhor assim: é lá que ficam o livro de registro e o telefone.",
        ],
        "n3-intro": [
            "Romperam o lacre da suíte 7 para limpar antes da vistoria. Você entra junto.",
            "Tudo que sair de lá some depois. Hoje é a única chance.",
        ],
        "n4-intro": [
            "Rui aceitou trocar o turno com você no porão. Ele está com medo de alguma coisa.",
            "Se der, faça ele falar. Medo solta a língua mais que ameaça.",
        ],
        "n5-intro": [
            "Última noite. A venda assina amanhã de manhã.",
            "A chave da escada de serviço abre o oitavo. Não existe registro desse andar em lugar nenhum.",
            "Sai antes das seis. Se ela te pegar lá em cima, eu não consigo te tirar.",
        ],
        "mao": ["Uma mão do lado de fora, no sétimo andar? Fotografa isso antes de terminar o vidro."],
        "cigarro": ["Batom vermelho. A Celeste fuma na escada de incêndio, todo mundo sabe. Sozinho não prova nada."],
        "cartao": ["O cartão da 7 no quarto do Almeida. Ele me disse na cara que nunca pisou lá."],
        "conversa": ["Trocaram de quarto na véspera. Então Vilar dormiu no quarto que era do Almeida."],
        "pagina": ["Arrancaram a página justamente da noite da troca. Isso não é descuido."],
        "recibo": ["Alugaram e devolveram a gôndola no mesmo dia, sem usar. Alguém queria a fachada livre."],
        "chave": ["Oitavo andar. Eu tenho a planta do hotel aqui e ela para no sétimo."],
        "telefonema": ["A voz é dele. Vilar ligou avisando que ia escrever o laudo. Morreu antes."],
        "cracha": ["O crachá arrebentado. Teve luta ali dentro, por mais limpo que esteja."],
        "bilhete": ["OITO escrito por dentro do vidro. Escrito por quem, é outra conversa."],
        "arranhao": ["Sapato social na cornija do sétimo andar. Ele andou por fora, com o prédio inteiro embaixo."],
        "confissao": ["A mãe dela morreu lá em cima. Ela não está protegendo o Almeida, está protegendo o hotel."],
        "uniforme": ["Osvaldo Braga. Guardaram o uniforme dele num saco em vez de entregar para a família."],
        "planta": ["Oito andares na planta original. O oitavo foi riscado a tinta, não demolido."],
        "ponto": ["Quatro pessoas entraram e nunca bateram a saída. Isso é um enterro, não um arquivo."],
        "rui": ["Ele confessou a gôndola. É o suficiente para eu abrir inquérito, mas não para prender ninguém."],
        "carrinho": ["Você disse que o rodo está limpo? Depois de cinquenta anos?"],
        "gondola": ["Então a gôndola do Almeida foi devolvida porque já tinha uma pendurada lá em cima."],
        "contrato": ["Coproprietário oculto desde 96. Aí está o motivo inteiro, preto no branco."],
        "apolice": ["\"Recomendo negar\", escrito à mão um dia antes. Ele morreu por causa dessa frase."],
        "descoberto": ["Sai daí. Agora. Ela chamou a segurança."],
    ]

    // MARK: Falas

    static let door7Talk: [String] = [
        "Celeste: \"Rui, eu não posso ter mais gente subindo aqui.\"",
        "Rui: \"A gôndola não sai do térreo desde segunda. Eu já disse isso pra senhora.\"",
        "Celeste: \"O Almeida pediu pra trocar de quarto com o Vilar na véspera. Eu deixei.\"",
        "Celeste: \"Se a polícia souber, fecham o hotel. Ninguém fala nada.\"",
    ]

    static let answeringMachine: [String] = [
        "(bipe) Recado de ontem, 21h04.",
        "Vilar: \"Dona Celeste, é o Heitor. Eu subi pela escada dos fundos hoje.\"",
        "Vilar: \"A gente precisa falar sobre o oitavo andar antes que eu escreva o laudo.\"",
        "Vilar: \"Não é ameaça, é o meu trabalho. Me liga.\" (fim)",
    ]

    static let celesteTalk: [String] = [
        "Celeste: \"Você é nova, então eu vou explicar uma vez.\"",
        "Celeste: \"Minha mãe estava no 803 em setenta e quatro. Eu tinha nove anos.\"",
        "Celeste: \"Levaram três dias pra me dizer, e nunca me devolveram nem a aliança dela.\"",
        "Celeste: \"Eu não vou deixar arrancarem esse hotel de mim por causa de um laudo.\"",
    ]

    static let ruiTalk: [String] = [
        "Rui: \"Você não devia estar aqui embaixo a essa hora.\"",
        "Rui: \"Me mandaram desativar a gôndola e assinar a devolução sem tirar do lugar.\"",
        "Rui: \"Eu perguntei por quê. Ela disse que era pra fachada ficar livre naquela noite.\"",
        "Rui: \"Eu só faço o que a Dona Celeste manda. Nunca subi nesse prédio pra machucar ninguém.\"",
    ]

    static let osvaldoLines: [String] = [
        "(o som de um rodo passando no vidro, um andar acima)",
        "(alguém assobia baixinho no fim do corredor, e para quando você olha)",
        "(o cheiro de sabão velho, forte, e some)",
    ]

    // MARK: As cinco noites

    static let nights: [NightSpec] = [night1, night2, night3, night4, night5]

    static func night(_ n: Int) -> NightSpec { nights[max(0, min(nights.count - 1, n - 1))] }
    static var count: Int { nights.count }

    // MARK: Noite 1

    static let night1 = NightSpec(
        number: 1,
        title: "O sétimo andar",
        epigraph: "Uma camareira que limpa mal chama atenção. Uma que limpa bem vê tudo.",
        briefing: [
            "Vilar morreu na suíte 7 e a gerência barrou a perícia.",
            "Seu turno cobre o corredor do sétimo, o quarto 5 e a fachada.",
            "Faça as três tarefas. O que aparecer embaixo da sujeira, fotografe.",
        ],
        areas: [.corredor7, .quarto5, .fachada],
        seconds: 8 * 60,
        surfaces: [
            SurfaceSpec(id: "n1-corredor", area: .corredor7, taskTitle: "Varrer o corredor da suíte 7",
                        tool: .vassoura, promptVerb: "Varrer o corredor", dirt: .poeira,
                        origin: [0, 0.006, -11.5], right: [1, 0, 0], up: [0, 0, -1], width: 2.9, height: 4.0,
                        camera: [0, 1.9, -8.6], lookAt: [0, 0, -11.5],
                        reveal: .cigarro, revealRegion: CGRect(x: 0.72, y: 0.3, width: 0.16, height: 0.12), evidenceID: "cigarro"),
            SurfaceSpec(id: "n1-mesa", area: .quarto5, taskTitle: "Limpar a mesa do quarto 5",
                        tool: .pano, promptVerb: "Limpar a mesa", dirt: .vinho,
                        origin: [3.6, 0.781, -7.0], right: [1, 0, 0], up: [0, 0, -1], width: 1.2, height: 0.7,
                        camera: [3.6, 1.5, -6.0], lookAt: [3.6, 0.78, -7.0],
                        reveal: .cartao, revealRegion: CGRect(x: 0.55, y: 0.25, width: 0.3, height: 0.42), evidenceID: "cartao"),
            SurfaceSpec(id: "n1-fachada", area: .fachada, taskTitle: "Lavar as janelas do sétimo por fora",
                        tool: .rodo, promptVerb: "Lavar o vidro da suíte 7", dirt: .vidro,
                        origin: [0, 1.5, 0.06], right: [1, 0, 0], up: [0, 1, 0], width: 1.8, height: 1.7,
                        camera: [0, 1.6, 1.3], lookAt: [0, 1.5, 0],
                        reveal: .mao, revealRegion: CGRect(x: 0.52, y: 0.34, width: 0.3, height: 0.34), evidenceID: "mao"),
        ],
        interactions: [
            InteractionSpec(id: "n1-porta7", area: .corredor7, kind: .escuta, position: [1.5, 1.2, -12],
                            prompt: "Escutar atrás da porta da suíte 7", lines: door7Talk, speaker: "Porta 7",
                            evidenceID: "conversa", risky: true),
        ],
        closer: "As luzes do corredor piscaram e, do lado de fora do sétimo andar, alguém estava limpando o vidro.",
        scare: "silhueta",
        unlockText: "Dona Celeste te deu a chave do carrinho. Amanhã você cobre o lobby."
    )

    // MARK: Noite 2

    static let night2 = NightSpec(
        number: 2,
        title: "O livro de registro",
        epigraph: "Todo hotel mente com educação. O livro é onde a mentira precisa ser escrita.",
        briefing: [
            "Lacraram o sétimo. Te puseram no lobby, que é onde ficam os papéis.",
            "Balcão, tapete e a porta giratória. E o corredor do sétimo, que ainda é seu.",
            "O livro de registro fica no balcão. Limpe em volta dele.",
        ],
        areas: [.lobby, .corredor7],
        seconds: 8 * 60,
        surfaces: [
            SurfaceSpec(id: "n2-balcao", area: .lobby, taskTitle: "Lustrar o balcão de mármore",
                        tool: .flanela, promptVerb: "Lustrar o balcão", dirt: .poeira,
                        origin: [0, 1.101, -3.0], right: [1, 0, 0], up: [0, 0, -1], width: 3.0, height: 0.9,
                        camera: [0, 1.6, -1.7], lookAt: [0, 1.1, -3.0],
                        reveal: .pagina, revealRegion: CGRect(x: 0.6, y: 0.3, width: 0.28, height: 0.42), evidenceID: "pagina"),
            SurfaceSpec(id: "n2-tapete", area: .lobby, taskTitle: "Aspirar o tapete do lobby",
                        tool: .vassoura, promptVerb: "Aspirar o tapete", dirt: .poeira,
                        origin: [0, 0.007, -7.5], right: [1, 0, 0], up: [0, 0, -1], width: 4.4, height: 4.4,
                        camera: [0, 2.0, -4.2], lookAt: [0, 0, -7.5],
                        reveal: .recibo, revealRegion: CGRect(x: 0.2, y: 0.62, width: 0.22, height: 0.16), evidenceID: "recibo"),
            SurfaceSpec(id: "n2-vidro", area: .corredor7, taskTitle: "Limpar o vidro do fim do corredor",
                        tool: .rodo, promptVerb: "Limpar o vidro", dirt: .vidro,
                        origin: [0, 1.5, -15.98], right: [1, 0, 0], up: [0, 1, 0], width: 0.8, height: 1.6,
                        camera: [0, 1.6, -14.75], lookAt: [0, 1.5, -16],
                        reveal: .chave, revealRegion: CGRect(x: 0.3, y: 0.08, width: 0.4, height: 0.18), evidenceID: "chave"),
        ],
        interactions: [
            InteractionSpec(id: "n2-secretaria", area: .lobby, kind: .examinar, position: [1.3, 1.15, -3.4],
                            prompt: "Ouvir a secretária eletrônica", lines: answeringMachine, speaker: "Secretária",
                            evidenceID: "telefonema", risky: true),
        ],
        closer: "No quadro atrás do balcão, o Grand Oxford de 1974 tem uma fileira de janelas a mais do que o prédio de hoje.",
        scare: "quadro",
        unlockText: "A chave da escada de serviço agora é sua. Amanhã abrem a suíte 7 para a limpeza."
    )

    // MARK: Noite 3

    static let night3 = NightSpec(
        number: 3,
        title: "A suíte 7",
        epigraph: "Limparam o quarto três vezes. Sujeira boa some. Sujeira de verdade volta.",
        briefing: [
            "Romperam o lacre para limpar antes da vistoria. Você entra junto.",
            "Carpete, espelho e a janela por fora, da gôndola.",
            "Depois de hoje não sobra nada dessa suíte.",
        ],
        areas: [.suite7, .fachada, .corredor7],
        seconds: 8 * 60,
        surfaces: [
            SurfaceSpec(id: "n3-carpete", area: .suite7, taskTitle: "Limpar o carpete da suíte 7",
                        tool: .vassoura, promptVerb: "Limpar o carpete", dirt: .sangueVelho,
                        origin: [3.7, 0.007, -12.0], right: [1, 0, 0], up: [0, 0, -1], width: 3.4, height: 2.6,
                        camera: [3.7, 1.9, -10.75], lookAt: [3.7, 0, -12.2],
                        reveal: .cracha, revealRegion: CGRect(x: 0.06, y: 0.1, width: 0.2, height: 0.16), evidenceID: "cracha"),
            SurfaceSpec(id: "n3-espelho", area: .suite7, taskTitle: "Limpar o espelho do banheiro",
                        tool: .pano, promptVerb: "Limpar o espelho", dirt: .mofo,
                        origin: [6.34, 1.55, -13.2], right: [0, 0, 1], up: [0, 1, 0], width: 1.0, height: 1.2,
                        camera: [5.3, 1.6, -13.2], lookAt: [6.34, 1.55, -13.2],
                        reveal: .bilhete, revealRegion: CGRect(x: 0.22, y: 0.42, width: 0.56, height: 0.3), evidenceID: "bilhete"),
            SurfaceSpec(id: "n3-peitoril", area: .fachada, taskTitle: "Lavar a janela da suíte por fora",
                        tool: .rodo, promptVerb: "Lavar a janela da suíte", dirt: .vidro,
                        origin: [0, 1.5, 0.06], right: [1, 0, 0], up: [0, 1, 0], width: 1.8, height: 1.7,
                        camera: [0, 1.6, 1.3], lookAt: [0, 1.5, 0],
                        reveal: .arranhao, revealRegion: CGRect(x: 0.12, y: 0.06, width: 0.7, height: 0.16), evidenceID: "arranhao"),
        ],
        interactions: [
            InteractionSpec(id: "n3-celeste", area: .corredor7, kind: .conversa, position: [0.6, 1.3, -5.0],
                            prompt: "Deixar Dona Celeste falar", lines: celesteTalk, speaker: "Dona Celeste",
                            evidenceID: "confissao", risky: false),
        ],
        closer: "O espelho embaçou de novo sozinho, com o box seco, e a palavra apareceu escrita por dentro do vidro.",
        scare: "espelho",
        unlockText: "Rui trocou o turno com você. Amanhã é o porão."
    )

    // MARK: Noite 4

    static let night4 = NightSpec(
        number: 4,
        title: "O porão",
        epigraph: "Todo hotel guarda embaixo o que não cabe na recepção.",
        briefing: [
            "Lavanderia, incinerador e o basculante. Rui está lá embaixo e está com medo.",
            "É escuro. Sem lanterna você vai limpar quase às cegas.",
            "Faça ele falar. Medo solta mais a língua que ameaça.",
        ],
        areas: [.porao],
        seconds: 8 * 60,
        surfaces: [
            SurfaceSpec(id: "n4-chao", area: .porao, taskTitle: "Esfregar o chão da lavanderia",
                        tool: .vassoura, promptVerb: "Esfregar o chão", dirt: .graxa,
                        origin: [0, 0.007, -6.0], right: [1, 0, 0], up: [0, 0, -1], width: 4.6, height: 4.2,
                        camera: [0, 2.0, -2.9], lookAt: [0, 0, -6.0],
                        reveal: .uniforme, revealRegion: CGRect(x: 0.55, y: 0.14, width: 0.34, height: 0.3), evidenceID: "uniforme"),
            SurfaceSpec(id: "n4-incinerador", area: .porao, taskTitle: "Limpar o filtro do incinerador",
                        tool: .pano, promptVerb: "Limpar o filtro", dirt: .cinza,
                        origin: [-3.4, 1.3, -8.4], right: [1, 0, 0], up: [0, 1, 0], width: 1.4, height: 1.0,
                        camera: [-3.4, 1.5, -7.1], lookAt: [-3.4, 1.3, -8.4],
                        reveal: .planta, revealRegion: CGRect(x: 0.18, y: 0.2, width: 0.62, height: 0.56), evidenceID: "planta"),
            SurfaceSpec(id: "n4-basculante", area: .porao, taskTitle: "Lavar o basculante",
                        tool: .rodo, promptVerb: "Lavar o basculante", dirt: .vidro,
                        origin: [3.6, 2.0, -8.42], right: [1, 0, 0], up: [0, 1, 0], width: 1.6, height: 0.8,
                        camera: [3.6, 1.9, -7.1], lookAt: [3.6, 2.0, -8.42],
                        reveal: .ponto, revealRegion: CGRect(x: 0.3, y: 0.2, width: 0.42, height: 0.56), evidenceID: "ponto"),
        ],
        interactions: [
            InteractionSpec(id: "n4-rui", area: .porao, kind: .conversa, position: [2.6, 1.3, -4.0],
                            prompt: "Falar com Rui", lines: ruiTalk, speaker: "Rui",
                            evidenceID: "rui", risky: false),
        ],
        closer: "O incinerador acendeu sozinho por três segundos. Rui olhou para ele e disse que isso acontece desde sempre.",
        scare: "incinerador",
        unlockText: "A chave mestra antiga abre a escada murada. Amanhã, o oitavo andar."
    )

    // MARK: Noite 5

    static let night5 = NightSpec(
        number: 5,
        title: "O oitavo andar",
        epigraph: "Cinquenta anos de poeira, e o rodo dele está limpo.",
        briefing: [
            "A venda assina amanhã de manhã. É hoje ou nunca.",
            "O oitavo não tem luz, não tem registro e não tem saída fácil.",
            "Se ela te pegar lá em cima, eu não consigo te tirar.",
        ],
        areas: [.andar8],
        seconds: 8 * 60,
        surfaces: [
            SurfaceSpec(id: "n5-corredor", area: .andar8, taskTitle: "Abrir caminho no corredor do oitavo",
                        tool: .vassoura, promptVerb: "Varrer a cinza do corredor", dirt: .cinza,
                        origin: [0, 0.006, -8.0], right: [1, 0, 0], up: [0, 0, -1], width: 2.9, height: 6.0,
                        camera: [0, 1.9, -4.2], lookAt: [0, 0, -8.0],
                        reveal: .carrinho, revealRegion: CGRect(x: 0.3, y: 0.55, width: 0.4, height: 0.22), evidenceID: "carrinho"),
            SurfaceSpec(id: "n5-janela", area: .andar8, taskTitle: "Limpar a janela selada do fim",
                        tool: .rodo, promptVerb: "Limpar a janela selada", dirt: .cinza,
                        origin: [0, 1.5, -13.98], right: [1, 0, 0], up: [0, 1, 0], width: 1.4, height: 1.7,
                        camera: [0, 1.6, -12.7], lookAt: [0, 1.5, -14],
                        reveal: .gondola, revealRegion: CGRect(x: 0.2, y: 0.24, width: 0.6, height: 0.5), evidenceID: "gondola"),
            SurfaceSpec(id: "n5-803", area: .andar8, taskTitle: "Limpar o chão do 803",
                        tool: .pano, promptVerb: "Limpar o chão do 803", dirt: .cinza,
                        origin: [3.9, 0.008, -10.0], right: [1, 0, 0], up: [0, 0, -1], width: 3.2, height: 2.6,
                        camera: [3.9, 1.8, -8.75], lookAt: [3.9, 0, -10.3],
                        reveal: .contrato, revealRegion: CGRect(x: 0.55, y: 0.5, width: 0.34, height: 0.34), evidenceID: "contrato"),
        ],
        interactions: [
            InteractionSpec(id: "n5-cofre", area: .andar8, kind: .examinar, position: [5.9, 1.2, -11.2],
                            prompt: "Abrir a pasta em cima da cômoda do 803",
                            lines: ["A pasta de Vilar estava aqui em cima o tempo todo.",
                                    "Apólice do Grand Oxford, com o parecer escrito à mão na margem.",
                                    "\"Andar não declarado. Risco estrutural. Recomendo NEGAR.\"",
                                    "A data é de um dia antes de ele morrer."],
                            speaker: "Pasta de Vilar", evidenceID: "apolice", risky: false),
        ],
        closer: "Do fim do corredor veio o barulho de um rodo passando no vidro, devagar, do lado de fora do oitavo andar.",
        scare: "osvaldo",
        unlockText: ""
    )

    // MARK: Finais

    static func verdictText(correct: Int) -> String {
        switch correct {
        case 3:
            return "O Sr. Almeida, coproprietário oculto desde 1996, trocou de quarto com Vilar na véspera para ficar com a chave antiga da suíte 7. Saiu pela janela do quarto 5, andou dez metros de cornija no sétimo andar e entrou pela janela da 7. Matou o perito que ia negar a apólice e derrubar a venda. Dona Celeste escondeu tudo, não por dinheiro, mas porque a mãe dela morreu no 803 em 1974 e o hotel é a única coisa que sobrou dela. O oitavo andar foi aberto por ordem judicial na quinta-feira. Retiraram quatro corpos. Um deles ainda vestia macacão de limpador de vidros."
        case 2:
            return "O inquérito foi aberto e Almeida respondeu em liberdade. Faltou fechar um ponto, e o advogado dele encontrou exatamente esse ponto. O oitavo andar foi lacrado de novo, agora com papel timbrado do juiz."
        case 1:
            return "O delegado levou o que você trouxe, e o promotor devolveu. Uma prova sozinha não sustenta uma acusação. O Grand Oxford foi vendido no fim do mês."
        default:
            return "Sem provas que se sustentem, o caso voltou a ser um infarto. O hotel mudou de dono e o sétimo andar ganhou carpete novo."
        }
    }

    static func endingTitle(_ e: Ending) -> String {
        switch e {
        case .descoberta: return "Descoberta"
        case .turnoEncerrado: return "Fim do turno"
        case .casoResolvido: return "Caso encerrado"
        case .casoAberto: return "Caso arquivado"
        }
    }
}

enum Ending: String, Codable {
    case descoberta, turnoEncerrado, casoResolvido, casoAberto
}
