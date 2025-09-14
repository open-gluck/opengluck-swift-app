import SwiftUI

struct TvContentView: View {
    @State private var path: [PathItem] = []
    
    enum PathItem {
        case settings
    }
    
    var body: some View {
        AppDataAutoFetch {
            OpenGluckEnvironmentUpdaterView {
                NavigationStack(path: $path) {
                    VStack(alignment: .center) {
                        TimelineView(.everyMinute) { context in
                            CurrentGlucoseView(now: context.date, mode: .graph, graphGeometry: .constant(CGSize(width: 0, height: 0)))
                                .clipped()
                            Spacer()
                            HStack {
                                Button("Settings") {
                                    path.append(PathItem.settings)
                                }
                                Spacer()
                                CurrentGlucoseView(now: context.date, mode: .graphBrick, graphGeometry: .constant(CGSize(width: 0, height: 0)))
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
