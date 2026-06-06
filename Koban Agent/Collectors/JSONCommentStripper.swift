import Foundation

/// Removes JSONC comments while preserving string contents.
enum JSONCommentStripper {
    static func stringByRemovingComments(from text: String) -> String {
        var output = ""
        var index = text.startIndex
        var isInsideString = false
        var isEscaped = false

        while index < text.endIndex {
            let character = text[index]
            let nextIndex = text.index(after: index)
            let nextCharacter = nextIndex < text.endIndex ? text[nextIndex] : nil

            if isInsideString {
                output.append(character)
                if isEscaped {
                    isEscaped = false
                } else if character == JSONSyntax.escape {
                    isEscaped = true
                } else if character == JSONSyntax.quote {
                    isInsideString = false
                }
                index = nextIndex
                continue
            }

            if character == JSONSyntax.quote {
                isInsideString = true
                output.append(character)
                index = nextIndex
                continue
            }

            if character == JSONSyntax.slash, nextCharacter == JSONSyntax.slash {
                index = skipLineComment(from: nextIndex, in: text)
                continue
            }

            if character == JSONSyntax.slash, nextCharacter == JSONSyntax.asterisk {
                index = skipBlockComment(from: nextIndex, in: text)
                continue
            }

            output.append(character)
            index = nextIndex
        }

        return output
    }

    private static func skipLineComment(from index: String.Index, in text: String) -> String.Index {
        var cursor = text.index(after: index)
        while cursor < text.endIndex, text[cursor].isNewline == false {
            cursor = text.index(after: cursor)
        }
        return cursor
    }

    private static func skipBlockComment(from index: String.Index, in text: String) -> String.Index {
        var cursor = text.index(after: index)
        while cursor < text.endIndex {
            let next = text.index(after: cursor)
            if text[cursor] == JSONSyntax.asterisk, next < text.endIndex, text[next] == JSONSyntax.slash {
                return text.index(after: next)
            }
            cursor = next
        }
        return cursor
    }
}
