import Foundation

struct URLSessionSyncHTTPTransport: SyncHTTPTransport {
    private let session: URLSession
    private let delegate: SyncClientCertificateDelegate?

    init(
        configuration: URLSessionConfiguration = .default,
        delegate: SyncClientCertificateDelegate = SyncClientCertificateDelegate()
    ) {
        self.delegate = delegate
        session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
    }

    init(session: URLSession) {
        delegate = nil
        self.session = session
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await session.data(for: request)
    }
}
