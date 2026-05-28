import Foundation

extension Error {
    var isUserCanceledImport: Bool {
        let error = self as NSError
        return error.domain == NSCocoaErrorDomain && error.code == NSUserCancelledError
    }
}
