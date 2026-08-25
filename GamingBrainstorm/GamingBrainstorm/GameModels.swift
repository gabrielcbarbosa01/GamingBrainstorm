import CoreGraphics

enum AnimalKind: String, Codable, CaseIterable {
    case guardian
    case goldenLionTamarin
}

enum AbilityID: String, Codable, Hashable {
    case natureSight
    case vineClimb
}

protocol AnimalForm {
    var kind: AnimalKind { get }
    var displayName: String { get }
    var movementSpeed: CGFloat { get }
    var abilities: Set<AbilityID> { get }
}

struct GuardianForm: AnimalForm {
    let kind = AnimalKind.guardian
    let displayName = "Guardião"
    let movementSpeed: CGFloat = 285
    let abilities: Set<AbilityID> = [.natureSight]
}

struct TamarinForm: AnimalForm {
    let kind = AnimalKind.goldenLionTamarin
    let displayName = "Mico-leão-dourado"
    let movementSpeed: CGFloat = 365
    let abilities: Set<AbilityID> = [.natureSight, .vineClimb]
}

enum JourneyPhase: Int, Comparable {
    case findTamarin
    case receiveAmulet
    case transform
    case defeatSerrador
    case climbVines
    case restored

    static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

struct ProgressionState {
    private(set) var unlockedAnimals: Set<AnimalKind> = [.guardian]
    private(set) var restoredAreas: Set<String> = []
    private(set) var restoration: Int = 0

    mutating func unlock(_ form: any AnimalForm) { unlockedAnimals.insert(form.kind) }
    mutating func restore(area id: String, amount: Int) {
        restoredAreas.insert(id)
        restoration = min(100, restoration + amount)
    }
    func hasUnlocked(_ animal: AnimalKind) -> Bool { unlockedAnimals.contains(animal) }
}

struct WorldEventDefinition {
    let title: String
    let objective: String
}

enum PrototypeContent {
    static let events: [JourneyPhase: WorldEventDefinition] = [
        .findTamarin: .init(title: "Fragmentos da Mata", objective: "Siga os chamados e encontre o mico-leão-dourado"),
        .receiveAmulet: .init(title: "Um pedido entre as copas", objective: "Aproxime-se do mico e pressione E"),
        .transform: .init(title: "Amuleto do Mico", objective: "Pressione T para manifestar a forma animal"),
        .defeatSerrador: .init(title: "Serrador da Ruptura", objective: "Ataque com J ou K e esquive com L"),
        .climbVines: .init(title: "Copas Separadas", objective: "Vá até o cipó e pressione E na forma do mico"),
        .restored: .init(title: "Corredor Reconectado", objective: "Vertical slice concluído — o caminho do Cerrado foi revelado")
    ]
}
