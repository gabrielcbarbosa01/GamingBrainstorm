import SwiftUI
import SceneKit
import QuartzCore

struct GameView: NSViewRepresentable {
    let controller: GameController

    func makeNSView(context: Context) -> GameSCNView {
        Debug.mark("make-view")
        let view = GameSCNView(frame: NSRect(x: 0, y: 0, width: 1440, height: 860), options: nil)
        view.controller = controller
        view.scene = controller.presenter.scene
        view.pointOfView = controller.presenter.cameraNode
        view.backgroundColor = .black
        view.antialiasingMode = .multisampling2X
        view.isPlaying = true
        view.rendersContinuously = true
        view.allowsCameraControl = false
        view.autoenablesDefaultLighting = false
        return view
    }

    func updateNSView(_ nsView: GameSCNView, context: Context) {}
}

/// Captura teclado e mouse e roda o passo fixo pelo CADisplayLink da tela.
final class GameSCNView: SCNView {

    weak var controller: GameController?
    private var link: CADisplayLink?
    private var mouseCaptured = false
    private var snapshotTimer: Timer?

    override var acceptsFirstResponder: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        Debug.log("viewDidMoveToWindow window=\(window != nil) bounds=\(bounds)")
        guard let window else {
            link?.invalidate()
            link = nil
            setMouseCaptured(false)
            return
        }
        window.acceptsMouseMovedEvents = true
        window.makeFirstResponder(self)
        window.title = "Protocolo Bovino — clique na janela para capturar o mouse"
        if link == nil {
            let l = displayLink(target: self, selector: #selector(onFrame(_:)))
            l.add(to: .main, forMode: .common)
            link = l
        }
        scheduleSnapshotIfNeeded()
    }

    @objc private func onFrame(_ sender: CADisplayLink) {
        MainActor.assumeIsolated {
            controller?.tick(now: CACurrentMediaTime())
        }
    }

    // MARK: Mouse
    private func setMouseCaptured(_ on: Bool) {
        guard mouseCaptured != on else { return }
        mouseCaptured = on
        MainActor.assumeIsolated { controller?.setMouseCaptured(on) }
        if on {
            CGAssociateMouseAndMouseCursorPosition(0)
            NSCursor.hide()
        } else {
            CGAssociateMouseAndMouseCursorPosition(1)
            NSCursor.unhide()
            window?.title = "Protocolo Bovino — clique na janela para capturar o mouse"
        }
    }

    override func mouseDown(with event: NSEvent) {
        guard !CommandLine.arguments.contains("--snapshot") else { return }
        setMouseCaptured(true)
        window?.title = "Protocolo Bovino — ESC solta o mouse"
    }
    override func scrollWheel(with event: NSEvent) {
        MainActor.assumeIsolated { controller?.zoom(by: Float(event.scrollingDeltaY)) }
    }

    override func mouseMoved(with event: NSEvent) { forwardLook(event) }
    override func mouseDragged(with event: NSEvent) { forwardLook(event) }
    override func rightMouseDragged(with event: NSEvent) { forwardLook(event) }

    private func forwardLook(_ event: NSEvent) {
        guard mouseCaptured else { return }
        MainActor.assumeIsolated {
            controller?.look(dx: Float(event.deltaX), dy: Float(event.deltaY))
        }
    }

    // MARK: Teclado
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {                    // Esc solta o mouse
            setMouseCaptured(false)
            return
        }
        MainActor.assumeIsolated {
            controller?.keyDown(event.keyCode, isRepeat: event.isARepeat)
        }
    }

    override func keyUp(with event: NSEvent) {
        MainActor.assumeIsolated { controller?.keyUp(event.keyCode) }
    }

    override func flagsChanged(with event: NSEvent) {
        MainActor.assumeIsolated {
            controller?.setSprint(event.modifierFlags.contains(.shift))
        }
    }

    override func resignFirstResponder() -> Bool {
        MainActor.assumeIsolated { controller?.releaseAllKeys() }
        setMouseCaptured(false)
        return super.resignFirstResponder()
    }

    // MARK: Modo captura de tela — verificacao visual sem depender da janela estar visivel.
    // `snapshot()` renderiza fora da tela, entao nao precisa de foco nem de display link.
    private func scheduleSnapshotIfNeeded() {
        let args = CommandLine.arguments
        guard let i = args.firstIndex(of: "--snapshot"), i + 1 < args.count else { return }
        let path = args[i + 1]
        guard snapshotTimer == nil else { return }
        Debug.mark("snapshot-scheduled")
        snapshotTimer = Timer.scheduledTimer(withTimeInterval: 1.2, repeats: false) { [weak self] _ in
            guard let self else { return }
            Debug.log("timer fired, bounds=\(self.bounds)")
            MainActor.assumeIsolated {
                // Avanca 2 s de simulacao com passo sintetico: determinista.
                var t = CACurrentMediaTime()
                for _ in 0..<120 {
                    t += 1.0 / 60.0
                    self.controller?.tick(now: t)
                }
            }
            let image = self.snapshot()
            Debug.log("snapshot size=\(image.size)")
            if let tiff = image.tiffRepresentation,
               let rep = NSBitmapImageRep(data: tiff),
               let png = rep.representation(using: .png, properties: [:]) {
                do {
                    try png.write(to: URL(fileURLWithPath: path))
                    FileHandle.standardError.write("[snapshot] escrito em \(path)\n".data(using: .utf8)!)
                } catch {
                    FileHandle.standardError.write("[snapshot] falhou: \(error)\n".data(using: .utf8)!)
                }
            } else {
                FileHandle.standardError.write("[snapshot] sem imagem\n".data(using: .utf8)!)
            }
            exit(0)
        }
    }
}
