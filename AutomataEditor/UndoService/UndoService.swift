import Foundation
import Combine
import ComposableArchitecture

private enum UndoServiceKey: DependencyKey {
  static let liveValue = UndoService.live
}

extension DependencyValues {
  var undoService: UndoService {
    get { self[UndoServiceKey.self] }
    set { self[UndoServiceKey.self] = newValue }
  }
}

struct UndoService {
    let registerUndoManager: () -> EffectTask<EditorFeature.Action>
    let registerUndo: (_ undoAction: EditorFeature.Action) -> Void
    let undo: () -> Void
    let redo: () -> Void
    var canUndo: () -> Bool
    var canRedo: () -> Bool
}

