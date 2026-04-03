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
}
