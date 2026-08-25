import AppKit
import SpriteKit

final class GameScene: SKScene {
    private let world = SKNode()
    private let gameCamera = SKCameraNode()
    private let player = SKNode()
    private let guardianVisual = SKNode()
    private let tamarinVisual = SKSpriteNode(imageNamed: "MicoPrototype")
    private let tamarinNPC = SKSpriteNode(imageNamed: "MicoPrototype")
    private let vineGate = SKNode()
    private let natureSightRing = SKShapeNode(circleOfRadius: 240)

    private let titleLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let objectiveLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
    private let controlsLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
    private let formLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let restorationLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let toastLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let healthFill = SKShapeNode(rectOf: CGSize(width: 220, height: 16), cornerRadius: 8)
    private let enemyHealthGroup = SKNode()
    private let enemyHealthFill = SKShapeNode(rectOf: CGSize(width: 260, height: 12), cornerRadius: 6)

    private var phase: JourneyPhase = .findTamarin
    private var progression = ProgressionState()
    private var form: any AnimalForm = GuardianForm()
    private var keys = Set<UInt16>()
    private var lastTime: TimeInterval = 0
    private var lastDirection = CGVector(dx: 1, dy: 0)
    private var attackReadyAt: TimeInterval = 0
    private var invulnerableUntil: TimeInterval = 0
    private var enemyAttackReadyAt: TimeInterval = 0
    private var currentTime: TimeInterval = 0
    private var playerHealth: CGFloat = 100
    private var enemyHealth: CGFloat = 100
    private var enemy: SKNode?
    private var isMoving = false
    private var isNatureSightActive = false
    private var forestNodes: [SKShapeNode] = []

    private let worldBounds = CGRect(x: -1250, y: -720, width: 2500, height: 1440)

    static func makeScene() -> GameScene {
        let scene = GameScene(size: CGSize(width: 1280, height: 720))
        scene.scaleMode = .aspectFill
        return scene
    }

    override func didMove(to view: SKView) {
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = NSColor(red: 0.025, green: 0.055, blue: 0.045, alpha: 1)
        buildWorld()
        buildPlayer()
        buildCameraAndHUD()
        updateHUD()
        showToast("MATA ATLÂNTICA • 12% RESTAURADA")
    }

    // MARK: - World

    private func buildWorld() {
        addChild(world)
        let ground = SKShapeNode(rectOf: worldBounds.size, cornerRadius: 100)
        ground.position = CGPoint(x: worldBounds.midX, y: worldBounds.midY)
        ground.fillColor = NSColor(red: 0.105, green: 0.18, blue: 0.13, alpha: 1)
        ground.strokeColor = NSColor(red: 0.18, green: 0.34, blue: 0.22, alpha: 1)
        ground.lineWidth = 12
        ground.zPosition = -100
        ground.name = "ground"
        world.addChild(ground)

        buildDistantForest()
        buildPaths()
        buildFragmentedForest()
        buildTamarinEncounter()
        buildVineGate()
        buildAmbientLife()
    }

    private func buildDistantForest() {
        for index in 0..<36 {
            let x = CGFloat((index * 227) % 2400) - 1200
            let upper = index.isMultiple(of: 2)
            let y = upper ? CGFloat(420 + (index * 37) % 260) : CGFloat(-670 + (index * 41) % 180)
            let tree = makeTree(scale: CGFloat(0.85 + Double(index % 4) * 0.12), healthy: index % 5 != 0)
            tree.position = CGPoint(x: x, y: y)
            tree.zPosition = depth(for: tree.position.y)
            world.addChild(tree)
        }
    }

    private func buildPaths() {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -1200, y: -150))
        path.addCurve(to: CGPoint(x: 1200, y: 80), control1: CGPoint(x: -550, y: 230), control2: CGPoint(x: 520, y: -250))
        let road = SKShapeNode(path: path)
        road.lineWidth = 190
        road.strokeColor = NSColor(red: 0.23, green: 0.22, blue: 0.16, alpha: 1)
        road.zPosition = -80
        world.addChild(road)

        let center = SKShapeNode(path: path)
        center.lineWidth = 5
        center.strokeColor = NSColor(red: 0.55, green: 0.45, blue: 0.25, alpha: 0.28)
        center.zPosition = -79
        world.addChild(center)
    }

    private func buildFragmentedForest() {
        let positions: [CGPoint] = [
            .init(x: -1030, y: 280), .init(x: -820, y: 230), .init(x: -610, y: 330),
            .init(x: -450, y: 175), .init(x: -220, y: 290), .init(x: 50, y: 250),
            .init(x: 310, y: 360), .init(x: 610, y: 280), .init(x: 920, y: 330),
            .init(x: 1110, y: 200), .init(x: 560, y: -330), .init(x: 850, y: -300)
        ]
        for (index, position) in positions.enumerated() {
            let tree = makeTree(scale: CGFloat(0.82 + Double(index % 3) * 0.14), healthy: false)
            tree.position = position
            tree.zPosition = depth(for: position.y)
            tree.name = "restorableTree"
            forestNodes.append(tree)
            world.addChild(tree)
        }

        for x in stride(from: CGFloat(470), through: 850, by: 95) {
            let stump = SKShapeNode(ellipseOf: CGSize(width: 62, height: 26))
            stump.position = CGPoint(x: x, y: CGFloat(-70 + Int(x) % 150))
            stump.fillColor = NSColor(red: 0.31, green: 0.21, blue: 0.12, alpha: 1)
            stump.strokeColor = NSColor(red: 0.15, green: 0.10, blue: 0.06, alpha: 1)
            stump.zPosition = depth(for: stump.position.y)
            world.addChild(stump)
        }
    }

    private func makeTree(scale: CGFloat, healthy: Bool) -> SKShapeNode {
        let canopy = SKShapeNode(ellipseOf: CGSize(width: 155, height: 105))
        canopy.setScale(scale)
        canopy.fillColor = healthy
            ? NSColor(red: 0.10, green: 0.38, blue: 0.18, alpha: 1)
            : NSColor(red: 0.20, green: 0.28, blue: 0.19, alpha: 1)
        canopy.strokeColor = NSColor(red: 0.055, green: 0.17, blue: 0.09, alpha: 1)
        canopy.lineWidth = 7

        let crown2 = SKShapeNode(ellipseOf: CGSize(width: 105, height: 85))
        crown2.position = CGPoint(x: -45, y: 22)
        crown2.fillColor = canopy.fillColor
        crown2.strokeColor = canopy.strokeColor
        crown2.lineWidth = 5
        canopy.addChild(crown2)

        let trunk = SKShapeNode(rectOf: CGSize(width: 28, height: 145), cornerRadius: 12)
        trunk.position = CGPoint(x: 0, y: -92)
        trunk.fillColor = NSColor(red: 0.28, green: 0.18, blue: 0.11, alpha: 1)
        trunk.strokeColor = NSColor(red: 0.13, green: 0.08, blue: 0.05, alpha: 1)
        trunk.lineWidth = 5
        trunk.zPosition = -1
        canopy.addChild(trunk)
        return canopy
    }

    private func buildTamarinEncounter() {
        tamarinNPC.position = CGPoint(x: -80, y: 0)
        tamarinNPC.size = CGSize(width: 105, height: 98)
        tamarinNPC.zPosition = depth(for: tamarinNPC.position.y) + 2
        tamarinNPC.name = "tamarinNPC"
        tamarinNPC.run(.repeatForever(.sequence([
            .moveBy(x: 0, y: 9, duration: 0.65),
            .moveBy(x: 0, y: -9, duration: 0.65)
        ])))
        world.addChild(tamarinNPC)

        let call = SKLabelNode(fontNamed: "AvenirNext-Bold")
        call.text = "krii…"
        call.fontSize = 22
        call.fontColor = NSColor(red: 1, green: 0.73, blue: 0.25, alpha: 1)
        call.position = CGPoint(x: 0, y: 76)
        tamarinNPC.addChild(call)
    }

    private func buildVineGate() {
        vineGate.position = CGPoint(x: 1030, y: 120)
        vineGate.zPosition = depth(for: vineGate.position.y) + 4
        vineGate.name = "vineGate"
        for offset in stride(from: CGFloat(-70), through: 70, by: 35) {
            let vine = SKShapeNode(rectOf: CGSize(width: 12, height: 270), cornerRadius: 6)
            vine.position = CGPoint(x: offset, y: 30)
            vine.fillColor = NSColor(red: 0.18, green: 0.50, blue: 0.16, alpha: 1)
            vine.strokeColor = NSColor(red: 0.07, green: 0.23, blue: 0.08, alpha: 1)
            vine.zRotation = sin(offset) * 0.08
            vineGate.addChild(vine)
        }
        let marker = SKLabelNode(fontNamed: "AvenirNext-Bold")
        marker.text = "CIPÓS ENTRE AS COPAS"
        marker.fontSize = 16
        marker.fontColor = .systemGreen
        marker.position = CGPoint(x: 0, y: 195)
        vineGate.addChild(marker)
        vineGate.alpha = 0.35
        world.addChild(vineGate)
    }

    private func buildAmbientLife() {
        for index in 0..<28 {
            let mote = SKShapeNode(circleOfRadius: CGFloat(1 + index % 3))
            mote.fillColor = NSColor(red: 0.78, green: 0.85, blue: 0.55, alpha: 0.35)
            mote.strokeColor = .clear
            mote.position = CGPoint(x: CGFloat((index * 191) % 2300) - 1150, y: CGFloat((index * 83) % 1000) - 500)
            mote.zPosition = 2000
            mote.run(.repeatForever(.sequence([
                .moveBy(x: 18, y: 35, duration: 3 + Double(index % 3)),
                .moveBy(x: -18, y: -35, duration: 3 + Double(index % 3))
            ])))
            world.addChild(mote)
        }
    }

    // MARK: - Player and visuals

    private func buildPlayer() {
        player.position = CGPoint(x: -920, y: -110)
        player.zPosition = depth(for: player.position.y) + 10
        player.name = "player"
        world.addChild(player)

        let aura = SKShapeNode(circleOfRadius: 38)
        aura.fillColor = NSColor(red: 0.22, green: 0.82, blue: 0.66, alpha: 0.18)
        aura.strokeColor = NSColor(red: 0.37, green: 1, blue: 0.78, alpha: 0.8)
        aura.glowWidth = 12
        guardianVisual.addChild(aura)

        let body = SKShapeNode(ellipseOf: CGSize(width: 48, height: 58))
        body.fillColor = NSColor(red: 0.18, green: 0.63, blue: 0.49, alpha: 1)
        body.strokeColor = .white
        body.lineWidth = 3
        body.position.y = 4
        guardianVisual.addChild(body)

        let face = SKShapeNode(circleOfRadius: 17)
        face.fillColor = NSColor(red: 0.86, green: 0.70, blue: 0.53, alpha: 1)
        face.strokeColor = .white
        face.lineWidth = 2
        face.position.y = 33
        guardianVisual.addChild(face)
        player.addChild(guardianVisual)

        tamarinVisual.size = CGSize(width: 112, height: 105)
        tamarinVisual.alpha = 0
        tamarinVisual.name = "tamarinForm"
        player.addChild(tamarinVisual)
    }

    // MARK: - Camera and HUD

    private func buildCameraAndHUD() {
        addChild(gameCamera)
        camera = gameCamera
        gameCamera.position = player.position
        gameCamera.setScale(0.94)

        let panel = SKShapeNode(rectOf: CGSize(width: 850, height: 100), cornerRadius: 22)
        panel.position = CGPoint(x: -160, y: 284)
        panel.fillColor = NSColor(white: 0.025, alpha: 0.84)
        panel.strokeColor = NSColor(red: 0.28, green: 0.64, blue: 0.39, alpha: 0.65)
        panel.lineWidth = 2
        panel.zPosition = 10_000
        gameCamera.addChild(panel)

        titleLabel.fontSize = 21
        titleLabel.fontColor = NSColor(red: 1, green: 0.76, blue: 0.30, alpha: 1)
        titleLabel.horizontalAlignmentMode = .left
        titleLabel.position = CGPoint(x: -395, y: 16)
        panel.addChild(titleLabel)

        objectiveLabel.fontSize = 16
        objectiveLabel.horizontalAlignmentMode = .left
        objectiveLabel.position = CGPoint(x: -395, y: -19)
        panel.addChild(objectiveLabel)

        formLabel.fontSize = 14
        formLabel.horizontalAlignmentMode = .right
        formLabel.position = CGPoint(x: 395, y: 16)
        panel.addChild(formLabel)

        restorationLabel.fontSize = 14
        restorationLabel.fontColor = .systemGreen
        restorationLabel.horizontalAlignmentMode = .right
        restorationLabel.position = CGPoint(x: 395, y: -19)
        panel.addChild(restorationLabel)

        let healthBack = SKShapeNode(rectOf: CGSize(width: 230, height: 26), cornerRadius: 13)
        healthBack.position = CGPoint(x: -500, y: 218)
        healthBack.fillColor = NSColor(white: 0.04, alpha: 0.9)
        healthBack.strokeColor = NSColor(white: 0.8, alpha: 0.4)
        healthBack.zPosition = 10_000
        gameCamera.addChild(healthBack)

        healthFill.fillColor = NSColor(red: 0.30, green: 0.82, blue: 0.48, alpha: 1)
        healthFill.strokeColor = .clear
        healthFill.position = CGPoint(x: -5, y: 0)
        healthBack.addChild(healthFill)

        controlsLabel.text = "WASD mover  •  J ataque  •  K forte  •  L esquiva  •  T transformar  •  ESPAÇO percepção  •  E interagir"
        controlsLabel.fontSize = 15
        controlsLabel.fontColor = NSColor(white: 0.92, alpha: 1)
        controlsLabel.position = CGPoint(x: 0, y: -320)
        controlsLabel.zPosition = 10_000
        gameCamera.addChild(controlsLabel)

        toastLabel.fontSize = 25
        toastLabel.fontColor = .systemYellow
        toastLabel.position = CGPoint(x: 0, y: 145)
        toastLabel.zPosition = 10_020
        toastLabel.alpha = 0
        gameCamera.addChild(toastLabel)

        let enemyBack = SKShapeNode(rectOf: CGSize(width: 276, height: 28), cornerRadius: 14)
        enemyBack.fillColor = NSColor(white: 0.02, alpha: 0.9)
        enemyBack.strokeColor = .systemRed
        enemyHealthGroup.addChild(enemyBack)
        enemyHealthFill.fillColor = .systemRed
        enemyHealthFill.strokeColor = .clear
        enemyBack.addChild(enemyHealthFill)
        let enemyName = SKLabelNode(fontNamed: "AvenirNext-Bold")
        enemyName.text = "SERRADOR DA RUPTURA"
        enemyName.fontSize = 15
        enemyName.position.y = 25
        enemyHealthGroup.addChild(enemyName)
        enemyHealthGroup.position = CGPoint(x: 0, y: 215)
        enemyHealthGroup.zPosition = 10_010
        enemyHealthGroup.alpha = 0
        gameCamera.addChild(enemyHealthGroup)

        natureSightRing.fillColor = NSColor(red: 0.12, green: 0.82, blue: 0.54, alpha: 0.08)
        natureSightRing.strokeColor = NSColor(red: 0.35, green: 1, blue: 0.68, alpha: 0.85)
        natureSightRing.lineWidth = 8
        natureSightRing.glowWidth = 22
        natureSightRing.alpha = 0
        natureSightRing.zPosition = 2200
        world.addChild(natureSightRing)
    }

    // MARK: - Input and update

    override func keyDown(with event: NSEvent) {
        guard !event.isARepeat else { return }
        keys.insert(event.keyCode)
        switch event.charactersIgnoringModifiers?.lowercased() {
        case "e": interact()
        case "t": toggleTransformation()
        case " ": useNatureSight()
        case "j": attack(damage: 18, heavy: false)
        case "k": attack(damage: 32, heavy: true)
        case "l": dodge()
        default: break
        }
    }

    override func keyUp(with event: NSEvent) { keys.remove(event.keyCode) }

    override func update(_ time: TimeInterval) {
        currentTime = time
        let dt = lastTime == 0 ? 0 : min(time - lastTime, 1.0 / 30.0)
        lastTime = time
        updateMovement(deltaTime: dt)
        updateCamera()
        updateEncounterState()
        updateEnemy(deltaTime: dt)
        updateDepth()
    }

    private func updateMovement(deltaTime: TimeInterval) {
        var direction = CGVector.zero
        if keys.contains(0) || keys.contains(123) { direction.dx -= 1 }
        if keys.contains(2) || keys.contains(124) { direction.dx += 1 }
        if keys.contains(1) || keys.contains(125) { direction.dy -= 1 }
        if keys.contains(13) || keys.contains(126) { direction.dy += 1 }
        let length = hypot(direction.dx, direction.dy)
        isMoving = length > 0
        guard length > 0 else { return }
        direction.dx /= length
        direction.dy /= length
        lastDirection = direction
        let speed = form.movementSpeed * CGFloat(deltaTime)
        player.position.x = max(worldBounds.minX + 55, min(worldBounds.maxX - 55, player.position.x + direction.dx * speed))
        player.position.y = max(worldBounds.minY + 55, min(worldBounds.maxY - 55, player.position.y + direction.dy * speed * 0.78))
        player.xScale = direction.dx < 0 ? -abs(player.xScale) : abs(player.xScale)
    }

    private func updateCamera() {
        let lookAhead = CGPoint(x: lastDirection.dx * 95, y: lastDirection.dy * 55)
        let target = CGPoint(x: player.position.x + lookAhead.x, y: player.position.y + lookAhead.y)
        gameCamera.position.x += (target.x - gameCamera.position.x) * 0.075
        gameCamera.position.y += (target.y - gameCamera.position.y) * 0.075
        let desiredScale: CGFloat = isMoving ? 1.07 : 0.92
        let nextScale = gameCamera.xScale + (desiredScale - gameCamera.xScale) * 0.045
        gameCamera.setScale(nextScale)
    }

    private func updateEncounterState() {
        if phase == .findTamarin, distance(player.position, tamarinNPC.position) < 270 {
            phase = .receiveAmulet
            showToast("UM MICO OBSERVA VOCÊ ENTRE AS ÁRVORES")
            updateHUD()
        }
        if phase == .receiveAmulet, distance(player.position, tamarinNPC.position) < 140 {
            controlsLabel.text = "[ E ]  Criar conexão com o mico-leão-dourado"
        } else if phase == .climbVines, distance(player.position, vineGate.position) < 150 {
            controlsLabel.text = "[ E ]  Escalar os cipós e reconectar as copas"
        } else {
            controlsLabel.text = "WASD mover  •  J ataque  •  K forte  •  L esquiva  •  T transformar  •  ESPAÇO percepção  •  E interagir"
        }
    }

    private func updateDepth() {
        player.zPosition = depth(for: player.position.y) + 12
        enemy?.zPosition = depth(for: enemy?.position.y ?? 0) + 10
    }

    // MARK: - Transformation and interaction

    private func interact() {
        if phase == .receiveAmulet, distance(player.position, tamarinNPC.position) < 150 {
            phase = .transform
            progression.unlock(TamarinForm())
            tamarinNPC.run(.sequence([.group([.fadeAlpha(to: 0.45, duration: 0.5), .scale(to: 0.82, duration: 0.5)]), .moveBy(x: 100, y: 180, duration: 0.7)]))
            showToast("AMULETO DO MICO-LEÃO-DOURADO")
            burst(at: player.position, color: .systemOrange)
            updateHUD()
        } else if phase == .climbVines, distance(player.position, vineGate.position) < 160 {
            guard form.kind == .goldenLionTamarin else {
                showToast("MANIFESTE A FORMA DO MICO PARA ESCALAR")
                return
            }
            completeRestoration()
        }
    }

    private func toggleTransformation() {
        guard progression.hasUnlocked(.goldenLionTamarin) else { return }
        if form.kind == .guardian {
            form = TamarinForm()
            guardianVisual.run(.fadeOut(withDuration: 0.18))
            tamarinVisual.run(.fadeIn(withDuration: 0.25))
            burst(at: player.position, color: .systemOrange)
            if phase == .transform {
                phase = .defeatSerrador
                spawnSerrador()
            }
            showToast("FORMA ESPIRITUAL DO MICO")
        } else {
            form = GuardianForm()
            tamarinVisual.run(.fadeOut(withDuration: 0.18))
            guardianVisual.run(.fadeIn(withDuration: 0.25))
        }
        updateHUD()
    }

    private func useNatureSight() {
        guard !isNatureSightActive else { return }
        isNatureSightActive = true
        natureSightRing.position = player.position
        natureSightRing.setScale(0.2)
        natureSightRing.alpha = 1
        natureSightRing.run(.sequence([
            .group([.scale(to: 3.2, duration: 0.75), .fadeOut(withDuration: 1.15)]),
            .run { [weak self] in self?.isNatureSightActive = false }
        ]))
        if phase == .defeatSerrador {
            enemy?.run(.sequence([.colorize(with: .systemYellow, colorBlendFactor: 0.85, duration: 0.2), .wait(forDuration: 1.2), .colorize(withColorBlendFactor: 0, duration: 0.3)]))
            showToast("PONTO FRACO: O NÚCLEO DE METAL")
        } else if phase == .climbVines {
            vineGate.run(.sequence([.fadeAlpha(to: 1, duration: 0.25), .wait(forDuration: 1.5), .fadeAlpha(to: 0.55, duration: 0.4)]))
        }
    }

    // MARK: - Combat

    private func spawnSerrador() {
        let monster = makeSerrador()
        monster.position = CGPoint(x: 620, y: -40)
        monster.zPosition = depth(for: monster.position.y) + 10
        monster.alpha = 0
        monster.setScale(0.3)
        world.addChild(monster)
        monster.run(.group([.fadeIn(withDuration: 0.45), .scale(to: 1, duration: 0.45)]))
        enemy = monster
        enemyHealth = 100
        enemyHealthGroup.run(.fadeIn(withDuration: 0.3))
        showToast("UM SERRADOR BLOQUEIA O CORREDOR")
        updateEnemyHealth()
    }

    private func makeSerrador() -> SKNode {
        let root = SKNode()
        root.name = "serrador"

        let shadow = SKShapeNode(ellipseOf: CGSize(width: 150, height: 46))
        shadow.position.y = -62
        shadow.fillColor = NSColor(white: 0, alpha: 0.34)
        shadow.strokeColor = .clear
        root.addChild(shadow)

        let body = SKShapeNode(rectOf: CGSize(width: 105, height: 125), cornerRadius: 28)
        body.fillColor = NSColor(red: 0.27, green: 0.16, blue: 0.09, alpha: 1)
        body.strokeColor = NSColor(red: 0.70, green: 0.34, blue: 0.12, alpha: 1)
        body.lineWidth = 7
        root.addChild(body)

        let eye = SKShapeNode(circleOfRadius: 18)
        eye.position = CGPoint(x: 10, y: 30)
        eye.fillColor = .systemRed
        eye.strokeColor = .systemYellow
        eye.glowWidth = 12
        body.addChild(eye)

        let sawArm = SKNode()
        sawArm.position = CGPoint(x: -70, y: 0)
        sawArm.name = "sawArm"
        let handle = SKShapeNode(rectOf: CGSize(width: 90, height: 30), cornerRadius: 10)
        handle.fillColor = NSColor(red: 0.36, green: 0.35, blue: 0.32, alpha: 1)
        handle.strokeColor = .black
        sawArm.addChild(handle)
        let blade = SKShapeNode(circleOfRadius: 39)
        blade.position.x = -54
        blade.fillColor = NSColor(red: 0.64, green: 0.65, blue: 0.60, alpha: 1)
        blade.strokeColor = .white
        blade.lineWidth = 6
        blade.run(.repeatForever(.rotate(byAngle: .pi * 2, duration: 0.33)))
        sawArm.addChild(blade)
        root.addChild(sawArm)

        let smoke = SKLabelNode(text: "⌁")
        smoke.fontName = "AvenirNext-Bold"
        smoke.fontSize = 46
        smoke.fontColor = NSColor(white: 0.6, alpha: 0.55)
        smoke.position = CGPoint(x: 35, y: 75)
        smoke.run(.repeatForever(.sequence([.moveBy(x: 8, y: 20, duration: 0.7), .moveBy(x: -8, y: -20, duration: 0)])))
        root.addChild(smoke)
        return root
    }

    private func attack(damage: CGFloat, heavy: Bool) {
        guard phase == .defeatSerrador, currentTime >= attackReadyAt else { return }
        attackReadyAt = currentTime + (heavy ? 0.65 : 0.28)
        let slash = SKShapeNode(circleOfRadius: heavy ? 86 : 62)
        slash.fillColor = .clear
        slash.strokeColor = heavy ? .systemOrange : .white
        slash.lineWidth = heavy ? 14 : 8
        slash.glowWidth = 12
        slash.position = CGPoint(x: lastDirection.dx * 60, y: lastDirection.dy * 45)
        slash.zPosition = 50
        player.addChild(slash)
        slash.run(.sequence([.group([.scale(to: 1.45, duration: 0.16), .fadeOut(withDuration: 0.18)]), .removeFromParent()]))

        guard let enemy, distance(player.position, enemy.position) < (heavy ? 205 : 165) else { return }
        enemyHealth = max(0, enemyHealth - damage)
        enemy.run(.sequence([.colorize(with: .white, colorBlendFactor: 1, duration: 0.07), .colorize(withColorBlendFactor: 0, duration: 0.12)]))
        enemy.run(.moveBy(x: lastDirection.dx * (heavy ? 52 : 24), y: lastDirection.dy * (heavy ? 35 : 16), duration: 0.12))
        updateEnemyHealth()
        burst(at: enemy.position, color: .systemOrange)
        if enemyHealth <= 0 { defeatEnemy() }
    }

    private func dodge() {
        guard currentTime >= invulnerableUntil else { return }
        invulnerableUntil = currentTime + 0.5
        let dx = lastDirection.dx == 0 && lastDirection.dy == 0 ? 1 : lastDirection.dx
        player.run(.group([
            .moveBy(x: dx * 145, y: lastDirection.dy * 105, duration: 0.20),
            .sequence([.fadeAlpha(to: 0.32, duration: 0.08), .fadeIn(withDuration: 0.16)])
        ]))
    }

    private func updateEnemy(deltaTime: TimeInterval) {
        guard phase == .defeatSerrador, let enemy else { return }
        let dx = player.position.x - enemy.position.x
        let dy = player.position.y - enemy.position.y
        let d = max(1, hypot(dx, dy))
        if d > 105 {
            enemy.position.x += dx / d * 105 * CGFloat(deltaTime)
            enemy.position.y += dy / d * 78 * CGFloat(deltaTime)
        } else if currentTime >= enemyAttackReadyAt {
            enemyAttackReadyAt = currentTime + 1.15
            enemy.childNode(withName: "sawArm")?.run(.sequence([.rotate(toAngle: -0.8, duration: 0.16), .rotate(toAngle: 0.55, duration: 0.18), .rotate(toAngle: 0, duration: 0.15)]))
            if currentTime >= invulnerableUntil { damagePlayer(18) }
        }
    }

    private func damagePlayer(_ damage: CGFloat) {
        playerHealth = max(0, playerHealth - damage)
        player.run(.sequence([.colorize(with: .systemRed, colorBlendFactor: 0.9, duration: 0.08), .colorize(withColorBlendFactor: 0, duration: 0.2)]))
        updatePlayerHealth()
        if playerHealth <= 0 { resetCombat() }
    }

    private func resetCombat() {
        playerHealth = 100
        enemyHealth = 100
        player.position = CGPoint(x: 170, y: -100)
        enemy?.position = CGPoint(x: 620, y: -40)
        updatePlayerHealth()
        updateEnemyHealth()
        showToast("A MATA LHE DÁ OUTRA OPORTUNIDADE")
    }

    private func defeatEnemy() {
        guard let enemy else { return }
        enemy.run(.sequence([
            .group([.scale(to: 1.35, duration: 0.25), .fadeOut(withDuration: 0.45), .rotate(byAngle: 0.8, duration: 0.45)]),
            .removeFromParent()
        ]))
        self.enemy = nil
        enemyHealthGroup.run(.fadeOut(withDuration: 0.25))
        phase = .climbVines
        vineGate.run(.fadeAlpha(to: 0.65, duration: 0.5))
        showToast("SINTOMA CONTIDO • A CAUSA AINDA PERMANECE")
        updateHUD()
    }

    // MARK: - Restoration

    private func completeRestoration() {
        phase = .restored
        progression.restore(area: "corredor-da-mata", amount: 38)
        player.run(.sequence([
            .group([.moveTo(x: 1190, duration: 0.7), .moveTo(y: 340, duration: 0.7), .scale(to: 0.72, duration: 0.7)]),
            .wait(forDuration: 0.25),
            .group([.moveTo(x: 920, duration: 0.75), .moveTo(y: 210, duration: 0.75), .scale(to: 1, duration: 0.75)])
        ]))
        vineGate.run(.sequence([.fadeAlpha(to: 1, duration: 0.3), .colorize(with: .systemGreen, colorBlendFactor: 0.65, duration: 1.2)]))
        if let ground = world.childNode(withName: "ground") {
            ground.run(.colorize(with: NSColor(red: 0.08, green: 0.31, blue: 0.13, alpha: 1), colorBlendFactor: 1, duration: 2.2))
        }
        for (index, tree) in forestNodes.enumerated() {
            tree.run(.sequence([
                .wait(forDuration: Double(index) * 0.08),
                .group([.colorize(with: NSColor(red: 0.06, green: 0.48, blue: 0.16, alpha: 1), colorBlendFactor: 1, duration: 1.4), .scale(to: 1.12, duration: 1.4)])
            ]))
        }
        returningLife()
        showToast("CORREDOR RECONECTADO • RESTAURAÇÃO 50%")
        updateHUD()
    }

    private func returningLife() {
        for index in 0..<22 {
            let leaf = SKShapeNode(ellipseOf: CGSize(width: 12, height: 7))
            leaf.fillColor = index.isMultiple(of: 4) ? .systemYellow : .systemGreen
            leaf.strokeColor = .clear
            leaf.position = CGPoint(x: CGFloat((index * 101) % 1900) - 800, y: -480)
            leaf.zPosition = 2100
            world.addChild(leaf)
            leaf.run(.sequence([.wait(forDuration: Double(index) * 0.06), .group([.moveBy(x: CGFloat(index % 3 * 30), y: CGFloat(420 + index % 5 * 50), duration: 2), .rotate(byAngle: 4, duration: 2)])]))
        }
        let birds = SKLabelNode(fontNamed: "AvenirNext-Bold")
        birds.text = "⌁   ⌁    ⌁"
        birds.fontSize = 38
        birds.position = CGPoint(x: 1180, y: 480)
        birds.zPosition = 2200
        world.addChild(birds)
        birds.run(.moveTo(x: -1100, duration: 8))
    }

    // MARK: - Feedback

    private func updateHUD() {
        let event = PrototypeContent.events[phase]
        titleLabel.text = event?.title.uppercased()
        objectiveLabel.text = event?.objective
        formLabel.text = "FORMA: \(form.displayName.uppercased())"
        restorationLabel.text = "MATA ATLÂNTICA  \(12 + progression.restoration)%"
        updatePlayerHealth()
    }

    private func updatePlayerHealth() {
        healthFill.xScale = max(0.001, playerHealth / 100)
        healthFill.position.x = -110 + 110 * healthFill.xScale
        healthFill.fillColor = playerHealth > 35 ? .systemGreen : .systemRed
    }

    private func updateEnemyHealth() {
        enemyHealthFill.xScale = max(0.001, enemyHealth / 100)
        enemyHealthFill.position.x = -130 + 130 * enemyHealthFill.xScale
    }

    private func showToast(_ text: String) {
        toastLabel.removeAllActions()
        toastLabel.text = text
        toastLabel.alpha = 0
        toastLabel.setScale(0.82)
        toastLabel.run(.sequence([
            .group([.fadeIn(withDuration: 0.25), .scale(to: 1, duration: 0.25)]),
            .wait(forDuration: 2.0),
            .fadeOut(withDuration: 0.4)
        ]))
    }

    private func burst(at position: CGPoint, color: NSColor) {
        for index in 0..<10 {
            let particle = SKShapeNode(circleOfRadius: CGFloat(3 + index % 3))
            particle.fillColor = color
            particle.strokeColor = .clear
            particle.position = position
            particle.zPosition = 2300
            world.addChild(particle)
            let angle = CGFloat(index) / 10 * .pi * 2
            particle.run(.sequence([
                .group([.moveBy(x: cos(angle) * 90, y: sin(angle) * 90, duration: 0.45), .fadeOut(withDuration: 0.45)]),
                .removeFromParent()
            ]))
        }
    }

    private func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat { hypot(a.x - b.x, a.y - b.y) }
    private func depth(for y: CGFloat) -> CGFloat { 1000 - y }
}
