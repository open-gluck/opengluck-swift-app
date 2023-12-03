import SwiftUI

struct AppDataContext: Codable {
    static let jsonDecoder: JSONDecoder = JSONDecoder()
    
    struct Redirect: Codable {
        let title: String
        let message: String
        let button: String
        let url: String
    }
    
    let redirect: Redirect?
    
    static func read(fromURL url: URL) throws -> Foundation.Data {
        let data = try Data(contentsOf: url)
        return data
    }
    
    static func read(fromData data: Foundation.Data) throws -> AppDataContext {
        let context = try jsonDecoder.decode(Self.self, from: data)
        return context
    }
}

struct AppDataView<Content>: View where Content: View {
    let context: AppDataContext?
    @ViewBuilder let content: () -> Content
    @State var isPresented: Bool = false
    
    var body: some View {
        content()
            .task(id: context?.redirect != nil) {
                if context?.redirect != nil {
                    isPresented = true
                }
            }
            .alert(context?.redirect?.title ?? "", isPresented: $isPresented) {
                if let redirect = context?.redirect {
                    Button(redirect.button) {
                        UIApplication.shared.open(URL(string: redirect.url)!)
                        Task {
                            try? await Task.sleep(for: .seconds(0.5))
                            isPresented = true
                        }
                    }
                }
            }
    }
}

fileprivate actor AppDataAutoFetcher {
    static let `default`: AppDataAutoFetcher = AppDataAutoFetcher()
    
    @AppStorage("AppDataAutoFetch.cachedContext") var cachedAppDataContextData: Foundation.Data = Foundation.Data()
    private var preventRefreshUntil: Date? = nil

    private static let dateFormatter: ISO8601DateFormatter = ISO8601DateFormatter()
    private static let jsonEncoder: JSONEncoder = JSONEncoder()

    func read() -> Foundation.Data? {
        return { () -> Foundation.Data? in
            if let preventRefreshUntil, Date() < preventRefreshUntil {
                return nil
            }
            
            guard let infoDictionary: [String: Any] = Bundle.main.infoDictionary else { return nil }

            // check if build expired
            if let appDataExpireAt: String = infoDictionary["OPENGLUCK_APPDATA_EXPIRE_AT"] as? String, !appDataExpireAt.isEmpty,
               let appDataExpireMessage: String = infoDictionary["OPENGLUCK_APPDATA_EXPIRE_MESSAGE"] as? String, !appDataExpireMessage.isEmpty {
                let expireAt: Date = Self.dateFormatter.date(from: appDataExpireAt)!
                if Date() > expireAt {
                    let message = AppDataContext(redirect: AppDataContext.Redirect(title: "App Expired", message: appDataExpireMessage, button: "Close", url: "https://www.opengluck.com"))
                    return try! Self.jsonEncoder.encode(message)
                    
                }
            }

            // check remote data
            if let appDataUrl: String = infoDictionary["OPENGLUCK_APPDATA_URL"] as? String, !appDataUrl.isEmpty {
                preventRefreshUntil = Date().addingTimeInterval(3600) // do not refresh for at least one hour
                if let appDataContextData = try? AppDataContext.read(fromURL: URL(string: appDataUrl)!) {
                    cachedAppDataContextData = appDataContextData
                    return appDataContextData
                }
            }
            return nil
        }() ?? {
            return cachedAppDataContextData
        }()
    }
}

@MainActor
struct AppDataAutoFetch<Content>: View where Content: View {
    let timer = Timer.publish(every: 86400, on: .main, in: .common).autoconnect()
    @ViewBuilder let content: () -> Content
    @State var appDataContext: AppDataContext? = nil
    
    private func refreshAppDataContext() {
        Task.detached {
            if let appDataContextData = await AppDataAutoFetcher.default.read() {
                await MainActor.run {
                    //                        cachedAppDataContextData = appDataContextData
                }
                let appDataContext = try AppDataContext.read(fromData: appDataContextData)
                await MainActor.run {
                    self.appDataContext = appDataContext
                }
            }
        }
    }
    
    var body: some View {
        AppDataView(context: appDataContext) {
            content()
        }
            .onReceive(timer, perform: { _ in
                refreshAppDataContext()
            })
            .task {
                refreshAppDataContext()
            }
    }
}

#Preview {
    AppDataView(context: AppDataContext(redirect: nil)) {
        Text("Foo")
    }
}

#Preview("Update Required") {
    AppDataView(context: AppDataContext(redirect: .init(title: "App Needs Update", message: "Needs update", button: "Update", url: "https://example.com/alice"))) {
        Text("Foo")
    }
}
