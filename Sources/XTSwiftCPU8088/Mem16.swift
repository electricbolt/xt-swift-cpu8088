// Mem16.swift
// XT Copyright © 2025-2026; Electric Bolt Limited.

import Foundation

class Mem16 {

    private let segOfs: SegOfs?
    private let reg: Reg16?
    private let memory: Memory?

    init(_ segOfs: SegOfs, _ memory: Memory) {
        self.segOfs = segOfs
        self.memory = memory
        self.reg = nil
    }

    init(_ reg: Reg16) {
        self.segOfs = nil
        self.memory = nil
        self.reg = reg
    }

    func getSegOfs() -> SegOfs? {
        if let segOfs {
            return segOfs.copy()
        } else {
            return nil
        }
    }

    func getReg() -> Reg16? {
        return reg
    }

    func getValue() -> UInt16 {
        if let reg {
            return reg.getValue()
        } else {
            return memory!.readWord(segOfs!)
        }
    }

    func setValue(_ value: UInt16) {
        if let reg {
            reg.setValue(value)
        } else {
            memory!.writeWord(segOfs!, value)
        }
    }
}
