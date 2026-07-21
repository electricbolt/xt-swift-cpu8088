// CPU+Group3AInstructions.swift
// XT Copyright © 2025-2026; Electric Bolt Limited.

import Foundation

extension CPU {

    func decodeGroup3A() {
        let regRM = modRegRMFetch8()
        switch regRM.getRegValue() {
            case 0: // TEST r/m8,imm8 - And immediate byte with r/m byte.
                _ = and8(UInt16(regRM.getMem8().getValue()), UInt16(fetch8()))
            case 2: // NOT r/m8 - Reverse each bit of r/m byte.
                regRM.getMem8().setValue(~regRM.getMem8().getValue())
            case 3: // NEG r/m8 - Two's complement negate r/m byte.
                regRM.getMem8().setValue(sub8(0, regRM.getMem8().getValue(), false))
            case 4: // MUL r/m8 - Unsigned multiply (AX = AL * r/m byte)
                reg.AX.setValue(mul8(reg.AL.getValue(), regRM.getMem8().getValue()))
            case 5: // IMUL r/m8 - Signed multiply (AX = AL * r/m byte)
                reg.AX.setValue(imul8(reg.AL.getValue(), regRM.getMem8().getValue()))
            case 6: // DIV r/m8 - Unsigned divide AX by r/m byte (AL=QUO, AH=REM)
                do {
                    reg.AX.setValue(try div8(reg.AX.getValue(), regRM.getMem8().getValue()))
                } catch { // ArithmeticError
                    interrupt(0)
                }
            case 7: // IDIV r/m8 - Signed divide AX by r/m byte (AL=QUO, AH=REM)
                do {
                    let negateQuotient = isRepeating
                    reg.AX.setValue(try idiv8(reg.AX.getValue(), regRM.getMem8().getValue(), negateQuotient))
                } catch { // ArithmeticError
                    interrupt(0)
                }
            default:
                delegate.invalidOpcode(self, "Group 3A operation 1 invalid")
        }
    }
}
