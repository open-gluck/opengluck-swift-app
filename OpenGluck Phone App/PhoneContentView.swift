import SwiftUI

struct PhoneContentView: View {
    @EnvironmentObject var appDelegate: PhoneAppDelegate

    var body: some View {
        AppDataAutoFetch {
            OpenGluckEnvironmentUpdater {
                VStack {
                    SheetStatusView()
                    //WKDataDebugView()
                    PhoneAppTabs()
                }
            }
        }
        .environmentObject(appDelegate.openGlückConnection)
        .environmentObject(appDelegate.sheetStatusOptions)
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        PhoneContentView()
            .environmentObject(PhoneAppDelegate())
            .environmentObject(PhoneNavigationData())
    }
}
