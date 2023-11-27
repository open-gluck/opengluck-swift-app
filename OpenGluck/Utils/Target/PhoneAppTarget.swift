import SwiftUI

extension OpenGluckManager {
    static let target = {
        if ProcessInfo.processInfo.isiOSAppOnMac {
            return "openglück.mac"
        }
        switch UIDevice.current.userInterfaceIdiom
        {
        case .phone:
            return "openglück.phone"
        case .pad:
            return "openglück.pad"
        default:
            return "openglück.unknown"
        }
    }()
}
