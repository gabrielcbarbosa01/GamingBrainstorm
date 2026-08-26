//
//  AmbientFaunaEngine.swift
//  GamingBrainstorm
//
//  Created by Gabriel Barbosa on 25/08/26.
//

import Foundation
import CoreGraphics

@Observable
public final class AmbientFaunaEngine {
    public var wildFauna: [WildAnimal] = []
    
    public init() {
        populateInitialFauna()
    }
    
    private func populateInitialFauna() {
        wildFauna = [
            // Amazônia: Araras-Canindé voando
            WildAnimal(id: "wild_amz_macaw_1", type: .macaw, nativeBiome: .amazonia, position: CGPoint(x: -180, y: -220), patrolRadius: 60),
            WildAnimal(id: "wild_amz_macaw_2", type: .macaw, nativeBiome: .amazonia, position: CGPoint(x: -110, y: -160), patrolRadius: 50),
            WildAnimal(id: "wild_amz_macaw_3", type: .macaw, nativeBiome: .amazonia, position: CGPoint(x: -240, y: -260), patrolRadius: 55),
            
            // Pantanal: Capivaras na beira do rio
            WildAnimal(id: "wild_pan_capy_1", type: .capybara, nativeBiome: .pantanal, position: CGPoint(x: -35, y: -40), patrolRadius: 28),
            WildAnimal(id: "wild_pan_capy_2", type: .capybara, nativeBiome: .pantanal, position: CGPoint(x: -42, y: 15), patrolRadius: 25),
            WildAnimal(id: "wild_pan_capy_3", type: .capybara, nativeBiome: .pantanal, position: CGPoint(x: -30, y: 70), patrolRadius: 30),
            
            // Mata Atlântica: Borboletas Azuis
            WildAnimal(id: "wild_mat_bfly_1", type: .butterfly, nativeBiome: .mataAtlantica, position: CGPoint(x: 40, y: 110), patrolRadius: 35),
            WildAnimal(id: "wild_mat_bfly_2", type: .butterfly, nativeBiome: .mataAtlantica, position: CGPoint(x: 90, y: 150), patrolRadius: 30),
            WildAnimal(id: "wild_mat_bfly_3", type: .butterfly, nativeBiome: .mataAtlantica, position: CGPoint(x: 140, y: 170), patrolRadius: 40),
            
            // Caatinga: Tatus-Mirins
            WildAnimal(id: "wild_caa_arma_1", type: .armadillo, nativeBiome: .caatinga, position: CGPoint(x: 120, y: -240), patrolRadius: 30),
            WildAnimal(id: "wild_caa_arma_2", type: .armadillo, nativeBiome: .caatinga, position: CGPoint(x: 180, y: -160), patrolRadius: 25),
            
            // Pampa: Emas nas coxilhas
            WildAnimal(id: "wild_pam_rhea_1", type: .rhea, nativeBiome: .pampa, position: CGPoint(x: -50, y: 260), patrolRadius: 45),
            WildAnimal(id: "wild_pam_rhea_2", type: .rhea, nativeBiome: .pampa, position: CGPoint(x: 60, y: 290), patrolRadius: 40)
        ]
    }
    
    /// Update organic wandering & reactive scattering AI
    public func update(deltaTime: Double, playerPos: CGPoint, enemies: [WorldEnemy]) {
        for index in wildFauna.indices {
            var animal = wildFauna[index]
            
            // 1. Check Threat Distance (Player or Enemies within 18m)
            let distToPlayer = hypot(animal.position.x - playerPos.x, animal.position.y - playerPos.y)
            var threatOrigin: CGPoint? = (distToPlayer < 20.0) ? playerPos : nil
            
            if threatOrigin == nil {
                for enemy in enemies where !enemy.isNeutralized {
                    let dist = hypot(animal.position.x - enemy.position.x, animal.position.y - enemy.position.y)
                    if dist < 22.0 {
                        threatOrigin = enemy.position
                        break
                    }
                }
            }
            
            // 2. React to Threat
            if let threat = threatOrigin {
                animal.isScattering = true
                animal.scatterTimer = 2.5
                // Flee in opposite direction of threat
                let fleeAngle = atan2(animal.position.y - threat.y, animal.position.x - threat.x)
                animal.wanderAngle = fleeAngle
            } else if animal.scatterTimer > 0 {
                animal.scatterTimer -= deltaTime
                if animal.scatterTimer <= 0 {
                    animal.isScattering = false
                }
            }
            
            // 3. Movement
            let speed = animal.isScattering ? (animal.type.baseSpeed * 2.8) : animal.type.baseSpeed
            if !animal.isScattering {
                // Subtle wander angle modulation
                animal.wanderAngle += Double.random(in: -0.25...0.25)
            }
            
            let moveX = cos(animal.wanderAngle) * speed
            let moveY = sin(animal.wanderAngle) * speed
            
            let nextX = animal.position.x + moveX
            let nextY = animal.position.y + moveY
            
            // Leash to patrol origin
            let distFromOrigin = hypot(nextX - animal.patrolOrigin.x, nextY - animal.patrolOrigin.y)
            if distFromOrigin > animal.patrolRadius {
                // Steer back towards patrol origin
                animal.wanderAngle = atan2(animal.patrolOrigin.y - animal.position.y, animal.patrolOrigin.x - animal.position.x)
            }
            
            animal.position = CGPoint(
                x: min(max(nextX, -340), 340),
                y: min(max(nextY, -340), 340)
            )
            
            wildFauna[index] = animal
        }
    }
}
