import Foundation

class ProjectConfiguration: NSObject, Codable {
  @objc dynamic var regions: [Region] = []
  @objc dynamic var dataTypes: [DataType] = []
  @objc dynamic var globals: [Global] = []
  @objc dynamic var macros: [Macro] = []
  @objc dynamic var scripts: [Script] = []

  override init() {
    super.init()
  }

  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: Self.CodingKeys)
    regions = (try? container.decode(Array<Region>.self, forKey: .regions)) ?? []
  }
}
