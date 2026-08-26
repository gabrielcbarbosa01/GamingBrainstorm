//
//  RefugioViews.swift
//  Guardiões dos Biomas
//
//  Painéis da base: viveiro (plantio), oficina (melhorias), pesca (minigame)
//  e o painel da Harpia com as condições do reencontro.
//

import SwiftUI
import SpriteKit

/// Moldura comum dos painéis do Refúgio.
private struct PainelBase<Conteudo: View>: View {
    let titulo: String
    let subtitulo: String
    let icone: String
    @ObservedObject var st: GameState
    @ViewBuilder var conteudo: Conteudo

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
                .onTapGesture { st.painelRefugio = nil }

            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: icone)
                        .font(.system(size: 22))
                        .foregroundStyle(Tema.ouro)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(titulo)
                            .font(.system(size: 22, weight: .bold, design: .serif))
                            .foregroundStyle(Tema.papel)
                        Text(subtitulo)
                            .font(Tema.rotulo)
                            .foregroundStyle(Tema.papel.opacity(0.55))
                    }
                    Spacer()
                    Button { st.painelRefugio = nil } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(Tema.papel.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                }

                RecursosView(st: st)

                ScrollView { conteudo }
                    .frame(maxHeight: 380)
            }
            .padding(24)
            .frame(width: 620)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(nsColor: Palette.refugio.sky).opacity(0.97)))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Tema.ouro.opacity(0.35), lineWidth: 1.2))
        }
    }
}

/// Linha de recursos: pontos, sementes, mudas e peixes.
struct RecursosView: View {
    @ObservedObject var st: GameState

    var body: some View {
        HStack(spacing: 14) {
            item("★", "\(st.save.pontos)", Tema.ouro, "pontos de conservação")
            item("🌱", "\(st.save.refugio.sementes)", Color(nsColor: SKColor(hex: 0x9AD06A)), "sementes")
            item("🌿", "\(st.save.refugio.mudas)", Color(nsColor: SKColor(hex: 0x5AC88A)), "mudas")
            item("🐟", "\(st.save.refugio.peixes)", Tema.essencia, "peixes guardados")
        }
    }

    private func item(_ icone: String, _ valor: String, _ cor: Color, _ ajuda: String) -> some View {
        HStack(spacing: 5) {
            Text(icone).font(.system(size: 13))
            Text(valor)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(cor)
        }
        .padding(.horizontal, 9).padding(.vertical, 5)
        .background(Capsule().fill(Color.white.opacity(0.07)))
        .help(ajuda)
    }
}

// MARK: - Viveiro

struct ViveiroView: View {
    @ObservedObject var st: GameState
    let canteiro: Int

    var body: some View {
        PainelBase(titulo: "Viveiro do Refúgio",
                   subtitulo: "canteiro \(canteiro + 1) de \(st.canteirosDisponiveis)",
                   icone: "leaf.fill", st: st) {
            VStack(spacing: 10) {
                ForEach(Especie.catalogo) { sp in
                    linha(sp)
                }
            }
        }
    }

    private func linha(_ sp: Especie) -> some View {
        let podePagar = st.save.refugio.sementes >= sp.custoSementes
        return HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(sp.nome)
                        .font(.system(size: 15, weight: .semibold, design: .serif))
                        .foregroundStyle(Tema.papel)
                    Text(sp.cientifico)
                        .font(.system(size: 11, design: .serif)).italic()
                        .foregroundStyle(Tema.papel.opacity(0.45))
                    Circle().fill(Tema.cor(Biome[sp.bioma].palette.accent))
                        .frame(width: 7, height: 7)
                    Text(Biome[sp.bioma].nome)
                        .font(Tema.rotulo)
                        .foregroundStyle(Tema.papel.opacity(0.45))
                }
                Text(sp.papel)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(Tema.papel.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 10) {
                    etiqueta("🌱 \(sp.custoSementes)", podePagar ? Tema.papel.opacity(0.7) : Tema.perigo)
                    etiqueta("⏳ \(Int(sp.tempo))s", Tema.papel.opacity(0.55))
                    etiqueta("🌿 \(sp.mudas)", Tema.essencia)
                    etiqueta("★ \(sp.pontos)", Tema.ouro)
                }
            }
            Spacer()
            Button {
                st.plantar(canteiro: canteiro, especie: sp)
                st.painelRefugio = nil
            } label: {
                Text("Plantar")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 9)
                        .fill(podePagar ? Tema.ouro.opacity(0.85) : Color.white.opacity(0.08)))
                    .foregroundStyle(podePagar ? Tema.tinta : Tema.papel.opacity(0.4))
            }
            .buttonStyle(.plain)
            .disabled(!podePagar)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05)))
    }

    private func etiqueta(_ t: String, _ c: Color) -> some View {
        Text(t).font(.system(size: 11, weight: .semibold, design: .rounded)).foregroundStyle(c)
    }
}

// MARK: - Oficina

struct OficinaView: View {
    @ObservedObject var st: GameState

    var body: some View {
        PainelBase(titulo: "Oficina de campo",
                   subtitulo: "pontos e recursos viram estrutura permanente",
                   icone: "wrench.and.screwdriver.fill", st: st) {
            VStack(spacing: 10) {
                ForEach(Melhoria.catalogo) { m in
                    linha(m)
                }
            }
        }
    }

    private func linha(_ m: Melhoria) -> some View {
        let nivel = st.save.refugio.nivel(m.id)
        let custo = st.custoDe(m)
        let pode = st.podeComprar(m)
        return HStack(alignment: .top, spacing: 14) {
            Image(systemName: m.icone)
                .font(.system(size: 18))
                .foregroundStyle(nivel > 0 ? Tema.ouro : Tema.papel.opacity(0.5))
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(m.nome)
                        .font(.system(size: 15, weight: .semibold, design: .serif))
                        .foregroundStyle(Tema.papel)
                    HStack(spacing: 3) {
                        ForEach(0..<m.nivelMaximo, id: \.self) { i in
                            Circle()
                                .fill(i < nivel ? Tema.ouro : Color.white.opacity(0.15))
                                .frame(width: 7, height: 7)
                        }
                    }
                }
                Text(m.descricao)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(Tema.papel.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)
                if let c = custo {
                    HStack(spacing: 10) {
                        if c.pontos > 0 {
                            etiqueta("★ \(c.pontos)", st.save.pontos >= c.pontos)
                        }
                        if c.mudas > 0 {
                            etiqueta("🌿 \(c.mudas)", st.save.refugio.mudas >= c.mudas)
                        }
                        if c.peixes > 0 {
                            etiqueta("🐟 \(c.peixes)", st.save.refugio.peixes >= c.peixes)
                        }
                    }
                }
            }
            Spacer()
            if custo == nil {
                Text("máximo")
                    .font(Tema.rotulo)
                    .foregroundStyle(Tema.ouro)
                    .padding(.horizontal, 12).padding(.vertical, 8)
            } else {
                Button { st.comprar(m) } label: {
                    Text(nivel == 0 ? "Construir" : "Melhorar")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 9)
                            .fill(pode ? Tema.ouro.opacity(0.85) : Color.white.opacity(0.08)))
                        .foregroundStyle(pode ? Tema.tinta : Tema.papel.opacity(0.4))
                }
                .buttonStyle(.plain)
                .disabled(!pode)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05)))
    }

    private func etiqueta(_ t: String, _ ok: Bool) -> some View {
        Text(t)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundStyle(ok ? Tema.papel.opacity(0.8) : Tema.perigo)
    }
}

// MARK: - Harpia

struct HarpiaView: View {
    @ObservedObject var st: GameState

    var body: some View {
        PainelBase(titulo: "A Harpia",
                   subtitulo: st.save.amuletos.contains(.harpia)
                       ? "a floresta ficou grande de novo"
                       : "ela observa do galho seco",
                   icone: "crown.fill", st: st) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 16) {
                    Image(nsImage: Creatures.retrato(.harpia))
                        .interpolation(.high).resizable().scaledToFit()
                        .frame(width: 96, height: 96)
                        .background(RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.05)))
                    Text(st.save.amuletos.contains(.harpia)
                         ? "“Voo porque a floresta ficou grande de novo. Foi você que fez o céu caber.”"
                         : "“Um predador de topo não se convence com pedaço de mata. Ou o território inteiro volta, ou eu não volto.”")
                        .font(.system(size: 15, design: .serif)).italic()
                        .foregroundStyle(Tema.papel.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                }

                if !st.save.amuletos.contains(.harpia) {
                    VStack(alignment: .leading, spacing: 9) {
                        Text("O QUE ELA EXIGE")
                            .font(Tema.rotulo).tracking(1.4)
                            .foregroundStyle(Tema.ouro)
                        ForEach(Array(st.condicoesHarpia.enumerated()), id: \.offset) { _, c in
                            HStack(spacing: 10) {
                                Image(systemName: c.feito ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(c.feito ? Tema.essencia : Tema.papel.opacity(0.3))
                                Text(c.texto)
                                    .font(Tema.corpo)
                                    .foregroundStyle(Tema.papel.opacity(c.feito ? 0.95 : 0.6))
                                    .strikethrough(c.feito, color: Tema.essencia.opacity(0.5))
                            }
                        }
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05)))

                    if st.harpiaLiberada {
                        Text("Tudo cumprido. Fale com ela.")
                            .font(Tema.subtitulo)
                            .foregroundStyle(Tema.ouro)
                    }
                } else {
                    Text("Coroa da Harpia conquistada — atalho 7. Segure ESPAÇO para voar sobre qualquer barreira do mundo.")
                        .font(Tema.corpo)
                        .foregroundStyle(Tema.essencia)
                }
            }
        }
    }
}
