import Foundation
import Testing
@testable import Koban_Agent

struct FileDescriptorLimitTests {
    @Test
    func raisesGUIDefaultSoftLimitToSystemMaximum() {
        // A GUI-launched macOS process inherits a soft limit of 256 and an unlimited hard
        // limit; Koban must raise the soft limit to the per-process ceiling so FSEvents plus
        // SQLite do not exhaust the table.
        let target = FileDescriptorLimit.raisedSoftLimit(
            soft: 256,
            hard: FileDescriptorLimit.noLimit,
            systemMaximum: 61440
        )

        #expect(target == 61440)
    }

    @Test
    func clampsToFiniteHardLimitWhenLowerThanSystemMaximum() {
        let target = FileDescriptorLimit.raisedSoftLimit(
            soft: 256,
            hard: 10240,
            systemMaximum: 61440
        )

        #expect(target == 10240)
    }

    @Test
    func clampsToSystemMaximumWhenBelowHardLimit() {
        let target = FileDescriptorLimit.raisedSoftLimit(
            soft: 256,
            hard: FileDescriptorLimit.noLimit,
            systemMaximum: 10240
        )

        #expect(target == 10240)
    }

    @Test
    func returnsNilWhenSoftLimitAlreadyMeetsCeiling() {
        let target = FileDescriptorLimit.raisedSoftLimit(
            soft: 61440,
            hard: FileDescriptorLimit.noLimit,
            systemMaximum: 61440
        )

        #expect(target == nil)
    }

    @Test
    func neverLowersAnAlreadyGenerousSoftLimit() {
        // A terminal-launched process can start at ~1M; raising must be a no-op, never a cut.
        let target = FileDescriptorLimit.raisedSoftLimit(
            soft: 1_048_576,
            hard: FileDescriptorLimit.noLimit,
            systemMaximum: 61440
        )

        #expect(target == nil)
    }
}
