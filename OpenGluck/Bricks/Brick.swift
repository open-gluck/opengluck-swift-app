import SwiftUI

struct BrickUI {
    static let cornerRadius = 10.0
    static let smallHeight: Double = 150.0
}

struct Brick<Content: View>: View {
    let title: String
    let systemImage: String?
    @ViewBuilder let content: () -> Content
    
#if os(watchOS) || os(tvOS)
    let secondarySystemGroupedBackground: Color = Color(red: 28/256, green: 28/256, blue: 30/256)
#else
    let secondarySystemGroupedBackground: Color = Color(uiColor: .secondarySystemGroupedBackground)
#endif
    
    init(title: String, systemImage: String? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.systemImage = systemImage
        self.content = content
    }
    
    var body: some View {
#if os(watchOS)
        VStack {
            content()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
#else
        VStack {
            HStack {
                if let systemImage {
                    Label(title, systemImage: systemImage)
                        .font(.headline)
                        .padding()
                } else {
                    Text(title)
                        .font(.headline)
                        .padding()
                }
            }
            .foregroundStyle(Color(uiColor: .lightGray))
            Spacer()
            content()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(secondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: BrickUI.cornerRadius))
#endif
    }
}

#Preview("Brick") {
    Grid {
        GridRow {
            Brick(title: "Alice") {
                Text("Foo")
            }
        }
    }
    .preferredColorScheme(.dark)
}

