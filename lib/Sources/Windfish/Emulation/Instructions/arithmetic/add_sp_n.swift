import Foundation

// References:
// - https://stackoverflow.com/questions/57958631/game-boy-half-carry-flag-and-16-bit-instructions-especially-opcode-0xe8

extension LR35902.Emulation {
  final class add_sp_n: InstructionEmulator, InstructionEmulatorInitializable {
    init?(spec: LR35902.Instruction.Spec) {
      guard case .add(.sp, .imm8) = spec else {
        return nil
      }
    }

    func emulate(cpu: LR35902, memory: AddressableMemory, sourceLocation: Gameboy.SourceLocation) {
      immediate = Int8(bitPattern: memory.read(from: cpu.pc))
      cpu.pc += 1
      cpu.fzero = false
      cpu.fsubtract = false
      let wideImm = UInt16(bitPattern: Int16(truncatingIfNeeded: immediate))
      cpu.fcarry = (cpu.sp & 0xff) &+ (wideImm & 0xff) > 0xff
      cpu.fhalfcarry = (cpu.sp & 0xf) &+ (wideImm & 0xf) > 0xf
      wz = cpu.sp &+ wideImm
      cpu.sp = wz
    }

    private var immediate: Int8 = 0
    private var wz: UInt16 = 0
  }
}
