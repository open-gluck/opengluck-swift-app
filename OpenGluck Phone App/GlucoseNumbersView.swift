import SwiftUI
import OG

struct GlucoseNumbersView: View {
    
    struct Item: View {
        @State var mgDl: Int?
        var body: some View {
            let timestamp: Binding<Date?> = .constant(Date())
            let hasCgmRealTimeData: Binding<Bool?> = .constant(true)
            let episode: Binding<Episode?> = .constant(nil)
            let episodeConstant: Binding<Date?> = .constant(nil)
            VStack {
                NumberImageView(timestamp: timestamp, mgDl: $mgDl, hasCgmRealTimeData: hasCgmRealTimeData, episode: episode, episodeTimestamp: episodeConstant)
            }
            .frame(width: 128, height: 128)
            .scaleEffect(0.5)
        }
    }
    
    var body: some View {
        Grid {
            GridRow {
                Item(mgDl: 40)
                Item(mgDl: 64)
                Item(mgDl: 69)
            }
            GridRow {
                Item(mgDl: 70)
                Item(mgDl: 145)
                Item(mgDl: 150)
            }
            GridRow {
                Item(mgDl: 151)
                Item(mgDl: 190)
                Item(mgDl: 240)
            }
            GridRow {
                Item(mgDl: 241)
                Item(mgDl: 260)
                Item(mgDl: 321)
            }
        }
    }
}

struct GlucoseNumbersView_Previews: PreviewProvider {
    static var previews: some View {
        GlucoseNumbersView()
    }
}
