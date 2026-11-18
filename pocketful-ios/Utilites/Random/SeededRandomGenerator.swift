import Foundation

/// A random number generator that always gives the same numbers for the same seed, so a user's tree looks the same every launch.
struct SeededRandomGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    /// Makes a seed from a string (like a user ID) that stays the same across launches, unlike `hashValue`.
    init(seedText: String) {
        // FNV-1a hash.
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in seedText.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x100000001b3
        }
        state = hash
    }

    /// SplitMix64: a small, well-known algorithm for turning a counter into random-looking numbers.
    mutating func next() -> UInt64 {
        state = state &+ 0x9e3779b97f4a7c15
        var value = state
        value = (value ^ (value >> 30)) &* 0xbf58476d1ce4e5b9
        value = (value ^ (value >> 27)) &* 0x94d049bb133111eb
        return value ^ (value >> 31)
    }
}
