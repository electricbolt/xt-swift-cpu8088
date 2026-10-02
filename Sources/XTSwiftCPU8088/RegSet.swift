// RegSet.swift
// XT Copyright © 2025-2026; Electric Bolt Limited.

import Foundation

public class RegSet: CustomStringConvertible {

    public let flags = Flags()
    public let AX = Reg16("AX")         // Accumulator
    public let AL: Reg8
    public let AH: Reg8
    public let BX = Reg16("BX")         // Base
    public let BL: Reg8
    public let BH: Reg8
    public let CX = Reg16("CX")         // Counting
    public let CL: Reg8
    public let CH: Reg8
    public let DX = Reg16("DX") // Data
    public let DL: Reg8
    public let DH: Reg8
    public let SP = Reg16("SP")
    public let BP = Reg16("BP")
    public let SI = Reg16("SI")
    public let DI = Reg16("DI")
    public let IP = Reg16("IP", 0xFFF0)
    public let CS = Reg16("CS", 0xF000) // Code segment
    public let DS = Reg16("DS")         // Data segment
    public let SS = Reg16("SS")         // Stack segment
    public let ES = Reg16("ES")         // Extra segment

    public init() {
        AL = AX.low()
        AH = AX.high()
        BL = BX.low()
        BH = BX.high()
        CL = CX.low()
        CH = CX.high()
        DL = DX.low()
        DH = DX.high()
    }

    public var description: String {
        return "\(CS) \(IP) \(AX) \(BX) \(CX) \(DX) \(SI) \(DI) \(BP) \(SP) \(DS) \(ES) \(SS) \(flags)"
    }
}
