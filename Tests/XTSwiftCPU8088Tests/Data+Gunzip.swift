// Data+Gunzip.swift
// XT Copyright © 2026; Electric Bolt Limited.

import Compression
import Foundation

enum GzipError : Error {
    case invalidHeader
    case corruptData
    case decodingFailed
}

/// Single step tests are gzipped to save disk space.

extension Data {
    
    /// Decompress a GZIP-wrapped Data object.
    /// - Returns: Data object.
    /// - Throws: GzipError if .gz file could not be decompressed.
    
    func decompressGzip() throws -> Data {
        // Since Compression framework's COMPRESSION_ZLIB algorithm only understands raw DEFLATE streams, this strips
        // the 10-byte gzip header (and any optional fields) plus the trailing 8-byte CRC32/ISIZE footer before decoding.
        guard self.count > 18 else { throw GzipError.invalidHeader }
        
        let bytes = [UInt8](self)
        
        // Magic bytes 0x1f 0x8b, compression method must be 8 (deflate)
        guard bytes[0] == 0x1f, bytes[1] == 0x8b, bytes[2] == 0x08 else {
            throw GzipError.invalidHeader
        }
        
        let flags = bytes[3]
        var offset = 10 // fixed header: magic(2) + method(1) + flags(1) + mtime(4) + xfl(1) + os(1)
        
        if flags & 0x04 != 0 { // FEXTRA
            guard offset + 2 <= bytes.count else { throw GzipError.corruptData }
            let xlen = Int(bytes[offset]) | (Int(bytes[offset + 1]) << 8)
            offset += 2 + xlen
        }
        if flags & 0x08 != 0 { // FNAME (null-terminated)
            while offset < bytes.count, bytes[offset] != 0 { offset += 1 }
            offset += 1
        }
        if flags & 0x10 != 0 { // FCOMMENT (null-terminated)
            while offset < bytes.count, bytes[offset] != 0 { offset += 1 }
            offset += 1
        }
        if flags & 0x02 != 0 { // FHCRC
            offset += 2
        }
        
        guard offset < bytes.count - 8 else {
            throw GzipError.corruptData
        }
        
        // Strip trailing 8 bytes (CRC32 + ISIZE) — not used by raw deflate decoding.
        let deflateData = self.subdata(in: offset..<(self.count - 8))
        
        return try decodeRawDeflate(deflateData)
    }
    
    private func decodeRawDeflate(_ sourceData: Data) throws -> Data {
        let stream = UnsafeMutablePointer<compression_stream>.allocate(capacity: 1)
        defer { stream.deallocate() }

        var status = compression_stream_init(stream, COMPRESSION_STREAM_DECODE, COMPRESSION_ZLIB)
        guard status != COMPRESSION_STATUS_ERROR else {
            throw GzipError.decodingFailed
        }
        defer { compression_stream_destroy(stream) }

        let bufferSize = 64 * 1024
        var outputData = Data()
        let outputBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { outputBuffer.deallocate() }

        try sourceData.withUnsafeBytes { (rawBufferPointer: UnsafeRawBufferPointer) in
            guard let sourcePointer = rawBufferPointer.bindMemory(to: UInt8.self).baseAddress else {
                throw GzipError.decodingFailed
            }

            stream.pointee.src_ptr = sourcePointer
            stream.pointee.src_size = sourceData.count

            repeat {
                stream.pointee.dst_ptr = outputBuffer
                stream.pointee.dst_size = bufferSize

                let flags: Int32 = stream.pointee.src_size == 0 ? Int32(COMPRESSION_STREAM_FINALIZE.rawValue) : 0
                status = compression_stream_process(stream, flags)

                guard status != COMPRESSION_STATUS_ERROR else {
                    throw GzipError.decodingFailed
                }

                let bytesWritten = bufferSize - stream.pointee.dst_size
                if bytesWritten > 0 {
                    outputData.append(outputBuffer, count: bytesWritten)
                }
            } while status == COMPRESSION_STATUS_OK
        }

        return outputData
    }
}
