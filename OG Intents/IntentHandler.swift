//
//  IntentHandler.swift
//  OG Intents
//
//  Created by Christopher Allène on 18/12/2025.
//

// ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
// ┃                                                                             ┃
// ┃   ⚠️  IMPORTANT: SIRI PERMISSION REQUIRED FOR CARPLAY TO WORK  ⚠️           ┃
// ┃                                                                             ┃
// ┃   Open Glück MUST be allowed to work with Siri before CarPlay               ┃
// ┃   notifications will function properly.                                     ┃
// ┃                                                                             ┃
// ┃   To enable this, the user must do ONE of the following:                    ┃
// ┃                                                                             ┃
// ┃   1. Ask Siri: "Hey Siri, open Open Glück"                                  ┃
// ┃      - OR -                                                                 ┃
// ┃   2. Ask Siri: "Hey Siri, read my messages in Open Glück"                   ┃
// ┃                                                                             ┃
// ┃   This grants Siri permission to interact with the app.                     ┃
// ┃                                                                             ┃
// ┃   UNTIL THIS IS DONE:                                                       ┃
// ┃   - Clicking notifications in CarPlay will say "Something went wrong"       ┃
// ┃   - The intent handlers below will never be called                          ┃
// ┃                                                                             ┃
// ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

import Intents
import os.log

private let logger = Logger(subsystem: "open-gluck.github.io.ios.OG-Intents", category: "IntentHandler")

class IntentHandler: INExtension {

    override func handler(for intent: INIntent) -> Any {
        logger.info("handler(for:) called with intent type: \(type(of: intent))")

        if intent is INSearchForMessagesIntent {
            logger.info("Returning SearchForMessagesIntentHandler")
            return SearchForMessagesIntentHandler()
        }
        if intent is INSendMessageIntent {
            logger.info("Returning SendMessageIntentHandler")
            return SendMessageIntentHandler()
        }
        if intent is INSetMessageAttributeIntent {
            logger.info("Returning SetMessageAttributeIntentHandler")
            return SetMessageAttributeIntentHandler()
        }
        logger.warning("No matching handler for intent type: \(type(of: intent))")
        return self
    }
}

// MARK: - INSearchForMessagesIntentHandling

class SearchForMessagesIntentHandler: NSObject, INSearchForMessagesIntentHandling {

    func handle(intent: INSearchForMessagesIntent, completion: @escaping (INSearchForMessagesIntentResponse) -> Void) {
        logger.info("SearchForMessagesIntentHandler.handle() called")

        let response = INSearchForMessagesIntentResponse(code: .success, userActivity: nil)

        // Return the last notification as a message for Siri to read
        if let lastMessage = getLastMessage() {
            logger.info("Returning message with content: \(lastMessage.content ?? "nil")")
            response.messages = [lastMessage]
        } else {
            logger.info("getLastMessage() returned nil - no message to read")
            response.messages = []
        }
        completion(response)
    }
    
    // Prepares notification text for Siri TTS:
    // - Removes the glucose unit “mg/dL” (case-insensitive, allows spaces around the slash)
    //   to avoid awkward pronunciation (e.g., “em gee slash dee ell”).
    // - Strips emoji and common emoji modifiers/variation selectors so the spoken output
    //   focuses on the meaningful content.
    // - Normalizes whitespace after removals so the final string sounds natural.
    private func improveMessageBodyForTTS(_ body: String) -> String {
        // Remove emojis and common emoji modifiers/variation selectors
        func stripEmoji(from s: String) -> String {
            var scalars = String.UnicodeScalarView()
            scalars.reserveCapacity(s.unicodeScalars.count)
            for scalar in s.unicodeScalars {
                switch scalar.value {
                case 0xFE0E, 0xFE0F: // variation selectors
                    continue
                case 0x1F3FB...0x1F3FF: // skin tone modifiers
                    continue
                case 0x1F000...0x1FFFF, // many emoji blocks
                     0x2600...0x27BF:   // misc symbols/dingbats
                    continue
                default:
                    scalars.append(scalar)
                }
            }
            return String(scalars)
        }
        
        // Remove mg/dL (case-insensitive, optional spaces around slash)
        func stripMgDl(_ s: String) -> String {
            let pattern = #"(?i)\bmg\s*/\s*dL\b"#
            return s.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
        }
        
        // Collapse extra whitespace
        func cleanSpaces(_ s: String) -> String {
            let squashed = s.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            return squashed.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        let noEmoji = stripEmoji(from: body)
        let noUnits = stripMgDl(noEmoji)
        return cleanSpaces(noUnits)
    }

    // Read the last notification from shared storage for Siri to read
    private func getLastMessage() -> INMessage? {
        // Debug: verify app group entitlement is applied
        let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.open-gluck.github.io.ios")
        logger.info("App group container URL: \(containerURL?.path ?? "nil (ENTITLEMENT NOT APPLIED)")")

        let defaults = UserDefaults(suiteName: "group.open-gluck.github.io.ios")
        let body = defaults?.string(forKey: "lastNotificationBody")
        let sender = defaults?.string(forKey: "lastNotificationSender")
        let date = defaults?.object(forKey: "lastNotificationDate") as? Date

        // Debug logging
        logger.info("suite exists: \(defaults != nil), body: \(body ?? "nil"), sender: \(sender ?? "nil"), date: \(String(describing: date))")

        guard defaults != nil, let body, let sender, let date else {
            logger.info("returning nil - missing data")
            return nil
        }

        let handle = INPersonHandle(value: "notifications@opengluck.com", type: .emailAddress)
        let senderPerson = INPerson(
            personHandle: handle,
            nameComponents: nil,
            displayName: "OG",
            image: nil,
            contactIdentifier: nil,
            customIdentifier: nil
        )

        return INMessage(
            identifier: UUID().uuidString,
            content: improveMessageBodyForTTS("\(sender); \(body)"),
            dateSent: date,
            sender: senderPerson,
            recipients: nil
        )
    }

    func resolveRecipients(for intent: INSearchForMessagesIntent, with completion: @escaping ([INPersonResolutionResult]) -> Void) {
        completion([])
    }

    func resolveSenders(for intent: INSearchForMessagesIntent, with completion: @escaping ([INPersonResolutionResult]) -> Void) {
        completion([])
    }

    func resolveAttributes(for intent: INSearchForMessagesIntent, with completion: @escaping (INMessageAttributeOptionsResolutionResult) -> Void) {
        completion(.success(with: .unread))
    }
}

// MARK: - INSendMessageIntentHandling

class SendMessageIntentHandler: NSObject, INSendMessageIntentHandling {

    func handle(intent: INSendMessageIntent, completion: @escaping (INSendMessageIntentResponse) -> Void) {
        logger.info("SendMessageIntentHandler.handle() called - returning success")
        // Return success to prevent "something went wrong" when user taps notification in CarPlay.
        // We don't actually send messages, but returning success allows the interaction to complete gracefully.
        let response = INSendMessageIntentResponse(code: .success, userActivity: nil)
        completion(response)
    }

    func resolveRecipients(for intent: INSendMessageIntent, with completion: @escaping ([INSendMessageRecipientResolutionResult]) -> Void) {
        // No recipients needed - we only receive notifications
        completion([])
    }

    func resolveContent(for intent: INSendMessageIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
        // No content resolution needed
        completion(.notRequired())
    }
}

// MARK: - INSetMessageAttributeIntentHandling

class SetMessageAttributeIntentHandler: NSObject, INSetMessageAttributeIntentHandling {

    func handle(intent: INSetMessageAttributeIntent, completion: @escaping (INSetMessageAttributeIntentResponse) -> Void) {
        // After Siri reads a message, it calls this to mark it as read.
        // We don't track read state, so just return success.
        let response = INSetMessageAttributeIntentResponse(code: .success, userActivity: nil)
        completion(response)
    }
}
