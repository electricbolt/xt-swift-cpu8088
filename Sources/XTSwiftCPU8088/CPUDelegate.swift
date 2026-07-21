// CPUDelegate.swift
// XT Copyright © 2025-2026; Electric Bolt Limited.

import Foundation

public protocol CPUDelegate {

    /// Invoked when a byte was fetched from memory for use in instruction decoding and execution.
    ///
    /// This is the ideal place to perform logging or tracing of instructions.
    ///
    /// - Parameter cpu: The CPU instance invoking this delegate method.

    func fetched8(_ cpu: CPU, _ value: UInt8, _ instructionCount: UInt64)

    /// Invoked when a word was fetched from memory for use in instruction decoding and execution.
    ///
    /// This is the ideal place to perform logging or tracing of instructions.
    ///
    /// - Parameter cpu: The CPU instance invoking this delegate method.

    func fetched16(_ cpu: CPU, _ value: UInt16, _ instructionCount: UInt64)

    /// Invoked when an interrupt occurs due to 'software' INT, INT3, INTO instructions or as a result of 'hardware'
    /// error e.g. divide by zero, quotient overflow or AAM with base 0.
    ///
    /// Flags, CS:IP have been pushed onto the stack and CS:IP was updated to the interrupt vector. If the delegate
    /// wants to return from the interrupt, it must call `cpu.iret()` method or pop the stack manually.
    ///
    /// - Parameter cpu: The CPU instance invoking this delegate method.
    /// - Parameter value: byte 0x00 - 0xFF interrupt number.

    func interrupt(_ cpu: CPU, _ value: UInt8)

    /// Invoked when the CPU is halted by the HLT instruction.
    ///
    /// - Parameter cpu: The CPU instance invoking this delegate method.

    func halt(_ cpu: CPU)

    /// Invoked when a byte is requested from the IO port specified.
    ///
    /// - Parameter cpu: The CPU instance invoking this delegate method.
    /// - Parameter address: port number 0x0000 - 0xFFFF.

    func portRead8(_ cpu: CPU, _ address: UInt16) -> UInt8

    /// Invoked when a byte is written to the IO port specified.
    ///
    /// - Parameter cpu: The CPU instance invoking this delegate method.
    /// - Parameter address: port number 0x0000 - 0xFFFF.
    /// - Parameter value: to write to port specified.

    func portWrite8(_ cpu: CPU, _ address: UInt16, _ value: UInt8)

    /// Invoked when a word is requested from the IO port specified.
    ///
    /// - Parameter cpu: The CPU instance invoking this delegate method.
    /// - Parameter address: port number 0x0000 - 0xFFFF.

    func portRead16(_ cpu: CPU, _ address: UInt16) -> UInt16

    /// Invoked when a word is written to the IO port specified.
    ///
    /// - Parameter cpu: The CPU instance invoking this delegate method.
    /// - Parameter address: port number 0x0000 - 0xFFFF.
    /// - Parameter value: to write to port specified.

    func portWrite16(_ cpu: CPU, _ address: UInt16, _ value: UInt16)

    /// Invoked when a fetch, read or write memory access is attempted that is not permitted by the current permission
    /// mask.
    ///
    /// - Parameter memoryAddress: address of the memory location being accessed.
    /// - Parameter permissionMask: permission bitmask that isn't allowed for the memory location.

    func invalidMemoryAccess(_ cpu: CPU, _ memoryAddress: SegOfs, _ permissionMask: UInt8)

    /// Invoked when an undocumented (unimplemented) opcode is encountered.
    ///
    /// - Parameter cpu: The CPU instance invoking this delegate method.
    /// - Parameter message: message to be displayed to the user.

    func invalidOpcode(_ cpu: CPU, _ message: String)
}

/// Default implementation of a CPUDelegate. Terminates on interrupt,  halt instruction, invalid memory access or
/// invalid opcode.

open class CPUDelegateAdapter: CPUDelegate {

    public init() {
    }

    public func fetched8(_ cpu: CPU, _ value: UInt8, _ instructionCount: UInt64) {
    }

    public func fetched16(_ cpu: CPU, _ value: UInt16, _ instructionCount: UInt64) {
    }

    public func interrupt(_ cpu: CPU, _ value: UInt8) {
        cpu.terminate()
    }

    public func halt(_ cpu: CPU) {
        cpu.terminate()
    }

    public func portRead8(_ cpu: CPU, _ address: UInt16) -> UInt8 {
        return 0xFF
    }

    public func portWrite8(_ cpu: CPU, _ address: UInt16, _ value: UInt8) {
    }

    public func portRead16(_ cpu: CPU, _ address: UInt16) -> UInt16 {
        return 0xFFFF
    }

    public func portWrite16(_ cpu: CPU, _ address: UInt16, _ value: UInt16) {
    }

    public func invalidMemoryAccess(_ cpu: CPU, _ memoryAddress: SegOfs, _ permissionMask: UInt8) {
        cpu.terminate()
    }

    public func invalidOpcode(_ cpu: CPU, _ message: String) {
        cpu.terminate()
    }
}
