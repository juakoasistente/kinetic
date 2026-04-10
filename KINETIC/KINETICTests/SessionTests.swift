import Testing
import Foundation
@testable import KINETIC

struct SessionTests {

    // MARK: - formattedDistance

    @Test func formattedDistance_zero() {
        let session = Session(name: "Test", distance: 0)
        #expect(session.formattedDistance == "0.0 km")
    }

    @Test func formattedDistance_roundsToOneDecimal() {
        let session = Session(name: "Test", distance: 123.456)
        #expect(session.formattedDistance == "123.5 km")
    }

    @Test func formattedDistance_smallValue() {
        let session = Session(name: "Test", distance: 0.05)
        #expect(session.formattedDistance == "0.1 km")
    }

    // MARK: - formattedDuration

    @Test func formattedDuration_zero() {
        let session = Session(name: "Test", duration: 0)
        #expect(session.formattedDuration == "00:00")
    }

    @Test func formattedDuration_secondsOnly() {
        let session = Session(name: "Test", duration: 45)
        #expect(session.formattedDuration == "00:45")
    }

    @Test func formattedDuration_minutesAndSeconds() {
        let session = Session(name: "Test", duration: 125)
        #expect(session.formattedDuration == "02:05")
    }

    @Test func formattedDuration_justUnderOneHour() {
        let session = Session(name: "Test", duration: 3599)
        #expect(session.formattedDuration == "59:59")
    }

    @Test func formattedDuration_exactlyOneHour() {
        let session = Session(name: "Test", duration: 3600)
        #expect(session.formattedDuration == "1:00:00")
    }

    @Test func formattedDuration_hoursMinutesSeconds() {
        let session = Session(name: "Test", duration: 7322) // 2:02:02
        #expect(session.formattedDuration == "2:02:02")
    }

    @Test func formattedDuration_fractionalSecondsTruncated() {
        let session = Session(name: "Test", duration: 1.9)
        #expect(session.formattedDuration == "00:01")
    }

    // MARK: - formattedDate

    @Test func formattedDate_isUppercased() {
        let session = Session(name: "Test")
        let result = session.formattedDate
        #expect(result == result.uppercased())
    }

    // MARK: - videoType / videoLength

    @Test func videoType_nilWhenNoVideo() {
        let session = Session(name: "Test", hasVideo: false)
        #expect(session.videoType == nil)
        #expect(session.videoLength == nil)
    }

    @Test func videoType_returnsWhenHasVideo() {
        let session = Session(name: "Test", duration: 125, hasVideo: true)
        #expect(session.videoType == "4K Video")
        #expect(session.videoLength == "02:05")
    }

    // MARK: - Equality by ID

    @Test func equality_sameId() {
        let id = UUID()
        let a = Session(id: id, name: "A")
        let b = Session(id: id, name: "B")
        #expect(a == b)
    }

    @Test func equality_differentId() {
        let a = Session(name: "A")
        let b = Session(name: "A")
        #expect(a != b)
    }
}
