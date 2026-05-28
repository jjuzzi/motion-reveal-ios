import OSLog
import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct WorkspaceDocumentPicker: UIViewControllerRepresentable {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.jjuzzi.motionreveal",
        category: "ImportPicker"
    )

    @Binding var isPresented: Bool
    let allowedContentTypes: [UTType]
    let allowsMultipleSelection: Bool
    let onCompletion: (Result<[URL], Error>) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(
            forOpeningContentTypes: allowedContentTypes,
            asCopy: true
        )
        picker.delegate = context.coordinator
        picker.presentationController?.delegate = context.coordinator
        picker.allowsMultipleSelection = allowsMultipleSelection
        picker.shouldShowFileExtensions = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UIDocumentPickerDelegate, UIAdaptivePresentationControllerDelegate {
        private var parent: WorkspaceDocumentPicker
        private var didResolve = false

        init(_ parent: WorkspaceDocumentPicker) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if urls.isEmpty {
                WorkspaceDocumentPicker.logger.warning("Files picker returned no documents before dismissal")
            } else {
                WorkspaceDocumentPicker.logger.info(
                    "Files picker selected documents count=\(urls.count, privacy: .public)"
                )
            }

            resolve(with: .success(urls))
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            WorkspaceDocumentPicker.logger.info("Files picker cancelled by user")
            resolve(with: .failure(Self.userCancelledError(description: "The file picker was cancelled.")))
        }

        func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
            guard !didResolve else { return }

            WorkspaceDocumentPicker.logger.info("Files picker dismissed without returning a selection")
            resolve(
                with: .failure(
                    Self.userCancelledError(description: "The file picker was dismissed without returning a selection.")
                )
            )
        }

        private func resolve(with result: Result<[URL], Error>) {
            guard !didResolve else { return }

            didResolve = true
            parent.isPresented = false
            parent.onCompletion(result)
        }

        private static func userCancelledError(description: String) -> NSError {
            NSError(
                domain: NSCocoaErrorDomain,
                code: NSUserCancelledError,
                userInfo: [NSLocalizedDescriptionKey: description]
            )
        }
    }
}
