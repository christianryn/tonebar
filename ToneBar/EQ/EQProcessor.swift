import AVFAudio
import Foundation

final class EQProcessor {
    private let centerFrequencies: [Float] = [32, 64, 125, 250, 500, 1_000, 2_000, 4_000, 8_000, 16_000]

    func applyGraphicEQ(to unit: AVAudioUnitEQ) {
        let bands = unit.bands
        for index in bands.indices {
            let band = bands[index]
            band.filterType = .parametric
            band.frequency = centerFrequencies[min(index, centerFrequencies.count - 1)]
            band.bandwidth = 1.0
            band.gain = 0
            band.bypass = false
        }
    }

    func setBandGain(on unit: AVAudioUnitEQ, index: Int, gain: Float) {
        guard unit.bands.indices.contains(index) else { return }
        unit.bands[index].gain = gain
    }

    func linearGain(fromDecibels decibels: Float) -> Float {
        pow(10, decibels / 20)
    }
}
