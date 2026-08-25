//
//  HUDView.swift
//  Guardiões dos Biomas
//
//  Camada de informação sobre a cena: missão atual, essência, roda de
//  amuletos, bússola, avisos e dica de interação.
//

import SwiftUI
import SpriteKit

struct HUDView: View {
    @ObservedObject var st: GameState

    var body: some View {
        ZStack {
            VStack {
                HStack(alignment: .top) {
                    painelMissao
                    Spacer()
                    painelPontuacao
                }
                Spacer()
                HStack(alignment: .bottom) {
                    painelEssencia
                    Spacer()
                    painelAtalhos
                }
            }
            .padding(18)

            VStack {
                avisos
                Spacer()
                dicaInteracao
                    .padding(.bottom, 116)
            }
            .padding(.top, 14)
            .allowsHitTesting(false)
        }
    }

    // MARK: Missão

    private var painelMissao: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Circle()
                    .fill(Tema.cor(Biome[st.biomaCarregado].palette.accent))
                    .frame(width: 9, height: 9)
                Text(Biome[st.biomaCarregado].nome.uppercased())
                    .font(Tema.rotulo)
                    .tracking(1.4)
                    .foregroundStyle(Tema.papel.opacity(0.85))
            }

            if let etapa = st.etapaAtual(st.biomaCarregado),
               let prog = st.progressoAtual(st.biomaCarregado) {
                Text(etapa.titulo)
                    .font(Tema.subtitulo)
                    .foregroundStyle(Tema.papel)
                HStack(spacing: 8) {
                    Image(systemName: etapa.kind.icone)
                        .foregroundStyle(Tema.ouro)
                        .font(.system(size: 12))
                    BarraDeProgresso(valor: Double(prog.feito) / Double(max(1, prog.alvo)),
                                     cor: Tema.ouro)
                        .frame(width: 150)
                    Text("\(prog.feito)/\(prog.alvo)")
                        .font(Tema.rotulo)
                        .foregroundStyle(Tema.papel.opacity(0.85))
                }
                if let b = st.bussola, let d = st.distanciaObjetivo {
                    HStack(spacing: 6) {
                        Image(systemName: "location.north.fill")
                            .rotationEffect(.radians(atan2(Double(b.dx), Double(b.dy))))
                            .foregroundStyle(Tema.essencia)
                            .font(.system(size: 11))
                        Text("ponto mais próximo a \(Int(d / WorldMetrics.tileSize)) passos")
                            .font(Tema.rotulo)
                            .foregroundStyle(Tema.papel.opacity(0.6))
                    }
                }
            } else if st.biomaCarregado == .refugio {
                Text("Base segura — escolha um portal")
                    .font(Tema.subtitulo)
                    .foregroundStyle(Tema.papel)
            } else {
                Text("Território liberado")
                    .font(Tema.subtitulo)
                    .foregroundStyle(Tema.papel)
                Text("R · iniciar nova expedição (nível \(st.save.biome(st.biomaCarregado).nivelExpedicao))")
                    .font(Tema.rotulo)
                    .foregroundStyle(Tema.ouro)
            }
        }
        .frame(width: 264, alignment: .leading)
        .painelDeCampo()
    }

    // MARK: Pontuação

    private var painelPontuacao: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text("ÍNDICE DE BIODIVERSIDADE")
                .font(Tema.rotulo).tracking(1.1)
                .foregroundStyle(Tema.papel.opacity(0.6))
            Text("\(st.indiceBiodiversidade)")
                .font(Tema.numero)
                .foregroundStyle(Tema.ouro)
            Text(st.tituloGuardiao)
                .font(Tema.rotulo)
                .foregroundStyle(Tema.papel.opacity(0.8))
            HStack(spacing: 3) {
                ForEach(AnimalForm.vestiveis) { f in
                    Circle()
                        .fill(st.temAmuleto(f) ? Tema.cor(f.corPrimaria) : Color.white.opacity(0.12))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.top, 2)
            RecursosView(st: st)
                .padding(.top, 4)
        }
        .painelDeCampo()
    }

    // MARK: Essência e formas

    private var painelEssencia: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Tema.essencia)
                BarraDeProgresso(valor: Double(st.essencia / max(1, st.essenciaMaxima)),
                                 cor: Tema.essencia)
                    .frame(width: 170)
                Text("\(Int(st.essencia))")
                    .font(Tema.rotulo)
                    .foregroundStyle(Tema.papel.opacity(0.85))
                    .frame(width: 30, alignment: .leading)
            }

            // Fôlego: aparece apenas quando o corpo está submerso ou se recuperando.
            if st.folego < st.folegoMaximo {
                HStack(spacing: 8) {
                    Image(systemName: "wind")
                        .font(.system(size: 12))
                        .foregroundStyle(st.folego < 30 ? Tema.perigo : Tema.papel.opacity(0.8))
                    BarraDeProgresso(valor: Double(st.folego / st.folegoMaximo),
                                     cor: st.folego < 30 ? Tema.perigo : Color(nsColor: SKColor(hex: 0x9AD8E0)))
                        .frame(width: 170)
                    Text("fôlego")
                        .font(Tema.rotulo)
                        .foregroundStyle(Tema.papel.opacity(0.6))
                }
                .transition(.opacity)
            }

            HStack(spacing: 8) {
                botaoForma(.humano, atalho: "Q")
                ForEach(Array(AnimalForm.vestiveis.enumerated()), id: \.element) { i, f in
                    botaoForma(f, atalho: "\(i + 1)")
                }
            }

            // O verbo da forma atual — é a informação mais importante da HUD.
            HStack(spacing: 8) {
                Text("ESPAÇO")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(RoundedRectangle(cornerRadius: 4)
                        .fill(st.formaAtual.verbo == .nenhum
                              ? Color.white.opacity(0.08) : Tema.ouro.opacity(0.28)))
                    .foregroundStyle(st.formaAtual.verbo == .nenhum
                                     ? Tema.papel.opacity(0.35) : Tema.ouro)
                Text(st.formaAtual.verbo == .nenhum
                     ? "sem movimento especial"
                     : st.formaAtual.verbo.nome)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Tema.papel.opacity(0.85))
                Text(st.formaAtual.verbo.dica)
                    .font(.system(size: 10, design: .rounded))
                    .foregroundStyle(Tema.papel.opacity(0.42))
                    .lineLimit(1)
            }
            .frame(maxWidth: 400, alignment: .leading)
        }
        .painelDeCampo()
    }

    private func botaoForma(_ f: AnimalForm, atalho: String) -> some View {
        let temAmuleto = st.temAmuleto(f)
        let ativa = st.formaAtual == f
        return VStack(spacing: 3) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(temAmuleto ? Tema.cor(f.corPrimaria).opacity(ativa ? 0.9 : 0.28)
                                     : Color.white.opacity(0.06))
                    .frame(width: 42, height: 42)
                if temAmuleto {
                    Text(f.icone).font(.system(size: 20))
                } else {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(Tema.papel.opacity(0.35))
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .strokeBorder(ativa ? Tema.ouro : Color.clear, lineWidth: 2)
                    .frame(width: 42, height: 42)
            )
            Text(atalho)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(Tema.papel.opacity(temAmuleto ? 0.7 : 0.3))
        }
        .help(temAmuleto ? "\(f.nome) — \(f.habilidade)" : "Amuleto ainda não conquistado")
        .onTapGesture { st.trocarForma(f) }
    }

    // MARK: Atalhos

    private var painelAtalhos: some View {
        VStack(alignment: .trailing, spacing: 3) {
            atalho("WASD", "mover")
            atalho("ESPAÇO", "habilidade")
            atalho("E", "interagir")
            atalho("TAB", "códice")
            atalho("M", "mapa")
            atalho("ESC", "menu")
        }
        .painelDeCampo(padding: 10, raio: 10)
    }

    private func atalho(_ tecla: String, _ acao: String) -> some View {
        HStack(spacing: 6) {
            Text(acao)
                .font(Tema.rotulo)
                .foregroundStyle(Tema.papel.opacity(0.55))
            Text(tecla)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .padding(.horizontal, 5).padding(.vertical, 1.5)
                .background(RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.12)))
                .foregroundStyle(Tema.papel.opacity(0.9))
        }
    }

    // MARK: Avisos e dica

    private var avisos: some View {
        VStack(spacing: 6) {
            ForEach(st.toasts) { t in
                HStack(spacing: 8) {
                    Image(systemName: t.icone)
                        .font(.system(size: 12))
                        .foregroundStyle(Tema.corToast(t.cor))
                    Text(t.texto)
                        .font(Tema.corpo)
                        .foregroundStyle(Tema.papel)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 14).padding(.vertical, 9)
                .frame(maxWidth: 460, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.black.opacity(0.74))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Tema.corToast(t.cor).opacity(0.45), lineWidth: 1)
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeOut(duration: 0.22), value: st.toasts)
    }

    @ViewBuilder
    private var dicaInteracao: some View {
        if let dica = st.dicaInteracao {
            Text(dica)
                .font(Tema.corpo)
                .foregroundStyle(Tema.papel)
                .padding(.horizontal, 16).padding(.vertical, 9)
                .background(Capsule().fill(Color.black.opacity(0.72)))
                .overlay(Capsule().strokeBorder(Tema.ouro.opacity(0.4), lineWidth: 1))
        }
    }
}
