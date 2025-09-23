import Foundation

extension Date {
    func rollingWindow(days: Int) -> Date? {
        Calendar.current.date(byAdding: .day, value: days, to: self)
    }
}
