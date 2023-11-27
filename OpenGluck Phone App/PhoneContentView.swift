import SwiftUI

struct PhoneContentView: View {
    @EnvironmentObject var appDelegate: PhoneAppDelegate

    var body: some View {
        AppDataAutoFetch {
            OpenGluckEnvironmentUpdater {
                VStack {
                    //WKDataDebugView()
                    PhoneAppTabs()
                }
            }
        }
        .environmentObject(appDelegate.openGlückConnection)
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        PhoneContentView()
            .environmentObject(PhoneAppDelegate())
    }
}
