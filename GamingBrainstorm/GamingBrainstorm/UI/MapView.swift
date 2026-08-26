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

    var body: some View {
        HStack(spacing: 0) {
            recorteLocal
            Divider().background(Tema.ouro.opacity(0.2))
            painelBiomas
        }
        .background(Tema.cor(Palette.refugio.sky).opacity(0.98).ignoresSafeArea())
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

            if st.biomaCarregado != .refugio {
                plantaDoSantuario
            } else {
            ZStack {
                Image(nsImage: Minimapa.imagem(bioma: st.biomaCarregado,
                                               centro: st.jogadorTile,
                                               nivel: st.save.biome(st.biomaCarregado).nivelExpedicao))
                    .interpolation(.none)
                    .resizable()
                    .frame(width: 380, height: 380)

                // Marcador do jogador, sempre no centro do recorte.
                Circle().fill(Tema.ouro).frame(width: 9, height: 9)
                Circle().strokeBorder(Tema.ouro.opacity(0.55), lineWidth: 1.5)
                    .frame(width: 19, height: 19)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Tema.ouro.opacity(0.3), lineWidth: 1))

            Text("recorte de \(Minimapa.lado)×\(Minimapa.lado) tiles em volta de você")
                .font(Tema.rotulo)
                .foregroundStyle(Tema.papel.opacity(0.4))
            }

            if st.biomaCarregado == .refugio { legenda }
            Spacer()
        }
        .padding(24)
        .frame(width: 430)
    }

    /// A planta da masmorra: o que a Planta e a Bússola revelam.
    private var plantaDoSantuario: some View {
        let s = st.santuario(st.biomaCarregado)
        let temMapa = st.temMapa(st.biomaCarregado)
        let temBussola = st.temBussola(st.biomaCarregado)
        return VStack(alignment: .leading, spacing: 10) {
            Text(s.nome)
                .font(.system(size: 17, weight: .bold, design: .serif))
                .foregroundStyle(Tema.papel)

            Image(nsImage: PlantaArt.imagem(santuario: s, estado: st, bioma: st.biomaCarregado))
                .interpolation(.high)
                .resizable().scaledToFit()
                .frame(maxWidth: 380, maxHeight: 340)
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.4)))
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Tema.ouro.opacity(0.3), lineWidth: 1))

            VStack(alignment: .leading, spacing: 4) {
                item(temMapa, "map.fill", "Planta do santuário",
                     temMapa ? "todas as salas desenhadas" : "só o que você já pisou")
                item(temBussola, "location.north.circle.fill", "Bússola do zelador",
                     temBussola ? "baús e Guardião marcados" : "conteúdo das salas oculto")
                item(st.temChaveDoGuardiao(st.biomaCarregado), "key.horizontal.fill",
                     "Chave do Guardião",
                     st.temChaveDoGuardiao(st.biomaCarregado) ? "a porta do fundo abre"
                                                              : "a porta do fundo continua selada")
                HStack(spacing: 6) {
                    Image(systemName: "key.fill").font(.system(size: 10)).foregroundStyle(Tema.ouro)
                    Text("Chaves pequenas: \(st.chaves(st.biomaCarregado))")
                        .font(Tema.rotulo).foregroundStyle(Tema.papel.opacity(0.8))
                }
            }

            HStack(spacing: 12) {
                cor(Tema.ouro, "trancada")
                cor(Tema.cor(Biome[st.biomaCarregado].animal.corPrimaria), "selada")
                cor(Tema.perigo, "do Guardião")
            }
            .padding(.top, 2)
        }
    }

    private func item(_ tem: Bool, _ icone: String, _ nome: String, _ detalhe: String) -> some View {
        HStack(spacing: 7) {
            Image(systemName: tem ? icone : "questionmark.circle")
                .font(.system(size: 11))
                .foregroundStyle(tem ? Tema.essencia : Tema.papel.opacity(0.3))
            Text(nome)
                .font(Tema.rotulo)
                .foregroundStyle(Tema.papel.opacity(tem ? 0.95 : 0.4))
            Text("· \(detalhe)")
                .font(.system(size: 10, design: .rounded))
                .foregroundStyle(Tema.papel.opacity(0.45))
        }
    }

    private func cor(_ c: Color, _ nome: String) -> some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 2).fill(c).frame(width: 14, height: 5)
            Text(nome).font(.system(size: 10, design: .rounded))
                .foregroundStyle(Tema.papel.opacity(0.55))
        }
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
                            .fill(Tema.cor(Minimapa.cor(de: t,
                                                        palette: Biome[st.biomaCarregado].palette)))
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
        let liberado = st.podeEntrar(id)
        let concluido = st.biomaConcluido(id)

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
                VStack(alignment: .leading, spacing: 5) {
                    let frags = st.objetivosDoAto(id)
                    let feitos = frags.filter { $0.completo }.count
                    Text(st.ato(id) == .acesso
                         ? "Ato 1 · conquistar o \(b.animal.amuleto)"
                         : "Ato 2 · provar o mérito — \(feitos)/\(frags.count)")
                        .font(Tema.rotulo)
                        .foregroundStyle(Tema.papel.opacity(0.7))
                    HStack(spacing: 6) {
                        ForEach(frags, id: \.frag.id) { item in
                            HStack(spacing: 4) {
                                Image(systemName: item.completo ? "checkmark.circle.fill" : item.frag.kind.icone)
                                    .font(.system(size: 9))
                                    .foregroundStyle(item.completo
                                                     ? Tema.essencia : Tema.papel.opacity(0.45))
                                Text("\(item.feito)/\(item.frag.alvo)")
                                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Tema.papel.opacity(0.6))
                            }
                            .padding(.horizontal, 6).padding(.vertical, 3)
                            .background(Capsule().fill(Color.white.opacity(0.06)))
                        }
                    }
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
