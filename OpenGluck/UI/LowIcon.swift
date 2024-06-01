import SwiftUI
import OGUI

struct LowIconFill: View {
    let isSnoozed: Bool
    let isActive: Bool

    var body: some View {
        LowIcon(isSnoozed: isSnoozed, isActive: isActive, variant: .graphIcon)
            .shadow(color: Color(uiColor: .white), radius: 0.5)
    }
}

struct LowIcon: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
#if os(watchOS)
    static let systemBackground: Color = Color.black
    static let gray: Color = Color(uiColor: .darkGray)
#else
    static let systemBackground: Color = Color(uiColor: .systemBackground)
    static let gray: Color = Color(uiColor: .systemGray)
#endif
    
    private var gray: Color { variant == .graphIcon ? Color(uiColor: .darkGray) : Self.gray }

    enum Variant {
        case listIcon
        case graphIcon
    }

    let isSnoozed: Bool
    let isActive: Bool
    var variant: Variant = Variant.listIcon
    
    var isIntake: Bool { !isSnoozed }

    var body: some View {
        ZStack {
//            Color.blue
            if isIntake {
                ZStack(alignment: .center) {
                    if isActive {
                        VStack(spacing: 0) {
                            HStack(spacing: 0) {
                                Color.clear
                                Color.white
                                Color.white
                                Color.clear
                            }
                            HStack(spacing: 0) {
                                Color.clear
                                Color.white
                                Color.white
                                Color.clear
                            }
                            HStack(spacing: 0) {
                                Color.clear
                                Color.white
                                Color.white
                                Color.clear
                            }
                            Color.white
                            Color.white
                        }
                        Image(systemName: "teddybear.fill")
                            .resizable()
                            .foregroundStyle(OGUI.lowColor)
                            .scaleEffect(1.2)
                    } else {
                        Image(systemName: isSnoozed ? "teddybear" : "teddybear.fill")
                            .resizable()
                            .clipShape(Circle())
                            .scaleEffect(1.2)
                            .foregroundStyle(gray)
                    }
                }
                .clipShape(Circle())
            } else if variant == .listIcon {
                Image(systemName: isActive ? "flag.fill" : "flag")
                    .resizable()
                    .foregroundStyle(gray)
                    .scaleEffect(0.9)
                    .foregroundStyle(gray)
            } else {
                if isActive {
                    Self.systemBackground
                        .clipShape(Circle())
                        .scaleEffect(0.8)
                    Image(systemName: "flag.circle.fill")
                        .resizable()
                        .foregroundStyle(gray)
                        .scaleEffect(1.25)
                        .clipShape(Circle())
                        .background(
                            Circle()
                                .opacity(colorScheme == .dark ? 1.0 : 0.0)
                                .clipShape(Circle())
                                .scaleEffect(0.9)
                        )
                } else {
                    Image(systemName: "circle")
                        .resizable()
                        .foregroundStyle(gray)
                    Image(systemName: "flag")
                        .resizable()
                        .bold()
                        .scaleEffect(0.54)
                        .foregroundStyle(gray)
                }
            }
        }
            .aspectRatio(1, contentMode: .fit)
    }
}

#Preview("Grid") {
    struct GridPreview: View {
        let spacing: CGFloat = 4
        var body: some View {
            VStack(spacing: spacing) {
                HStack(spacing: spacing) {
                    LowIcon(isSnoozed: false, isActive: true)
                    LowIcon(isSnoozed: false, isActive: false)
                }
                HStack(spacing: spacing) {
                    LowIcon(isSnoozed: true, isActive: true)
                    LowIcon(isSnoozed: true, isActive: false)
                }
                HStack(spacing: spacing) {
                    LowIconFill(isSnoozed: true, isActive: true)
                    LowIconFill(isSnoozed: true, isActive: false)
                }
}
        }
    }
    return GridPreview()
}
