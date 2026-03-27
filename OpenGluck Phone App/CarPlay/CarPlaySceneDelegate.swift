import UIKit
import CarPlay
import OG

@MainActor
final class CarPlaySceneDelegate: NSObject, @MainActor CPTemplateApplicationSceneDelegate {
    private var interfaceController: CPInterfaceController?
    private var timer: Timer?
    private var currentGlucose: OpenGluckGlucoseRecord?
    private var historicGlucose: OpenGluckGlucoseRecord?

    private let connection = OpenGluckConnection()
    
    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        self.interfaceController = interfaceController

        let template = createTemplate()
        interfaceController.setRootTemplate(template, animated: false, completion: nil)

        fetchData()
        startTimer()
    }
    
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didDisconnectInterfaceController interfaceController: CPInterfaceController) {
        stopTimer()
        self.interfaceController = nil

    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.fetchData()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func fetchData() {
        Task { @MainActor in
            do {
                if let currentData = try await connection.getCurrentData(becauseUpdateOf: "CarPlay", force: false) {
                    self.currentGlucose = currentData.currentGlucoseRecord
                    self.historicGlucose = currentData.lastHistoricGlucoseRecord
                } else {
                    self.currentGlucose = nil
                    self.historicGlucose = nil
                }
                self.updateTemplate()
            } catch {
                // Silently handle errors
            }
        }
    }

    private func createTemplate() -> CPInformationTemplate {
        var items: [CPInformationItem] = []

        let currentValue: String
        let currentDetail: String
        if let current = currentGlucose {
            currentValue = BloodGlucose.localize(current.mgDl, style: .short)
            currentDetail = OpenGluckManager.secondsToTextAgo(current.timestamp.timeIntervalSinceNow)
        } else {
            currentValue = "--"
            currentDetail = "Loading..."
        }
        items.append(CPInformationItem(title: "Current", detail: "\(currentValue) (\(currentDetail))"))

        let historicValue: String
        let historicDetail: String
        if let historic = historicGlucose {
            historicValue = BloodGlucose.localize(historic.mgDl, style: .short)
            historicDetail = OpenGluckManager.secondsToTextAgo(historic.timestamp.timeIntervalSinceNow)
        } else {
            historicValue = "--"
            historicDetail = "No data"
        }
        items.append(CPInformationItem(title: "Last Historic", detail: "\(historicValue) (\(historicDetail))"))

        return CPInformationTemplate(
            title: "OpenGluck",
            layout: .leading,
            items: items,
            actions: []
        )
    }

    private func updateTemplate() {
        let template = createTemplate()
        interfaceController?.setRootTemplate(template, animated: true, completion: nil)
    }
}
