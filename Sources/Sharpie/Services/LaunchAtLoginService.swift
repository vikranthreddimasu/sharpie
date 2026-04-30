import Foundation
import ServiceManagement

// SMAppService.mainApp is the modern (macOS 13+) replacement for the old
// LSSharedFileList / SMLoginItemSetEnabled approach. The mainApp registers
// the host .app bundle as a login item — the .app's CFBundleIdentifier is
// what the registration tracks, so launch-at-login only takes effect when
// Sharpie is launched as a bundled .app, not as a loose `swift run` binary.
enum LaunchAtLoginService {

    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// `true` if we're running inside a .app bundle and SMAppService can
    /// meaningfully register us. Loose-binary `swift run` invocations
    /// can't register, so we hide the toggle in that case.
    static var isAvailable: Bool {
        Bundle.main.bundleIdentifier?.isEmpty == false
            && Bundle.main.bundlePath.hasSuffix(".app")
    }

    @discardableResult
    static func set(_ enabled: Bool) -> Bool {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            return true
        } catch {
            return false
        }
    }
}
