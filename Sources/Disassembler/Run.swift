import Foundation
import CPU

public protocol Run {
  associatedtype AddressT: BinaryInteger
  associatedtype InstructionT: Instruction

  var startAddress: AddressT { get }
  var visitedRange: Range<AddressT>? { get }

  var invocationInstruction: InstructionT? { get }

  /**
   Runs that were invoked within this run via a control transfer.
   */
  var children: [Self] { get }
}

public final class RunGroup<T: Run>: Sequence {
  init(runs: [T]) {
    self.runs = runs
  }

  fileprivate let runs: [T]

  public func makeIterator() -> IndexingIterator<[T]> {
    return runs.makeIterator()
  }

  public var first: T? {
    return runs.first
  }

  /**
   The run group's starting address.
   */
  public lazy var startAddress: T.AddressT? = {
    guard let firstRun = runs.first else {
      return nil
    }
    return firstRun.startAddress
  }()

  /**
   Returns all of the ranges visited by the runs in this group.

   - Note: Runs are not an ideal representation of the call graph because runs intentionally do not recurse on themselves.
   A more ideal representation for scope calculation would be a legitimiate call graph that annotates, for a given instruction, all
   of the reachable transfers of control. This graph could then reasonably be walked each time we want to calculate scope.
   */
  public lazy var scope: IndexSet = {
    return runs.compactMap { $0.visitedRange }.reduce(into: IndexSet()) { (accumulator, visitedRange) in
      accumulator.insert(integersIn: Int(visitedRange.lowerBound)..<Int(visitedRange.upperBound))
    }
  }()

  public lazy var firstContiguousScopeRange: Range<T.AddressT>? = {
    if let startAddress = startAddress {
      if let range = scope.rangeView.first(where: { $0.lowerBound == Int(startAddress) }) {
        return Range<T.AddressT>(uncheckedBounds: (T.AddressT(range.lowerBound),
                                                   T.AddressT(range.upperBound)))
      } else if let range = scope.rangeView.first(where: { $0.contains(Int(startAddress)) }) {
        return Range<T.AddressT>(uncheckedBounds: (startAddress, T.AddressT(range.upperBound)))
      }
    }
    return nil
  }()
}

extension Run {
  /**
   Breaks this run apart into call groups.

   - Returns: a collection of arrays of Runs, where each array of Runs is part of a single call invocation.
   */
  public func runGroups() -> [RunGroup<Self>] {
    var runGroups: [RunGroup<Self>] = []

    var sanityCheckSeenRuns = 0

    var runGroupQueue = [self]
    while !runGroupQueue.isEmpty {
      let run = runGroupQueue.removeFirst()
      var runGroup = [run]

      sanityCheckSeenRuns += 1

      var descendantQueue = run.children
      while !descendantQueue.isEmpty {
        let descendant = descendantQueue.removeFirst()
        if case .call = descendant.invocationInstruction?.spec.category {
          // Calls mark the start of a new run group.
          runGroupQueue.append(descendant)
        } else {
          // Everything else is part of the current group...
          runGroup.append(descendant)
          // ...including any of its descendants.
          descendantQueue.append(contentsOf: descendant.children)

          sanityCheckSeenRuns += 1
        }
      }

      runGroups.append(RunGroup<Self>(runs: runGroup))
    }

    assert(sanityCheckSeenRuns == (runGroups.reduce(0) { $0 + $1.runs.count }))

    return runGroups
  }
}
