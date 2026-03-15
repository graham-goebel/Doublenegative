import Foundation

extension URL {
    /// Runs `body` with the security-scoped resource accessible.
    /// Stops access in a `defer` only if `startAccessingSecurityScopedResource()` returned true.
    func withSecurityScope<T>(_ body: () async -> T) async -> T {
        let accessing = startAccessingSecurityScopedResource()
        defer { if accessing { stopAccessingSecurityScopedResource() } }
        return await body()
    }
}
