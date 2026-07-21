// Reg8.swift
// XT Copyright © 2025-2026; Electric Bolt Limited.

import Foundation

public class Reg8: Equatable, CustomStringConvertible {

    public func setValue(_ value: UInt8) {
        if high {
            reg.setValue((reg.getValue() & 0x00FF) | (UInt16(value) << 8))
        } else {
            reg.setValue((reg.getValue() & 0xFF00) | UInt16(value))
        }
    }

    public func getValue() -> UInt8 {
        if high {
            return UInt8((reg.getValue() >> 8) & 0xFF)
        } else {
            return UInt8(reg.getValue() & 0x00FF)
        }
    }

    public static func == (lhs: Reg8, rhs: Reg8) -> Bool {
        return lhs.getName() == rhs.getName() && lhs.getValue() == rhs.getValue()
    }

    public func getName() -> String {
        return String(reg.getName().prefix(1)) + (high ? "H" : "L")
    }

    public var description: String {
        return getName() + "=" + String(format: "%02X", getValue())
    }

    // MARK: - Internal

    private let high: Bool
    private unowned let reg: Reg16

    init(_ reg: Reg16, _ high: Bool) {
        self.reg = reg
        self.high = high
    }
}
