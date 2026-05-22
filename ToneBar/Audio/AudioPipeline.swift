import AVFAudio
import Foundation

/// AVAudioEngine graph: source node → EQ → output gain → hardware output.
final class AudioPipeline {
    private let engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode?
    private let eqNode = AVAudioUnitEQ(numberOfBands: 10)
    private let outputMixer = AVAudioMixerNode()

    private var ringBuffer: RingBuffer?
    private var isConfigured = false

    var outputGain: Float = 0 {
        didSet { outputMixer.outputVolume = eqProcessor.linearGain(fromDecibels: outputGain) }
    }

    private let eqProcessor = EQProcessor()

    func configure(format: AVAudioFormat, ringBuffer: RingBuffer) throws {
        stop()
        self.ringBuffer = ringBuffer
        engine.reset()

        let frameCapacity = Int(format.sampleRate * 0.05)
        self.ringBuffer = ringBuffer

        let node = AVAudioSourceNode(format: format) { [weak self] _, _, frameCount, inputBuffer in
            guard let self, let ringBuffer = self.ringBuffer else { return noErr }
            let channelCount = Int(format.channelCount)
            let requestedSamples = Int(frameCount) * channelCount

            guard let channelData = inputBuffer.pointee.mBuffers.mData?.assumingMemoryBound(to: Float.self) else {
                return noErr
            }

            let read = ringBuffer.read(into: channelData, count: requestedSamples)
            if read < requestedSamples {
                channelData.advanced(by: read).initialize(repeating: 0, count: requestedSamples - read)
            }
            return noErr
        }
        sourceNode = node

        eqProcessor.applyGraphicEQ(to: eqNode)

        engine.attach(node)
        engine.attach(eqNode)
        engine.attach(outputMixer)

        engine.connect(node, to: eqNode, format: format)
        engine.connect(eqNode, to: outputMixer, format: format)
        engine.connect(outputMixer, to: engine.outputNode, format: format)

        outputMixer.outputVolume = eqProcessor.linearGain(fromDecibels: outputGain)
        engine.prepare()
        try engine.start()
        isConfigured = true
    }

    func setBandGain(index: Int, gain: Float) {
        eqProcessor.setBandGain(on: eqNode, index: index, gain: gain)
    }

    func stop() {
        if engine.isRunning {
            engine.stop()
        }
        engine.reset()
        isConfigured = false
    }

    var isRunning: Bool { engine.isRunning }
}
