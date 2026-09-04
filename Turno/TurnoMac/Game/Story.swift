//
//  Story.swift
//  TurnoMac
//
//  Conteúdo narrativo do vertical slice: Grand Oxford Hotel, 7º andar.
//  Tudo aqui é texto/tabela; regras ficam em GameState e GameLoop.
//

import Foundation

enum Story {
    static let hotel = "Grand Oxford Hotel"
    static let floor = "7º andar"
    static let detective = "Delegado Nunes"
    static let shiftSeconds: Int = 9 * 60

    struct Suspect: Identifiable, Equatable {
        let id: String
        let name: String
        let role: String
    }

    static let suspects: [Suspect] = [
        .init(id: "almeida", name: "Sr. Almeida", role: "Hóspede do quarto 5"),
        .init(id: "celeste", name: "Dona Celeste", role: "Gerente do hotel"),
        .init(id: "rui", name: "Rui", role: "Manutenção e gôndola das janelas"),
    ]
    static let culprit = "almeida"

    static let evidence: [EvidenceCard] = [
        .init(id: "mao", title: "Marca de mão do lado de fora",
              detail: "Uma mão espalmada no vidro externo do 7º andar, entre as janelas do 5 e do 7. Ninguém usou a gôndola esta semana."),
        .init(id: "cigarro", title: "Bituca com batom vermelho",
              detail: "Escondida na poeira do corredor, a dois passos da suíte 7. Dona Celeste fuma escondida."),
        .init(id: "cartao", title: "Cartão-chave da suíte 7",
              detail: "Embaixo da mancha de vinho na mesa do quarto 5. O Sr. Almeida jurou nunca ter entrado no 7."),
        .init(id: "conversa", title: "Conversa atrás da porta 7",
              detail: "Celeste: \"O Almeida pediu pra trocar de quarto com o Vilar na véspera. Eu deixei. Se a polícia souber, fecham o hotel.\""),
    ]

    static func card(_ id: String) -> EvidenceCard {
        evidence.first { $0.id == id }!
    }

    /// Mensagens do delegado no celular, por gatilho.
    static let messages: [String: [String]] = [
        "intro": [
            "Você está dentro. Turno das 22h, 7º andar.",
            "Heitor Vilar morreu na suíte 7 ontem. A gerente, Dona Celeste, barrou a perícia e chamou de infarto.",
            "Faça o serviço direito. Uma camareira que limpa mal chama atenção. Uma que limpa bem vê tudo.",
        ],
        "mao": [
            "Uma mão do lado de FORA? No sétimo andar?",
            "Fotografa isso antes de terminar o vidro. E confere com a manutenção quem mexeu na gôndola.",
        ],
        "cigarro": [
            "Batom vermelho. A Celeste fuma na escada de incêndio, todo mundo sabe.",
            "Mas isso sozinho não prova nada. Continue.",
        ],
        "cartao": [
            "Cartão da 7 no quarto 5. O Almeida me disse na cara que nunca pisou naquela suíte.",
            "Não deixe ele perceber que você achou.",
        ],
        "conversa": [
            "Trocaram de quarto na véspera. Então o Vilar dormiu no quarto que era do Almeida.",
            "E o cartão antigo do Almeida abria a 7. Está fechando.",
        ],
        "silhueta": [
            "...você viu isso também?",
        ],
        "descoberto": [
            "Saia daí. Agora. Ela chamou a segurança.",
        ],
        "fim": [
            "Turno encerrado. Me diz: quem foi?",
        ],
    ]

    static let door7Transcript: [String] = [
        "Celeste: \"Rui, eu não posso ter mais gente subindo aqui.\"",
        "Rui: \"A gôndola não sai do térreo desde segunda. Eu já disse.\"",
        "Celeste: \"O Almeida pediu pra trocar de quarto com o Vilar na véspera. Eu deixei.\"",
        "Celeste: \"Se a polícia souber, fecham o hotel. Ninguém fala nada.\"",
    ]

    static func endingTitle(_ e: Ending) -> String {
        switch e {
        case .descoberto: return "Descoberta"
        case .semProvas: return "Turno encerrado"
        case .casoResolvido: return "Caso resolvido"
        case .casoErrado: return "Suspeito errado"
        }
    }

    static func endingText(_ e: Ending) -> String {
        switch e {
        case .descoberto:
            return "Dona Celeste percebeu que você não era da limpeza. A segurança acompanhou você até a rua. O caso continua um infarto."
        case .semProvas:
            return "O turno acabou e o corredor ficou impecável, mas sem provas o delegado não consegue reabrir o caso."
        case .casoResolvido:
            return "O Sr. Almeida trocou de quarto com Vilar na véspera, saiu pela janela do 5, andou pela cornija e entrou na 7 com o cartão antigo. A marca de mão era dele. Celeste escondia a troca para salvar o hotel."
        case .casoErrado:
            return "As provas não sustentaram a acusação. O verdadeiro responsável saiu do hotel na manhã seguinte."
        }
    }
}

enum Ending: String, Codable {
    case descoberto, semProvas, casoResolvido, casoErrado
}
