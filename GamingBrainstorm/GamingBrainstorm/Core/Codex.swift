//
//  Codex.swift
//  Guardiões dos Biomas
//
//  O "Caderno da Avó": fichas de conservação desbloqueadas conforme o jogador
//  descobre bichos e biomas. As informações são baseadas em dados reais de
//  conservação (IUCN, ICMBio, projetos de campo brasileiros).
//

import Foundation

struct CodexEntry: Identifiable {
    let id: String
    let titulo: String
    let subtitulo: String
    let categoria: CodexCategoria
    let status: String
    let statusCor: StatusCor
    let paragrafos: [String]
    let curiosidades: [String]
}

enum CodexCategoria: String, CaseIterable, Identifiable {
    case animais = "Animais"
    case fauna = "Fauna"
    case biomas = "Biomas"
    case campo = "Diário de campo"
    var id: String { rawValue }
}

enum StatusCor { case critico, ameacado, vulneravel, quaseAmeacado, estavel }

enum Codex {

    static var todos: [CodexEntry] { animais + [lendaria] + faunaAmbiente + biomas + campo }

    /// Fichas geradas a partir do catálogo de fauna: uma por espécie avistada.
    static var faunaAmbiente: [CodexEntry] {
        FaunaSpec.catalogo.map { sp in
            CodexEntry(id: "fauna_" + sp.id,
                       titulo: sp.nome,
                       subtitulo: sp.cientifico,
                       categoria: .fauna,
                       status: "Avistada em \(Biome[sp.bioma].nome)",
                       statusCor: .estavel,
                       paragrafos: [sp.nota,
                                    "Registrada em campo durante uma expedição em \(Biome[sp.bioma].nome). Espécies ariscas exigem aproximação silenciosa: em forma animal você assusta menos, e no subsolo ou submerso não assusta nada."],
                       curiosidades: [])
        }
    }

    static func entry(_ id: String) -> CodexEntry? { todos.first { $0.id == id } }

    // MARK: Animais

    static let animais: [CodexEntry] = [
        CodexEntry(
            id: AnimalForm.micoLeaoDourado.rawValue,
            titulo: "Mico-leão-dourado",
            subtitulo: "Leontopithecus rosalia",
            categoria: .animais,
            status: "Em Perigo (IUCN)",
            statusCor: .ameacado,
            paragrafos: [
                "Vive apenas nas baixadas da Mata Atlântica do estado do Rio de Janeiro. É endêmico: some daqui, some do mundo.",
                "Nos anos 1970 restavam cerca de 200 indivíduos na natureza. Reprodução em cativeiro, reintrodução e a criação de corredores florestais levaram a população de volta à casa dos milhares — uma das recuperações mais citadas da conservação mundial.",
                "Em 2018 um surto de febre amarela derrubou de novo boa parte da população, e um programa de vacinação de micos foi montado às pressas. A recuperação nunca é definitiva.",
                "Vive em grupos familiares de 2 a 8 indivíduos, come frutos e insetos e passa quase toda a vida na copa. Por isso a fragmentação da floresta é tão grave para ele: uma estrada no meio da mata é um muro."
            ],
            curiosidades: [
                "É diurno — raro entre primatas pequenos.",
                "Cada grupo defende um território de dezenas de hectares.",
                "Corredores de mata plantados entre fragmentos permitem que grupos isolados voltem a trocar genes."
            ]),

        CodexEntry(
            id: AnimalForm.loboGuara.rawValue,
            titulo: "Lobo-guará",
            subtitulo: "Chrysocyon brachyurus",
            categoria: .animais,
            status: "Vulnerável (lista brasileira)",
            statusCor: .vulneravel,
            paragrafos: [
                "É o maior canídeo da América do Sul e o mais alto de todos — as pernas longas servem para enxergar por cima do capim do Cerrado.",
                "Não é lobo nem raposa: é o único do seu gênero. Anda sozinho, geralmente ao entardecer e à noite, e percorre longas distâncias por território.",
                "Cerca de metade da sua dieta é vegetal, com destaque para a lobeira. Ao comer o fruto e defecar longe, planta a própria comida: é um jardineiro do Cerrado.",
                "A maior causa de morte registrada hoje é o atropelamento em rodovias que cortam o bioma, seguida por perda de hábitat e conflito com criação doméstica."
            ],
            curiosidades: [
                "Seu latido grave, o 'aú-aú', é ouvido a mais de um quilômetro.",
                "A urina tem cheiro forte e característico, usada para marcar território.",
                "Passagens de fauna e cercas-guia sob rodovias reduzem muito os atropelamentos."
            ]),

        CodexEntry(
            id: AnimalForm.araraAzul.rawValue,
            titulo: "Arara-azul-grande",
            subtitulo: "Anodorhynchus hyacinthinus",
            categoria: .animais,
            status: "Vulnerável (IUCN)",
            statusCor: .vulneravel,
            paragrafos: [
                "É o maior papagaio voador do mundo, com cerca de um metro do bico à ponta da cauda. Ocorre no Pantanal, em partes do Cerrado e no leste da Amazônia.",
                "Nos anos 1980 o tráfico de animais retirou dezenas de milhares de indivíduos da natureza. No fim daquela década a população selvagem havia despencado para poucos milhares.",
                "A recuperação veio do trabalho de campo iniciado nos anos 1990: instalação de ninhos artificiais, proteção de árvores de manduvi e envolvimento direto dos fazendeiros pantaneiros.",
                "Depende de dois recursos muito específicos: ocos de manduvi centenários para nidificar e palmeiras como acuri e bocaiúva para se alimentar. Perder qualquer um dos dois quebra a cadeia."
            ],
            curiosidades: [
                "O bico quebra coco de palmeira que resiste a marreta.",
                "Casais são monogâmicos e costumam criar apenas um filhote por ninhada.",
                "Uma árvore de manduvi leva décadas até formar um oco grande o bastante — por isso ninhos artificiais fazem tanta diferença."
            ]),

        CodexEntry(
            id: AnimalForm.pirarucu.rawValue,
            titulo: "Pirarucu",
            subtitulo: "Arapaima gigas",
            categoria: .animais,
            status: "Sob manejo — CITES II",
            statusCor: .quaseAmeacado,
            paragrafos: [
                "Um dos maiores peixes de água doce do planeta: chega a três metros e mais de duzentos quilos.",
                "Respira ar atmosférico. Precisa subir à superfície a cada poucos minutos, o que o torna o peixe mais fácil de localizar — e de matar — de todo o rio.",
                "A sobrepesca zerou populações inteiras em muitos lagos amazônicos. A virada veio com o manejo comunitário: contagem anual feita pelos próprios pescadores, cotas de captura, tamanho mínimo e proteção total das áreas de desova.",
                "Onde o manejo funciona, os estoques se multiplicaram em poucos anos e a renda das comunidades subiu junto. É o exemplo mais forte do Brasil de que conservação e uso podem andar juntos — quando quem mora no lugar decide."
            ],
            curiosidades: [
                "A contagem é feita por pescadores experientes que reconhecem cada subida à superfície.",
                "O macho protege os filhotes na boca e ao redor do corpo por semanas.",
                "Suas escamas são tão duras que resistem a dentes de piranha."
            ]),

        CodexEntry(
            id: AnimalForm.tucoTuco.rawValue,
            titulo: "Tuco-tuco-das-dunas",
            subtitulo: "Ctenomys flamarioni",
            categoria: .animais,
            status: "Ameaçado (lista brasileira)",
            statusCor: .critico,
            paragrafos: [
                "Roedor subterrâneo que existe apenas na faixa de dunas costeiras do Rio Grande do Sul. Em nenhum outro lugar do mundo.",
                "Passa quase toda a vida em galerias que ele mesmo cava. O nome vem do som que emite dentro do túnel: 'tuco-tuco'.",
                "Ao escavar, revolve o solo, arejando e permitindo a infiltração de água. É engenheiro de ecossistema: a duna depende dele tanto quanto ele depende da duna.",
                "Ameaças: urbanização do litoral, plantios de pínus e eucalipto sobre as dunas, tráfego de veículos na areia e expansão agrícola. Área de ocorrência pequena somada a impacto intenso é a receita da extinção silenciosa."
            ],
            curiosidades: [
                "É um dos animais brasileiros ameaçados menos conhecidos do grande público.",
                "Vive praticamente solitário, cada indivíduo no seu próprio sistema de túneis.",
                "Proteger uma faixa contínua de duna vale mais do que proteger vários pedaços soltos."
            ])
    ]

    // MARK: Biomas — a lendária entra entre os animais

    static let lendaria = CodexEntry(
        id: "harpia",
        titulo: "Harpia",
        subtitulo: "Harpia harpyja",
        categoria: .animais,
        status: "Quase Ameaçada (IUCN) — extinta em boa parte da mata",
        statusCor: .ameacado,
        paragrafos: [
            "É a maior e mais poderosa ave de rapina das Américas. A envergadura passa de dois metros e as garras traseiras são maiores que as de um urso pardo.",
            "Caça no interior da floresta, entre as copas: preguiças, macacos, quatis. É predadora de topo — inclusive dos micos que você passou o jogo protegendo.",
            "Justamente por isso ela é um indicador tão bom. Um casal precisa de milhares de hectares contínuos e de árvores emergentes gigantes para nidificar. Onde a harpia ainda se reproduz, a floresta está inteira; onde ela sumiu, sobrou fragmento.",
            "Cria um único filhote a cada dois ou três anos, e ele depende dos pais por muitos meses. Uma população que cai demora demais para se recompor — não há atalho."
        ],
        curiosidades: [
            "É a ave símbolo do Panamá e já foi comum de norte a sul da Mata Atlântica.",
            "Ninhos monitorados no Brasil ficam em castanheiras e outras árvores emergentes de mais de 40 metros.",
            "Proteger uma harpia é, na prática, proteger todo o território de caça dela — e tudo que vive dentro dele."
        ])

    // MARK: Biomas

    static let biomas: [CodexEntry] = [
        CodexEntry(
            id: "bioma_mataAtlantica", titulo: "Mata Atlântica",
            subtitulo: "Floresta tropical costeira", categoria: .biomas,
            status: "Hotspot mundial de biodiversidade", statusCor: .critico,
            paragrafos: [
                "Cobria originalmente toda a costa brasileira e avançava para o interior. Hoje restam pouco mais de um décimo da cobertura original, quase toda em fragmentos.",
                "É onde vive a maior parte da população brasileira — o que torna cada remanescente uma disputa direta entre cidade, lavoura e floresta.",
                "Mesmo reduzida, concentra um número altíssimo de espécies que não existem em nenhum outro lugar."
            ],
            curiosidades: ["Fragmento isolado perde espécies mesmo sem ser derrubado: é a chamada dívida de extinção.",
                           "Corredores ecológicos religam fragmentos e são hoje a principal estratégia no bioma."]),

        CodexEntry(
            id: "bioma_cerrado", titulo: "Cerrado",
            subtitulo: "Savana tropical", categoria: .biomas,
            status: "Berço das águas do Brasil", statusCor: .ameacado,
            paragrafos: [
                "É a savana mais rica em espécies do mundo e ocupa cerca de um quarto do território brasileiro.",
                "Nasce aqui a água da maioria das grandes bacias hidrográficas do país. Suas árvores têm raízes profundíssimas que buscam água a dezenas de metros — por isso se diz que é uma floresta de cabeça para baixo.",
                "Cerca de metade da cobertura original já foi convertida em lavoura e pastagem, e a taxa de desmatamento supera a da Amazônia em alguns anos."
            ],
            curiosidades: ["O fogo faz parte do ciclo natural — o problema é o fogo fora de época e provocado.",
                           "Muitas plantas do Cerrado só germinam depois do calor de uma queimada natural."]),

        CodexEntry(
            id: "bioma_pantanal", titulo: "Pantanal",
            subtitulo: "Planície alagável", categoria: .biomas,
            status: "Maior área úmida contínua do planeta", statusCor: .vulneravel,
            paragrafos: [
                "Todo ano a planície inunda e seca de novo. Esse pulso de cheia organiza toda a vida: a reprodução dos peixes, a nidificação das aves, o pasto do gado.",
                "A biodiversidade não vem do número de espécies exclusivas, e sim da quantidade absurda de indivíduos concentrados — é o melhor lugar do Brasil para simplesmente ver bicho.",
                "As secas extremas e os incêndios recentes queimaram porções enormes da planície, com mortandade de fauna em escala inédita."
            ],
            curiosidades: ["A água que enche o Pantanal nasce no Cerrado: destruir o planalto seca a planície.",
                           "Fazendas pantaneiras tradicionais convivem com a fauna há gerações e são parceiras-chave da conservação."]),

        CodexEntry(
            id: "bioma_amazonia", titulo: "Amazônia",
            subtitulo: "Floresta tropical úmida", categoria: .biomas,
            status: "Maior floresta tropical do mundo", statusCor: .ameacado,
            paragrafos: [
                "A floresta bombeia umidade para o continente inteiro através dos chamados rios voadores, influenciando a chuva no Sudeste e no Sul.",
                "Cerca de um quinto da cobertura original já foi derrubado. Pesquisadores alertam para um ponto de não retorno a partir do qual a floresta se converteria em savana.",
                "Os rios são as estradas: a vida ribeirinha, a pesca e o manejo comunitário são inseparáveis da conservação aqui."
            ],
            curiosidades: ["Territórios indígenas estão entre as áreas mais bem conservadas da região.",
                           "Manejo comunitário de pesca recuperou estoques de pirarucu em dezenas de lagos."]),

        CodexEntry(
            id: "bioma_pampa", titulo: "Pampa",
            subtitulo: "Campos do sul", categoria: .biomas,
            status: "O bioma menos protegido do Brasil", statusCor: .critico,
            paragrafos: [
                "No Brasil ocorre apenas no Rio Grande do Sul. É campo nativo, não floresta — e por isso é frequentemente confundido com 'terra vazia'.",
                "Abriga centenas de espécies de gramíneas e uma fauna própria, incluindo animais que não existem em nenhum outro bioma.",
                "É o bioma com o menor percentual de área protegida do país, pressionado por lavouras de grãos e por plantios de árvores exóticas sobre o campo nativo."
            ],
            curiosidades: ["Pecuária extensiva sobre campo nativo pode conservar o Pampa — lavoura sobre ele, não.",
                           "As dunas costeiras formam um ecossistema à parte, com espécies exclusivas."])
    ]

    // MARK: Diário de campo

    static let campo: [CodexEntry] = [
        CodexEntry(
            id: "refugio", titulo: "Refúgio Raízes",
            subtitulo: "Estação de campo dos Guardiões", categoria: .campo,
            status: "Base segura", statusCor: .estavel,
            paragrafos: [
                "O Refúgio é o centro de tudo: daqui saem os portais para os cinco biomas e aqui ficam Dona Iara e Téo.",
                "Nenhuma ameaça entra no Refúgio. Use-o para recuperar essência, revisar o Códice e escolher a próxima expedição."
            ],
            curiosidades: ["A essência regenera sozinha na forma humana.",
                           "Cada portal só abre quando você tem o amuleto exigido por ele."]),

        CodexEntry(
            id: "viveiro", titulo: "Viveiro do Refúgio",
            subtitulo: "Restauração começa em canteiro", categoria: .campo,
            status: "Estrutura da base", statusCor: .estavel,
            paragrafos: [
                "Restaurar floresta não é jogar semente do avião: é produzir muda, cuidar dela por meses e plantar no lugar certo, na hora certa.",
                "Cada espécie do viveiro cumpre um papel real — a lobeira alimenta o lobo-guará, o manduvi vira ninho de arara, o capim-das-dunas segura a areia sobre as galerias do tuco-tuco.",
                "Mudas colhidas viram matéria-prima das melhorias da oficina, e é o viveiro cheio que convence a Harpia a voltar."
            ],
            curiosidades: ["Sementes vêm de objetivos de restauro e resgate no campo.",
                           "Ampliar o viveiro na oficina abre mais canteiros."]),

        CodexEntry(
            id: "acude", titulo: "Açude do Refúgio",
            subtitulo: "Pescar é medir o rio", categoria: .campo,
            status: "Estrutura da base", statusCor: .estavel,
            paragrafos: [
                "A pescaria do Refúgio é amostragem: cada peixe registrado diz alguma coisa sobre a saúde da água.",
                "Espécies migradoras como o dourado, e juvenis abaixo do tamanho mínimo como o pirarucu, devem voltar para a água — e valem o dobro em pontos justamente por isso.",
                "Melhorar o cais aumenta a chance de encontrar as espécies mais raras."
            ],
            curiosidades: ["Devolver vale mais que levar.",
                           "Peixes guardados são moeda de troca na oficina."]),

        CodexEntry(
            id: "amuletos", titulo: "Os cinco amuletos",
            subtitulo: "Como funcionam as transformações", categoria: .campo,
            status: "Mecânica central", statusCor: .estavel,
            paragrafos: [
                "Cada amuleto transforma o guardião em um animal ameaçado e concede uma travessia exclusiva: cipoal, espinheiro, abismo, água funda e terra compactada.",
                "Transformar-se consome essência continuamente. Sem essência, você volta à forma humana automaticamente.",
                "Só a forma humana interage com pessoas, armadilhas e equipamentos — parte do desafio é escolher a hora certa de voltar a ser gente."
            ],
            curiosidades: ["O lobo-guará fareja segredos a distância.",
                           "A arara-azul amplia o campo de visão enquanto plana.",
                           "O tuco-tuco fica invisível para ameaças enquanto escava."])
    ]
}
