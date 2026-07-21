// CPU+ALU.swift
// XT Copyright © 2025-2026; Electric Bolt Limited.

import Foundation

/// Thrown when a quotient overflows (or a divisor is zero) during a divide operation.

struct ArithmeticError: Error {
    let message: String

    init(_ message: String) {
        self.message = message
    }
}

/// Arithmetic logic unit performs arithmetic (addition, subtraction, multiplication, division) and logical operations
/// (and, or, not, xor).

extension CPU {

    func add8(_ a: UInt8, _ b: UInt8, _ carry: Bool) -> UInt8 {
        let result = Int(a) + Int(b) + (carry ? 1 : 0)
        // The overflow flag is set when the most significant bit is changed by adding two numbers with the same sign.
        reg.flags.setOverflow(((Int(a) & 0x80) == (Int(b) & 0x80)) && (result & 0x80) != (Int(a) & 0x80))
        reg.flags.setSignNegative((result & 0x80) == 0x80)
        reg.flags.setZero((result & 0xFF) == 0)
        reg.flags.setAuxiliaryCarry((Int(a) & 0xF) + (Int(b) & 0xF) + (carry ? 1 : 0) > 0xF)
        reg.flags.setParityEven(Parity8.isEven(result))
        reg.flags.setCarry(result > 0xFF)
        return UInt8(truncatingIfNeeded: result)
    }

    func add16(_ a: UInt16, _ b: UInt16, _ carry: Bool) -> UInt16 {
        let result = Int(a) + Int(b) + (carry ? 1 : 0)
        // The overflow flag is set when the most significant bit is changed by adding two numbers with the same sign.
        reg.flags.setOverflow(((Int(a) & 0x8000) == (Int(b) & 0x8000)) && (result & 0x8000) != (Int(a) & 0x8000))
        reg.flags.setSignNegative((result & 0x8000) == 0x8000)
        reg.flags.setZero((result & 0xFFFF) == 0)
        reg.flags.setAuxiliaryCarry((Int(a) & 0xF) + (Int(b) & 0xF) + (carry ? 1 : 0) > 0xF)
        reg.flags.setParityEven(Parity8.isEven(result & 0xFF))
        reg.flags.setCarry((result & 0xFFFFF) > 0xFFFF)
        return UInt16(truncatingIfNeeded: result)
    }

    func sub8(_ a: UInt8, _ b: UInt8, _ carry: Bool) -> UInt8 {
        let result = Int(a) - Int(b) - (carry ? 1 : 0)
        // The overflow flag is set when the most significant bit is changed by subtracting two numbers with different
        // signs.
        reg.flags.setOverflow(((Int(a) & 0x80) != (Int(b) & 0x80)) && (result & 0x80) != (Int(a) & 0x80))
        reg.flags.setSignNegative((result & 0x80) == 0x80)
        reg.flags.setZero((result & 0xFF) == 0)
        reg.flags.setAuxiliaryCarry((Int(a) & 0xF) - (Int(b) & 0xF) - (carry ? 1 : 0) < 0)
        reg.flags.setParityEven(Parity8.isEven(result))
        reg.flags.setCarry((result & 0xFFF) > 0xFF)
        return UInt8(truncatingIfNeeded: result)
    }

    func sub16(_ a: UInt16, _ b: UInt16, _ carry: Bool) -> UInt16 {
        let result = Int(a) - Int(b) - (carry ? 1 : 0)
        // The overflow flag is set when the most significant bit is changed by subtracting two numbers with different
        // signs.
        reg.flags.setOverflow(((Int(a) & 0x8000) != (Int(b) & 0x8000)) && (result & 0x8000) != (Int(a) & 0x8000))
        reg.flags.setSignNegative((result & 0x8000) == 0x8000)
        reg.flags.setZero((result & 0xFFFF) == 0)
        reg.flags.setAuxiliaryCarry((Int(a) & 0xF) - (Int(b) & 0xF) - (carry ? 1 : 0) < 0)
        reg.flags.setParityEven(Parity8.isEven(result))
        reg.flags.setCarry((result & 0xFFFFF) > 0xFFFF)
        return UInt16(truncatingIfNeeded: result)
    }

    /// Unsigned 8 bit multiply - https://www.righto.com/2023/03/8086-multiplication-microcode.html

    func mul8(_ a: UInt8, _ b: UInt8) -> UInt16 {
        let result = Int(a) * Int(b)
        reg.flags.setOverflow(result >> 8 != 0)
        reg.flags.setCarry(result >> 8 != 0)
        reg.flags.setSignNegative((result & 0x8000) == 0x8000)
        reg.flags.setZero(result >> 8 == 0)
        reg.flags.setAuxiliaryCarry(false)
        reg.flags.setParityEven(Parity8.isEven(result >> 8))
        return UInt16(truncatingIfNeeded: result)
    }

    /// Signed 8 bit multiply - https://www.righto.com/2023/03/8086-multiplication-microcode.html
    ///
    /// The overflow and carry flags are cleared when AL has been sign extended into AX. To calculate if AL
    /// was sign extended, the IMUL instruction internally uses an ADC operation. The undocumented parity, sign,
    /// auxiliary carry and zero flags are the result of this ADC operation. See IMULCOF section of the linked website.

    func imul8(_ a: UInt8, _ b: UInt8) -> UInt16 {
        let result = Int(Int8(bitPattern: a)) * Int(Int8(bitPattern: b))
        _ = add8(UInt8(truncatingIfNeeded: result >> 8), 0, ((result & 0x80) == 0x80))
        reg.flags.setOverflow(reg.flags.isNotZero())
        reg.flags.setCarry(reg.flags.isNotZero())
        return UInt16(truncatingIfNeeded: result)
    }

    /// Unsigned 8 bit divide - https://www.righto.com/2023/04/reverse-engineering-8086-divide-microcode.html
    ///
    /// Without implementing the full microcode of an 8088 for the DIV instruction, it's not possible to calculate
    /// the undocumented flags to pass the single step tests.
    ///
    /// - Throws ArithmeticError: if quotient overflows or divisor is zero.

    func div8(_ dividend: UInt16, _ divisor: UInt8) throws -> UInt16 {
        if divisor == 0 {
            throw ArithmeticError("/ by zero")
        }
        let quotient = Int(dividend) / Int(divisor)
        if quotient > 0xFF {
            throw ArithmeticError("Quotient overflow")
        }
        let remainder = Int(dividend) % Int(divisor)
        let result = (remainder << 8) | (quotient & 0xFF)
        reg.flags.setOverflow(false)
        reg.flags.setCarry(false)
        reg.flags.setSignNegative(false)
        reg.flags.setAuxiliaryCarry(false)
        reg.flags.setZero(false)
        reg.flags.setParityEven(false)
        return UInt16(truncatingIfNeeded: result)
    }

    /// Signed 8 bit divide - https://www.righto.com/2023/04/reverse-engineering-8086-divide-microcode.html
    ///
    /// Without implementing the full microcode of an 8088 for the DIV instruction, it's not possible to calculate
    /// the undocumented flags to pass the single step tests.
    ///
    /// - Parameter negateQuotient: set to true if idiv8 was preceded by a REP instruction, which negates the quotient.
    /// - Throws ArithmeticError: if quotient overflows or divisor is zero.

    func idiv8(_ dividend: UInt16, _ divisor: UInt8, _ negateQuotient: Bool) throws -> UInt16 {
        if divisor == 0 {
            throw ArithmeticError("/ by zero")
        }
        var quotient = Int(Int16(bitPattern: dividend)) / Int(Int8(bitPattern: divisor))
        if quotient > 127 || quotient < -127 {
            throw ArithmeticError("Quotient overflow")
        }
        if negateQuotient {
            quotient = -quotient
        }
        let remainder = Int(Int16(bitPattern: dividend)) % Int(Int8(bitPattern: divisor))
        let result = (remainder << 8) | (quotient & 0xFF)
        reg.flags.setOverflow(false)
        reg.flags.setCarry(false)
        reg.flags.setSignNegative(false)
        reg.flags.setAuxiliaryCarry(false)
        reg.flags.setZero(false)
        reg.flags.setParityEven(false)
        return UInt16(truncatingIfNeeded: result)
    }

    /// Unsigned 16 bit divide.
    ///
    /// https://www.righto.com/2023/04/reverse-engineering-8086-divide-microcode.html
    /// Without implementing the full microcode of an 8088 for the DIV instruction, it's not possible to calculate
    /// the undocumented flags to pass the single step tests.
    ///
    /// - Throws ArithmeticError: if quotient overflows or divisor is zero.

    func div16(_ dividend: UInt32, _ divisor: UInt16) throws -> UInt32 {
        if divisor == 0 {
            throw ArithmeticError("/ by zero")
        }
        let quotient = Int(dividend) / Int(divisor)
        if quotient > 0xFFFF {
            throw ArithmeticError("Quotient overflow")
        }
        let remainder = Int(dividend) % Int(divisor)
        let result = (remainder << 16) | (quotient & 0xFFFF)
        reg.flags.setOverflow(false)
        reg.flags.setCarry(false)
        reg.flags.setSignNegative(false)
        reg.flags.setAuxiliaryCarry(false)
        reg.flags.setZero(false)
        reg.flags.setParityEven(false)
        return UInt32(truncatingIfNeeded: result)
    }

    /// Signed 16 bit divide.
    ///
    /// https://www.righto.com/2023/04/reverse-engineering-8086-divide-microcode.html
    /// Without implementing the full microcode of an 8088 for the DIV instruction, it's not possible to calculate
    /// the undocumented flags to pass the single step tests.
    ///
    /// - Parameter negateQuotient: set to true if idiv8 was preceded by a REP instruction, which negates the quotient.
    /// - Throws ArithmeticError: if quotient overflows or divisor is zero.

    func idiv16(_ dividend: UInt32, _ divisor: UInt16, _ negateQuotient: Bool) throws -> UInt32 {
        if divisor == 0 {
            throw ArithmeticError("/ by zero")
        }
        var quotient = Int(Int32(bitPattern: dividend)) / Int(Int16(bitPattern: divisor))
        if quotient > 32767 || quotient < -32767 {
            throw ArithmeticError("Quotient overflow")
        }
        if negateQuotient {
            quotient = -quotient
        }
        let remainder = Int(Int32(bitPattern: dividend)) % Int(Int16(bitPattern: divisor))
        let result = (remainder << 16) | (quotient & 0xFFFF)
        reg.flags.setOverflow(false)
        reg.flags.setCarry(false)
        reg.flags.setSignNegative(false)
        reg.flags.setAuxiliaryCarry(false)
        reg.flags.setZero(false)
        reg.flags.setParityEven(false)
        return UInt32(truncatingIfNeeded: result)
    }

    /// Unsigned 16 bit multiply.

    func mul16(_ a: UInt16, _ b: UInt16) -> UInt32 {
        let result = Int(a) * Int(b)
        reg.flags.setOverflow(result >> 16 != 0)
        reg.flags.setCarry(result >> 16 != 0)
        reg.flags.setSignNegative((result & 0x80000000) == 0x80000000)
        reg.flags.setZero(result >> 16 == 0)
        reg.flags.setAuxiliaryCarry(false)
        reg.flags.setParityEven(Parity8.isEven(result >> 16))
        return UInt32(truncatingIfNeeded: result)
    }

    /// Signed 16 bit multiply.
    ///
    /// The overflow and carry flags are cleared when AX has been sign extended into DX:AX. To calculate if AX
    /// was sign extended, the IMUL instruction internally uses an ADC operation. The undocumented parity, sign,
    /// auxiliary carry and zero flags are the result of this ADC operation. See
    /// 
    /// https://www.righto.com/2023/03/8086-multiplication-microcode.html IMULCOF section.

    func imul16(_ a: UInt16, _ b: UInt16) -> UInt32 {
        let result = Int(Int16(bitPattern: a)) * Int(Int16(bitPattern: b))
        _ = add16(UInt16(truncatingIfNeeded: result >> 16), 0, ((result & 0x8000) == 0x8000))
        reg.flags.setOverflow(reg.flags.isNotZero())
        reg.flags.setCarry(reg.flags.isNotZero())
        return UInt32(truncatingIfNeeded: result)
    }

    func or8(_ a: UInt16, _ b: UInt16) -> UInt8 {
        let result = (Int(a) & 0xFF) | (Int(b) & 0xFF)
        reg.flags.setOverflow(false)
        reg.flags.setSignNegative((result & 0x80) == 0x80)
        reg.flags.setZero((result & 0xFF) == 0)
        reg.flags.setAuxiliaryCarry(false)
        reg.flags.setParityEven(Parity8.isEven(result))
        reg.flags.setCarry(false)
        return UInt8(truncatingIfNeeded: result)
    }

    func or16(_ a: UInt16, _ b: UInt16) -> UInt16 {
        let result = (Int(a) & 0xFFFF) | (Int(b) & 0xFFFF)
        reg.flags.setOverflow(false)
        reg.flags.setSignNegative((result & 0x8000) == 0x8000)
        reg.flags.setZero((result & 0xFFFF) == 0)
        reg.flags.setAuxiliaryCarry(false)
        reg.flags.setParityEven(Parity8.isEven(result))
        reg.flags.setCarry(false)
        return UInt16(truncatingIfNeeded: result)
    }

    func and8(_ a: UInt16, _ b: UInt16) -> UInt8 {
        let result = (Int(a) & 0xFF) & (Int(b) & 0xFF)
        reg.flags.setOverflow(false)
        reg.flags.setSignNegative((result & 0x80) == 0x80)
        reg.flags.setZero((result & 0xFF) == 0)
        reg.flags.setAuxiliaryCarry(false)
        reg.flags.setParityEven(Parity8.isEven(result))
        reg.flags.setCarry(false)
        return UInt8(truncatingIfNeeded: result)
    }

    func and16(_ a: UInt16, _ b: UInt16) -> UInt16 {
        let result = (Int(a) & 0xFFFF) & (Int(b) & 0xFFFF)
        reg.flags.setOverflow(false)
        reg.flags.setSignNegative((result & 0x8000) == 0x8000)
        reg.flags.setZero((result & 0xFFFF) == 0)
        reg.flags.setAuxiliaryCarry(false)
        reg.flags.setParityEven(Parity8.isEven(result))
        reg.flags.setCarry(false)
        return UInt16(truncatingIfNeeded: result)
    }

    func xor8(_ a: UInt16, _ b: UInt16) -> UInt8 {
        let result = (Int(a) & 0xFF) ^ (Int(b) & 0xFF)
        reg.flags.setOverflow(false)
        reg.flags.setSignNegative((result & 0x80) == 0x80)
        reg.flags.setZero((result & 0xFF) == 0)
        reg.flags.setAuxiliaryCarry(false)
        reg.flags.setParityEven(Parity8.isEven(result))
        reg.flags.setCarry(false)
        return UInt8(truncatingIfNeeded: result)
    }

    func xor16(_ a: UInt16, _ b: UInt16) -> UInt16 {
        let result = (Int(a) & 0xFFFF) ^ (Int(b) & 0xFFFF)
        reg.flags.setOverflow(false)
        reg.flags.setSignNegative((result & 0x8000) == 0x8000)
        reg.flags.setZero((result & 0xFFFF) == 0)
        reg.flags.setAuxiliaryCarry(false)
        reg.flags.setParityEven(Parity8.isEven(result))
        reg.flags.setCarry(false)
        return UInt16(truncatingIfNeeded: result)
    }
}
