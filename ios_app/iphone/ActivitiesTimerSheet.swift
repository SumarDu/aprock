import SwiftUI
import shared

extension NativeSheet {

    func showActivitiesTimerSheet(
        timerContext: ActivityTimerSheetVm.TimerContext?,
        onStart: @escaping () -> Void
    ) {
        self.show { isPresented in
            ActivitiesTimerSheet(
                isPresented: isPresented,
                timerContext: timerContext
            ) {
                isPresented.wrappedValue = false
                onStart()
            }
        }
    }
}

private let bgColor = c.sheetBg
private let listItemHeight = 46.0
private let topContentPadding = 4.0

private let activityItemEmojiWidth = 30.0
private let activityItemEmojiHPadding = 8.0
private let activityItemPaddingStart = activityItemEmojiWidth + (activityItemEmojiHPadding * 2)

private let secondaryFontSize = 16.0
private let secondaryFontWeight: Font.Weight = .light
private let timerHintHPadding = 5.0
private let listEngPadding = 8.0

private let myButtonStyle = MyButtonStyle()

private struct ActivitiesTimerSheet: View {
    
    @EnvironmentObject private var nativeSheet: NativeSheet
    
    @State private var vm: ActivitiesTimerSheetVm
    
    @Binding private var isPresented: Bool
    
    @State private var sheetHeight: Double
    
    @State private var isHistoryPresented = false
    @State private var isEditActivitiesPresented = false
    
    private let timerContext: ActivityTimerSheetVm.TimerContext?
    private let onStart: () -> Void
    
    init(
        isPresented: Binding<Bool>,
        timerContext: ActivityTimerSheetVm.TimerContext?,
        onStart: @escaping () -> Void
    ) {
        _isPresented = isPresented
        self.timerContext = timerContext
        self.onStart = onStart
        
        let vm = ActivitiesTimerSheetVm(timerContext: timerContext)
        _vm = State(initialValue: vm)
        
        let vmState = vm.state.value as! ActivitiesTimerSheetVm.State
        _sheetHeight = State(initialValue: calcSheetHeight(
            activitiesCount: vmState.allActivities.count
        ))
    }
    
    var body: some View {
        
        VMView(vm: vm) { state in
            
            ZStack {
                
                ScrollView {
                    
                    VStack {
                        
                        Padding(vertical: topContentPadding)
                        
                        ForEach(state.allActivities, id: \.activity.id) { activityUI in
                            
                            Button(
                                action: {
                                    // onTapGesture() / onLongPressGesture()
                                },
                                label: {
                                    
                                    ZStack(alignment: .bottomLeading) { // divider + isActive
                                        
                                        HStack {
                                            
                                            Text(activityUI.activity.emoji)
                                                .frame(width: activityItemEmojiWidth)
                                                .padding(.horizontal, activityItemEmojiHPadding)
                                                .font(.system(size: 22))
                                            
                                            Text(activityUI.listText)
                                                .foregroundColor(.primary)
                                                .truncationMode(.tail)
                                                .lineLimit(1)
                                            
                                            Spacer()
                                            
                                            TimerHintsView(
                                                timerHintsUI: activityUI.timerHints,
                                                hintHPadding: timerHintHPadding,
                                                fontSize: secondaryFontSize,
                                                fontWeight: secondaryFontWeight,
                                                onStart: {
                                                    onStart()
                                                }
                                            )
                                        }
                                        .padding(.trailing, listEngPadding)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                                        
                                        if state.allActivities.last != activityUI {
                                            SheetDividerBg()
                                                .padding(.leading, activityItemPaddingStart)
                                        }
                                        
                                        if activityUI.isActive {
                                            ZStack {}
                                                .frame(width: 8, height: listItemHeight - 2)
                                                .background(roundedShape.fill(c.blue))
                                                .offset(x: -4, y: -1)
                                        }
                                    }
                                    /// Ordering is important
                                    .contentShape(Rectangle()) // TRICK for tap gesture
                                    .onTapGesture {
                                        nativeSheet.showActivityTimerSheet(
                                            activity: activityUI.activity,
                                            timerContext: timerContext,
                                            hideOnStart: false,
                                            onStart: {
                                                isPresented = false
                                            }
                                        )
                                    }
                                    .onLongPressGesture(minimumDuration: 0.1) {
                                        nativeSheet.show { isActivityFormPresented in
                                            ActivityFormSheet(
                                                isPresented: isActivityFormPresented,
                                                activity: activityUI.activity
                                            ) {}
                                        }
                                    }
                                    //////
                                    .frame(alignment: .bottom)
                                }
                            )
                        }
                        .buttonStyle(myButtonStyle)
                    }
                }
            }
            .onChange(of: state.allActivities.count) { _, newCount in
                sheetHeight = calcSheetHeight(
                    activitiesCount: newCount
                )
            }
        }
        .frame(maxHeight: sheetHeight)
        .background(bgColor)
        .listStyle(.plain)
        .listSectionSeparatorTint(.clear)
        .presentationDetents([.height(sheetHeight)])
        .presentationDragIndicator(.visible)
    }
}

private func calcSheetHeight(
    activitiesCount: Int
) -> Double {
    // Do not be afraid of too much height because the native sheet will cut
    (listItemHeight * activitiesCount.toDouble()) + topContentPadding
}

private struct MyButtonStyle: ButtonStyle {

    func makeBody(configuration: Self.Configuration) -> some View {
        configuration
            .label
            .frame(height: listItemHeight)
            .background(configuration.isPressed ? c.dividerFg : bgColor)
    }
}
