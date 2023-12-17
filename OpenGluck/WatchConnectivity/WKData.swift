import Foundation
import WatchConnectivity

/*
 * A class to transfer and synchronize dictionnaries between the phone and watch,
 * and keep them in sync to the UserDefaults.
 * Implementors are suggested to use @AppStorage to read the values, and call
 * sendMessage here when a value is updated, so that the other part knows it.
 */

class WKData: ObservableObject {
    enum WKDataError: Error {
        case notSupported
        case notActive
        case noWatchApp
        case notReachable
        case transferUserInfoNotSupportedInSimulator
    }

    private enum Mode {
        case transferUserInfo
        #if os(iOS)
        case transferCurrentComplicationUserInfo
        #endif
        case sendMessage
    }

    private struct Message {
        let mode: Mode
        let userInfo: [String:Any]
        let replyHandler: (([String : Any]) -> Void)?
        let errorHandler: ((Error) -> Void)?
    }

    static let `default` = WKData()
    private init() {}

#if os(iOS)
    let ourName = "Phone"
    let otherName = "Watch"
#else
    let ourName = "Watch"
    let otherName = "Phone"
#endif

    private var messagesQueue: [Message] = []

    private func sanityCheck() throws {
        guard WCSession.isSupported() else {
            print("WCSession is not supported")
            throw WKDataError.notSupported
        }
    }

    func transferUserInfo(_ userInfo: [String:Any], replyHandler: (([String : Any]) -> Void)? = nil) throws {
        try sanityCheck()
        let message = Message(mode: .transferUserInfo, userInfo: userInfo, replyHandler: replyHandler, errorHandler: nil)
        messagesQueue.append(message)
        try flush()
    }

    func sendMessage(_ userInfo: [String:Any], errorHandler: ((Error) -> Void)? = nil) throws {
        try sanityCheck()
        let message = Message(mode: .sendMessage, userInfo: userInfo, replyHandler: nil, errorHandler: errorHandler)
        messagesQueue.append(message)
        try flush()
    }

    func sendMessage(_ userInfo: [String:Any], replyHandler: (([String : Any]) -> Void)?, errorHandler: ((Error) -> Void)? = nil) throws {
        try sanityCheck()
        let message = Message(mode: .sendMessage, userInfo: userInfo, replyHandler: replyHandler, errorHandler: errorHandler)
        messagesQueue.append(message)
        try flush()
    }

    #if os(iOS)
    func transferCurrentComplicationUserInfo(_ userInfo: [String:Any], replyHandler: (([String : Any]) -> Void)? = nil) throws {
        try sanityCheck()
        let message = Message(mode: .transferCurrentComplicationUserInfo, userInfo: userInfo, replyHandler: replyHandler, errorHandler: nil)
        messagesQueue.append(message)
        try flush()
    }
    #endif

    func flush() throws {
        let session = WCSession.default
        print("WKData.flush() started")
        guard session.activationState == .activated else {
            print("WKData.flush() Session not yet active (\(session.activationState)), will now activate and wait for an active session to flush")
            session.activate()
            throw WKDataError.notActive
        }

        #if os(iOS)
        guard session.isWatchAppInstalled else {
            print("WKData.flush() No watch app installed")
            throw WKDataError.noWatchApp
        }
        #endif

        while let message = messagesQueue.popLast() {
            if message.mode == .sendMessage && !session.isReachable {
                if let errorHandler = message.errorHandler {
                    print("WKData.flush() Live messages cannot be delivered as the other part is not reachable")
                    errorHandler(WKDataError.notReachable)
                }
                continue
            }
            try flushMessageImpl(message)
        }
    }

    private func flushMessageImpl(_ message: Message) throws {
        print("Sending message from \(ourName) to \(otherName): \(message)")
        let session = WCSession.default
        switch message.mode {
        case .sendMessage:
            if let replyHandler = message.replyHandler {
                session.sendMessage(message.userInfo, replyHandler: replyHandler, errorHandler: message.errorHandler)
            } else {
                session.sendMessage(message.userInfo, replyHandler: nil, errorHandler: message.errorHandler)
            }
        case .transferUserInfo:
            let userInfo = message.userInfo
            #if targetEnvironment(simulator)
            throw WKDataError.transferUserInfoNotSupportedInSimulator
            #else
            let res = session.transferUserInfo(userInfo)
            print("Result: \(res)")
            if let replyHandler = message.replyHandler {
                replyHandler(["transferCurrentComplicationUserInfo":res, "userInfo":userInfo])
            }
            #endif
        #if os(iOS)
        case .transferCurrentComplicationUserInfo:
            let userInfo = message.userInfo
            try! session.updateApplicationContext(["complicationInfo":userInfo]) // FIXME do we need this?
            #if targetEnvironment(simulator)
            throw WKDataError.transferUserInfoNotSupportedInSimulator
            #else
            let res = session.transferCurrentComplicationUserInfo(userInfo)
            print("Result: \(res)")
            if let replyHandler = message.replyHandler {
                replyHandler(["transferCurrentComplicationUserInfo":res, "userInfo":userInfo])
            }
            #endif
        #endif
        }
    }
    
    func didReceive(userInfo: [String:Any]) {
        for (rawValue, value) in userInfo {
            guard let key = WKDataKeys(rawValue: rawValue) else {
                print("🚨 Unknow key, ignoring: \(rawValue)")
                return
            }
            OpenGluckManager.userDefaults.setValue(value, forKey: key.keyValue)
        }
        OpenGluckManager.userDefaults.synchronize()
    }

    func get(key: WKDataKeys) -> Any? {
        return OpenGluckManager.userDefaults.value(forKey: key.keyValue)
    }

    func set(key: WKDataKeys, value: Any) throws {
        OpenGluckManager.userDefaults.setValue(value, forKey: key.keyValue)
        try sendToOther(key: key, value: value)
    }

    private func sendToOther(key: WKDataKeys, value: Any) throws {
        let userInfo = [key.rawValue: value]
        do {
            print("Transfering key \(key)=\(value)")
            try sendMessage(userInfo, errorHandler: { _ in
                do {
                    try self.transferUserInfo(userInfo)
                } catch {
                    print("Transfering key \(key) got error: \(error)")
                }
            })
        } catch WKDataError.notActive, WKDataError.notReachable, WKDataError.transferUserInfoNotSupportedInSimulator {
            print("Transfering key \(key) failed")
            try transferUserInfo(userInfo)
        }
    }

    func syncToOther(key: WKDataKeys) throws {
        if let value = get(key: key) {
            try sendToOther(key: key, value: value)
        }
    }
}
