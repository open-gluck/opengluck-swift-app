import SwiftUI

extension OpenGluckManager {
    static let isIpad: Bool = {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machine = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                ptr in String(validatingUTF8: ptr)
            }
        }
        
        return machine?.hasPrefix("iPad") ?? false
    }()
    
    static let isIphone: Bool = {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machine = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                ptr in String(validatingUTF8: ptr)
            }
        }
        
        return machine?.hasPrefix("iPhone") ?? false
    }()
    
    static let target = {
        if ProcessInfo.processInfo.isiOSAppOnMac {
            return "openglück.mac"
        } else if isIpad {
            return "openglück.pad"
        } else if isIphone {
            return "openglück.phone"
        } else {
            // we might return these on simulators
            return "openglück.unknown"
        }
    }()
}
