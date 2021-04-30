//
//  IDFactory.swift
//  AutomataEditor
//
//  Created by Marek Fořt on 30.03.2021.
//

import Foundation
import ComposableArchitecture

/// Factory for generating unique IDs
struct IDFactory {
    let generateID: () -> String
}

extension IDFactory {
    static func mock(_ generateID: @escaping () -> String) -> IDFactory {
        .init(
            generateID: generateID
        )
    }
}
