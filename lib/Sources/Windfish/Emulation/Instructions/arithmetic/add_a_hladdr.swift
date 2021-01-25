import Foundation

extension LR35902.Emulation {
  final class add_a_hladdr: InstructionEmulator, InstructionEmulatorInitializable {
    init?(spec: LR35902.Instruction.Spec) {
      guard case .add(.a, .hladdr) = spec else {
        return nil
      }
    }

    func emulate(cpu: LR35902, memory: TraceableMemory, sourceLocation: Gameboy.SourceLocation) {
      if let hl = cpu.hl {
        cpu.registerTraces[.a, default: []].append(.mutationFromAddress(memory.sourceLocation(from: hl)))
      }
      addNoCarry(cpu: cpu, value: read(address: cpu.hl, from: memory))
    }
  }
}
