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
    var etapa: Int = 0             // índice na cadeia principal
    var progresso: Int = 0         // contagem da etapa atual
    var visitado: Bool = false
    var nivelExpedicao: Int = 1
    var expedicaoAtiva: Bool = false
    var expedicaoProgresso: Int = 0
    var expedicoesConcluidas: Int = 0
    var vestigiosTotais: Int = 0
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

    func ganharEssencia(_ v: CGFloat) {
        essencia = min(essenciaMaxima, essencia + v)
    }

    // MARK: Missões

    /// Etapa ativa do bioma: a da cadeia principal ou a expedição infinita.
    func etapaAtual(_ id: BiomeID) -> QuestStage? {
        let chain = Quests.chain(for: id)
        let bs = save.biome(id)
        if bs.etapa < chain.etapas.count { return chain.etapas[bs.etapa] }
        if bs.expedicaoAtiva {
            return Quests.expedicao(biome: id, nivel: bs.nivelExpedicao, seed: Biome[id].semente)
        }
        return nil
    }

    func progressoAtual(_ id: BiomeID) -> (feito: Int, alvo: Int)? {
        guard let etapa = etapaAtual(id) else { return nil }
        let bs = save.biome(id)
        let chain = Quests.chain(for: id)
        let feito = bs.etapa < chain.etapas.count ? bs.progresso : bs.expedicaoProgresso
        return (min(feito, etapa.alvo), etapa.alvo)
    }

    func cadeiaConcluida(_ id: BiomeID) -> Bool {
        save.biome(id).etapa >= Quests.chain(for: id).etapas.count
    }

    /// Registra um objetivo cumprido no mundo. Retorna true se contou.
    @discardableResult
    func registrarObjetivo(_ kind: ObjectiveKind, em id: BiomeID) -> Bool {
        guard let etapa = etapaAtual(id), etapa.kind == kind else { return false }
        var bs = save.biome(id)
        let chain = Quests.chain(for: id)
        let naCadeia = bs.etapa < chain.etapas.count

        if naCadeia { bs.progresso += 1 } else { bs.expedicaoProgresso += 1 }
        bs.vestigiosTotais += 1
        save.setBiome(id, bs)
        somarPontos(Int(35 * multiplicadorPontos))
        // Restauro e resgate rendem sementes para o viveiro do Refúgio.
        if kind == .restauro || kind == .resgate { ganharSementes(1) }

        let feito = naCadeia ? bs.progresso : bs.expedicaoProgresso
        if feito >= etapa.alvo {
            concluirEtapa(id)
        } else {
            avisar("\(etapa.kind.nome): \(feito)/\(etapa.alvo)", icone: etapa.kind.icone, cor: .bom)
        }
        salvar()
        return true
    }

    private func concluirEtapa(_ id: BiomeID) {
        var bs = save.biome(id)
        let chain = Quests.chain(for: id)

        if bs.etapa < chain.etapas.count {
            let concluida = chain.etapas[bs.etapa]
            bs.etapa += 1
            bs.progresso = 0
            save.setBiome(id, bs)
            somarPontos(250)
            avisar("Etapa concluída: \(concluida.titulo)", icone: "checkmark.seal.fill", cor: .conquista)

            if bs.etapa >= chain.etapas.count {
                // Cadeia inteira concluída: o Guardião do bioma aparece.
                iniciarDialogo(DialogueBook.guardiao(de: id), contexto: id)
            } else {
                iniciarDialogo(DialogueBook.avancoDeEtapa(de: id, etapa: bs.etapa), contexto: id)
            }
        } else {
            // Expedição infinita concluída — sobe o nível de dificuldade.
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
        }
        salvar()
    }

    func iniciarExpedicao(_ id: BiomeID) {
        guard cadeiaConcluida(id) else { return }
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

    func podeEntrar(_ id: BiomeID) -> Bool {
        guard let req = Biome[id].requisito else { return true }
        return save.amuletos.contains(req)
    }

    func viajar(para id: BiomeID) {
        guard podeEntrar(id) else {
            let req = Biome[id].requisito!
            avisar("O caminho exige o \(req.amuleto).", icone: "lock.fill", cor: .alerta)
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
