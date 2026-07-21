// Reg16.swift
// XT Copyright © 2025-2026; Electric Bolt Limited.

import Foundation

public class Reg16: Equatable, CustomStringConvertible {

    public func add(_ value: UInt16) {
        setValue(getValue() &+ value)
    }

    public func getValue() -> UInt16 {
        return value
    }

    public func setValue(_ value: UInt16) {
        self.value = value
    }

    public func getName() -> String {
        return name
    }

    public func copy() -> Reg16 {
        return Reg16(name, value)
    }

    public static func == (lhs: Reg16, rhs: Reg16) -> Bool {
        return lhs.name == rhs.name && lhs.value == rhs.value
    }

    public var description: String {
        return name + "=" + String(format: "%04X", value)
    }

    func high() -> Reg8 {
        if _high == nil {
            _high = Reg8(self, true)
        }
        return _high!
    }

    func low() -> Reg8 {
        if _low == nil {
            _low = Reg8(self, false)
        }
        return _low!
    }

    // MARK: - Internal

    private let name: String
    private var value: UInt16 = 0
    private var _high: Reg8?
    private var _low: Reg8?

    convenience init(_ name: String) {
        self.init(name, 0)
    }

    init(_ name: String, _ initialValue: UInt16) {
        self.name = name
        setValue(initialValue)
    }
}
