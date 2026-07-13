import Foundation

public enum MPOperations {
    public static func speedMax(header: String, speed: Int) -> String {
        let payload = HexParser.addZeroForNumLeft(String(speed, radix: 16, uppercase: true), 4)
        let body = header + "00" + payload
        return body + HexParser.checksum(body, beginByte: 1, byteCount: 5)
    }

    public static func speedSetting(header: String, mode: Int) -> String {
        let body = header + "00" + "0" + String(mode)
        return body + HexParser.checksum(body, beginByte: 1, byteCount: 4)
    }

    public static func switchOnOff(header: String, on: Bool) -> String {
        let body = header + "00" + (on ? "01" : "00")
        return body + HexParser.checksum(body, beginByte: 1, byteCount: 4)
    }

    public static func switchFlowMiles(header: String, metric: Bool) -> String {
        let body = header + "00" + "0" + String(metric ? 0 : 1)
        return body + HexParser.checksum(body, beginByte: 1, byteCount: 4)
    }
}
