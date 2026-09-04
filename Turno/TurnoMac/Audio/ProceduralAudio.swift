//
//  ProceduralAudio.swift
//  TurnoMac
//
//  Som sem assets: zumbido quente do hotel, ruído do esfregar, batimento
//  cardíaco quando algo está errado e um "stinger" para o susto.
//

import AVFoundation

final class ProceduralAudio {
    private let engine = AVAudioEngine()
    private var node: AVAudioSourceNode?
    private var sampleRate: Double = 48000
    private var phase: Double = 0
    private var phase2: Double = 0
    private var noiseState: UInt32 = 12345
    private var ambientLevel: Float = 0
    private var ambientTarget: Float = 0
    private var scrubLevel: Float = 0
    private var heartPhase: Double = 0
    private var stingerT: Double = -1
    private var lowpass: Float = 0

    /// 0...1, definido pelo GameLoop a cada frame.
    var scrub: Float = 0
    var heartbeat = false

    init() {
        let format = engine.outputNode.outputFormat(forBus: 0)
        sampleRate = format.sampleRate
        let src = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self else { return noErr }
            let abl = UnsafeMutableAudioBufferListPointer(audioBufferList)
            for frame in 0..<Int(frameCount) {
                let s = self.sample()
                for buf in abl {
                    let p = buf.mData!.assumingMemoryBound(to: Float.self)
                    p[frame] = s
                }
            }
            return noErr
        }
        node = src
        engine.attach(src)
        let mono = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)
        engine.connect(src, to: engine.mainMixerNode, format: mono)
        engine.mainMixerNode.outputVolume = 0.5
        do { try engine.start() } catch { print("Audio: \(error)") }
    }

    func setAmbient(_ on: Bool) { ambientTarget = on ? 1 : 0 }

    func stinger() { stingerT = 0 }

    private func noise() -> Float {
        noiseState = noiseState &* 1664525 &+ 1013904223
        return Float(noiseState >> 8) / Float(1 << 24) * 2 - 1
    }

    private func sample() -> Float {
        let dt = 1.0 / sampleRate
        ambientLevel += (ambientTarget - ambientLevel) * 0.00002
        scrubLevel += (scrub - scrubLevel) * 0.0008

        // zumbido do prédio: 55 Hz + harmônico + ar-condicionado (ruído filtrado)
        phase += 55 * dt; if phase > 1 { phase -= 1 }
        phase2 += 110.3 * dt; if phase2 > 1 { phase2 -= 1 }
        let hum = Float(sin(phase * 2 * .pi)) * 0.12 + Float(sin(phase2 * 2 * .pi)) * 0.05
        lowpass += (noise() - lowpass) * 0.02
        let air = lowpass * 0.35
        var out = (hum + air) * ambientLevel * 0.35

        // esfregar: ruído com brilho proporcional à velocidade
        if scrubLevel > 0.001 {
            let n = noise()
            out += n * scrubLevel * 0.28
        }

        // batimento: dois pulsos surdos por segundo
        if heartbeat {
            heartPhase += dt * 1.3
            if heartPhase > 1 { heartPhase -= 1 }
            let beat = pulse(heartPhase, at: 0.0) + pulse(heartPhase, at: 0.22) * 0.7
            out += beat * 0.5
        } else {
            heartPhase = 0
        }

        // stinger: nota grave descendo com ruído, ~1.2 s
        if stingerT >= 0 {
            stingerT += dt
            let t = stingerT
            let f = 180.0 - t * 90
            let env = Float(max(0, 1 - t / 1.2))
            out += Float(sin(t * f * 2 * .pi)) * env * 0.5 + noise() * env * env * 0.15
            if t > 1.3 { stingerT = -1 }
        }
        return max(-1, min(1, out))
    }

    private func pulse(_ p: Double, at t0: Double) -> Float {
        let d = p - t0
        guard d >= 0 && d < 0.12 else { return 0 }
        let env = Float(1 - d / 0.12)
        return Float(sin(d * 48 * 2 * .pi)) * env * env
    }
}
