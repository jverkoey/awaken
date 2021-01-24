import XCTest
@testable import Windfish

extension InstructionEmulatorTests {
  func test_push() {
    for spec in LR35902.InstructionSet.allSpecs() {
      guard case .push(let register) = spec, let emulator = LR35902.Emulation.push_rr(spec: spec) else { continue }
      InstructionEmulatorTests.testedSpecs.insert(spec)
      let memory = TestMemory()

      let cpu = LR35902.zeroed()
      cpu.sp = 0xfffe
      cpu[register] = 0x1234 as UInt16
      let mutations = cpu.copy()
      mutations.sp = 0xfffc
emulator.emulate(cpu: cpu, memory: memory, sourceLocation: .memory(0))

      assertEqual(cpu, mutations)
      XCTAssertEqual(memory.reads, [], "\(spec)")
      XCTAssertEqual(memory.writes, [
        .init(byte: 0x12, address: 0xfffd),
        .init(byte: register == .af ? 0x30 : 0x34, address: 0xfffc),
      ], "\(spec)")
    }
  }
}
