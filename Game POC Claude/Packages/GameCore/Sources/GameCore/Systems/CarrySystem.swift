import Foundation
import simd

extension World {

    /// Bloco 10 (decisao de arquitetura): a vaca carregada NAO e um corpo fisico.
    /// Ela e cinematica, presa a uma ancora a frente de quem carrega.
    /// O peso e o cambaleio sao empurrao de input + mola visual, nunca juntas.
    func stepCarried(dt: Float) -> Float {
        var noise: Float = 0

        for c in Array(cows.values) where c.behavior == .carregada {
            guard let pid = c.carriers.first, let p = players[pid] else {
                // Carregador sumiu (desconexao, queda): a vaca cai onde estava.
                mutate(c.id) { cow in
                    cow.carriers.removeAll()
                    cow.behavior = .alerta
                    cow.behaviorTimer = 1
                }
                continue
            }

            let anchor = p.position + p.forward * (0.75 + c.size.bodyRadius * 0.6)
            mutate(c.id) { cow in
                cow.position = Vec3(anchor.x, 0.42 * cow.size.modelScale, anchor.z)
                cow.heading = p.yaw + .pi / 2
                cow.velocity = p.velocity
                cow.struggleTimer -= dt
                cow.alarm = min(1, cow.alarm + 0.08 * dt)
            }

            // Ela se debate: empurrao lateral em quem carrega.
            if let updated = cows[c.id], updated.struggleTimer <= 0 {
                let side = Vec3(cos(p.yaw), 0, -sin(p.yaw))
                let sign: Float = random() < 0.5 ? -1 : 1
                let force = c.size.struggle * (0.9 + random() * 0.8)
                mutate(pid) { player in
                    player.velocity += side * sign * force
                    player.yaw += sign * force * 0.06
                }
                mutate(c.id) { cow in
                    cow.struggleTimer = (2.6 - min(1.6, cow.size.struggle * 0.6)) * (0.6 + self.random() * 0.8)
                }
            }

            // O sino do adorno mais valioso e o que entrega a operacao.
            if c.hasBell && simd_length(p.velocity) > 0.5 {
                noise += Balance.alertBellMoving
                disturb(at: c.position, radius: Balance.noiseRadius * 0.8, amount: 0.12 * dt)
            }
        }
        return noise
    }

    /// Bloco 2: o feixe leva 6 s por vaca e custa +12 de alerta.
    func stepBeam(dt: Float) {
        let anchor = farm.shipAnchor
        for c in Array(cows.values) {
            switch c.behavior {
            case .extraida, .carregada:
                continue
            case .subindo:
                mutate(c.id) { cow in
                    cow.beamProgress += dt / Balance.beamLiftDuration
                    cow.position.y = cow.beamProgress * Balance.shipHeight
                    cow.velocity = .zero
                }
                if let updated = cows[c.id], updated.beamProgress >= 1 {
                    mutate(c.id) { $0.behavior = .extraida }
                    markExtracted(c.id)
                    addAlert(Balance.alertBeamExtraction)
                    disturb(at: anchor, radius: Balance.noiseRadius * 1.4, amount: 0.55)
                    emit(.cowExtracted(c.id))
                }
            default:
                if planarDistance(c.position, anchor) < Balance.beamRadius {
                    mutate(c.id) { cow in
                        cow.behavior = .subindo
                        cow.beamProgress = 0
                        cow.velocity = .zero
                    }
                }
            }
        }
    }

    /// Vacas em debandada atropelam quem estiver no caminho.
    func stepTrampling(dt: Float) {
        for c in Array(cows.values) where c.isPanicking && c.isOnGround {
            guard simd_length(c.velocity.flat) > Balance.tramplingSpeed else { continue }
            for pid in playerOrder {
                guard let p = players[pid], !p.isDown else { continue }
                let reach = c.size.bodyRadius + Balance.playerRadius + 0.25
                if planarDistance(p.position, c.position) < reach {
                    knockDown(pid)
                }
            }
        }
    }

    /// Bloco 2: a Alavanca de Subida. Publica, fisica, abortavel.
    func stepLever(dt: Float) {
        guard var t = leverCountdown else { return }
        t -= dt
        if t <= 0 {
            setLever(nil)
            finish()
        } else {
            setLever(t)
        }
    }
}
