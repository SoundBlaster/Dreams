import AppKit
import ApplicationServices
import Foundation

guard AXIsProcessTrusted() else { print("AX_NOT_TRUSTED"); exit(2) }
guard CommandLine.arguments.count > 1, let pid = Int32(CommandLine.arguments[1]) else {
    let apps = NSWorkspace.shared.runningApplications.filter {
        ($0.bundleIdentifier?.contains("qa") ?? false) && ($0.localizedName?.contains("Dreams") ?? false)
    }.map { ["pid": String($0.processIdentifier), "name": $0.localizedName ?? "", "bundle": $0.bundleIdentifier ?? ""] }
    print(String(decoding: try JSONSerialization.data(withJSONObject: apps, options: [.prettyPrinted, .sortedKeys]), as: UTF8.self))
    exit(0)
}
let app = AXUIElementCreateApplication(pid)
func attr(_ e: AXUIElement, _ key: String) -> CFTypeRef? {
 var v: CFTypeRef?; return AXUIElementCopyAttributeValue(e,key as CFString,&v) == .success ? v : nil
}
func find(_ e: AXUIElement, _ depth: Int = 0) -> AXUIElement? {
 if attr(e,"AXIdentifier") as? String == "dreams.rain-speed" { return e }
 guard depth < 35 else { return nil }
 for c in attr(e,"AXChildren") as? [AXUIElement] ?? [] { if let r = find(c,depth+1) { return r } }
 return nil
}
guard let slider = find(app), let initial = attr(slider,"AXValue") as? NSNumber else { exit(3) }
func state(_ phase: String) { print("\(phase): value=\(String(describing: attr(slider,"AXValue"))) readout=\(String(describing: attr(slider,"AXValueDescription")))") }
state("before")
let inc = AXUIElementPerformAction(slider,"AXIncrement" as CFString)
Thread.sleep(forTimeInterval:0.25); state("increment")
let dec = AXUIElementPerformAction(slider,"AXDecrement" as CFString)
Thread.sleep(forTimeInterval:0.25); state("decrement")
if attr(slider,"AXValue") as? NSNumber != initial {
 _ = AXUIElementSetAttributeValue(slider,"AXValue" as CFString,initial)
 Thread.sleep(forTimeInterval:0.25)
}
state("restored")
guard inc == .success, dec == .success, attr(slider,"AXValue") as? NSNumber == initial else { exit(4) }
