import Foundation

protocol SyncHTTPTransport: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}
