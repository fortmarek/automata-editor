//
//  IDFactoryLive.swift
//  AutomataEditor
//
//  Created by Marek Fořt on 30.03.2021.
//

import Foundation

extension IDFactory {
    static func live() -> IDFactory {
        .init(
            generateID: { UUID().uuidString }
        )
    }
}
