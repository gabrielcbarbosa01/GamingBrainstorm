//
//  MenuView.swift
//  Guardiões dos Biomas
//

import SwiftUI

struct MenuView: View {
    @ObservedObject var st: GameState
    @State private var confirmandoApagar = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [Tema.cor(Palette.mataAtlantica.sky),
                                    Tema.cor(Palette.amazonia.sky)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            // Faixa decorativa com os cinco bichos.
            HStack(spacing: 0) {
                ForEach(AnimalForm.amuletos) { f in
                    Image(nsImage: Creatures.retrato(f))
                        .interpolation(.high)
                        .resizable().scaledToFit()
                        .frame(height: 150)
                        .opacity(st.temAmuleto(f) ? 0.5 : 0.14)
                }
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
            .padding(.bottom, 24)

            VStack(spacing: 26) {
                VStack(spacing: 8) {
                    Text("GUARDIÕES DOS BIOMAS")
                        .font(.system(size: 42, weight: .heavy, design: .serif))
                        .tracking(3)
                        .foregroundStyle(Tema.papel)
                    Text("cinco animais ameaçados · cinco amuletos · um mundo sem fim")
                        .font(.system(size: 14, weight: .medium, design: .serif))
                        .foregroundStyle(Tema.ouro.opacity(0.9))
                }

                if st.temPartidaSalva {
                    VStack(spacing: 4) {
                        Text("\(st.tituloGuardiao) · \(st.indiceBiodiversidade) pontos")
                            .font(Tema.corpo)
                            .foregroundStyle(Tema.papel.opacity(0.8))
                        Text("\(st.save.amuletos.count)/5 amuletos · \(tempoFormatado) em campo")
                            .font(Tema.rotulo)
                            .foregroundStyle(Tema.papel.opacity(0.5))
                    }
                }

                VStack(spacing: 10) {
                    if st.temPartidaSalva {
                        botao("Continuar expedição", destaque: true) { st.continuar() }
                    }
                    botao(st.temPartidaSalva ? "Recomeçar do zero" : "Começar", destaque: !st.temPartidaSalva) {
                        if st.temPartidaSalva { confirmandoApagar = true } else { st.novaPartida() }
                    }
                    if st.temPartidaSalva {
                        botao("Voltar ao jogo") { st.tela = .jogo }
                    }
                    botao("Como se joga") { st.tela = .creditos }
                }
                .frame(width: 300)
            }
            .padding(40)
        }
        .alert("Apagar todo o progresso?", isPresented: $confirmandoApagar) {
            Button("Apagar", role: .destructive) {
                st.apagarProgresso()
                st.novaPartida()
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Os cinco amuletos, o Índice de Biodiversidade e o Códice voltam ao zero.")
        }
    }

    private var tempoFormatado: String {
        let m = Int(st.save.tempoJogado) / 60
        return m < 60 ? "\(m) min" : "\(m / 60) h \(m % 60) min"
    }

    private func botao(_ titulo: String, destaque: Bool = false, acao: @escaping () -> Void) -> some View {
        Button(action: acao) {
            Text(titulo)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(destaque ? Tema.ouro.opacity(0.88) : Color.white.opacity(0.10))
                )
                .foregroundStyle(destaque ? Tema.tinta : Tema.papel)
        }
        .buttonStyle(.plain)
    }
}

struct ComoSeJogaView: View {
    @ObservedObject var st: GameState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Como se joga")
                    .font(Tema.titulo)
                    .foregroundStyle(Tema.papel)

                secao("A ideia", [
                    "Você é guardiã(o) de campo. Explora cinco biomas brasileiros gerados sem limite, registra vestígios, liberta animais presos e recupera áreas degradadas.",
                    "Cada bioma tem um animal ameaçado e um Guardião. Concluindo as três tarefas do bioma, o Guardião entrega o amuleto — e o amuleto abre o bioma seguinte.",
                    "Depois dos cinco amuletos o jogo não acaba: cada bioma passa a gerar expedições infinitas, cada uma mais difícil que a anterior."
                ])

                secao("Controles", [
                    "WASD ou setas — andar",
                    "ESPAÇO — o movimento especial da forma atual (é o botão mais importante do jogo)",
                    "E — interagir e avançar diálogos",
                    "1 a 6 — vestir um amuleto · Q — voltar à forma humana",
                    "TAB — Códice · M — mapa · R — nova expedição · ESC — menu"
                ])

                secao("Cada bicho, um movimento", AnimalForm.vestiveis.map {
                    "\($0.icone) \($0.nome) — \($0.verbo.nome.uppercased()): \($0.verbo.dica)"
                })

                secao("As travessias", [
                    "Cada amuleto abre um tipo de barreira: cipoal, espinheiro, abismo, água funda e terra compactada.",
                    "Mas o movimento vale mais que a chave: saltando, o mico passa por cima de água, cipó e abismo sem precisar do amuleto correspondente.",
                    "No ar você atravessa quase tudo — só o paredão de rocha continua sendo parede."
                ])

                secao("O Refúgio", [
                    "Viveiro: plante mudas de espécies reais de restauração. Elas crescem com o tempo de jogo e viram matéria-prima.",
                    "Açude: pesque no minigame de tempo. Espécies migradoras e juvenis valem o dobro quando você as devolve à água.",
                    "Oficina: troque pontos, mudas e peixes por melhorias permanentes — mais canteiros, mais essência, torre de observação, ferramenta melhor.",
                    "Sementes vêm dos objetivos de restauro e resgate no campo."
                ])

                secao("A Harpia", [
                    "Ela aparece na primeira noite, dá uma dica e some.",
                    "Só volta quando o mundo inteiro tiver voltado: os cinco amuletos, uma expedição em cada bioma e quinze mudas cultivadas no viveiro.",
                    "Aí ela vira a sexta forma — e nenhuma barreira deste mundo se aplica a você."
                ])

                secao("Essência", [
                    "Transformar-se consome essência continuamente, e voar ou planar consome muito mais.",
                    "Na forma humana a essência regenera sozinha; orbes espalhadas pelo mundo devolvem 30 de uma vez, e peixe também.",
                    "Só a forma humana conversa com pessoas, abre armadilhas, planta e pesca."
                ])

                secao("Ameaças", [
                    "Nenhum bicho morre neste jogo e você também não. Se uma ameaça te alcança, você é afugentado e perde pontos.",
                    "Como tuco-tuco, escavando, ninguém enxerga você. Como pirarucu, submerso, também não.",
                    "A investida do lobo-guará empurra as ameaças para longe."
                ])

                Button("Voltar") { st.tela = st.temPartidaSalva ? .menu : .menu }
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 8)
            }
            .padding(40)
            .frame(maxWidth: 780, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
        .background(Tema.cor(Palette.amazonia.sky).ignoresSafeArea())
    }

    private func secao(_ titulo: String, _ itens: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(titulo.uppercased())
                .font(Tema.rotulo).tracking(1.4)
                .foregroundStyle(Tema.ouro)
            ForEach(itens, id: \.self) { i in
                HStack(alignment: .top, spacing: 8) {
                    Circle().fill(Tema.ouro.opacity(0.5)).frame(width: 4, height: 4).padding(.top, 7)
                    Text(i)
                        .font(Tema.corpo)
                        .foregroundStyle(Tema.papel.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}
