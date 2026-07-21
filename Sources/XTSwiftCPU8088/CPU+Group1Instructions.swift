// CPU+Group1Instructions.swift
// XT Copyright © 2025-2026; Electric Bolt Limited.

import Foundation

extension CPU {

    func imm8() {
        let regRM8 = modRegRMFetch8()
        let mem8 = regRM8.getMem8()
        switch regRM8.getRegValue() {
            case 0: // ADD r/m8,imm8 - Add immediate byte to r/m byte.
                mem8.setValue(add8(mem8.getValue(), fetch8(), false))
            case 1: // OR r/m8,imm8 - OR immediate byte to r/m byte.
                mem8.setValue(or8(UInt16(mem8.getValue()), UInt16(fetch8())))
            case 2: // ADC r/m8,imm8 - Add with carry immediate byte to r/m byte.
                mem8.setValue(add8(mem8.getValue(), fetch8(), reg.flags.isCarry()))
            case 3: // SBB r/m8,imm8 - Subtract with borrow immediate byte from r/m byte.
                mem8.setValue(sub8(mem8.getValue(), fetch8(), reg.flags.isCarry()))
            case 4: // AND r/m8,imm8 - AND immediate byte to r/m byte.
                mem8.setValue(and8(UInt16(mem8.getValue()), UInt16(fetch8())))
            case 5: // SUB r/m8,imm8 - Subtract immediate byte from r/m byte.
                mem8.setValue(sub8(mem8.getValue(), fetch8(), false))
            case 6: // XOR r/m8,imm8 - Exclusive-OR immediate byte to r/m byte.
                mem8.setValue(xor8(UInt16(mem8.getValue()), UInt16(fetch8())))
            default: // CMP r/m8,imm8 - Compare immediate byte to r/m byte.
                _ = sub8(mem8.getValue(), fetch8(), false)
        }
    }

    func imm16(_ signExtendedByte: Bool) {
        let regRM16 = modRegRMFetch16()
        let mem16 = regRM16.getMem16()
        let imm16 = signExtendedByte ? UInt16(truncatingIfNeeded: Int8(bitPattern: fetch8())) : fetch16()
        switch regRM16.getRegValue() {
            case 0: // ADD r/m16,imm16/imm8
                mem16.setValue(add16(mem16.getValue(), imm16, false))
            case 1: // OR r/m16,imm16/imm8
                mem16.setValue(or16(mem16.getValue(), imm16))
            case 2: // ADC r/m16,imm16/imm8
                mem16.setValue(add16(mem16.getValue(), imm16, reg.flags.isCarry()))
            case 3: // SBB r/m16,imm16/imm8
                mem16.setValue(sub16(mem16.getValue(), imm16, reg.flags.isCarry()))
            case 4: // AND r/m16,imm16/imm8
                mem16.setValue(and16(mem16.getValue(), imm16))
            case 5: // SUB r/m16,imm16/imm8
                mem16.setValue(sub16(mem16.getValue(), imm16, false))
            case 6: // XOR r/m16,imm16/imm8
                mem16.setValue(xor16(mem16.getValue(), imm16))
            default: // CMP r/m16,imm16/imm8
                _ = sub16(mem16.getValue(), imm16, false)
        }
    }
}
