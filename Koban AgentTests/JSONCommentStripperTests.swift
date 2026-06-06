import Foundation
import Testing
@testable import Koban_Agent

struct JSONCommentStripperTests {
    @Test
    func removesLineAndBlockCommentsWithoutTouchingStrings() {
        let input = #"""
        {
          // comment
          "url": "https://example.com/path//kept",
          /* block */
          "command": "echo /* kept */"
        }
        """#

        let stripped = JSONCommentStripper.stringByRemovingComments(from: input)

        #expect(stripped.contains("comment") == false)
        #expect(stripped.contains("block") == false)
        #expect(stripped.contains("https://example.com/path//kept"))
        #expect(stripped.contains("echo /* kept */"))
    }
}
