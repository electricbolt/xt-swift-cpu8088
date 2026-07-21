// ModRegRM.swift
// XT Copyright © 2025-2026; Electric Bolt Limited.

import Foundation

/*
 * <code>
 * +---+---+---+---+---+---+---+---+
 * | mod   | reg       | r/m       |
 * +---+---+---+---+---+---+---+---+
 * | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
 * +---+---+---+---+---+---+---+---+
 * <p>
 * +-----------------------+-----+-----+-----+-----+-----+-----+-----+-----+
 * | r8(/r)                | AL  | CL  | DL  | BL  | AH  | CH  | DH  | BH  |
 * | r16(/r)               | AX  | CX  | DX  | BX  | SP  | BP  | SI  | DI  |
 * | reg =                 | 000 | 001 | 010 | 011 | 100 | 101 | 110 | 111 |
 * +-----------------------+-----+-----+-----+-----+-----+-----+-----+-----+
 * <p>
 * +-------------+---------+-----+-----+-----+-----+-----+-----+-----+-----+
 * | Effective   |         | mod reg r/m values in hexadecimal:            |
 * | address     | mod r/m |                                               |
 * +-------------+---------+-----+-----+-----+-----+-----+-----+-----+-----+
 * | [BX+SI]     |     000 |  00 |  08 |  10 |  18 |  20 |  28 |  30 |  38 |
 * | [BX+DI]     |     001 |  01 |  09 |  11 |  19 |  21 |  29 |  31 |  39 |
 * | [BP+SI]     |     010 |  02 |  0A |  12 |  1A |  22 |  2A |  32 |  3A |
 * | [BP+DI]     | 00  011 |  03 |  0B |  13 |  1B |  23 |  2B |  33 |  3B |
 * | [SI]        |     100 |  04 |  0C |  14 |  1C |  24 |  2C |  34 |  3C |
 * | [DI]        |     101 |  05 |  0D |  15 |  1D |  25 |  2D |  35 |  3D |
 * | disp16      |     110 |  06 |  0E |  16 |  1E |  26 |  2E |  36 |  3E |
 * | [BX]        |     111 |  07 |  0F |  17 |  1F |  27 |  2F |  37 |  3F |
 * +-------------+---------+-----+-----+-----+-----+-----+-----+-----+-----+
 * | [BX+SI]+d8  |     000 |  40 |  48 |  50 |  58 |  60 |  68 |  70 |  78 |
 * | [BX+DI]+d8  |     001 |  41 |  49 |  51 |  59 |  61 |  69 |  71 |  79 |
 * | [BP+SI]+d8  |     010 |  42 |  4A |  52 |  5A |  62 |  6A |  72 |  7A |
 * | [BP+DI]+d8  | 01  011 |  43 |  4B |  53 |  5B |  63 |  6B |  73 |  7B |
 * | [SI]+d8     |     100 |  44 |  4C |  54 |  5C |  64 |  6C |  74 |  7C |
 * | [DI]+d8     |     101 |  45 |  4D |  55 |  5D |  65 |  6D |  75 |  7D |
 * | [BP]+d8     |     110 |  46 |  4E |  56 |  5E |  66 |  6E |  76 |  7E |
 * | [BX]+d8     |     111 |  47 |  4F |  57 |  5F |  67 |  6F |  77 |  7F |
 * +-------------+---------+-----+-----+-----+-----+-----+-----+-----+-----+
 * | [BX+SI]+d16 |     000 |  80 |  88 |  90 |  98 |  A0 |  A8 |  B0 |  B8 |
 * | [BX+DI]+d16 |     001 |  81 |  89 |  91 |  99 |  A1 |  A9 |  B1 |  B9 |
 * | [BP+SI]+d16 |     010 |  82 |  8A |  92 |  9A |  A2 |  AA |  B2 |  BA |
 * | [BP+DI]+d16 | 10  011 |  83 |  8B |  93 |  9B |  A3 |  AB |  B3 |  BB |
 * | [SI]+d16    |     100 |  84 |  8C |  94 |  9C |  A4 |  AC |  B4 |  BC |
 * | [DI]+d16    |     101 |  85 |  8D |  95 |  9D |  A5 |  AD |  B5 |  BD |
 * | [BP]+d16    |     110 |  86 |  8E |  96 |  9E |  A6 |  AE |  B6 |  BE |
 * | [BX]+d16    |     111 |  87 |  8F |  97 |  9F |  A7 |  AF |  B7 |  BF |
 * +-------------+---------+-----+-----+-----+-----+-----+-----+-----+-----+
 * | AX  /  AL   |     000 |  C0 |  C8 |  D0 |  D8 |  E0 |  E8 |  F0 |  F8 |
 * | CX  /  CL   |     001 |  C1 |  C9 |  D1 |  D9 |  E1 |  E9 |  F1 |  F9 |
 * | DX  /  DL   |     010 |  C2 |  CA |  D2 |  DA |  E2 |  EA |  F2 |  FA |
 * | BX  /  BL   | 11  011 |  C3 |  CB |  D3 |  DB |  E3 |  EB |  F3 |  FB |
 * | SP  /  AH   |     100 |  C4 |  CC |  D4 |  DC |  E4 |  EC |  F4 |  FC |
 * | BP  /  CH   |     101 |  C5 |  CD |  D5 |  DD |  E5 |  ED |  F5 |  FD |
 * | SI  /  DH   |     110 |  C6 |  CE |  D6 |  DE |  E6 |  EE |  F6 |  FE |
 * | DI  /  BH   |     111 |  C7 |  CF |  D7 |  DF |  E7 |  EF |  F7 |  FF |
 * +-------------+---------+-----+-----+-----+-----+-----+-----+-----+-----+
 * </code>
 */

extension CPU {

    func modRegRMFetchSegOfs() -> SegOfs {
        let offset = fetch16()
        let segment = segmentOverride ?? reg.DS
        segmentOverride = nil
        return SegOfs(segment, offset)
    }

    func modRegRMFetch8() -> RegRM8 {
        let value = Int(fetch8())
        let modValue = value >> 6
        let regValue = (value >> 3) & 0x07
        let rmValue = value & 0x07
        if modValue == 3 {
            return RegRM8(modRegRMGetReg8(regValue), modRegRMGetReg8(rmValue), regValue)
        } else {
            return RegRM8(modRegRMGetReg8(regValue), effectiveAddress(modValue, rmValue), memory, regValue)
        }
    }

    func modRegRMFetch16() -> RegRM16 {
        return fetch16(false)
    }

    func modRegRMFetch16SReg() -> RegRM16 {
        return fetch16(true)
    }

    private func fetch16(_ SReg: Bool) -> RegRM16 {
        let value = Int(fetch8())
        let modValue = value >> 6
        let regValue = (value >> 3) & 0x07
        let rmValue = value & 0x07
        if modValue == 3 {
            return RegRM16(SReg ? modRegRMGetSegReg(regValue) : modRegRMGetReg16(regValue), modRegRMGetReg16(rmValue), regValue)
        } else {
            return RegRM16(SReg ? modRegRMGetSegReg(regValue) : modRegRMGetReg16(regValue), effectiveAddress(modValue, rmValue), memory, regValue)
        }
    }

    private func effectiveAddress(_ mod: Int, _ rm: Int) -> SegOfs {
        var displacement = 0
        var segment = segmentOverride
        segmentOverride = nil

        if mod == 0 && rm == 6 {
            displacement = Int(fetch16())
            if segment == nil {
                segment = reg.DS
            }
        } else {
            if mod == 1 {
                displacement = Int(Int8(bitPattern: fetch8()))
            } else if mod == 2 {
                displacement = Int(Int16(bitPattern: fetch16()))
            }

            let base: Int = switch rm {
                case 0: Int(reg.BX.getValue()) + Int(reg.SI.getValue())
                case 1: Int(reg.BX.getValue()) + Int(reg.DI.getValue())
                case 2: Int(reg.BP.getValue()) + Int(reg.SI.getValue())
                case 3: Int(reg.BP.getValue()) + Int(reg.DI.getValue())
                case 4: Int(reg.SI.getValue())
                case 5: Int(reg.DI.getValue())
                case 6: Int(reg.BP.getValue())
                default: Int(reg.BX.getValue())
            }
            displacement += base
            if segment == nil {
                if rm == 2 || rm == 3 || rm == 6 {
                    segment = reg.SS
                } else {
                    segment = reg.DS
                }
            }
        }
        return SegOfs(segment!, UInt16(truncatingIfNeeded: displacement))
    }

    func modRegRMGetReg8(_ _reg: Int) -> Reg8 {
        return switch _reg {
            case 0: reg.AL
            case 1: reg.CL
            case 2: reg.DL
            case 3: reg.BL
            case 4: reg.AH
            case 5: reg.CH
            case 6: reg.DH
            default: reg.BH
        }
    }

    func modRegRMGetReg16(_ _reg: Int) -> Reg16 {
        return switch _reg {
            case 0: reg.AX
            case 1: reg.CX
            case 2: reg.DX
            case 3: reg.BX
            case 4: reg.SP
            case 5: reg.BP
            case 6: reg.SI
            default: reg.DI
        }
    }

    func modRegRMGetSegReg(_ _reg: Int) -> Reg16 {
        return switch _reg {
            case 0: reg.ES
            case 1: reg.CS
            case 2: reg.SS
            case 3: reg.DS
            // Undocumented behaviour to allow single step tests to pass. Registers replicated 4-7.
            case 4: reg.ES
            case 5: reg.CS
            case 6: reg.SS
            default: reg.DS
        }
    }
}
