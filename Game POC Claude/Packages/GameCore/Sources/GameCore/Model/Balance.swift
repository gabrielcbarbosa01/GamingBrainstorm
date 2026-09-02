import Foundation

/// Todos os numeros do documento de design vivem aqui.
/// Bloco 13: isto deve virar `Content/Balance/*.json` com hot-reload no debug.
public enum Balance {

    // MARK: Jogador
    public static let walkSpeed: Float = 4.2          // m/s
    public static let sprintMultiplier: Float = 1.75
    public static let crouchMultiplier: Float = 0.45
    public static let acceleration: Float = 22
    public static let turnRate: Float = 9             // rad/s do corpo seguindo a camera
    public static let playerRadius: Float = 0.4
    public static let interactReach: Float = 2.4
    public static let knockdownDuration: Float = 8

    // MARK: Terreno
    public static let mudSpeedMultiplier: Float = 0.45
    public static let mudSpeedMultiplierCarrying: Float = 0.40
    /// Chance por segundo de escorregar carregando na lama (escala com o porte).
    public static let mudSlipChancePerSecond: Float = 0.12

    // MARK: Alerta (Bloco 2)
    public static let alertMax: Float = 100
    public static let alertAfterStampede: Float = 40
    public static let alertDecayPerSecond: Float = 2
    public static let alertSilenceDelay: Float = 8

    public static let alertSprintNearCow: Float = 1      // por segundo
    public static let alertBellMoving: Float = 2         // por segundo
    public static let alertLanternOnCow: Float = 3       // por segundo
    public static let alertCowDropped: Float = 8         // impulso
    public static let alertGateSlammed: Float = 5        // impulso
    public static let alertBeamExtraction: Float = 12    // impulso, por vaca
    public static let alertPanickedCow: Float = 2        // por segundo, por vaca

    /// Raio em que o barulho do jogador alcanca as vacas.
    public static let noiseRadius: Float = 14
    public static let lanternRange: Float = 18
    public static let lanternHalfAngle: Float = 0.42     // rad

    // MARK: Vigilia
    public static let maxVigilia = 4
    /// Multiplicador de ganho de alerta por nivel de vigilia.
    public static func vigiliaAlertMultiplier(_ level: Int) -> Float {
        1 + 0.35 * Float(min(level, maxVigilia))
    }

    // MARK: Rebanho
    public static let cowWalkSpeed: Float = 1.5
    public static let cowPanicSpeed: Float = 7.5
    public static let cowWanderRadius: Float = 9
    public static let cowPanicContagionRadius: Float = 8
    public static let cowPanicDuration: Float = 6
    public static let stampedeDuration: Float = 22
    /// Velocidade minima de uma vaca para derrubar um jogador.
    public static let tramplingSpeed: Float = 5

    // MARK: Feixe (Bloco 2)
    public static let beamLiftDuration: Float = 6
    public static let beamRadius: Float = 3.2
    public static let shipHeight: Float = 12

    // MARK: Expedicao
    public static let leverCountdown: Float = 10
    public static let dawnAt: Float = 22 * 60           // segundos
}
