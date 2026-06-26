import Foundation

/// Decides whether the current time falls inside the user's "work hours" window.
/// Pure function over the clock so it's trivially unit-testable.
enum ScheduleManager {
    /// - Parameters:
    ///   - startHour: 0–23, inclusive.
    ///   - endHour: 0–23, exclusive. If endHour <= startHour the range is treated
    ///     as overnight (e.g. 22 → 6).
    ///   - weekdaysOnly: when true, Saturday and Sunday always return false.
    static func isWithin(
        now: Date = Date(),
        startHour: Int,
        endHour: Int,
        weekdaysOnly: Bool,
        calendar: Calendar = .current
    ) -> Bool {
        let comps = calendar.dateComponents([.hour, .weekday], from: now)
        let hour = comps.hour ?? 0
        let weekday = comps.weekday ?? 1  // 1 = Sunday … 7 = Saturday

        if weekdaysOnly && (weekday == 1 || weekday == 7) {
            return false
        }

        if startHour <= endHour {
            return hour >= startHour && hour < endHour
        } else {
            // Overnight window, e.g. 22:00–06:00.
            return hour >= startHour || hour < endHour
        }
    }
}
