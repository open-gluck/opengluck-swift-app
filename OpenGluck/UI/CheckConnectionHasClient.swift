import SwiftUI

struct CheckConnectionHasClientDefaultSetupContent: View {
    static let systemImage = "exclamationmark.magnifyingglass"
    var body: some View {
        ContentUnavailableView("Unknown Server URL/Token", systemImage: Self.systemImage, description: Text("Please configure a connection in the More tab."))
    }
}

struct CheckConnectionHasClientDefaultTimeoutContent: View {
    static let systemImage = "network.slash"
    var body: some View {
#if os(watchOS)
        ContentUnavailableView("Still Loading…", systemImage: Self.systemImage, description: Text("\nLoading data from OpenGlück server takes a while…"))
#else
        ContentUnavailableView("Still Loading…", systemImage: Self.systemImage, description: Text("\nLoading data from OpenGlück server takes a while…\n\nCheck your network and configuration."))
#endif
    }
}

struct CheckConnectionHasClientDefaultExceptionContent: View {
    static let systemImage = "network.slash"
    var body: some View {
        ContentUnavailableView("Could Not Connect To Server", systemImage: Self.systemImage, description: Text("\nConnection to server failed.\n\nCheck your network and configuration."))
    }
}

@MainActor
struct CheckConnectionHasClient<C: View, SetupC: View, TimeoutC: View, ExceptionC: View>: View {
    @ViewBuilder let content: () -> C
    @ViewBuilder let setupContent: () -> SetupC
    @ViewBuilder let timeoutContent: () -> TimeoutC
    @ViewBuilder let exceptionContent: () -> ExceptionC
    
    @State var hasCompletedSetup: Bool = false
    @EnvironmentObject var environment: OpenGluckEnvironment
    
    private enum CurrentContent {
        case setup
        case timeout
        case exception
        case normal
    }
    @State private var currentContent: CurrentContent? = nil
    
    init(
        content: @escaping () -> C,
        setupContent: @escaping @MainActor () -> SetupC = { CheckConnectionHasClientDefaultSetupContent() },
        timeoutContent: @escaping @MainActor () -> TimeoutC = { CheckConnectionHasClientDefaultTimeoutContent() },
        exceptionContent: @escaping @MainActor () -> ExceptionC = { CheckConnectionHasClientDefaultExceptionContent() }
    ) {
        self.content = content
        self.setupContent = setupContent
        self.timeoutContent = timeoutContent
        self.exceptionContent = exceptionContent
    }
    
    private func updateCurrentContent() {
        let newHasCompletedSetup = OpenGluckConnection.client != nil
        if newHasCompletedSetup != hasCompletedSetup {
            hasCompletedSetup = newHasCompletedSetup
        }

        currentContent = computeCurrentContent()
    }
    
    private func computeCurrentContent() -> CurrentContent {
        return if !hasCompletedSetup {
            .setup
        } else if environment.hasTimedOut {
            .timeout
        } else if environment.hasException {
            .exception
        } else {
            .normal
        }
    }
    
    var body: some View {
        ZStack {
            switch currentContent ?? computeCurrentContent() {
            case .setup:
                setupContent()
            case .timeout:
                timeoutContent()
            case .exception:
                exceptionContent()
            case .normal:
                content()
            }
        }
        .task {
            updateCurrentContent()
        }
        .task(id: OpenGluckConnection.client != nil) {
            updateCurrentContent()
        }
        .onReceive(environment.$hasTimedOut) { _ in
            updateCurrentContent()
        }
        .onReceive(environment.$lastAttemptAt) { _ in
            updateCurrentContent()
        }
        .onReceive(environment.$lastSuccessAt) { _ in
            updateCurrentContent()
        }
    }
}

