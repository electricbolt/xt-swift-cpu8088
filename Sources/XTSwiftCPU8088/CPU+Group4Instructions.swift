// CPU+Group4Instructions.swift
// XT Copyright © 2025-2026; Electric Bolt Limited.

import Foundation

extension CPU {

    func decodeGroup4() {
        let regRM = modRegRMFetch8()
        switch regRM.getRegValue() {
            case 0: // INC r/m8 - Increment r/m byte by 1.
                let value = regRM.getMem8().getValue()
                let origcarry = reg.flags.isCarry()
                let result = add8(value, 1, false)
                regRM.getMem8().setValue(result)
                reg.flags.setCarry(origcarry)
            case 1: // DEC r/m8 - Decrement r/m byte by 1.
                let value = regRM.getMem8().getValue()
                let origcarry = reg.flags.isCarry()
                let result = sub8(value, 1, false)
                regRM.getMem8().setValue(result)
                reg.flags.setCarry(origcarry)
            default:
                delegate.invalidOpcode(self, "Group 4 operation \(regRM.getRegValue()) invalid")
        }
    }
}
