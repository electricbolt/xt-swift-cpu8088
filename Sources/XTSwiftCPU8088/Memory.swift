// Memory.swift
// XT Copyright © 2025-2026; Electric Bolt Limited.

import Foundation

public class Memory {

    public static let PERMISSION_EXECUTE: UInt8 = 0x01
    public static let PERMISSION_READ: UInt8 = 0x02
    public static let PERMISSION_WRITE: UInt8 = 0x04

    public static let MEMORY_SIZE: Int = 1024 * 1024 // 1MB

    /// Creates 1MB of accessible RAM for the CPU.
    ///
    /// This initializer should only be called by the CPU or unit tests. See also `CPU.memory` property.
    ///
    /// - Parameter hasPermissions: If true, enable capturing invalid memory reads, writes, and execution. The default
    /// is false. If true, then Memory.PERMISSION＿EXECUTE, Memory.PERMISSION＿READ and Memory.PERMISSION＿WRITE
    /// will be applied to every byte.
    /// - Parameter zeroMemory: If true, initializes the RAM to all zeros. For unit-testing it is orders of magnitude
    /// quicker to set this parameter to false. Note that in a physical PC, RAM would contain random values when
    /// powered on. The default is false.

    public init(hasPermissions: Bool = false, zeroMemory: Bool = false) {
        buf = UnsafeMutableBufferPointer.allocate(capacity: Memory.MEMORY_SIZE)
        if zeroMemory {
            buf.initialize(repeating: 0)
        }
        if hasPermissions {
            permissions = UnsafeMutableBufferPointer.allocate(capacity: Memory.MEMORY_SIZE)
            permissions!.initialize(repeating: Memory.PERMISSION_EXECUTE | Memory.PERMISSION_READ | Memory.PERMISSION_WRITE)
        }
    }

    public func fromBitmask(_ permissionBitmask: UInt8) -> String {
        var buf = ""
        if (permissionBitmask & Memory.PERMISSION_EXECUTE) == Memory.PERMISSION_EXECUTE {
            buf += "EXECUTE "
        }
        if (permissionBitmask & Memory.PERMISSION_READ) == Memory.PERMISSION_READ {
            buf += "READ "
        }
        if (permissionBitmask & Memory.PERMISSION_WRITE) == Memory.PERMISSION_WRITE {
            buf += "WRITE "
        }
        return buf.trimmingCharacters(in: .whitespaces)
    }

    public func applyPermission(_ linearAddress: Int, _ size: Int, _ permissionBitmask: UInt8) {
        if let permissions = permissions {
            for i in linearAddress..<(linearAddress + size) {
                permissions[i] |= permissionBitmask
            }
        }
    }

    public func removePermission(_ linearAddress: Int, _ size: Int, _ permissionBitmask: UInt8) {
        if let permissions = permissions {
            for i in linearAddress..<(linearAddress + size) {
                permissions[i] &= ~permissionBitmask
            }
        }
    }

    /// Gets an 8-bit byte from memory at the specified segment:offset without any memory protection bits.
    ///
    /// If the segment:offset computes to a linear address of greater than 0xFFFFF, it is wrapped around to the beginning
    /// of the address space at 0x00000.

    public func getByte(_ segOfs: SegOfs) -> UInt8 {
        let address = segOfs.toLinearAddress()
        return buf[address]
    }

    /// Sets an 8-bit byte to memory at the specified segment:offset without any memory protection bits.
    ///
    /// If the segment:offset computes to a linear address of greater than 0xFFFFF, it is wrapped around to the beginning
    /// of the address space at 0x00000.

    public func setByte(_ segOfs: SegOfs, _ value: UInt8) {
        let address = segOfs.toLinearAddress()
        buf[address] = value
    }

    /// Gets a 16-bit instruction from memory at the specified segment:offset without any memory protection bits.
    ///
    /// If the offset value is 0xFFFF, then the low byte uses offset 0xFFFF. The high byte wraps to the beginning of the
    /// segment and uses offset 0x0000. If the segment:offset computes to a linear address of greater than 0xFFFFF, it is
    /// wrapped around to the beginning of the address space at 0x00000.

    public func getWord(_ segOfs: SegOfs) -> UInt16 {
        let segOfs = segOfs.copy()
        let lo = getByte(segOfs)
        segOfs.increment()
        let hi = getByte(segOfs)
        return UInt16(hi) << 8 | UInt16(lo)
    }

    /// Sets a 16-bit word to memory at the specified segment:offset without any memory protection bits.
    ///
    /// If the offset value is 0xFFFF, then the low byte uses offset 0xFFFF. The high byte wraps to the beginning of the
    /// segment and uses offset 0x0000. If the segment:offset computes to a linear address of greater than 0xFFFFF, it is
    /// wrapped around to the beginning of the address space at 0x00000.

    public func setWord(_ segOfs: SegOfs, _ value: UInt16) {
        let segOfs = segOfs.copy()
        setByte(segOfs, UInt8(truncatingIfNeeded: value))
        segOfs.increment()
        setByte(segOfs, UInt8(truncatingIfNeeded: value >> 8))
    }

    /// Sets a 32-bit word to memory at the specified segment:offset without any memory protection bits.
    ///
    /// Whilst writing the 4 bytes to memory, the offset value can wrap from 0xFFFF to 0x0000. If the segment:offset
    /// computes to a linear address of greater than 0xFFFFF, it is wrapped around to the beginning of the address space
    /// at 0x00000.

    public func setDoubleWord(_ segOfs: SegOfs, _ value: UInt32) {
        let segOfs = segOfs.copy()
        setByte(segOfs, UInt8(truncatingIfNeeded: value))
        segOfs.increment()
        setByte(segOfs, UInt8(truncatingIfNeeded: value >> 8))
        segOfs.increment()
        setByte(segOfs, UInt8(truncatingIfNeeded: value >> 16))
        segOfs.increment()
        setByte(segOfs, UInt8(truncatingIfNeeded: value >> 24))
    }

    /// Reads an 8-bit byte from memory at the specified segment:offset.
    ///
    /// If the segment:offset computes to a linear address of greater than 0xFFFFF, it is wrapped around to the beginning
    /// of the address space at 0x00000. Invokes delegate.invalidMemoryAccess() if the memory address is not readable
    /// (Memory.PERMISSION_READ).

    public func readByte(_ segOfs: SegOfs) -> UInt8 {
        let address = segOfs.toLinearAddress()
        let value = buf[address]
        if let permissions = permissions, (permissions[address] & Memory.PERMISSION_READ) == 0 {
            cpu?.delegate.invalidMemoryAccess(cpu!, segOfs, Memory.PERMISSION_READ)
        }
        return value
    }

    /// Reads an 8-bit instruction byte from memory at the specified segment:offset.
    ///
    /// If the segment:offset computes to a linear address of greater than 0xFFFFF, it is wrapped around to the beginning
    /// of the address space at 0x00000. Invokes delegate.invalidMemoryAccess() if the memory address is not executable
    /// (Memory.PERMISSION_EXECUTE).

    public func fetchByte(_ segOfs: SegOfs) -> UInt8 {
        let address = segOfs.toLinearAddress()
        let value = buf[address]
        if let permissions = permissions, (permissions[address] & Memory.PERMISSION_EXECUTE) == 0 {
            cpu?.delegate.invalidMemoryAccess(cpu!, segOfs, Memory.PERMISSION_EXECUTE)
        }
        return value
    }

    /// Writes an 8-bit byte to memory at the specified segment:offset.
    ///
    /// If the segment:offset computes to a linear address of greater than 0xFFFFF, it is wrapped around to the beginning
    /// of the address space at 0x00000. Invokes delegate.invalidMemoryAccess() if the memory address is not writable
    /// (Memory.PERMISSION_WRITE).

    public func writeByte(_ segOfs: SegOfs, _ value: UInt8) {
        let address = segOfs.toLinearAddress()
        if let permissions = permissions, (permissions[address] & Memory.PERMISSION_WRITE) == 0 {
            cpu?.delegate.invalidMemoryAccess(cpu!, segOfs, Memory.PERMISSION_WRITE)
        }
        buf[address] = value
    }

    /// Reads a 16-bit word from memory at the specified segment:offset.
    ///
    /// If the offset value is 0xFFFF, then the low byte uses offset 0xFFFF. The high byte wraps to the beginning of the
    /// segment and uses offset 0x0000. If the segment:offset computes to a linear address of greater than 0xFFFFF, it is
    /// wrapped around to the beginning of the address space at 0x00000. Invokes delegate.invalidMemoryAccess() if the
    /// memory address is not readable (Memory.PERMISSION_READ).

    public func readWord(_ segOfs: SegOfs) -> UInt16 {
        let segOfs = segOfs.copy()
        let lo = readByte(segOfs)
        segOfs.increment()
        let hi = readByte(segOfs)
        return UInt16(hi) << 8 | UInt16(lo)
    }

    /// Reads a 16-bit instruction from memory at the specified segment:offset.
    ///
    /// If the offset value is 0xFFFF, then the low byte uses offset 0xFFFF. The high byte wraps to the beginning of the
    /// segment and uses offset 0x0000. If the segment:offset computes to a linear address of greater than 0xFFFFF, it is
    /// wrapped around to the beginning of the address space at 0x00000. Invokes delegate.invalidMemoryAccess() if the
    /// memory address is not executable (Memory.PERMISSION_EXECUTE).

    public func fetchWord(_ segOfs: SegOfs) -> UInt16 {
        let segOfs = segOfs.copy()
        let lo = fetchByte(segOfs)
        segOfs.increment()
        let hi = fetchByte(segOfs)
        return UInt16(hi) << 8 | UInt16(lo)
    }

    /// Writes a 16-bit word to memory at the specified segment:offset.
    ///
    /// If the offset value is 0xFFFF, then the low byte uses offset 0xFFFF. The high byte wraps to the beginning of the
    /// segment and uses offset 0x0000. If the segment:offset computes to a linear address of greater than 0xFFFFF, it is
    /// wrapped around to the beginning of the address space at 0x00000. Invokes delegate.invalidMemoryAccess() if the
    /// memory address is not writable (Memory.PERMISSION_WRITE).

    public func writeWord(_ segOfs: SegOfs, _ value: UInt16) {
        let segOfs = segOfs.copy()
        writeByte(segOfs, UInt8(truncatingIfNeeded: value))
        segOfs.increment()
        writeByte(segOfs, UInt8(truncatingIfNeeded: value >> 8))
    }

    // MARK: - Internal

    var buf: UnsafeMutableBufferPointer<UInt8>
    private var permissions: UnsafeMutableBufferPointer<UInt8>?
    unowned var cpu: CPU? = nil

    deinit {
        buf.deallocate()
        permissions?.deallocate()
    }

    /// Reads bytes directly from linear memory at the specified address 0x00000 - 0xFFFFF without any memory protection
    /// bits.
    ///
    /// Should only be used by unit tests. Terminates with a fatal error if linearAddress (+size) is not within the range above.

    func getLinearData(_ linearAddress: Int, _ size: Int) -> [UInt8] {
        if size <= 0 || size > Memory.MEMORY_SIZE {
            fatalError("size argument (\(size)) is not in range 0..\(Memory.MEMORY_SIZE - 1)")
        }
        if linearAddress < 0 || linearAddress + size >= Memory.MEMORY_SIZE {
            fatalError("linearAddress argument (\(linearAddress)) is not in range 0..\(Memory.MEMORY_SIZE - 1)")
        }
        return Array(buf[linearAddress..<(linearAddress + size)])
    }

    /// Writes bytes directly to linear memory at the specified address 0x00000 - 0xFFFFF without any memory protection
    /// bits.
    ///
    /// Should only be used by unit tests. Terminates with a fatal error if linearAddress (+size) is not within the range above.

    func putLinearData(_ linearAddress: Int, _ data: [UInt8], _ srcPos: Int, _ length: Int) {
        if data.isEmpty || data.count > Memory.MEMORY_SIZE {
            fatalError("data argument (\(data.count)) is not in range 0..\(Memory.MEMORY_SIZE - 1)")
        } else if linearAddress < 0 || linearAddress >= Memory.MEMORY_SIZE {
            fatalError("linearAddress \(linearAddress) not in range 0..\(Memory.MEMORY_SIZE - 1)")
        }
        data.withUnsafeBytes { dataPtr in
            _ = memcpy(buf.baseAddress! + linearAddress, dataPtr.baseAddress! + srcPos, length)
        }
    }

    /// Reads a byte directly from linear memory at the specified address 0x00000 - 0xFFFFF without any memory protection
    /// bits.
    ///
    /// Should only be used by unit tests. Terminates with a fatal error if linearAddress is not within the range above.

    func getLinearByte(_ linearAddress: Int) -> UInt8 {
        return buf[linearAddress]
    }

    /// Writes a byte directly to linear memory at the specified address 0x00000 - 0xFFFFF without any memory protection
    /// bits.
    ///
    /// Should only be used by unit tests. Terminates with a fatal error if linearAddress is not within the range above.

    func setLinearByte(_ linearAddress: Int, _ value: UInt8) {
        buf[linearAddress] = value
    }
}
