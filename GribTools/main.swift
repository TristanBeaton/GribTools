import Foundation

do {
    let filePath = "/Users/tristanbeaton/Developer/tempswinds.grb2"
    let fileHandle = FileHandle(forReadingAtPath: filePath)!
    
    var decoder = GribDecoder(source: fileHandle)
    let bytes = try decoder.readBytes(at: 0, amount: 4)
    let stringValue = String(bytes: bytes, encoding: .utf8)!
    
    print(stringValue) // GRIB
    
    func section(at offset: UInt? = nil) -> (UInt?, UInt?) {
        guard let sectionLength = try? decoder.decodeUInt32(at: offset) else { return (nil, nil) }
        // 'GRIB'
        if sectionLength == 1196575042 {
            decoder.rewind(amount: 4) // move back to start of section
            return (0, 16)
        }
        // '7777'
        if sectionLength == 926365495 {
            decoder.rewind(amount: 4) // move back to start of section
            return (8, 4)
        }
        // Check section number
        guard let sectionNumber = try? decoder.decodeUInt8() else { return (nil, nil) }
        decoder.rewind(amount: 5) // move back to start of section
        guard sectionNumber < 8 else { return (nil, nil) }
        return (sectionNumber, sectionLength)
    }
    
    
    var sectionNumber: UInt?
    var sectionLength: UInt?
    var offset = 0 as UInt
    
    (sectionNumber, sectionLength) = section(at: offset)
    
    while sectionNumber != nil && sectionLength != nil{
        print(sectionNumber!, sectionLength!)
        offset +=  sectionLength! * 8
        (sectionNumber, sectionLength) = section(at: offset)
    }
} catch let error as GribDecodingError {
    print(error)
}
