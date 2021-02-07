import Foundation

import LR35902

extension LR35902.Emulation {
  final class add_a_r: InstructionEmulator, InstructionEmulatorInitializable {
    init?(spec: LR35902.Instruction.Spec) {
      let registers8 = LR35902.Instruction.Numeric.registers8
      guard case .add(.a, let register) = spec, registers8.contains(register) else {
        return nil
      }
      self.register = register
    }

    func emulate(cpu: LR35902, memory: TraceableMemory, sourceLocation: Gameboy.SourceLocation) {
      memory.registerTraces[.a, default: []].append(contentsOf: memory.registerTraces[register] ?? [])

      addNoCarry(cpu: cpu, value: cpu[register] as UInt8?)
    }

    private let register: LR35902.Instruction.Numeric
  }
}
