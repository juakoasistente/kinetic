import Testing
@testable import KINETIC

struct ClipSelectionTests {

    @Test func duration_normalRange() {
        let clip = ClipSelection(startTime: 10, endTime: 25)
        #expect(clip.duration == 15)
    }

    @Test func duration_zero() {
        let clip = ClipSelection(startTime: 5, endTime: 5)
        #expect(clip.duration == 0)
    }

    @Test func duration_fractional() {
        let clip = ClipSelection(startTime: 1.5, endTime: 4.7)
        #expect(abs(clip.duration - 3.2) < 0.001)
    }

    @Test func duration_negativeIfInverted() {
        // Edge case: shouldn't happen but verify behavior
        let clip = ClipSelection(startTime: 10, endTime: 5)
        #expect(clip.duration < 0)
    }

    @Test func clips_haveUniqueIds() {
        let a = ClipSelection(startTime: 0, endTime: 10)
        let b = ClipSelection(startTime: 0, endTime: 10)
        #expect(a.id != b.id)
    }
}
