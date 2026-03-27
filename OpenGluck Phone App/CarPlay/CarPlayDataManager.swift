import Foundation
import OG

@MainActor
class CarPlayDataManager {
    typealias UpdateCallback = (OpenGluckGlucoseRecord?, OpenGluckGlucoseRecord?) -> Void

    private var timer: Timer?
    private let updateCallback: UpdateCallback
    private let refreshInterval: TimeInterval = 60
    private let openGluckConnection: OpenGluckConnection

    init(openGluckConnection: OpenGluckConnection, updateCallback: @escaping UpdateCallback) {
        self.openGluckConnection = openGluckConnection
        self.updateCallback = updateCallback
    }

    func startRefreshing() {
        fetchData()

        timer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.fetchData()
            }
        }
    }

    func stopRefreshing() {
        timer?.invalidate()
        timer = nil
    }

    private func fetchData() {
        Task {
            do {
                if let currentData = try await openGluckConnection.getCurrentData(becauseUpdateOf: "CarPlay refresh") {
                    updateCallback(currentData.currentGlucoseRecord, currentData.lastHistoricGlucoseRecord)
                }
            } catch {
                // Silently handle errors - keep showing last known values
            }
        }
    }
}
