// Reg16Tests.swift
// XT Copyright © 2025-2026; Electric Bolt Limited.

import Testing
@testable import XTSwiftCPU8088

struct Reg16Tests {

    @Test
    func setValueTests() {
        let RA = Reg16("RA")
        #expect(RA.getValue() == 0)
        RA.setValue(0)
        #expect(RA.getValue() == 0x0000)
        RA.setValue(1)
        #expect(RA.getValue() == 0x0001)
        RA.setValue(0xFFFE)
        #expect(RA.getValue() == 0xFFFE)
        RA.setValue(0xFFFF)
        #expect(RA.getValue() == 0xFFFF)
        RA.setValue(UInt16(truncatingIfNeeded: 0x10000))
        #expect(RA.getValue() == 0)
        RA.setValue(UInt16(truncatingIfNeeded: 0x10001))
        #expect(RA.getValue() == 1)
        RA.setValue(UInt16(bitPattern: -1))
        #expect(RA.getValue() == 0xFFFF)
        RA.setValue(UInt16(bitPattern: -2))
        #expect(RA.getValue() == 0xFFFE)
    }

    @Test
    func addValueTests() {
        let RA = Reg16("RA")
        RA.add(1)
        #expect(RA.getValue() == 0x0001)
        RA.add(2)
        #expect(RA.getValue() == 0x0003)
        RA.setValue(0)
        RA.add(0xFFFF)
        #expect(RA.getValue() == 0xFFFF)
        RA.setValue(0)
        RA.add(UInt16(truncatingIfNeeded: 0x10000))
        #expect(RA.getValue() == 0x0000)
        RA.setValue(0)
        RA.add(UInt16(truncatingIfNeeded: 0x12345))
        #expect(RA.getValue() == 0x2345)

        RA.setValue(0)
        RA.add(UInt16(bitPattern: -1))
        #expect(RA.getValue() == 0xFFFF)
        RA.add(UInt16(bitPattern: -2))
        #expect(RA.getValue() == 0xFFFD)

        RA.setValue(0x1234)
        RA.add(UInt16(bitPattern: -1))
        #expect(RA.getValue() == 0x1233)
        RA.add(UInt16(bitPattern: -2))
        #expect(RA.getValue() == 0x1231)
    }

    @Test
    func miscTests() {
        let RA = Reg16("RA", 0x2459)
        let RB = RA.copy()
        #expect(RB == RA)
        #expect(RA.getValue() == RB.getValue())

        RA.setValue(0x4567)
        #expect(RA.getValue() == 0x4567)
        #expect(RB.getValue() == 0x2459)
        #expect(RA.description == "RA=4567")
        #expect(RA.getName() == "RA")
        #expect(RA.getValue() != RB.getValue())
    }
}
