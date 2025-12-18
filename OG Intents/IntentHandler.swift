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
