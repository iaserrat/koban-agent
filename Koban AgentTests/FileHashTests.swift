import Foundation
import Testing
@testable import Koban_Agent

struct FileHashTests {
    @Test
    func computesStableSHA256Digest() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let url = directory.appending(path: "payload.txt")
            try Data("abc".utf8).write(to: url)

            let hash = try FileHash.sha256(url)

            #expect(hash == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
        }
    }

    @Test
    func streamsFilesLargerThanOneChunk() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let url = directory.appending(path: "large.bin")
            let first = Data(
                repeating: UInt8(ascii: "a"),
                count: ConfigurationDefaults.fileHashReadChunkBytes
            )
            let second = Data("tail".utf8)
            try (first + second).write(to: url)

            let hash = try FileHash.sha256(url)

            #expect(hash == "bc7b226ad091282cb14c2025b5cca519e6e007ff4a1e375ae70aa5a7937c96d2")
        }
    }
}
