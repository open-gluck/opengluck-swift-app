import SwiftUI

struct TVSettingsView: View {
    @State var openglückUrl: String = ""
    @State var openglückToken: String = ""
    @State var isUrlOk: Bool = true

    
    var body: some View {
        Form {
            Section("OpenGlück"){
                LabeledContent("Server hostname") {
                    TextField("", text: $openglückUrl)
                        .onChange(of: openglückUrl) {
                            if (try? openglückUrl.firstMatch(of: Regex("^[a-z0-9:.]+$"))) != nil {
                                OpenGluckManager.userDefaults.set(openglückUrl, forKey: WKDataKeys.openglückUrl.keyValue)
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
                            OpenGluckManager.userDefaults.set(openglückToken, forKey: WKDataKeys.openglückToken.keyValue)
                        }
                }
            }
        }
        .task {
            openglückUrl = OpenGluckManager.openglückUrl ?? ""
            openglückToken = OpenGluckManager.openglückToken ?? ""
        }
    }
}

#Preview {
    TVSettingsView()
}
