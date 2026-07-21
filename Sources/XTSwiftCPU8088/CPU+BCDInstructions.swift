// CPU+BCDInstructions.swift
// XT Copyright © 2025-2026; Electric Bolt Limited.

import Foundation

extension CPU {

    /// AAA - ASCII adjust after addition.

    func aaa() {
        let origal = Int(reg.AL.getValue())
        let adjal: Int

        if ((reg.AL.getValue() & 0xF) > 0x9) || reg.flags.isAuxiliaryCarry() {
            reg.AH.setValue(reg.AH.getValue() &+ 1)
            adjal = (origal + 6) & 0xFF
            reg.AL.setValue(UInt8(adjal & 0xF))
            reg.flags.setAuxiliaryCarry(true)
            reg.flags.setCarry(true)
        } else {
            adjal = origal
            reg.AL.setValue(UInt8(adjal & 0xF))
            reg.flags.setAuxiliaryCarry(false)
            reg.flags.setCarry(false)
        }

        reg.flags.setZero(adjal == 0)
        reg.flags.setParityEven(Parity8.isEven(adjal))

        // Undocumented behaviour to allow Single Step Tests to pass.
        reg.flags.setOverflow(origal >= 0x7A && origal <= 0x7F)
        reg.flags.setSignNegative(origal >= 0x7A && origal <= 0xF9)
    }

    /// AAS - ASCII adjust after subtraction.

    func aas() {
        let origal = Int(reg.AL.getValue())
        let adjal: Int
        let origAuxiliaryCarry = reg.flags.isAuxiliaryCarry()

        if ((reg.AL.getValue() & 0xF) > 0x9) || reg.flags.isAuxiliaryCarry() {
            reg.AH.setValue(reg.AH.getValue() &- 1)
            adjal = (origal - 6) & 0xFF
            reg.AL.setValue(UInt8(adjal & 0xF))
            reg.flags.setAuxiliaryCarry(true)
            reg.flags.setCarry(true)
        } else {
            adjal = origal
            reg.AL.setValue(UInt8(adjal & 0xF))
            reg.flags.setAuxiliaryCarry(false)
            reg.flags.setCarry(false)
        }

        reg.flags.setZero(adjal == 0)
        reg.flags.setParityEven(Parity8.isEven(adjal))

        // Undocumented behaviour to allow Single Step Tests to pass.
        if origAuxiliaryCarry {
            reg.flags.setOverflow(origal >= 0x80 && origal <= 0x85)
            reg.flags.setSignNegative(origal <= 0x05 || origal >= 0x86)
        } else {
            reg.flags.setOverflow(false)
            reg.flags.setSignNegative(origal >= 0x80)
        }
    }

    /// DAA - Decimal adjust AL after addition.
    ///
    /// Algorithm from https://www.righto.com/2023/01/understanding-x86s-decimal-adjust-after.html website.

    func daa() {
        var al = Int(reg.AL.getValue())
        let origal = al
        let comp1 = reg.flags.isAuxiliaryCarry() ? 0x9F : 0x99

        // Undocumented behaviour to allow Single Step Tests to pass.
        let comp2 = reg.flags.isCarry() ? 0x1A : 0x7A
        reg.flags.setOverflow(al >= comp2 && al <= 0x7F)

        if ((al & 0xF) > 0x9) || reg.flags.isAuxiliaryCarry() {
            al += 0x6
            reg.flags.setAuxiliaryCarry(true)
        } else {
            reg.flags.setAuxiliaryCarry(false)
        }

        if ((origal & 0xFF) > comp1) || reg.flags.isCarry() {
            al += 0x60
            reg.flags.setCarry(true)
        } else {
            reg.flags.setCarry(false)
        }

        reg.flags.setSignNegative((al & 0x80) == 0x80)
        reg.flags.setZero((al & 0xFF) == 0)
        reg.flags.setParityEven(Parity8.isEven(al))
        reg.AL.setValue(UInt8(truncatingIfNeeded: al))
    }

    /// DAS - Decimal adjust AL after subtraction.

    func das() {
        var al = Int(reg.AL.getValue())
        let origal = al
        let comp1 = reg.flags.isAuxiliaryCarry() ? 0x9F : 0x99

        // Undocumented behaviour to allow Single Step Tests to pass.
        let overflow = switch reg.flags.getValue16() & (Flags.AUX_CARRY | Flags.CARRY) {
            case Flags.CARRY: (al >= 0x80 && al <= 0xDF)
            case Flags.AUX_CARRY: (al >= 0x80 && al <= 0x85) || (al >= 0xA0 && al <= 0xE5)
            case Flags.AUX_CARRY | Flags.CARRY: (al >= 0x80 && al <= 0xE5)
            default: (al >= 0x9A && al <= 0xDF)
        }
        reg.flags.setOverflow(overflow)

        if ((al & 0xF) > 0x9) || reg.flags.isAuxiliaryCarry() {
            al -= 0x6
            reg.flags.setAuxiliaryCarry(true)
        } else {
            reg.flags.setAuxiliaryCarry(false)
        }

        if ((origal & 0xFF) > comp1) || reg.flags.isCarry() {
            al -= 0x60
            reg.flags.setCarry(true)
        } else {
            reg.flags.setCarry(false)
        }

        reg.flags.setSignNegative((al & 0x80) == 0x80)
        reg.flags.setZero((al & 0xFF) == 0)
        reg.flags.setParityEven(Parity8.isEven(al))
        reg.AL.setValue(UInt8(truncatingIfNeeded: al))
    }

    /// AAM - ASCII adjust after multiplication.
    ///
    /// - Parameter base: Normally base 10.
    /// - Returns false: if base is zero, otherwise true.

    func aam(_ base: UInt8) -> Bool {
        // Undocumented behaviour to allow Single Step Tests to pass.
        reg.flags.setCarry(false)
        reg.flags.setAuxiliaryCarry(false)
        reg.flags.setOverflow(false)

        if base == 0 {
            reg.flags.setSignNegative(false)
            reg.flags.setZero(true)
            reg.flags.setParityEven(true)
            return false
        } else {
            reg.AH.setValue(reg.AL.getValue() / base)
            reg.AL.setValue(reg.AL.getValue() % base)

            reg.flags.setSignNegative((reg.AL.getValue() & 0x80) == 0x80)
            reg.flags.setZero(reg.AL.getValue() == 0)
            reg.flags.setParityEven(Parity8.isEven(Int(reg.AL.getValue())))
            return true
        }
    }

    /// AAD - ASCII adjust before division.
    /// 
    /// - Parameter base: Normally base 10.

    func aad(_ base: UInt8) {
        let al = reg.AL.getValue()
        let ah = reg.AH.getValue()
        let multiply = UInt8(truncatingIfNeeded: Int(ah) * Int(base))
        let result = Int(al) + Int(multiply)

        reg.AL.setValue(UInt8(truncatingIfNeeded: result))
        reg.AH.setValue(0)

        reg.flags.setSignNegative((result & 0x80) == 0x80)
        reg.flags.setZero((result & 0xFF) == 0)
        reg.flags.setParityEven(Parity8.isEven(result))

        // Undocumented behaviour to allow Single Step Tests to pass.
        reg.flags.setOverflow(((al & 0x80) == (multiply & 0x80)) && (Int(result) & 0x80) != (Int(al) & 0x80))
        reg.flags.setAuxiliaryCarry(((al & 0xF) + (multiply & 0xF)) > 0xF)
        reg.flags.setCarry(result > 0xFF)
    }
}
