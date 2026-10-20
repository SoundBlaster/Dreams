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
var rows: [[String: Any]] = []
var count = 0
func attribute(_ node: AXUIElement, _ name: String) -> CFTypeRef? {
    var value: CFTypeRef?
    guard AXUIElementCopyAttributeValue(node, name as CFString, &value) == .success else { return nil }
    return value
}
func walk(_ node: AXUIElement, depth: Int) {
    guard depth < 35, count < 3000 else { return }
    count += 1
    let id = attribute(node, "AXIdentifier") as? String ?? ""
    let role = attribute(node, "AXRole") as? String ?? ""
    if CommandLine.arguments.contains("--all") || id.hasPrefix("dreams.") || role == "AXSlider" {
        var row: [String: Any] = ["id": id, "role": role]
        for key in ["AXRoleDescription", "AXSubrole", "AXTitle", "AXDescription", "AXHelp", "AXValue", "AXValueDescription", "AXEnabled"] {
            if let value = attribute(node, key) {
                row[key] = (value as? String).map { $0 as Any } ?? (value as? NSNumber).map { $0 as Any } ?? String(describing: value)
            }
        }
        var actions: CFArray?
        if AXUIElementCopyActionNames(node, &actions) == .success { row["actions"] = actions as? [String] ?? [] }
        rows.append(row)
    }
    for child in attribute(node, "AXChildren") as? [AXUIElement] ?? [] { walk(child, depth: depth + 1) }
}
walk(app, depth: 0)
print(String(decoding: try JSONSerialization.data(withJSONObject: ["pid": pid, "visited": count, "controls": rows],
                                               options: [.prettyPrinted, .sortedKeys]), as: UTF8.self))
