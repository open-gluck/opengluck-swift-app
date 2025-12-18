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
        // Return empty results - we only support receiving notifications, not searching messages
        let response = INSearchForMessagesIntentResponse(code: .success, userActivity: nil)
        response.messages = []
        completion(response)
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
