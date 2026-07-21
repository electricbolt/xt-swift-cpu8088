// ExampleTests.swift
// XT Copyright © 2026; Electric Bolt Limited.

import Testing
@testable import XTSwiftCPU8088

class ExampleTests : CPUDelegateAdapter {

    @Test
    public func add() {
        let cpu = CPU(delegate: self)

        cpu.reg.AX.setValue(0x10)
        cpu.reg.CS.setValue(0x1000)
        cpu.reg.IP.setValue(0x0000)

        cpu.memory.setByte(SegOfs(0x1000, 0x0000), 0x05) // ADD AX,imm16
        cpu.memory.setByte(SegOfs(0x1000, 0x0001), 0x10) //   imm16 lo byte
        cpu.memory.setByte(SegOfs(0x1000, 0x0002), 0x00) //   imm16 hi byte

        cpu.execute(1)

        #expect(cpu.reg.AX.getValue() == 0x20)
    }
}
