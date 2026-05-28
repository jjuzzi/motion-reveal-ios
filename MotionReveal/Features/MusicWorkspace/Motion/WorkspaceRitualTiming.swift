import Foundation

struct WorkspaceRitualTiming: Equatable {
    var loadScreenSwapDelayMilliseconds: Int
    var loadDismissDelayMilliseconds: Int
    var createInsertDelayMilliseconds: Int
    var createActivateDelayMilliseconds: Int

    init(reduceMotion: Bool) {
        if reduceMotion {
            loadScreenSwapDelayMilliseconds = 120
            loadDismissDelayMilliseconds = 90
            createInsertDelayMilliseconds = 140
            createActivateDelayMilliseconds = 90
        } else {
            loadScreenSwapDelayMilliseconds = 1_210
            loadDismissDelayMilliseconds = 250
            createInsertDelayMilliseconds = 1_420
            createActivateDelayMilliseconds = 180
        }
    }

    var totalLoadDelayMilliseconds: Int {
        loadScreenSwapDelayMilliseconds + loadDismissDelayMilliseconds
    }

    var totalCreateDelayMilliseconds: Int {
        createInsertDelayMilliseconds + createActivateDelayMilliseconds
    }
}
