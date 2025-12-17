//
//  OpeningHours.swift
//  TCG Arena
//
//  Created by TCG Arena Team
//

import Foundation

/// Represents the opening schedule for a single day
struct DaySchedule: Codable, Equatable {
    var open: String?   // Format: "HH:mm" e.g., "09:00"
    var close: String?  // Format: "HH:mm" e.g., "18:00"
    var closed: Bool    // true if the shop is closed that day
    
    init(open: String? = nil, close: String? = nil, closed: Bool = false) {
        self.open = closed ? nil : open
        self.close = closed ? nil : close
        self.closed = closed
    }
    
    /// Returns a user-friendly string representation of the schedule
    var displayString: String {
        if closed {
            return "Chiuso"
        }
        if let open = open, let close = close {
            return "\(open) - \(close)"
        }
        return "Non specificato"
    }
    
    /// Check if the shop is open at a specific time
    func isOpenAt(time: String) -> Bool {
        guard !closed, let open = open, let close = close else { return false }
        return time >= open && time <= close
    }
}

/// Represents the weekly opening hours for a shop
struct OpeningHours: Codable, Equatable {
    var monday: DaySchedule
    var tuesday: DaySchedule
    var wednesday: DaySchedule
    var thursday: DaySchedule
    var friday: DaySchedule
    var saturday: DaySchedule
    var sunday: DaySchedule
    
    init(
        monday: DaySchedule = DaySchedule(closed: true),
        tuesday: DaySchedule = DaySchedule(closed: true),
        wednesday: DaySchedule = DaySchedule(closed: true),
        thursday: DaySchedule = DaySchedule(closed: true),
        friday: DaySchedule = DaySchedule(closed: true),
        saturday: DaySchedule = DaySchedule(closed: true),
        sunday: DaySchedule = DaySchedule(closed: true)
    ) {
        self.monday = monday
        self.tuesday = tuesday
        self.wednesday = wednesday
        self.thursday = thursday
        self.friday = friday
        self.saturday = saturday
        self.sunday = sunday
    }
    
    /// Create default weekday schedule (Mon-Fri: 9-18, Sat: 10-16, Sun: Closed)
    static func defaultWeekdaySchedule() -> OpeningHours {
        return OpeningHours(
            monday: DaySchedule(open: "09:00", close: "18:00"),
            tuesday: DaySchedule(open: "09:00", close: "18:00"),
            wednesday: DaySchedule(open: "09:00", close: "18:00"),
            thursday: DaySchedule(open: "09:00", close: "18:00"),
            friday: DaySchedule(open: "09:00", close: "18:00"),
            saturday: DaySchedule(open: "10:00", close: "16:00"),
            sunday: DaySchedule(closed: true)
        )
    }
    
    /// Get the schedule for a specific day of the week
    func schedule(for weekday: Int) -> DaySchedule? {
        switch weekday {
        case 1: return sunday
        case 2: return monday
        case 3: return tuesday
        case 4: return wednesday
        case 5: return thursday
        case 6: return friday
        case 7: return saturday
        default: return nil
        }
    }
    
    /// Get the schedule for today
    var todaySchedule: DaySchedule {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return schedule(for: weekday) ?? DaySchedule(closed: true)
    }
    
    /// Check if the shop is open now
    var isOpenNow: Bool {
        let now = Date()
        let weekday = Calendar.current.component(.weekday, from: now)
        
        guard let todaySchedule = schedule(for: weekday), !todaySchedule.closed else {
            return false
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let currentTime = formatter.string(from: now)
        
        return todaySchedule.isOpenAt(time: currentTime)
    }
    
    /// Get all days as an array for easy iteration
    var allDays: [(String, DaySchedule)] {
        return [
            ("Lunedì", monday),
            ("Martedì", tuesday),
            ("Mercoledì", wednesday),
            ("Giovedì", thursday),
            ("Venerdì", friday),
            ("Sabato", saturday),
            ("Domenica", sunday)
        ]
    }
    
    /// Mutating method to update a day's schedule
    mutating func setSchedule(for dayIndex: Int, schedule: DaySchedule) {
        switch dayIndex {
        case 0: monday = schedule
        case 1: tuesday = schedule
        case 2: wednesday = schedule
        case 3: thursday = schedule
        case 4: friday = schedule
        case 5: saturday = schedule
        case 6: sunday = schedule
        default: break
        }
    }
}
