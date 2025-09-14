import SwiftUI

struct ComplicationDebugView: View {
    @State var debugComplication: Int = 0
    @State var result: String = ""
    
    var body: some View {
        VStack {
            Form {
                Text("Current Value: \(debugComplication)")
                Text("Result: \(result)")
                Button("transferUserInfo") {
                    debugComplication += 1
                    try? WKData.default.transferUserInfo([WKDataKeys.debugComplication.rawValue: "\(debugComplication)"], replyHandler: { result in
                        self.result = result.debugDescription
                    })
                }
                Button("transferCurrentComplicationUserInfo") {
                    debugComplication += 1
                    try? WKData.default.transferCurrentComplicationUserInfo([WKDataKeys.debugComplication.rawValue: "\(debugComplication)"], replyHandler: { result in
                        self.result = result.debugDescription
                    })
                }
                Divider()
                WKDataDebugView()
            }
        }
    }
}

struct ComplicationDebugView_Previews: PreviewProvider {
    static var previews: some View {
        ComplicationDebugView()
    }
}
