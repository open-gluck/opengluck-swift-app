import Foundation
import SwiftUI
import OG
import OGUI

struct NumberImageView: View {
    @Binding var timestamp: Date?
    @Binding var mgDl: Int?
    @Binding var hasCgmRealTimeData: Bool?
    @Binding var episode: Episode?
    @Binding var episodeTimestamp: Date?
    
    static let thresholdNormalLow = Int(OGUI.thresholdNormalLow)
    static let thresholdNormalHigh = Int(OGUI.thresholdNormalHigh)
    static let thresholdLow = Int(OGUI.thresholdNormalLow)
    static let thresholdHighVeryHigh = Int(OGUI.thresholdHighVeryHigh)

    static private func getInfo(forEpisode episode: Episode) -> (Color, Color, String?, String?) {
        return CurrentDataColors.getInfo(forEpisode: episode)
    }
    
    static private func getInfo(forMgDl mgDl: Int, hasCgmRealTimeData: Bool?) -> (Color, Color, String?, String?) {
        return CurrentDataColors.getInfo(forMgDl: mgDl, hasCgmRealTimeData: hasCgmRealTimeData)
    }
    
    static func getImage(timestamp: Date?, forMgDl mgDl: Int?, hasCgmRealTimeData: Bool?, episode: Episode?, episodeTimestamp: Date?) -> UIImage {
        let width = 256.0
        let height = 256.0
        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        let colorText: Color
        let color: Color
        let string: String?
        let systemName: String?
                
        if let timestamp, let episodeTimestamp {
            if timestamp >= episodeTimestamp {
                (color, colorText, string, systemName) = getInfo(forMgDl: mgDl!, hasCgmRealTimeData: hasCgmRealTimeData)
            } else {
                (color, colorText, string, systemName) = getInfo(forEpisode: episode!)
            }
        } else if timestamp != nil {
            if let mgDl {
                (color, colorText, string, systemName) = getInfo(forMgDl: mgDl, hasCgmRealTimeData: hasCgmRealTimeData)
            } else {
                (color, colorText, string, systemName) = getInfo(forEpisode: .disconnected)
            }
        } else if episodeTimestamp != nil {
            (color, colorText, string, systemName) = getInfo(forEpisode: episode!)
        } else {
            (color, colorText, string, systemName) = getInfo(forEpisode: .disconnected)
        }
                
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(color.cgColor!)
        context?.fill(rect)
                
        let attributes: [NSAttributedString.Key : Any] = [
            NSAttributedString.Key.font : UIFont.systemFont(ofSize: 100, weight: .bold),
            NSAttributedString.Key.foregroundColor : UIColor(colorText)
        ]
        if let string {
            let stringSize = string.size(withAttributes: attributes)
            string.draw(
                in: CGRectMake(
                    (width - stringSize.width) / 2,
                    (height - stringSize.height) / 2,
                    stringSize.width,
                    stringSize.height
                ),
                withAttributes: attributes
            )
        }
        if let systemName {
            let paddingRatio = 0.5
            let dx = (width * (1 - paddingRatio)) / 2
            let dy = (height * (1 - paddingRatio)) / 2
            let width = width * paddingRatio
            let height = height * paddingRatio
            let icon = UIImage(systemName: systemName)?.withTintColor(UIColor(colorText))
            let ratio = icon!.size.height / icon!.size.width
            let iconWidth = width
            let iconHeight = width * ratio
            icon?.draw(in: CGRect(x: dx, y: dy + (height - iconHeight) / 2, width: iconWidth, height: iconHeight))
        }

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image ?? UIImage()
    }
    
    var uiImage: UIImage {
        return NumberImageView.getImage(timestamp: timestamp, forMgDl: mgDl, hasCgmRealTimeData: hasCgmRealTimeData, episode: episode, episodeTimestamp: episodeTimestamp)
    }
    
    var body: some View {
        Image(uiImage: uiImage)
            .frame(width: 256, height: 256)
    }
}

struct NumberImageViewPreview: View {
    @Binding var timestamp: Date?
    @Binding var mgDl: Int?
    @Binding var hasCgmRealTimeData: Bool?
    @Binding var episode: Episode?
    @Binding var episodeTimestamp: Date?
    
    var body: some View {
        ZStack {
            NumberImageView(timestamp: $timestamp, mgDl: $mgDl, hasCgmRealTimeData: $hasCgmRealTimeData, episode: $episode, episodeTimestamp: $episodeTimestamp)
            Circle()
                .stroke(lineWidth: 20)
                .foregroundColor(.white)
        }
        .frame(width: 256, height: 256)
        .clipShape(Circle())
        .preferredColorScheme(.dark)
    }
}

struct NumberImageViewEpisode_Previews: PreviewProvider {
    struct Preview: View {
        @State var timestamp: Date? = nil
        @State var episodeTimestamp = ISO8601DateFormatter().date(from: "2023-04-02T14:00:00+02:00")
        var body: some View {
            NumberImageViewPreview(timestamp: $timestamp, mgDl: .constant(nil), hasCgmRealTimeData: .constant(true), episode: .constant(.disconnected), episodeTimestamp: $episodeTimestamp).previewDisplayName("Disconnected")
            NumberImageViewPreview(timestamp: $timestamp, mgDl: .constant(nil), hasCgmRealTimeData: .constant(true), episode: .constant(.unknown), episodeTimestamp: $episodeTimestamp).previewDisplayName("Unknown")
            NumberImageViewPreview(timestamp: $timestamp, mgDl: .constant(nil), hasCgmRealTimeData: .constant(true), episode: .constant(.error), episodeTimestamp: $episodeTimestamp).previewDisplayName("Error")
            NumberImageViewPreview(timestamp: $timestamp, mgDl: .constant(nil), hasCgmRealTimeData: .constant(true), episode: .constant(.high), episodeTimestamp: $episodeTimestamp).previewDisplayName("High")
            NumberImageViewPreview(timestamp: $timestamp, mgDl: .constant(nil), hasCgmRealTimeData: .constant(true), episode: .constant(.normal), episodeTimestamp: $episodeTimestamp).previewDisplayName("Normal")
            NumberImageViewPreview(timestamp: $timestamp, mgDl: .constant(nil), hasCgmRealTimeData: .constant(true), episode: .constant(.low), episodeTimestamp: $episodeTimestamp).previewDisplayName("Low")
        }
    }
    static var previews: some View {
        Preview()
    }
}

struct NumberImageView_Previews: PreviewProvider {
    struct Preview: View {
        @State var timestamp = ISO8601DateFormatter().date(from: "2023-04-02T14:00:00+02:00")
        var body: some View {
            NumberImageViewPreview(timestamp: $timestamp, mgDl: .constant(40), hasCgmRealTimeData: .constant(true), episode: .constant(nil), episodeTimestamp: .constant(nil)).previewDisplayName("40")
            NumberImageViewPreview(timestamp: $timestamp, mgDl: .constant(63), hasCgmRealTimeData: .constant(true), episode: .constant(nil), episodeTimestamp: .constant(nil)).previewDisplayName("63")
            NumberImageViewPreview(timestamp: $timestamp, mgDl: .constant(69), hasCgmRealTimeData: .constant(true), episode: .constant(nil), episodeTimestamp: .constant(nil)).previewDisplayName("69")
            NumberImageViewPreview(timestamp: $timestamp, mgDl: .constant(79), hasCgmRealTimeData: .constant(true), episode: .constant(nil), episodeTimestamp: .constant(nil)).previewDisplayName("79")
            NumberImageViewPreview(timestamp: $timestamp, mgDl: .constant(113), hasCgmRealTimeData: .constant(true), episode: .constant(nil), episodeTimestamp: .constant(nil)).previewDisplayName("113")
            NumberImageViewPreview(timestamp: $timestamp, mgDl: .constant(166), hasCgmRealTimeData: .constant(true), episode: .constant(nil), episodeTimestamp: .constant(nil)).previewDisplayName("166")
            NumberImageViewPreview(timestamp: $timestamp, mgDl: .constant(260), hasCgmRealTimeData: .constant(true), episode: .constant(nil), episodeTimestamp: .constant(nil)).previewDisplayName("260")
            NumberImageViewPreview(timestamp: $timestamp, mgDl: .constant(nil), hasCgmRealTimeData: .constant(true), episode: .constant(nil), episodeTimestamp: .constant(nil)).previewDisplayName("Unknown")
            NumberImageViewPreview(timestamp: $timestamp, mgDl: .constant(120), hasCgmRealTimeData: .constant(false), episode: .constant(nil), episodeTimestamp: .constant(nil)).previewDisplayName("120,no real-time")
        }
    }
    static var previews: some View {
        Preview()
    }
}

