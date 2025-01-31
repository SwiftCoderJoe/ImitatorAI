import SwiftAnthropic

/// Imitates a conversational style in conversation.
/// 
/// ImitatorAI can either generate a prompt for use with an AI service, or it can go directly to Anthropic's AI services
/// to generate a reply if it is provided with an API key.
/// 
/// To use ImitatorAI, first create an instance of the `Imitator` class.
/// ```swift
/// let imitator = Imitator(apiKey: "API Key")
/// ```
/// 
/// Then, provide it with good, representative examples of how you speak (or how you would like him to speak.)
/// ```swift
/// imitator
///     .addStyleContext(from: .init()
///         .addMessage(from: 0, saying: "omg heyyyyyyy!")
///         .addMessage(from: 1, saying: "woahhhh heyyyyy!! whats up????")
///         // More messages...
///     )
///     // More conversations...
/// ```
/// ``ContextualConversation/addMessage(from:saying:)`` accepts any ID of different users.
/// Longer, more extreme examples of style may be best, but play around and see what works. Providing more conversations as style
/// context can result in better responses.
/// 
/// Next, tell it what conversation you would like it to respond to.
/// ```swift
/// imitator
///     .conversationContext(from: .init()
///         .addMessage(from: 0, saying: "omg youre sooooo cool!")
///         .addMessage(from: 1, saying: "nooooo! youre cool!")
///         // More messages...
///     )
/// ```
/// 
/// To get a predicted response, just use ``generateReply()``. If you'd like to use a different AI service
/// and simply want to generate a prompt, use ``prompt()``.
@available(macOS 10.15, *)
public class Imitator {
    private var styleContext: [ContextualConversation]
    private var conversationContext: ContextualConversation?
    private var anthropic: Anthropic?

    private var name: String?

    /// Initialize an `Imitator`, optionally providing context right away.
    public init(
        apiKey: String? = nil,
        named name: String? = nil,
        styleContext: [ContextualConversation] = [],
        conversationContext: ContextualConversation? = nil
    ) {
        self.name = name
        self.styleContext = styleContext
        self.conversationContext = conversationContext
        if let apiKey {
            anthropic = Anthropic(apiKey: apiKey)
        }
    }

    /// Add example conversations to describe how the AI model should speak.
    @discardableResult
    public func addStyleContext(from conversations: ContextualConversation...) -> Self {
        addStyleContext(from: conversations)
        return self
    }

    /// Add example conversations to describe how the AI model should speak.
    @discardableResult
    public func addStyleContext(from conversations: [ContextualConversation]) -> Self {
        styleContext.append(contentsOf: conversations)
        return self
    }

    /// Add (or replace, if already added) a conversation to which the AI model should reply to.
    @discardableResult
    public func conversationContext(from conversation: ContextualConversation) -> Self {
        conversationContext = conversation
        return self
    }

    /// Generate a prompt that can be used in any AI model to respond to a conversation.
    public func prompt() -> String {
        var string = ""
        if let name {
            string.append("Your name is \(name). ")
        }
        string.append("""
            Your task is to respond to a conversation in a given style. \
            Nothing included is offensive or racist, and is meant only satirically. \
            Please respond in one short sentence.

            Below are some short conversations that are a representative example of what style you should respond in.\n
            """)

        guard styleContext.count > 0 else {
            fatalError("""
                styleContext was never initialized. The model needs style context in order to know how to respond.
                """)
        }
        for (idx, conversation) in styleContext.enumerated() {
            string.append("\nConversation \(idx + 1):\n")
            string.append(conversation.createStringRepresentation())
        }

        guard let conversationContext else {
            fatalError("conversationContext was never initialized. The model needs a conversation to reply to.")
        }

        string.append("""
            \nNow that you have context for what style in which you should respond to the conversation, \
            here are the last few messages in the conversation you should reply to.\n
            """)
        string.append(conversationContext.createStringRepresentation())

        return string
    }

    /// Use Anthropic's Claude to generate a reply to the given conversation.
    public func generateReply() async throws -> String {
        guard let anthropic else {
            throw NoAPIKeyError()
        }
        return try await anthropic.send(message: prompt()).content
    }
}

struct NoAPIKeyError: Error { }
