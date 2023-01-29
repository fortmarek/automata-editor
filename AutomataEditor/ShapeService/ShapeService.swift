//
//  ShapeService.swift
//  AutomataEditor
//
//  Created by Marek Fořt on 30.03.2021.
//

import Foundation
import CoreGraphics
import ComposableArchitecture

/// Service for working with shapes and their points.
struct ShapeService {
    /// Returns a center from an array of points.
    let center: ([CGPoint]) -> CGPoint
    /// Returns a radius of a circle from given points and a center.
    let radius: (_ points: [CGPoint], _ center: CGPoint) -> CGFloat
    /// Returns a circle for a given center and a radius
    let circle: (_ center: CGPoint, _ radius: CGFloat) -> [CGPoint]
}

private enum ShapeServiceKey: DependencyKey {
  static let liveValue = ShapeService.live
}

extension DependencyValues {
  var shapeService: ShapeService {
    get { self[ShapeServiceKey.self] }
    set { self[ShapeServiceKey.self] = newValue }
  }
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
