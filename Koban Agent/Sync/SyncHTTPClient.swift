import Foundation

struct SyncHTTPClient {
    private let transport: any SyncHTTPTransport
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        transport: any SyncHTTPTransport = URLSessionSyncHTTPTransport(),
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.transport = transport
        self.encoder = encoder
        self.decoder = decoder
    }

    func upload(_ request: SyncRequest, settings: SyncSettings) async throws -> SyncResponse {
        let urlRequest = try buildSensorURLRequest(
            request,
            settings: settings,
            routePath: SensorProtocolConstants.syncRoutePath
        )
        let (data, response) = try await transport.data(for: urlRequest)
        return try decode(SyncResponse.self, data: data, response: response)
    }

    func enroll(_ request: EnrollmentRequest, settings: SyncSettings) async throws -> EnrollmentResponse {
        let urlRequest = try buildURLRequest(
            request,
            settings: settings,
            routePath: SensorProtocolConstants.enrollRoutePath,
            token: nil
        )
        let (data, response) = try await transport.data(for: urlRequest)
        return try decode(EnrollmentResponse.self, data: data, response: response)
    }

    func getConfig(_ request: GetConfigRequest, settings: SyncSettings) async throws -> GetConfigResponse {
        let urlRequest = try buildSensorURLRequest(
            request,
            settings: settings,
            routePath: SensorProtocolConstants.configRoutePath
        )
        let (data, response) = try await transport.data(for: urlRequest)
        return try decode(GetConfigResponse.self, data: data, response: response)
    }

    func checkIn(_ request: CheckInRequest, settings: SyncSettings) async throws -> CheckInResponse {
        let urlRequest = try buildSensorURLRequest(
            request,
            settings: settings,
            routePath: SensorProtocolConstants.checkInRoutePath
        )
        let (data, response) = try await transport.data(for: urlRequest)
        return try decode(CheckInResponse.self, data: data, response: response)
    }

    func buildURLRequest(_ request: SyncRequest, settings: SyncSettings) throws -> URLRequest {
        try buildSensorURLRequest(
            request,
            settings: settings,
            routePath: SensorProtocolConstants.syncRoutePath
        )
    }

    private func decode<T: Decodable>(
        _ type: T.Type,
        data: Data,
        response: URLResponse
    ) throws -> T {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SyncUploadError.invalidResponse
        }
        guard SensorProtocolConstants.successfulHTTPStatusRange.contains(httpResponse.statusCode) else {
            throw SyncUploadError.serverStatus(httpResponse.statusCode)
        }
        return try decoder.decode(type, from: data)
    }

    private func buildSensorURLRequest(
        _ request: some Encodable,
        settings: SyncSettings,
        routePath: String
    ) throws -> URLRequest {
        try buildURLRequest(request, settings: settings, routePath: routePath, token: settings.sensorToken)
    }

    private func buildURLRequest(
        _ request: some Encodable,
        settings: SyncSettings,
        routePath: String,
        token: String?
    ) throws -> URLRequest {
        guard let endpoint = settings.endpoint else {
            throw SyncUploadError.missingEndpoint
        }
        guard let baseURL = URL(string: endpoint) else {
            throw SyncUploadError.invalidEndpoint(endpoint)
        }

        var urlRequest = URLRequest(url: routeURL(baseURL: baseURL, routePath: routePath))
        urlRequest.httpMethod = SensorProtocolConstants.httpMethodPOST
        urlRequest.setValue(
            SensorProtocolConstants.applicationJSONContentType,
            forHTTPHeaderField: SensorProtocolConstants.contentTypeHeader
        )
        if let token {
            urlRequest.setValue(token, forHTTPHeaderField: SensorProtocolConstants.sensorTokenHeader)
        }
        urlRequest.httpBody = try encoder.encode(request)
        return urlRequest
    }

    private func routeURL(baseURL: URL, routePath: String) -> URL {
        baseURL.appending(path: routePath)
    }
}
