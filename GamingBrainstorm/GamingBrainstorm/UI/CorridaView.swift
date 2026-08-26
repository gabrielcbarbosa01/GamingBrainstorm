//
//  CorridaView.swift
//  Guardiões dos Biomas
//
//  Interface das provas arcade: instruções, painel de corrida e resultado.
//

import SwiftUI
import SpriteKit

/// Embrulho que mantém a cena viva enquanto a prova durar.
struct CorridaHost: View {
    @ObservedObject var st: GameState
    @State private var cena: RunScene

    init(st: GameState, config: Corrida) {
        self.st = st
        _cena = State(wrappedValue: RunScene(config: config, estado: st))
    }

    var body: some View {
        SpriteView(scene: cena, preferredFramesPerSecond: 60)
            .ignoresSafeArea()
    }
}

struct CorridaView: View {
    @ObservedObject var st: GameState
    let sessao: CorridaSessao

    private var cor: Color { Tema.cor(Biome[sessao.config.bioma].palette.accent) }

    var body: some View {
        ZStack {
            switch sessao.fase {
            case .instrucoes: instrucoes
            case .correndo: painelDeCorrida
            case .fim(let sucesso): resultado(sucesso: sucesso)
            }
        }
    }

    // MARK: Instruções

    private var instrucoes: some View {
        ZStack {
            Color.black.opacity(0.72).ignoresSafeArea()
            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    Text(Biome[sessao.config.bioma].nome.uppercased())
                        .font(Tema.rotulo).tracking(2)
                        .foregroundStyle(cor)
                    Text(sessao.config.titulo)
                        .font(.system(size: 34, weight: .heavy, design: .serif))
                        .foregroundStyle(Tema.papel)
                }

                HStack(spacing: 14) {
                    Image(nsImage: Creatures.retrato(sessao.config.forma))
                        .interpolation(.high).resizable().scaledToFit()
                        .frame(width: 76, height: 76)
                    Text(sessao.config.chamada)
                        .font(.system(size: 16, design: .serif))
                        .foregroundStyle(Tema.papel.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: 420, alignment: .leading)
                }

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(sessao.config.comoJogar, id: \.self) { linha in
                        HStack(alignment: .top, spacing: 9) {
                            Circle().fill(cor.opacity(0.7)).frame(width: 5, height: 5)
                                .padding(.top, 7)
                            Text(linha)
                                .font(Tema.corpo)
                                .foregroundStyle(Tema.papel.opacity(0.88))
                        }
                    }
                }
                .padding(18)
                .frame(maxWidth: 520, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.06)))

                HStack(spacing: 22) {
                    etiqueta("meta", "\(Int(sessao.config.meta)) \(unidade)")
                    etiqueta("vidas", sessao.config.modo == .fuga ? "só uma" : "\(sessao.config.vidas)")
                    if sessao.recorde > 0 {
                        etiqueta("recorde", "\(sessao.recorde) \(unidade)")
                    }
                }

                Text("ESPAÇO para largar   ·   ESC para desistir")
                    .font(Tema.rotulo)
                    .foregroundStyle(Tema.ouro)
                    .padding(.top, 4)
            }
            .padding(36)
        }
    }

    private var unidade: String { sessao.config.modo == .travessia ? "fileiras" : "m" }

    private func etiqueta(_ t: String, _ v: String) -> some View {
        VStack(spacing: 2) {
            Text(t.uppercased()).font(.system(size: 9, weight: .bold, design: .rounded))
                .tracking(1.2).foregroundStyle(Tema.papel.opacity(0.45))
            Text(v).font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(Tema.papel)
        }
    }

    // MARK: Durante a corrida

    private var painelDeCorrida: some View {
        VStack {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 7) {
                    Text(sessao.config.titulo.uppercased())
                        .font(Tema.rotulo).tracking(1.4)
                        .foregroundStyle(cor)
                    HStack(spacing: 9) {
                        BarraDeProgresso(valor: Double(sessao.fracao), cor: cor)
                            .frame(width: 220)
                        Text("\(Int(sessao.progresso))/\(Int(sessao.config.meta)) \(unidade)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(Tema.papel)
                    }
                    if sessao.config.modo == .fuga {
                        HStack(spacing: 8) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(sessao.folga < 0.4 ? Tema.perigo : Tema.ouro)
                            BarraDeProgresso(valor: Double(sessao.folga),
                                             cor: sessao.folga < 0.4 ? Tema.perigo : Tema.ouro,
                                             altura: 6)
                                .frame(width: 180)
                            Text("distância do fogo")
                                .font(Tema.rotulo)
                                .foregroundStyle(Tema.papel.opacity(0.55))
                        }
                    } else {
                        HStack(spacing: 5) {
                            ForEach(0..<sessao.config.vidas, id: \.self) { i in
                                Image(systemName: i < sessao.vidas ? "heart.fill" : "heart")
                                    .font(.system(size: 12))
                                    .foregroundStyle(i < sessao.vidas ? Tema.perigo : Tema.papel.opacity(0.25))
                            }
                        }
                    }
                }
                .painelDeCampo(padding: 12)

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                    Text("COLETADOS").font(Tema.rotulo).tracking(1.1)
                        .foregroundStyle(Tema.papel.opacity(0.5))
                    Text("\(sessao.coletados)")
                        .font(Tema.numero).foregroundStyle(cor)
                    if sessao.recorde > 0 {
                        Text("recorde \(sessao.recorde)")
                            .font(Tema.rotulo).foregroundStyle(Tema.papel.opacity(0.5))
                    }
                }
                .painelDeCampo(padding: 12)
            }
            Spacer()
            Text(dicaCurta)
                .font(Tema.rotulo)
                .foregroundStyle(Tema.papel.opacity(0.5))
                .padding(.bottom, 14)
        }
        .padding(18)
        .allowsHitTesting(false)
    }

    private var dicaCurta: String {
        switch sessao.config.modo {
        case .pistas: "A / D trocam de galho   ·   ESPAÇO salta"
        case .fuga: "A / D desviam   ·   ESPAÇO salta   ·   não bata"
        case .voo: "segure ESPAÇO para subir   ·   A / D derivam"
        case .travessia: "ESPAÇO pula para a fileira seguinte   ·   A / D andam no tronco"
        case .tunel: "A / D trocam de galeria   ·   ESPAÇO salta   ·   fique atento à marca vermelha"
        }
    }

    // MARK: Resultado

    private func resultado(sucesso: Bool) -> some View {
        ZStack {
            Color.black.opacity(0.78).ignoresSafeArea()
            VStack(spacing: 18) {
                Image(systemName: sucesso ? "flag.checkered" : "xmark.octagon.fill")
                    .font(.system(size: 42))
                    .foregroundStyle(sucesso ? Tema.ouro : Tema.perigo)
                Text(sucesso ? "PROVA CONCLUÍDA" : "PROVA INTERROMPIDA")
                    .font(.system(size: 26, weight: .heavy, design: .serif))
                    .tracking(2)
                    .foregroundStyle(Tema.papel)
                Text(sucesso ? sessao.config.titulo
                             : "Você chegou a \(Int(sessao.progresso)) de \(Int(sessao.config.meta)) \(unidade).")
                    .font(.system(size: 15, design: .serif))
                    .foregroundStyle(Tema.papel.opacity(0.8))

                HStack(spacing: 26) {
                    etiqueta("percurso", "\(Int(sessao.progresso)) \(unidade)")
                    etiqueta("coletados", "\(sessao.coletados)")
                    etiqueta("recorde", "\(max(sessao.recorde, Int(sessao.progresso))) \(unidade)")
                }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))

                Text("ESPAÇO para voltar ao campo")
                    .font(Tema.rotulo)
                    .foregroundStyle(Tema.ouro)
            }
            .padding(40)
        }
    }
}
