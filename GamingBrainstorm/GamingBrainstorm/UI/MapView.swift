//
//  MapView.swift
//  Guardiões dos Biomas
//
//  Mapa de campo: um recorte do terreno em volta do jogador (gerado com a
//  mesma semente da cena, então bate exatamente com o mundo) e o painel de
//  situação dos cinco biomas.
//

import SwiftUI
import SpriteKit

struct MapView: View {
    @ObservedObject var st: GameState
    @State private var amostras: [[Color]] = []

    /// Lado do recorte, em tiles.
    private let lado = 61

    var body: some View {
        HStack(spacing: 0) {
            recorteLocal
            Divider().background(Tema.ouro.opacity(0.2))
            painelBiomas
        }
        .background(Tema.cor(Palette.refugio.sky).opacity(0.98).ignoresSafeArea())
        .onAppear(perform: amostrar)
        .onChange(of: st.jogadorTile) { _, _ in amostrar() }
    }

    // MARK: Recorte do terreno

    private var recorteLocal: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("MAPA DE CAMPO")
                    .font(.system(size: 20, weight: .heavy, design: .serif))
                    .tracking(2.5)
                    .foregroundStyle(Tema.papel)
                Spacer()
                Button { st.tela = .jogo } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Tema.papel.opacity(0.5))
                }
                .buttonStyle(.plain)
            }

            Text("\(Biome[st.biomaCarregado].nome) · posição \(st.jogadorTile.x), \(st.jogadorTile.y)")
                .font(Tema.rotulo)
                .foregroundStyle(Tema.papel.opacity(0.55))

            Canvas { ctx, size in
                guard !amostras.isEmpty else { return }
                let passo = size.width / CGFloat(lado)
                for (j, linha) in amostras.enumerated() {
                    for (i, cor) in linha.enumerated() {
                        let r = CGRect(x: CGFloat(i) * passo, y: CGFloat(j) * passo,
                                       width: passo + 0.5, height: passo + 0.5)
                        ctx.fill(Path(r), with: .color(cor))
                    }
                }
                // Marcador do jogador no centro.
                let c = size.width / 2
                ctx.fill(Path(ellipseIn: CGRect(x: c - 5, y: c - 5, width: 10, height: 10)),
                         with: .color(Tema.ouro))
                ctx.stroke(Path(ellipseIn: CGRect(x: c - 9, y: c - 9, width: 18, height: 18)),
                           with: .color(Tema.ouro.opacity(0.5)), lineWidth: 1.5)
            }
            .frame(width: 380, height: 380)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Tema.ouro.opacity(0.3), lineWidth: 1))

            legenda
            Spacer()
        }
        .padding(24)
        .frame(width: 430)
    }

    private var legenda: some View {
        let regras = Biome[st.biomaCarregado].rules
        let barreiras: [Terrain] = Array(Set([regras.terrenoEspecial, regras.terrenoEspecialSecundario]))
        return VStack(alignment: .leading, spacing: 5) {
            Text("BARREIRAS DESTE BIOMA")
                .font(Tema.rotulo).tracking(1.3)
                .foregroundStyle(Tema.ouro)
            ForEach(barreiras, id: \.rawValue) { t in
                if let forma = t.formaNecessaria {
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(cor(de: t))
                            .frame(width: 12, height: 12)
                        Text("\(t.nome) — \(forma.icone) \(forma.nome)")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundStyle(st.temAmuleto(forma)
                                             ? Tema.papel.opacity(0.85)
                                             : Tema.perigo.opacity(0.85))
                    }
                }
            }
        }
    }

    private func amostrar() {
        let bioma = Biome[st.biomaCarregado]
        let nivel = st.save.biome(st.biomaCarregado).nivelExpedicao
        let gen = WorldGenerator(biome: bioma, dificuldade: nivel)
        let meio = lado / 2
        var grade: [[Color]] = []
        // O eixo Y do mundo cresce para cima; o do Canvas, para baixo.
        for j in 0..<lado {
            var linha: [Color] = []
            for i in 0..<lado {
                let t = GridPoint(x: st.jogadorTile.x + i - meio,
                                  y: st.jogadorTile.y + meio - j)
                linha.append(cor(de: gen.terrain(at: t)))
            }
            grade.append(linha)
        }
        amostras = grade
    }

    private func cor(de t: Terrain) -> Color {
        let p = Biome[st.biomaCarregado].palette
        switch t {
        case .agua: return Tema.cor(p.water)
        case .charco: return Tema.cor(p.water.blended(with: p.ground, amount: 0.5))
        case .abismo: return Color.black
        case .rocha: return Tema.cor(p.rock)
        case .tronco: return Tema.cor(p.foliageDark)
        case .cipos: return Tema.cor(p.foliage.lighter(0.08))
        case .espinheiro: return Tema.cor(p.accent.darker(0.35))
        case .terraDura: return Tema.cor(p.ground.darker(0.30))
        case .areia: return Tema.cor(p.sand)
        case .pedraChao: return Tema.cor(p.rock.lighter(0.15))
        case .trilha: return Tema.cor(p.ground.lighter(0.20))
        case .folhagem: return Tema.cor(p.ground.blended(with: p.foliageDark, amount: 0.4))
        case .terra: return Tema.cor(p.ground)
        case .gramaAlta: return Tema.cor(p.grass.darker(0.10))
        case .grama: return Tema.cor(p.grass)
        }
    }

    // MARK: Situação dos biomas

    private var painelBiomas: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("SITUAÇÃO DOS TERRITÓRIOS")
                    .font(Tema.rotulo).tracking(1.4)
                    .foregroundStyle(Tema.ouro)
                    .padding(.bottom, 2)

                ForEach(BiomeID.exploraveis) { id in
                    cartao(id)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("A viagem é feita pelos portais.")
                        .font(Tema.corpo)
                        .foregroundStyle(Tema.papel.opacity(0.7))
                    Text("Os cinco portais ficam no Refúgio Raízes; em cada bioma há um portal de retorno ao lado do ponto de chegada.")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(Tema.papel.opacity(0.45))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 6)
            }
            .padding(24)
            .frame(maxWidth: 520, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
    }

    private func cartao(_ id: BiomeID) -> some View {
        let b = Biome[id]
        let bs = st.save.biome(id)
        let chain = Quests.chain(for: id)
        let liberado = st.podeEntrar(id)
        let concluido = st.cadeiaConcluida(id)

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(nsImage: Creatures.retrato(b.animal))
                    .interpolation(.high).resizable().scaledToFit()
                    .frame(width: 44, height: 44)
                    .opacity(liberado ? 1 : 0.3)

                VStack(alignment: .leading, spacing: 2) {
                    Text(b.nome)
                        .font(.system(size: 16, weight: .bold, design: .serif))
                        .foregroundStyle(Tema.papel)
                    Text(b.subtitulo)
                        .font(.system(size: 11, design: .serif))
                        .italic()
                        .foregroundStyle(Tema.papel.opacity(0.5))
                }
                Spacer()
                if !liberado {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(Tema.perigo.opacity(0.7))
                } else if concluido {
                    Text(b.animal.icone).font(.system(size: 20))
                }
            }

            if !liberado, let req = b.requisito {
                Text("Selado — exige o \(req.amuleto)")
                    .font(Tema.rotulo)
                    .foregroundStyle(Tema.perigo.opacity(0.8))
            } else if concluido {
                HStack(spacing: 10) {
                    rotulo("\(b.animal.amuleto) conquistado", cor: Tema.ouro)
                    rotulo("expedições: \(bs.expedicoesConcluidas)", cor: Tema.essencia)
                    rotulo("nível \(bs.nivelExpedicao)", cor: Tema.papel.opacity(0.6))
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Etapa \(min(bs.etapa + 1, chain.etapas.count)) de \(chain.etapas.count) · \(chain.titulo)")
                        .font(Tema.rotulo)
                        .foregroundStyle(Tema.papel.opacity(0.7))
                    BarraDeProgresso(valor: Double(bs.etapa) / Double(chain.etapas.count),
                                     cor: Tema.cor(b.palette.accent), altura: 5)
                }
            }

            HStack(spacing: 6) {
                Image(systemName: b.ameaca.icone)
                    .font(.system(size: 10))
                    .foregroundStyle(Tema.perigo.opacity(0.8))
                Text(b.ameaca.nome)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(Tema.papel.opacity(0.5))
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 12)
            .fill(st.biomaCarregado == id ? Tema.ouro.opacity(0.10) : Color.white.opacity(0.05)))
        .overlay(RoundedRectangle(cornerRadius: 12)
            .strokeBorder(st.biomaCarregado == id ? Tema.ouro.opacity(0.5) : Color.clear, lineWidth: 1))
    }

    private func rotulo(_ texto: String, cor: Color) -> some View {
        Text(texto)
            .font(.system(size: 10, weight: .semibold, design: .rounded))
            .padding(.horizontal, 7).padding(.vertical, 3)
            .background(Capsule().fill(cor.opacity(0.16)))
            .foregroundStyle(cor)
    }
}
