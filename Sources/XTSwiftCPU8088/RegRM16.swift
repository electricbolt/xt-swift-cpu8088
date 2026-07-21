// RegRM16.swift
// XT Copyright © 2025-2026; Electric Bolt Limited.

import Foundation

class RegRM16 {

    private let reg: Reg16
    private let mem: Mem16
    private let regValue: Int

    init(_ reg: Reg16, _ RMReg: Reg16, _ regValue: Int) {
        self.reg = reg
        self.mem = Mem16(RMReg)
        self.regValue = regValue
    }

    init(_ reg: Reg16, _ RMMem: SegOfs, _ memory: Memory, _ regValue: Int) {
        self.reg = reg
        self.mem = Mem16(RMMem, memory)
        self.regValue = regValue
    }

    func getReg16() -> Reg16 {
        return reg
    }

    func getMem16() -> Mem16 {
        return mem
    }

    func getRegValue() -> Int {
        return regValue
    }
}
