// FlagsTest.swift
// XT Copyright © 2025-2026; Electric Bolt Limited.

import Testing
@testable import XTSwiftCPU8088

struct FlagsTest {

    @Test
    func flagsAllTest() {
        let flags = Flags()
        #expect(flags.getValue16() == 0xF002)
        flags.setValue16(0xFFFF)
        #expect(flags.getValue16() == 0xFFD7)
        #expect(flags.description == "FLAGS=OF DF IF TF SF ZF AF PF CF")
        #expect(flags.isCarry())
        #expect(flags.isParityEven())
        #expect(!flags.isParityOdd())
        #expect(flags.isAuxiliaryCarry())
        #expect(!flags.isNotAuxiliaryCarry())
        #expect(flags.isZero())
        #expect(!flags.isNotZero())
        #expect(flags.isSignNegative())
        #expect(!flags.isSignPositive())
        #expect(flags.isTrapEnabled())
        #expect(flags.isInterruptEnabled())
        #expect(!flags.isInterruptDisabled())
        #expect(flags.isDirectionDown())
        #expect(!flags.isDirectionUp())
        #expect(flags.isOverflow())
        #expect(!flags.isNotOverflow())

        flags.setValue16(0x0)
        #expect(flags.getValue16() == 0xF002)
        #expect(flags.description == "FLAGS=")
    }

    @Test
    func flags8Test() {
        let flags = Flags()
        #expect(flags.getValue8() == 0x02)
        flags.setValue8(0xFF)
        #expect(flags.getValue16() == 0xF0D7)
        #expect(flags.getValue8() == 0xD7)

        flags.setValue8(0x00)
        #expect(flags.getValue16() == 0xF002)
        #expect(flags.getValue8() == 0x02)
    }

    @Test
    func flagsCarryTest() {
        let flags = Flags()
        flags.setValue16(0x0000)

        #expect(!flags.isCarry())
        #expect(flags.isNotCarry())
        flags.setValue16(0x0001)
        #expect(flags.description == "FLAGS=CF")
        #expect(flags.isCarry())
        #expect(!flags.isNotCarry())

        flags.setValue16(0xFFFF)
        flags.setCarry(false)
        #expect(flags.getValue16() == 0xFFD6)

        flags.setValue16(0x0000)
        flags.setCarry(true)
        #expect(flags.getValue16() == 0xF003)
    }

    @Test
    func flagsParityTest() {
        let flags = Flags()
        flags.setValue16(0x0000)
        #expect(!flags.isParityEven())
        #expect(flags.isParityOdd())
        flags.setValue16(0x0004)
        #expect(flags.description == "FLAGS=PF")
        #expect(flags.isParityEven())
        #expect(!flags.isParityOdd())

        flags.setValue16(0xFFFF)
        flags.setParityEven(false)
        #expect(flags.getValue16() == 0xFFD3)

        flags.setValue16(0x0000)
        flags.setParityEven(true)
        #expect(flags.getValue16() == 0xF006)
    }

    @Test
    func flagsAuxilaryCarryTest() {
        let flags = Flags()
        flags.setValue16(0x0000)
        #expect(!flags.isAuxiliaryCarry())
        #expect(flags.isNotAuxiliaryCarry())
        flags.setValue16(0x0010)
        #expect(flags.description == "FLAGS=AF")
        #expect(flags.isAuxiliaryCarry())
        #expect(!flags.isNotAuxiliaryCarry())

        flags.setValue16(0xFFFF)
        flags.setAuxiliaryCarry(false)
        #expect(flags.getValue16() == 0xFFC7)

        flags.setValue16(0x0000)
        flags.setAuxiliaryCarry(true)
        #expect(flags.getValue16() == 0xF012)
    }

    @Test
    func flagsZeroTest() {
        let flags = Flags()
        flags.setValue16(0x0000)
        #expect(!flags.isZero())
        #expect(flags.isNotZero())
        flags.setValue16(0x0040)
        #expect(flags.description == "FLAGS=ZF")
        #expect(flags.isZero())
        #expect(!flags.isNotZero())

        flags.setValue16(0xFFFF)
        flags.setZero(false)
        #expect(flags.getValue16() == 0xFF97)

        flags.setValue16(0x0000)
        flags.setZero(true)
        #expect(flags.getValue16() == 0xF042)
    }

    @Test
    func flagsSignTest() {
        let flags = Flags()
        flags.setValue16(0x0000)
        #expect(!flags.isSignNegative())
        #expect(flags.isSignPositive())
        flags.setValue16(0x0080)
        #expect(flags.description == "FLAGS=SF")
        #expect(flags.isSignNegative())
        #expect(!flags.isSignPositive())

        flags.setValue16(0xFFFF)
        flags.setSignNegative(false)
        #expect(flags.getValue16() == 0xFF57)

        flags.setValue16(0x0000)
        flags.setSignNegative(true)
        #expect(flags.getValue16() == 0xF082)
    }

    @Test
    func flagsTrapTest() {
        let flags = Flags()
        flags.setValue16(0x0000)
        #expect(!flags.isTrapEnabled())
        #expect(flags.isTrapDisabled())
        flags.setValue16(0x0100)
        #expect(flags.description == "FLAGS=TF")
        #expect(flags.isTrapEnabled())
        #expect(!flags.isTrapDisabled())

        flags.setValue16(0xFFFF)
        flags.setTrapEnabled(false)
        #expect(flags.getValue16() == 0xFED7)

        flags.setValue16(0x0000)
        flags.setTrapEnabled(true)
        #expect(flags.getValue16() == 0xF102)
    }

    @Test
    func flagsInterruptTest() {
        let flags = Flags()
        flags.setValue16(0x0000)
        #expect(!flags.isInterruptEnabled())
        #expect(flags.isInterruptDisabled())
        flags.setValue16(0x0200)
        #expect(flags.description == "FLAGS=IF")
        #expect(flags.isInterruptEnabled())
        #expect(!flags.isInterruptDisabled())

        flags.setValue16(0xFFFF)
        flags.setInterruptEnabled(false)
        #expect(flags.getValue16() == 0xFDD7)

        flags.setValue16(0x0000)
        flags.setInterruptEnabled(true)
        #expect(flags.getValue16() == 0xF202)
    }

    @Test
    func flagsDirectionTest() {
        let flags = Flags()
        flags.setValue16(0x0000)
        #expect(!flags.isDirectionDown())
        #expect(flags.isDirectionUp())
        flags.setValue16(0x0400)
        #expect(flags.description == "FLAGS=DF")
        #expect(flags.isDirectionDown())
        #expect(!flags.isDirectionUp())

        flags.setValue16(0xFFFF)
        flags.setDirectionDown(false)
        #expect(flags.getValue16() == 0xFBD7)

        flags.setValue16(0x0000)
        flags.setDirectionDown(true)
        #expect(flags.getValue16() == 0xF402)
    }

    @Test
    func flagsOverflowTest() {
        let flags = Flags()
        flags.setValue16(0x0000)
        #expect(!flags.isOverflow())
        #expect(flags.isNotZero())
        flags.setValue16(0x0800)
        #expect(flags.description == "FLAGS=OF")
        #expect(flags.isOverflow())
        #expect(!flags.isNotOverflow())

        flags.setValue16(0xFFFF)
        flags.setOverflow(false)
        #expect(flags.getValue16() == 0xF7D7)

        flags.setValue16(0x0000)
        flags.setOverflow(true)
        #expect(flags.getValue16() == 0xF802)
    }
}
