/*
 This file is based on https://github.com/ApplebaumIan/SwiftUI-Apple-Watch-Decimal-Pad/blob/main/README.md
 It has been modified to better suit OpenGlück needs.
 */

//
//  Modifiers.swift
//  TestDecimilKeyboard WatchKit Extension
//
//  Created by Ian Applebaum on 2/2/21.
//

import Foundation
import SwiftUI

@available(watchOS 6.0, *)
@available(macOS, unavailable)
@available(macCatalyst, unavailable)
@available(iOS, unavailable)
@available(tvOS, unavailable)
public struct DigitButtonModifier: ViewModifier {
    let transparent: Bool
    init(transparent: Bool = false) {
        self.transparent = transparent
    }
    public func body(content: Content) -> some View {
        return content
            .buttonStyle(DigitPadStyle(transparent: transparent))
        
    }
}

@available(watchOS 6.0, *)
@available(macOS, unavailable)
@available(macCatalyst, unavailable)
@available(iOS, unavailable)
@available(tvOS, unavailable)
public extension Button {
    @MainActor func digitKeyFrame() -> some View {
        self.modifier(DigitButtonModifier())
    }
    @MainActor func digitKeyTransparentFrame() -> some View {
        self.modifier(DigitButtonModifier(transparent: true))
    }
}

@available(watchOS 6.0, *)
@available(macOS, unavailable)
@available(macCatalyst, unavailable)
@available(iOS, unavailable)
@available(tvOS, unavailable)
public struct DigitPadStyle: ButtonStyle {
    let transparent: Bool
    init(transparent: Bool) {
        self.transparent = transparent
    }
    public func makeBody(configuration: Configuration) -> some View {
        GeometryReader(content: { geometry in
            if !transparent {
                configuration.isPressed ?
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.gray.opacity(0.7))
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .scaleEffect(1.5)
                :
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.gray.opacity(0.5))
                    .frame(width:  geometry.size.width, height:  geometry.size.height)
                    .scaleEffect(1)
            }
            
            configuration.label
                .background(
                    ZStack {
                        GeometryReader(content: { geometry in
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.clear)
                                .frame(width: configuration.isPressed ? geometry.size.width/0.75 : geometry.size.width, height: configuration.isPressed ? geometry.size.height/0.8 : geometry.size.height)
                            
                        })
                        
                        
                    }
                )
                .frame(width: geometry.size.width, height: geometry.size.height)
                .scaleEffect(configuration.isPressed ? 1.2 : 1)
        })
        .onChange(of: configuration.isPressed) { (_, value) in
            if configuration.isPressed{
                DispatchQueue.main.async {
#if os(watchOS)
                    WKInterfaceDevice().play(.click)
#endif
                    
                }
            }
        }
        
    }
}

public enum TextViewAlignment {
    case trailing
    case leading
    case center
}

public enum KeyboardStyle {
    case decimal
    case numbers
}

#if DEBUG && os(watchOS)
struct EnteredTextKeys_Previews: PreviewProvider {
    static var previews: some View {
        EnteredText( text: .constant(""), presentedAsModal: .constant(true), style: .numbers, confirmLabel: "Add", labelMacro: "%")
        Group {
            EnteredText( text: .constant(""), presentedAsModal: .constant(true), style: .decimal, confirmLabel: "Add", labelMacro: "%")
            EnteredText( text: .constant(""), presentedAsModal: .constant(true), style: .decimal, confirmLabel: "Add", labelMacro: "%")
                .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
        }
        EnteredText( text: .constant(""), presentedAsModal: .constant(true), style: .decimal, confirmLabel: "Add", labelMacro: "%").previewDevice("Apple Watch Series 6 - 40mm")
        EnteredText( text: .constant(""), presentedAsModal: .constant(true), style: .numbers, confirmLabel: "Add", labelMacro: "%").previewDevice("Apple Watch Series 3 - 38mm")
        EnteredText( text: .constant(""), presentedAsModal: .constant(true), style: .decimal, confirmLabel: "Add", labelMacro: "%").previewDevice("Apple Watch Series 3 - 42mm")
    }
}
#endif


//
//  ContentView.swift
//  TestDecimilKeyboard WatchKit Extension
//
//  Created by Ian Applebaum on 2/2/21.
//

import SwiftUI
#if os(watchOS)
@available(watchOS 6.0, *)
@available(macOS, unavailable)
@available(macCatalyst, unavailable)
@available(iOS, unavailable)
@available(tvOS, unavailable)
public struct DigiTextView: View {
    private var locale: Locale
    var style: KeyboardStyle
    var placeholder: String
    let confirmLabel: String
    let labelMacro: String
    @Binding public var text: String
    let onClose: () -> Void
    let onConfirm: () -> Void
    @Binding public var presentingModal: Bool
    
    var align: TextViewAlignment
    public init( placeholder: String, text: Binding<String>, confirmLabel: String, labelMacro: String, presentingModal: Binding<Bool>, alignment: TextViewAlignment = .center,style: KeyboardStyle = .numbers, locale: Locale = .current, onClose: @escaping () -> Void = {}, onConfirm: @escaping () -> Void = {}) {
        _text = text
        _presentingModal = presentingModal
        self.align = alignment
        self.placeholder = placeholder
        self.confirmLabel = confirmLabel
        self.labelMacro = labelMacro
        self.style = style
        self.locale = locale
        self.onClose = onClose
        self.onConfirm = onConfirm
    }
    
    public var body: some View {
        ZStack {
        }.buttonStyle(TextViewStyle(alignment: align))
            .sheet(isPresented: $presentingModal, content: {
                EnteredText(text: $text, presentedAsModal: $presentingModal, style: self.style, confirmLabel: confirmLabel, placeholder: placeholder, labelMacro: labelMacro, locale: locale, onClose: onClose, onConfirm: onConfirm)
            })
    }
}
@available(watchOS 6.0, *)
@available(macOS, unavailable)
@available(macCatalyst, unavailable)
@available(iOS, unavailable)
@available(tvOS, unavailable)
public struct EnteredText: View {
    @Binding var text:String
    @Binding var presentedAsModal: Bool
    var style: KeyboardStyle
    let confirmLabel: String
    let placeholder: String
    let labelMacro: String
    var watchOSDimensions: CGRect?
    private var locale: Locale
    let onClose: () -> Void
    let onConfirm: () -> Void

    public init(text: Binding<String>, presentedAsModal:
                Binding<Bool>, style: KeyboardStyle, confirmLabel: String, placeholder: String = "", labelMacro: String, locale: Locale = .current, onClose: @escaping () -> Void = {}, onConfirm: @escaping () -> Void = {}){
        _text = text
        _presentedAsModal = presentedAsModal
        self.style = style
        self.confirmLabel = confirmLabel
        self.placeholder = placeholder
        self.labelMacro = labelMacro
        self.locale = locale
        let device = WKInterfaceDevice.current()
        watchOSDimensions = device.screenBounds
        self.onClose = onClose
        self.onConfirm = onConfirm
    }
    public var body: some View{
        VStack(alignment: .trailing) {
            Text(text.isEmpty ? placeholder : labelMacro.replacingOccurrences(of: "%", with: text))
                .foregroundColor(text.isEmpty ? Color.gray : nil)
                .font(.title2)
                .frame(height: watchOSDimensions!.height * 0.15, alignment: .trailing)

            DigetPadView(text: $text, style: style, locale: locale)
                .edgesIgnoringSafeArea(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
        }
        .toolbar(content: {
            ToolbarItem(placement: .cancellationAction){
                Button {
                    presentedAsModal = false
                    onClose()
                } label: {
                    Image(systemName: "xmark")
                }
            }
            ToolbarItem(placement: .confirmationAction){
                Button {
                    presentedAsModal = false
                    onConfirm()
                } label: {
                    Text(confirmLabel)
                }
                .padding()
                .foregroundColor(.blue)
                .buttonStyle(PlainButtonStyle())
                .background(Color.secondary)
                .clipShape(Capsule())
            }
        })
    }
}
@available(watchOS 6.0, *)
@available(macOS, unavailable)
@available(macCatalyst, unavailable)
@available(iOS, unavailable)
@available(tvOS, unavailable)
public struct DigetPadView: View {
    public var widthSpace: CGFloat = 1.0
    @Binding var text:String
    var style: KeyboardStyle
    private var decimalSeparator: String
    public init(text: Binding<String>, style: KeyboardStyle, locale: Locale = .current) {
        _text = text
        self.style = style
        
        let numberFormatter = NumberFormatter()
        numberFormatter.locale = locale
        decimalSeparator = numberFormatter.decimalSeparator
    }
    public var body: some View {
        VStack(spacing: 1) {
            HStack(spacing: widthSpace){
                Button(action: {
                    text.append("1")
                }) {
                    Text("1")
                        .padding(0)
                }
                .digitKeyFrame()
                Button(action: {
                    text.append("2")
                }) {
                    Text("2")
                }.digitKeyFrame()
                
                Button(action: {
                    text.append("3")
                }) {
                    Text("3")
                }.digitKeyFrame()
            }
            HStack(spacing:widthSpace){
                Button(action: {
                    text.append("4")
                }) {
                    Text("4")
                }.digitKeyFrame()
                Button(action: {
                    text.append("5")
                }) {
                    Text("5")
                }.digitKeyFrame()
                
                Button(action: {
                    text.append("6")
                }) {
                    Text("6")
                }.digitKeyFrame()
            }
            
            HStack(spacing:widthSpace){
                Button(action: {
                    text.append("7")
                }) {
                    Text("7")
                }.digitKeyFrame()
                Button(action: {
                    text.append("8")
                }) {
                    Text("8")
                }.digitKeyFrame()
                
                Button(action: {
                    text.append("9")
                }) {
                    Text("9")
                }
                .digitKeyFrame()
            }
            HStack(spacing:widthSpace) {
                if style == .decimal {
                    Button(action: {
                        if !(text.contains(decimalSeparator)){
                            if text == ""{
                                text.append("0\(decimalSeparator)")
                            }else{
                                text.append(decimalSeparator)
                            }
                        }
                    }) {
                        Text(decimalSeparator)
                    }
                    .digitKeyTransparentFrame()
                } else {
                    Spacer()
                        .padding(1)
                }
                Button(action: {
                    text.append("0")
                }) {
                    Text("0")
                }
                .digitKeyFrame()
                
                Button(action: {
                    if let last = text.indices.last{
                        text.remove(at: last)
                    }
                }) {
                    Image(systemName: "delete.left.fill")
                        .foregroundColor(.red)
                }
                .digitKeyTransparentFrame()
            }
        }
        .font(.title2)
        .padding(.bottom)
    }
}

@available(iOS 13.0, watchOS 6.0, *)
struct TextViewStyle: ButtonStyle {
    init(alignment: TextViewAlignment = .center) {
        self.align = alignment
    }
    
    
    var align: TextViewAlignment
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            if align == .center || align == .trailing{
                Spacer()
            }
            configuration.label
                .font(/*@START_MENU_TOKEN@*/.body/*@END_MENU_TOKEN@*/)
                .padding(.vertical, 11.0)
                .padding(.horizontal)
            if align == .center || align == .leading{
                Spacer()
            }
        }
        .background(
            GeometryReader { geometry in
                ZStack{
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(configuration.isPressed ? Color.gray.opacity(0.1): Color.gray.opacity(0.2))
                }
            })
        
    }
    
}
#endif

#if DEBUG && os(watchOS)
struct EnteredText_Previews: PreviewProvider {
    static var previews: some View {
        EnteredText( text: .constant(""), presentedAsModal: .constant(true), style: .numbers, confirmLabel: "Add", labelMacro: "%")
        Group {
            EnteredText( text: .constant(""), presentedAsModal: .constant(true), style: .decimal, confirmLabel: "Add", labelMacro: "%")
            EnteredText( text: .constant(""), presentedAsModal: .constant(true), style: .decimal, confirmLabel: "Add", labelMacro: "%")
                .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
            EnteredText( text: .constant(""), presentedAsModal: .constant(true), style: .decimal, confirmLabel: "Add", labelMacro: "%")
                .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
                .accessibilityElement(children: /*@START_MENU_TOKEN@*/.contain/*@END_MENU_TOKEN@*/)
            
        }
        EnteredText( text: .constant(""), presentedAsModal: .constant(true), style: .decimal, confirmLabel: "Add", labelMacro: "%").previewDevice("Apple Watch Series 6 - 40mm")
        Group {
            EnteredText( text: .constant(""), presentedAsModal: .constant(true), style: .numbers, confirmLabel: "Add", labelMacro: "%").previewDevice("Apple Watch Series 3 - 38mm")
            EnteredText( text: .constant(""), presentedAsModal: .constant(true), style: .numbers, confirmLabel: "Add", labelMacro: "%").environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge).previewDevice("Apple Watch Series 3 - 38mm")
        }
        EnteredText( text: .constant(""), presentedAsModal: .constant(true), style: .decimal, confirmLabel: "Add", labelMacro: "%").previewDevice("Apple Watch Series 3 - 42mm")
    }
}

struct Content_View_Previews: PreviewProvider {
    static var previews: some View{
        ScrollView {
            ForEach(0 ..< 4) { item in
                DigiTextView(placeholder: "Placeholder", text: .constant(""), confirmLabel: "Add", labelMacro: "%", presentingModal: .constant(false), alignment: .leading)
            }
            Button(action: /*@START_MENU_TOKEN@*//*@PLACEHOLDER=Action@*/{}/*@END_MENU_TOKEN@*/) {
                /*@START_MENU_TOKEN@*//*@PLACEHOLDER=Content@*/Text("Button")/*@END_MENU_TOKEN@*/
            }
        }
    }
}

struct TextField_Previews: PreviewProvider {
    static var previews: some View{
        ScrollView{
            ForEach(0 ..< 4){ item in
                TextField(/*@START_MENU_TOKEN@*/"Placeholder"/*@END_MENU_TOKEN@*/, text: /*@START_MENU_TOKEN@*//*@PLACEHOLDER=Value@*/.constant("")/*@END_MENU_TOKEN@*/)
            }
            Button(action: /*@START_MENU_TOKEN@*//*@PLACEHOLDER=Action@*/{}/*@END_MENU_TOKEN@*/) {
                /*@START_MENU_TOKEN@*//*@PLACEHOLDER=Content@*/Text("Button")/*@END_MENU_TOKEN@*/
            }
        }
    }
}
#endif
