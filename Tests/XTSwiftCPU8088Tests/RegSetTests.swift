// RegSetTests.swift
// XT Copyright © 2025-2026; Electric Bolt Limited.

import Testing
@testable import XTSwiftCPU8088

struct RegSetTests {

    @Test
    func setValueTests() {
        let reg = RegSet()
        #expect(reg.description == "CS=F000 IP=FFF0 FLAGS= AX=0000 BX=0000 CX=0000 DX=0000 DS=0000 SI=0000 ES=0000 DI=0000 SS=0000 SP=0000 BP=0000")

        reg.flags.setValue16(0xFFFF)
        reg.AX.setValue(0x1234)
        reg.BX.setValue(0x5678)
        reg.CX.setValue(0x9ABC)
        reg.DX.setValue(0xDEF0)
        reg.DS.setValue(0x4321)
        reg.SI.setValue(0x8765)
        reg.ES.setValue(0xCBA9)
        reg.DI.setValue(0x0FED)
        reg.SS.setValue(0x1020)
        reg.SP.setValue(0x3040)
        reg.BP.setValue(0x5060)
        reg.CS.setValue(0x9988)
        reg.IP.setValue(0x7766)
        #expect(reg.description == "CS=9988 IP=7766 FLAGS=OF DF IF TF SF ZF AF PF CF AX=1234 BX=5678 CX=9ABC DX=DEF0 DS=4321 SI=8765 ES=CBA9 DI=0FED SS=1020 SP=3040 BP=5060")
    }
}
