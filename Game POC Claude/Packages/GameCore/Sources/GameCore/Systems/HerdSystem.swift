import Foundation
import simd

extension World {

    /// IA do rebanho. Bloco 13: boids proprio, nao GKAgent — mais previsivel de sincronizar.
    /// Retorna a taxa de alerta por segundo gerada pelas vacas.
    func stepHerd(dt: Float) -> Float {
        var noise: Float = 0
        var panicking = 0

        if stampedeTimer > 0 {
            stampedeTimer -= dt
            if stampedeTimer <= 0 { calmDownAfterStampede() }
        }

        for c in Array(cows.values) {
            guard c.isOnGround, c.behavior != .carregada, c.behavior != .subindo else { continue }
            var cow = c
            cow.behaviorTimer -= dt
            cow.alarm = max(0, cow.alarm - 0.15 * dt)

            switch cow.behavior {
            case .dormindo:
                cow.velocity = .zero
                if cow.alarm > 0.25 {
                    cow.behavior = .alerta
                    cow.behaviorTimer = 1.5
                }

            case .alerta:
                cow.velocity *= max(0, 1 - 5 * dt)
                if cow.behaviorTimer <= 0 {
                    if cow.alarm > 0.7 {
                        cow.behavior = .panico
                        cow.behaviorTimer = Balance.cowPanicDuration
                    } else {
                        cow.behavior = .pastando
                        cow.behaviorTimer = 0
                        cow.wanderTarget = randomPoint(radius: Balance.cowWanderRadius, around: cow.position)
                    }
                }

            case .pastando:
                if cow.behaviorTimer > 0 {
                    cow.velocity *= max(0, 1 - 4 * dt)
                } else {
                    let toTarget = (cow.wanderTarget - cow.position).flat
                    if simd_length(toTarget) < 1.0 {
                        cow.behaviorTimer = 2 + random() * 5
                        cow.wanderTarget = randomPoint(radius: Balance.cowWanderRadius, around: cow.position)
                    } else {
                        let dir = normalizedOrZero(toTarget)
                        cow.velocity = dir * Balance.cowWalkSpeed
                        cow.heading = atan2(dir.x, dir.z)
                    }
                }
                if cow.alarm > 0.8 {
                    cow.behavior = .panico
                    cow.behaviorTimer = Balance.cowPanicDuration
                }

            case .panico:
                panicking += 1
                var away = normalizedOrZero((cow.position - cow.fleeFrom).flat)
                if simd_length(away) < 0.1 { away = Vec3(sin(cow.heading), 0, cos(cow.heading)) }
                // Separacao simples: nao atravessa as vizinhas.
                var sep = Vec3.zero
                for other in Array(cows.values) where other.id != cow.id && other.isOnGround {
                    let d = (cow.position - other.position).flat
                    let dist = simd_length(d)
                    if dist > 0.01 && dist < 3.0 { sep += normalizedOrZero(d) / dist }
                }
                let dir = normalizedOrZero(away + sep * 0.6)
                cow.velocity = dir * Balance.cowPanicSpeed
                cow.heading = atan2(dir.x, dir.z)
                if cow.behaviorTimer <= 0 && stampedeTimer <= 0 {
                    cow.behavior = .alerta
                    cow.behaviorTimer = 1.5
                    cow.alarm = 0.5
                }

            default:
                break
            }

            cow.position = farm.resolveFences(cow.position + cow.velocity * dt,
                                              radius: cow.size.bodyRadius)
            cow.position.y = 0
            cows[cow.id] = cow
            separate(cow.id)
        }

        // Contagio de panico: a mesma regra do estresse no habitat (Bloco 3).
        if stampedeTimer <= 0 {
            let panickers = cows.values.filter { $0.isPanicking && $0.isOnGround }
            for source in panickers {
                for other in Array(cows.values) where other.id != source.id && other.isOnGround && !other.isPanicking {
                    if planarDistance(source.position, other.position) < Balance.cowPanicContagionRadius {
                        mutate(other.id) { cow in
                            cow.alarm = min(1, cow.alarm + 0.55 * dt)
                            if cow.alarm >= 0.9 {
                                cow.behavior = .panico
                                cow.behaviorTimer = Balance.cowPanicDuration
                                cow.fleeFrom = source.position
                                self.emit(.cowPanicked(cow.id))
                            }
                        }
                    }
                }
            }
        }

        noise += min(10, Float(panicking) * Balance.alertPanickedCow)
        return noise
    }

    /// Vacas nao se atravessam. Empurrao simetrico e barato, roda so no host.
    private func separate(_ id: CowID) {
        guard let me = cows[id], me.isOnGround else { return }
        for other in Array(cows.values) where other.id != id && other.isOnGround {
            let delta = (me.position - other.position).flat
            let dist = simd_length(delta)
            let minDist = me.size.bodyRadius + other.size.bodyRadius
            guard dist < minDist else { continue }
            let push = normalizedOrZero(dist > 0.001 ? delta : Vec3(1, 0, 0)) * (minDist - dist) * 0.5
            mutate(id) { $0.position = self.farm.resolveFences($0.position + push, radius: $0.size.bodyRadius) }
            mutate(other.id) { $0.position = self.farm.resolveFences($0.position - push, radius: $0.size.bodyRadius) }
            return
        }
    }

    private func calmDownAfterStampede() {
        for c in Array(cows.values) where c.isOnGround && c.behavior == .panico {
            mutate(c.id) { cow in
                cow.behavior = .alerta
                cow.behaviorTimer = 2
                cow.alarm = 0.4
            }
        }
    }

    /// Bloco 2: o alerta e uma escada. Estourar sobe a Vigilia, que nunca desce.
    func stepAlert(dt: Float, noiseRate: Float) {
        // Durante a debandada o campo ja esta perdido: o medidor fica congelado.
        guard stampedeTimer <= 0 else { return }

        if noiseRate > 0 {
            resetSilence()
            addAlert(noiseRate * Balance.vigiliaAlertMultiplier(vigilia) * dt)
        } else {
            advanceSilence(dt)
            if silenceElapsed > Balance.alertSilenceDelay {
                decayAlert(Balance.alertDecayPerSecond * dt)
            }
        }

        if alert >= Balance.alertMax {
            raiseVigilia()
        }
    }
}
