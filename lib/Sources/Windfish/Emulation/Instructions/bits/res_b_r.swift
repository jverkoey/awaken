import Foundation

extension LR35902.Emulation {
  final class res_b_r: InstructionEmulator, InstructionEmulatorInitializable {
    init?(spec: LR35902.Instruction.Spec) {
      let registers8 = LR35902.Instruction.Numeric.registers8
      guard case .cb(.res(let bit, let register)) = spec, registers8.contains(register) else {
        return nil
      }
      self.bit = bit
      self.register = register
    }

    func emulate(cpu: LR35902, memory: AddressableMemory, sourceLocation: Gameboy.SourceLocation) {
      cpu[register] &= ~(UInt8(1) << bit.rawValue)
    }

    private let register: LR35902.Instruction.Numeric
    private let bit: LR35902.Instruction.Bit
  }
}
