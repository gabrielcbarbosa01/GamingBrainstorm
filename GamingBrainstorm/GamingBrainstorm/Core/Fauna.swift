//
//  Fauna.swift
//  Guardiões dos Biomas
//
//  Os bichos que só vivem ali. Não são missão nem obstáculo: passam, comem,
//  fogem de você. Observar cada espécie pela primeira vez abre uma ficha.
//

import SpriteKit

/// Arquétipo de corpo — define qual rotina de desenho monta o bicho.
enum FaunaCorpo {
    case quadrupede    // capivara, veado, quati, graxaim…
    case ave           // tucano, ema, quero-quero, tuiuiú
    case reptil        // jacaré, jabuti
    case aquatico      // boto
    case pendurado     // preguiça, macaco-prego
}

/// O detalhe que identifica a espécie de longe.
enum FaunaTraco {
    case nenhum
    case bicoGrande      // tucano
    case pescocoLongo    // ema, tuiuiú
    case focinhoLongo    // tamanduá-bandeira
}

struct FaunaSpec: Identifiable, Hashable {
    let id: String
    let nome: String
    let cientifico: String
    let corpo: FaunaCorpo
    let bioma: BiomeID
    let corA: SKColor
    let corB: SKColor
    let corDetalhe: SKColor
    let escala: CGFloat
    /// Distância em que percebe o jogador e foge.
    let arisco: CGFloat
    let velocidade: CGFloat
    /// Anda pela água em vez de pela terra?
    let aquatico: Bool
    let traco: FaunaTraco
    let nota: String

    static func == (a: FaunaSpec, b: FaunaSpec) -> Bool { a.id == b.id }
    func hash(into h: inout Hasher) { h.combine(id) }

    static let catalogo: [FaunaSpec] = [
        // ---- Mata Atlântica ----
        FaunaSpec(id: "tucano", nome: "Tucano-de-bico-verde", cientifico: "Ramphastos dicolorus",
                  corpo: .ave, bioma: .mataAtlantica,
                  corA: SKColor(hex: 0x1E1E22), corB: SKColor(hex: 0xE8C24E),
                  corDetalhe: SKColor(hex: 0x8ABF3E), escala: 0.78, arisco: 190,
                  velocidade: 120, aquatico: false, traco: .bicoGrande, nota: "Engole o fruto inteiro e solta a semente longe: é plantador de floresta."),
        FaunaSpec(id: "preguica", nome: "Preguiça-de-coleira", cientifico: "Bradypus torquatus",
                  corpo: .pendurado, bioma: .mataAtlantica,
                  corA: SKColor(hex: 0x8A7A5E), corB: SKColor(hex: 0x3A3026),
                  corDetalhe: SKColor(hex: 0xC6B694), escala: 0.66, arisco: 90,
                  velocidade: 22, aquatico: false,
                  traco: .nenhum, nota: "Ameaçada e lentíssima. Desce da árvore uma vez por semana."),
        FaunaSpec(id: "quati", nome: "Quati", cientifico: "Nasua nasua",
                  corpo: .quadrupede, bioma: .mataAtlantica,
                  corA: SKColor(hex: 0x9A6A3E), corB: SKColor(hex: 0x3E3228),
                  corDetalhe: SKColor(hex: 0xE8E0D0), escala: 0.60, arisco: 210,
                  velocidade: 165, aquatico: false,
                  traco: .nenhum, nota: "Anda em bando, de rabo em pé, revirando a serrapilheira."),

        // ---- Cerrado ----
        FaunaSpec(id: "ema", nome: "Ema", cientifico: "Rhea americana",
                  corpo: .ave, bioma: .cerrado,
                  corA: SKColor(hex: 0x9A9280), corB: SKColor(hex: 0x6A6252),
                  corDetalhe: SKColor(hex: 0x3A3428), escala: 1.05, arisco: 260,
                  velocidade: 230, aquatico: false,
                  traco: .pescocoLongo, nota: "A maior ave do Brasil. Não voa, mas corre a 60 km/h."),
        FaunaSpec(id: "tamandua", nome: "Tamanduá-bandeira", cientifico: "Myrmecophaga tridactyla",
                  corpo: .quadrupede, bioma: .cerrado,
                  corA: SKColor(hex: 0x4E4640), corB: SKColor(hex: 0x1E1A16),
                  corDetalhe: SKColor(hex: 0xD8D2C4), escala: 0.95, arisco: 170,
                  velocidade: 95, aquatico: false,
                  traco: .focinhoLongo, nota: "Vulnerável. Come formiga e cupim; atropelamento e fogo são a maior ameaça."),
        FaunaSpec(id: "veado", nome: "Veado-campeiro", cientifico: "Ozotoceros bezoarticus",
                  corpo: .quadrupede, bioma: .cerrado,
                  corA: SKColor(hex: 0xC09256), corB: SKColor(hex: 0x6A4E2E),
                  corDetalhe: SKColor(hex: 0xF0E8D8), escala: 0.80, arisco: 300,
                  velocidade: 250, aquatico: false,
                  traco: .nenhum, nota: "Sumiu de quase todo o campo aberto que virou lavoura."),

        // ---- Pantanal ----
        FaunaSpec(id: "capivara", nome: "Capivara", cientifico: "Hydrochoerus hydrochaeris",
                  corpo: .quadrupede, bioma: .pantanal,
                  corA: SKColor(hex: 0x8A6A42), corB: SKColor(hex: 0x5A4028),
                  corDetalhe: SKColor(hex: 0x3A2E20), escala: 0.85, arisco: 150,
                  velocidade: 130, aquatico: false,
                  traco: .nenhum, nota: "O maior roedor do mundo. Pasta em bando e mergulha ao menor susto."),
        FaunaSpec(id: "jacare", nome: "Jacaré-do-pantanal", cientifico: "Caiman yacare",
                  corpo: .reptil, bioma: .pantanal,
                  corA: SKColor(hex: 0x4A5A3E), corB: SKColor(hex: 0x2A3424),
                  corDetalhe: SKColor(hex: 0xC8C08A), escala: 0.95, arisco: 110,
                  velocidade: 85, aquatico: true,
                  traco: .nenhum, nota: "Quase extinto pelo couro nos anos 80; hoje há milhões na planície."),
        FaunaSpec(id: "tuiuiu", nome: "Tuiuiú", cientifico: "Jabiru mycteria",
                  corpo: .ave, bioma: .pantanal,
                  corA: SKColor(hex: 0xF0EEE8), corB: SKColor(hex: 0x1E1E22),
                  corDetalhe: SKColor(hex: 0xC8442E), escala: 1.0, arisco: 240,
                  velocidade: 150, aquatico: false,
                  traco: .pescocoLongo, nota: "Ave-símbolo do Pantanal. O ninho é reusado por décadas."),

        // ---- Amazônia ----
        FaunaSpec(id: "boto", nome: "Boto-cor-de-rosa", cientifico: "Inia geoffrensis",
                  corpo: .aquatico, bioma: .amazonia,
                  corA: SKColor(hex: 0xE0A0B0), corB: SKColor(hex: 0xB07084),
                  corDetalhe: SKColor(hex: 0xF6D8E0), escala: 0.95, arisco: 200,
                  velocidade: 175, aquatico: true,
                  traco: .nenhum, nota: "Em Perigo. Fica mais rosa com a idade e sobe igarapé adentro na cheia."),
        FaunaSpec(id: "macacoprego", nome: "Macaco-prego", cientifico: "Sapajus apella",
                  corpo: .pendurado, bioma: .amazonia,
                  corA: SKColor(hex: 0x6A5238), corB: SKColor(hex: 0x2E2418),
                  corDetalhe: SKColor(hex: 0xC6AE84), escala: 0.62, arisco: 200,
                  velocidade: 160, aquatico: false,
                  traco: .nenhum, nota: "Usa pedra como ferramenta para quebrar coco — cultura que passa de geração."),
        FaunaSpec(id: "jabuti", nome: "Jabuti-tinga", cientifico: "Chelonoidis denticulatus",
                  corpo: .reptil, bioma: .amazonia,
                  corA: SKColor(hex: 0x5A4A32), corB: SKColor(hex: 0x2E2618),
                  corDetalhe: SKColor(hex: 0xE0C264), escala: 0.55, arisco: 80,
                  velocidade: 35, aquatico: false,
                  traco: .nenhum, nota: "Dispersor de sementes grandes; poucas espécies fazem esse papel."),

        // ---- Pampa ----
        FaunaSpec(id: "graxaim", nome: "Graxaim-do-campo", cientifico: "Lycalopex gymnocercus",
                  corpo: .quadrupede, bioma: .pampa,
                  corA: SKColor(hex: 0xA08A64), corB: SKColor(hex: 0x4A4034),
                  corDetalhe: SKColor(hex: 0xE8E0D0), escala: 0.68, arisco: 280,
                  velocidade: 215, aquatico: false,
                  traco: .nenhum, nota: "Canídeo do campo sul, ativo à noite; sofre com cães e com o arado."),
        FaunaSpec(id: "queroquero", nome: "Quero-quero", cientifico: "Vanellus chilensis",
                  corpo: .ave, bioma: .pampa,
                  corA: SKColor(hex: 0x9AA2A8), corB: SKColor(hex: 0x22262A),
                  corDetalhe: SKColor(hex: 0xC8442E), escala: 0.55, arisco: 320,
                  velocidade: 190, aquatico: false,
                  traco: .nenhum, nota: "Sentinela do campo: grita e ataca qualquer intruso perto do ninho."),
        FaunaSpec(id: "ratao", nome: "Ratão-do-banhado", cientifico: "Myocastor coypus",
                  corpo: .quadrupede, bioma: .pampa,
                  corA: SKColor(hex: 0x7A5E3E), corB: SKColor(hex: 0x3E3020),
                  corDetalhe: SKColor(hex: 0xE8B23A), escala: 0.62, arisco: 160,
                  velocidade: 120, aquatico: true,
                  traco: .nenhum, nota: "Roedor nadador dos banhados costeiros, de dentes alaranjados.")
    ]

    static func doBioma(_ b: BiomeID) -> [FaunaSpec] { catalogo.filter { $0.bioma == b } }
    static func porId(_ id: String) -> FaunaSpec? { catalogo.first { $0.id == id } }
}
