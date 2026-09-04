//
//  MotionService.swift
//  TurnoControle
//
//  CoreMotion a 60 Hz: attitude (quaternion) e rotationRate.
//

import Foundation
import CoreMotion

final class MotionService {
    private let manager = CMMotionManager()
    private(set) var quaternion: [Float] = []
    private(set) var rotationRate: [Float] = [0, 0, 0]
    var available: Bool { manager.isDeviceMotionAvailable }

    func start() {
        guard manager.isDeviceMotionAvailable else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 60.0
        manager.startDeviceMotionUpdates(using: .xArbitraryCorrectedZVertical, to: .main) { [weak self] dm, _ in
            guard let self, let dm else { return }
            let q = dm.attitude.quaternion
            self.quaternion = [Float(q.x), Float(q.y), Float(q.z), Float(q.w)]
            let r = dm.rotationRate
            self.rotationRate = [Float(r.x), Float(r.y), Float(r.z)]
        }
    }

    func stop() { manager.stopDeviceMotionUpdates() }
}
