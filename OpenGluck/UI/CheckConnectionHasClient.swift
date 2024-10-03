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
    
    var body: some View {
        ZStack {
            if !hasCompletedSetup {
                setupContent()
            } else if environment.hasTimedOut {
                timeoutContent()
            } else if environment.hasException {
                exceptionContent()
            } else {
                content()
            }
        }
        .onAppear {
            hasCompletedSetup = OpenGluckConnection.client != nil
        }
    }
}

