// RegRM8.swift
// XT Copyright © 2025-2026; Electric Bolt Limited.

import Foundation

class RegRM8 {

    private let reg: Reg8
    private let mem: Mem8
    private let regValue: Int

    init(_ reg: Reg8, _ RMReg: Reg8, _ regValue: Int) {
        self.reg = reg
        self.mem = Mem8(RMReg)
        self.regValue = regValue
    }

    init(_ reg: Reg8, _ RMMem: SegOfs, _ memory: Memory, _ regValue: Int) {
        self.reg = reg
        self.mem = Mem8(RMMem, memory)
        self.regValue = regValue
    }

    func getReg8() -> Reg8 {
        return reg
    }

    func getMem8() -> Mem8 {
        return mem
    }

    func getRegValue() -> Int {
        return regValue
    }
}
