//
//  ControllerServer.swift
//  TurnoMac
//
//  Recebe o iPhone (app Turno Controle) por UDP + Bonjour e alimenta o InputState.
//  Manda de volta FeedbackPacket (estado, mensagens, háptica).
//

import Foundation
import Network
import simd

final class ControllerServer {
    private let input: InputState
    private var listener: NWListener?
    private let queue = DispatchQueue(label: "turno.controller")
    private var connection: NWConnection?
    private var lastSeq: UInt32 = 0
    private var lastAct: UInt16 = 0, lastBack: UInt16 = 0, lastRecal: UInt16 = 0
    private var lastPacketTime: TimeInterval = 0
    private var timeoutTimer: Timer?

    var onConnected: ((String) -> Void)?
    var onDisconnected: (() -> Void)?
    private(set) var peerName: String = ""

    init(input: InputState) {
        self.input = input
    }

    func start() {
        do {
            let params = NWParameters.udp
            params.allowLocalEndpointReuse = true
            let l = try NWListener(using: params, on: NWEndpoint.Port(rawValue: TurnoNet.port)!)
            l.service = NWListener.Service(name: "Turno · \(Host.current().localizedName ?? "Mac")", type: TurnoNet.bonjourType)
            l.stateUpdateHandler = { state in
                print("ControllerServer:", state)
            }
            l.newConnectionHandler = { [weak self] conn in
                self?.accept(conn)
            }
            l.start(queue: queue)
            listener = l
        } catch {
            print("ControllerServer: não conseguiu abrir a porta: \(error)")
        }
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self, self.connection != nil else { return }
            if Date().timeIntervalSince1970 - self.lastPacketTime > 4 {
                self.dropConnection()
            }
        }
    }

    private func accept(_ conn: NWConnection) {
        connection?.cancel()
        connection = conn
        lastSeq = 0
        conn.stateUpdateHandler = { [weak self] state in
            if case .failed = state { self?.dropConnection() }
            if case .cancelled = state { self?.dropConnection() }
        }
        conn.start(queue: queue)
        receive(on: conn)
    }

    private func dropConnection() {
        DispatchQueue.main.async {
            guard self.connection != nil else { return }
            self.connection?.cancel()
            self.connection = nil
            self.peerName = ""
            self.input.hasPhoneAttitude = false
            self.input.source = .keyboard
            self.input.moveX = 0; self.input.moveY = 0; self.input.use = false
            self.onDisconnected?()
        }
    }

    private func receive(on conn: NWConnection) {
        conn.receiveMessage { [weak self] data, _, _, error in
            guard let self else { return }
            if let data, let packet = try? JSONDecoder().decode(ControllerPacket.self, from: data) {
                DispatchQueue.main.async { self.apply(packet) }
            }
            if error == nil, self.connection === conn {
                self.receive(on: conn)
            }
        }
    }

    private func apply(_ p: ControllerPacket) {
        lastPacketTime = Date().timeIntervalSince1970
        if p.hello || peerName.isEmpty {
            let name = p.name.isEmpty ? "iPhone" : p.name
            if peerName != name {
                peerName = name
                lastAct = p.actCount; lastBack = p.backCount; lastRecal = p.recalCount
                onConnected?(name)
                send(.welcome("Conectado ao \(Host.current().localizedName ?? "Mac")"))
            }
            if p.hello { return }
        }
        if p.seq < lastSeq && lastSeq - p.seq < 1000 { return } // pacote atrasado
        lastSeq = p.seq

        input.source = .phone
        input.moveX = p.jx
        input.moveY = p.jy
        input.use = p.use
        input.phoneEffort = simd_length(SIMD3(p.rot.count == 3 ? p.rot[0] : 0, p.rot.count == 3 ? p.rot[1] : 0, p.rot.count == 3 ? p.rot[2] : 0))

        if p.q.count == 4 {
            let q = simd_quatf(ix: p.q[0], iy: p.q[1], iz: p.q[2], r: p.q[3])
            // Vetor "topo do celular" no referencial do CoreMotion (Z para cima).
            let f = q.act(SIMD3<Float>(0, 1, 0))
            input.phoneYaw = atan2(f.x, f.y)          // direita = positivo
            input.phonePitch = asin(max(-1, min(1, f.z)))
            input.hasPhoneAttitude = true
        } else {
            input.hasPhoneAttitude = false
        }

        if p.actCount != lastAct { input.actPressed = true; lastAct = p.actCount }
        if p.backCount != lastBack { input.backPressed = true; lastBack = p.backCount }
        if p.recalCount != lastRecal { input.recalPressed = true; lastRecal = p.recalCount }
    }

    func send(_ packet: FeedbackPacket) {
        guard let conn = connection, let data = try? JSONEncoder().encode(packet) else { return }
        conn.send(content: data, completion: .contentProcessed { _ in })
    }
}
