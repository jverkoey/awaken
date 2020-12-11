import Foundation

/** A computed representation of an instruction's binary width. */
public struct InstructionWidth<T: BinaryInteger>: Equatable {
  public init(opcode: T, operand: T) {
    self.opcode = opcode
    self.operand = operand
  }

  /** The width of the opcode. */
  public let opcode: T

  /** The width of the operand(s). */
  public let operand: T

  /** The total width of the instruction. */
  public var total: T {
    return opcode + operand
  }
}

/** A representation of an instruction set. */
public protocol InstructionSet {
  /** The instruction type this set consists of. */
  associatedtype InstructionType: Instruction
  typealias SpecType = InstructionType.SpecType

  /**
   The primary table of instructions.

   The array's index is meant to correspond to the binary opcode value of the instruction. When no instruction is
   available for a given index, provide an invalid instruction specification as filler.
   */
  static var table: [SpecType] { get }

  /** Additional tables for multi-byte instructions. */
  static var prefixTables: [SpecType: [SpecType]] { get }

  /**
   A cached map of specifications to computed widths.

   This is typically implemented by returning the result of `computeAllWidths()`.
   */
  static var widths: [SpecType: InstructionWidth<SpecType.WidthType>] { get }

  /**
   A cached map of specifications to their binary opcode representations.

   This is typically implemented by returning the result of `computeAllInstructionOpcodes()`.
   */
  static var instructionOpcodes: [SpecType: [UInt8]] { get }
}

// MARK: - Helper methods for computing properties

extension InstructionSet {
  /** Returns all specifications in this instruction set. */
  public static func allSpecs() -> [SpecType] {
    return (table + prefixTables.values.reduce([], +))
  }

  /** Calculates the widths for every specification in this set. */
  public static func computeAllWidths() -> [SpecType: InstructionWidth<SpecType.WidthType>] {
    var widths: [SpecType: InstructionWidth<SpecType.WidthType>] = [:]
    allSpecs().forEach { spec in
      widths[spec] = InstructionWidth(opcode: spec.opcodeWidth, operand: spec.operandWidth)
    }
    return widths
  }

  /** Calculates the opcode for every instruction in this set. */
  public static func computeAllInstructionOpcodes() -> [SpecType: [UInt8]] {
    var binary: [SpecType: [UInt8]] = [:]
    computeAllInstructionOpcodes(accumulator: &binary, table: table, prefix: [])
    return binary
  }

  /** Recursively computes opcodes by traversing tables when prefixes are encountered. */
  private static func computeAllInstructionOpcodes(accumulator: inout [SpecType: [UInt8]],
                                                   table: [SpecType],
                                                   prefix: [UInt8]) {
    for (byteRepresentation, spec) in table.enumerated() {
      let opcode = prefix + [UInt8(byteRepresentation)]
      if let prefixTable = prefixTables[spec] {
        computeAllInstructionOpcodes(accumulator: &accumulator,
                                     table: prefixTable,
                                     prefix: opcode)
      } else {
        accumulator[spec] = opcode
      }
    }
  }
}
