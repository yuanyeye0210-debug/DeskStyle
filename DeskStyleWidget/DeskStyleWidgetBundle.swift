import SwiftUI
import WidgetKit

@main
struct DeskStyleWidgetBundle: WidgetBundle {
    var body: some Widget {
        ClockWidget()
        CalendarWidget()
        PhotoWidget()
        CountdownWidget()
        QuoteWidget()
    }
}
