import Foundation

public struct GribDecodingError: Error {
    
    public enum Operation {
        case openingFile
        case readingFile
        case seekingFile
        case memoryAllocation
    }
    
    public let operation: Operation
    public let description: String
    
    public init(operation: Operation, description: String) {
        self.operation = operation
        self.description = description
    }
    
    public static let noDataAvailable = GribDecodingError(operation: .readingFile,
                                                          description: "Cannot read outside the bounds of the source data.")
    
    public static let incorrectDataFormat = GribDecodingError(operation: .readingFile,
                                                              description: "Failed to cast value to selected type.")
    
    public static let insufficientMemoryAvailable = GribDecodingError(operation: .memoryAllocation,
                                                                      description: "Not enough system memory to unpack this field.")
    
    public static let cannotSeekFile = GribDecodingError(operation: .seekingFile,
                                                         description: "Failed to move the file pointer.")
    
}
