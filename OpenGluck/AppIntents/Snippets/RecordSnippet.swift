import SwiftUI

struct RecordSnippet<Content: View>: View {
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack {
            content()
                .padding(.horizontal)
                .padding()
                .frame(maxWidth: .infinity)
        }
    }
}

#Preview("Record Snippet") {
    VStack {
        RecordSnippet {
            HStack {
                Text("Alice")
                Spacer()
                Text("Bob")
            }
                .font(.title3)
        }
    }
    .frame(maxHeight: .infinity)
    .background(.blue)
}
