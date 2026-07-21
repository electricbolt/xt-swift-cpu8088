// CPU.swift
// XT Copyright © 2025-2026; Electric Bolt Limited.

import Foundation

public class CPU: CustomStringConvertible {

    /// Get the CPU's delegate.
    public let delegate: CPUDelegate

    /// Get the CPU's register set.
    public let reg: RegSet = RegSet()

    /// Get the CPU's 1MB of accessible RAM.
    public let memory: Memory

    /// Creates an 8088 CPU and 1MB of accessible RAM.
    ///
    /// - Parameter delegate: Instance of CPUDelegate to handle callbacks from the CPU emulator.
    /// - Parameter hasPermissions: If true, enable capturing invalid memory reads, writes, and execution. The default
    /// is false.
    /// - Parameter zeroMemory: If true, initializes the RAM to all zeros. For unit-testing it is orders of magnitude
    /// quicker to set this parameter to false. Note that in a physical PC, RAM would contain random values when
    /// powered on. The default is false.

    public init(delegate: CPUDelegate, hasPermissions: Bool = false, zeroMemory: Bool = false) {
        self.delegate = delegate
        memory = Memory(hasPermissions: hasPermissions, zeroMemory: zeroMemory)
        memory.cpu = self
    }

    /// Invoke from the delegate to terminate execution of the CPU.

    public func terminate() {
        terminated = true
    }

    /// Executes the CPU forever, until the delegate terminates the execution.

    public func execute() {
        while true && !terminated {
            isRepeating = false
            repeatFlag = nil
            segmentOverride = nil
            step()
        }
    }

    /// Executes the CPU for a maximum of maxSteps, or until the delegate terminates the execution.
    ///
    /// A step is defined as a single instruction (including any segment prefix overrides and REP opcodes).

    public func execute(_ maxSteps: Int) {
        var maxSteps = maxSteps
        while maxSteps > 0 && !terminated {
            maxSteps -= 1
            isRepeating = false
            repeatFlag = nil
            segmentOverride = nil
            step()
        }
    }

    /// IRET instruction which returns from an interrupt routine.

    public func iret() {
        reg.IP.setValue(pop16())
        reg.CS.setValue(pop16())
        popf()
    }

    /// Pops a word value from the top of the stack and returns it.

    public func pop16() -> UInt16 {
        let result = memory.readWord(SegOfs(reg.SS, reg.SP))
        reg.SP.add(2)
        return result
    }

    public var description: String {
        return reg.description
    }

    // MARK: - Internal

    var segmentOverride: Reg16? = nil
    var isRepeating = false
    var repeatFlag: Bool? = nil
    var instructionCount: UInt64 = 0
    var terminated = false

    /// Opcode descriptions from Turbo Assembler Quick Reference Guide v3.2.

    private func step() {
        guard !terminated else {
            return
        }
        instructionCount += 1
        let opcode = fetch8()

        switch opcode {
        // MARK: - SEGMENT OVERRIDE
        case 0x26:   // ES segment override prefix.
            segmentOverride = reg.ES
            step()
        case 0x2E:   // CS segment override prefix.
            segmentOverride = reg.CS
            step()
        case 0x36:   // SS segment override prefix.
            segmentOverride = reg.SS
            step()
        case 0x3E:   // DS segment override prefix.
            segmentOverride = reg.DS
            step()

        // MARK: - REP
        case 0xF2:   // REPNZ/REPNE - Repeat while not zero/repeat while not equal.
            isRepeating = true
            repeatFlag = false
            step()
        case 0xF3:   // REPZ/REPE - Repeat while zero/repeat while equal.
            isRepeating = true
            repeatFlag = true
            step()

        // MARK: - ADD/ADC.
        case 0x00,   // ADD r/m8,r8 - Add byte register to r/m byte.
             0x02,   // ADD r8,r/m8 - Add r/m byte to byte register.
             0x10,   // ADC r/m8,r8 - Add with carry byte register to r/m byte.
             0x12:   // ADC r8,r/m8 - Add with carry r/m byte to byte register.
            let carry = (opcode == 0x10 || opcode == 0x12) && reg.flags.isCarry()
            let regRM = modRegRMFetch8()
            let result = add8(regRM.getMem8().getValue(), regRM.getReg8().getValue(), carry)
            if opcode == 0x02 || opcode == 0x12 {
                regRM.getReg8().setValue(result)
            } else {
                regRM.getMem8().setValue(result)
            }
        case 0x04,   // ADD AL,imm8 - Add immediate byte to AL.
             0x14:   // ADC AL,imm8 - Add with carry immediate byte to AL.
            let carry = opcode == 0x14 && reg.flags.isCarry()
            reg.AL.setValue(add8(fetch8(), reg.AL.getValue(), carry))
        case 0x01,   // ADD r/m16,r16 - Add word register to r/m word.
             0x03,   // ADD r16,r/m16 - Add r/m word to word register.
             0x11,   // ADC r/m16,r16 - Add with carry word register to r/m word.
             0x13:   // ADC r16,r/m16 - Add with carry r/m word to word register.
            let carry = (opcode == 0x11 || opcode == 0x13) && reg.flags.isCarry()
            let regRM = modRegRMFetch16()
            let result = add16(regRM.getMem16().getValue(), regRM.getReg16().getValue(), carry)
            if opcode == 0x03 || opcode == 0x13 {
                regRM.getReg16().setValue(result)
            } else {
                regRM.getMem16().setValue(result)
            }
        case 0x05,   // ADD AX,imm16 - Add immediate word to AX.
             0x15:   // ADC AX,imm16 - Add with carry immediate word to AX.
            let carry = opcode == 0x15 && reg.flags.isCarry()
            reg.AX.setValue(add16(fetch16(), reg.AX.getValue(), carry))

        // MARK: - PUSH/POP.
        case 0x06:   // PUSH ES - Push ES.
            push16(reg.ES.getValue())
        case 0x07:   // POP ES - Pop ES.
            reg.ES.setValue(pop16())
        case 0x0E:   // PUSH CS - Push CS.
            push16(reg.CS.getValue())
        case 0x16:   // PUSH SS - Push SS.
            push16(reg.SS.getValue())
        case 0x17:   // POP SS - Pop SS.
            reg.SS.setValue(pop16())
        case 0x1E:   // PUSH DS - Push DS.
            push16(reg.DS.getValue())
        case 0x1F:   // POP DS - Pop DS.
            reg.DS.setValue(pop16())
        case 0x50,   // PUSH AX - Push register word.
             0x51,   // PUSH CX - Push register word.
             0x52,   // PUSH DX - Push register word.
             0x53,   // PUSH BX - Push register word.
             0x54,   // PUSH SP - Push register word.
             0x55,   // PUSH BP - Push register word.
             0x56,   // PUSH SI - Push register word.
             0x57:   // PUSH DI - Push register word.
            let reg16 = modRegRMGetReg16(Int(opcode & 0x7))
            push16(reg16.getValue() &- (opcode == 0x54 ? 2 : 0))
        case 0x58,   // POP AX - Pop top of stack into word register.
             0x59,   // POP CX - Pop top of stack into word register.
             0x5A,   // POP DX - Pop top of stack into word register.
             0x5B,   // POP BX - Pop top of stack into word register.
             0x5C,   // POP SP - Pop top of stack into word register.
             0x5D,   // POP BP - Pop top of stack into word register.
             0x5E,   // POP SI - Pop top of stack into word register.
             0x5F:   // POP DI - Pop top of stack into word register.
            let reg16 = modRegRMGetReg16(Int(opcode & 0x7))
            reg16.setValue(pop16())
        case 0x8F:   // POP m16 - Pop top of stack into memory word.
            let regRM = modRegRMFetch16()
            regRM.getMem16().setValue(pop16())

        // MARK: - FLAGS.
        case 0x9C:   // PUSHF - Push FLAGS.
            push16(reg.flags.getValue16())
        case 0x9D:   // POPF - Pop top of stack into FLAGS.
            popf()
        case 0x9E:   // SAHF - Store AH flags SH ZF 0 AF 0 PF 1 CF
            reg.flags.setValue8(reg.AH.getValue())
        case 0x9F:   // LAHF - Load: AH = flags SF ZF 0 AF 0 PF 1 CF
            reg.AH.setValue(reg.flags.getValue8())
        case 0xF5:   // CMC - Complement carry flag.
            reg.flags.setCarry(!reg.flags.isCarry())
        case 0xF8:   // CLC - Clear carry flag.
            reg.flags.setCarry(false)
        case 0xF9:   // STC - Set carry flag.
            reg.flags.setCarry(true)
        case 0xFA:
            // CLI - Clear interrupt flag (disable interrupts).
            reg.flags.setInterruptEnabled(false)
        case 0xFB:
            // STI - Set interrupt flag (enable interrupts).
            reg.flags.setInterruptEnabled(true)
        case 0xFC:
            // CLD - Clear direction flag (up).
            reg.flags.setDirectionDown(false)
        case 0xFD:
            // STD - Set direction flag (down).
            reg.flags.setDirectionDown(true)

        // MARK: - OR.
        case 0x08:   // OR r/m8,r8 - OR byte register to r/m byte.
            let regRM = modRegRMFetch8()
            let result = or8(UInt16(regRM.getMem8().getValue()), UInt16(regRM.getReg8().getValue()))
            regRM.getMem8().setValue(result)
        case 0x09:   // OR r/m16,r16 - OR word register to r/m word.
            let regRM = modRegRMFetch16()
            let result = or16(regRM.getMem16().getValue(), regRM.getReg16().getValue())
            regRM.getMem16().setValue(result)
        case 0x0A:   // OR r8,r/m8 - OR r/m byte to byte register.
            let regRM = modRegRMFetch8()
            let result = or8(UInt16(regRM.getMem8().getValue()), UInt16(regRM.getReg8().getValue()))
            regRM.getReg8().setValue(result)
        case 0x0B:   // OR r16,r/m16 - OR r/m word to word register.
            let regRM = modRegRMFetch16()
            let result = or16(regRM.getMem16().getValue(), regRM.getReg16().getValue())
            regRM.getReg16().setValue(result)
        case 0x0C:   // OR AL,imm8 - OR immediate byte to AL.
            reg.AL.setValue(or8(UInt16(fetch8()), UInt16(reg.AL.getValue())))
        case 0x0D:   // OR AX,imm16 - OR immediate word to AX.
            reg.AX.setValue(or16(fetch16(), reg.AX.getValue()))

        // MARK: - SUB/SBB.
        case 0x18,   // SBB r/m8,r8 - Subtract with borrow byte register from r/m byte.
             0x28:   // SUB r/m8,r8 - Subtract byte register from r/m byte.
            let carry = (opcode == 0x18) && reg.flags.isCarry()
            let regRM = modRegRMFetch8()
            let result = sub8(regRM.getMem8().getValue(), regRM.getReg8().getValue(), carry)
            regRM.getMem8().setValue(result)
        case 0x1A,   // SBB r8,r/m8 - Subtract with borrow word register from r/m byte.
             0x2A:   // SUB r8,r/m8 - Subtract r/m byte from byte register.
            let carry = opcode == 0x1A && reg.flags.isCarry()
            let regRM = modRegRMFetch8()
            let result = sub8(regRM.getReg8().getValue(), regRM.getMem8().getValue(), carry)
            regRM.getReg8().setValue(result)
        case 0x1C,   // SBB AL,imm8 - Subtract with borrow immediate byte from AL.
             0x2C:   // SUB AL,imm8 - Subtract immediate byte from AL.
            let carry = opcode == 0x1C && reg.flags.isCarry()
            reg.AL.setValue(sub8(reg.AL.getValue(), fetch8(), carry))
        case 0x19,   // SBB r/m16,r16 - Subtract with borrow word register from r/m word.
             0x29:   // SUB r/m16,r16 - Subtract word register from r/m word.
            let carry = (opcode == 0x19) && reg.flags.isCarry()
            let regRM = modRegRMFetch16()
            let result = sub16(regRM.getMem16().getValue(), regRM.getReg16().getValue(), carry)
            regRM.getMem16().setValue(result)
        case 0x1B,   // SBB r16,r/m16 - Subtract with borrow r/m word from word register.
             0x2B:   // SUB r16,r/m16 - Subtract r/m word from word register.
            let carry = (opcode == 0x1B) && reg.flags.isCarry()
            let regRM = modRegRMFetch16()
            let result = sub16(regRM.getReg16().getValue(), regRM.getMem16().getValue(), carry)
            regRM.getReg16().setValue(result)
        case 0x1D,   // SBB AX,imm16 - Subtract with borrow immediate word from AX.
             0x2D:   // SUB AX,imm16 - Subtract immediate byte from AX.
            let carry = opcode == 0x1D && reg.flags.isCarry()
            reg.AX.setValue(sub16(reg.AX.getValue(), fetch16(), carry))

        // MARK: - AND.
        case 0x20:   // AND r/m8,r8 - AND byte register into r/m byte.
            let regRM = modRegRMFetch8()
            let result = and8(UInt16(regRM.getMem8().getValue()), UInt16(regRM.getReg8().getValue()))
            regRM.getMem8().setValue(result)
        case 0x21:   // AND r/m16,r16 - AND word register into r/m word.
            let regRM = modRegRMFetch16()
            let result = and16(regRM.getMem16().getValue(), regRM.getReg16().getValue())
            regRM.getMem16().setValue(result)
        case 0x22:   // AND r8,r/m8 - AND r/m byte into byte register.
            let regRM = modRegRMFetch8()
            let result = and8(UInt16(regRM.getMem8().getValue()), UInt16(regRM.getReg8().getValue()))
            regRM.getReg8().setValue(result)
        case 0x23:   // AND r16,r/m16 - AND r/m word into word register.
            let regRM = modRegRMFetch16()
            let result = and16(regRM.getMem16().getValue(), regRM.getReg16().getValue())
            regRM.getReg16().setValue(result)
        case 0x24:   // AND AL,imm8 - AND immediate byte to AL.
            reg.AL.setValue(and8(UInt16(fetch8()), UInt16(reg.AL.getValue())))
        case 0x25:   // AND AX,imm16 - AND immediate word to AX.
            reg.AX.setValue(and16(fetch16(), reg.AX.getValue()))

        // MARK: - BCD.
        case 0x27:   // DAA - Decimal adjust AL after addition.
            daa()
        case 0x2F:   // DAS - Decimal adjust AL after subtraction.
            das()
        case 0x37:   // AAA - ASCII adjust after addition.
            aaa()
        case 0x3F:   // AAS - ASCII adjust after subtraction.
            aas()
        case 0xD4:   // AAM base - ASCII adjust after multiplication.
            let base = fetch8()
            if !aam(base) {
                interrupt(0)
            }
        case 0xD5:   // AAD base - ASCII adjust before division.
            let base = fetch8()
            aad(base)

        // MARK: - XOR.
        case 0x30:   // XOR r/m8,r8 - Exclusive-OR byte register to r/m byte.
            let regRM = modRegRMFetch8()
            let result = xor8(UInt16(regRM.getMem8().getValue()), UInt16(regRM.getReg8().getValue()))
            regRM.getMem8().setValue(result)
        case 0x31:   // XOR r/m16,r16 - Exclusive-OR word register to r/m word.
            let regRM = modRegRMFetch16()
            let result = xor16(regRM.getMem16().getValue(), regRM.getReg16().getValue())
            regRM.getMem16().setValue(result)
        case 0x32:   // XOR r8,r/m8 - Exclusive-OR r/m byte into byte register.
            let regRM = modRegRMFetch8()
            let result = xor8(UInt16(regRM.getMem8().getValue()), UInt16(regRM.getReg8().getValue()))
            regRM.getReg8().setValue(result)
        case 0x33:   // XOR r16,r/m16 - Exclusive-OR r/m word into word register.
            let regRM = modRegRMFetch16()
            let result = xor16(regRM.getMem16().getValue(), regRM.getReg16().getValue())
            regRM.getReg16().setValue(result)
        case 0x34:   // XOR AL,imm8 - Exclusive-OR immediate byte to AL.
            reg.AL.setValue(xor8(UInt16(fetch8()), UInt16(reg.AL.getValue())))
        case 0x35:   // XOR AX,imm16 - Exclusive-OR immediate word to AX.
            reg.AX.setValue(xor16(fetch16(), reg.AX.getValue()))

        // MARK: - CMP.
        case 0x38:   // CMP r/m8,r8 - Compare byte register to r/m byte.
            let regRM = modRegRMFetch8()
            _ = sub8(regRM.getMem8().getValue(), regRM.getReg8().getValue(), false)
        case 0x39:   // CMP r/m16,r16 - Compare word register to r/m word.
            let regRM = modRegRMFetch16()
            _ = sub16(regRM.getMem16().getValue(), regRM.getReg16().getValue(), false)
        case 0x3A:   // CMP r8,r/m8 - Compare r/m byte to byte register.
            let regRM = modRegRMFetch8()
            _ = sub8(regRM.getReg8().getValue(), regRM.getMem8().getValue(), false)
        case 0x3B:   // CMP r16,r/m16 - Compare r/m word to word register.
            let regRM = modRegRMFetch16()
            _ = sub16(regRM.getReg16().getValue(), regRM.getMem16().getValue(), false)
        case 0x3C:   // CMP AL,imm8 - Compare immediate byte to AL.
            _ = sub8(reg.AL.getValue(), fetch8(), false)
        case 0x3D:   // CMP AX,imm8 - Compare immediate word to AX.
            _ = sub16(reg.AX.getValue(), fetch16(), false)

        // MARK: - INC/DEC.
        case 0x40,   // INC AX - Increment word register by 1.
             0x41,   // INC CX - Increment word register by 1.
             0x42,   // INC DX - Increment word register by 1.
             0x43,   // INC BX - Increment word register by 1.
             0x44,   // INC SP - Increment word register by 1.
             0x45,   // INC BP - Increment word register by 1.
             0x46,   // INC SI - Increment word register by 1.
             0x47:   // INC DI - Increment word register by 1.
            let reg16 = modRegRMGetReg16(Int(opcode & 0x7))
            let origCarry = reg.flags.isCarry()
            reg16.setValue(add16(reg16.getValue(), 1, false))
            reg.flags.setCarry(origCarry)
        case 0x48,   // DEC AX - Decrement word register by 1.
             0x49,   // DEC CX - Decrement word register by 1.
             0x4A,   // DEC DX - Decrement word register by 1.
             0x4B,   // DEC BX - Decrement word register by 1.
             0x4C,   // DEC SP - Decrement word register by 1.
             0x4D,   // DEC BP - Decrement word register by 1.
             0x4E,   // DEC SI - Decrement word register by 1.
             0x4F:   // DEC DI - Decrement word register by 1.
            let reg16 = modRegRMGetReg16(Int(opcode & 0x7))
            let origCarry = reg.flags.isCarry()
            reg16.setValue(sub16(reg16.getValue(), 1, false))
            reg.flags.setCarry(origCarry)
        case 0xFE:   // INC/DEC r/m8.
            decodeGroup4()

        // MARK: - Jcc.
        case 0x70:   // JO rel8 - Jump short if overflow (OF=1).
            jcc(reg.flags.isOverflow())
        case 0x71:   // JNO rel8 - Jump short if not overflow (OF=0).
            jcc(reg.flags.isNotOverflow())
        case 0x72:   // JB/JNAE/JC rel8 - Jump short if carry/Jump short if not above or equal/Jump short if carry (CF=1).
            jcc(reg.flags.isCarry())
        case 0x73:   // JNB/JAE/JNC rel8 - Jump short if not carry/Jump short if above or equal/Jump short if not carry (CF=0).
            jcc(reg.flags.isNotCarry())
        case 0x74:   // JE/JZ rel8 - Jump short if equal/Jump short if zero (ZF=1).
            jcc(reg.flags.isZero())
        case 0x75:   // JNE/JNZ rel8 - Jump short if not equal/Jump short if not zero (ZF=0).
            jcc(reg.flags.isNotZero())
        case 0x76:   // JBE/JNA rel8 - Jump short if below or equal/Jump short if not above (CF=1 | ZF=1).
            jcc(reg.flags.isCarry() || reg.flags.isZero())
        case 0x77:   // JNBE/JA rel8 - Jump short if not below or equal/Jump short if above (CF=0 & ZF=0).
            jcc(reg.flags.isNotCarry() && reg.flags.isNotZero())
        case 0x78:   // JS rel8 - Jump short if sign (SF=1).
            jcc(reg.flags.isSignNegative())
        case 0x79:   // JNS rel8 - Jump short if not sign (SF=0).
            jcc(reg.flags.isSignPositive())
        case 0x7A:   // JP/JPE rel8 - Jump short if parity/Jump short if parity even (PF=1).
            jcc(reg.flags.isParityEven())
        case 0x7B:   // JNP/JPO rel8 - Jump short if not parity/jump short if parity odd (PF=0).
            jcc(reg.flags.isParityOdd())
        case 0x7C:   // JL/JNGE rel8 - jump short if less/jump short if not greater than or equal (SF <> OE).
            jcc(reg.flags.isSignPositive() != reg.flags.isNotOverflow())
        case 0x7D:   // JNL/JGE rel8 - jump short if not less/jump short if greater than or equal (SF == OE).
            jcc(reg.flags.isSignNegative() == reg.flags.isOverflow())
        case 0x7E:   // JLE/JNG rel8 - Jump short if less than or equal/Not greater than
            jcc(reg.flags.isZero() || (reg.flags.isSignNegative() != reg.flags.isOverflow())) // (ZF=1 and SF=OF).
        case 0x7F:   // JNLE/JG rel8 - Jump short if not less than or equal/Greater than (ZF=0 and SF=OF).
            jcc(reg.flags.isNotZero() && (reg.flags.isSignNegative() == reg.flags.isOverflow()))
        case 0xE3:   // JCXZ rel8  - Jump short if CX register is 0.
            jcc(reg.CX.getValue() == 0)

        // MARK: - Group 1 - ADD/ADC/AND/CMP/OR/SBB/SUB/XOR.
        case 0x80:   // op r/m8, imm8.
            imm8()
        case 0x81:   // op r/m16, imm16.
            imm16(false)
        case 0x83:   // op r/m16, imm8 - sign-extended immediate byte to r/m word.
            imm16(true)

        // MARK: - TEST.
        case 0x84:   // TEST r/m8,r8 - AND byte register with r/m byte.
            let regRM = modRegRMFetch8()
            _ = and8(UInt16(regRM.getMem8().getValue()), UInt16(regRM.getReg8().getValue()))
        case 0x85:   // TEST r/m16,r16 - AND word register with r/m word.
            let regRM = modRegRMFetch16()
            _ = and16(regRM.getMem16().getValue(), regRM.getReg16().getValue())
        case 0xA8:   // TEST AL,imm8 - AND immediate byte with AL.
            let imm8 = fetch8()
            _ = and8(UInt16(reg.AL.getValue()), UInt16(imm8))
        case 0xA9:   // TEST AX,imm16 - AND immediate word with AX.
            let imm16 = fetch16()
            _ = and16(reg.AX.getValue(), imm16)

        // MARK: - XCHG.
        case 0x86:   // XCHG r/m8,r8 - Exchange byte register with r/m byte.
            let regRM = modRegRMFetch8()
            let temp = regRM.getMem8().getValue()
            regRM.getMem8().setValue(regRM.getReg8().getValue())
            regRM.getReg8().setValue(temp)
        case 0x87:   // XCHG r/m16,r16 - Exchange word register with r/m word.
            let regRM = modRegRMFetch16()
            let temp = regRM.getMem16().getValue()
            regRM.getMem16().setValue(regRM.getReg16().getValue())
            regRM.getReg16().setValue(temp)
        case 0x90,   // XCHG AX, AX - Exchange word register with AX/NOP - No operation.
             0x91,   // XCHG AX, CX - Exchange word register with AX.
             0x92,   // XCHG AX, DX - Exchange word register with AX.
             0x93,   // XCHG AX, BX - Exchange word register with AX.
             0x94,   // XCHG AX, SP - Exchange word register with AX.
             0x95,   // XCHG AX, BP - Exchange word register with AX.
             0x96,   // XCHG AX, SI - Exchange word register with AX.
             0x97:   // XCHG AX, DI - Exchange word register with AX.
            let reg16 = modRegRMGetReg16(Int(opcode & 0x7))
            let temp = reg16.getValue()
            reg16.setValue(reg.AX.getValue())
            reg.AX.setValue(temp)

        // MARK: - MOV.
        case 0x88:   // MOV r/m8,r8 - Move byte register into r/m byte.
            let regRM = modRegRMFetch8()
            regRM.getMem8().setValue(regRM.getReg8().getValue())
        case 0x89:   // MOV r/m16,r16 - Move word register into r/m word.
            let regRM = modRegRMFetch16()
            regRM.getMem16().setValue(regRM.getReg16().getValue())
        case 0x8A:   // MOV r8,r/m8 - Move r/m byte into byte register.
            let regRM = modRegRMFetch8()
            regRM.getReg8().setValue(regRM.getMem8().getValue())
        case 0x8B:   // MOV r8,r/m16 - Move r/m word into word register.
            let regRM = modRegRMFetch16()
            regRM.getReg16().setValue(regRM.getMem16().getValue())
        case 0x8C:   // MOV r/m16,Sreg - Move segment register to r/m register.
            let regRM = modRegRMFetch16SReg()
            regRM.getMem16().setValue(regRM.getReg16().getValue())
        case 0x8D:   // LEA r16,m - Store effective address for m in register 16.
            let regRM = modRegRMFetch16()
            regRM.getReg16().setValue(regRM.getMem16().getSegOfs()!.getOffset())
        case 0x8E:   // MOV Sreg,r/m16 - Move r/m register to segment register.
            let regRM = modRegRMFetch16SReg()
            regRM.getReg16().setValue(regRM.getMem16().getValue())
        case 0xA0:   // MOV AL,moffs8 - Move byte at (seg:offset) to AL.
            let segOfs = modRegRMFetchSegOfs()
            reg.AL.setValue(memory.readByte(segOfs))
        case 0xA1:   // MOV AX,moffs16 - Move byte at (seg:offset) to AX.
            let segOfs = modRegRMFetchSegOfs()
            reg.AX.setValue(memory.readWord(segOfs))
        case 0xA2:   // MOV moffs8,AL - Move AL to (seg:offset).
            let segOfs = modRegRMFetchSegOfs()
            memory.writeByte(segOfs, reg.AL.getValue())
        case 0xA3:   // MOV moffs16,AX - Move AX to (seg:offset).
            let segOfs = modRegRMFetchSegOfs()
            memory.writeWord(segOfs, reg.AX.getValue())
        case 0xB0,   // MOV AL, imm8 - Move immediate byte to register.
             0xB1,   // MOV CL, imm8 - Move immediate byte to register.
             0xB2,   // MOV DL, imm8 - Move immediate byte to register.
             0xB3,   // MOV BL, imm8 - Move immediate byte to register.
             0xB4,   // MOV AH, imm8 - Move immediate byte to register.
             0xB5,   // MOV CH, imm8 - Move immediate byte to register.
             0xB6,   // MOV DH, imm8 - Move immediate byte to register.
             0xB7:   // MOV BH, imm8 - Move immediate byte to register.
            let reg8 = modRegRMGetReg8(Int(opcode & 0x7))
            reg8.setValue(fetch8())
        case 0xB8,   // MOV AX, imm16 - Move immediate word to register.
             0xB9,   // MOV CX, imm16 - Move immediate word to register.
             0xBA,   // MOV DX, imm16 - Move immediate word to register.
             0xBB,   // MOV BX, imm16 - Move immediate word to register.
             0xBC,   // MOV SP, imm16 - Move immediate word to register.
             0xBD,   // MOV BP, imm16 - Move immediate word to register.
             0xBE,   // MOV SI, imm16 - Move immediate word to register.
             0xBF:   // MOV DI, imm16 - Move immediate word to register.
            let reg16 = modRegRMGetReg16(Int(opcode & 0x7))
            reg16.setValue(fetch16())
        case 0xC6:   // MOV r/m8,imm8 - Move immediate byte to r/m byte.
            let regRM = modRegRMFetch8()
            regRM.getMem8().setValue(fetch8())
        case 0xC7:   // MOV r/m16,imm16 - Move immediate word to r/m word.
            let regRM = modRegRMFetch16()
            regRM.getMem16().setValue(fetch16())

        // MARK: - STRING.
        case 0xA4:   // MOVSB - Move byte SS:[SI] to ES:[DI].
            move8()
        case 0xA5:   // MOVSW - Move word DS:[SI] to ES:[DI].
            move16()
        case 0xA6:   // CMPSB - Compare bytes DS:[SI] with ES:[DI].
            compare8()
        case 0xA7:   // CMPSW - Compare words DS:[SI] with ES:[DI].
            compare16()
        case 0xAA:   // STOSB - Store AL in byte ES:[DI].
            store8()
        case 0xAB:   // STOSW - Store AX in word ES:[DI].
            store16()
        case 0xAC:   // LODSB - Load byte DS:[SI] into AL.
            load8()
        case 0xAD:   // LODSW - Load word DS:[SI] into AX.
            load16()
        case 0xAE:   // SCASB - Compare bytes AL - ES:[DI].
            scan8()
        case 0xAF:   // SCASW - Compare words AX - ES:[DI].
            scan16()

        // MARK: - CBW/CWD.
        case 0x98:   // CBW - AX sign extend of AL.
            reg.AX.setValue(UInt16(bitPattern: Int16(Int8(bitPattern: reg.AL.getValue()))))
        case 0x99:   // CWD - DX:AX <- sign-extend of AX.
            if (reg.AX.getValue() & 0x8000) == 0x8000 {
                reg.DX.setValue(0xFFFF)
            } else {
                reg.DX.setValue(0)
            }

        // MARK: - CALL/RET.
        case 0x9A:   // CALL ptr16:16 - Call intersegment, to full pointer given (far call).
            let offset = fetch16()
            let segment = fetch16()
            push16(reg.CS.getValue())
            push16(reg.IP.getValue())
            reg.CS.setValue(segment)
            reg.IP.setValue(offset)
        case 0xC2:   // RET imm16 - Return (near), popping off N additional bytes.
            let additionalPopBytes = fetch16()
            reg.IP.setValue(pop16())
            reg.SP.add(additionalPopBytes)
        case 0xC3:   // RET - Return (near).
            reg.IP.setValue(pop16())
        case 0xCA:   // RETF - Return (far), popping off N additional bytes.
            let additionalPopBytes = fetch16()
            reg.IP.setValue(pop16())
            reg.CS.setValue(pop16())
            reg.SP.add(additionalPopBytes)
        case 0xCB:   // RETF - Return (far).
            reg.IP.setValue(pop16())
            reg.CS.setValue(pop16())

        // MARK: - LOAD SEG.
        case 0xC4:   // LES r16,m16:16 - Load ES:r16 with pointer from memory.
            loadSeg(reg.ES)
        case 0xC5:   // LDS r16,m16:16 - Load DS:r16 with pointer from memory.
            loadSeg(reg.DS)

        // MARK: - MISC.
        case 0x9B:   // WAIT - Wait until BUSY pin is inactive (HIGH).
            // ignore.
            break
        case 0xF0:   // LOCK - Assert LOCK# signal for the next instruction.
            // ignore.
            break
        case 0xF4:   // HLT - Halt.
            delegate.halt(self)

        // MARK: - INTERRUPTS.
        case 0xCC:   // INT3 - Interrupt 3 -- trap to debugger.
            interrupt(3)
        case 0xCD:   // INT imm8 - Interrupt numbered by immediate byte.
            interrupt(fetch8())
        case 0xCE:   // INTO - Interrupt 4 -- if overflow flag is 1.
            if reg.flags.isOverflow() {
                interrupt(4)
            }
        case 0xCF:   // IRET - Interrupt return (far return and pop flags).
            iret()

        // MARK: - Group 2 - RCL/RCR/ROL/ROR/SHL/SHR/SAL/SAR.
        case 0xD0:   // Rotate byte 1 bit.
            rotate8(1)
        case 0xD1:   // Rotate word 1 bit.
            rotate16(1)
        case 0xD2:   // Rotate byte by CL bits.
            rotate8(Int(reg.CL.getValue()))
        case 0xD3:   // Rotate word by CL bits.
            rotate16(Int(reg.CL.getValue()))

        // MARK: - XLAT.
        case 0xD7:   // XLAT - Set AL to memory byte DS:[BX + unsigned AL].
            let segOfs = SegOfs(segmentOverride ?? reg.DS, reg.BX.getValue() &+ UInt16(reg.AL.getValue()))
            reg.AL.setValue(memory.readByte(segOfs))
            segmentOverride = nil

        // MARK: - ESC.
        case 0xD8,   // ESC - Escape to co-processor.
             0xD9,
             0xDA,
             0xDB,
             0xDC,
             0xDD,
             0xDE,
             0xDF:
            _ = modRegRMFetch16()

        // MARK: - LOOP.
        case 0xE0:   // LOOPNZ/LOOPNE - DEC Count; jump short if Count 0 and ZF=0.
            loop(reg.flags.isNotZero())
        case 0xE1:   // LOOPZ/LOOPE - DEC Count; jump short if Count 0 and ZF=1.
            loop(reg.flags.isZero())
        case 0xE2:   // LOOP rel8 - DEC Count; jump short if Count 0.
            loop(true)

        // MARK: - IN/OUT.
        case 0xE4:   // IN AL,imm8 - Input byte from immediate port into AL.
            let address = UInt16(fetch8())
            reg.AL.setValue(delegate.portRead8(self, address))
        case 0xE5:   // IN AX,imm8 - Input word from immediate port into AX.
            let address = UInt16(fetch8())
            reg.AX.setValue(delegate.portRead16(self, address))
        case 0xE6:   // OUT imm8,AL - Output byte AL to immediate port number.
            let address = UInt16(fetch8())
            delegate.portWrite8(self, address, reg.AL.getValue())
        case 0xE7:   // OUT imm8,AX - Output word AX to immediate port number.
            let address = UInt16(fetch8())
            delegate.portWrite16(self, address, reg.AX.getValue())
        case 0xEC:   // IN AL,DX - Input byte from port DX into AL.
            reg.AL.setValue(delegate.portRead8(self, reg.DX.getValue()))
        case 0xED:   // IN AX,DX - Input word from port DX into AX.
            reg.AX.setValue(delegate.portRead16(self, reg.DX.getValue()))
        case 0xEE:   // OUT DX,AL - Output byte AL to port number in DX.
            delegate.portWrite8(self, reg.DX.getValue(), reg.AL.getValue())
        case 0xEF:   // OUT DX,AX - Output word AX to port number in DX.
            delegate.portWrite16(self, reg.DX.getValue(), reg.AX.getValue())

        // MARK: - CALL/JMP.
        case 0xE8:   // CALL rel16 - Call near, displacement relative to next instruction.
            let offset = fetch16()
            push16(reg.IP.getValue())
            reg.IP.setValue(reg.IP.getValue() &+ offset)
        case 0xE9:   // JMP rel16 - Jump short.
            let offset = fetch16()
            reg.IP.setValue(reg.IP.getValue() &+ offset)
        case 0xEA:   // JMP ptr16:16 - Jump intersegment, 4-byte immediate address.
            let ip = fetch16()
            let cs = fetch16()
            reg.IP.setValue(ip)
            reg.CS.setValue(cs)
        case 0xEB:   // JMP rel8 - Jump short.
            let offset = fetch8()
            reg.IP.setValue(reg.IP.getValue() &+ UInt16(bitPattern: Int16(Int8(bitPattern: offset))))

        // MARK: - Group 3A/3B - TEST/NOT/NEG/MUL/IMUL/DIV/IDIV.
        case 0xF6:   // 8-bit instructions.
            decodeGroup3A()
        case 0xF7:   // 16-bit instructions.
            decodeGroup3B()

        // MARK: - Group 5 - 16-bit instructions.
        case 0xFF:
            decodeGroup5()

        default:
            delegate.invalidOpcode(self, "Invalid opcode")
        }
    }

    /// Fetches a byte from the address at CS:IP, then increments IP by 1. If IP was 0xFFFF it will wrap to 0x0.

    func fetch8() -> UInt8 {
        let result = memory.fetchByte(SegOfs(reg.CS, reg.IP))
        delegate.fetched8(self, result, instructionCount)
        reg.IP.add(1)
        return result
    }

    /// Fetches a word from the address at CS:IP, then increments IP by 2. If IP was 0xFFFE or 0xFFFF it will wrap
    /// around to 0x0 or 0x1.

    func fetch16() -> UInt16 {
        let result = memory.fetchWord(SegOfs(reg.CS, reg.IP))
        delegate.fetched16(self, result, instructionCount)
        reg.IP.add(2)
        return result
    }

    /// LOOP instruction. Decrements CX and jumps short if CX is 0, or the optional flag evaluates to true.

    func loop(_ flag: Bool) {
        let relOfs = fetch8()
        reg.CX.add(0xFFFF)
        if reg.CX.getValue() != 0 && flag {
            reg.IP.add(UInt16(bitPattern: Int16(Int8(bitPattern: relOfs))))
        }
    }

    /// Pops a word from the stack into the flags register.

    func popf() {
        reg.flags.setValue16(pop16())
    }

    /// Interrupt handler, which is called by 'software' INT, INT3, INTO instructions or as a result of a 'hardware'
    /// error e.g. divide by zero, quotient overflow or AAM with base 0.
    ///
    /// To pass Single Step Tests, we must update the registers. The `CPUDelegate` will be invoked. If the CPUDelegate
    /// wants to continue execution, it must invoke the `iret` method or pop the stack manually.

    func interrupt(_ interrupt: UInt8) {
        push16(reg.flags.getValue16())
        push16(reg.CS.getValue())
        push16(reg.IP.getValue())

        reg.flags.setTrapEnabled(false)
        reg.flags.setInterruptEnabled(false)
        reg.CS.setValue(memory.getWord(SegOfs(0, UInt16((4 * Int(interrupt)) + 2))))
        reg.IP.setValue(memory.getWord(SegOfs(0, UInt16(4 * Int(interrupt)))))
        delegate.interrupt(self, interrupt)
    }

    /// LES or LDS instruction. Loads the DS or ES segment register with a word from memory.

    func loadSeg(_ segReg: Reg16) {
        let regRM = modRegRMFetch16()
        let segOfs = regRM.getMem16().getSegOfs()!
        regRM.getReg16().setValue(memory.readWord(segOfs))
        segOfs.addOffset(2)
        segReg.setValue(memory.readWord(segOfs))
    }

    /// Push a word value onto the stack.

    func push16(_ value: UInt16) {
        reg.SP.add(0xFFFE)
        memory.writeWord(SegOfs(reg.SS, reg.SP), value)
    }

    /// Jump short to relative address if condition code is true.
    /// - Parameter flag: the condition code flag.

    func jcc(_ flag: Bool) {
        let offset = fetch8()
        if flag {
            reg.IP.setValue(reg.IP.getValue() &+ UInt16(bitPattern: Int16(Int8(bitPattern: offset))))
        }
    }
}
