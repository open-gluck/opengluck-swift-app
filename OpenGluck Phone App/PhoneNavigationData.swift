import SwiftUI

class PhoneNavigationData: ObservableObject {
    static let urlAddLow: URL = URL(string: "opengluck://add-low")!
    static let urlAddInsulin: URL = URL(string: "opengluck://add-insulin")!
    static let urlRecords: URL = URL(string: "opengluck://records")!
    
    
    struct PathAddLow: Hashable {}
    struct PathAddInsulin: Hashable {}

    enum Tabs {
        case graph
        case records
        case advanced
    }

    @Published var currentTab: Tabs = .graph
    @Published var path: NavigationPath = NavigationPath()
    
    func deeplink(toURL url: URL) {
        guard url.scheme == "opengluck"/*, let components = URLComponents(url: url, resolvingAgainstBaseURL: true), let queryItems = components.queryItems*/ else {
            return
        }
        
        if url.host == "add-insulin" {
            self.currentTab = .graph
            self.path.append(PhoneNavigationData.PathAddInsulin())
        } else if url.host == "add-low" {
            self.currentTab = .graph
            self.path.append(PhoneNavigationData.PathAddLow())
        } else if url.host == "records" {
            self.currentTab = .records
        } else if url.host == "advanced" {
            self.currentTab = .advanced
        }
    }
}
