import Foundation

import LR35902

extension LR35902.Emulation {
  final class ld_rraddr_r: InstructionEmulator, InstructionEmulatorInitializable {
    init?(spec: LR35902.Instruction.Spec) {
      let registers8 = LR35902.Instruction.Numeric.registers8
      let registersAddr = LR35902.Instruction.Numeric.registersAddr
      guard case .ld(let dst, let src) = spec, registersAddr.contains(dst) && registers8.contains(src) else {
        return nil
      }
      self.dst = dst
      self.src = src
    }

    func emulate(cpu: LR35902, memory: TraceableMemory, sourceLocation: Gameboy.SourceLocation) {
      guard let address: UInt16 = cpu[dst] else {
        return
      }
      memory.registerTraces[src, default: []].append(.storeToAddress(address))

      memory.write(cpu[src], to: address)
    }

    private let dst: LR35902.Instruction.Numeric
    private let src: LR35902.Instruction.Numeric
  }
}
