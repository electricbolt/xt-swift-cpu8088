// CPU+Group3BInstructions.swift
// XT Copyright © 2025-2026; Electric Bolt Limited.

import Foundation

extension CPU {

    func decodeGroup3B() {
        let regRM = modRegRMFetch16()
        switch regRM.getRegValue() {
            case 0: // TEST r/m16,imm16 - And immediate word with r/m word.
                _ = and16(regRM.getMem16().getValue(), fetch16())
            case 2: // NOT r/m16 - Reverse each bit of r/m word.
                regRM.getMem16().setValue(~regRM.getMem16().getValue())
            case 3: // NEG r/m16 - Two's complement negate r/m word.
                regRM.getMem16().setValue(sub16(0, regRM.getMem16().getValue(), false))
            case 4: // MUL r/m16 - Unsigned multiply (DX:AX = AX * r/m word)
                let result = mul16(reg.AX.getValue(), regRM.getMem16().getValue())
                reg.DX.setValue(UInt16(truncatingIfNeeded: result >> 16))
                reg.AX.setValue(UInt16(truncatingIfNeeded: result & 0xFFFF))
            case 5: // IMUL r/m16 - Signed multiply (DX:AX = AX * r/m word)
                let result = imul16(reg.AX.getValue(), regRM.getMem16().getValue())
                reg.DX.setValue(UInt16(truncatingIfNeeded: result >> 16))
                reg.AX.setValue(UInt16(truncatingIfNeeded: result & 0xFFFF))
            case 6: // DIV r/m16 - Unsigned divide DX:AX by r/m word (AX=QUO, DX=REM)
                do {
                    let dividend = (UInt32(reg.DX.getValue()) << 16) | UInt32(reg.AX.getValue())
                    let result = try div16(dividend, regRM.getMem16().getValue())
                    reg.DX.setValue(UInt16(truncatingIfNeeded: result >> 16))
                    reg.AX.setValue(UInt16(truncatingIfNeeded: result & 0xFFFF))
                } catch { // ArithmeticError
                    interrupt(0)
                }
            case 7: // IDIV r/m16 - Signed divide DX/AX by r/m word (AX=QUO, DX=REM)
                do {
                    let negateQuotient = isRepeating
                    let dividend = (UInt32(reg.DX.getValue()) << 16) | UInt32(reg.AX.getValue())
                    let result = try idiv16(dividend, regRM.getMem16().getValue(), negateQuotient)
                    reg.DX.setValue(UInt16(truncatingIfNeeded: result >> 16))
                    reg.AX.setValue(UInt16(truncatingIfNeeded: result & 0xFFFF))
                } catch { // ArithmeticError
                    interrupt(0)
                }
            default:
                delegate.invalidOpcode(self, "Group 3B operation 1 invalid")
        }
    }
}
