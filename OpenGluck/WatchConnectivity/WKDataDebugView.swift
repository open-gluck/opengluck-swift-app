import SwiftUI
import WatchConnectivity

struct WKDataDebugView: View {
    #if os(iOS)
    static let ourEmoji: WKDataKeys = WKDataKeys.debugPhoneEmoji
    static let otherEmoji: WKDataKeys = WKDataKeys.debugWatchEmoji
    #else
    static let ourEmoji: WKDataKeys = WKDataKeys.debugWatchEmoji
    static let otherEmoji: WKDataKeys = WKDataKeys.debugPhoneEmoji
    #endif

    @AppStorage(WKDataDebugView.otherEmoji.keyValue, store: OpenGluckManager.userDefaults) var ourEmoji: String = "(none)"
    @AppStorage(WKDataDebugView.otherEmoji.keyValue, store: OpenGluckManager.userDefaults) var otherEmoji: String = "(none)"

    private func sendEmoji(emoji: String) {
        try? WKData.default.set(key: WKDataDebugView.ourEmoji, value: emoji)
    }

    struct PropsView: View {
        let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
        @State var rerender: UUID? = UUID()

        var body: some View {
            VStack {
                if rerender != nil {
                    let session = WCSession.default
                    Text("State=\(session.activationState.rawValue)")
                    Text("Oustanding UserInfos=\(session.outstandingUserInfoTransfers.debugDescription)")
                    Text("Oustanding File=\(session.outstandingFileTransfers.debugDescription)")
                    #if os(iOS)
                    Text("remainingComplicationUserInfoTransfers=\(session.remainingComplicationUserInfoTransfers)")
                    #endif
#if os(iOS)
                    Text("Paired=\(session.isPaired.description)")
                    Text("Watch App=\(session.isWatchAppInstalled.description)")
                    Text("Complication Enabled=\(session.isComplicationEnabled.description)")
#endif
                    Text("Reachable=\(session.isReachable.description)")
                    Text("\(Date().ISO8601Format())")
                }
            }.onReceive(timer) { _ in
                rerender = UUID()
            }
        }
    }

    var body: some View {
        VStack {
            Text("Other: \(otherEmoji)")
            PropsView()
            HStack {
                Button("🤗") {
                    sendEmoji(emoji: "🤗")
                }
                .padding()
                .backgroundStyle(ourEmoji == "🤗" ? Color.green : Color.gray)
                Button("🚂") {
                    sendEmoji(emoji: "🚂")
                }
                .padding()
                .backgroundStyle(ourEmoji == "🚂" ? Color.green : Color.gray)
                Button("✈️") {
                    sendEmoji(emoji: "✈️")
                }
                .padding()
                .backgroundStyle(ourEmoji == "✈️" ? Color.green : Color.gray)
            }
        }
    }
}

struct WKDataDebugView_Previews: PreviewProvider {
    static var previews: some View {
        WKDataDebugView()
    }
}
