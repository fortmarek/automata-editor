import Foundation
import Combine
import ComposableArchitecture

enum AutomatonDocumentServiceError: Error {
    case urlNotFound
}

extension AutomatonDocumentService {
    private static var url: URL? {
        FileManager.default
            .url(forUbiquityContainerIdentifier: nil)?
            .appendingPathComponent("Documents") ??
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    }
    
    static let live: Self = Self(
        createNewAutomaton: { automatonName in
            guard
                let url = url
            else {
                throw AutomatonDocumentServiceError.urlNotFound
            }
            let fileURL = url.appendingPathComponent("\(automatonName).automaton")
            let automaton = AutomatonDocument()
            let jsonEncoder = JSONEncoder()
            let data = try jsonEncoder.encode(automaton)
            try data.write(to: fileURL)
            
            return fileURL
        },
        readAutomaton: { url in
            let data = try Data(contentsOf: url)
            let jsonDecoder = JSONDecoder()
            let automatonDocument = try jsonDecoder.decode(AutomatonDocument.self, from: data)
            return automatonDocument
        },
        loadAutomata: {
            guard
                let url = url
            else {
                throw AutomatonDocumentServiceError.urlNotFound
            }
            return try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
                .filter { !$0.hasDirectoryPath }
        },
        saveAutomaton: { url, automatonDocument in
            let jsonEncoder = JSONEncoder()
            let data = try jsonEncoder.encode(automatonDocument)
            try data.write(to: url)
        },
        deleteAutomata: { urls in
            try urls.forEach(FileManager.default.removeItem)
        }
    )
}
