/// Domain-level errors related to webhook processing.
public enum WebhookError: Error, Equatable, Sendable {
    /// The provided source is not registered.
    case unknownSource(String)

    /// The payload cannot be decoded or validated.
    case invalidPayload(String)

    // Webhook authentication error supprimé (auth par token retirée)
}
