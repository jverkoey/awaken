import Foundation

extension Disassembler.Configuration {
  /** Returns the pre-comment registered at the given location, if any. */
  func preComment(at location: Cartridge.Location) -> String? {
    return preComments[location]
  }

  /** Registers a pre-comment at the given location. */
  func registerPreComment(at location: Cartridge.Location, text: String) {
    preComments[location] = text
  }
}