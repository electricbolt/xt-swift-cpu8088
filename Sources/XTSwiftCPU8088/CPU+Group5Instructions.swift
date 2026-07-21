// CPU+Group5Instructions.swift
// XT Copyright © 2025-2026; Electric Bolt Limited.

import Foundation

extension CPU {

    func decodeGroup5() {
        let regRM = modRegRMFetch16()
        switch regRM.getRegValue() {
            case 0: // INC r/m16 - Increment r/m word by 1.
                let origcarry = reg.flags.isCarry()
                let value = regRM.getMem16().getValue()
                let result = add16(value, 1, false)
                regRM.getMem16().setValue(result)
                reg.flags.setCarry(origcarry)
            case 1: // DEC r/m16 - Decrement r/m word by 1.
                let origcarry = reg.flags.isCarry()
                let value = regRM.getMem16().getValue()
                let result = sub16(value, 1, false)
                regRM.getMem16().setValue(result)
                reg.flags.setCarry(origcarry)
            case 2: // CALL r/m16 - Call near, register indirect/memory indirect.
                let value = regRM.getMem16().getValue()
                push16(reg.IP.getValue())
                reg.IP.setValue(value)
            case 3: // CALL m16:16 - Call intersegment address at r/m dword.
                let segOfs = regRM.getMem16().getSegOfs()!
                let offset = memory.readWord(segOfs)
                segOfs.addOffset(2)
                let segment = memory.readWord(segOfs)
                push16(reg.CS.getValue())
                push16(reg.IP.getValue())
                reg.IP.setValue(offset)
                reg.CS.setValue(segment)
            case 4: // JMP r/m16 - Jump near indirect.
                let value = regRM.getMem16().getValue()
                reg.IP.setValue(value)
            case 5: // JMP m16:16 - Jump r/m16:16 indirect and intersegment.
                let segOfs = regRM.getMem16().getSegOfs()!
                let offset = memory.readWord(segOfs)
                segOfs.addOffset(2)
                let segment = memory.readWord(segOfs)
                reg.IP.setValue(offset)
                reg.CS.setValue(segment)
            case 6: // PUSH m16 - Push memory word. (Also appears to be PUSH r/m16 - can be a register like AX).
                if let segOfs = regRM.getMem16().getSegOfs() {
                    let value = memory.readWord(segOfs)
                    push16(value)
                } else {
                    let value = regRM.getMem16().getValue()
                    if regRM.getMem16().getReg() === reg.SP {
                        // Push new value of SP instead of what SP was.
                        push16(value &- 2)
                    } else {
                        push16(value)
                    }
                }
            default:
                delegate.invalidOpcode(self, "Group5 operation 7 invalid")
        }
    }
}
