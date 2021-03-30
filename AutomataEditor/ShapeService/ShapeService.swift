//
//  ShapeService.swift
//  AutomataEditor
//
//  Created by Marek Fořt on 30.03.2021.
//

import Foundation
import CoreGraphics

struct ShapeService {
    let center: ([CGPoint]) -> CGPoint
    let radius: (_ points: [CGPoint], _ center: CGPoint) -> CGFloat
    let circle: (_ center: CGPoint, _ radius: CGFloat) -> [CGPoint]
}

extension ShapeService {
    static func mock(
        center: @escaping ([CGPoint]) -> CGPoint,
        radius: @escaping (_ points: [CGPoint], _ center: CGPoint) -> CGFloat
    ) -> Self {
        .init(
            center: center,
            radius: radius,
            circle: { center, _ in
                [center]
            }
        )
    }
}
