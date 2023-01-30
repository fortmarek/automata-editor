import Foundation
import ComposableArchitecture
import Combine

private enum AutomatonDocumentServiceKey: DependencyKey {
  static let liveValue = AutomatonDocumentService.live
}

extension DependencyValues {
  var automatonDocumentService: AutomatonDocumentService {
    get { self[AutomatonDocumentServiceKey.self] }
    set { self[AutomatonDocumentServiceKey.self] = newValue }
  }
}

/// Service to interact with `AutomatonDocument`s
struct AutomatonDocumentService {
    /// Creates a new `AutomatonDocument` in the ubiquituous folder
    /// Throws `AutomatonDocumentServiceError` if the file could not be created
    let createNewAutomaton: () async throws -> URL
    /// Reads the automaton from a given URL
    let readAutomaton: (URL) async throws -> AutomatonDocument
    /// Loads automata from the ubiquity container
    let loadAutomata: () async throws -> [URL]
    /// Saves automaton to a given URL
    let saveAutomaton: (URL, AutomatonDocument) throws -> Void
}

