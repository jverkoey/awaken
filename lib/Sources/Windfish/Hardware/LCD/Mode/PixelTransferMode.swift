import Foundation

extension PPU {
  private static let TilesPerRow: UInt16 = 32
  private static let PixelsPerTile: UInt16 = 8

  final class PixelTransferMode: PPUMode {
    init(registers: LCDRegisters, lineCycleDriver: LineCycleDriver) {
      self.registers = registers
      self.lineCycleDriver = lineCycleDriver
      self.fetcher = Fetcher(registers: registers)
    }

    private let registers: LCDRegisters
    private let lineCycleDriver: LineCycleDriver

    var intersectedOAMs: [OAM.Sprite] = []

    final class Fetcher {
      init(registers: LCDRegisters) {
        self.registers = registers
      }

      private let registers: LCDRegisters
      var tileMapAddress: LR35902.Address = 0
      var tileDataAddress: TileDataAddress = .x8000
      var tileMapAddressOffset: UInt16 = 0
      var tilePixelY: UInt16 = 0

      func start(tileMapAddress: TileMapAddress, tileDataAddress: TileDataAddress, x: UInt8, y: UInt8) {
        let wideX = UInt16(truncatingIfNeeded: x)
        let wideY = UInt16(truncatingIfNeeded: y)
        let tileY = wideY / PPU.PixelsPerTile

        self.tileMapAddress = tileMapAddress.address + tileY * PPU.TilesPerRow
        self.tileDataAddress = tileDataAddress
        self.tileMapAddressOffset = wideX / PPU.PixelsPerTile
        self.tilePixelY = wideY % PPU.PixelsPerTile
      }

      func advance() {
        // TODO: Figure out what level of timing is needed here. Likely needs tick-level granularity.
        let tileIndex = registers.tileMap[Int(truncatingIfNeeded: tileMapAddress + tileMapAddressOffset - PPU.tileMapRegion.lowerBound)]
      }
    }
    private let fetcher: Fetcher
    private var fifo: [Pixel] = []

    private struct Pixel {
      let color: UInt8
      let palette: UInt8
      let spritePriority: UInt8
      let bgPriority: UInt8
    }
    private var scanlineX: UInt8 = 0
    private var scanlineScrollX: UInt8 = 0
    private var windowYPlot: UInt8 = 0
    private var bgYPlot: UInt8 = 0
    private var lastBackgroundPixel: UInt8 = 0

    /** Starts the mode. */
    func start() {
      // Note that we don't reset lineCycleDriver.cycles here because we're continuing to cycle through this ly.

      // TODO: Check registers.backgroundEnable and registers.windowEnable
      precondition(registers.backgroundEnable)  // Disabled behavior not currently implemented.

      fetcher.start(tileMapAddress: registers.backgroundTileMapAddress,
                    tileDataAddress: registers.tileDataAddress,
                    x: registers.scx,
                    y: lineCycleDriver.scanline &+ registers.scy)

      windowYPlot = lineCycleDriver.scanline &- registers.windowY
      bgYPlot = lineCycleDriver.scanline &+ registers.scy
      scanlineX = 0
      scanlineScrollX = registers.scx
    }

    /** Executes a single machine cycle.  */
    func advance(memory: AddressableMemory) -> LCDCMode? {
      lineCycleDriver.cycles += 1

      var nextMode: LCDCMode? = nil

      if lineCycleDriver.cycles > PPU.searchingOAMLength + 1 && scanlineX < 160 {
        plot()
        scanlineX += 1
        plot()
        scanlineX += 1
        plot()
        scanlineX += 1
        plot()
        scanlineX += 1
      }

      if lineCycleDriver.cycles >= PPU.searchingOAMLength + 43 {
        precondition(scanlineX >= 160)
        nextMode = .hblank
        // Don't reset lcdModeCycle yet, as this mode can actually end early.

        registers.requestHBlankInterruptIfNeeded(memory: memory)
      }

      return nextMode
    }

    private func plot(x: UInt8, y: UInt8, byte: UInt8, palette: Palette) {
      let color = palette[Int(bitPattern: UInt(truncatingIfNeeded: byte))]
      registers.screenData[Int(bitPattern: UInt(truncatingIfNeeded: PPU.screenSize.width) * UInt(truncatingIfNeeded: y) + UInt(truncatingIfNeeded: x))] = color
    }

    private func plot() {
      if registers.windowEnable && (registers.windowX &- 7) <= scanlineX && registers.windowY <= lineCycleDriver.scanline {
        plot(x: scanlineX, y: lineCycleDriver.scanline,
             byte: backgroundPixel(x: scanlineX &- (registers.windowX &- 7), y: windowYPlot, window: true),
             palette: registers.backgroundPalette)
      } else if registers.backgroundEnable {
        plot(x: scanlineX, y: lineCycleDriver.scanline,
             byte: backgroundPixel(x: scanlineX &+ scanlineScrollX, y: bgYPlot, window: false),
             palette: registers.backgroundPalette)
      } else {
        lastBackgroundPixel = 0
      }

      if intersectedOAMs.isEmpty {
        return
      }

      for sprite in intersectedOAMs {
        guard sprite.x > scanlineX && sprite.x <= scanlineX + 8 else {
          continue
        }
        let wideScanlineX = Int16(truncatingIfNeeded: Int8(bitPattern: scanlineX))
        let wideScanlineY = Int16(truncatingIfNeeded: Int8(bitPattern: lineCycleDriver.scanline))
        let wideSpriteX = Int16(truncatingIfNeeded: Int8(bitPattern: sprite.x))
        let wideSpriteY = Int16(truncatingIfNeeded: Int8(bitPattern: sprite.y))
        let tileIndex: Int16
        var tileOffsetX = wideScanlineX + 8 - wideSpriteX
        var tileOffsetY = wideScanlineY + 16 - wideSpriteY

        switch registers.spriteSize {
        case .x8x16:
          let wideTile = Int16(truncatingIfNeeded: Int8(bitPattern: sprite.tile))
          if tileOffsetY > 7 && !sprite.yflip {
            tileOffsetY -= 8;
            tileIndex = wideTile | 0x01
          } else if tileOffsetY <= 7 && !sprite.yflip  {
            tileIndex = wideTile & 0xFE
          } else if tileOffsetY > 7 && sprite.yflip {
            tileOffsetY = 15 - tileOffsetY
            tileIndex = wideTile & 0xFE
          } else if tileOffsetY <= 7 && sprite.yflip {
            tileIndex = wideTile | 0x01
            tileOffsetY = 7 - tileOffsetY
          } else {
            tileIndex = 0
          }
        case .x8x8:
          tileIndex = Int16(truncatingIfNeeded: Int8(bitPattern: sprite.tile))
          if sprite.yflip {
            tileOffsetY = 7 - tileOffsetY
          }
        }
        if sprite.xflip {
          tileOffsetX = 7 - tileOffsetX
        }

        let tileData0: UInt8
        let tileData1: UInt8
        let tileDataIndex = Int(truncatingIfNeeded: (tileIndex &* 16) &+ tileOffsetY &* 2)
        tileData0 = registers.tileData[tileDataIndex]
        tileData1 = registers.tileData[tileDataIndex + 1]

        let lsb: UInt8 = (tileData0 & (0x80 >> tileOffsetX)) > 0 ? 0b01 : 0
        let msb: UInt8 = (tileData1 & (0x80 >> tileOffsetX)) > 0 ? 0b10 : 0
        let pixel = msb | lsb
        if pixel > 0 {
          let pixelBehindBg = sprite.priority && lastBackgroundPixel > 0
          if !pixelBehindBg {
            let palette: Palette
            switch sprite.palette {
            case .obj0pal:
              palette = registers.objectPallete0
            case .obj1pal:
              palette = registers.objectPallete1
            }
            plot(x: scanlineX, y: lineCycleDriver.scanline, byte: pixel, palette: palette)
          }
          break
        }
      }
    }

    private func backgroundPixel(x: UInt8, y: UInt8, window: Bool) -> UInt8 {
      let wideX = UInt16(truncatingIfNeeded: x)
      let wideY = UInt16(truncatingIfNeeded: y)
      let tileX = Int16(bitPattern: wideX / 8)
      let tileY = Int16(bitPattern: wideY / 8)
      let tileOffsetX = Int16(bitPattern: wideX % 8)
      let tileOffsetY = Int16(bitPattern: wideY % 8)

      let tileIndex: UInt8
      let tileMapIndex = Int(truncatingIfNeeded: tileX &+ tileY &* 32)
      switch window ? registers.windowTileMapAddress : registers.backgroundTileMapAddress {
      case .x9800:
        tileIndex = registers.tileMap[tileMapIndex]
      case .x9C00:
        tileIndex = registers.tileMap[0x400 + tileMapIndex]
      }

      let tileData0: UInt8
      let tileData1: UInt8
      switch registers.tileDataAddress {
      case .x8800:
        let signedTileIndex = Int8(bitPattern: tileIndex)
        let tileDataIndex = 0x1000 + Int(truncatingIfNeeded: (Int16(truncatingIfNeeded: signedTileIndex) &* 16) &+ tileOffsetY &* 2)
        tileData0 = registers.tileData[tileDataIndex]
        tileData1 = registers.tileData[tileDataIndex + 1]
      case .x8000:
        let tileDataIndex = Int(truncatingIfNeeded: Int16(bitPattern: UInt16(truncatingIfNeeded: tileIndex) &* 16) &+ tileOffsetY &* 2)
        tileData0 = registers.tileData[tileDataIndex]
        tileData1 = registers.tileData[tileDataIndex + 1]
      }

      let lsb: UInt8 = (tileData0 & (0x80 >> tileOffsetX)) > 0 ? 0b01 : 0
      let msb: UInt8 = (tileData1 & (0x80 >> tileOffsetX)) > 0 ? 0b10 : 0

      lastBackgroundPixel = msb | lsb
      return lastBackgroundPixel
    }
  }
}