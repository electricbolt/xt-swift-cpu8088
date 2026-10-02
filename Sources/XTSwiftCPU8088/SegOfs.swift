// SegOfs.swift
// XT Copyright © 2025-2026; Electric Bolt Limited.

import Foundation

public class SegOfs: CustomStringConvertible, Equatable {

    public init(_ segment: Reg16, _ offset: Reg16) {
        self.segment = segment.getValue()
        self.offset = offset.getValue()
    }

    public init(_ segment: Reg16, _ offset: UInt16) {
        self.segment = segment.getValue()
        self.offset = offset
    }

    public init(_ segment: UInt16, _ offset: UInt16) {
        self.segment = segment
        self.offset = offset
    }

    public func getSegment() -> UInt16 {
        return segment
    }

    public func setSegment(_ segment: UInt16) {
        self.segment = segment
    }

    public func getOffset() -> UInt16 {
        return offset
    }

    public func setOffset(_ offset: UInt16) {
        self.offset = offset
    }

    public func copy() -> SegOfs {
        return SegOfs(segment, offset)
    }

    public func addOffset(_ value: UInt16) {
        offset = offset &+ value
    }

    public func increment() {
        addOffset(1)
    }

    public func decrement() {
        addOffset(0xFFFF)
    }

    public var description: String {
        return String(format: "%04X:%04X (%05X %d)", segment, offset, toLinearAddress(), toLinearAddress())
    }

    public func toLinearAddress() -> Int {
        var address = Int(segment) << 4
        address = address + Int(offset)
        address %= Memory.MEMORY_SIZE
        return address
    }

    /// Returns true if the addresses being compared have the same computed linear address.

    public static func == (lhs: SegOfs, rhs: SegOfs) -> Bool {
        return lhs.toLinearAddress() == rhs.toLinearAddress()
    }

    // MARK: - Internal

    private var segment: UInt16
    private var offset: UInt16
}
