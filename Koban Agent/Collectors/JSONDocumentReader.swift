import Foundation

/// Reads JSON and JSONC documents into decodable models.
struct JSONDocumentReader {
    func decode<T: Decodable>(_ type: T.Type, from url: URL) throws -> T {
        try Task.checkCancellation()
        let text = try String(contentsOf: url, encoding: .utf8)
        try Task.checkCancellation()
        let stripped = JSONCommentStripper.stringByRemovingComments(from: text)
        try Task.checkCancellation()
        let data = Data(stripped.utf8)
        return try JSONDecoder().decode(type, from: data)
    }
}
