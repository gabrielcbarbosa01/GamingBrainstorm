import SwiftUI
import GameCore

/// HUD minima. O jogo deve ser legivel pelo mundo — isto e so o que o mundo nao diz.
struct HUDView: View {
    let hud: HUDState

    private let beam = Color(red: 0.35, green: 0.85, blue: 0.80)
    private let alerta = Color(red: 0.95, green: 0.53, blue: 0.30)
    private let ink = Color.white.opacity(0.88)

    var body: some View {
        ZStack {
            VStack {
                HStack(alignment: .top) {
                    alertPanel
                    Spacer()
                    cargoPanel
                }
                Spacer()
                bottom
            }
            .padding(22)

            if let p = hud.liftProgress { liftRing(p) }
            if let c = hud.leverCountdown { countdown(c) }
            if !hud.mouseCaptured && hud.summary == nil { captureHint }
            if hud.isDown { downOverlay }
            if hud.stampede { stampedeBanner }
            if let s = hud.summary { SummaryView(summary: s) }
        }
        .allowsHitTesting(false)
        .font(.system(size: 13, weight: .medium, design: .rounded))
    }

    // MARK: Alerta e vigilia
    private var alertPanel: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("ALERTA DA FAZENDA")
                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                .tracking(1.6)
                .foregroundStyle(.white.opacity(0.55))

            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.10)).frame(width: 220, height: 9)
                Capsule()
                    .fill(LinearGradient(colors: [beam, alerta], startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(3, 220 * CGFloat(min(1, hud.alert))), height: 9)
            }

            HStack(spacing: 5) {
                ForEach(0..<5, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(i <= hud.vigilia ? alerta : Color.white.opacity(0.12))
                        .frame(width: 24, height: 4)
                }
                Text("VIGÍLIA \(hud.vigilia) · \(hud.vigiliaName.uppercased())")
                    .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                    .tracking(1.1)
                    .foregroundStyle(hud.vigilia > 0 ? alerta : .white.opacity(0.5))
                    .padding(.leading, 4)
            }
        }
        .padding(14)
        .background(.black.opacity(0.45), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: Carga
    private var cargoPanel: some View {
        VStack(alignment: .trailing, spacing: 5) {
            Text("CARGA")
                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                .tracking(1.6)
                .foregroundStyle(.white.opacity(0.55))
            Text("\(hud.cargoCount) vaca\(hud.cargoCount == 1 ? "" : "s")")
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(ink)
            Text("\(hud.cargoValue) créditos")
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(beam)
            Text("\(hud.cowsLeft) no pasto  ·  \(timeString)")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.45))
        }
        .padding(14)
        .background(.black.opacity(0.45), in: RoundedRectangle(cornerRadius: 12))
    }

    private var timeString: String {
        let t = Int(hud.elapsed)
        return String(format: "%02d:%02d", t / 60, t % 60)
    }

    // MARK: Rodape
    private var bottom: some View {
        VStack(spacing: 10) {
            ForEach(Array(hud.messages.prefix(4).enumerated()), id: \.offset) { i, m in
                Text(m)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(1 - Double(i) * 0.22))
                    .padding(.horizontal, 12).padding(.vertical, 5)
                    .background(.black.opacity(0.4), in: Capsule())
            }

            if let prompt = hud.prompt {
                VStack(spacing: 2) {
                    Text(prompt)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    if let d = hud.promptDetail {
                        Text(d)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(beam)
                    }
                }
                .padding(.horizontal, 18).padding(.vertical, 10)
                .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 10))
            }

            if let lever = hud.leverPrompt {
                Text(lever)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(alerta)
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 10))
            }

            HStack(spacing: 14) {
                Label(hud.hands, systemImage: "hand.raised.fill")
                    .foregroundStyle(ink)
                Text("WASD mover · SHIFT correr · C agachar · E pegar/soltar · F lanterna · R alavanca · roda: zoom · ESC solta o mouse")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.42))
            }
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(.black.opacity(0.4), in: Capsule())
        }
    }

    // MARK: Sobreposicoes
    private func liftRing(_ p: Float) -> some View {
        Circle()
            .trim(from: 0, to: CGFloat(min(1, max(0, p))))
            .stroke(beam, style: StrokeStyle(lineWidth: 4, lineCap: .round))
            .frame(width: 54, height: 54)
            .rotationEffect(.degrees(-90))
    }

    private func countdown(_ t: Float) -> some View {
        VStack(spacing: 4) {
            Text("SUBIDA EM")
                .font(.system(size: 11, weight: .bold, design: .monospaced)).tracking(2)
                .foregroundStyle(alerta)
            Text(String(format: "%.1f", t))
                .font(.system(size: 54, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
            Text("[R] para abortar")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(24)
        .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 16))
        .offset(y: -110)
    }

    private var captureHint: some View {
        VStack(spacing: 6) {
            Image(systemName: "cursorarrow.click")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(beam)
            Text("Clique na janela para controlar a câmera")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text("ESC solta o mouse  ·  roda do mouse aproxima e afasta")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.horizontal, 26).padding(.vertical, 18)
        .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 14))
    }

    private var downOverlay: some View {
        Text("DERRUBADO")
            .font(.system(size: 30, weight: .heavy, design: .rounded))
            .foregroundStyle(alerta)
            .padding(.horizontal, 26).padding(.vertical, 12)
            .background(.black.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
    }

    private var stampedeBanner: some View {
        VStack {
            Text("DEBANDADA")
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .tracking(4)
                .foregroundStyle(alerta)
                .padding(.horizontal, 22).padding(.vertical, 8)
                .background(.black.opacity(0.45), in: Capsule())
            Spacer()
        }
        .padding(.top, 120)
    }
}

struct SummaryView: View {
    let summary: ExpeditionSummary

    var body: some View {
        VStack(spacing: 14) {
            Text("PRESTAÇÃO DE CONTAS")
                .font(.system(size: 11, weight: .bold, design: .monospaced)).tracking(3)
                .foregroundStyle(.white.opacity(0.5))
            Text("\(summary.totalValue) créditos")
                .font(.system(size: 46, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 5) {
                if summary.extracted.isEmpty {
                    Text("Nenhum espécime a bordo. O Conselho registra constrangimento.")
                        .foregroundStyle(.white.opacity(0.65))
                }
                ForEach(Array(summary.extracted.enumerated()), id: \.offset) { _, item in
                    HStack {
                        Text(item.name).foregroundStyle(.white)
                        Text("· \(item.size.displayName)").foregroundStyle(.white.opacity(0.5))
                        Spacer()
                        Text("\(item.value)")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color(red: 0.35, green: 0.85, blue: 0.80))
                    }
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
            }
            .frame(width: 320)

            Text(String(format: "Duração %02d:%02d  ·  Vigília máxima %d",
                        Int(summary.duration) / 60, Int(summary.duration) % 60, summary.maxVigilia))
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.45))
        }
        .padding(34)
        .background(.black.opacity(0.82), in: RoundedRectangle(cornerRadius: 20))
    }
}
