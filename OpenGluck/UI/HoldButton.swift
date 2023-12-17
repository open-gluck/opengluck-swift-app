import SwiftUI

struct HoldButton: View {
    let label: String
    @State var pleaseHold: Bool = false
    @State var task: Task<Void,Error>? = nil
    
    private var labelLabel: String {
        pleaseHold ? "Tap & Hold" : label
    }
    
    private var labelSystemImage: String {
        pleaseHold ? "hand.tap.fill" : "hand.tap"
    }
    
    var body: some View {
        VStack {
            Label(labelLabel, systemImage: labelSystemImage)
                .contentTransition(.numericText())
                .padding()
                .foregroundStyle(Color(uiColor: .lightGray))
                .background(Color(uiColor: .systemFill))
                .clipShape(Capsule())
        }
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
