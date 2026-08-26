//
//  ViagemMapaView.swift
//  Guardiões dos Biomas
//
//  Transição de viagem: em vez de um portal seco, a câmera "sobe" para um
//  mapa estilizado do Brasil e o guardião atravessa até o bioma de destino.
//  Reforça o pilar "Um Brasil conectado e redescoberto" do GDD.
//

import SwiftUI

/// Geografia estilizada do mapa de viagem — condensada, não é reprodução 1:1.
enum MapaBrasil {

    /// Contorno simplificado do Brasil, em coordenadas normalizadas (0...1,
    /// y cresce para baixo). Estilizado de propósito: legível como silhueta
    /// pequena, não como mapa cartográfico preciso.
    static let contorno: [CGPoint] = [
        CGPoint(x: 0.30, y: 0.02), CGPoint(x: 0.44, y: 0.04),
        CGPoint(x: 0.57, y: 0.11), CGPoint(x: 0.73, y: 0.19),
        CGPoint(x: 0.88, y: 0.29), CGPoint(x: 0.85, y: 0.39),
        CGPoint(x: 0.79, y: 0.49), CGPoint(x: 0.73, y: 0.59),
        CGPoint(x: 0.66, y: 0.67), CGPoint(x: 0.57, y: 0.75),
        CGPoint(x: 0.49, y: 0.85), CGPoint(x: 0.42, y: 0.95),
        CGPoint(x: 0.29, y: 0.90), CGPoint(x: 0.19, y: 0.80),
        CGPoint(x: 0.13, y: 0.67), CGPoint(x: 0.09, y: 0.52),
        CGPoint(x: 0.06, y: 0.36), CGPoint(x: 0.10, y: 0.20)
    ]

    /// Posição normalizada de cada território no mapa.
    static let pontos: [BiomeID: CGPoint] = [
        .refugio: CGPoint(x: 0.56, y: 0.60),
        .mataAtlantica: CGPoint(x: 0.63, y: 0.65),
        .cerrado: CGPoint(x: 0.42, y: 0.48),
        .pantanal: CGPoint(x: 0.20, y: 0.62),
        .caatinga: CGPoint(x: 0.68, y: 0.32),
        .amazonia: CGPoint(x: 0.30, y: 0.19),
        .pampa: CGPoint(x: 0.36, y: 0.86)
    ]

    /// Rotas desenhadas entre territórios vizinhos — o Cerrado, central e
    /// nascente das águas, funciona como o cruzamento natural do mapa.
    static let rotas: [(BiomeID, BiomeID)] = [
        (.refugio, .mataAtlantica),
        (.mataAtlantica, .cerrado),
        (.cerrado, .pantanal),
        (.cerrado, .caatinga),
        (.caatinga, .amazonia),
        (.cerrado, .pampa)
    ]
}

struct ViagemMapaView: View {
    @ObservedObject var st: GameState
    @Environment(\.accessibilityReduceMotion) private var reduzMovimento

    @State private var progresso: CGFloat = 0
    @State private var mostrarTitulo = false

    private var origem: BiomeID { st.biomaCarregado }
    private var destino: BiomeID { st.viagemDestino ?? origem }

    var body: some View {
        GeometryReader { geo in
            let tamanho = geo.size
            ZStack {
                Tema.tinta.ignoresSafeArea()

                Canvas { ctx, size in
                    desenharSilhueta(ctx, size: size)
                    desenharRotas(ctx, size: size)
                    desenharPontos(ctx, size: size)
                    desenharViajante(ctx, size: size)
                }
                .frame(width: tamanho.width, height: tamanho.height)

                VStack {
                    if mostrarTitulo {
                        VStack(spacing: 6) {
                            Text("ATRAVESSANDO O BRASIL")
                                .font(Tema.rotulo).tracking(2.5)
                                .foregroundStyle(Tema.ouro.opacity(0.85))
                            Text(Biome[destino].nome)
                                .font(.system(size: 26, weight: .heavy, design: .serif))
                                .foregroundStyle(Tema.papel)
                            Text(Biome[destino].subtitulo)
                                .font(.system(size: 13, design: .serif)).italic()
                                .foregroundStyle(Tema.papel.opacity(0.55))
                        }
                        .transition(.opacity)
                        .padding(.top, 36)
                    }
                    Spacer()
                }
            }
        }
        .onAppear(perform: iniciarAnimacao)
    }

    private func iniciarAnimacao() {
        let duracao: Double = reduzMovimento ? 0.35 : 1.8
        withAnimation(.easeInOut(duration: duracao)) { progresso = 1 }
        withAnimation(.easeIn(duration: 0.4).delay(duracao * 0.25)) { mostrarTitulo = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + duracao + 0.35) {
            st.concluirViagem()
        }
    }

    // MARK: - Desenho

    private func p(_ n: CGPoint, _ size: CGSize) -> CGPoint {
        CGPoint(x: n.x * size.width, y: n.y * size.height)
    }

    private func desenharSilhueta(_ ctx: GraphicsContext, size: CGSize) {
        guard let primeiro = MapaBrasil.contorno.first else { return }
        var caminho = Path()
        caminho.move(to: p(primeiro, size))
        for pt in MapaBrasil.contorno.dropFirst() { caminho.addLine(to: p(pt, size)) }
        caminho.closeSubpath()
        ctx.fill(caminho, with: .color(Tema.cor(Palette.refugio.foliage).opacity(0.42)))
        ctx.stroke(caminho, with: .color(Tema.ouro.opacity(0.5)), lineWidth: 1.6)
    }

    private func desenharRotas(_ ctx: GraphicsContext, size: CGSize) {
        for (a, b) in MapaBrasil.rotas {
            guard let pa = MapaBrasil.pontos[a], let pb = MapaBrasil.pontos[b] else { continue }
            var linha = Path()
            linha.move(to: p(pa, size))
            linha.addLine(to: p(pb, size))
            let ativa = (a == origem || a == destino) && (b == origem || b == destino)
            ctx.stroke(linha, with: .color(ativa ? Tema.ouro.opacity(0.7) : Tema.papel.opacity(0.16)),
                       style: StrokeStyle(lineWidth: ativa ? 2 : 1, dash: ativa ? [] : [3, 4]))
        }
    }

    private func desenharPontos(_ ctx: GraphicsContext, size: CGSize) {
        for id in BiomeID.allCases {
            guard let n = MapaBrasil.pontos[id] else { continue }
            let centro = p(n, size)
            let liberado = st.podeEntrar(id) || id == .refugio
            let destaque = id == origem || id == destino
            let cor = liberado ? Tema.cor(Biome[id].palette.accent) : Tema.papel.opacity(0.25)

            if destaque {
                let raioAnel: CGFloat = id == destino ? 15 : 11
                ctx.stroke(Path(ellipseIn: CGRect(x: centro.x - raioAnel, y: centro.y - raioAnel,
                                                  width: raioAnel * 2, height: raioAnel * 2)),
                          with: .color(Tema.ouro.opacity(0.6)), lineWidth: 1.6)
            }

            ctx.fill(Path(ellipseIn: CGRect(x: centro.x - 6, y: centro.y - 6, width: 12, height: 12)),
                     with: .color(cor))

            ctx.draw(Text(id == .refugio ? "🏕" : Biome[id].animal.icone).font(.system(size: 15)),
                     at: CGPoint(x: centro.x, y: centro.y - 20))

            if destaque {
                ctx.draw(Text(Biome[id].nome)
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundColor(Tema.papel.opacity(0.85)),
                         at: CGPoint(x: centro.x, y: centro.y + 16))
            }
        }
    }

    private func desenharViajante(_ ctx: GraphicsContext, size: CGSize) {
        guard let pa = MapaBrasil.pontos[origem], let pb = MapaBrasil.pontos[destino] else { return }
        let a = p(pa, size), b = p(pb, size)
        // Arco suave: desloca o ponto de controle perpendicular à linha reta.
        let meio = CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
        let dx = b.x - a.x, dy = b.y - a.y
        let controle = CGPoint(x: meio.x - dy * 0.18, y: meio.y + dx * 0.18)

        let t = progresso
        let x = (1 - t) * (1 - t) * a.x + 2 * (1 - t) * t * controle.x + t * t * b.x
        let y = (1 - t) * (1 - t) * a.y + 2 * (1 - t) * t * controle.y + t * t * b.y

        var trilha = Path()
        trilha.move(to: a)
        trilha.addQuadCurve(to: CGPoint(x: x, y: y), control: controle)
        ctx.stroke(trilha, with: .color(Tema.essencia.opacity(0.55)), lineWidth: 2)

        ctx.draw(Text("✦").font(.system(size: 16)).foregroundColor(Tema.essencia),
                 at: CGPoint(x: x, y: y))
    }
}
