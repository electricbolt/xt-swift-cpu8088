// Flags.swift
// XT Copyright © 2025-2026; Electric Bolt Limited.

import Foundation

public class Flags: Equatable, Hashable, CustomStringConvertible {

    public static let CARRY: UInt16 = 0x0001
    public static let RESERVED1: UInt16 = 0x0002 // Always one.
    public static let PARITY: UInt16 = 0x0004
    public static let RESERVED2: UInt16 = 0x0008 // Always zero.
    public static let AUX_CARRY: UInt16 = 0x0010
    public static let RESERVED3: UInt16 = 0x0020 // Always zero.
    public static let ZERO: UInt16 = 0x0040
    public static let SIGN: UInt16 = 0x0080
    public static let TRAP: UInt16 = 0x0100
    public static let INTERRUPT_ENABLE: UInt16 = 0x0200
    public static let DIRECTION: UInt16 = 0x0400
    public static let OVERFLOW: UInt16 = 0x0800
    public static let RESERVED4: UInt16 = 0x1000 // Always one.
    public static let RESERVED5: UInt16 = 0x2000 // Always one.
    public static let RESERVED6: UInt16 = 0x4000 // Always one.
    public static let RESERVED7: UInt16 = 0x8000 // Always one.

    public static let ALWAYS_ONE_MASK16: UInt16 = RESERVED7 | RESERVED6 | RESERVED5 | RESERVED4 | RESERVED1
    public static let ALWAYS_ZERO_MASK16: UInt16 = RESERVED3 | RESERVED2
    public static let FLAG_MASK16: UInt16 = OVERFLOW | DIRECTION | INTERRUPT_ENABLE | TRAP | SIGN | ZERO | AUX_CARRY | PARITY | CARRY

    public init() {
        value = Flags.ALWAYS_ONE_MASK16
    }

    public func setValue8(_ value: UInt8) {
        var value16 = getValue16() & 0xFF00
        value16 |= UInt16(value)
        setValue16(value16)
    }

    public func getValue8() -> UInt8 {
        return UInt8(getValue16() & 0x00FF)
    }

    public func setValue16(_ value: UInt16) {
        self.value = ((value & Flags.FLAG_MASK16) | Flags.ALWAYS_ONE_MASK16) & ~Flags.ALWAYS_ZERO_MASK16
    }

    public func getValue16() -> UInt16 {
        return value
    }

    public func getName() -> String {
        return "FLAGS"
    }

    public var description: String {
        return ("FLAGS=" +
                (isOverflow() ? "OF " : "") +
                (isDirectionDown() ? "DF " : "") +
                (isInterruptEnabled() ? "IF " : "") +
                (isTrapEnabled() ? "TF " : "") +
                (isSignNegative() ? "SF " : "") +
                (isZero() ? "ZF " : "") +
                (isAuxiliaryCarry() ? "AF " : "") +
                (isParityEven() ? "PF " : "") +
                (isCarry() ? "CF " : "")).trimmingCharacters(in: .whitespaces)
    }

    public static func == (lhs: Flags, rhs: Flags) -> Bool {
        return lhs.value == rhs.value
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }

    public func setCarry(_ carry: Bool) {
        if carry {
            value |= Flags.CARRY
        } else {
            value &= ~Flags.CARRY
        }
    }

    public func isCarry() -> Bool {
        return (value & Flags.CARRY) == Flags.CARRY
    }

    public func isNotCarry() -> Bool {
        return (value & Flags.CARRY) == 0
    }

    public func setParityEven(_ even: Bool) {
        if even {
            value |= Flags.PARITY
        } else {
            value &= ~Flags.PARITY
        }
    }

    public func isParityEven() -> Bool {
        return (value & Flags.PARITY) == Flags.PARITY
    }

    public func isParityOdd() -> Bool {
        return (value & Flags.PARITY) == 0
    }

    public func setAuxiliaryCarry(_ carry: Bool) {
        if carry {
            value |= Flags.AUX_CARRY
        } else {
            value &= ~Flags.AUX_CARRY
        }
    }

    public func isAuxiliaryCarry() -> Bool {
        return (value & Flags.AUX_CARRY) == Flags.AUX_CARRY
    }

    public func isNotAuxiliaryCarry() -> Bool {
        return (value & Flags.AUX_CARRY) == 0
    }

    public func setZero(_ zero: Bool) {
        if zero {
            value |= Flags.ZERO
        } else {
            value &= ~Flags.ZERO
        }
    }

    public func isZero() -> Bool {
        return (value & Flags.ZERO) == Flags.ZERO
    }

    public func isNotZero() -> Bool {
        return (value & Flags.ZERO) == 0
    }

    public func setSignNegative(_ sign: Bool) {
        if sign {
            value |= Flags.SIGN
        } else {
            value &= ~Flags.SIGN
        }
    }

    public func isSignNegative() -> Bool {
        return (value & Flags.SIGN) == Flags.SIGN
    }

    public func isSignPositive() -> Bool {
        return (value & Flags.SIGN) == 0
    }

    public func setTrapEnabled(_ trap: Bool) {
        if trap {
            value |= Flags.TRAP
        } else {
            value &= ~Flags.TRAP
        }
    }

    public func isTrapEnabled() -> Bool {
        return (value & Flags.TRAP) == Flags.TRAP
    }

    public func isTrapDisabled() -> Bool {
        return (value & Flags.TRAP) == 0
    }

    public func setInterruptEnabled(_ enabled: Bool) {
        if enabled {
            value |= Flags.INTERRUPT_ENABLE
        } else {
            value &= ~Flags.INTERRUPT_ENABLE
        }
    }

    public func isInterruptEnabled() -> Bool {
        return (value & Flags.INTERRUPT_ENABLE) == Flags.INTERRUPT_ENABLE
    }

    public func isInterruptDisabled() -> Bool {
        return (value & Flags.INTERRUPT_ENABLE) == 0
    }

    public func setDirectionDown(_ down: Bool) {
        if down {
            value |= Flags.DIRECTION
        } else {
            value &= ~Flags.DIRECTION
        }
    }

    public func isDirectionDown() -> Bool {
        return (value & Flags.DIRECTION) == Flags.DIRECTION
    }

    public func isDirectionUp() -> Bool {
        return (value & Flags.DIRECTION) == 0
    }

    public func setOverflow(_ overflow: Bool) {
        if overflow {
            value |= Flags.OVERFLOW
        } else {
            value &= ~Flags.OVERFLOW
        }
    }

    public func isOverflow() -> Bool {
        return (value & Flags.OVERFLOW) == Flags.OVERFLOW
    }

    public func isNotOverflow() -> Bool {
        return (value & Flags.OVERFLOW) == 0
    }

    // MARK: - Internal

    private var value: UInt16
}
