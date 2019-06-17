import Foundation

struct GribDecoder {
    // Source of GRIB data
    private var source: GribDecodable
    // The current bit offset
    private var currentOffset: UInt = 0
    
    public init(source: GribDecodable) {
        self.source = source
    }
    
    // MARK:- Reading File
    
    // Reads bits from the source
    public mutating func readBits(at offset: UInt? = nil, length: UInt) throws -> UInt {
        // Move file pointer
        seek(to: offset ?? currentOffset)
        // Set up
        var bitsToRead = length
        var byteOffset = currentOffset / 8 // currentOffset
        let bitOffset = currentOffset % 8 // bitIndex
        let masks = [1, 3, 7, 15, 31, 63, 127, 255] as [UInt8]
        var bitsRead: UInt = 0
        // Helper function
        func readByte(at offset: UInt) throws -> UInt8 {
            return try source.readBytes(at: offset, amount: 1)[0]
        }
        // Splice the first byte
        let amountOfBitsToReadFromTheFirstByte = min(8 - bitOffset, bitsToRead)
        let byte = try readByte(at: byteOffset)
        let mask = masks[Int(7 - bitOffset)]
        bitsRead = UInt(byte & mask)
        // Check if all the bits are contained within the first byte
        if (amountOfBitsToReadFromTheFirstByte != (8 - bitOffset)) {
            bitsRead = bitsRead >> (8 - bitOffset - amountOfBitsToReadFromTheFirstByte)
        }
        byteOffset += 1
        bitsToRead -= amountOfBitsToReadFromTheFirstByte
        // Append whole bytes
        while bitsToRead >= 8 {
            bitsRead = bitsRead << 8 | UInt(try readByte(at: byteOffset))
            bitsToRead -= 8
            byteOffset += 1
        }
        // Splice last byte for remaining bits
        if bitsToRead > 0 {
            bitsRead = (bitsRead << bitsToRead) | UInt((try readByte(at: byteOffset) >> (8 - bitsToRead)) & masks[Int(bitsToRead - 1)])
        }
        // Update file pointer
        currentOffset += length
        return bitsRead
    }
    
    public mutating func readBytes(at offset: UInt, amount: UInt) throws -> [UInt8] {
        guard amount > 0 else { return [] }
        var bytes = [] as [UInt8]
        // Check if we are reading whole bytes.
        if offset % 8 == 0 && amount % 8 == 0 {
            bytes = try source.readBytes(at: offset / 8, amount: amount)
            currentOffset = offset + (amount * 8)
        } else {
            // Otherwise read using bit offset
            for _ in 0 ..< amount {
                let bits = UInt8(truncatingIfNeeded: try readBits(length: 8))
                bytes.append(bits)
            }
        }
        // Check that the bytes where read correctly
        guard bytes.count == amount else { throw GribDecodingError.noDataAvailable }
        return bytes
    }
    
    // Read bytes without moving file pointer
    public mutating func peek(at offset: UInt? = nil, amount: UInt) throws -> [UInt8] {
        let bitOffset = offset ?? currentOffset
        let bytes = try readBytes(at: bitOffset, amount: amount)
        // Restore the file pointer
        self.currentOffset = bitOffset
        return bytes
    }
    
    // MARK:- Seeking File
    
    // This moves the byte offset pointer back
    public mutating func rewind(amount: UInt? = nil) {
        self.currentOffset -= amount ?? currentOffset
    }
    
    // This moves the byte offset pointer forward
    public mutating func skip(amount: UInt) {
        self.currentOffset += amount
    }
    
    // This moves the offset pointer to a given byte offset
    public mutating func seek(to offset: UInt, bitIndex index: UInt? = nil) {
        self.currentOffset = offset
    }
    
    // MARK:- Decoding Values
    
    public mutating func decodeUInt8(at offset: UInt? = nil) throws -> UInt {
        return try readBits(at: offset, length: 8)
    }
    
    public mutating func decodeUInt16(at offset: UInt? = nil) throws -> UInt {
        return try readBits(at: offset, length: 16)
    }
    
    public mutating func decodeUInt32(at offset: UInt? = nil) throws -> UInt {
        return try readBits(at: offset, length: 32)
    }
    
    public mutating func decodeUInt64(at offset: UInt? = nil) throws -> UInt {
        return try readBits(at: offset, length: 64)
    }
    
    public mutating func decodeInt8(at offset: UInt? = nil) throws -> Int {
        return Int(bitPattern: try readBits(at: offset, length: 8))
    }
    
    public mutating func decodeInt16(at offset: UInt? = nil) throws -> Int {
        return Int(bitPattern: try readBits(at: offset, length: 16))
    }
    
    public mutating func decodeInt32(at offset: UInt? = nil) throws -> Int {
        return Int(bitPattern: try readBits(at: offset, length: 32))
    }
    
    public mutating func decodeInt64(at offset: UInt? = nil) throws -> Int {
        return Int(bitPattern: try readBits(at: offset, length: 64))
    }
    
    public mutating func decodeFloat32(at offset: UInt? = nil) throws -> Float {
        let bits = try readBits(at: offset, length: 32)
        return Float(bitPattern: UInt32(bits))
    }
    
    public mutating func decodeRepeatedBitFieldValue(at offset: UInt? = nil, wordLength: UInt, numberOfValues count: UInt) throws -> [UInt] {
        var values = [] as [UInt]
        let capacity = Int(bitPattern: count)
        // Allocate Memory
        values.reserveCapacity(capacity)
        guard values.capacity >= Int(bitPattern: count) && capacity > 0 else {
            throw GribDecodingError.insufficientMemoryAvailable
        }
        // Move file pointer
        seek(to: offset ?? currentOffset)
        // Read Values
        for _ in 0 ..< count {
            let bits = try readBits(length: wordLength)
            values.append(bits)
        }
        return values
    }
}
