//
//  Dialogue.swift
//  Guardiões dos Biomas
//
//  Sistema de diálogo em árvore + o roteiro do jogo. Cada nó tem falas,
//  escolhas opcionais e efeitos sobre o estado da partida.
//

import Foundation

struct DialogueChoice {
    let texto: String
    var destino: (() -> DialogueNode?)? = nil
    var efeito: ((GameState) -> Void)? = nil
}

final class DialogueNode {
    let falante: String
    let papel: String
    /// Retrato: se for uma forma animal, desenhamos o bicho; senão, uma pessoa.
    let retrato: AnimalForm?
    let linhas: [String]
    let escolhas: [DialogueChoice]
    let aoEntrar: ((GameState) -> Void)?
    let proximo: (() -> DialogueNode?)?

    init(falante: String,
         papel: String = "",
         retrato: AnimalForm? = nil,
         linhas: [String],
         escolhas: [DialogueChoice] = [],
         aoEntrar: ((GameState) -> Void)? = nil,
         proximo: (() -> DialogueNode?)? = nil) {
        self.falante = falante
        self.papel = papel
        self.retrato = retrato
        self.linhas = linhas
        self.escolhas = escolhas
        self.aoEntrar = aoEntrar
        self.proximo = proximo
    }
}

/// Uma conversa em andamento.
struct DialogueSession {
    var atual: DialogueNode
    var linha: Int = 0
    let bioma: BiomeID
    private var entrouNoNo = false

    init(raiz: DialogueNode, bioma: BiomeID) {
        self.atual = raiz
        self.bioma = bioma
    }

    var falaAtual: String { atual.linhas.indices.contains(linha) ? atual.linhas[linha] : "" }
    var naUltimaLinha: Bool { linha >= atual.linhas.count - 1 }
    var mostrandoEscolhas: Bool { naUltimaLinha && !atual.escolhas.isEmpty }

    /// Dispara o efeito de entrada do nó (uma única vez).
    mutating func entrar(_ estado: GameState) {
        guard !entrouNoNo else { return }
        entrouNoNo = true
        atual.aoEntrar?(estado)
    }

    /// Avança a conversa. Retorna false quando o diálogo terminou.
    mutating func avancar(escolha: Int?, estado: GameState) -> Bool {
        if let i = escolha, atual.escolhas.indices.contains(i) {
            let c = atual.escolhas[i]
            c.efeito?(estado)
            if let destino = c.destino?() {
                trocar(para: destino, estado: estado)
                return true
            }
            return false
        }

        if !naUltimaLinha {
            linha += 1
            return true
        }

        if !atual.escolhas.isEmpty { return true } // aguardando escolha

        if let destino = atual.proximo?() {
            trocar(para: destino, estado: estado)
            return true
        }
        return false
    }

    private mutating func trocar(para no: DialogueNode, estado: GameState) {
        atual = no
        linha = 0
        entrouNoNo = false
        entrar(estado)
    }
}

// MARK: - Roteiro

enum DialogueBook {

    // ---------- Abertura ----------

    static func abertura() -> DialogueNode {
        let terceiro = DialogueNode(
            falante: "Dona Iara", papel: "bióloga, Refúgio Raízes",
            linhas: [
                "São seis amuletos. Seis bichos que estão perto de sumir do mapa — e seis biomas que estão perto de sumir junto com eles.",
                "Cada amuleto está com um Guardião. Eles não entregam nada de graça: você tem que provar que sabe olhar antes de sair correndo.",
                "Começa pela Mata Atlântica. O portal fica na clareira ao norte daqui. Vai com calma — e volta pra contar."
            ],
            aoEntrar: { st in
                st.ligarFlag("abertura_ok")
                st.descobrirCodex("refugio")
            },
            proximo: { harpiaAbertura() })

        let segundo = DialogueNode(
            falante: "Dona Iara", papel: "bióloga, Refúgio Raízes",
            linhas: [
                "Sua avó passou quarenta anos anotando o que via nesses campos. O caderno dela agora é seu.",
                "Só que na última página tem uma coisa que ela nunca me explicou: um desenho de seis amuletos de barro.",
                "Ela dizia que quem vestisse um deles deixava de olhar o bicho de fora. Passava a olhar o mundo de dentro dele."
            ],
            escolhas: [
                DialogueChoice(texto: "Virar bicho? Isso é sério?", destino: { terceiro }),
                DialogueChoice(texto: "Ela nunca me contou disso.", destino: { terceiro }),
                DialogueChoice(texto: "Me diz onde começo.", destino: { terceiro })
            ])

        return DialogueNode(
            falante: "Dona Iara", papel: "bióloga, Refúgio Raízes",
            retrato: .humano,
            linhas: [
                "Chegou. Achei que você não vinha mais.",
                "Isto aqui é o Refúgio Raízes. Faz trinta anos que a gente conta bicho, planta muda e briga com quem chega de motosserra.",
                "E faz três anos que a conta só dá negativo."
            ],
            proximo: { segundo })
    }

    // ---------- A Harpia ----------

    /// Ela abre o jogo e some. Não explica nada direito — é esse o ponto.
    static func harpiaAbertura() -> DialogueNode {
        let despedida = DialogueNode(
            falante: "Harpia", papel: "a que veio antes", retrato: .harpia,
            linhas: [
                "Cinco vão te chamar pelo nome. Eu não.",
                "Eu como o que você veio salvar. Macaco, preguiça, filhote de tudo quanto é bicho. E mesmo assim, se eles sumirem, eu sumo junto.",
                "É por isso que servir de sinal: onde eu ainda vivo, a floresta está inteira. Onde eu não vivo mais, ela virou retalho.",
                "Quando os seis estiverem com você — e a terra aqui embaixo voltar a dar fruto — eu volto.",
                "Até lá, uma dica que sua avó também sabia: procure o que ficou preso, não o que ficou bonito."
            ],
            aoEntrar: { st in
                st.ligarFlag("harpia_conheceu")
                st.descobrirCodex("harpia")
                st.avisar("Missão: atravesse o portal ao norte do Refúgio.",
                          icone: "signpost.right.fill", cor: .bom)
            })

        let resposta = DialogueNode(
            falante: "Harpia", papel: "a que veio antes", retrato: .harpia,
            linhas: ["Não perguntei o que você quer. Perguntei o que você devolve.",
                     "Guarde a resposta. Vou cobrar."],
            proximo: { despedida })

        return DialogueNode(
            falante: "???", papel: "uma sombra grande demais", retrato: .harpia,
            linhas: [
                "A luz sai da clareira antes do tempo. Alguma coisa pousou no galho seco.",
                "Não é um pássaro. É do tamanho de uma pessoa, e olha para você como quem já decidiu.",
                "— Então é você. A neta.",
                "— Eu sou mais velha que este refúgio, que essa cerca e que o nome que deram a essa serra. Me chamam de Harpia."
            ],
            escolhas: [
                DialogueChoice(texto: "O que você quer de mim?", destino: { resposta }),
                DialogueChoice(texto: "Você é real?", destino: { resposta }),
                DialogueChoice(texto: "…", destino: { resposta })
            ])
    }

    /// O reencontro: só acontece quando o mundo inteiro já foi devolvido.
    static func harpiaFinal() -> DialogueNode {
        let coroa = DialogueNode(
            falante: "Harpia", papel: "guardiã do alto", retrato: .harpia,
            linhas: [
                "Toma. A Coroa não é um amuleto — é um lugar. O lugar de quem enxerga tudo de uma vez.",
                "Voando comigo você não vai encontrar barreira nenhuma neste mundo. Rocha, abismo, rio: passa por cima.",
                "Mas repara: eu não voo porque sou forte. Voo porque a floresta ficou grande de novo. Foi você que fez o céu caber.",
                "Vai. E quando cansar, volta pro viveiro. O trabalho não acaba — ele só muda de altura."
            ],
            aoEntrar: { st in
                st.conquistarAmuleto(.harpia)
                st.ligarFlag("harpia_final")
                st.somarPontos(2000)
                st.avisar("Coroa da Harpia — atalho 7. Nada mais te barra.",
                          icone: "crown.fill", cor: .conquista)
            })

        let prova = DialogueNode(
            falante: "Harpia", papel: "guardiã do alto", retrato: .harpia,
            linhas: [
                "Eu voltei porque deu para voltar. Tem presa outra vez, tem árvore alta outra vez, tem sossego para criar filhote.",
                "Isso não foi milagre. Foi você contando bicho um por um e plantando muda uma por uma."
            ],
            escolhas: [
                DialogueChoice(texto: "Ainda falta muita coisa.", destino: { coroa },
                               efeito: { $0.somarPontos(200) }),
                DialogueChoice(texto: "Fizemos juntos — eu, o Refúgio e a gente daqui.", destino: { coroa },
                               efeito: { $0.somarPontos(260) }),
                DialogueChoice(texto: "Eu só segui a dica que você deu.", destino: { coroa },
                               efeito: { $0.somarPontos(220) })
            ])

        return DialogueNode(
            falante: "Harpia", papel: "guardiã do alto", retrato: .harpia,
            linhas: [
                "Cheguei a duvidar que fosse te ver de novo de pé.",
                "Você lembra o que eu pedi? Não era coragem. Era o que você devolve.",
                "Seis amuletos. Expedição em cada território. E terra dando fruto no seu próprio quintal.",
                "Está tudo aí. Então vem, sobe."
            ],
            proximo: { prova })
    }

    // ---------- Chegada em cada bioma ----------

    static func chegada(em id: BiomeID) -> DialogueNode? {
        switch id {
        case .refugio:
            return nil

        case .mataAtlantica:
            return DialogueNode(
                falante: "Seu Bento", papel: "guia local, Poço das Antas",
                linhas: [
                    "Ô, forasteiro. Cuidado com o barranco — isso aqui já foi mata fechada, hoje é retalho.",
                    "O mico-leão-dourado não sai do chão pra nada. Ele vive lá em cima, na copa, e a estrada cortou a copa em dois.",
                    "Se você quiser achar o grupo, não procura o bicho. Procura o que ele deixou pra trás: fruta mordida, pelo em galho, casca arranhada.",
                    "Anda pelo capim alto e usa o E pra registrar. É assim que a gente faz censo de verdade."
                ],
                aoEntrar: { $0.avisar("Etapa 1: registre 6 vestígios.", icone: "pawprint.fill", cor: .bom) })

        case .cerrado:
            return DialogueNode(
                falante: "Dona Firmina", papel: "raizeira do chapadão",
                linhas: [
                    "Cerrado não é mato feio, meu filho. É floresta de cabeça pra baixo — raiz mais funda que árvore é alta.",
                    "Aqui nasce a água que abastece meio Brasil. E aqui tá queimando cedo demais, todo ano mais cedo.",
                    "O lobo-guará anda sozinho, à noite, quilômetros e quilômetros. Come lobeira, planta semente andando. É jardineiro sem saber.",
                    "Segue as pegadas dele. Se achar cipoal fechado no caminho, você já sabe: vira mico e sobe."
                ],
                aoEntrar: { $0.avisar("O amuleto da Copa abre os cipoais deste bioma.", icone: "leaf.fill", cor: .neutro) })

        case .pantanal:
            return DialogueNode(
                falante: "Nalva", papel: "guia pantaneira",
                linhas: [
                    "Bem-vindo à planície. Aqui a água manda: seis meses ela cobre tudo, seis meses ela devolve.",
                    "A onça-pintada é a maior fera das Américas, e mora bem aqui. Mas onça que ataca gado vira onça morta — foi sempre assim.",
                    "O jeito que achamos de segurar isso foi pagar o fazendeiro pela onça viva, não pela onça morta. Vaca que ela mata, alguém indeniza.",
                    "Se você não quer ser visto, siga o jeito dela: pelo matagal denso, sem barulho. Passo Invisível — é assim que os antigos chamavam."
                ])

        case .caatinga:
            return DialogueNode(
                falante: "Dona Creuza", papel: "guia do riacho seco",
                linhas: [
                    "Chegou no sertão. Água aqui não falta o ano inteiro: falta é bem onde não devia.",
                    "A ararinha-azul já foi dada como extinta na natureza. Extinta mesmo — não sobrou nenhuma voando livre, só umas poucas em cativeiro.",
                    "Voltou a voar aqui porque um bocado de gente teimosa não desistiu: soltou filhote criado em cativeiro, protegeu caraibeira, botou gente pra vigiar oco de árvore.",
                    "Se achar gaiola armada num oco, não hesite: vira gente e solta o bicho antes que ele vire contrabando."
                ],
                aoEntrar: { $0.avisar("Etapa 1: registre 8 ninhos.", icone: "pawprint.fill", cor: .bom) })

        case .amazonia:
            return DialogueNode(
                falante: "Seu Raimundo", papel: "pescador de manejo, Médio Solimões",
                linhas: [
                    "Chegou na hora da contagem. Todo ano a comunidade conta pirarucu — um por um, na subida pra respirar.",
                    "Bicho de três metros, duzentos quilos, respira ar igual a gente. Sobe, dá o bodeco, some.",
                    "Aqui já foi zerado. Aí a gente combinou: cota, época, ninguém pega fêmea de desova. Hoje tem mais peixe que nos anos 90.",
                    "Manejo dá certo quando quem mora manda. Vem, te mostro os lagos."
                ])

        case .pampa:
            return DialogueNode(
                falante: "Seu Adão", papel: "campeiro do litoral",
                linhas: [
                    "Pampa todo mundo acha que é só campo vazio. Vazio nada — é a casa mais cheia que tem.",
                    "Esse tuco-tuco daqui não existe em outro canto do planeta. Só nessas dunas, nessa faixa de areia.",
                    "Ele cava galeria, revira a terra, deixa entrar ar e água. Some ele, some a duna junto.",
                    "E o arado tá chegando. Cada passada derruba um bairro inteiro embaixo do chão."
                ])
        }
    }

    // ---------- Entre etapas ----------

    static func avancoDeEtapa(de id: BiomeID, etapa: Int) -> DialogueNode? {
        let b = Biome[id]
        let chain = Quests.chain(for: id)
        guard chain.etapas.indices.contains(etapa) else { return nil }
        let proxima = chain.etapas[etapa]

        let falante: (String, String)
        switch id {
        case .refugio: falante = ("Dona Iara", "bióloga")
        case .mataAtlantica: falante = ("Seu Bento", "guia local")
        case .cerrado: falante = ("Dona Firmina", "raizeira")
        case .pantanal: falante = ("Nalva", "guia pantaneira")
        case .caatinga: falante = ("Dona Creuza", "guia do riacho seco")
        case .amazonia: falante = ("Seu Raimundo", "pescador de manejo")
        case .pampa: falante = ("Seu Adão", "campeiro")
        }

        return DialogueNode(
            falante: falante.0, papel: falante.1,
            linhas: [
                "Boa. Isso já é dado — dado de verdade, do tipo que vira política pública.",
                "Mas não acabou. \(b.ameaca.descricao)",
                "Próxima tarefa: \(proxima.titulo). \(proxima.descricao)",
                proxima.dica
            ],
            aoEntrar: { st in
                st.avisar("Nova etapa: \(proxima.titulo)", icone: proxima.kind.icone, cor: .bom)
            })
    }

    // ---------- Guardiões ----------

    static func guardiao(de id: BiomeID) -> DialogueNode? {
        let b = Biome[id]
        guard id != .refugio else { return nil }
        let forma = b.animal

        let entrega = DialogueNode(
            falante: "Guardião", papel: forma.nome, retrato: forma,
            linhas: [
                "Então leva. O \(forma.amuleto) é seu.",
                "Vestindo ele, você \(forma.habilidade.lowercased()). Mas escuta bem: amuleto não é fantasia.",
                "Toda vez que você virar um de nós, vai gastar essência. E vai lembrar que a gente cansa, tem medo e passa fome igual a você.",
                proximaEtapaTexto(depois: id)
            ],
            aoEntrar: { st in
                st.conquistarAmuleto(forma)
                st.ligarFlag("guardiao_\(id.rawValue)")
                if let seguinte = proximoBioma(depois: id) {
                    st.avisar("Portal liberado: \(Biome[seguinte].nome)", icone: "arrow.triangle.branch", cor: .conquista)
                }
            })

        let prova = DialogueNode(
            falante: "Guardião", papel: forma.nome, retrato: forma,
            linhas: [
                "Você não veio caçar. Veio contar, soltar e plantar. Isso eu vi.",
                "A maior parte de vocês chega aqui achando que salvar é levar embora. Salvar é deixar ficar."
            ],
            escolhas: [
                DialogueChoice(texto: "Eu quero aprender a enxergar como vocês.", destino: { entrega },
                               efeito: { $0.somarPontos(120) }),
                DialogueChoice(texto: "Eu quero devolver o que tomaram daqui.", destino: { entrega },
                               efeito: { $0.somarPontos(120) }),
                DialogueChoice(texto: "Sinceramente? Eu ainda não sei.", destino: { entrega },
                               efeito: { st in
                                   st.somarPontos(160)
                                   st.avisar("Honestidade também é ciência.", icone: "heart.fill", cor: .bom)
                               })
            ])

        return DialogueNode(
            falante: "Guardião", papel: forma.nome, retrato: forma,
            linhas: [
                aberturaGuardiao(id),
                "Eu sou o que sobra quando a última de nós fecha os olhos. E eu ando muito perto de ser só isso: memória.",
                "Você andou por \(b.nome) sem quebrar nada. Isso é mais raro do que devia ser."
            ],
            proximo: { prova })
    }

    private static func aberturaGuardiao(_ id: BiomeID) -> String {
        switch id {
        case .refugio: return ""
        case .mataAtlantica:
            return "Sete por cento. É o que restou da minha mata inteira. Eu vivo em sete por cento de mim mesmo."
        case .cerrado:
            return "Metade do cerrado virou lavoura em cinquenta anos. Eu ando à noite porque de dia não sobrou sombra."
        case .pantanal:
            return "Onça que mata gado vira onça morta — essa sempre foi a lei do pasto. Eu ainda respiro porque alguém decidiu que minha vida valia mais viva do que minha pele."
        case .caatinga:
            return "Fui dada como extinta na natureza. Não sobrou nenhuma de nós livre. Eu voltei. Nem todo bicho volta."
        case .amazonia:
            return "Eu preciso subir pra respirar. Isso me faz o peixe mais fácil de matar do rio inteiro."
        case .pampa:
            return "Eu só existo aqui. Se essa duna virar plantação, eu não me mudo — eu acabo."
        }
    }

    private static func proximoBioma(depois id: BiomeID) -> BiomeID? {
        let ordem = Biome[id].ordem
        return BiomeID.exploraveis.first { Biome[$0].ordem == ordem + 1 }
    }

    private static func proximaEtapaTexto(depois id: BiomeID) -> String {
        if let seguinte = proximoBioma(depois: id) {
            return "Agora o portal de \(Biome[seguinte].nome) te aceita. Volta ao Refúgio e segue."
        }
        return "Seis amuletos. Agora o Refúgio te espera — e o campo nunca deixa de precisar de gente. As expedições não têm fim."
    }

    // ---------- Refúgio: NPCs permanentes ----------

    static func iara(_ st: GameState) -> DialogueNode {
        let total = st.save.amuletos.count
        var linhas: [String] = []
        switch total {
        case 0:
            linhas = ["Ainda sem amuleto nenhum. Vai pra Mata Atlântica — é o portal ao norte.",
                      "E leva o caderno da sua avó. Ele anota sozinho o que você registra."]
        case 1...5:
            linhas = ["\(total) de 6 amuletos. Tá indo.",
                      "Cada bicho que você traz de volta pro mapa é uma linha que a gente pode botar num relatório e defender no papel.",
                      "Sem dado, não tem política. Sem política, não tem bicho."]
        default:
            linhas = ["Seis amuletos. Sua avó ia querer ver isso.",
                      "Só que agora vem a parte que ninguém conta: conservação não termina.",
                      "Todo bioma continua gerando expedição. Toda expedição sobe um degrau de dificuldade.",
                      "É pra sempre mesmo. O trabalho é esse."]
        }
        return DialogueNode(falante: "Dona Iara", papel: "bióloga, Refúgio Raízes",
                            retrato: .humano, linhas: linhas)
    }

    static func teo(_ st: GameState) -> DialogueNode {
        return DialogueNode(
            falante: "Téo", papel: "técnico de campo",
            retrato: .humano,
            linhas: [
                "Índice de Biodiversidade em \(st.indiceBiodiversidade). Título atual: \(st.tituloGuardiao).",
                "Dica de quem apanhou: essência gasta rápido. Volte pra forma humana sempre que puder, ela regenera sozinha.",
                "E aperta TAB pra abrir o Códice. Tem ficha de cada bicho lá — informação real, não invenção minha."
            ])
    }
}
