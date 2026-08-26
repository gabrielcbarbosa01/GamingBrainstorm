//
//  OperacaoView.swift
//  Guardiões dos Biomas
//
//  O painel da operação: quanto falta a frente atravessar, o que já foi salvo
//  e o que se perdeu. E o balanço no fim — que é onde a escolha aparece.
//

import SwiftUI
import SpriteKit

struct OperacaoHUD: View {
    @ObservedObject var st: GameState
    let sessao: OperacaoSessao

    private var cor: Color { Tema.cor(Biome[sessao.config.bioma].palette.accent) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 7) {
                Image(systemName: sessao.config.ameaca.icone)
                    .font(.system(size: 12))
                    .foregroundStyle(Tema.perigo)
                Text(sessao.config.frente.uppercased())
                    .font(Tema.rotulo).tracking(1.3)
                    .foregroundStyle(Tema.papel.opacity(0.9))
            }

            // O relógio é a frente: quanto falta dela atravessar tudo.
            HStack(spacing: 8) {
                BarraDeProgresso(valor: Double(sessao.fracaoTempo),
                                 cor: sessao.fracaoTempo < 0.3 ? Tema.perigo : Tema.ouro)
                    .frame(width: 180)
                Text("\(Int(sessao.tempoRestante))s")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(sessao.fracaoTempo < 0.3 ? Tema.perigo : Tema.papel)
            }

            HStack(spacing: 12) {
                contador("salvos", sessao.salvos, Tema.essencia, "checkmark.circle.fill")
                contador("perdidos", sessao.perdidos, Tema.perigo, "xmark.circle.fill")
                contador("em pé", sessao.restantes, Tema.papel.opacity(0.75), "circle")
            }

            HStack(spacing: 6) {
                Image(systemName: sessao.atingiuMeta ? "checkmark.seal.fill" : "target")
                    .font(.system(size: 10))
                    .foregroundStyle(sessao.atingiuMeta ? Tema.essencia : cor)
                Text(sessao.atingiuMeta
                     ? "meta alcançada — cada um a mais é lucro"
                     : "meta: \(sessao.config.meta) \(sessao.config.focoPlural)")
                    .font(Tema.rotulo)
                    .foregroundStyle(sessao.atingiuMeta ? Tema.essencia : Tema.papel.opacity(0.6))
            }

            if sessao.proximidadeDaFrente < 0.28 {
                Text("A LINHA ESTÁ EM CIMA DE VOCÊ")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(Tema.perigo)
            }
        }
        .frame(width: 282, alignment: .leading)
        .painelDeCampo()
    }

    private func contador(_ nome: String, _ v: Int, _ c: Color, _ icone: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icone).font(.system(size: 9)).foregroundStyle(c)
            Text("\(v)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(c)
            Text(nome)
                .font(.system(size: 9, design: .rounded))
                .foregroundStyle(Tema.papel.opacity(0.45))
        }
    }
}

struct OperacaoResultado: View {
    @ObservedObject var st: GameState
    let sessao: OperacaoSessao

    private var cor: Color { Tema.cor(Biome[sessao.config.bioma].palette.accent) }

    var body: some View {
        ZStack {
            Color.black.opacity(0.80).ignoresSafeArea()
            VStack(spacing: 18) {
                Text(sessao.atingiuMeta ? "A LINHA PASSOU" : "A LINHA PASSOU")
                    .font(Tema.rotulo).tracking(2.4)
                    .foregroundStyle(Tema.papel.opacity(0.5))

                Text("\(sessao.salvos) de \(sessao.total)")
                    .font(.system(size: 44, weight: .heavy, design: .serif))
                    .foregroundStyle(sessao.atingiuMeta ? Tema.ouro : Tema.perigo)
                Text("\(sessao.config.focoPlural) salvos em \(Biome[sessao.config.bioma].nome)")
                    .font(.system(size: 15, design: .serif))
                    .foregroundStyle(Tema.papel.opacity(0.85))

                // A perda é parte do resultado, não um detalhe escondido.
                if sessao.perdidos > 0 {
                    Text("\(sessao.perdidos) \(sessao.perdidos == 1 ? "ficou" : "ficaram") para trás.")
                        .font(.system(size: 14, design: .serif))
                        .italic()
                        .foregroundStyle(Tema.perigo.opacity(0.9))
                }

                HStack(spacing: 6) {
                    ForEach(0..<sessao.total, id: \.self) { i in
                        Circle()
                            .fill(i < sessao.salvos ? Tema.essencia
                                  : (i < sessao.salvos + sessao.perdidos
                                     ? Tema.perigo.opacity(0.55) : Color.white.opacity(0.15)))
                            .frame(width: 10, height: 10)
                    }
                }
                .padding(.vertical, 4)

                Text(sessao.atingiuMeta
                     ? "Meta de \(sessao.config.meta) cumprida. +\(sessao.salvos * 120) pontos."
                     : "A meta era \(sessao.config.meta). A frente volta — e você pode chegar antes.")
                    .font(Tema.corpo)
                    .foregroundStyle(sessao.atingiuMeta ? Tema.essencia : Tema.papel.opacity(0.7))
                    .multilineTextAlignment(.center)

                HStack(spacing: 12) {
                    botao(sessao.atingiuMeta ? "Continuar" : "Nova frente", destaque: true) {
                        if sessao.atingiuMeta {
                            st.operacao = nil
                        } else {
                            st.reiniciarOperacao()
                        }
                    }
                    botao("Voltar ao Refúgio") {
                        st.operacao = nil
                        st.viajar(para: .refugio)
                    }
                }
                .padding(.top, 6)
            }
            .padding(40)
            .frame(maxWidth: 620)
        }
    }

    private func botao(_ t: String, destaque: Bool = false, acao: @escaping () -> Void) -> some View {
        Button(action: acao) {
            Text(t)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .padding(.horizontal, 22).padding(.vertical, 11)
                .background(RoundedRectangle(cornerRadius: 10)
                    .fill(destaque ? Tema.ouro.opacity(0.88) : Color.white.opacity(0.10)))
                .foregroundStyle(destaque ? Tema.tinta : Tema.papel)
        }
        .buttonStyle(.plain)
    }
}
