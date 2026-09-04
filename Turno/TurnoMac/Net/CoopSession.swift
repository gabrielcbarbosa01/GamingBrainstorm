//
//  CoopSession.swift
//  TurnoMac
//
//  Co-op entre Macs na mesma rede via MultipeerConnectivity (sem servidor).
//  Mesmo padrão do protótipo anterior do repositório: isolado atrás desta
//  classe para poder trocar por GameKit (internet) depois.
//

import Foundation
import MultipeerConnectivity

enum CoopMessage: Codable {
    case pose(x: Float, y: Float, z: Float, yaw: Float, role: Role)
    case clean(surface: Int, u0: Float, v0: Float, u1: Float, v1: Float, amount: Float)
    case evidence(String)
    case task(String, Float)
    case manager(t: Float, dir: Float, area: String)
    case startNight(Int)
}

final class CoopSession: NSObject {
    static let serviceType = "turno-coop"

    private let myPeerID = MCPeerID(displayName: Host.current().localizedName ?? "Mac")
    private lazy var session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .none)
    private lazy var advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: Self.serviceType)
    private lazy var browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: Self.serviceType)

    private(set) var peers: [MCPeerID] = []
    var onPeersChanged: ((Int) -> Void)?
    var onMessage: ((String, CoopMessage) -> Void)?
    var onPeerLost: ((String) -> Void)?

    /// Host = menor nome em ordem alfabética entre os conectados (determinístico).
    var isHost: Bool {
        let all = ([myPeerID] + peers).map(\.displayName).sorted()
        return all.first == myPeerID.displayName
    }

    func start() {
        session.delegate = self
        advertiser.delegate = self
        browser.delegate = self
        advertiser.startAdvertisingPeer()
        browser.startBrowsingForPeers()
    }

    func stop() {
        advertiser.stopAdvertisingPeer()
        browser.stopBrowsingForPeers()
        session.disconnect()
    }

    func send(_ message: CoopMessage, reliable: Bool = true) {
        guard !session.connectedPeers.isEmpty, let data = try? JSONEncoder().encode(message) else { return }
        try? session.send(data, toPeers: session.connectedPeers, with: reliable ? .reliable : .unreliable)
    }
}

extension CoopSession: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            self.peers = session.connectedPeers
            if state == .notConnected { self.onPeerLost?(peerID.displayName) }
            self.onPeersChanged?(self.peers.count)
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        guard let m = try? JSONDecoder().decode(CoopMessage.self, from: data) else { return }
        DispatchQueue.main.async { self.onMessage?(peerID.displayName, m) }
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

extension CoopSession: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, session)
    }
}

extension CoopSession: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        // Só um lado convida, para evitar convites cruzados.
        if myPeerID.displayName < peerID.displayName {
            browser.invitePeer(peerID, to: session, withContext: nil, timeout: 15)
        }
    }
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}
}
