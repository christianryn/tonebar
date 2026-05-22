import Foundation

/// Single-producer, single-consumer float ring buffer for PCM between IOProc and AVAudioEngine.
final class RingBuffer {
    private var storage: [Float]
    private let capacity: Int
    private var readIndex = 0
    private var writeIndex = 0
    private var availableSamples = 0

    init(frameCapacity: Int, channelCount: Int) {
        capacity = max(frameCapacity * channelCount, 1)
        storage = [Float](repeating: 0, count: capacity)
    }

    var count: Int { availableSamples }

    func write(_ samples: UnsafePointer<Float>, count sampleCount: Int) -> Int {
        guard sampleCount > 0 else { return 0 }
        let writable = min(sampleCount, capacity - availableSamples)
        guard writable > 0 else { return 0 }

        var remaining = writable
        var sourceOffset = 0
        while remaining > 0 {
            let chunk = min(remaining, capacity - writeIndex)
            storage.withUnsafeMutableBufferPointer { buffer in
                buffer.baseAddress!.advanced(by: writeIndex)
                    .update(from: samples.advanced(by: sourceOffset), count: chunk)
            }
            writeIndex = (writeIndex + chunk) % capacity
            sourceOffset += chunk
            remaining -= chunk
        }
        availableSamples += writable
        return writable
    }

    func read(into destination: UnsafeMutablePointer<Float>, count requested: Int) -> Int {
        guard requested > 0, availableSamples > 0 else { return 0 }
        let readable = min(requested, availableSamples)

        var remaining = readable
        var destinationOffset = 0
        while remaining > 0 {
            let chunk = min(remaining, capacity - readIndex)
            storage.withUnsafeBufferPointer { buffer in
                destination.advanced(by: destinationOffset)
                    .update(from: buffer.baseAddress!.advanced(by: readIndex), count: chunk)
            }
            readIndex = (readIndex + chunk) % capacity
            destinationOffset += chunk
            remaining -= chunk
        }
        availableSamples -= readable
        return readable
    }

    func reset() {
        readIndex = 0
        writeIndex = 0
        availableSamples = 0
    }
}
