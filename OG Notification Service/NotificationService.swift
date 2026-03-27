import UserNotifications
import Intents

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

        // Debug: verify app group entitlement is applied
        let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.open-gluck.github.io.ios")
        print("NotificationService: App group container URL:", containerURL?.path ?? "nil (ENTITLEMENT NOT APPLIED)")

        guard let bestAttemptContent else {
            contentHandler(request.content)
            return
        }

        // Set category for CarPlay support
        if bestAttemptContent.categoryIdentifier.isEmpty {
            bestAttemptContent.categoryIdentifier = "DEFAULT"
        }

        // Set time-sensitive to break through Focus modes (including Driving)
        bestAttemptContent.interruptionLevel = .timeSensitive
        
        // Play custom alert sound
        bestAttemptContent.sound = UNNotificationSound(named: UNNotificationSoundName("alert_sound.caf"))

        let senderEmail: String = "notifications@opengluck.com"
        let toMeEmail: String = "me@opengluck.com"
        let openGluckName: String = "Open Glück"

        let senderHandle = INPersonHandle(value: senderEmail, type: .emailAddress)
        let toMeHandle = INPersonHandle(value: toMeEmail, type: .emailAddress)

        // Use PersonNameComponents as shown in the reference gist
        var senderNameComponents = PersonNameComponents()
        senderNameComponents.nickname = bestAttemptContent.title

        let sender = INPerson(
            personHandle: senderHandle,
            nameComponents: senderNameComponents,
            displayName: bestAttemptContent.title,
            image: nil,
            contactIdentifier: nil,
            customIdentifier: "opengluck-sender",
            isMe: false,
            suggestionType: .none
        )
        let toMe = INPerson(
            personHandle: toMeHandle,
            nameComponents: nil,
            displayName: nil,
            image: nil,
            contactIdentifier: nil,
            customIdentifier: "opengluck-me",
            isMe: true,
            suggestionType: .none
        )

        let intent = INSendMessageIntent(
            recipients: [toMe],
            outgoingMessageType: .outgoingMessageText,
            content: request.content.body,
            speakableGroupName: INSpeakableString(spokenPhrase: openGluckName),
            conversationIdentifier: "opengluck-notifications",
            serviceName: nil,
            sender: sender,
            attachments: nil
        )

        // Donate the intent so iOS learns about this sender
        let interaction = INInteraction(intent: intent, response: nil)
        interaction.direction = .incoming
        interaction.donate { error in
            if let error = error {
                print("NotificationService: Intent donation FAILED: \(error)")
            } else {
                print("NotificationService: Intent donation succeeded")
            }
        }

        // Store notification content for Siri to read via IntentHandler
        if let defaults = UserDefaults(suiteName: "group.open-gluck.github.io.ios") {
            defaults.set(bestAttemptContent.body, forKey: "lastNotificationBody")
            defaults.set(bestAttemptContent.title, forKey: "lastNotificationSender")
            defaults.set(Date(), forKey: "lastNotificationDate")

            // Debug: verify write
            print("NotificationService wrote:",
                  "sender:", defaults.string(forKey: "lastNotificationSender") ?? "nil",
                  "body:", defaults.string(forKey: "lastNotificationBody") ?? "nil",
                  "date:", defaults.object(forKey: "lastNotificationDate") ?? "nil")
        } else {
            print("NotificationService: ERROR - Could not access app group UserDefaults")
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
