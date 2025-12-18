import UserNotifications
import Intents

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

        guard let bestAttemptContent else {
            contentHandler(request.content)
            return
        }

        // Set category for CarPlay support
        if bestAttemptContent.categoryIdentifier.isEmpty {
            bestAttemptContent.categoryIdentifier = "DEFAULT"
        }

        let senderEmail: String = "notifications@opengluck.com"
        let conversationIdentifier: String? = nil

        // Create the sender identity
        let handle = INPersonHandle(value: senderEmail, type: .emailAddress)

        // Create sender - iOS should match the email to whitelisted contacts
        let sender = INPerson(
            personHandle: handle,
            nameComponents: nil,
            displayName: bestAttemptContent.title,
            image: nil,
            contactIdentifier: nil,
            customIdentifier: nil
        )

        let intent = INSendMessageIntent(
            recipients: nil,
            outgoingMessageType: .outgoingMessageText,
            content: request.content.body,
            speakableGroupName: nil,
            conversationIdentifier: conversationIdentifier,
            serviceName: nil,
            sender: sender,
            attachments: nil
        )

        // Donate the intent so iOS learns about this sender
        let interaction = INInteraction(intent: intent, response: nil)
        interaction.direction = .incoming
        interaction.donate { error in
            if let error = error {
                print("Intent donation failed: \(error)")
            }
        }

        // Update the notification with the intent
        do {
            let updatedContent = try bestAttemptContent.updating(from: intent)
            contentHandler(updatedContent)
        } catch {
            print("Failed to update notification with intent: \(error)")
            contentHandler(bestAttemptContent)
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

}
