import Foundation

extension LR35902.Emulation {
  final class rla: InstructionEmulator, InstructionEmulatorInitializable {
    init?(spec: LR35902.Instruction.Spec) {
      guard case .rla = spec else {
        return nil
      }
    }

    func emulate(cpu: LR35902, memory: AddressableMemory, sourceLocation: Gameboy.SourceLocation) {
      cpu.fzero = false
      cpu.fsubtract = false
      cpu.fhalfcarry = false

      let carry = (cpu.a & 0b1000_0000) != 0
      let result = (cpu.a &<< 1) | (cpu.fcarry ? 0x01 : 0)
      cpu.fcarry = carry
      cpu.a = result
    }
  }
}
