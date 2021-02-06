//
//  NotificationNames.swiftui
//
//  Created by Jeff Verkoeyen on 12/2/20.
//

import Foundation

extension Notification.Name {
  static let disassembled = Notification.Name("disassembled")
  static let selectedFileDidChange = Notification.Name("selectedFileDidChange")
  static let selectedRegionDidChange = Notification.Name("selectedRegionDidChange")
  static let jumpToLocation = Notification.Name("jumpToLocation")
  static let didCreateRegion = Notification.Name("didCreateRegion")
}
