//
//  ControllerClient.swift
//  TurnoControle
//
//  Descobre o Mac por Bonjour (_turno._udp), manda ControllerPacket a 60 Hz
//  e recebe FeedbackPacket (estado, mensagens, provas, háptica).
//

import Foundation
import Network
import Observation
import UIKit

@Observable
final class ControllerClient {
    struct Host: Identifiable, Hashable {
        let id: String
        let name: String
        let endpoint: NWEndpoint
        static func == (a: Host, b: Host) -> Bool { a.id == b.id }
        func hash(into h: inout Hasher) { h.combine(id) }
    }

    var hosts: [Host] = []
    var connectedTo: String? = nil
    var status: String = "Procurando o jogo na rede..."
    var state = ControllerState()
    var messages: [ChatMessage] = []
    var evidence: [EvidenceCard] = []
    var unreadMessages = 0
    var lastHaptic: HapticKind? = nil

    // entrada atual (escrita pela UI)
    var joystick = SIMD2<Float>(0, 0)
    var usePressed = false
    private var actCount: UInt16 = 0
    private var backCount: UInt16 = 0
    private var recalCount: UInt16 = 0

    let motion = MotionService()
    private var browser: NWBrowser?
    private var connection: NWConnection?
    private let queue = DispatchQueue(label: "turno.client")
    private var timer: Timer?
    private var seq: UInt32 = 0
    private var heartbeatTimer: Timer?
    private let impact = UIImpactFeedbackGenerator(style: .medium)
    private let heavy = UIImpactFeedbackGenerator(style: .heavy)
    private let notify = UINotificationFeedbackGenerator()

    func start() {
        motion.start()
        // Atalho de teste (simulador): SIMCTL_CHILD_TURNO_HOST=127.0.0.1
        if let host = ProcessInfo.processInfo.environment["TURNO_HOST"], !host.isEmpty {
            connectManually(host: host)
        }
        let b = NWBrowser(for: .bonjour(type: TurnoNet.bonjourType, domain: nil), using: .udp)
        b.browseResultsChangedHandler = { [weak self] results, _ in
            let found: [Host] = results.compactMap { r in
                if case .service(let name, _, _, _) = r.endpoint {
                    return Host(id: name, name: name, endpoint: r.endpoint)
                }
                return nil
            }
            DispatchQueue.main.async {
                self?.hosts = found
                if let self, self.connection == nil, let first = found.first {
                    self.connect(to: first)
                }
            }
        }
        b.start(queue: queue)
        browser = b
    }

    func connect(to host: Host) {
        connection?.cancel()
        let conn = NWConnection(to: host.endpoint, using: .udp)
        conn.stateUpdateHandler = { [weak self] st in
            DispatchQueue.main.async {
                switch st {
                case .ready:
                    self?.status = "Conectado a \(host.name)"
                    self?.connectedTo = host.name
                    self?.sendHello()
                    self?.startSending()
                case .failed(let e):
                    self?.status = "Falhou: \(e.localizedDescription)"
                    self?.connectedTo = nil
                case .waiting(let e):
                    self?.status = "Aguardando rede: \(e.localizedDescription)"
                default: break
                }
            }
        }
        conn.start(queue: queue)
        connection = conn
        receive(on: conn)
    }

    func connectManually(host: String) {
        let h = Host(id: host, name: host, endpoint: .hostPort(host: NWEndpoint.Host(host), port: NWEndpoint.Port(rawValue: TurnoNet.port)!))
        connect(to: h)
    }

    private func receive(on conn: NWConnection) {
        conn.receiveMessage { [weak self] data, _, _, error in
            guard let self else { return }
            if let data, let fb = try? JSONDecoder().decode(FeedbackPacket.self, from: data) {
                DispatchQueue.main.async { self.apply(fb) }
            }
            if error == nil { self.receive(on: conn) }
        }
    }

    private func apply(_ fb: FeedbackPacket) {
        switch fb {
        case .state(let s):
            let wasHeart = state.managerNear
            state = s
            if s.managerNear && !wasHeart { heavy.impactOccurred(intensity: 0.6) }
        case .haptic(let h):
            lastHaptic = h
            switch h {
            case .tick: impact.impactOccurred(intensity: 0.5)
            case .stroke: impact.impactOccurred(intensity: 0.8)
            case .success: notify.notificationOccurred(.success)
            case .heartbeat: heavy.impactOccurred(intensity: 0.7)
            case .alarm: notify.notificationOccurred(.error)
            case .shock:
                heavy.impactOccurred(intensity: 1.0)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { self.heavy.impactOccurred(intensity: 1.0) }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { self.notify.notificationOccurred(.error) }
            }
        case .message(let m):
            if !messages.contains(m) {
                messages.append(m)
                unreadMessages += 1
                impact.impactOccurred(intensity: 0.6)
            }
        case .evidence(let e):
            if !evidence.contains(e) {
                evidence.append(e)
                notify.notificationOccurred(.success)
            }
        case .welcome(let text):
            status = text
        }
    }

    private func sendHello() {
        var p = ControllerPacket()
        p.hello = true
        p.name = UIDevice.current.name
        send(p)
    }

    private func startSending() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        heartbeatTimer?.invalidate()
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.sendHello()
        }
    }

    private func tick() {
        seq &+= 1
        var p = ControllerPacket()
        p.seq = seq
        p.q = motion.quaternion
        p.rot = motion.rotationRate
        p.jx = joystick.x
        p.jy = joystick.y
        p.use = usePressed
        p.actCount = actCount
        p.backCount = backCount
        p.recalCount = recalCount
        p.name = UIDevice.current.name
        send(p)
    }

    private func send(_ p: ControllerPacket) {
        guard let conn = connection, let data = try? JSONEncoder().encode(p) else { return }
        conn.send(content: data, completion: .contentProcessed { _ in })
    }

    func act() { actCount &+= 1; impact.impactOccurred(intensity: 0.4) }
    func back() { backCount &+= 1; impact.impactOccurred(intensity: 0.3) }
    func recalibrate() { recalCount &+= 1; notify.notificationOccurred(.warning) }
}
