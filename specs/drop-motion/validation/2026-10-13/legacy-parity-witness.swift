import Foundation
@main enum Witness {
 static func main() {
  var hash: UInt64 = 14695981039346656037
  func add(_ n: UInt64) { hash = (hash ^ n) &* 1099511628211 }
  for density in [0.0, 0.5, 1.0] {
   var rain = MatrixSimulation(columnCount: 12, rows: 72, glyphCount: 57, density: density)
   add(rain.trigger(column: 0, at: 0).bitPattern)
   for frame in 0...300 {
    rain.advance(to: Double(frame) / 30)
    for column in rain.columns {
     add(column.nextWrite.bitPattern); add(column.nextMutation.bitPattern)
     add(column.lastWrite.bitPattern); add(UInt64(bitPattern: Int64(column.headRow)))
     add(column.generator.state)
     for cell in column.cells {
      add(UInt64(bitPattern: Int64(cell.glyph))); add(cell.writtenAt.bitPattern)
      add(cell.changedAt.bitPattern); add(cell.settledAt.bitPattern); add(cell.flashedAt.bitPattern)
      add(cell.hold.bitPattern); add(cell.fade.bitPattern)
      add(UInt64(cell.ink.bitPattern)); add(UInt64(cell.warmth.bitPattern)); add(UInt64(cell.visibility.bitPattern))
      add(cell.isGap ? 1 : 0)
     }
    }
   }
  }
  print(String(hash, radix:16))
 }
}
