import SwiftUI

struct TvContentView: View {
    @State private var path: [PathItem] = []
    
    enum PathItem {
        case settings
    }
    
    
    var body: some View {
        AppDataAutoFetch {
            OpenGluckEnvironmentUpdater {
                NavigationStack(path: $path) {
                    VStack(alignment: .center) {
                        TimelineView(.everyMinute) { context in
                            CurrentGlucoseView(now: context.date, mode: .graph)
                                .clipped()
                            Spacer()
                            HStack {
                                Button("Settings") {
                                    path.append(PathItem.settings)
                                }
                                Spacer()
                                CurrentGlucoseView(now: context.date, mode: .current)
                            }
                        }
                    }
                    .navigationDestination(for: PathItem.self) { target in
                        switch target {
                        case .settings:
                            TVSettingsView()
                            Button("Close") {
                                path = []
                            }
                        }
                    }
                }
            }
        }
        .environmentObject(OpenGluckConnection())
    }
}

#Preview {
    TvContentView()
}
