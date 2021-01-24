import Foundation

extension LR35902.Emulation {
  final class nop: InstructionEmulator, InstructionEmulatorInitializable {
    init?(spec: LR35902.Instruction.Spec) {
      guard case .nop = spec else {
        return nil
      }
    }

    func emulate(cpu: LR35902, memory: AddressableMemory, sourceLocation: Gameboy.SourceLocation) {
    }
  }
}
