import SwiftUI
@preconcurrency import OG // FIXME LATER TODO upgrade lib
import OGUI

#if OPENGLUCK_CONTACT_TRICK_IS_YES
struct ContactsPermissionGrantStatus: View {
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @EnvironmentObject var openGlückConnection: OpenGluckConnection
    @State var granted: Bool? = nil
    
    private func sync() {
        granted = openGlückConnection.contactsUpdater.granted
    }

    var body: some View {
        HStack {
            Text("Contact Permission Status:")
            Spacer()
            if let granted {
                if granted {
                    Text("Granted")
                        .foregroundStyle(.green)
                } else {
                    Text("Denied")
                        .foregroundStyle(.red)
                }
            } else {
                Text("Unknown")
                    .foregroundStyle(.gray)
            }
        }
        .onReceive(timer) { _ in
            sync()
        }
        .onAppear {
            sync()
        }
    }
}
struct ContactsFoundStatus: View {
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @EnvironmentObject var openGlückConnection: OpenGluckConnection
    @State var found: Bool? = nil
    
    private func sync() {
        guard openGlückConnection.contactsUpdater.granted != nil else {
            found = false
            return
        }
        do {
            found = try openGlückConnection.contactsUpdater.contact != nil
        } catch {
            found = false
        }
    }

    var body: some View {
        HStack {
            Text("Contact Found:")
            Spacer()
            if let found {
                if found {
                    Text("Found")
                        .foregroundStyle(.green)
                } else {
                    Text("Missing")
                        .foregroundStyle(.red)
                }
            } else {
                Text("Unknown")
                    .foregroundStyle(.gray)
            }
        }
        .onReceive(timer) { _ in
            sync()
        }
        .onAppear {
            sync()
        }
    }
}

#endif

struct PhoneAdvancedView: View {
    @EnvironmentObject var appDelegate: PhoneAppDelegate
    @State var openglückUrl: String = ""
    @State var openglückToken: String = ""
    @AppStorage(WKDataKeys.phoneDeviceToken.keyValue, store: OpenGluckManager.userDefaults) var phoneDeviceToken: String = ""
    @AppStorage(WKDataKeys.watchDeviceToken.keyValue, store: OpenGluckManager.userDefaults) var watchDeviceToken: String = ""
    @AppStorage(WKDataKeys.enableUpdateBadgeCount.keyValue, store: OpenGluckManager.userDefaults) var enableUpdateBadgeCount: Bool = false
    @EnvironmentObject var openGlückConnection: OpenGluckConnection
#if OPENGLUCK_CONTACT_TRICK_IS_YES
    @AppStorage(WKDataKeys.enableContactTrick.keyValue, store: OpenGluckManager.userDefaults) var enableContactTrick: Bool = false
    @AppStorage(WKDataKeys.enableContactTrickDebug.keyValue, store: OpenGluckManager.userDefaults) var enableContactTrickDebug: Bool = false
#endif

    @State var isUrlOk: Bool = true

    var body: some View {
        NavigationStack {
            Form {
                Section("OpenGlück"){
                    LabeledContent("Server hostname") {
                        TextField("", text: $openglückUrl)
                            .onChange(of: openglückUrl) {
                                if (try? openglückUrl.firstMatch(of: Regex("^[a-z0-9:.]+$"))) != nil {
                                    appDelegate.openglückUrl = openglückUrl
                                    isUrlOk = true
                                } else {
                                    isUrlOk = false
                                }
                            }
                            .foregroundColor(isUrlOk ? nil : Color.red)
                    }
                    LabeledContent("Token") {
                        TextField("", text: $openglückToken)
                            .onChange(of: openglückToken) {
                                appDelegate.openglückToken = openglückToken
                            }
                    }
                }
                
                #if OPENGLUCK_CONTACT_TRICK_IS_YES
                Section("Contact Trick") {
                    VStack(alignment: .leading) {
                        Text("The Contact Trick will update the photo of a contact whose email is og@opengluck.com to your current blood glucose in the background.")
                        Text("")
                        Text("You can then use the built-in Contacts widget on your watch to add this contact to your watch face. This will show your current blood glucose.")
                        Text("")
                        Text("This trick is useful to work around WidgetKit restrictions, but might result in out-of-date measurements shown on your watch. Advise caution.")
                    }
                    .font(.caption)
                    Toggle("Enable the Contact Trick", isOn: .init(get: {
                        enableContactTrick
                    }, set: { newValue in
                        enableContactTrick = newValue
                        if newValue {
                            Task {
                                // this will re-sync the contact
                                openGlückConnection.contactsUpdater.checkIfUpToDate()
                                let _ = try? await openGlückConnection.getCurrentData(becauseUpdateOf: "PhoneAdvancedView", force: true)
                            }
                        }
                    }))
                    if enableContactTrick {
                        VStack(alignment: .leading) {
                            Text("If you enable the Contact Trick, we need access to your Contacts so that we can update the photo of the OpenGlück contact. You can always grant us the permission from the Settings app on your phone.")
                            Text("")
                            Text("We will update the photo of the contact whose email is og@opengluck.com.")
                        }
                        .font(.caption)
                        ContactsPermissionGrantStatus()
                        ContactsFoundStatus()
                    }
                    VStack(alignment: .leading) {
                        Text("Having issues? You might enable Debug Mode.\n\nThis will make the app update the first name of the contact with debug infos. We still need to update the last name with internal data regardless of this setting.")
                    }
                    .font(.caption)
                    Toggle("Enable Debug Mode", isOn: .init(get: {
                        enableContactTrickDebug
                    }, set: { newValue in
                        enableContactTrickDebug = newValue
                        if newValue {
                            Task {
                                // this will re-sync the contact
                                try? await openGlückConnection.getCurrentData(becauseUpdateOf: "PhoneAdvancedView", force: true)
                            }
                        }
                    }))
                }
                #endif
                
                Section("Application Badge") {
                    VStack(alignment: .leading) {
                        Text("Checking this will update the badge count to the latest known blood glucose.")
                    }
                    .font(.caption)
                    Toggle("Update Badge Count", isOn: .init(get: {
                        enableUpdateBadgeCount
                    }, set: { newValue in
                        enableUpdateBadgeCount = newValue
                        let openGlückConnection = openGlückConnection
                        if newValue {
                            Task {
                                // this will update the badge count
                                let _ = try? await openGlückConnection.getCurrentData(becauseUpdateOf: "PhoneAdvancedView", force: true)
                            }
                        }
                    }))
                }
                
                NavigationLink("Display") {
                    DisplayPreferencesView()
                }
                
                Section("App Version") {
                    LabeledContent("OG") {
                        Text("\(OG.VERSION)")
                    }
                    LabeledContent("OGUI") {
                        Text("\(OGUI.VERSION)")
                    }
                }

                Section("Dev Tools") {
                    NavigationLink("View Glucose Numbers") {
                        
                        GlucoseNumbersView()
                    }
                    LabeledContent("DEBUG") {
                        #if DEBUG
                        Text("DEBUG")
                        #else
                        Text("Not debug")
                        #endif
                    }
                    LabeledContent("OpenGlück.target") {
                        Text(OpenGluckManager.target)
                    }
                    LabeledContent("apsEnvironment") {
                        Text("\(MobileProvision.read()?.entitlements.apsEnvironment.rawValue.description ?? "nil")")
                    }
                    LabeledContent("apnAppSuffix") {
                        Text("\(OG.apnAppSuffix)")
                    }
                    LabeledContent("Phone Token") {
                        TextField("", text: .init(get: {
                            return phoneDeviceToken
                        }, set: { _ in
                        }))
                    }
                    LabeledContent("Watch Token") {
                        TextField("", text: .init(get: {
                            return watchDeviceToken
                        }, set: { _ in
                        }))
                    }
                    /*NavigationLink("Complication Debug View") {
                        ComplicationDebugView()
                    }*/
                }
            }.onAppear {
                openglückUrl = appDelegate.openglückUrl
                openglückToken = appDelegate.openglückToken
                #if OPENGLUCK_CONTACT_TRICK_IS_YES
                if enableContactTrick {
                    Task {
                        // this will re-sync the contact
                        try? await openGlückConnection.getCurrentData(becauseUpdateOf: "PhoneAdvancedView", force: true)
                    }
                }
                #endif
            }
        }
    }
}

#Preview {
    PhoneAdvancedView()
        .environmentObject(PhoneAppDelegate())
        .environmentObject(OpenGluckConnection())
}
