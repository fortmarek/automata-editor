import Foundation
import SwiftUI
import UIKit

final class DocumentPickerCoordinator: NSObject, UIDocumentPickerDelegate {
    private var parent: DocumentPicker
    
    init(parent: DocumentPicker){
        self.parent = parent
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        parent.selectedDocument(url)
    }
}

struct DocumentPicker: UIViewControllerRepresentable {
    let selectedDocument: (URL) -> Void
    
    func makeCoordinator() -> DocumentPickerCoordinator {
        return DocumentPickerCoordinator(parent: self)
    }
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<DocumentPicker>) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.automatonDocument])
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(
        _ uiViewController: DocumentPicker.UIViewControllerType,
        context: UIViewControllerRepresentableContext<DocumentPicker>
    ) {
        // noop
    }
}
