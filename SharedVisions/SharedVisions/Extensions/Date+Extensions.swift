import Foundation

extension Date {
    // Relative time string (e.g., "2 hours ago")
    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    // Formatted date string
    var formattedDate: String {
        formatted(date: .abbreviated, time: .omitted)
    }
    
    // Formatted time string
    var formattedTime: String {
        formatted(date: .omitted, time: .shortened)
    }
    
    // Formatted date and time
    var formattedDateTime: String {
        formatted(date: .abbreviated, time: .shortened)
    }
    
    // Check if date is today
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    // Check if date is yesterday
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }
    
    // Smart date string
    var smartDateString: String {
        if isToday {
            return "Today, \(formattedTime)"
        } else if isYesterday {
            return "Yesterday, \(formattedTime)"
        } else {
            return formattedDateTime
        }
    }
}

