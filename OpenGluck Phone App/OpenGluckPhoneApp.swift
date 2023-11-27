import SwiftUI
import Contacts
import BackgroundTasks
import WatchConnectivity
import WidgetKit

@main
struct OpenGluckPhoneApp: App {
    //@UIApplicationDelegateAdaptor(PhoneAppDelegate.self) var appDelegate
    @UIApplicationDelegateAdaptor private var appDelegate: PhoneAppDelegate
    
#if OPENGLUCK_CONTACT_TRICK_IS_YES
    private let timer = Timer.publish(every: 60, on: .main, in: .default).autoconnect()
#endif
    var body: some Scene {
        WindowGroup {
            VStack {
                PhoneContentView()
                    .preferredColorScheme(.dark)
            }
            .onAppear {
                WidgetCenter.shared.reloadAllTimelines()
            }
#if OPENGLUCK_CONTACT_TRICK_IS_YES
            .onReceive(timer, perform: { _ in
                appDelegate.openGlückConnection.contactsUpdater.checkIfUpToDate()
            })
#endif
        }
    }
}
