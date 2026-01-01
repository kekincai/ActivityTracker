import Foundation
import AppKit

class ExportManager {
    static let shared = ExportManager()
    
    private let dataStore = DataStore.shared
    
    private init() {}
    
    func exportCSV() {
        guard let url = dataStore.exportToCSV() else {
            showAlert(title: "Export Failed", message: "Failed to export CSV file.")
            return
        }
        revealInFinder(url)
    }
    
    func exportJSON() {
        guard let url = dataStore.exportToJSON() else {
            showAlert(title: "Export Failed", message: "Failed to export JSON file.")
            return
        }
        revealInFinder(url)
    }
    
    private func revealInFinder(_ url: URL) {
        NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: url.deletingLastPathComponent().path)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
