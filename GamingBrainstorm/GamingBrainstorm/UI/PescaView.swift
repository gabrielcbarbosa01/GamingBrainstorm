//
//  PescaView.swift
//  Guardiões dos Biomas
//
//  Minigame de pesca: um marcador varre a barra e o jogador aperta E dentro da
//  faixa. Melhorar o cais alarga a faixa e puxa espécies mais raras.
//

import SwiftUI
import SpriteKit

struct PescaView: View {
    @ObservedObject var st: GameState
    let sessao: PescaSession

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()

            VStack(spacing: 18) {
                if let peixe = sessao.resultado {
                    resultado(peixe)
                } else if sessao.encerrada {
                    vazio
                } else {
                    jogo
                }
            }
            .padding(26)
            .frame(width: 520)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(nsColor: Palette.pantanal.sky).opacity(0.97)))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Tema.ouro.opacity(0.35), lineWidth: 1.2))
        }
    }

    // MARK: Barra

    private var jogo: some View {
        VStack(spacing: 16) {
            VStack(spacing: 4) {
                Text("AÇUDE DO REFÚGIO")
                    .font(Tema.rotulo).tracking(1.6)
                    .foregroundStyle(Tema.ouro)
                Text("Aperte E quando o marcador cruzar a faixa clara")
                    .font(Tema.corpo)
                    .foregroundStyle(Tema.papel.opacity(0.75))
            }

            // TimelineView anima sem custar um redesenho de todo o jogo.
            TimelineView(.animation) { contexto in
                let t = contexto.date.timeIntervalSince(sessao.inicio)
                let pos = sessao.posicao(em: t)
                let dentro = sessao.acertou(em: t)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.black.opacity(0.45))
                        // Faixa de acerto
                        Capsule()
                            .fill(dentro ? Tema.essencia.opacity(0.55) : Tema.essencia.opacity(0.25))
                            .frame(width: geo.size.width * sessao.zonaLargura)
                            .offset(x: geo.size.width * (sessao.zonaCentro - sessao.zonaLargura / 2))
                        // Marcador
                        RoundedRectangle(cornerRadius: 3)
                            .fill(dentro ? Tema.ouro : Tema.papel)
                            .frame(width: 6, height: 46)
                            .offset(x: geo.size.width * pos - 3)
                            .shadow(color: dentro ? Tema.ouro.opacity(0.8) : .clear, radius: 6)
                    }
                }
                .frame(height: 46)
            }

            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { i in
                    Image(systemName: i < sessao.tentativas ? "circle.fill" : "circle")
                        .font(.system(size: 9))
                        .foregroundStyle(i < sessao.tentativas ? Tema.ouro : Tema.papel.opacity(0.25))
                }
                Text("tentativas")
                    .font(Tema.rotulo)
                    .foregroundStyle(Tema.papel.opacity(0.5))
                    .padding(.leading, 4)
            }

            if let m = sessao.mensagem {
                Text(m)
                    .font(Tema.corpo)
                    .foregroundStyle(Tema.perigo)
            }

            Text("ESC para desistir")
                .font(Tema.rotulo)
                .foregroundStyle(Tema.papel.opacity(0.4))
        }
    }

    // MARK: Resultado

    private func resultado(_ peixe: Peixe) -> some View {
        VStack(spacing: 14) {
            Text(peixe.soltar ? "DEVOLVIDO À ÁGUA" : "REGISTRADO")
                .font(Tema.rotulo).tracking(1.6)
                .foregroundStyle(peixe.soltar ? Tema.essencia : Tema.ouro)

            VStack(spacing: 3) {
                Text(peixe.nome)
                    .font(.system(size: 26, weight: .bold, design: .serif))
                    .foregroundStyle(Tema.papel)
                Text(peixe.cientifico)
                    .font(.system(size: 13, design: .serif)).italic()
                    .foregroundStyle(Tema.papel.opacity(0.55))
            }

            HStack(spacing: 3) {
                ForEach(0..<4, id: \.self) { i in
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(i < peixe.raridade ? Tema.ouro : Tema.papel.opacity(0.2))
                }
            }

            Text(peixe.nota)
                .font(.system(size: 14, design: .serif))
                .foregroundStyle(Tema.papel.opacity(0.85))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 14) {
                Text("★ +\(peixe.pontos * (peixe.soltar ? 2 : 1))")
                    .foregroundStyle(Tema.ouro)
                Text("⚡ +\(peixe.essencia)")
                    .foregroundStyle(Tema.essencia)
            }
            .font(.system(size: 14, weight: .bold, design: .rounded))

            if peixe.soltar {
                Text("Espécies migradoras e juvenis valem o dobro quando voltam para a água.")
                    .font(Tema.rotulo)
                    .foregroundStyle(Tema.essencia.opacity(0.8))
                    .multilineTextAlignment(.center)
            }

            botaoFechar
        }
    }

    private var vazio: some View {
        VStack(spacing: 14) {
            Image(systemName: "water.waves")
                .font(.system(size: 34))
                .foregroundStyle(Tema.papel.opacity(0.3))
            Text("O cardume dispersou.")
                .font(.system(size: 18, design: .serif))
                .foregroundStyle(Tema.papel.opacity(0.8))
            Text("Espere a água acalmar e tente de novo.")
                .font(Tema.rotulo)
                .foregroundStyle(Tema.papel.opacity(0.5))
            botaoFechar
        }
    }

    private var botaoFechar: some View {
        Button { st.encerrarPesca() } label: {
            Text("Fechar")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .padding(.horizontal, 26).padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 10).fill(Tema.ouro.opacity(0.85)))
                .foregroundStyle(Tema.tinta)
        }
        .buttonStyle(.plain)
    }
}
