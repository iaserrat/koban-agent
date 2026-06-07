enum SyncResetLabels {
    static let sectionTitle = "Local identity"
    static let identityLabel = "Enrollment"
    static let buttonTitle = "Reset sync identity"
    static let helpText = "Deletes the saved tenant and device identity, then restarts monitoring."
    static let confirmationTitle = "Reset sync identity?"
    static let confirmationButton = "Reset identity"
    static let cancelButton = "Cancel"
    static let confirmationMessage = "Koban will enroll again using the saved sync configuration."
    static let reenrollmentFailedMessage = """
    Identity was cleared but the device could not enroll again. Koban will retry automatically.
    """
    static let reloadInProgressMessage = "A configuration reload is in progress. Try again in a moment."

    static func errorPrefix(_ message: String) -> String {
        "Reset failed: \(message)"
    }
}
