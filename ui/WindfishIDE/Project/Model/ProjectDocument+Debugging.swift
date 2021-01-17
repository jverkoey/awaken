import Foundation

extension ProjectDocument {
  @objc func stepForward(_ sender: Any?) {
    guard project.sameboy.debugStopped else {
      return // Emulation must be stopped first.
    }

    project.nextDebuggerCommand = "next"
    project.sameboyDebuggerSemaphore.signal()
  }

  @objc func stepInto(_ sender: Any?) {
    guard project.sameboy.debugStopped else {
      return // Emulation must be stopped first.
    }

    project.nextDebuggerCommand = "step"
    project.sameboyDebuggerSemaphore.signal()
  }

  @objc func undoCommand(_ sender: Any?) {
    guard project.sameboy.debugStopped else {
      return // Emulation must be stopped first.
    }

    project.nextDebuggerCommand = "undo"
    project.sameboyDebuggerSemaphore.signal()
  }

  @objc func toggleEmulation(_ sender: Any?) {
    project.sameboy.debugStopped = !project.sameboy.debugStopped

    if !project.sameboy.debugStopped {
      // Disconnect the debugger repl.
      project.nextDebuggerCommand = nil
      project.sameboyDebuggerSemaphore.signal()
    }

    // TODO: Signal to the UI of this state change.
//    self.toggleEmulationButton?.state = document.sameboy.gb.pointee.debug_stopped ? .off : .on
  }

  @objc func pauseEmulation(_ sender: Any?) {
    project.sameboy.debuggerBreak()
  }
}
