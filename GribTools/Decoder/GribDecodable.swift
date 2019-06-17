import Foundation

public protocol GribDecodable {
    
    func readBytes(at offset: UInt, amount: UInt) throws -> [UInt8]
}

extension FileHandle: GribDecodable {
    
    public func readBytes(at offset: UInt, amount: UInt) throws -> Array<UInt8> {
        // Move the file pointer
        self.seek(toFileOffset: UInt64(offset))
        // Read bytes
        let data = readData(ofLength: Int(bitPattern: amount))
        let bytes = Array(data)
        // Check that bytes were read correctly
        guard bytes.count == amount else {
            throw GribDecodingError.noDataAvailable
        }
        return bytes
    }
}

extension InputStream: GribDecodable {
    
    public func readBytes(at offset: UInt, amount: UInt) throws -> Array<UInt8> {
        // Move the file pointer
        guard self.setProperty(offset, forKey: .fileCurrentOffsetKey) else {
            throw GribDecodingError.cannotSeekFile
        }
        // Create a buffer to store bytes read from stream
        var bytes = [] as [UInt8]
        let response = read(&bytes, maxLength: MemoryLayout<UInt8>.size)
        // Check that bytes were read correctly
        guard response == amount else {
            throw GribDecodingError.noDataAvailable
        }
        return bytes
    }
}
