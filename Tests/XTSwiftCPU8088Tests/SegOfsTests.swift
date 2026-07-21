// SegOfsTests.swift
// XT Copyright © 2025-2026; Electric Bolt Limited.

import Testing
@testable import XTSwiftCPU8088

struct SegOfsTests {

    @Test
    func segOfsTests() {
        #expect(SegOfs(0x0000, 0x0000).toLinearAddress() == 0x00000)
        #expect(SegOfs(0x0000, 0x0001).toLinearAddress() == 0x00001)
        #expect(SegOfs(0x0001, 0x0001).toLinearAddress() == 0x00011)
        #expect(SegOfs(0x400E, 0xCCE9).toLinearAddress() == 0x4CDC9)
        #expect(SegOfs(0xB800, 0x0000).toLinearAddress() == 0xB8000)
        #expect(SegOfs(0xB800, 0x0001).toLinearAddress() == 0xB8001)
        #expect(SegOfs(0xB800, 0xFFFE).toLinearAddress() == 0xC7FFE)
        #expect(SegOfs(0xB800, 0xFFFF).toLinearAddress() == 0xC7FFF)
        #expect(SegOfs(0xFFFF, 0xFFFF).toLinearAddress() == 0x0FFEF) // Linear address wraps around to 0.

        #expect(SegOfs(0xB800, 0xFFFE).description == "B800:FFFE (C7FFE 819198)")
    }

    @Test
    func segOfsTestsWithOffset() {
        let segOfs = SegOfs(0xB800, 0x0000)
        segOfs.addOffset(0x0000)
        #expect(segOfs.getOffset() == 0x0000)
        segOfs.addOffset(0x0001)
        #expect(segOfs.getOffset() == 0x0001)
        segOfs.addOffset(0x0001)
        #expect(segOfs.getOffset() == 0x0002)

        segOfs.addOffset(0x0010)
        #expect(segOfs.getOffset() == 0x0012)

        segOfs.addOffset(0x0010)
        #expect(segOfs.getOffset() == 0x0022)

        segOfs.setOffset(0x0000)
        #expect(segOfs.getOffset() == 0x0000)
        segOfs.addOffset(UInt16(bitPattern: -1))
        #expect(segOfs.getOffset() == 0xFFFF)
        segOfs.addOffset(UInt16(bitPattern: -1))
        #expect(segOfs.getOffset() == 0xFFFE)
        segOfs.addOffset(3)
        #expect(segOfs.getOffset() == 0x0001)

        segOfs.increment()
        #expect(segOfs.getOffset() == 0x0002)

        segOfs.decrement()
        #expect(segOfs.getOffset() == 0x0001)
    }
}
