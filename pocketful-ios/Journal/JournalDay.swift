import Foundation

/// One day in the journal and everything written on it.
struct JournalDay: Identifiable {
    /// Midnight at the start of the day.
    let date: Date

    /// Newest first.
    let items: [JournalItem]

    var id: Date { date }

    /// "Today", "Yesterday", or like "Monday, Nov 18", with the year added for past years.
    var title: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        let format = Date.FormatStyle.dateTime.weekday(.wide).month(.abbreviated).day()
        if calendar.isDate(date, equalTo: .now, toGranularity: .year) {
            return date.formatted(format)
        }
        return date.formatted(format.year())
    }
}
