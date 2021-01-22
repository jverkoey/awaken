import Foundation

extension Disassembler {
  /** Returns all scopes that intersect with the given location. */
  func contiguousScopes(at pc: LR35902.Address, in bank: Cartridge.Bank) -> Set<Range<Cartridge._Location>> {
    guard let location: Cartridge._Location = Cartridge.location(for: pc, in: bank) else {
      return Set()
    }
    let effectiveBank: Cartridge.Bank = self.effectiveBank(at: pc, in: bank)
    return contiguousScopes[effectiveBank, default: Set()].filter { (scope: (Range<Cartridge._Location>)) -> Bool in
      scope.contains(location)
    }
  }

  /** Returns all labeled scopes that intersect with the given location. */
  public func labeledContiguousScopes(at location: Cartridge.Location) -> [(label: String, scope: Range<Cartridge._Location>)] {
    return contiguousScopes(at: location.address, in: location.bank).compactMap { (range: Range<Cartridge._Location>) -> (label: String, scope: Range<Cartridge._Location>)? in
      let addressAndBank: (address: LR35902.Address, bank: Cartridge.Bank) = Cartridge.addressAndBank(from: range.lowerBound)
      guard let label: String = label(at: addressAndBank.address, in: addressAndBank.bank) else {
        return nil
      }
      return (label, range)
    }
  }

  /** Registers a new contiguous scope at the given range. */
  func registerContiguousScope(range: Range<Cartridge._Location>) {
    let bankAndAddress: (address: LR35902.Address, bank: Cartridge.Bank) = Cartridge.addressAndBank(from: range.lowerBound)
    let bankAndAddress2: (address: LR35902.Address, bank: Cartridge.Bank) = Cartridge.addressAndBank(from: range.upperBound - 1)
    precondition(bankAndAddress.bank == bankAndAddress2.bank, "Scopes can't cross banks")
    let effectiveBank: Cartridge.Bank = self.effectiveBank(at: bankAndAddress.address, in: bankAndAddress.bank)
    contiguousScopes[effectiveBank, default: Set()].insert(range)
  }
}
