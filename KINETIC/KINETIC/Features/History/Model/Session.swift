import Foundation

struct Session: Identifiable, Hashable {
    let id: String
    let name: String
    let category: String
    let vehicle: String
    let date: Date
    let distance: Double
    let duration: TimeInterval
    let hasVideo: Bool
    let thumbnailURL: String?

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        return formatter.string(from: date).uppercased()
    }

    var formattedDistance: String {
        String(format: "%.1f km", distance)
    }

    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        let seconds = Int(duration) % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var videoType: String? {
        hasVideo ? "4K Video" : nil
    }

    var videoLength: String? {
        guard hasVideo else { return nil }
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    static let mockData: [Session] = {
        let calendar = Calendar.current
        let now = Date()
        return [
            Session(
                id: "1",
                name: "Sierra Route",
                category: "Performance Run",
                vehicle: "Porsche 911",
                date: calendar.date(byAdding: .day, value: -5, to: now)!,
                distance: 42.8,
                duration: 1452,
                hasVideo: false,
                thumbnailURL: nil
            ),
            Session(
                id: "2",
                name: "Coastal Loop",
                category: "Cruising",
                vehicle: "BMW M3",
                date: calendar.date(byAdding: .day, value: -9, to: now)!,
                distance: 128.5,
                duration: 6300,
                hasVideo: false,
                thumbnailURL: nil
            ),
            Session(
                id: "3",
                name: "Tunnel Sound Run",
                category: "Exhaust Note",
                vehicle: "Audi R8",
                date: calendar.date(byAdding: .day, value: -17, to: now)!,
                distance: 18.0,
                duration: 165,
                hasVideo: true,
                thumbnailURL: nil
            ),
            Session(
                id: "4",
                name: "Midnight City",
                category: "Precision",
                vehicle: "Nissan GT-R",
                date: calendar.date(byAdding: .day, value: -24, to: now)!,
                distance: 18.2,
                duration: 770,
                hasVideo: false,
                thumbnailURL: nil
            ),
        ]
    }()
}
