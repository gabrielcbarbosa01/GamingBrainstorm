//
//  JournalView.swift
//  Guardiões dos Biomas
//
//  O Códice — o caderno de campo herdado da avó. Fichas se abrem conforme o
//  jogador descobre bichos, biomas e mecânicas.
//

import SwiftUI
import SpriteKit

struct JournalView: View {
    @ObservedObject var st: GameState
    @State private var categoria: CodexCategoria = .animais
    @State private var selecionado: String?

    private var entradas: [CodexEntry] {
        Codex.todos.filter { $0.categoria == categoria }
    }

    private func desbloqueado(_ e: CodexEntry) -> Bool {
        st.save.codex.contains(e.id)
    }

    var body: some View {
        HStack(spacing: 0) {
            lista
            Divider().background(Tema.ouro.opacity(0.2))
            detalhe
        }
        .background(Tema.cor(Palette.refugio.sky).opacity(0.98).ignoresSafeArea())
        .onAppear {
            if selecionado == nil {
                selecionado = entradas.first(where: desbloqueado)?.id
            }
        }
    }

    private var lista: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("CÓDICE")
                    .font(.system(size: 22, weight: .heavy, design: .serif))
                    .tracking(3)
                    .foregroundStyle(Tema.papel)
                Spacer()
                Button {
                    st.tela = .jogo
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Tema.papel.opacity(0.5))
                }
                .buttonStyle(.plain)
            }

            Text("\(st.save.codex.count) de \(Codex.todos.count) registros")
                .font(Tema.rotulo)
                .foregroundStyle(Tema.papel.opacity(0.5))

            Picker("", selection: $categoria) {
                ForEach(CodexCategoria.allCases) { c in
                    Text(c.rawValue).tag(c)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            ScrollView {
                VStack(spacing: 6) {
                    ForEach(entradas) { e in
                        linha(e)
                    }
                }
            }
            Spacer()
        }
        .padding(20)
        .frame(width: 300)
    }

    private func linha(_ e: CodexEntry) -> some View {
        let aberto = desbloqueado(e)
        let ativo = selecionado == e.id
        return Button {
            if aberto { selecionado = e.id }
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7).fill(Color.white.opacity(0.07))
                    if aberto, let forma = AnimalForm(rawValue: e.id) {
                        Image(nsImage: Creatures.retrato(forma))
                            .interpolation(.high).resizable().scaledToFit().padding(2)
                    } else {
                        Image(systemName: aberto ? iconeCategoria(e.categoria) : "lock.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(Tema.papel.opacity(aberto ? 0.7 : 0.3))
                    }
                }
                .frame(width: 38, height: 38)

                VStack(alignment: .leading, spacing: 1) {
                    Text(aberto ? e.titulo : "Registro bloqueado")
                        .font(.system(size: 13, weight: .semibold, design: .serif))
                        .foregroundStyle(Tema.papel.opacity(aberto ? 1 : 0.4))
                    Text(aberto ? e.subtitulo : "descubra em campo")
                        .font(.system(size: 10, design: .rounded))
                        .foregroundStyle(Tema.papel.opacity(0.45))
                }
                Spacer()
            }
            .padding(8)
            .background(RoundedRectangle(cornerRadius: 9)
                .fill(ativo ? Tema.ouro.opacity(0.16) : Color.clear))
        }
        .buttonStyle(.plain)
    }

    private func iconeCategoria(_ c: CodexCategoria) -> String {
        switch c {
        case .animais: return "pawprint.fill"
        case .biomas: return "mountain.2.fill"
        case .campo: return "book.closed.fill"
        }
    }

    @ViewBuilder
    private var detalhe: some View {
        if let id = selecionado, let e = Codex.entry(id), desbloqueado(e) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .top, spacing: 16) {
                        if let forma = AnimalForm(rawValue: e.id) {
                            Image(nsImage: Creatures.retrato(forma))
                                .interpolation(.high).resizable().scaledToFit()
                                .frame(width: 110, height: 110)
                                .background(RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.white.opacity(0.05)))
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text(e.titulo)
                                .font(.system(size: 28, weight: .bold, design: .serif))
                                .foregroundStyle(Tema.papel)
                            Text(e.subtitulo)
                                .font(.system(size: 14, design: .serif))
                                .italic()
                                .foregroundStyle(Tema.papel.opacity(0.6))
                            HStack(spacing: 6) {
                                Circle().fill(corStatus(e.statusCor)).frame(width: 8, height: 8)
                                Text(e.status)
                                    .font(Tema.rotulo)
                                    .foregroundStyle(corStatus(e.statusCor))
                            }
                            .padding(.top, 2)

                            if let forma = AnimalForm(rawValue: e.id), st.temAmuleto(forma) {
                                Text("\(forma.amuleto) · \(forma.habilidade)")
                                    .font(Tema.rotulo)
                                    .foregroundStyle(Tema.ouro)
                                    .padding(.horizontal, 8).padding(.vertical, 4)
                                    .background(Capsule().fill(Tema.ouro.opacity(0.14)))
                            }
                        }
                        Spacer()
                    }

                    ForEach(e.paragrafos, id: \.self) { p in
                        Text(p)
                            .font(.system(size: 15, design: .serif))
                            .lineSpacing(5)
                            .foregroundStyle(Tema.papel.opacity(0.92))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if !e.curiosidades.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ANOTAÇÕES DE MARGEM")
                                .font(Tema.rotulo).tracking(1.4)
                                .foregroundStyle(Tema.ouro)
                            ForEach(e.curiosidades, id: \.self) { c in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("—").foregroundStyle(Tema.ouro.opacity(0.6))
                                    Text(c)
                                        .font(.system(size: 13, design: .serif))
                                        .foregroundStyle(Tema.papel.opacity(0.8))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.05)))
                    }
                }
                .padding(30)
                .frame(maxWidth: 640, alignment: .leading)
            }
            .frame(maxWidth: .infinity)
        } else {
            VStack(spacing: 10) {
                Image(systemName: "book.closed")
                    .font(.system(size: 40))
                    .foregroundStyle(Tema.papel.opacity(0.25))
                Text("Nenhum registro aberto ainda.\nExplore os biomas para preencher o caderno.")
                    .multilineTextAlignment(.center)
                    .font(Tema.corpo)
                    .foregroundStyle(Tema.papel.opacity(0.45))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func corStatus(_ s: StatusCor) -> Color {
        switch s {
        case .critico: return Color(nsColor: SKColor(hex: 0xE04A32))
        case .ameacado: return Color(nsColor: SKColor(hex: 0xE8862E))
        case .vulneravel: return Color(nsColor: SKColor(hex: 0xE8C23A))
        case .quaseAmeacado: return Color(nsColor: SKColor(hex: 0x8CC85A))
        case .estavel: return Color(nsColor: SKColor(hex: 0x5AD0A8))
        }
    }
}
