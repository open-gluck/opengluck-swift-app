import Foundation
import SwiftUI
import OG
import OGUI

struct CurrentDataGauge: View {
    @Environment(\.widgetRenderingMode) var widgetRenderingMode

    @Binding var timestamp: Date?
    @Binding var mgDl: Int?
    @Binding var instantMgDl: Int?
    @Binding var hasCgmRealTimeData: Bool?
    @Binding var episode: Episode?
    @Binding var episodeTimestamp: Date?
    @Binding var freshnessLevel: Double?

    @State var freshnessColorOpacity: CGFloat = 0.4
    
    @State private var isAnimatingOut: Bool = false
    @State private var instantMgDlAngle: Angle = .zero
    @State private var instantColorBackground: Color? = nil
    @State private var instantColorText: Color? = nil
    @State private var instantText: String? = nil
    @State private var animatedInstantMgDl: Int? = nil

    var body: some View {
        let (color, colorText, string, systemName): (Color, Color, String?, String?) = {
            if let timestamp, let episodeTimestamp {
                if timestamp >= episodeTimestamp {
                    return CurrentDataColors.getInfo(forMgDl: mgDl!, hasCgmRealTimeData: hasCgmRealTimeData)
                } else {
                    return CurrentDataColors.getInfo(forEpisode: episode!)
                }
            } else if timestamp != nil {
                if let mgDl {
                    return CurrentDataColors.getInfo(forMgDl: mgDl, hasCgmRealTimeData: hasCgmRealTimeData)
                } else {
                    return CurrentDataColors.getInfo(forEpisode: .disconnected)
                }
            } else if episodeTimestamp != nil {
                return CurrentDataColors.getInfo(forEpisode: episode!)
            } else {
                return CurrentDataColors.getInfo(forEpisode: .disconnected)
            }
        }()
        let backgroundColor = widgetRenderingMode == .fullColor ? color : .white.opacity(0)
        let tintColor: Color = {
            guard freshnessLevel != nil else {
                return.white.opacity(0)
            }
            var r: CGFloat = 0
            var g: CGFloat = 0
            var b: CGFloat = 0
            var a: CGFloat = 0
            guard UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a) else {
                return .white
            }
            func f(_ x: CGFloat) -> CGFloat {
                return 1 - ((1 - x) * freshnessColorOpacity)
            }
            return Color(red: f(r), green: f(g), blue: f(b))
        }()
        ZStack {
            Gauge(value: freshnessLevel ?? 0, in: 0...1) {
                if let systemName {
                    Image(systemName: systemName)
                        .resizable()
                        .scaledToFit()
                        .tint(colorText)
                }
                if let string {
                    if string == "?" {
                        // when text is ? display instead a grayish version of our icon,
                        // that better conveys we don't have up-to-date data
                        Image("SmallUnknownAppIcon")
                            .resizable()
                            .scaledToFit()
                            .clipShape(Circle())
                            .scaleEffect(2)
                    } else {
                        Text(string)
                            .foregroundStyle(colorText)
                    }
                }
            }
            .gaugeStyle(.accessoryCircularCapacity)
            //.tint(.white.opacity(freshnessLevel == nil ? 0 : 0.6))
            .tint(tintColor)
            .background(backgroundColor)
            .clipShape(Circle())
            VStack {
                ZStack {
                    ZStack {
                        if let instantText {
                            Text(animatedInstantMgDl != mgDl ? instantText : "→")
                                .contentTransition(.numericText(value: Double(animatedInstantMgDl ?? 0)))
                                .rotationEffect(-instantMgDlAngle)
                                                    .font(.system(size: 15))
                                                    .foregroundStyle(instantColorText ?? Color.white)
                                                    .padding(5)
                                                    .background {
                                                        instantColorBackground
                                                            .clipShape(Capsule())
                                                            .rotationEffect(-instantMgDlAngle)
                                                    }
                                                    .shadow(radius: 6)
                                                    .padding(.leading, 28)

                                                    .transition(.scale)
                        }
                    }
                    .frame(minWidth: 92, alignment: .leading)
//                    .border(.purple)
                }
                #if !os(watchOS)
                .offset(x: 42, y: 0)
                #else
                .offset(x: 37, y: 0)
                #endif
                .frame(width: 64, height: 64)
//                .border(.red)
                .rotationEffect(instantMgDlAngle)
            }
        }
        .task(id: instantMgDl) {
            let animation: Animation = .default.speed(4)
            if let instantMgDl {
                let (instantColorBackground, instantColorText, instantText, _) = CurrentDataColors.getInfo(forMgDl: instantMgDl, hasCgmRealTimeData: true)
                if instantText != nil && self.instantText == nil, !isAnimatingOut {
                    instantMgDlAngle = getInstantMgDlAngle()
                }
                withAnimation(animation) {
                    self.instantColorBackground = instantColorBackground
                    self.instantColorText = instantColorText
                    self.instantText = instantText
                    self.animatedInstantMgDl = instantMgDl

                    instantMgDlAngle = getInstantMgDlAngle()
                }
            } else {
                self.isAnimatingOut = true
                withAnimation(animation) {
                    self.instantColorBackground = nil
                    self.instantColorText = nil
                    self.instantText = nil
                } completion: {
                    self.animatedInstantMgDl = nil
                    self.isAnimatingOut = false
                }
            }
        }
    }
    
    private func getInstantMgDlAngle() -> Angle {
        #if os(watchOS)
        // we use a smaller angle on watchOS, to make things tidier
        let positiveAngle: Angle = .degrees(24)
        #else
        let positiveAngle: Angle = .degrees(30)
        #endif
        return if let mgDl, let instantMgDl, instantMgDl > mgDl {
            -positiveAngle
        } else if let mgDl, let instantMgDl, instantMgDl < mgDl {
            positiveAngle
        } else {
            .zero
        }
    }
}

fileprivate struct CurrentDataGaugePreview: View {
    @Binding var timestamp: Date?
    @Binding var mgDl: Int?
    @Binding var instantMgDl: Int?
    @Binding var hasCgmRealTimeData: Bool?
    @Binding var episode: Episode?
    @Binding var episodeTimestamp: Date?
    @State var freshnessLevel: Double? = nil
    
    @State var width: Double = 128
    @State var height: Double = 128
    
    var body: some View {
        CurrentDataGauge(timestamp: $timestamp, mgDl: $mgDl, instantMgDl: $instantMgDl, hasCgmRealTimeData: $hasCgmRealTimeData, episode: $episode, episodeTimestamp: $episodeTimestamp, freshnessLevel: .constant(freshnessLevel))
        .frame(width: width, height: height)
    }
}

#Preview("Random") {
    struct Preview: View {
        let timer = Timer.publish(every: 0.3, on: .main, in: .common).autoconnect()
        @State var mgDl: Int? = 100
        @State var instantMgDl: Int? = 105
        
        var body: some View {
            VStack {
                Text(BloodGlucose.localize(mgDl!, style: .short))
                CurrentDataGaugePreview(timestamp: .constant(Date()), mgDl: $mgDl, instantMgDl: $instantMgDl, hasCgmRealTimeData: .constant(true), episode: .constant(nil), episodeTimestamp: .constant(nil))
            }
                .onReceive(timer) { _ in
                    mgDl = .random(in: 50...250)
                    instantMgDl = .random(in: 50...250)
                }
                .previewDisplayName("Random")
        }
    }

    return Preview()
}

#Preview("Instant") {
    struct Preview: View {
        let timer = Timer.publish(every: 0.3, on: .main, in: .common).autoconnect()
        @State var mgDl: Int? = 128
        @State var instantMgDl: Int? = nil
        
        enum PreviewInstant: Int, Hashable {
            case none
            case lower
            case equal
            case greater
        }
        @State var instant: PreviewInstant  = .greater
        
        var body: some View {
            VStack {
                Text(BloodGlucose.localize(mgDl!, style: .short))
#if !os(watchOS)
                Picker("Instant", selection: $instant) {
                    Text("nil").tag(PreviewInstant.none)
                    Text("lower").tag(PreviewInstant.lower)
                    Text("equal").tag(PreviewInstant.equal)
                    Text("greater").tag(PreviewInstant.greater)
                }
                .pickerStyle(.palette)
#else
                HStack {
                    Button("nil") { instant = PreviewInstant.none }
                    Button("<") { instant = PreviewInstant.lower }
                    Button("=") { instant = PreviewInstant.equal }
                    Button(">") { instant = PreviewInstant.greater }
                }
#endif
                CurrentDataGaugePreview(timestamp: .constant(Date()), mgDl: $mgDl, instantMgDl: $instantMgDl, hasCgmRealTimeData: .constant(true), episode: .constant(nil), episodeTimestamp: .constant(nil))
            }
                .previewDisplayName("Random")
                .task(id: instant) {
                    instantMgDl = switch (instant) {
                    case .none: nil
                    case .lower: 119
                    case .equal: 128
                    case .greater: 133
                    }
                }
        }
    }

    return Preview()
}


/*
struct CurrentDataGaugeFreshnessPreview: View {
    @Binding var timestamp: Date?
    @Binding var mgDl: Int?
    @Binding var instantMgDl: Int?
    @Binding var hasCgmRealTimeData: Bool?
    @Binding var episode: Episode?
    @Binding var episodeTimestamp: Date?
    @Binding var freshnessLevel: Double?
    
    @State var width: Double = 60
    @State var height: Double = 60
    
    var body: some View {
        CurrentDataGauge(timestamp: $timestamp, mgDl: $mgDl, instantMgDl: $instantMgDl, hasCgmRealTimeData: $hasCgmRealTimeData, episode: $episode, episodeTimestamp: $episodeTimestamp, freshnessLevel: $freshnessLevel)
        .frame(width: width, height: height)
    }
}

struct CurrentDataGaugeFreshness_Previews: PreviewProvider {
    struct Preview: View {
        let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
        @State var freshnessLevel: Double? = 1
        
        var body: some View {
            VStack {
                Text("\(freshnessLevel!)")
                CurrentDataGaugeFreshnessPreview(timestamp: .constant(Date()), mgDl: .constant(139), instantMgDl: .constant(140), hasCgmRealTimeData: .constant(true), episode: .constant(nil), episodeTimestamp: .constant(nil), freshnessLevel: .constant(freshnessLevel))
            }
                .onReceive(timer) { _ in
                    freshnessLevel = freshnessLevel! - 0.1
                    if freshnessLevel! < 0 {
                        freshnessLevel = 1.0
                    }
                }
                .previewDisplayName("Freshness")
        }
    }
    
    static var previews: some View {
        Preview()
    }
}


struct CurrentDataGaugeEpisode_Previews: PreviewProvider {
    struct Preview: View {
        @State var timestamp: Date? = nil
        @State var episodeTimestamp = ISO8601DateFormatter().date(from: "2023-04-02T14:00:00+02:00")
        var body: some View {
            CurrentDataGaugePreview(timestamp: $timestamp, mgDl: .constant(nil), instantMgDl: .constant(nil), hasCgmRealTimeData: .constant(true), episode: .constant(.disconnected), episodeTimestamp: $episodeTimestamp).previewDisplayName("Disconnected")
            CurrentDataGaugePreview(timestamp: $timestamp, mgDl: .constant(nil), instantMgDl: .constant(nil), hasCgmRealTimeData: .constant(true), episode: .constant(.unknown), episodeTimestamp: $episodeTimestamp).previewDisplayName("Unknown")
            CurrentDataGaugePreview(timestamp: $timestamp, mgDl: .constant(nil), instantMgDl: .constant(nil), hasCgmRealTimeData: .constant(true), episode: .constant(.error), episodeTimestamp: $episodeTimestamp).previewDisplayName("Error")
            CurrentDataGaugePreview(timestamp: $timestamp, mgDl: .constant(nil), instantMgDl: .constant(nil), hasCgmRealTimeData: .constant(true), episode: .constant(.high), episodeTimestamp: $episodeTimestamp).previewDisplayName("High")
            CurrentDataGaugePreview(timestamp: $timestamp, mgDl: .constant(nil), instantMgDl: .constant(nil), hasCgmRealTimeData: .constant(true), episode: .constant(.normal), episodeTimestamp: $episodeTimestamp).previewDisplayName("Normal")
            CurrentDataGaugePreview(timestamp: $timestamp, mgDl: .constant(nil), instantMgDl: .constant(nil), hasCgmRealTimeData: .constant(true), episode: .constant(.low), episodeTimestamp: $episodeTimestamp).previewDisplayName("Low")
        }
    }
    static var previews: some View {
        Preview()
    }
}


struct CurrentDataGauge_Previews: PreviewProvider {
    struct Preview: View {
        @State var timestamp = ISO8601DateFormatter().date(from: "2023-04-02T14:00:00+02:00")
        
        var body: some View {
            CurrentDataGaugePreview(timestamp: $timestamp, mgDl: .constant(40), instantMgDl: .constant(nil), hasCgmRealTimeData: .constant(true), episode: .constant(nil), episodeTimestamp: .constant(nil)).previewDisplayName("40")
            CurrentDataGaugePreview(timestamp: $timestamp, mgDl: .constant(63), instantMgDl: .constant(nil), hasCgmRealTimeData: .constant(true), episode: .constant(nil), episodeTimestamp: .constant(nil)).previewDisplayName("63")
            CurrentDataGaugePreview(timestamp: $timestamp, mgDl: .constant(69), instantMgDl: .constant(nil), hasCgmRealTimeData: .constant(true), episode: .constant(nil), episodeTimestamp: .constant(nil)).previewDisplayName("69")
            CurrentDataGaugePreview(timestamp: $timestamp, mgDl: .constant(79), instantMgDl: .constant(nil), hasCgmRealTimeData: .constant(true), episode: .constant(nil), episodeTimestamp: .constant(nil)).previewDisplayName("79")
            CurrentDataGaugePreview(timestamp: $timestamp, mgDl: .constant(113), instantMgDl: .constant(nil), hasCgmRealTimeData: .constant(true), episode: .constant(nil), episodeTimestamp: .constant(nil)).previewDisplayName("113")
            CurrentDataGaugePreview(timestamp: $timestamp, mgDl: .constant(166), instantMgDl: .constant(nil), hasCgmRealTimeData: .constant(true), episode: .constant(nil), episodeTimestamp: .constant(nil)).previewDisplayName("166")
            CurrentDataGaugePreview(timestamp: $timestamp, mgDl: .constant(260), instantMgDl: .constant(nil), hasCgmRealTimeData: .constant(true), episode: .constant(nil), episodeTimestamp: .constant(nil)).previewDisplayName("260")
            CurrentDataGaugePreview(timestamp: $timestamp, mgDl: .constant(nil), instantMgDl: .constant(nil), hasCgmRealTimeData: .constant(true), episode: .constant(nil), episodeTimestamp: .constant(nil)).previewDisplayName("Unknown")
            CurrentDataGaugePreview(timestamp: $timestamp, mgDl: .constant(120), instantMgDl: .constant(nil), hasCgmRealTimeData: .constant(false), episode: .constant(nil), episodeTimestamp: .constant(nil)).previewDisplayName("120,no real-time")
        }
    }
    
    static var previews: some View {
        Preview()
    }
}
*/
