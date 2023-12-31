import SwiftUI

enum SheetStatusViewState {
    case inProgress
    case complete
}

class SheetStatusViewOptions: ObservableObject {
    struct Error {
        let id: UUID
        let message: String
    }
    
    @Published var state: SheetStatusViewState?
    @Published var status: String = ""
    @Published var subStatus1: String = ""
    @Published var subStatus2: String = ""
    @Published var errors: [Error] = []
    
    @discardableResult
    func pushError(message: String) -> UUID {
        let id = UUID()
        let error = Error(id: id, message: message)
        errors.append(error)
        return id
    }
    
    func cancelError(id: UUID) {
        errors.removeAll { $0.id == id }
    }
}

struct SheetStatusView: View {
    @EnvironmentObject var options: SheetStatusViewOptions

    @State private var status: String = ""
    @State private var subStatus1: String = ""
    @State private var subStatus2: String = ""

    @State private var isPresented = false
    @State private var scaling = false
    @State private var scalingDone = false
    @State private var page: Int = 1
    @State private var errors: [SheetStatusViewOptions.Error] = []
    
    var body: some View {
        VStack {
        }
        .onReceive(options.$errors, perform: { errors in
            self.errors = errors
        })
        .sheet(isPresented: .init(get: { errors.count > 0 }, set: { newValue in
#if os(watchOS)
            if(!newValue) { errors = [] }
#endif
        })) {
            GeometryReader(content: { geometry in
                ScrollView {
                    ForEach(errors.indices, id: \.self) { i in
                        let error = errors[i]
                        VStack {
                            HStack {
                                Image(systemName: "exclamationmark.bubble.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .padding()
                                Text(error.message)
                                    .foregroundColor(.white)
                                    .padding([.vertical, .trailing])
                                Spacer()
                            }
                            if i < errors.count - 1 {
                                Rectangle()
                                    .frame(width: geometry.size.width, height: 1)
                                #if os(watchOS)
                                    .foregroundColor(Color.black)
                                #else
                                    .foregroundColor(Color(uiColor: .systemBackground))
                                #endif
                            }
                        }
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .background(.red)
            })
            .presentationDetents([.height(200)])
            .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: .init(get: { isPresented && errors.count == 0 }, set: { isPresented = $0 })) {
            VStack {
                Spacer()
                TabView(selection: $page) {
                    VStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .scaleEffect(scaling ? 0.9 : 1)
                            .font(.system(size: 40))
#if !os(watchOS)
                            .foregroundColor(Color(uiColor: .secondaryLabel))
#endif
                            .onAppear {
                                //LATER re-introduce animation, if they work
                                //withAnimation(.spring().repeatForever()) {
                                    scaling.toggle()
                                //}
                            }
                        Text(status)
                        Text(subStatus1)
                            .font(.subheadline)
                        #if !os(watchOS)
                        Text(subStatus2)
                            .font(.subheadline)
                        #endif
                    }
#if os(watchOS)
                    .offset(x: 0, y: -20)
#endif
                    .tag(1)
                    .contentShape(Rectangle()).gesture(DragGesture())
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .scaleEffect(scalingDone ? 1 : 0.5)
                        .foregroundColor(.white)
                        .tag(2)
                        .contentShape(Rectangle()).gesture(DragGesture())
                }
#if os(watchOS)
                .tabViewStyle(.page)
#else
                .tabViewStyle(.page(indexDisplayMode: .never))
#endif
                Spacer()
            }
#if os(watchOS)
            .background(page == 1 ? Color(.black) : .green)
#else
            .background(page == 1 ? Color(.systemBackground) : .green)
#endif
            .presentationDetents([.height(200)])
            .presentationDragIndicator(.hidden)
        }
        .onReceive(options.$status) { newStatus in
            //withAnimation {
                status = newStatus
            //}
            
        }
        .onReceive(options.$subStatus1) { newSubStatus1 in subStatus1 = newSubStatus1 }
        .onReceive(options.$subStatus2) { newSubStatus2 in subStatus2 = newSubStatus2 }
        .onReceive(options.$state) { newState in
            guard let newState else {
                isPresented = false
                return
            }
            switch newState {
            case .inProgress:
                page = 1
                scalingDone = false
                isPresented = true
            case .complete:
                Task {
                    withAnimation {
                        page = 2
                    }
                    let animationInterval: TimeInterval = 0.3
                    try? await Task.sleep(for: .seconds(animationInterval / 3))
                    //withAnimation(.easeIn(duration: animationInterval)) {
                        scalingDone = true
                    //}
                    try? await Task.sleep(for: .seconds(animationInterval))
                    //withAnimation(.spring()) {
                        scalingDone = false
                    //}
                    try? await Task.sleep(for: .seconds(animationInterval / 3))
                    print("isPresented = false")
                    isPresented = false
                }
            }
        }
    }
}

struct SheetStatusView_Previews: PreviewProvider {
    @MainActor
    struct Preview: View {
        @State var options = SheetStatusViewOptions()
        
        func run() {
            options.state = .inProgress
            options.subStatus1 = "Substatus One"
            options.subStatus2 = "Substatus Two"
            Task {
                options.status = "Status A1"
                try? await Task.sleep(for: .seconds(0.5))
                options.status = "Status B2"
                try? await Task.sleep(for: .seconds(1.5))
                options.state = .complete
            }
        }
        
        var body: some View {
            VStack {
                SheetStatusView()
                    .environmentObject(options)
                Button("Run") {
                    run()
                }
            }
        }
    }
    
    struct ErrorPreview: View {
        @State var options = SheetStatusViewOptions()
        
        var body: some View {
            VStack {
                List {
                    Button("Clear All") {
                        options.errors = []
                    }
                    Button("Add Temporary") {
                        Task {
                            let id = options.pushError(message: "This is a temporary error scheduled at: \(Date()))")
                            try? await Task.sleep(for: .seconds(2))
                            options.cancelError(id: id)
                        }
                    }
                }
                SheetStatusView()
                    .environmentObject(options)
            }
            .task {
                options.pushError(message: "This is a test error. You can dismiss it by clicking Clear All in the view below.")
            }
        }
    }
    
    static var previews: some View {
        Preview()
        ErrorPreview()
    }
}
