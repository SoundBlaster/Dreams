import Foundation

enum DreamsError: LocalizedError {
    case unavailable(String)
    var errorDescription: String? { if case .unavailable(let message) = self { message } else { nil } }
}
