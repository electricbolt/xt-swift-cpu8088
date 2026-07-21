// CPU+StringInstructions.swift
// XT Copyright © 2025-2026; Electric Bolt Limited.

import Foundation

extension CPU {

    private typealias StringFunction = () -> Void

    private func loopCXNZ(_ function: StringFunction) {
        if isRepeating {
            while reg.CX.getValue() != 0 {
                function()
                reg.CX.add(0xFFFF)
                if let repeatFlag = repeatFlag, reg.flags.isZero() != repeatFlag {
                    break
                }
            }
        } else {
            function()
        }
    }

    /// SCASB - Compare bytes AL - ES:[DI].

    func scan8() {
        loopCXNZ {
            let dstSegOfs = SegOfs(reg.ES, reg.DI)
            _ = sub8(reg.AL.getValue(), memory.readByte(dstSegOfs), false)
            reg.DI.add(reg.flags.isDirectionDown() ? 0xFFFF : 1)
        }
    }

    /// SCASW - Compare words AX - ES:[DI].

    func scan16() {
        loopCXNZ {
            let dstSegOfs = SegOfs(reg.ES, reg.DI)
            _ = sub16(reg.AX.getValue(), memory.readWord(dstSegOfs), false)
            reg.DI.add(reg.flags.isDirectionDown() ? 0xFFFE : 2)
        }
    }

    /// LODSB - Load byte DS:[SI] into AL.

    func load8() {
        repeatFlag = nil
        loopCXNZ {
            let srcSegOfs = SegOfs(segmentOverride ?? reg.DS, reg.SI)
            reg.AL.setValue(memory.readByte(srcSegOfs))
            reg.SI.add(reg.flags.isDirectionDown() ? 0xFFFF : 1)
        }
    }

    /// LODSW - Load word DS:[SI] into AX.

    func load16() {
        repeatFlag = nil
        loopCXNZ {
            let srcSegOfs = SegOfs(segmentOverride ?? reg.DS, reg.SI)
            reg.AX.setValue(memory.readWord(srcSegOfs))
            reg.SI.add(reg.flags.isDirectionDown() ? 0xFFFE : 2)
        }
    }

    /// STOSB - Store AL in byte ES:[DI].

    func store8() {
        repeatFlag = nil
        loopCXNZ {
            let dstSegOfs = SegOfs(reg.ES, reg.DI)
            memory.writeByte(dstSegOfs, reg.AL.getValue())
            reg.DI.add(reg.flags.isDirectionDown() ? 0xFFFF : 1)
        }
    }

    /// STOSW - Store AX in word ES:[DI].

    func store16() {
        repeatFlag = nil
        loopCXNZ {
            let dstSegOfs = SegOfs(reg.ES, reg.DI)
            memory.writeWord(dstSegOfs, reg.AX.getValue())
            reg.DI.add(reg.flags.isDirectionDown() ? 0xFFFE : 2)
        }
    }

    /// CMPSB - Compare bytes DS:[SI] with ES:[DI].
    ///
    /// Compare byte at DS:SI with ES:DI. DS can be overridden with a segment prefix.
    /// SI and DI increment or decrement based upon the direction flag.

    func compare8() {
        loopCXNZ {
            let srcSegOfs = SegOfs(segmentOverride ?? reg.DS, reg.SI)
            let dstSegOfs = SegOfs(reg.ES, reg.DI)
            _ = sub8(memory.readByte(srcSegOfs), memory.readByte(dstSegOfs), false)
            reg.DI.add(reg.flags.isDirectionDown() ? 0xFFFF : 1)
            reg.SI.add(reg.flags.isDirectionDown() ? 0xFFFF : 1)
        }
    }

    /// CMPSW - Compare words DS:[SI] with ES:[DI].
    ///
    /// Compare word at DS:SI with ES:DI. DS can be overridden with a segment prefix.
    /// SI and DI increment or decrement based upon the direction flag.

    func compare16() {
        loopCXNZ {
            let srcSegOfs = SegOfs(segmentOverride ?? reg.DS, reg.SI)
            let dstSegOfs = SegOfs(reg.ES, reg.DI)
            _ = sub16(memory.readWord(srcSegOfs), memory.readWord(dstSegOfs), false)
            reg.DI.add(reg.flags.isDirectionDown() ? 0xFFFE : 2)
            reg.SI.add(reg.flags.isDirectionDown() ? 0xFFFE : 2)
        }
    }

    /// MOVSB - Move byte SS:[SI] to ES:[DI].
    ///
    /// Move byte from DS:SI to ES:DI. DS can be overridden with a segment prefix.
    /// SI and DI increment or decrement based upon the direction flag.

    func move8() {
        repeatFlag = nil
        loopCXNZ {
            let srcSegOfs = SegOfs(segmentOverride ?? reg.DS, reg.SI)
            let dstSegOfs = SegOfs(reg.ES, reg.DI)
            memory.writeByte(dstSegOfs, memory.readByte(srcSegOfs))
            reg.DI.add(reg.flags.isDirectionDown() ? 0xFFFF : 1)
            reg.SI.add(reg.flags.isDirectionDown() ? 0xFFFF : 1)
        }
    }

    /// MOVSW - Move word DS:[SI] to ES:[DI].
    ///
    /// Move word from DS:SI to ES:DI. DS can be overridden with a segment prefix.
    /// SI and DI increment or decrement based upon the direction flag.

    func move16() {
        repeatFlag = nil
        loopCXNZ {
            let srcSegOfs = SegOfs(segmentOverride ?? reg.DS, reg.SI)
            let dstSegOfs = SegOfs(reg.ES, reg.DI)
            memory.writeWord(dstSegOfs, memory.readWord(srcSegOfs))
            reg.DI.add(reg.flags.isDirectionDown() ? 0xFFFE : 2)
            reg.SI.add(reg.flags.isDirectionDown() ? 0xFFFE : 2)
        }
    }
}
