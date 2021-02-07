import XCTest

import LR35902
@testable import Windfish

extension InstructionEmulatorTests {
  private struct TestCase {
    let a: UInt8
    let imm8: UInt8
    let fc: Bool
    struct Result {
      let fz: Bool
      let fc: Bool
      let fh: Bool
      let a: UInt8
    }
    let result: Result

    static let testCases: [String: TestCase] = [
      "nopzero":    .init(a: 0,    imm8: 0,    fc: false, result: .init(fz: true,  fc: false, fh: false, a: 0)),
      "nopnzero":   .init(a: 1,    imm8: 0,    fc: false, result: .init(fz: false, fc: false, fh: false, a: 1)),
      "zero":       .init(a: 1,    imm8: 1,    fc: false, result: .init(fz: true,  fc: false, fh: false, a: 0)),
      "underflow":  .init(a: 0,    imm8: 1,    fc: false, result: .init(fz: false, fc: true,  fh: true,  a: 0xff)),
      "halfcarry":  .init(a: 0xf0, imm8: 1,    fc: false, result: .init(fz: false, fc: false, fh: true,  a: 0xef)),

      "cnopzero":   .init(a: 0,    imm8: 0,    fc: true, result: .init(fz: false, fc: true,  fh: true,  a: 0xff)),
      "cnopnzero":  .init(a: 1,    imm8: 0,    fc: true, result: .init(fz: true,  fc: false, fh: false, a: 0)),
      "czero":      .init(a: 1,    imm8: 1,    fc: true, result: .init(fz: false, fc: true,  fh: true,  a: 0xff)),
      "cunderflow": .init(a: 0,    imm8: 1,    fc: true, result: .init(fz: false, fc: true,  fh: true,  a: 0xfe)),
      "chalfcarry": .init(a: 0xf0, imm8: 1,    fc: true, result: .init(fz: false, fc: false, fh: true,  a: 0xee)),
    ]
  }

  // Test the a, a case separately because it's a doubling rather than an addition.
  func test_sbc_a() {
    let testCases: [String: TestCase] = [
      "zero":    .init(a: 0, imm8: 0, fc: false, result: .init(fz: true, fc: false, fh: false, a: 0)),
      "nonzero": .init(a: 1, imm8: 0, fc: false, result: .init(fz: true, fc: false, fh: false, a: 0)),

      "czero":    .init(a: 0, imm8: 0, fc: true, result: .init(fz: false, fc: true,  fh: true, a: 0xff)),
      "cnonzero": .init(a: 1, imm8: 0, fc: true, result: .init(fz: false, fc: true,  fh: true, a: 0xff)),
    ]
    for (name, testCase) in testCases {
      for spec in LR35902.InstructionSet.allSpecs() {
        guard case .sbc(.a) = spec, let emulator = LR35902.Emulation.sbc_r(spec: spec) else { continue }
        InstructionEmulatorTests.testedSpecs.insert(spec)
        let memory = TestMemory()
        let cpu = LR35902.zeroed()
        cpu.fcarry = testCase.fc
        cpu.a = testCase.a
        let mutations = cpu.copy()

        emulator.emulate(cpu: cpu, memory: memory, sourceLocation: .memory(0))

        mutations.a = testCase.result.a
        mutations.fsubtract = true
        mutations.fzero = testCase.result.fz
        mutations.fcarry = testCase.result.fc
        mutations.fhalfcarry = testCase.result.fh
        assertEqual(cpu, mutations, message: "Test case: \(name)")
      }
    }
  }

  func test_sbc_n() {
    for (name, testCase) in TestCase.testCases {
      for spec in LR35902.InstructionSet.allSpecs() {
        guard let emulator = LR35902.Emulation.sbc_n(spec: spec) else { continue }
        InstructionEmulatorTests.testedSpecs.insert(spec)
        let memory = TestMemory(defaultReadValue: testCase.imm8)
        let cpu = LR35902.zeroed()
        cpu.a = testCase.a
        cpu.fcarry = testCase.fc
        let mutations = cpu.copy()

        emulator.emulate(cpu: cpu, memory: memory, sourceLocation: .memory(0))

        mutations.pc += 1
        mutations.a = testCase.result.a
        mutations.fsubtract = true
        mutations.fzero = testCase.result.fz
        mutations.fcarry = testCase.result.fc
        mutations.fhalfcarry = testCase.result.fh
        assertEqual(cpu, mutations, message: "Test case: \(name)")
      }
    }
  }

  func test_sbc_r() {
    for (name, testCase) in TestCase.testCases {
      for spec in LR35902.InstructionSet.allSpecs() {
        guard case .sbc(let register) = spec, register != .a,
              let emulator = LR35902.Emulation.sbc_r(spec: spec) else { continue }
        InstructionEmulatorTests.testedSpecs.insert(spec)
        let memory = TestMemory()
        let cpu = LR35902.zeroed()
        cpu.a = testCase.a
        cpu.fcarry = testCase.fc
        cpu[register] = testCase.imm8
        let mutations = cpu.copy()

        emulator.emulate(cpu: cpu, memory: memory, sourceLocation: .memory(0))

        mutations.a = testCase.result.a
        mutations.fsubtract = true
        mutations.fzero = testCase.result.fz
        mutations.fcarry = testCase.result.fc
        mutations.fhalfcarry = testCase.result.fh
        assertEqual(cpu, mutations, message: "Test case: \(name)")
      }
    }
  }

  func test_sbc_hladdr() {
    for (name, testCase) in TestCase.testCases {
      for spec in LR35902.InstructionSet.allSpecs() {
        guard let emulator = LR35902.Emulation.sbc_hladdr(spec: spec) else { continue }
        InstructionEmulatorTests.testedSpecs.insert(spec)
        let memory = TestMemory(defaultReadValue: testCase.imm8)
        let cpu = LR35902.zeroed()
        cpu.a = testCase.a
        cpu.fcarry = testCase.fc
        let mutations = cpu.copy()

        emulator.emulate(cpu: cpu, memory: memory, sourceLocation: .memory(0))

        mutations.a = testCase.result.a
        mutations.fsubtract = true
        mutations.fzero = testCase.result.fz
        mutations.fcarry = testCase.result.fc
        mutations.fhalfcarry = testCase.result.fh
        assertEqual(cpu, mutations, message: "Test case: \(name)")
      }
    }
  }
}
