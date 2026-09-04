//
//  SoundManager.swift
//  GamingBrainstorm
//
//  Created by Gabriel Barbosa on 25/08/26.
//

import Foundation
import AVFoundation

public enum FootstepSurface {
    case grass
    case water
    case gravel
    case pampaGrass
}

public final class SoundManager: @unchecked Sendable {
    public static let shared = SoundManager()
    
    // Audio Engine & Nodes
    private let engine = AVAudioEngine()
    private let sfxPlayerNode = AVAudioPlayerNode()
    private let footstepPlayerNode = AVAudioPlayerNode()
    private let riverPlayerNode = AVAudioPlayerNode()
    private let windPlayerNode = AVAudioPlayerNode()
    private let musicPlayerNode = AVAudioPlayerNode()
    
    // Audio Format: Standard 44.1kHz Stereo Float
    private let sampleRate: Double = 44100.0
    private let audioFormat: AVAudioFormat
    
    // Pre-synthesized PCM Buffers
    private var grassStepBuffers: [AVAudioPCMBuffer] = []
    private var waterStepBuffers: [AVAudioPCMBuffer] = []
    private var gravelStepBuffers: [AVAudioPCMBuffer] = []
    private var pampaStepBuffers: [AVAudioPCMBuffer] = []
    
    private var riverAmbienceBuffer: AVAudioPCMBuffer?
    private var windAmbienceBuffer: AVAudioPCMBuffer?
    private var metamorphosisBuffer: AVAudioPCMBuffer?
    private var rescueFanfareBuffer: AVAudioPCMBuffer?
    private var uiClickBuffer: AVAudioPCMBuffer?
    private var droneAlarmBuffer: AVAudioPCMBuffer?
    private var poacherWhistleBuffer: AVAudioPCMBuffer?
    private var fireCrackleBuffer: AVAudioPCMBuffer?
    private var dialogueBeepBuffer: AVAudioPCMBuffer?
    private var totemPurifiedBuffer: AVAudioPCMBuffer?
    private var chainsawBuffer: AVAudioPCMBuffer?
    private var netCutBuffer: AVAudioPCMBuffer?
    private var timerTickBuffer: AVAudioPCMBuffer?
    private var portalTeleportBuffer: AVAudioPCMBuffer?
    private var ambientMusicBuffers: [BiomeType: AVAudioPCMBuffer] = [:]
    
    // Volume & State Settings
    public var isMuted: Bool = false {
        didSet {
            updateMasterVolume()
        }
    }
    public var sfxVolume: Float = 0.85
    public var footstepVolume: Float = 0.22
    public var ambienceVolume: Float = 0.60
    public var musicVolume: Float = 0.45
    
    private var currentPlayingMusicBiome: BiomeType?
    private var lastFootstepTime: TimeInterval = 0.0
    private var lastEnemyAlarmTime: TimeInterval = 0.0
    private var stepAlternator: Bool = false
    private var isEngineRunning: Bool = false
    
    private init() {
        guard let format = AVAudioFormat(standardFormatWithSampleRate: 44100.0, channels: 2) else {
            fatalError("Could not create AVAudioFormat")
        }
        self.audioFormat = format
        
        setupAudioEngine()
        synthesizeAllBuffers()
        startAmbientLoops()
    }
    
    // MARK: - Audio Engine Setup
    private func setupAudioEngine() {
        engine.attach(sfxPlayerNode)
        engine.attach(footstepPlayerNode)
        engine.attach(riverPlayerNode)
        engine.attach(windPlayerNode)
        engine.attach(musicPlayerNode)
        
        engine.connect(sfxPlayerNode, to: engine.mainMixerNode, format: audioFormat)
        engine.connect(footstepPlayerNode, to: engine.mainMixerNode, format: audioFormat)
        engine.connect(riverPlayerNode, to: engine.mainMixerNode, format: audioFormat)
        engine.connect(windPlayerNode, to: engine.mainMixerNode, format: audioFormat)
        engine.connect(musicPlayerNode, to: engine.mainMixerNode, format: audioFormat)
        
        do {
            try engine.start()
            sfxPlayerNode.play()
            footstepPlayerNode.play()
            riverPlayerNode.play()
            windPlayerNode.play()
            musicPlayerNode.play()
            isEngineRunning = true
        } catch {
            print("⚠️ [SoundManager] Could not start AVAudioEngine (possibly headless environment): \(error)")
        }
    }
    
    private func updateMasterVolume() {
        if isMuted {
            engine.mainMixerNode.outputVolume = 0.0
        } else {
            engine.mainMixerNode.outputVolume = 1.0
        }
    }
    
    // MARK: - Procedural Sound Synthesis
    private func synthesizeAllBuffers() {
        // 1. Synthesize 4 Variations of Grass/Foliage Footsteps
        for i in 0..<4 {
            let buf = createFootstepBuffer(surface: .grass, variation: i)
            grassStepBuffers.append(buf)
        }
        
        // 2. Synthesize 4 Variations of Water Splashes
        for i in 0..<4 {
            let buf = createFootstepBuffer(surface: .water, variation: i)
            waterStepBuffers.append(buf)
        }
        
        // 3. Synthesize 4 Variations of Gravel/Dry Earth Steps
        for i in 0..<4 {
            let buf = createFootstepBuffer(surface: .gravel, variation: i)
            gravelStepBuffers.append(buf)
        }
        
        // 4. Synthesize 4 Variations of Pampa Prairie Steps
        for i in 0..<4 {
            let buf = createFootstepBuffer(surface: .pampaGrass, variation: i)
            pampaStepBuffers.append(buf)
        }
        
        // 5. River Flow Ambient Loop (4 seconds seamless buffer)
        riverAmbienceBuffer = createRiverAmbienceBuffer(durationSeconds: 4.0)
        
        // 6. Wind Ambient Loop (5 seconds seamless buffer)
        windAmbienceBuffer = createWindAmbienceBuffer(durationSeconds: 5.0)
        
        // 7. Metamorphosis Shimmer Chime
        metamorphosisBuffer = createMetamorphosisBuffer()
        
        // 8. Rescue Victory Fanfare
        rescueFanfareBuffer = createRescueFanfareBuffer()
        
        // 9. UI Click
        uiClickBuffer = createUIClickBuffer()
        
        // 10. Narrative & Enemy Sounds
        droneAlarmBuffer = createDroneAlarmBuffer()
        poacherWhistleBuffer = createPoacherWhistleBuffer()
        fireCrackleBuffer = createFireCrackleBuffer()
        dialogueBeepBuffer = createDialogueBeepBuffer()
        totemPurifiedBuffer = createTotemPurifiedBuffer()
        chainsawBuffer = createChainsawBuffer()
        netCutBuffer = createNetCutBuffer()
        timerTickBuffer = createTimerTickBuffer()
        portalTeleportBuffer = createPortalTeleportBuffer()
        
        // 11. Procedural Ambient Musical Tracks for All 6 Biomes
        for biome in BiomeType.allCases {
            if let buf = createBiomeMusicBuffer(for: biome) {
                ambientMusicBuffers[biome] = buf
            }
        }
    }
    
    // MARK: - Procedural Ambient Music Soundscape Synthesis
    private func createBiomeMusicBuffer(for biome: BiomeType) -> AVAudioPCMBuffer? {
        let duration: Double = 6.0
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount),
              let left = buffer.floatChannelData?[0],
              let right = buffer.floatChannelData?[1] else {
            return nil
        }
        buffer.frameLength = frameCount
        
        let chords: [Double]
        switch biome {
        case .amazonia: chords = [220.0, 329.63, 440.0, 523.25, 659.25] // A minor pentatonic (Flute & Marimba)
        case .caatinga: chords = [146.83, 220.0, 293.66, 369.99] // D major open strings (Viola sertaneja)
        case .pantanal: chords = [164.81, 246.94, 329.63, 392.0, 493.88] // E minor (Aquatic flow)
        case .cerrado: chords = [196.0, 293.66, 392.0, 493.88] // G major warm chords (Seresta)
        case .mataAtlantica: chords = [261.63, 329.63, 392.0, 493.88, 587.33] // C major 9th (Lush canopy)
        case .pampa: chords = [146.83, 220.0, 293.66, 440.0] // D open horizon (Vento Pampeano)
        }
        
        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / sampleRate
            let masterEnv = sin(Double.pi * (time / duration)) // Seamless loop swell
            var sampleL: Float = 0.0
            var sampleR: Float = 0.0
            
            for (idx, freq) in chords.enumerated() {
                let phase = time * freq * 2.0 * .pi
                let arpeggioOffset = Double(idx) * 1.2
                let noteTime = (time + arpeggioOffset).truncatingRemainder(dividingBy: 3.0)
                let noteEnv = exp(-noteTime * 1.8) * (1.0 - exp(-noteTime * 20.0))
                
                let harmonic = sin(phase) + 0.3 * sin(phase * 2.0) + 0.1 * sin(phase * 3.0)
                let noteSample = Float(harmonic * noteEnv * 0.16)
                
                // Stereo panning
                let pan = Float(idx % 2 == 0 ? 0.35 : -0.35)
                sampleL += noteSample * (1.0 - pan)
                sampleR += noteSample * (1.0 + pan)
            }
            
            left[frame] = sampleL * Float(masterEnv) * 0.40
            right[frame] = sampleR * Float(masterEnv) * 0.40
        }
        return buffer
    }
    // MARK: - Soft Organic Footstep Sound Generation
    private func createFootstepBuffer(surface: FootstepSurface, variation: Int) -> AVAudioPCMBuffer {
        let duration: Double = (surface == .water) ? 0.09 : 0.065
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount) else {
            return AVAudioPCMBuffer()
        }
        buffer.frameLength = frameCount
        
        guard let leftChannel = buffer.floatChannelData?[0],
              let rightChannel = buffer.floatChannelData?[1] else {
            return buffer
        }
        
        let pitchMod = 1.0 + Double(variation) * 0.04 - 0.06
        var noiseState: Float = 0.0
        
        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / sampleRate
            let normalizedTime = time / duration
            
            // Ultra-smooth Hann/raised envelope (No harsh click on attack or tail)
            let attack = min(1.0, time / 0.012)
            let decay = exp(-normalizedTime * 9.0)
            let envelope = attack * decay
            
            let rawNoise = Float.random(in: -1.0...1.0)
            // Low-pass filter noise for warm, soft muffled texture
            noiseState = (noiseState * 0.75) + (rawNoise * 0.25)
            
            var sample: Float = 0.0
            
            switch surface {
            case .grass:
                // Soft leafy cushion rustle with gentle 65Hz body thump
                let body = Float(sin(2.0 * .pi * 65.0 * pitchMod * time)) * 0.18
                sample = (noiseState * 0.22 + body) * Float(envelope)
                
            case .water:
                // Gentle liquid droplet trickle
                let splashFreq = (320.0 - normalizedTime * 160.0) * pitchMod
                let bubble = Float(sin(2.0 * .pi * splashFreq * time)) * 0.22
                sample = (bubble + noiseState * 0.12) * Float(envelope)
                
            case .gravel:
                // Muffled sandy gravel patter
                let thud = Float(sin(2.0 * .pi * 85.0 * pitchMod * time)) * 0.15
                sample = (noiseState * 0.26 + thud) * Float(envelope)
                
            case .pampaGrass:
                // Gentle whisper of prairie grass
                sample = noiseState * 0.18 * Float(envelope)
            }
            
            // Subtle stereo spatialization
            leftChannel[frame] = sample * 0.95
            rightChannel[frame] = sample * 1.05
        }
        
        return buffer
    }
    
    // MARK: - River Flow Synthesis
    private func createRiverAmbienceBuffer(durationSeconds: Double) -> AVAudioPCMBuffer {
        let frameCount = AVAudioFrameCount(durationSeconds * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount),
              let left = buffer.floatChannelData?[0],
              let right = buffer.floatChannelData?[1] else {
            return AVAudioPCMBuffer()
        }
        buffer.frameLength = frameCount
        
        var pinkState1: Float = 0.0
        var pinkState2: Float = 0.0
        
        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / sampleRate
            
            // Continuous filtered water surge
            let white1 = Float.random(in: -1.0...1.0)
            let white2 = Float.random(in: -1.0...1.0)
            pinkState1 = pinkState1 * 0.92 + white1 * 0.08
            pinkState2 = pinkState2 * 0.92 + white2 * 0.08
            
            // Water current surge wave
            let waveMod = Float(0.75 + 0.25 * sin(2.0 * .pi * 0.45 * time))
            
            left[frame] = pinkState1 * waveMod * 0.35
            right[frame] = pinkState2 * waveMod * 0.35
        }
        return buffer
    }
    
    // MARK: - Wind Ambience Synthesis
    private func createWindAmbienceBuffer(durationSeconds: Double) -> AVAudioPCMBuffer {
        let frameCount = AVAudioFrameCount(durationSeconds * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount),
              let left = buffer.floatChannelData?[0],
              let right = buffer.floatChannelData?[1] else {
            return AVAudioPCMBuffer()
        }
        buffer.frameLength = frameCount
        
        var lowPass: Float = 0.0
        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / sampleRate
            let white = Float.random(in: -1.0...1.0)
            lowPass = lowPass * 0.98 + white * 0.02
            
            let breeze = Float(0.5 + 0.5 * sin(2.0 * .pi * 0.2 * time))
            let sample = lowPass * breeze * 0.4
            left[frame] = sample
            right[frame] = sample
        }
        return buffer
    }
    
    // MARK: - Metamorphosis Shimmer Chime Synthesis
    private func createMetamorphosisBuffer() -> AVAudioPCMBuffer {
        let duration: Double = 0.75
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount),
              let left = buffer.floatChannelData?[0],
              let right = buffer.floatChannelData?[1] else {
            return AVAudioPCMBuffer()
        }
        buffer.frameLength = frameCount
        
        // Pentatonic Ascending Frequencies: C5, E5, G5, B5, D6, G6
        let frequencies: [Double] = [523.25, 659.25, 783.99, 987.77, 1174.66, 1567.98]
        let noteSpacing = 0.07
        
        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / sampleRate
            var sample: Float = 0.0
            
            for (idx, freq) in frequencies.enumerated() {
                let noteStart = Double(idx) * noteSpacing
                if time >= noteStart {
                    let noteTime = time - noteStart
                    let env = exp(-noteTime * 6.5)
                    let tone = sin(2.0 * .pi * freq * noteTime) + 0.3 * sin(4.0 * .pi * freq * noteTime)
                    sample += Float(tone * env) * 0.18
                }
            }
            
            left[frame] = sample
            right[frame] = sample
        }
        return buffer
    }
    
    // MARK: - Rescue Fanfare Chord Synthesis
    private func createRescueFanfareBuffer() -> AVAudioPCMBuffer {
        let duration: Double = 1.4
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount),
              let left = buffer.floatChannelData?[0],
              let right = buffer.floatChannelData?[1] else {
            return AVAudioPCMBuffer()
        }
        buffer.frameLength = frameCount
        
        // C Major 9 Resonance: C4, G4, E5, B5, D6
        let chordFrequencies: [Double] = [261.63, 392.00, 659.25, 987.77, 1174.66]
        
        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / sampleRate
            var sample: Float = 0.0
            let masterEnv = exp(-time * 2.8) * (1.0 - exp(-time * 80.0))
            
            for freq in chordFrequencies {
                let wave = sin(2.0 * .pi * freq * time) + 0.25 * sin(2.0 * .pi * (freq * 2.0) * time)
                sample += Float(wave) * 0.16
            }
            
            sample *= Float(masterEnv)
            left[frame] = sample
            right[frame] = sample
        }
        return buffer
    }
    
    // MARK: - UI Click Synthesis
    private func createUIClickBuffer() -> AVAudioPCMBuffer {
        let duration: Double = 0.03
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount),
              let left = buffer.floatChannelData?[0],
              let right = buffer.floatChannelData?[1] else {
            return AVAudioPCMBuffer()
        }
        buffer.frameLength = frameCount
        
        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / sampleRate
            let env = exp(-time * 120.0)
            let freq = 1200.0 - (time / duration) * 800.0
            let sample = Float(sin(2.0 * .pi * freq * time) * env) * 0.45
            left[frame] = sample
            right[frame] = sample
        }
        return buffer
    }
    
    // MARK: - Drone Alarm Synthesis (Pulsing Electronic Siren)
    private func createDroneAlarmBuffer() -> AVAudioPCMBuffer {
        let duration: Double = 0.45
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount),
              let left = buffer.floatChannelData?[0],
              let right = buffer.floatChannelData?[1] else {
            return AVAudioPCMBuffer()
        }
        buffer.frameLength = frameCount
        
        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / sampleRate
            let freq = (time < 0.22) ? 880.0 : 1240.0
            let tone = sin(2.0 * .pi * freq * time)
            let env = (1.0 - exp(-time * 60.0)) * exp(-(duration - time) * 10.0)
            let sample = Float(tone * env) * 0.35
            left[frame] = sample
            right[frame] = sample
        }
        return buffer
    }
    
    // MARK: - Poacher Whistle Synthesis
    private func createPoacherWhistleBuffer() -> AVAudioPCMBuffer {
        let duration: Double = 0.35
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount),
              let left = buffer.floatChannelData?[0],
              let right = buffer.floatChannelData?[1] else {
            return AVAudioPCMBuffer()
        }
        buffer.frameLength = frameCount
        
        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / sampleRate
            let freq = 2100.0 + sin(2.0 * .pi * 8.0 * time) * 250.0
            let env = exp(-time * 8.0) * (1.0 - exp(-time * 80.0))
            let sample = Float(sin(2.0 * .pi * freq * time) * env) * 0.30
            left[frame] = sample
            right[frame] = sample
        }
        return buffer
    }
    
    // MARK: - Fire Crackle Synthesis
    private func createFireCrackleBuffer() -> AVAudioPCMBuffer {
        let duration: Double = 0.50
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount),
              let left = buffer.floatChannelData?[0],
              let right = buffer.floatChannelData?[1] else {
            return AVAudioPCMBuffer()
        }
        buffer.frameLength = frameCount
        
        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / sampleRate
            let isPop = Float.random(in: 0...1) > 0.985
            let popNoise = isPop ? Float.random(in: -1.0...1.0) * 0.8 : 0.0
            let lowRumble = Float(sin(2.0 * .pi * 65.0 * time)) * 0.25
            let sample = (popNoise + lowRumble) * Float(exp(-time * 4.0))
            left[frame] = sample
            right[frame] = sample
        }
        return buffer
    }
    
    // MARK: - Dialogue Beep Synthesis
    private func createDialogueBeepBuffer() -> AVAudioPCMBuffer {
        let duration: Double = 0.04
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount),
              let left = buffer.floatChannelData?[0],
              let right = buffer.floatChannelData?[1] else {
            return AVAudioPCMBuffer()
        }
        buffer.frameLength = frameCount
        
        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / sampleRate
            let env = exp(-time * 90.0)
            let sample = Float(sin(2.0 * .pi * 840.0 * time) * env) * 0.22
            left[frame] = sample
            right[frame] = sample
        }
        return buffer
    }
    
    // MARK: - Totem Purified Synthesis (Ethereal Chord)
    private func createTotemPurifiedBuffer() -> AVAudioPCMBuffer {
        let duration: Double = 1.8
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount),
              let left = buffer.floatChannelData?[0],
              let right = buffer.floatChannelData?[1] else {
            return AVAudioPCMBuffer()
        }
        buffer.frameLength = frameCount
        
        // F# Major Pentatonic Chime: F#4, A#4, C#5, F#5, G#5
        let freqs: [Double] = [369.99, 466.16, 554.37, 739.99, 830.61]
        
        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / sampleRate
            var sample: Float = 0.0
            let masterEnv = exp(-time * 2.2) * (1.0 - exp(-time * 60.0))
            
            for (idx, freq) in freqs.enumerated() {
                let noteTime = max(0, time - Double(idx) * 0.05)
                let noteEnv = exp(-noteTime * 2.5)
                let wave = sin(2.0 * .pi * freq * noteTime)
                sample += Float(wave * noteEnv) * 0.14
            }
            sample *= Float(masterEnv)
            left[frame] = sample
            right[frame] = sample
        }
        return buffer
    }
    
    // MARK: - Chainsaw Synthesis (Motor Distortion & Teeth Buzz)
    private func createChainsawBuffer() -> AVAudioPCMBuffer {
        let duration: Double = 0.9
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount),
              let left = buffer.floatChannelData?[0],
              let right = buffer.floatChannelData?[1] else {
            return AVAudioPCMBuffer()
        }
        buffer.frameLength = frameCount
        
        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / sampleRate
            let env = sin(.pi * min(1.0, time / duration))
            // Modulated sawtooth waveform for 2-stroke engine buzz
            let freq = 115.0 + 15.0 * sin(2.0 * .pi * 8.0 * time)
            let phase = (time * freq).truncatingRemainder(dividingBy: 1.0)
            let saw = (Float(phase) * 2.0 - 1.0)
            let grit = Float.random(in: -0.2...0.2)
            let sample = (saw * 0.4 + grit) * Float(env) * 0.35
            left[frame] = sample
            right[frame] = sample
        }
        return buffer
    }
    
    // MARK: - Net Cut Synthesis (Swift Snip)
    private func createNetCutBuffer() -> AVAudioPCMBuffer {
        let duration: Double = 0.12
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount),
              let left = buffer.floatChannelData?[0],
              let right = buffer.floatChannelData?[1] else {
            return AVAudioPCMBuffer()
        }
        buffer.frameLength = frameCount
        
        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / sampleRate
            let env = exp(-time * 45.0)
            let click = Float(sin(2.0 * .pi * 920.0 * time)) * 0.4
            let snapNoise = Float.random(in: -0.3...0.3) * Float(exp(-time * 80.0))
            let sample = (click + snapNoise) * Float(env) * 0.5
            left[frame] = sample
            right[frame] = sample
        }
        return buffer
    }
    
    // MARK: - Timer Tick Synthesis (Woodblock Clock)
    private func createTimerTickBuffer() -> AVAudioPCMBuffer {
        let duration: Double = 0.05
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount),
              let left = buffer.floatChannelData?[0],
              let right = buffer.floatChannelData?[1] else {
            return AVAudioPCMBuffer()
        }
        buffer.frameLength = frameCount
        
        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / sampleRate
            let env = exp(-time * 120.0)
            let sample = Float(sin(2.0 * .pi * 1250.0 * time) * env) * 0.35
            left[frame] = sample
            right[frame] = sample
        }
        return buffer
    }
    
    // MARK: - Portal Teleport Synthesis (Ascending Mystical Swell)
    private func createPortalTeleportBuffer() -> AVAudioPCMBuffer {
        let duration: Double = 1.4
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount),
              let left = buffer.floatChannelData?[0],
              let right = buffer.floatChannelData?[1] else {
            return AVAudioPCMBuffer()
        }
        buffer.frameLength = frameCount
        
        let chordFreqs: [Double] = [220.0, 329.63, 440.0, 554.37, 659.25, 880.0]
        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / sampleRate
            let env = sin(.pi * (time / duration)) * (1.0 - exp(-time * 15.0))
            let sweepFreq = 320.0 + pow(time / duration, 1.8) * 880.0
            var sample: Float = Float(sin(2.0 * .pi * sweepFreq * time) * 0.14)
            for (i, f) in chordFreqs.enumerated() {
                let shimmer = sin(2.0 * .pi * (f + sin(time * 12.0) * 4.0) * time)
                sample += Float(shimmer * exp(-Double(i) * 0.25) * 0.07)
            }
            sample *= Float(env)
            left[frame] = sample
            right[frame] = sample
        }
        return buffer
    }
    
    // MARK: - Ambient Loops
    private func startAmbientLoops() {
        guard isEngineRunning else { return }
        
        if let riverBuf = riverAmbienceBuffer {
            riverPlayerNode.scheduleBuffer(riverBuf, at: nil, options: .loops, completionHandler: nil)
            riverPlayerNode.volume = 0.0 // Initially updated by proximity
        }
        
        if let windBuf = windAmbienceBuffer {
            windPlayerNode.scheduleBuffer(windBuf, at: nil, options: .loops, completionHandler: nil)
            windPlayerNode.volume = ambienceVolume * 0.4
        }
    }
    
    // MARK: - Public Playback API
    
    /// Trigger player footstep with surface adaptation & organic pitch modulation
    public func playFootstep(at position: CGPoint, biome: BiomeType) {
        guard !isMuted else { return }
        let now = ProcessInfo.processInfo.systemUptime
        // Enforce natural human/animal walking stride cadence interval (0.34s)
        guard now - lastFootstepTime >= 0.34 else { return }
        lastFootstepTime = now
        
        // 1. Determine Surface based on river proximity & biome
        let distToRiver = distanceToRiver(point: position)
        let surface: FootstepSurface
        
        if distToRiver < 22.0 {
            surface = .water // Walking in or right by the river
        } else {
            switch biome {
            case .pantanal:
                surface = (distToRiver < 45.0) ? .water : .grass
            case .cerrado, .caatinga:
                surface = .gravel
            case .pampa:
                surface = .pampaGrass
            case .amazonia, .mataAtlantica:
                surface = .grass
            }
        }
        
        // 2. Pick buffer variation
        let list: [AVAudioPCMBuffer]
        switch surface {
        case .grass: list = grassStepBuffers
        case .water: list = waterStepBuffers
        case .gravel: list = gravelStepBuffers
        case .pampaGrass: list = pampaStepBuffers
        }
        
        guard !list.isEmpty else { return }
        stepAlternator.toggle()
        let index = stepAlternator ? Int.random(in: 0...1) : Int.random(in: 2...3)
        let buffer = list[min(index, list.count - 1)]
        
        // 3. Play buffer with soft organic gain on dedicated footstep node
        footstepPlayerNode.volume = footstepVolume * sfxVolume * Float.random(in: 0.80...1.0)
        footstepPlayerNode.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
    }
    
    /// Update positional river sound volume based on player's proximity to the river
    public func updateRiverProximity(playerPos: CGPoint) {
        guard !isMuted else {
            riverPlayerNode.volume = 0.0
            return
        }
        let dist = distanceToRiver(point: playerPos)
        // River audible up to 120 units away, maximum volume when closer than 15 units
        let maxDist: Double = 120.0
        let normalized = max(0.0, min(1.0, 1.0 - (dist / maxDist)))
        let targetVolume = Float(normalized * normalized) * ambienceVolume * 0.75
        riverPlayerNode.volume = targetVolume
    }
    
    /// Play Metamorphosis Shimmer Chime
    public func playMetamorphosis() {
        guard !isMuted, let buf = metamorphosisBuffer else { return }
        sfxPlayerNode.volume = sfxVolume * 1.1
        sfxPlayerNode.scheduleBuffer(buf, at: nil, options: [], completionHandler: nil)
    }
    
    /// Play Animal Rescue Victory Fanfare
    public func playRescueFanfare() {
        guard !isMuted, let buf = rescueFanfareBuffer else { return }
        sfxPlayerNode.volume = sfxVolume * 1.2
        sfxPlayerNode.scheduleBuffer(buf, at: nil, options: [], completionHandler: nil)
    }
    
    /// Play UI Click
    public func playUIClick() {
        guard !isMuted, let buf = uiClickBuffer else { return }
        sfxPlayerNode.volume = sfxVolume * 0.6
        sfxPlayerNode.scheduleBuffer(buf, at: nil, options: [], completionHandler: nil)
    }
    
    /// Play Drone Warning Alarm
    public func playDroneAlarm() {
        guard !isMuted, let buf = droneAlarmBuffer else { return }
        let now = ProcessInfo.processInfo.systemUptime
        guard now - lastEnemyAlarmTime >= 0.8 else { return }
        lastEnemyAlarmTime = now
        sfxPlayerNode.volume = sfxVolume * 0.85
        sfxPlayerNode.scheduleBuffer(buf, at: nil, options: [], completionHandler: nil)
    }
    
    /// Play Poacher Alert Whistle
    public func playPoacherWhistle() {
        guard !isMuted, let buf = poacherWhistleBuffer else { return }
        let now = ProcessInfo.processInfo.systemUptime
        guard now - lastEnemyAlarmTime >= 0.8 else { return }
        lastEnemyAlarmTime = now
        sfxPlayerNode.volume = sfxVolume * 0.8
        sfxPlayerNode.scheduleBuffer(buf, at: nil, options: [], completionHandler: nil)
    }
    
    /// Play Fire Crackle
    public func playFireCrackle() {
        guard !isMuted, let buf = fireCrackleBuffer else { return }
        sfxPlayerNode.volume = sfxVolume * 0.75
        sfxPlayerNode.scheduleBuffer(buf, at: nil, options: [], completionHandler: nil)
    }
    
    /// Play Dialogue Beep
    public func playDialogueBeep() {
        guard !isMuted, let buf = dialogueBeepBuffer else { return }
        sfxPlayerNode.volume = sfxVolume * 0.35
        sfxPlayerNode.scheduleBuffer(buf, at: nil, options: [], completionHandler: nil)
    }
    
    /// Play Totem Purified Ethereal Chime
    public func playTotemPurified() {
        guard !isMuted, let buf = totemPurifiedBuffer else { return }
        sfxPlayerNode.volume = sfxVolume * 1.25
        sfxPlayerNode.scheduleBuffer(buf, at: nil, options: [], completionHandler: nil)
    }
    
    /// Play Chainsaw Buzz
    public func playChainsaw() {
        guard !isMuted, let buf = chainsawBuffer else { return }
        let now = ProcessInfo.processInfo.systemUptime
        guard now - lastEnemyAlarmTime >= 0.8 else { return }
        lastEnemyAlarmTime = now
        sfxPlayerNode.volume = sfxVolume * 0.8
        sfxPlayerNode.scheduleBuffer(buf, at: nil, options: [], completionHandler: nil)
    }
    
    /// Play Net Cutting Snip
    public func playNetCut() {
        guard !isMuted, let buf = netCutBuffer else { return }
        sfxPlayerNode.volume = sfxVolume * 0.95
        sfxPlayerNode.scheduleBuffer(buf, at: nil, options: [], completionHandler: nil)
    }
    
    /// Play Timer Tick
    public func playTimerTick() {
        guard !isMuted, let buf = timerTickBuffer else { return }
        sfxPlayerNode.volume = sfxVolume * 0.45
        sfxPlayerNode.scheduleBuffer(buf, at: nil, options: [], completionHandler: nil)
    }
    
    /// Play Mystical Portal Teleport Swell
    public func playPortalTeleport() {
        guard !isMuted, let buf = portalTeleportBuffer else { return }
        sfxPlayerNode.volume = sfxVolume * 1.15
        sfxPlayerNode.scheduleBuffer(buf, at: nil, options: [], completionHandler: nil)
    }
    
    /// Update Procedural Biome Music Soundscape
    public func updateBiomeMusic(for biome: BiomeType) {
        guard !isMuted else {
            musicPlayerNode.volume = 0.0
            return
        }
        
        if currentPlayingMusicBiome != biome {
            currentPlayingMusicBiome = biome
            if let buf = ambientMusicBuffers[biome] {
                musicPlayerNode.stop()
                musicPlayerNode.scheduleBuffer(buf, at: nil, options: .loops, completionHandler: nil)
                musicPlayerNode.volume = musicVolume
                if !musicPlayerNode.isPlaying {
                    musicPlayerNode.play()
                }
            }
        }
    }
    
    // MARK: - Mathematical River Distance Calculation
    private func distanceToRiver(point: CGPoint) -> Double {
        // Straight North-South Continental River along x = -15.0
        let riverX = -15.0
        return abs(point.x - riverX)
    }
}
