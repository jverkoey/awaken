import XCTest
@testable import Windfish

extension InstructionEmulatorTests {
  private struct TestCase {
    let value: UInt8
    let fc: Bool
    struct Result {
      let fc: Bool
      let fz: Bool
      let value: UInt8
    }
    let result: Result

    static let testCases: [String: TestCase] = [
      "zero":       .init(value: 0,           fc: false, result: .init(fc: false, fz: true,  value: 0)),
      "0000_0001":  .init(value: 0b0000_0001, fc: false, result: .init(fc: true,  fz: true,  value: 0)),
      "0001_0000":  .init(value: 0b0001_0000, fc: false, result: .init(fc: false, fz: false, value: 0b0000_1000)),
      "1000_0000":  .init(value: 0b1000_0000, fc: false, result: .init(fc: false, fz: false, value: 0b0100_0000)),
    ]
  }

  func test_srl_r() {
    for spec in LR35902.InstructionSet.allSpecs() {
      guard case .cb(.srl(let register)) = spec, let emulator = LR35902.Emulation.srl_r(spec: spec) else { continue }
      InstructionEmulatorTests.testedSpecs.insert(spec)
      for (name, testCase) in TestCase.testCases {
        let memory = TestMemory()
        let cpu = LR35902.zeroed()
        cpu[register] = testCase.value
        cpu.fsubtract = true
        cpu.fhalfcarry = true
        cpu.fzero = true
        cpu.fcarry = testCase.fc
        let mutations = cpu.copy()

        emulator.emulate(cpu: cpu, memory: memory, sourceLocation: .memory(0))

        mutations.fcarry = testCase.result.fc
        mutations.fzero = testCase.result.fz
        mutations.fsubtract = false
        mutations.fhalfcarry = false
        mutations[register] = testCase.result.value
        assertEqual(cpu, mutations, message: "Test case: \(name)")
      }
    }
  }

  func test_srl_hladdr() {
    for spec in LR35902.InstructionSet.allSpecs() {
      guard let emulator = LR35902.Emulation.srl_hladdr(spec: spec) else { continue }
      InstructionEmulatorTests.testedSpecs.insert(spec)
      for (name, testCase) in TestCase.testCases {
        let memory = TestMemory(defaultReadValue: testCase.value)
        let cpu = LR35902.zeroed()
        cpu.hl = 0x1234
        cpu.fsubtract = true
        cpu.fhalfcarry = true
        cpu.fzero = true
        cpu.fcarry = testCase.fc
        let mutations = cpu.copy()

        emulator.emulate(cpu: cpu, memory: memory, sourceLocation: .memory(0))

        mutations.fcarry = testCase.result.fc
        mutations.fzero = testCase.result.fz
        mutations.fsubtract = false
        mutations.fhalfcarry = false
        assertEqual(cpu, mutations, message: "Test case: \(name)")
        XCTAssertEqual(memory.reads, [0x1234], "\(name)")
        XCTAssertEqual(memory.writes, [
          .init(byte: testCase.result.value, address: 0x1234),
        ], "\(name)")
      }
    }
  }
}
