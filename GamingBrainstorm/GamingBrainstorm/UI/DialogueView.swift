//
//  DialogueView.swift
//  Guardiões dos Biomas
//
//  Painel de conversa. Enquanto está aberto o mundo congela — a fala é a cena.
//

import SwiftUI

struct DialogueView: View {
    @ObservedObject var st: GameState
    let sessao: DialogueSession

    var body: some View {
        VStack {
            Spacer()
            HStack(alignment: .top, spacing: 16) {
                retrato
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(sessao.atual.falante)
                            .font(.system(size: 18, weight: .bold, design: .serif))
                            .foregroundStyle(Tema.ouro)
                        if !sessao.atual.papel.isEmpty {
                            Text(sessao.atual.papel)
                                .font(Tema.rotulo)
                                .foregroundStyle(Tema.papel.opacity(0.55))
                        }
                    }

                    Text(sessao.falaAtual)
                        .font(.system(size: 16, weight: .regular, design: .serif))
                        .foregroundStyle(Tema.papel)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if sessao.mostrandoEscolhas {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(Array(sessao.atual.escolhas.enumerated()), id: \.offset) { i, escolha in
                                Button {
                                    st.avancarDialogo(escolha: i)
                                } label: {
                                    HStack(spacing: 8) {
                                        Text("\(i + 1)")
                                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                                            .padding(.horizontal, 6).padding(.vertical, 2)
                                            .background(RoundedRectangle(cornerRadius: 4)
                                                .fill(Tema.ouro.opacity(0.25)))
                                        Text(escolha.texto)
                                            .font(.system(size: 14, design: .serif))
                                        Spacer()
                                    }
                                    .foregroundStyle(Tema.papel)
                                    .padding(.horizontal, 12).padding(.vertical, 8)
                                    .background(RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.white.opacity(0.07)))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.top, 2)
                    } else {
                        HStack(spacing: 6) {
                            Spacer()
                            Text("E")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 5).padding(.vertical, 1.5)
                                .background(RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white.opacity(0.14)))
                            Text("continuar")
                                .font(Tema.rotulo)
                        }
                        .foregroundStyle(Tema.papel.opacity(0.55))
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: 860)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.black.opacity(0.86))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Tema.ouro.opacity(0.35), lineWidth: 1.2)
            )
            .padding(.horizontal, 40)
            .padding(.bottom, 34)
            .onTapGesture {
                if !sessao.mostrandoEscolhas { st.avancarDialogo() }
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    @ViewBuilder
    private var retrato: some View {
        let moldura = RoundedRectangle(cornerRadius: 14, style: .continuous)
        ZStack {
            moldura.fill(Color.white.opacity(0.06))
            if let forma = sessao.atual.retrato, forma != .humano {
                Image(nsImage: Creatures.retrato(forma))
                    .interpolation(.high)
                    .resizable().scaledToFit()
                    .padding(6)
            } else if sessao.atual.falante.contains("Iara") {
                Image(nsImage: Creatures.retratoNPC("iara"))
                    .interpolation(.high)
                    .resizable().scaledToFit()
                    .padding(6)
            } else if sessao.atual.falante.contains("Téo") {
                Image(nsImage: Creatures.retratoNPC("teo"))
                    .interpolation(.high)
                    .resizable().scaledToFit()
                    .padding(6)
            } else {
                Text(String(sessao.atual.falante.prefix(1)))
                    .font(.system(size: 40, weight: .bold, design: .serif))
                    .foregroundStyle(Tema.cor(Biome[sessao.bioma].palette.accent))
            }
        }
        .frame(width: 96, height: 96)
        .overlay(moldura.strokeBorder(Tema.ouro.opacity(0.3), lineWidth: 1))
    }
}
