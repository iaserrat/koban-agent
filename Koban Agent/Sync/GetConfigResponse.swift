import Foundation

struct GetConfigResponse: Codable, Hashable {
    var generation: String
    var configJSON: Data
    var signature: Data

    private enum CodingKeys: String, CodingKey {
        case generation
        case configJSON = "configJson"
        case signature
    }

    init(generation: String, configJSON: Data, signature: Data) {
        self.generation = generation
        self.configJSON = configJSON
        self.signature = signature
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        generation = try container.decode(String.self, forKey: .generation)
        configJSON = try container.decodeIfPresent(Data.self, forKey: .configJSON) ?? Data()
        signature = try container.decodeIfPresent(Data.self, forKey: .signature) ?? Data()
    }
}
