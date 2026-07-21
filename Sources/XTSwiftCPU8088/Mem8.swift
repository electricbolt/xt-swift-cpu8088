// Mem8.swift
// XT Copyright © 2025-2026; Electric Bolt Limited.

import Foundation

class Mem8 {

    private let segOfs: SegOfs?
    private let reg: Reg8?
    private let memory: Memory?

    init(_ segOfs: SegOfs, _ memory: Memory) {
        self.segOfs = segOfs
        self.memory = memory
        self.reg = nil
    }

    init(_ reg: Reg8) {
        self.segOfs = nil
        self.memory = nil
        self.reg = reg
    }

    func getValue() -> UInt8 {
        if let reg {
            return reg.getValue()
        } else {
            return memory!.readByte(segOfs!)
        }
    }

    func setValue(_ value: UInt8) {
        if let reg {
            reg.setValue(value)
        } else {
            memory!.writeByte(segOfs!, value)
        }
    }
}
