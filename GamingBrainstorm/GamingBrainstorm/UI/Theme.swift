//
//  Theme.swift
//  Guardiões dos Biomas
//
//  Vocabulário visual da interface: cores de caderno de campo, tipografia e
//  os painéis translúcidos usados por toda a HUD.
//

import SwiftUI
import SpriteKit

enum Tema {
    static let tinta = Color(nsColor: Palette.ink)
    static let papel = Color(nsColor: Palette.parchment)
    static let ouro = Color(nsColor: Palette.gold)
    static let perigo = Color(nsColor: Palette.danger)
    static let essencia = Color(nsColor: Palette.essence)

    static func cor(_ c: SKColor) -> Color { Color(nsColor: c) }

    static func corToast(_ t: ToastColor) -> Color {
        switch t {
        case .neutro: return papel
        case .bom: return essencia
        case .alerta: return perigo
        case .conquista: return ouro
        }
    }

    static let titulo = Font.system(size: 30, weight: .bold, design: .serif)
    static let subtitulo = Font.system(size: 15, weight: .semibold, design: .serif)
    static let corpo = Font.system(size: 14, weight: .regular, design: .rounded)
    static let rotulo = Font.system(size: 11, weight: .semibold, design: .rounded)
    static let numero = Font.system(size: 20, weight: .bold, design: .rounded)
}

/// Painel de vidro escuro com borda dourada — o "cartão" padrão da interface.
struct PainelDeCampo: ViewModifier {
    var padding: CGFloat = 14
    var raio: CGFloat = 14

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: raio, style: .continuous)
                    .fill(Color.black.opacity(0.62))
            )
            .overlay(
                RoundedRectangle(cornerRadius: raio, style: .continuous)
                    .strokeBorder(Tema.ouro.opacity(0.28), lineWidth: 1)
            )
    }
}

extension View {
    func painelDeCampo(padding: CGFloat = 14, raio: CGFloat = 14) -> some View {
        modifier(PainelDeCampo(padding: padding, raio: raio))
    }
}

/// Barra de progresso fina usada para essência e missões.
struct BarraDeProgresso: View {
    let valor: Double
    let cor: Color
    var altura: CGFloat = 8

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.14))
                Capsule()
                    .fill(LinearGradient(colors: [cor.opacity(0.75), cor],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(0, min(1, valor)) * geo.size.width)
            }
        }
        .frame(height: altura)
    }
}
