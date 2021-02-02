import Foundation
import Cocoa

import RGBDS
import Windfish

extension RGBDS.Statement {
  func attributedString(attributes: [NSAttributedString.Key : Any],
                        opcodeAttributes: [NSAttributedString.Key : Any],
                        operandAttributes: [NSAttributedString.Key : Any],
                        regionLookup: [String: Region],
                        scope: String?) -> NSAttributedString {
    let string = NSMutableAttributedString(string: formattedOpcode)
    string.beginEditing()
    if let spec: LR35902.Instruction.Spec = context as? LR35902.Instruction.Spec,
       let documentation: String = opcodeDocumentation[spec] {
      var attributesWithDocs = opcodeAttributes
      attributesWithDocs[.toolTip] = documentation
      string.setAttributes(attributesWithDocs, range: NSRange(location: 0, length: string.length))
    } else {
      string.setAttributes(opcodeAttributes, range: NSRange(location: 0, length: string.length))
    }
    if !operands.isEmpty {
      string.append(NSAttributedString(string: " ", attributes: attributes))

      let separator = ", "
      var accumulatedLength = 0
      let operandStrings: [(String, (Int, String, String)?)] = operands.map { operand in
        let label: String
        if let scope = scope, operand.starts(with: ".") {
          label = scope + operand
        } else {
          label = operand
        }

        let lengthSoFar = accumulatedLength
        accumulatedLength += operand.count + separator.count
        if regionLookup[label] != nil {
          return (operand, (lengthSoFar, "windfish://jumpto/\(label)", "Jump to \(label)"))
        } else {
          return (operand, nil)
        }
      }
      let operandString = NSMutableAttributedString(string: operandStrings.map { $0.0 }.joined(separator: separator),
                                                    attributes: operandAttributes)
      operandStrings.filter { $0.1 != nil }.forEach {
        let range = NSRange(($0.1!.0..<$0.1!.0 + $0.0.count))
        operandString.addAttribute(.link, value: $0.1!.1, range: range)
        operandString.addAttribute(.toolTip, value: $0.1!.2, range: range)
      }
      string.append(operandString)
    }
    string.endEditing()
    return string
  }
}
