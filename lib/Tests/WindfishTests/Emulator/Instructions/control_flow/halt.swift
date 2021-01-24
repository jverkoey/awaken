import XCTest
@testable import Windfish

extension InstructionEmulatorTests {
  func test_halt() {
    for spec in LR35902.InstructionSet.allSpecs() {
      guard let emulator = LR35902.Emulation.halt(spec: spec) else { continue }
      InstructionEmulatorTests.testedSpecs.insert(spec)
      let memory = TestMemory(defaultReadValue: 0x12)

      let cpu = LR35902.zeroed()
      let mutations = cpu.copy()
emulator.emulate(cpu: cpu, memory: memory, sourceLocation: .memory(0))

      mutations.halted = true
      assertEqual(cpu, mutations, message: "Test case: \(name)")
    }
  }
}
