// CPU+Group2Instructions.swift
// XT Copyright © 2025-2026; Electric Bolt Limited.

import Foundation

extension CPU {

    func rotate8(_ count: Int) {
        let regRM = modRegRMFetch8()
        var value = regRM.getMem8().getValue()
        switch regRM.getRegValue() {
            case 0: value = rotateLeft8(value, count) // ROL r/m8,1 - Rotate 8 bits r/m byte count times.
            case 1: value = rotateRight8(value, count) // ROR r/m8,1 - Rotate 8 bits r/m byte count times.
            case 2: value = rotateLeft9(value, count) // RCL r/m8,1 - Rotate 9 bits (CF,r/m byte) count times.
            case 3: value = rotateRight9(value, count) // RCR r/m8,1 - Rotate 9 bits (CF,r/m byte) right count times.
            case 4: value = shiftLeft8(value, count) // SAL/SHL r/m8,1 - Multiply r/m byte by 2 count times.
            case 5: value = shiftRight8(value, count, false) // SHR r/m8,1 - Unsigned divide r/m byte by 2 count times.
            case 7: value = shiftRight8(value, count, true) // SAR r/m8,1 - Signed divide r/m byte by 2 count times.
            default:
                delegate.invalidOpcode(self, "Unexpected value: \(regRM.getRegValue())")
                value = 0
        }
        regRM.getMem8().setValue(value)
    }

    func rotate16(_ count: Int) {
        let regRM = modRegRMFetch16()
        var value = regRM.getMem16().getValue()
        switch regRM.getRegValue() {
            case 0: value = rotateLeft16(value, count) // ROL r/m16,1 - Rotate 16 bits r/m byte left count times.
            case 1: value = rotateRight16(value, count) // ROR r/m16,1 - Rotate 16 bits r/m byte right count times.
            case 2: value = rotateLeft17(value, count) // RCL r/m16,1 - Rotate 17 bits (CF,r/m byte) left count times.
            case 3: value = rotateRight17(value, count) // RCR r/m16,1 - Rotate 17 bits (CF,r/m byte) right count times.
            case 4: value = shiftLeft16(value, count) // SAL/SHL r/m16,1 - Multiply r/m byte by 2 count times.
            case 5: value = shiftRight16(value, count, false) // SHR r/m16,1 - Unsigned divide r/m byte by 2 count times.
            case 7: value = shiftRight16(value, count, true) // SAR r/m16,1 - Signed divide r/m byte by 2 count times.
            default:
                delegate.invalidOpcode(self, "Unexpected value: \(regRM.getRegValue())")
                value = 0
        }
        regRM.getMem16().setValue(value)
    }

    func shiftLeft8(_ value: UInt8, _ count: Int) -> UInt8 {
        var value = value
        for _ in 0..<count {
            reg.flags.setCarry((value & 0x80) == 0x80)
            value = value << 1
        }
        reg.flags.setSignNegative((value & 0x80) == 0x80)
        reg.flags.setZero(value == 0x0)
        reg.flags.setParityEven(Parity8.isEven(Int(value)))
        reg.flags.setOverflow(reg.flags.isCarry() != ((value & 0x80) == 0x80))

        // Undocumented behaviour to allow single step tests to pass.
        reg.flags.setAuxiliaryCarry((value & 0x10) != 0)
        return value
    }

    func shiftRight8(_ value: UInt8, _ count: Int, _ signed: Bool) -> UInt8 {
        var value = value
        for _ in 0..<count {
            reg.flags.setCarry((value & 0x01) == 0x01)
            value = UInt8(bitPattern: Int8(bitPattern: value) >> 1) & (signed ? 0xFF : 0x7F)
        }
        reg.flags.setSignNegative((value & 0x80) == 0x80)
        reg.flags.setZero(value == 0x0)
        reg.flags.setParityEven(Parity8.isEven(Int(value)))
        reg.flags.setOverflow(((value & 0x80) == 0x80) != ((value & 0x40) == 0x40))

        // Undocumented behaviour to allow single step tests to pass.
        reg.flags.setAuxiliaryCarry(false)
        return value
    }

    func shiftLeft16(_ value: UInt16, _ count: Int) -> UInt16 {
        var value = value
        for _ in 0..<count {
            reg.flags.setCarry((value & 0x8000) == 0x8000)
            value = value << 1
        }
        reg.flags.setSignNegative((value & 0x8000) == 0x8000)
        reg.flags.setZero(value == 0x0)
        reg.flags.setParityEven(Parity8.isEven(Int(value)))
        reg.flags.setOverflow(reg.flags.isCarry() != ((value & 0x8000) == 0x8000))

        // Undocumented behaviour to allow single step tests to pass.
        reg.flags.setAuxiliaryCarry((value & 0x10) != 0)
        return value
    }

    func shiftRight16(_ value: UInt16, _ count: Int, _ signed: Bool) -> UInt16 {
        var value = value
        for _ in 0..<count {
            reg.flags.setCarry((value & 0x0001) == 0x0001)
            value = UInt16(bitPattern: Int16(bitPattern: value) >> 1) & (signed ? 0xFFFF : 0x7FFF)
        }
        reg.flags.setSignNegative((value & 0x8000) == 0x8000)
        reg.flags.setZero(value == 0x0)
        reg.flags.setParityEven(Parity8.isEven(Int(value)))
        reg.flags.setOverflow(((value & 0x8000) == 0x8000) != ((value & 0x4000) == 0x4000))

        // Undocumented behaviour to allow single step tests to pass.
        reg.flags.setAuxiliaryCarry(false)
        return value
    }

    func rotateLeft8(_ value: UInt8, _ count: Int) -> UInt8 {
        var value = value
        for _ in 0..<count {
            reg.flags.setCarry((value & 0x80) == 0x80)
            let value1 = value << 1
            let value2 = (value >> 7) & 0x01
            value = value1 | value2
        }
        reg.flags.setOverflow(reg.flags.isCarry() != ((value & 0x80) == 0x80))
        return value
    }

    func rotateRight8(_ value: UInt8, _ count: Int) -> UInt8 {
        var value = value
        for _ in 0..<count {
            reg.flags.setCarry((value & 0x01) == 0x01)
            let value1 = (value >> 1) & 0x7F
            let value2 = (value << 7) & 0x80
            value = value1 | value2
        }
        reg.flags.setOverflow(((value & 0x80) == 0x80) != ((value & 0x40) == 0x40))
        return value
    }

    func rotateLeft9(_ value: UInt8, _ count: Int) -> UInt8 {
        var value = value
        for _ in 0..<count {
            let origCarry = reg.flags.isCarry()
            let value1 = value << 1
            reg.flags.setCarry(((value >> 7) & 0x01) == 0x01)
            value = value1 | (origCarry ? 0x01 : 0x00)
        }
        reg.flags.setOverflow(reg.flags.isCarry() != ((value & 0x80) == 0x80))
        return value
    }

    func rotateRight9(_ value: UInt8, _ count: Int) -> UInt8 {
        var value = value
        for _ in 0..<count {
            let origCarry = reg.flags.isCarry()
            reg.flags.setCarry((value & 0x01) == 0x01)
            let value1 = (value >> 1) & 0x7F
            value = value1 | (origCarry ? 0x80 : 0x00)
        }
        reg.flags.setOverflow(((value & 0x80) == 0x80) != ((value & 0x40) == 0x40))
        return value
    }

    func rotateLeft16(_ value: UInt16, _ count: Int) -> UInt16 {
        var value = value
        for _ in 0..<count {
            reg.flags.setCarry((value & 0x8000) == 0x8000)
            let value1 = value << 1
            let value2 = (value >> 15) & 0x0001
            value = value1 | value2
        }
        reg.flags.setOverflow(reg.flags.isCarry() != ((value & 0x8000) == 0x8000))
        return value
    }

    func rotateRight16(_ value: UInt16, _ count: Int) -> UInt16 {
        var value = value
        for _ in 0..<count {
            reg.flags.setCarry((value & 0x0001) == 0x0001)
            let value1 = (value >> 1) & 0x7FFF
            let value2 = (value << 15) & 0x8000
            value = value1 | value2
        }
        reg.flags.setOverflow(((value & 0x8000) == 0x8000) != ((value & 0x4000) == 0x4000))
        return value
    }

    func rotateLeft17(_ value: UInt16, _ count: Int) -> UInt16 {
        var value = value
        for _ in 0..<count {
            let origCarry = reg.flags.isCarry()
            let value1 = value << 1
            reg.flags.setCarry(((value >> 15) & 0x0001) == 0x0001)
            value = value1 | (origCarry ? 0x0001 : 0x0000)
        }
        reg.flags.setOverflow(reg.flags.isCarry() != ((value & 0x8000) == 0x8000))
        return value
    }

    func rotateRight17(_ value: UInt16, _ count: Int) -> UInt16 {
        var value = value
        for _ in 0..<count {
            let origCarry = reg.flags.isCarry()
            reg.flags.setCarry((value & 0x0001) == 0x0001)
            let value1 = (value >> 1) & 0x7FFF
            value = value1 | (origCarry ? 0x8000 : 0x0000)
        }
        reg.flags.setOverflow(((value & 0x8000) == 0x8000) != ((value & 0x4000) == 0x4000))
        return value
    }
}
