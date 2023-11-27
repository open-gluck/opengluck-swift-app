import WidgetKit
import WatchConnectivity
import SwiftUI
import OGUI
import OG

struct AppLauncherWidget: Widget {
    let kind = WidgetKinds.AppLauncherWidget.rawValue

    struct Provider: TimelineProvider {
        func placeholder(in context: Context) -> SimpleEntry {
            return SimpleEntry(date: Date())
        }
        
        private var entry: SimpleEntry {
            SimpleEntry(date: Date())
        }
        
        func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
            completion(entry)
        }
        
        func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
            let timeline = Timeline(entries: [entry], policy: .never)
            completion(timeline)
        }
    }

    struct SimpleEntry: TimelineEntry {
        let date: Date
    }


    struct WidgetView : View {
        var entry: Provider.Entry

        @Environment(\.widgetRenderingMode) var renderingMode
        var body: some View {
            ZStack {
                if renderingMode == .fullColor {
                    Image("MainAppIcon")
                        .resizable()
                        .scaledToFit()
                    Circle().stroke(lineWidth: 4)
                } else {
                    AccessoryWidgetBackground()
                    Rectangle()
                        .opacity(0.3)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    Text("💉")
                        .widgetAccentable()
                }
            }
            .containerBackground(.background, for: .widget)
        }
    }

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WidgetView(entry: entry)
        }
        .configurationDisplayName("Open OpenGlück")
        .description("Open OpenGlück.")
        .supportedFamilies([.accessoryCircular])
    }
}

struct AppLauncherWidget_Previews: PreviewProvider {
    static var previews: some View {
        AppLauncherWidget.WidgetView(entry: AppLauncherWidget.SimpleEntry(date: Date()))
            .previewContext(WidgetPreviewContext(family: .accessoryCircular))
            .previewDisplayName("Circular")
    }
}
