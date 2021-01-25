import Foundation

extension LR35902.Emulation {
  final class adc_n: InstructionEmulator, InstructionEmulatorInitializable {
    init?(spec: LR35902.Instruction.Spec) {
      guard case .adc(.imm8) = spec else {
        return nil
      }
    }

    func emulate(cpu: LR35902, memory: TraceableMemory, sourceLocation: Gameboy.SourceLocation) {
      cpu.registerTraces[.a, default: []].append(.mutationWithImmediateAtSourceLocation(sourceLocation))

      addConsideringCarry(cpu: cpu, value: memory.read(from: cpu.pc))
      cpu.pc &+= 1
    }
  }
}
