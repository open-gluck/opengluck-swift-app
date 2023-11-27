import Foundation
import SwiftUI

struct WKComplicationDebugView: View {
    @State var debugComplicationInt: Int = -1
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack {
            Text("DCI=\(debugComplicationInt)")
        }
        .onReceive(timer) { _ in
            debugComplicationInt = OpenGluckManager.userDefaults.integer(forKey: WKDataKeys.debugComplication.keyValue)
        }
    }
}

struct WKComplicationDebugView_Previews: PreviewProvider {
    static var previews: some View {
        WKComplicationDebugView()
    }
}
