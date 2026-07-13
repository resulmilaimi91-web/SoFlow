import Foundation

public enum HexParser {
    public static func hex16to10Byte1(_ s: String, at i: Int) -> String? {
        guard i + 2 <= s.count else { return nil }
        return Int(substring(s, i, i+2), radix: 16).map(String.init)
    }

    public static func hex16to10Byte2(_ s: String, at i: Int) -> String? {
        guard i + 4 <= s.count else { return nil }
        return Int(substring(s, i, i+4), radix: 16).map(String.init)
    }

    public static func checksum(_ frame: String, beginByte: Int, byteCount: Int) -> String {
        var sum: UInt = 0
        let chars = Array(frame)
        let from = beginByte * 2
        let to   = (beginByte + byteCount) * 2
        guard to <= chars.count else { return "00" }
        var i = from
        while i < to {
            if let b = UInt(String(chars[i..<min(i+2, to)]), radix: 16) {
                sum &+= b
            }
            i += 2
        }
        return String(format: "%02X", sum & 0xFF)
    }

    public static func toCheck(_ frameWithoutChecksum: String) -> String {
        var sum: UInt = 0
        var idx = frameWithoutChecksum.startIndex
        while idx < frameWithoutChecksum.endIndex {
            let next = frameWithoutChecksum.index(idx, offsetBy: 2, limitedBy: frameWithoutChecksum.endIndex) ?? frameWithoutChecksum.endIndex
            if let b = UInt(frameWithoutChecksum[idx..<next], radix: 16) {
                sum &+= b
            }
            idx = next
        }
        return String(format: "%02X", sum & 0xFF)
    }

    public static func addZeroForNumLeft(_ hex: String, _ length: Int) -> String {
        if hex.count >= length { return hex }
        return String(repeating: "0", count: length - hex.count) + hex
    }

    public static func bytesToHexString(_ data: Data) -> String {
        data.map { String(format: "%02X", $0) }.joined()
    }

    public static func hexToBytes(_ hex: String) -> Data {
        var s = hex
        if s.count % 2 == 1 { s = "0" + s }
        var out = Data(capacity: s.count / 2)
        var idx = s.startIndex
        while idx < s.endIndex {
            let next = s.index(idx, offsetBy: 2)
            if let b = UInt8(s[idx..<next], radix: 16) {
                out.append(b)
            }
            idx = next
        }
        return out
    }

    private static func substring(_ s: String, _ from: Int, _ to: Int) -> String {
        let lo = s.index(s.startIndex, offsetBy: from)
        let hi = s.index(s.startIndex, offsetBy: to)
        return String(s[lo..<hi])
    }
}
