import Foundation

extension LR35902.Emulation {
  final class rr_hladdr: InstructionEmulator, InstructionEmulatorInitializable {
    init?(spec: LR35902.Instruction.Spec) {
      guard case .cb(.rr(.hladdr)) = spec else {
        return nil
      }
    }

    func emulate(cpu: LR35902, memory: AddressableMemory, sourceLocation: Gameboy.SourceLocation) {
      value = memory.read(from: cpu.hl)
      cpu.fsubtract = false
      cpu.fhalfcarry = false

      let carry = (value & 0b0000_0001) != 0
      let result = (value &>> 1) | (cpu.fcarry ? 0b1000_0000 : 0)
      cpu.fzero = result == 0
      cpu.fcarry = carry
      value = result
      memory.write(value, to: cpu.hl)
    }

    private var value: UInt8 = 0
  }
}
