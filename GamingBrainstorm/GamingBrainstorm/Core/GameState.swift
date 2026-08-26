//
//  GameState.swift
//  Guardiões dos Biomas
//
//  Fonte única de verdade da partida: progressão, amuletos, essência,
//  missões, códice e persistência em disco.
//

import SwiftUI
import Combine
import SpriteKit

// MARK: - Persistência

struct BiomeSave: Codable {
    /// Progresso de cada estilhaço do amuleto, por tipo de objetivo.
    var fragmentos: [String: Int] = [:]
    var etapa: Int = 0             // legado
    var progresso: Int = 0         // legado
    var visitado: Bool = false
    var nivelExpedicao: Int = 1
    var expedicaoAtiva: Bool = false
    var expedicaoProgresso: Int = 0
    var expedicoesConcluidas: Int = 0
    var vestigiosTotais: Int = 0
    // --- Santuário (a masmorra do bioma) ---
    var salasLimpas: [String] = []
    var bausAbertos: [String] = []
    var chaves: Int = 0
    var santuarioConcluido = false
    var temMapa = false
    var temBussola = false
    var temChaveDoGuardiao = false
    var salasVisitadas: [String] = []
}

struct SaveData: Codable {
    var nomeGuardiao: String = "Guardiã(o)"
    var amuletos: [AnimalForm] = []
    var biomas: [String: BiomeSave] = [:]
    var biomaAtual: BiomeID = .refugio
    var pontos: Int = 0
    var codex: [String] = []
    var flags: [String] = []
    var tempoJogado: Double = 0
    var criadoEm: Date = Date()
    var refugio = RefugioSave()
    /// Melhor marca de cada prova arcade.
    var recordes: [String: Int] = [:]
    /// Corações de vida conquistados em baús pelos santuários.
    var coracoes: Int = 3
    /// Os Cantos conquistados ao vencer cada Guardião — os instrumentos.
    var cantos: [String] = []

    func biome(_ id: BiomeID) -> BiomeSave { biomas[id.rawValue] ?? BiomeSave() }
    mutating func setBiome(_ id: BiomeID, _ v: BiomeSave) { biomas[id.rawValue] = v }
}

// MARK: - Avisos de tela

struct Toast: Identifiable, Equatable {
    let id = UUID()
    let texto: String
    let icone: String
    let cor: ToastColor
    var criado = Date()
}

enum ToastColor: Equatable { case neutro, bom, alerta, conquista }

// MARK: - Pesca

/// Minigame de tempo: um marcador varre a barra e o jogador tenta parar
/// dentro da faixa. Um cais melhor alarga a faixa.
struct PescaSession {
    let inicio = Date()
    var tentativas: Int
    var zonaCentro: Double
    var zonaLargura: Double
    var velocidade: Double
    var resultado: Peixe?
    var mensagem: String?
    var encerrada = false

    /// Posição do marcador em 0…1 para um instante da animação.
    func posicao(em t: TimeInterval) -> Double {
        (sin(t * velocidade) + 1) / 2
    }

    func acertou(em t: TimeInterval) -> Bool {
        abs(posicao(em: t) - zonaCentro) <= zonaLargura / 2
    }
}

// MARK: - Navegação

enum Screen: Equatable {
    case menu
    case jogo
    case jornal
    case mapa
    case creditos
}

// MARK: - Estado

@MainActor
final class GameState: ObservableObject {

    @Published var save = SaveData()
    @Published var formaAtual: AnimalForm = .humano
    @Published var essencia: CGFloat = 100
    @Published var tela: Screen = .menu
    @Published var toasts: [Toast] = []
    @Published var dialogo: DialogueSession?
    @Published var biomaCarregado: BiomeID = .refugio
    @Published var dicaInteracao: String?
    @Published var mostrarRodaAmuletos = false
    @Published var pesca: PescaSession?
    /// O pirarucu respira ar: submerso, isto cai; na superfície, volta.
    @Published var folego: CGFloat = 100
    /// Prova arcade em andamento. Quando existe, a cena de corrida assume.
    @Published var corrida: CorridaSessao?
    /// Operação em andamento no bioma: a frente avançando e o que resta salvar.
    @Published var operacao: OperacaoSessao?
    /// Vida em meios-corações: 6 = três corações cheios.
    @Published var vida: Int = 6
    @Published var salaAtual = GridPoint(x: 0, y: 0)
    /// Painel do Refúgio aberto no momento (viveiro, oficina…).
    @Published var painelRefugio: PainelRefugio?
    /// Muda sempre que a cena precisa recarregar o mundo (viagem entre biomas).
    @Published var geracaoMundo: Int = 0

    // Publicados pela cena para a HUD (atualizados com folga, não a cada frame).
    @Published var jogadorTile = GridPoint(x: 0, y: 0)
    @Published var bussola: CGVector?
    @Published var distanciaObjetivo: CGFloat?

    private let arquivo: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("GuardioesDosBiomas", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("save.json")
    }()

    init() { carregar() }

    // MARK: Essência

    var essenciaMaxima: CGFloat {
        100 + CGFloat(save.amuletos.count) * 35 + CGFloat(save.refugio.nivel("alojamento")) * 40
    }

    // MARK: Refúgio: recursos e melhorias

    var canteirosDisponiveis: Int { 4 + save.refugio.nivel("viveiro") * 2 }

    /// A oficina faz cada objetivo render mais pontos.
    var multiplicadorPontos: Double { 1 + Double(save.refugio.nivel("oficina")) * 0.25 }

    /// A torre de observação revela caches mesmo sem estar na forma de lobo.
    var faroPassivo: CGFloat { save.refugio.nivel("torre") > 0 ? 360 : 0 }

    func plantar(canteiro i: Int, especie: Especie) {
        guard save.refugio.canteiros.indices.contains(i) else { return }
        guard save.refugio.canteiros[i].especie == nil else { return }
        guard save.refugio.sementes >= especie.custoSementes else {
            avisar("Sementes insuficientes — objetivos de restauro rendem sementes.",
                   icone: "leaf.circle", cor: .alerta)
            return
        }
        save.refugio.sementes -= especie.custoSementes
        save.refugio.canteiros[i].especie = especie.id
        save.refugio.canteiros[i].plantadoEm = save.tempoJogado
        avisar("\(especie.nome) plantada. Volte quando estiver pronta.",
               icone: "leaf.fill", cor: .bom)
        salvar()
    }

    func colher(canteiro i: Int) {
        guard save.refugio.canteiros.indices.contains(i) else { return }
        let c = save.refugio.canteiros[i]
        guard let eid = c.especie, let sp = Especie.porId(eid),
              c.pronto(agora: save.tempoJogado) else { return }
        save.refugio.canteiros[i].especie = nil
        save.refugio.mudas += sp.mudas
        save.refugio.mudasCultivadas += sp.mudas
        if !save.refugio.especiesCultivadas.contains(eid) {
            save.refugio.especiesCultivadas.append(eid)
            descobrirCodex("viveiro")
        }
        somarPontos(sp.pontos)
        avisar("\(sp.nome) colhida: +\(sp.mudas) muda(s), +\(sp.pontos) pontos.",
               icone: "leaf.arrow.trianglehead.clockwise", cor: .conquista)
        salvar()
    }

    func custoDe(_ m: Melhoria) -> (pontos: Int, mudas: Int, peixes: Int)? {
        let n = save.refugio.nivel(m.id)
        guard n < m.nivelMaximo else { return nil }
        return m.custo(n + 1)
    }

    func podeComprar(_ m: Melhoria) -> Bool {
        guard let c = custoDe(m) else { return false }
        return save.pontos >= c.pontos && save.refugio.mudas >= c.mudas
            && save.refugio.peixes >= c.peixes
    }

    func comprar(_ m: Melhoria) {
        guard let c = custoDe(m), podeComprar(m) else {
            avisar("Recursos insuficientes.", icone: "xmark.circle", cor: .alerta)
            return
        }
        save.pontos -= c.pontos
        save.refugio.mudas -= c.mudas
        save.refugio.peixes -= c.peixes
        save.refugio.melhorias[m.id] = save.refugio.nivel(m.id) + 1
        if m.id == "alojamento" { essencia = essenciaMaxima }
        if m.id == "viveiro" {
            while save.refugio.canteiros.count < canteirosDisponiveis {
                save.refugio.canteiros.append(Canteiro(id: save.refugio.canteiros.count))
            }
        }
        avisar("\(m.nome) melhorada para o nível \(save.refugio.nivel(m.id)).",
               icone: m.icone, cor: .conquista)
        salvar()
    }

    func ganharSementes(_ n: Int) {
        save.refugio.sementes += n
    }

    // MARK: Pesca

    func iniciarPesca() {
        guard pesca == nil else { return }
        let cais = save.refugio.nivel("cais")
        var rng = SeededRandom(seed: UInt64(Date().timeIntervalSince1970 * 1000))
        pesca = PescaSession(tentativas: 3,
                             zonaCentro: rng.double(0.25, 0.75),
                             zonaLargura: 0.16 + Double(cais) * 0.06,
                             velocidade: 3.1 + rng.double(0, 0.9))
    }

    /// Chamada quando o jogador confirma a fisgada.
    func confirmarPesca() {
        guard var p = pesca, !p.encerrada else { return }
        let t = Date().timeIntervalSince(p.inicio)
        if p.acertou(em: t) {
            var rng = SeededRandom(seed: UInt64(t * 100000))
            let peixe = Peixe.sortear(nivelCais: save.refugio.nivel("cais"), rng: &rng)
            p.resultado = peixe
            p.encerrada = true
            registrarPeixe(peixe)
        } else {
            p.tentativas -= 1
            p.mensagem = p.tentativas > 0
                ? "Escapou. Tentativas restantes: \(p.tentativas)"
                : "O cardume dispersou."
            if p.tentativas <= 0 { p.encerrada = true }
        }
        pesca = p
    }

    private func registrarPeixe(_ peixe: Peixe) {
        save.refugio.peixesPescados += 1
        if !save.refugio.peixesVistos.contains(peixe.id) {
            save.refugio.peixesVistos.append(peixe.id)
            descobrirCodex("acude")
        }
        // Devolver à água o que precisa crescer vale mais do que levar embora.
        let bonus = peixe.soltar ? 2 : 1
        somarPontos(peixe.pontos * bonus)
        ganharEssencia(CGFloat(peixe.essencia))
        if !peixe.soltar { save.refugio.peixes += 1 }
        salvar()
    }

    func encerrarPesca() { pesca = nil }

    // MARK: Provas arcade

    func iniciarCorrida(_ bioma: BiomeID) {
        guard let c = Corrida[bioma] else { return }
        guard temAmuleto(c.forma) else {
            avisar("A prova de \(Biome[bioma].nome) exige o \(c.forma.amuleto).",
                   icone: "lock.fill", cor: .alerta)
            return
        }
        painelRefugio = nil
        dialogo = nil
        corrida = CorridaSessao(config: c, recorde: save.recordes[bioma.rawValue] ?? 0)
    }

    func encerrarCorrida() {
        corrida = nil
        salvar()
    }

    /// Fecha a conta da prova: recorde, pontos e progresso de missão.
    func concluirCorrida(sucesso: Bool, progresso: Int, coletados: Int) {
        guard let c = corrida?.config else { return }
        let chave = c.bioma.rawValue
        if progresso > (save.recordes[chave] ?? 0) {
            save.recordes[chave] = progresso
            avisar("Novo recorde em \(c.titulo): \(progresso)\(c.modo == .travessia ? " fileiras" : " m")",
                   icone: "flag.checkered", cor: .conquista)
        }
        somarPontos(progresso * 2 + coletados * 15)

        if sucesso {
            // Se a prova era a etapa atual, ela conta como cumprida.
            if !registrarObjetivo(.corrida, em: c.bioma) {
                avisar("Prova concluída: +\(progresso * 2 + coletados * 15) pontos.",
                       icone: "figure.run", cor: .conquista)
            }
            ganharSementes(2)
        } else {
            avisar("Prova interrompida. O percurso continua ali quando quiser tentar de novo.",
                   icone: "arrow.counterclockwise", cor: .neutro)
        }
        salvar()
    }

    func recorde(_ b: BiomeID) -> Int { save.recordes[b.rawValue] ?? 0 }

    // MARK: Operações

    /// Fecha a conta da operação: o que foi salvo, o que se perdeu, e se isso
    /// bastou para o Guardião.
    func concluirOperacao() {
        guard let s = operacao else { return }
        let id = s.config.bioma
        somarPontos(s.salvos * 120)
        ganharSementes(max(1, s.salvos / 3))

        if s.atingiuMeta {
            let contou = registrarObjetivo(ato(id) == .acesso ? .acesso : .desafio, em: id)
            if !contou {
                avisar("Operação encerrada: \(s.salvos) \(s.config.focoPlural) salvos.",
                       icone: "checkmark.seal.fill", cor: .conquista)
            }
        } else {
            avisar("A frente passou. \(s.salvos) de \(s.total) — a meta era \(s.config.meta).",
                   icone: "xmark.octagon.fill", cor: .alerta)
        }
        salvar()
    }

    /// Recomeça a operação do bioma (nova frente, novos focos).
    func reiniciarOperacao() {
        operacao = nil
        geracaoMundo += 1
        biomaCarregado = save.biomaAtual
    }

    /// A frente fica mais rápida a cada operação já corrida naquele bioma.
    func ritmoDaFrente(_ id: BiomeID) -> CGFloat {
        let feitas = save.biome(id).expedicoesConcluidas
        let ato2 = ato(id) != .acesso ? 0.18 : 0
        return 1.0 + CGFloat(feitas) * 0.12 + ato2
    }

    // MARK: A Harpia

    /// Ela só se mostra a quem devolveu a floresta inteira, não um pedaço.
    var condicoesHarpia: [(texto: String, feito: Bool)] {
        let expedicoes = BiomeID.exploraveis.allSatisfy { save.biome($0).expedicoesConcluidas >= 1 }
        return [
            ("Os cinco amuletos conquistados", save.amuletos.count >= 5),
            ("Uma expedição concluída em cada bioma", expedicoes),
            ("15 mudas cultivadas no viveiro (\(min(save.refugio.mudasCultivadas, 15))/15)",
             save.refugio.mudasCultivadas >= 15)
        ]
    }

    var harpiaLiberada: Bool { condicoesHarpia.allSatisfy { $0.feito } }

    var podeTransformar: Bool { essencia > 12 }

    // MARK: Amuletos

    func temAmuleto(_ f: AnimalForm) -> Bool {
        f == .humano || save.amuletos.contains(f)
    }

    var amuletosDisponiveis: [AnimalForm] {
        AnimalForm.vestiveis.filter { save.amuletos.contains($0) }
    }

    func conquistarAmuleto(_ forma: AnimalForm) {
        guard !save.amuletos.contains(forma) else { return }
        save.amuletos.append(forma)
        essencia = essenciaMaxima
        descobrirCodex(forma.rawValue)
        avisar("\(forma.amuleto) conquistado — \(forma.habilidade)", icone: "sparkles", cor: .conquista)
        somarPontos(500)
        salvar()
    }

    func trocarForma(_ nova: AnimalForm) {
        guard temAmuleto(nova) else {
            avisar("Você ainda não possui esse amuleto.", icone: "lock.fill", cor: .alerta)
            return
        }
        if nova != .humano && !podeTransformar {
            avisar("Essência insuficiente para se transformar.", icone: "bolt.slash.fill", cor: .alerta)
            return
        }
        guard nova != formaAtual else { return }
        formaAtual = nova
        if nova != .humano {
            essencia = max(0, essencia - 8)
            avisar("Forma: \(nova.nome)", icone: "arrow.triangle.2.circlepath", cor: .neutro)
        } else {
            avisar("De volta à forma humana", icone: "figure.walk", cor: .neutro)
        }
    }

    /// Chamado a cada frame pela cena.
    func atualizar(delta: TimeInterval) {
        save.tempoJogado += delta
        let d = CGFloat(delta)
        if formaAtual == .humano {
            essencia = min(essenciaMaxima, essencia + 9 * d)
        } else {
            essencia -= formaAtual.custoEssencia * d
            if essencia <= 0 {
                essencia = 0
                formaAtual = .humano
                avisar("A essência acabou — você voltou à forma humana.", icone: "bolt.slash.fill", cor: .alerta)
            }
        }
        toasts.removeAll { Date().timeIntervalSince($0.criado) > 4.2 }
    }

    var folegoMaximo: CGFloat { 100 }

    // MARK: Vida e santuário

    var vidaMaxima: Int { save.coracoes * 2 }

    func machucar(_ meios: Int = 1) {
        vida = max(0, vida - meios)
    }

    func curar(_ meios: Int) { vida = min(vidaMaxima, vida + meios) }

    func ganharCoracao() {
        save.coracoes += 1
        vida = vidaMaxima
        avisar("Fruto do Vigor — um coração a mais, para sempre.",
               icone: "heart.fill", cor: .conquista)
        salvar()
    }

    func chaves(_ id: BiomeID) -> Int { save.biome(id).chaves }
    func temMapa(_ id: BiomeID) -> Bool { save.biome(id).temMapa }
    func temBussola(_ id: BiomeID) -> Bool { save.biome(id).temBussola }
    func temChaveDoGuardiao(_ id: BiomeID) -> Bool { save.biome(id).temChaveDoGuardiao }

    func ganharTesouroDeSantuario(_ t: Tesouro, em id: BiomeID) {
        var b = save.biome(id)
        switch t {
        case .mapa:
            b.temMapa = true
            avisar("Planta do santuário — abra o mapa (M) para ver as salas.",
                   icone: "map.fill", cor: .conquista)
        case .bussola:
            b.temBussola = true
            avisar("Bússola do zelador — agora a planta marca baús e o Guardião.",
                   icone: "location.north.circle.fill", cor: .conquista)
        case .chaveDoGuardiao:
            b.temChaveDoGuardiao = true
            avisar("Chave do Guardião — a porta do fundo se abre.",
                   icone: "key.horizontal.fill", cor: .conquista)
        default: break
        }
        save.setBiome(id, b)
        salvar()
    }

    /// O Canto de cada Guardião: o instrumento que se leva de cada santuário.
    func cantoDe(_ id: BiomeID) -> String { "Canto d" + (id == .pampa ? "as Dunas" : "o " + Biome[id].animal.nome) }

    func temCanto(_ id: BiomeID) -> Bool { save.cantos.contains(id.rawValue) }
    var cantosReunidos: Int { save.cantos.count }

    func ganharCanto(_ id: BiomeID) {
        guard !save.cantos.contains(id.rawValue) else { return }
        save.cantos.append(id.rawValue)
        somarPontos(1200)
        avisar("\(cantoDe(id)) — \(save.cantos.count) de 5 Cantos.",
               icone: "music.note", cor: .conquista)
        salvar()
    }

    func ganharChave(_ id: BiomeID) {
        var b = save.biome(id); b.chaves += 1; save.setBiome(id, b)
        avisar("Chave pequena (\(b.chaves))", icone: "key.fill", cor: .bom)
        salvar()
    }

    @discardableResult
    func gastarChave(_ id: BiomeID) -> Bool {
        var b = save.biome(id)
        guard b.chaves > 0 else {
            avisar("Trancada. Falta uma chave pequena.", icone: "lock.fill", cor: .alerta)
            return false
        }
        b.chaves -= 1; save.setBiome(id, b)
        salvar()
        return true
    }

    func salaVisitada(_ id: BiomeID, _ c: GridPoint) -> Bool {
        save.biome(id).salasVisitadas.contains("\(c.x),\(c.y)")
    }

    func marcarSalaVisitada(_ id: BiomeID, _ c: GridPoint) {
        var b = save.biome(id)
        let k = "\(c.x),\(c.y)"
        guard !b.salasVisitadas.contains(k) else { return }
        b.salasVisitadas.append(k)
        save.setBiome(id, b)
    }

    func salaLimpa(_ id: BiomeID, _ c: GridPoint) -> Bool {
        save.biome(id).salasLimpas.contains("\(c.x),\(c.y)")
    }

    func marcarSalaLimpa(_ id: BiomeID, _ c: GridPoint) {
        var b = save.biome(id)
        let k = "\(c.x),\(c.y)"
        guard !b.salasLimpas.contains(k) else { return }
        b.salasLimpas.append(k); save.setBiome(id, b)
        salvar()
    }

    func bauAberto(_ id: BiomeID, _ c: GridPoint) -> Bool {
        save.biome(id).bausAbertos.contains("\(c.x),\(c.y)")
    }

    func marcarBauAberto(_ id: BiomeID, _ c: GridPoint) {
        var b = save.biome(id)
        b.bausAbertos.append("\(c.x),\(c.y)"); save.setBiome(id, b)
        salvar()
    }

    /// O santuário do bioma, sempre o mesmo para a mesma semente.
    func santuario(_ id: BiomeID) -> Santuario {
        Santuario.gerar(bioma: id, seed: Biome[id].semente)
    }

    /// Sem vida, você acorda na entrada do santuário — não perde o que juntou.
    func desmaiar(_ id: BiomeID) {
        vida = vidaMaxima
        save.pontos = max(0, save.pontos - 60)
        avisar("Você foi afugentado. Acordou na entrada do santuário.",
               icone: "figure.fall", cor: .alerta)
        salvar()
    }

    func ganharEssencia(_ v: CGFloat) {
        essencia = min(essenciaMaxima, essencia + v)
    }

    // MARK: Os dois atos de cada bioma

    /// Ato 1: conquistar o amuleto. Ato 2: provar que merece. Depois, campo livre.
    enum AtoBioma: Equatable { case acesso, merito, livre }

    func ato(_ id: BiomeID) -> AtoBioma {
        guard let a = Quests.acesso(for: id) else { return .livre }
        let bs = save.biome(id)
        if (bs.fragmentos[a.kind.rawValue] ?? 0) < a.alvo { return .acesso }
        let pendente = Quests.merito(for: id).contains {
            (bs.fragmentos[$0.kind.rawValue] ?? 0) < $0.alvo
        }
        return pendente ? .merito : .livre
    }

    /// Objetivos do ato corrente, com progresso.
    func objetivosDoAto(_ id: BiomeID) -> [(frag: Fragmento, feito: Int, completo: Bool)] {
        let bs = save.biome(id)
        let lista: [Fragmento]
        switch ato(id) {
        case .acesso: lista = Quests.acesso(for: id).map { [$0] } ?? []
        case .merito, .livre: lista = Quests.merito(for: id)
        }
        return lista.map { f in
            let feito = min(bs.fragmentos[f.kind.rawValue] ?? 0, f.alvo)
            return (f, feito, feito >= f.alvo)
        }
    }

    /// Tipos de objetivo que ainda valem alguma coisa neste bioma.
    func objetivosPendentes(_ id: BiomeID) -> [ObjectiveKind] {
        switch ato(id) {
        case .acesso:
            return Quests.acesso(for: id).map { [$0.kind] } ?? []
        case .merito:
            return objetivosDoAto(id).filter { !$0.completo }.map { $0.frag.kind }
        case .livre:
            let bs = save.biome(id)
            guard bs.expedicaoAtiva else { return [] }
            return [Quests.expedicao(biome: id, nivel: bs.nivelExpedicao,
                                     seed: Biome[id].semente).kind]
        }
    }

    func biomaConcluido(_ id: BiomeID) -> Bool { ato(id) == .livre }

    /// Nome antigo, mantido para o modo infinito e para a Harpia.
    func cadeiaConcluida(_ id: BiomeID) -> Bool { biomaConcluido(id) }

    func etapaAtual(_ id: BiomeID) -> QuestStage? {
        let bs = save.biome(id)
        guard ato(id) == .livre, bs.expedicaoAtiva else { return nil }
        return Quests.expedicao(biome: id, nivel: bs.nivelExpedicao, seed: Biome[id].semente)
    }

    func progressoAtual(_ id: BiomeID) -> (feito: Int, alvo: Int)? {
        guard let etapa = etapaAtual(id) else { return nil }
        return (min(save.biome(id).expedicaoProgresso, etapa.alvo), etapa.alvo)
    }

    /// Registra um objetivo cumprido no mundo. Retorna true se contou.
    @discardableResult
    func registrarObjetivo(_ kind: ObjectiveKind, em id: BiomeID) -> Bool {
        var bs = save.biome(id)
        let atoCorrente = ato(id)

        if atoCorrente != .livre {
            // Só conta o que pertence ao ato em andamento.
            let candidatos: [Fragmento] = atoCorrente == .acesso
                ? (Quests.acesso(for: id).map { [$0] } ?? [])
                : Quests.merito(for: id)
            guard let alvo = candidatos.first(where: { $0.kind == kind }) else { return false }
            let feito = bs.fragmentos[kind.rawValue] ?? 0
            guard feito < alvo.alvo else { return false }

            bs.fragmentos[kind.rawValue] = feito + 1
            bs.vestigiosTotais += 1
            save.setBiome(id, bs)
            somarPontos(Int(40 * multiplicadorPontos))
            if kind == .desafio || kind == .corrida { ganharSementes(2) }

            if feito + 1 >= alvo.alvo {
                concluirObjetivo(id, alvo, atoAnterior: atoCorrente)
            } else {
                avisar("\(alvo.nome): \(feito + 1)/\(alvo.alvo)", icone: kind.icone, cor: .bom)
            }
            salvar()
            return true
        }

        // --- Expedição infinita ---
        guard let etapa = etapaAtual(id), etapa.kind == kind else { return false }
        bs.expedicaoProgresso += 1
        bs.vestigiosTotais += 1
        save.setBiome(id, bs)
        somarPontos(Int(35 * multiplicadorPontos))
        if kind == .restauro || kind == .resgate { ganharSementes(1) }

        if bs.expedicaoProgresso >= etapa.alvo {
            concluirExpedicao(id)
        } else {
            avisar("\(etapa.kind.nome): \(bs.expedicaoProgresso)/\(etapa.alvo)",
                   icone: etapa.kind.icone, cor: .bom)
        }
        salvar()
        return true
    }

    private func concluirObjetivo(_ id: BiomeID, _ frag: Fragmento, atoAnterior: AtoBioma) {
        somarPontos(400)
        let novoAto = ato(id)

        if atoAnterior == .acesso {
            // O amuleto é concedido aqui, não dentro da árvore de diálogo:
            // fechar a conversa no ESC não pode deixar o jogador sem ele.
            conquistarAmuleto(Biome[id].animal)
            iniciarDialogo(DialogueBook.guardiao(de: id), contexto: id)
        } else if novoAto == .livre {
            // Ato 2 inteiro cumprido: o amuleto foi merecido.
            iniciarDialogo(DialogueBook.meritoProvado(de: id), contexto: id)
        } else {
            let faltam = objetivosDoAto(id).filter { !$0.completo }.map { $0.frag.nome }
            avisar("\(frag.nome) cumprido. Falta: \(faltam.joined(separator: ", "))",
                   icone: "checkmark.circle.fill", cor: .conquista)
        }
        salvar()
    }

    private func concluirExpedicao(_ id: BiomeID) {
        var bs = save.biome(id)
        bs.expedicaoAtiva = false
        bs.expedicaoProgresso = 0
        bs.expedicoesConcluidas += 1
        bs.nivelExpedicao += 1
        save.setBiome(id, bs)
        let recompensa = 300 + bs.nivelExpedicao * 60
        somarPontos(recompensa)
        ganharEssencia(60)
        avisar("Expedição concluída! +\(recompensa) pontos. Próximo nível: \(bs.nivelExpedicao)",
               icone: "flag.checkered", cor: .conquista)
        salvar()
    }

    func iniciarExpedicao(_ id: BiomeID) {
        guard ato(id) == .livre else { return }
        var bs = save.biome(id)
        guard !bs.expedicaoAtiva else { return }
        bs.expedicaoAtiva = true
        bs.expedicaoProgresso = 0
        save.setBiome(id, bs)
        let etapa = Quests.expedicao(biome: id, nivel: bs.nivelExpedicao, seed: Biome[id].semente)
        avisar("Nova expedição: \(etapa.titulo) — \(etapa.kind.verbo.lowercased()) \(etapa.alvo)",
               icone: "map.fill", cor: .bom)
        salvar()
    }

    // MARK: Viagem

    /// Não basta ter o amuleto: é preciso ter provado que o merece.
    func podeEntrar(_ id: BiomeID) -> Bool {
        guard let req = Biome[id].requisito else { return true }
        guard save.amuletos.contains(req) else { return false }
        guard let anterior = BiomeID.exploraveis.first(where: { Biome[$0].animal == req })
        else { return true }
        return biomaConcluido(anterior)
    }

    func viajar(para id: BiomeID) {
        guard podeEntrar(id) else {
            let req = Biome[id].requisito!
            if save.amuletos.contains(req) {
                avisar("Você tem o \(req.amuleto), mas ainda não provou que o merece.",
                       icone: "lock.fill", cor: .alerta)
            } else {
                avisar("O caminho exige o \(req.amuleto).", icone: "lock.fill", cor: .alerta)
            }
            return
        }
        var bs = save.biome(id)
        let primeiraVez = !bs.visitado
        bs.visitado = true
        save.setBiome(id, bs)
        save.biomaAtual = id
        biomaCarregado = id
        geracaoMundo += 1
        formaAtual = .humano
        tela = .jogo
        salvar()

        if primeiraVez {
            descobrirCodex("bioma_\(id.rawValue)")
            iniciarDialogo(DialogueBook.chegada(em: id), contexto: id)
        } else {
            avisar("Você chegou: \(Biome[id].nome)", icone: "location.fill", cor: .neutro)
        }
    }

    // MARK: Diálogo

    func iniciarDialogo(_ no: DialogueNode?, contexto: BiomeID) {
        guard let no else { return }
        var sessao = DialogueSession(raiz: no, bioma: contexto)
        sessao.entrar(self)
        dialogo = sessao
    }

    func avancarDialogo(escolha: Int? = nil) {
        guard var sessao = dialogo else { return }
        if sessao.avancar(escolha: escolha, estado: self) {
            dialogo = sessao
        } else {
            dialogo = nil
            salvar()
        }
    }

    // MARK: Códice e pontos

    func descobrirCodex(_ chave: String) {
        guard !save.codex.contains(chave) else { return }
        save.codex.append(chave)
        somarPontos(80)
        avisar("Novo registro no Códice", icone: "book.fill", cor: .bom)
        salvar()
    }

    func ligarFlag(_ f: String) {
        guard !save.flags.contains(f) else { return }
        save.flags.append(f)
    }

    func temFlag(_ f: String) -> Bool { save.flags.contains(f) }

    func somarPontos(_ p: Int) { save.pontos += p }

    /// Painéis do Refúgio abertos por interação no mundo.
    enum PainelRefugio: Equatable {
        case viveiro(canteiro: Int)
        case oficina
        case harpia
    }

    /// Índice de Biodiversidade: a métrica que cresce para sempre.
    var indiceBiodiversidade: Int { save.pontos }

    var nivelGuardiao: Int { max(1, Int(Double(save.pontos).squareRoot() / 12) + 1) }

    var tituloGuardiao: String {
        switch nivelGuardiao {
        case 1: return "Aprendiz de campo"
        case 2: return "Monitor de fauna"
        case 3: return "Biólogo de campo"
        case 4: return "Guardião do corredor"
        case 5: return "Guardião de bioma"
        case 6: return "Voz da floresta"
        case 7...9: return "Guardião maior"
        default: return "Lenda dos biomas"
        }
    }

    func avisar(_ texto: String, icone: String, cor: ToastColor) {
        toasts.append(Toast(texto: texto, icone: icone, cor: cor))
        if toasts.count > 4 { toasts.removeFirst(toasts.count - 4) }
    }

    // MARK: Save / Load

    func salvar() {
        do {
            let enc = JSONEncoder()
            enc.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try enc.encode(save)
            try data.write(to: arquivo, options: .atomic)
        } catch {
            print("Falha ao salvar: \(error)")
        }
    }

    func carregar() {
        guard let data = try? Data(contentsOf: arquivo),
              let s = try? JSONDecoder().decode(SaveData.self, from: data) else { return }
        save = s
        biomaCarregado = s.biomaAtual
        essencia = essenciaMaxima
    }

    var temPartidaSalva: Bool {
        save.pontos > 0 || !save.biomas.isEmpty
    }

    func novaPartida() {
        save = SaveData()
        formaAtual = .humano
        essencia = 100
        biomaCarregado = .refugio
        geracaoMundo += 1
        tela = .jogo
        salvar()
        iniciarDialogo(DialogueBook.abertura(), contexto: .refugio)
    }

    func continuar() {
        biomaCarregado = save.biomaAtual
        geracaoMundo += 1
        formaAtual = .humano
        essencia = essenciaMaxima
        tela = .jogo
    }

    func apagarProgresso() {
        try? FileManager.default.removeItem(at: arquivo)
        save = SaveData()
        formaAtual = .humano
        essencia = 100
        tela = .menu
    }
}
