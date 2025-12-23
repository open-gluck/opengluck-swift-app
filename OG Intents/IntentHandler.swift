//
//  IntentHandler.swift
//  OG Intents
//
//  Created by Christopher Allène on 18/12/2025.
//

import Intents

class IntentHandler: INExtension {

    override func handler(for intent: INIntent) -> Any {
        if intent is INSearchForMessagesIntent {
            return SearchForMessagesIntentHandler()
        }
        if intent is INSendMessageIntent {
            return SendMessageIntentHandler()
        }
        return self
    }
}

// MARK: - INSearchForMessagesIntentHandling

class SearchForMessagesIntentHandler: NSObject, INSearchForMessagesIntentHandling {

    func handle(intent: INSearchForMessagesIntent, completion: @escaping (INSearchForMessagesIntentResponse) -> Void) {
        let response = INSearchForMessagesIntentResponse(code: .success, userActivity: nil)

        // Return the last notification as a message for Siri to read
        if let lastMessage = getLastMessage() {
            response.messages = [lastMessage]
        } else {
            response.messages = []
        }
        completion(response)
    }

    // Read the last notification from shared storage for Siri to read
    private func getLastMessage() -> INMessage? {
        guard let defaults = UserDefaults(suiteName: "group.open-gluck.github.io.ios"),
              let body = defaults.string(forKey: "lastNotificationBody"),
              let sender = defaults.string(forKey: "lastNotificationSender"),
              let date = defaults.object(forKey: "lastNotificationDate") as? Date else {
            return nil
        }

        let handle = INPersonHandle(value: "notifications@opengluck.com", type: .emailAddress)
        let senderPerson = INPerson(
            personHandle: handle,
            nameComponents: nil,
            displayName: sender,
            image: nil,
            contactIdentifier: nil,
            customIdentifier: nil
        )

        return INMessage(
            identifier: UUID().uuidString,
            content: body,
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
        // This handler exists solely to enable CarPlay notification support.
        // We don't send messages - notifications are incoming only.
        // Return failure to indicate this app doesn't support sending messages,
        // but the intent declaration enables CarPlay to display our incoming notifications.
        let response = INSendMessageIntentResponse(code: .failureRequiringAppLaunch, userActivity: nil)
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
