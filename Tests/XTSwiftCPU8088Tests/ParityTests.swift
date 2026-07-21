// ParityTests.swift
// XT Copyright © 2025-2026; Electric Bolt Limited.

import Testing
@testable import XTSwiftCPU8088

struct ParityTests {

    @Test
    func parityTest() {
        #expect(Parity8.isEven(0b00000000))
        #expect(!Parity8.isOdd(0b00000000))
        #expect(!Parity8.isEven(0b00000001))
        #expect(Parity8.isOdd(0b00000001))
        #expect(Parity8.isEven(0b00000011))
        #expect(!Parity8.isOdd(0b00000011))
        #expect(!Parity8.isEven(0b00000111))
        #expect(Parity8.isEven(0b00001111))
        #expect(!Parity8.isEven(0b00011111))
        #expect(Parity8.isEven(0b00111111))
        #expect(!Parity8.isEven(0b01111111))
        #expect(Parity8.isEven(0b11111111))

        #expect(Parity8.isEven(0b00000101))
        #expect(!Parity8.isEven(0b00010101))
        #expect(Parity8.isEven(0b01010101))

        #expect(!Parity8.isEven(0b10000000))
        #expect(Parity8.isEven(0b11000000))
        #expect(!Parity8.isEven(0b11100000))
        #expect(Parity8.isEven(0b11110000))
        #expect(!Parity8.isEven(0b11111000))
        #expect(Parity8.isEven(0b11111100))
        #expect(!Parity8.isEven(0b11111110))

        #expect(Parity8.isEven(0b10100000))
        #expect(!Parity8.isEven(0b10101000))
        #expect(Parity8.isEven(0b10101010))

        #expect(Parity8.isEven(0b111110101010)) // confirms lower 8 bits only
        #expect(Parity8.isEven(0b001010101010)) // confirms lower 8 bits only
    }
}
