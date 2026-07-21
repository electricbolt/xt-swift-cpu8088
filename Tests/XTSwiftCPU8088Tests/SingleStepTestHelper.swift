// SingleStepTestHelper.swift
// XT Copyright © 2025-2026; Electric Bolt Limited.

import Foundation
import Compression
import Testing
@testable import XTSwiftCPU8088

class SingleStepTestHelper : CPUDelegateAdapter {

    private var opcode: String
    private var opcodeTests = [OpcodeTest]()
    private var excludeFlags: UInt16
    private var interrupted: Int16!
    
    public convenience init(_ opcode: String) {
        self.init(opcode, 0)
    }
    
    public init(_ opcode: String, _ excludeFlags: UInt16) {
        self.opcode = opcode
        self.excludeFlags = excludeFlags
    }
    
    public func load() {
        do {
            var homeDir = NSHomeDirectory()
            if !homeDir.hasSuffix("/") {
                homeDir += "/"
            }
            var dir = try String.init(contentsOf: URL(fileURLWithPath: "\(homeDir).xt8088v2"), encoding: .utf8)
            dir = dir.trimmingCharacters(in: .whitespacesAndNewlines)
            if !dir.hasSuffix("/") {
                dir += "/"
            }
            var data = try Data(contentsOf: URL(filePath: "\(dir)v2/\(opcode).json.gz"))
            data = try data.decompressGzip()
            opcodeTests = try JSONDecoder().decode(Array<OpcodeTest>.self, from: data)
        } catch {
            print("CPUTest opcode \(opcode) skipped - \(error.localizedDescription)")
            return
        }
    }
    
    public func count() -> Int {
        return opcodeTests.count
    }
    
    public func test(_ index: Int) {
        interrupted = -1
        
        let testDTO = opcodeTests[index]
        #expect(testDTO.idx == index, "Opcode \(opcode) test \(index) does not match file index \(testDTO.idx)")
        
        let cpu = CPU(delegate: self)

        // Arrange
        cpu.reg.AX.setValue(testDTO.initial.regs.ax ?? 0)
        cpu.reg.BX.setValue(testDTO.initial.regs.bx ?? 0)
        cpu.reg.CX.setValue(testDTO.initial.regs.cx ?? 0)
        cpu.reg.DX.setValue(testDTO.initial.regs.dx ?? 0)
        cpu.reg.SP.setValue(testDTO.initial.regs.sp ?? 0)
        cpu.reg.BP.setValue(testDTO.initial.regs.bp ?? 0)
        cpu.reg.SI.setValue(testDTO.initial.regs.si ?? 0)
        cpu.reg.DI.setValue(testDTO.initial.regs.di ?? 0)
        cpu.reg.IP.setValue(testDTO.initial.regs.ip ?? 0)
        cpu.reg.CS.setValue(testDTO.initial.regs.cs ?? 0)
        cpu.reg.DS.setValue(testDTO.initial.regs.ds ?? 0)
        cpu.reg.SS.setValue(testDTO.initial.regs.ss ?? 0)
        cpu.reg.ES.setValue(testDTO.initial.regs.es ?? 0)
        cpu.reg.flags.setValue16(testDTO.initial.regs.flags ?? 0)

        for i in 0 ..< testDTO.initial.ram.count {
            let linearAddressValue: [UInt] = testDTO.initial.ram[i]
            let linearAddress: UInt = linearAddressValue[0]
            let value: UInt8 = UInt8(linearAddressValue[1] & 0xFF)
            cpu.memory.setLinearByte(Int(linearAddress), value)
        }
        
        let linearAddress = SegOfs(cpu.reg.CS, cpu.reg.IP).toLinearAddress()
        for i in 0 ..< testDTO.bytes.count {
            cpu.memory.setLinearByte(linearAddress + i, testDTO.bytes[i])
        }
        
        // Act
        cpu.execute(1)
        
        // Assert
        if interrupted == -1 {
            for i in 0 ..< testDTO.final.ram.count {
                let linearAddressValue: [UInt] = testDTO.final.ram[i]
                let linearAddress: UInt = linearAddressValue[0]
                let value1: UInt8 = UInt8(linearAddressValue[1] & 0xFF)
                let value2: UInt8 = cpu.memory.getLinearByte(Int(linearAddress))
                #expect(value1 == value2, "Opcode \(opcode) test \(index) memory[\(linearAddress)] expected \(value1) (\(String(format: "%X", value1))) actual \(value2) (\(String(format: "%X", value2)))")
            }
        }
        
        assertReg(index, testDTO.final.regs.ax, cpu.reg.AX)
        assertReg(index, testDTO.final.regs.bx, cpu.reg.BX)
        assertReg(index, testDTO.final.regs.cx, cpu.reg.CX)
        assertReg(index, testDTO.final.regs.dx, cpu.reg.DX)
        assertReg(index, testDTO.final.regs.sp, cpu.reg.SP)
        assertReg(index, testDTO.final.regs.bp, cpu.reg.BP)
        assertReg(index, testDTO.final.regs.si, cpu.reg.SI)
        assertReg(index, testDTO.final.regs.di, cpu.reg.DI)
        assertReg(index, testDTO.final.regs.ip, cpu.reg.IP)
        assertReg(index, testDTO.final.regs.cs, cpu.reg.CS)
        assertReg(index, testDTO.final.regs.ds, cpu.reg.DS)
        assertReg(index, testDTO.final.regs.ss, cpu.reg.SS)
        assertReg(index, testDTO.final.regs.es, cpu.reg.ES)

        if let flags = testDTO.final.regs.flags {
            let excludedAfterFlags = flags & ~excludeFlags
            let excludedActualFlags = cpu.reg.flags.getValue16() & ~excludeFlags

            let afterFlags = Flags()
            afterFlags.setValue16(excludedAfterFlags)
            
            let actualFlags = Flags()
            actualFlags.setValue16(excludedActualFlags)
            
            #expect(afterFlags == actualFlags, "Opcode \(opcode) test \(index) flags expected \(afterFlags) actual \(actualFlags)")
        }
    }
    
    private func assertReg(_ index: Int, _ expected: UInt16?, _ actual: Reg16) {
        if let expected = expected {
            #expect(expected == actual.getValue(), "Opcode \(opcode) test \(index) register \(actual.getName()) expected \(expected) (\(String(format: "%X", expected))) actual \(actual.getValue()) (\(String(format: "%X", actual.getValue())))")
        }
    }
    
    override func interrupt(_ cpu: CPU, _ value: UInt8) {
        interrupted = Int16(value)
    }
}

/// Decodable that implements the v2 Single Step Tests JSON format.

fileprivate struct OpcodeTest: Decodable {
    let idx: Int
    let name: String
    let bytes: [UInt8]
    let initial: TestSet
    let final: TestSet
    
    struct TestSet: Decodable {
        let regs: TestRegs
        let ram: [[UInt]]
        
        struct TestRegs: Decodable {
            let ax: UInt16?
            let bx: UInt16?
            let cx: UInt16?
            let dx: UInt16?
            let cs: UInt16?
            let ss: UInt16?
            let ds: UInt16?
            let es: UInt16?
            let sp: UInt16?
            let bp: UInt16?
            let si: UInt16?
            let di: UInt16?
            let ip: UInt16?
            let flags: UInt16?
        }
    }
}
