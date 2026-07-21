// MemoryTests.swift
// XT Copyright © 2025-2026; Electric Bolt Limited.

import Testing
@testable import XTSwiftCPU8088

struct MemoryTests {

    @Test
    func putDataTests() {
        let memory = Memory(zeroMemory: true)
        memory.putLinearData(3, [0x13, 0x24, 0x35, 0x7E, 0x7F, 0x80, 0xFE, 0xFF], 0, 8)
        #expect(memory.buf[1] == 0)
        #expect(memory.buf[3] == 0x13)
        #expect(memory.buf[4] == 0x24)
        #expect(memory.buf[5] == 0x35)
        #expect(memory.buf[6] == 0x7E)
        #expect(memory.buf[7] == 0x7F)
        #expect(memory.buf[8] == 0x80)
        #expect(memory.buf[9] == 0xFE)
        #expect(memory.buf[10] == 0xFF)
        #expect(memory.buf[11] == 0)
    }

    @Test
    func byteTests() {
        let memory = Memory()

        memory.putLinearData(3, [0x13, 0x24, 0x35, 0x7E], 0, 4)
        #expect(memory.buf[3] == 0x13)
        #expect(memory.buf[4] == 0x24)
        #expect(memory.buf[5] == 0x35)
        #expect(memory.buf[6] == 0x7E)

        let _0000_0000 = SegOfs(0x0000, 0x0000) // 0 first byte of addressable memory.
        memory.writeByte(_0000_0000, 0x69)
        #expect(memory.buf[0] == 0x69)
        #expect(memory.readByte(_0000_0000) == 0x69)

        let _B800_F319 = SegOfs(0xB800, 0xF319)
        memory.writeByte(_B800_F319, 0x89)
        #expect(memory.buf[815897] == 0x89)
        #expect(memory.readByte(_B800_F319) == 0x89)

        let _FFFF_000F = SegOfs(0xFFFF, 0x000F) // 1048575 last byte of addressable memory.
        memory.writeByte(_FFFF_000F, 0xFE)
        #expect(memory.buf[1048575] == 0xFE)
        #expect(memory.readByte(_FFFF_000F) == 0xFE)

        let _FFFF_0010 = SegOfs(0xFFFF, 0x0010) // 1048576 -> 0 wraps around to first byte of addressable memory.
        memory.writeByte(_FFFF_0010, 0x9E)
        #expect(memory.buf[0] == 0x9E)
        #expect(memory.readByte(_FFFF_0010) == 0x9E)
    }

    @Test
    func wordTests() {
        let memory = Memory()

        memory.putLinearData(3, [0x13, 0x24, 0x35, 0x7E], 0, 4)
        #expect(memory.buf[3] == 0x13)
        #expect(memory.buf[4] == 0x24)
        #expect(memory.buf[5] == 0x35)
        #expect(memory.buf[6] == 0x7E)
        #expect(memory.readWord(SegOfs(0x0000, 0x0003)) == 0x2413)
        #expect(memory.readWord(SegOfs(0x0000, 0x0005)) == 0x7E35)

        let _0000_593C = SegOfs(0x0000, 0x593C)
        memory.writeWord(_0000_593C, 0x593C)
        #expect(memory.buf[22844] == 0x3C)
        #expect(memory.buf[22845] == 0x59)
        #expect(memory.readWord(_0000_593C) == 0x593C)

        let _C800_4FE1 = SegOfs(0xC800, 0x4FE1)
        memory.writeWord(_C800_4FE1, 0xFE0A)
        #expect(memory.buf[839649] == 0x0A)
        #expect(memory.buf[839650] == 0xFE)
        #expect(memory.readWord(_C800_4FE1) == 0xFE0A)

        let _FFFF_000F = SegOfs(0xFFFF, 0x000F) // 1048575 last byte of addressable memory.
        memory.writeWord(_FFFF_000F, 0x5533)
        #expect(memory.buf[1048575] == 0x33)
        #expect(memory.buf[0] == 0x55)
        #expect(memory.readWord(_FFFF_000F) == 0x5533)
    }
}
