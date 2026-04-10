import SwiftUI

/// Modifier to lock supported interface orientations on a per-view basis.
struct SupportedOrientationsModifier: ViewModifier {
    let orientations: UIInterfaceOrientationMask

    func body(content: Content) -> some View {
        content
            .onAppear {
                OrientationLock.shared.lock(orientations)
            }
            .onDisappear {
                OrientationLock.shared.unlock()
            }
    }
}

extension View {
    func supportedOrientations(_ orientations: UIInterfaceOrientationMask) -> some View {
        modifier(SupportedOrientationsModifier(orientations: orientations))
    }
}

/// Singleton that holds the current orientation lock.
/// AppDelegate.supportedInterfaceOrientations reads from this.
@Observable
final class OrientationLock {
    static let shared = OrientationLock()

    var current: UIInterfaceOrientationMask = .portrait

    func lock(_ orientations: UIInterfaceOrientationMask) {
        print("[OrientationLock] Locking to: \(orientations.rawValue) (portrait=\(UIInterfaceOrientationMask.portrait.rawValue), landscape=\(UIInterfaceOrientationMask.landscape.rawValue))")
        current = orientations

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.requestGeometryUpdate(
                UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: orientations)
            ) { error in
                print("[OrientationLock] Geometry update error: \(error.localizedDescription)")
            }
            UIViewController.attemptRotationToDeviceOrientation()
        }
    }

    func unlock() {
        current = .portrait

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.requestGeometryUpdate(
                UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .portrait)
            ) { _ in }
            UIViewController.attemptRotationToDeviceOrientation()
        }
    }
}

/// AppDelegate that controls which orientations are allowed at any time.
class KINETICAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        OrientationLock.shared.current
    }
}
