import Foundation

extension LR35902.Emulation {
  final class ret: InstructionEmulator, InstructionEmulatorInitializable {
    init?(spec: LR35902.Instruction.Spec) {
      guard case .ret(nil) = spec else {
        return nil
      }
    }

    func advance(cpu: LR35902, memory: AddressableMemory, cycle: Int, sourceLocation: Gameboy.SourceLocation) -> LR35902.Emulation.EmulationResult {
      if cycle == 1 {
        pc = UInt16(truncatingIfNeeded: memory.read(from: cpu.sp))
        cpu.sp &+= 1
        return .continueExecution
      }
      if cycle == 2 {
        pc |= UInt16(truncatingIfNeeded: memory.read(from: cpu.sp)) << 8
        cpu.sp &+= 1
        return .continueExecution
      }
      if cycle == 3 {
        return .continueExecution
      }
      cpu.pc = pc
      return .fetchNext
    }

    private var pc: UInt16 = 0
  }
}
