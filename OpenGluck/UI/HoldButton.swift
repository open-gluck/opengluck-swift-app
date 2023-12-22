import SwiftUI

struct HoldButton: View {
    let label: String
    let systemImage: String?
    @State var pleaseHold: Bool = false
    @State var task: Task<Void,Error>? = nil
    
    init(label: String, systemImage: String? = nil) {
        self.label = label
        self.systemImage = systemImage
    }
    
    private var labelLabel: String {
        pleaseHold ? "Tap & Hold" : label
    }
    
    private var labelSystemImage: String {
        pleaseHold ? "hand.tap.fill" : (systemImage ?? "hand.tap")
    }
    
    var body: some View {
        HStack {
            Spacer()
            GeometryReader { geom in
                Label(labelLabel, systemImage: labelSystemImage)
                    .frame(width: geom.size.width, height: geom.size.height)
                    .contentTransition(.numericText())
                    .foregroundStyle(Color(uiColor: .lightGray))
                    .background(Color(uiColor: .systemFill))
                    .clipShape(Capsule())
            }
            Spacer()
        }
        .frame(width: .infinity)
        .onTapGesture {
            withAnimation {
                pleaseHold = true
            }
            if let task { task.cancel() }
            task = Task {
                try? await Task.sleep(for: .seconds(2))
                guard !Task.isCancelled else { return }
                withAnimation {
                    pleaseHold = false
                }
            }
        }
    }
}
