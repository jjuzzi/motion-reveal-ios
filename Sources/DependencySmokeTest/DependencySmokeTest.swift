import Foundation

#if canImport(Lottie)
import Lottie
#endif

#if canImport(RiveRuntime)
import RiveRuntime
#endif

public enum DependencySmokeTest {
    public static let configuredPackages = [
        "RiveRuntime",
        "Lottie"
    ]
}
