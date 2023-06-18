import Foundation
import ComposableArchitecture

final class EditorUndoManager: UndoManager {
    let send: Send<EditorFeature.Action>
    
    init(_ send: Send<EditorFeature.Action>) {
        self.send = send
    }
}

extension UndoService {
    static var undoManager: EditorUndoManager!
    static let live = Self(
        registerUndoManager: {
            return EffectTask<EditorFeature.Action>.run { send in
                undoManager = EditorUndoManager(send)
            }
        },
        registerUndo: { undoAction in
            undoManager.registerUndo(withTarget: undoManager) { undoManager in
                Task { await undoManager.send(undoAction) }
            }
        },
        undo: {
            undoManager.undo()
        },
        redo: {
            undoManager.redo()
        },
        canUndo: { undoManager.canUndo },
        canRedo: { undoManager.canRedo }
    )
}
