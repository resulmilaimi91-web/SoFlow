import Foundation

public enum BleDataOperateManage {
    public static let SPEED_MAX               = "D707A9"
    public static let LOCK_MODE               = "D706A0"
    public static let BRIGHTNESS_SETTING      = "D706A1"
    public static let LAMP_SETTING            = "D706A2"
    public static let SPEED_MODE              = "D706A3"
    public static let CRUISE_SETTING          = "D706A4"
    public static let BOOST_SETTING           = "D706A5"
    public static let CONNECTION_STATUS_LIGHT = "D706A6"
    public static let UNIT                    = "D706A7"
    public static let TURNING_LIGHTS          = "D706A8"
    public static let QUERY                   = "D706D9"
    public static let RESET                   = "D706D7"
    public static let SAVED_TREES             = "D706D8"
    public static let DARK_MODE               = "D706D6"
    public static let BATTERY_LOCK_SETTING    = "D706D5"
    public static let FLOWMILES               = "D706B5"
    public static let ECO                     = "D706F1"
    public static let OTA                     = "D707F1"
    public static let OTAPACKAGE_SIZE         = "D707F2"

    private static func encrypt32(_ parserHex: String) -> Data {
        do {
            let cipherHex = try AESKeyDerivation.encryptParser(parserHex, padLength: 32)
            return HexParser.hexToBytes(cipherHex)
        } catch { return Data() }
    }

    private static func encrypt64(_ parserHex: String) -> Data {
        do {
            let cipherHex = try AESKeyDerivation.encryptParser(parserHex, padLength: 64)
            return HexParser.hexToBytes(cipherHex)
        } catch { return Data() }
    }

    public static func setSpeedMax(_ kmh: Int) -> Data {
        let frame = MPOperations.speedMax(header: SPEED_MAX, speed: kmh)
        return HexParser.hexToBytes(frame)
    }

    public static func batteryLockSetting(success: Bool) -> Data { encrypt32(MPOperations.switchOnOff(header: BATTERY_LOCK_SETTING, on: success)) }
    public static func boostSetting(on: Bool) -> Data            { encrypt32(MPOperations.switchOnOff(header: BOOST_SETTING, on: on)) }
    public static func cruiseSetting(on: Bool) -> Data           { encrypt32(MPOperations.switchOnOff(header: CRUISE_SETTING, on: on)) }
    public static func darkMode(on: Bool) -> Data                { encrypt32(MPOperations.switchOnOff(header: DARK_MODE, on: on)) }
    public static func eco(level: Int) -> Data                   { encrypt32(MPOperations.speedSetting(header: ECO, mode: level)) }
    public static func flowMiles(metric: Bool) -> Data           { encrypt32(MPOperations.switchFlowMiles(header: FLOWMILES, metric: metric)) }
    public static func unit(metric: Bool) -> Data                { encrypt32(MPOperations.switchOnOff(header: UNIT, on: metric)) }
    public static func turningLights(on: Bool) -> Data           { encrypt32(MPOperations.switchOnOff(header: TURNING_LIGHTS, on: on)) }
    public static func connectionLight(on: Bool) -> Data         { encrypt32(MPOperations.switchOnOff(header: CONNECTION_STATUS_LIGHT, on: on)) }
    public static func brightness(level: Int) -> Data            { encrypt32(MPOperations.speedSetting(header: BRIGHTNESS_SETTING, mode: level)) }
    public static func lampSetting(on: Bool) -> Data             { encrypt32(MPOperations.switchOnOff(header: LAMP_SETTING, on: on)) }
    public static func speedMode(level: Int) -> Data             { encrypt32(MPOperations.speedSetting(header: SPEED_MODE, mode: level)) }
    public static func lockMode(on: Bool) -> Data                { encrypt32(MPOperations.switchOnOff(header: LOCK_MODE, on: on)) }
    public static func query() -> Data                           { encrypt32(MPOperations.switchOnOff(header: QUERY, on: false)) }
    public static func reset() -> Data                           { encrypt32(MPOperations.switchOnOff(header: RESET, on: true)) }
    public static func savedTrees(on: Bool) -> Data              { encrypt32(MPOperations.switchOnOff(header: SAVED_TREES, on: on)) }

    public static func changeBleName(_ name: String) -> Data {
        let utf8Hex = name.utf8.map { String(format: "%02X", $0) }.joined()
        return encrypt64(utf8Hex)
    }
}
