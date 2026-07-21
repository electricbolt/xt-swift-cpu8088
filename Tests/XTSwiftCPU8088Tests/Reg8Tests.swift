// Reg8Tests.swift
// XT Copyright © 2025-2026; Electric Bolt Limited.

import Testing
@testable import XTSwiftCPU8088

struct Reg8Tests {

    @Test
    func setValueTests() {
        let AX = Reg16("AX")
        let AL = Reg8(AX, false)
        let AH = Reg8(AX, true)

        AX.setValue(0)
        #expect(AX.getValue() == 0x0000)
        #expect(AL.getValue() == 0)
        #expect(AH.getValue() == 0)
        AL.setValue(0x12)
        #expect(AX.getValue() == 0x0012)
        #expect(AL.getValue() == 0x12)
        #expect(AH.getValue() == 0)
        AH.setValue(0x34)
        #expect(AX.getValue() == 0x3412)
        #expect(AL.getValue() == 0x12)
        #expect(AH.getValue() == 0x34)

        AX.setValue(1)
        #expect(AX.getValue() == 0x0001)
        #expect(AL.getValue() == 1)
        #expect(AH.getValue() == 0)

        AX.setValue(0x55AA)
        #expect(AX.getValue() == 0x55AA)
        #expect(AL.getValue() == 0xAA)
        #expect(AH.getValue() == 0x55)

        AX.setValue(0xFFFE)
        #expect(AX.getValue() == 0xFFFE)
        #expect(AL.getValue() == 0xFE)
        #expect(AH.getValue() == 0xFF)

        AX.setValue(0xFFFF)
        #expect(AX.getValue() == 0xFFFF)
        #expect(AL.getValue() == 0xFF)
        #expect(AH.getValue() == 0xFF)
        AL.setValue(0x12)
        #expect(AX.getValue() == 0xFF12)
        #expect(AL.getValue() == 0x12)
        #expect(AH.getValue() == 0xFF)
        AH.setValue(0x34)
        #expect(AX.getValue() == 0x3412)
        #expect(AL.getValue() == 0x12)
        #expect(AH.getValue() == 0x34)

        AX.setValue(UInt16(truncatingIfNeeded: 0x10000))
        #expect(AX.getValue() == 0)
        #expect(AL.getValue() == 0)
        #expect(AH.getValue() == 0)

        AX.setValue(UInt16(truncatingIfNeeded: 0x10001))
        #expect(AX.getValue() == 1)
        #expect(AL.getValue() == 1)
        #expect(AH.getValue() == 0)

        AX.setValue(UInt16(bitPattern: -1))
        #expect(AX.getValue() == 0xFFFF)
        #expect(AL.getValue() == 0xFF)
        #expect(AH.getValue() == 0xFF)

        AX.setValue(UInt16(bitPattern: -2))
        #expect(AX.getValue() == 0xFFFE)
        #expect(AL.getValue() == 0xFE)
        #expect(AH.getValue() == 0xFF)
    }

    @Test
    func miscTests() {
        let AX = Reg16("AX", 0x2459)
        let AL = Reg8(AX, false)
        let AH = Reg8(AX, true)
        #expect(AL.getName() == "AL")
        #expect(AH.getName() == "AH")
        #expect(AL.description == "AL=59")
        #expect(AH.description == "AH=24")

        let BX = Reg16("BX", 0x1234)
        let BL = BX.low()
        let BH = BX.high()
        #expect(BL.getValue() == 0x34)
        #expect(BH.getValue() == 0x12)

        #expect(AX.low() == AL)
        #expect(AX.high() == AH)
    }
}
