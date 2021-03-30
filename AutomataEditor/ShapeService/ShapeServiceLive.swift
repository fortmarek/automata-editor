//
//  ShapeServiceLive.swift
//  AutomataEditor
//
//  Created by Marek Fořt on 30.03.2021.
//

import Foundation
import CoreGraphics

extension ShapeService {
    static func live() -> ShapeService {
        return ShapeService(
            center: { $0.center() },
            radius: { $0.radius(with: $1) },
            circle: { .circle(center: $0, radius: $1) }
        )
    }
}
