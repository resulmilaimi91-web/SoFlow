import Foundation
import CoreBluetooth

public enum ScooterFactory: Int, CaseIterable, Codable {
    case kingMeter = 0
    case nordic    = 1
    case walkiz    = 2

    public var serviceUUID: CBUUID {
        switch self {
        case .kingMeter: return CBUUID(string: "43480001-F001-4B49-4E47-204D45544552")
        case .nordic:    return CBUUID(string: "6e400001-b5a3-f393-e0a9-e50e24dcca9e")
        case .walkiz:    return CBUUID(string: "00008000-0000-1000-8000-57616C6B697A")
        }
    }

    public var writeCharUUID: CBUUID {
        switch self {
        case .kingMeter: return CBUUID(string: "43480002-F001-4B49-4E47-204D45544552")
        case .nordic:    return CBUUID(string: "6e400002-b5a3-f393-e0a9-e50e24dcca9e")
        case .walkiz:    return CBUUID(string: "00008001-0000-1000-8000-57616C6B697A")
        }
    }

    public var notifyCharUUID: CBUUID {
        switch self {
        case .kingMeter: return CBUUID(string: "43480003-F001-4B49-4E47-204D45544552")
        case .nordic:    return CBUUID(string: "6e400003-b5a3-f393-e0a9-e50e24dcca9e")
        case .walkiz:    return CBUUID(string: "00008002-0000-1000-8000-57616C6B697A")
        }
    }
}

public enum BLEUUIDs {
    public static let cccd = CBUUID(string: "00002902-0000-1000-8000-00805f9b34fb")
    public static let shieldService = CBUUID(string: "00010203-0405-0607-0809-0a0b0c0d1910")
    public static let shieldTx      = CBUUID(string: "00010203-0405-0607-0809-0a0b0c0d1913")
    public static let fotaService   = CBUUID(string: "2600")
    public static let fotaCtrlChar  = CBUUID(string: "7000")
    public static let fotaDataChar  = CBUUID(string: "7001")
    public static let nameFilterPrefix = "HIBOY"
}

public enum FOTAControlOp: UInt8 {
    case signature        = 0
    case digest           = 1
    case startRequest     = 2
    case startResponse    = 3
    case newSector        = 4
    case integrityCheckRequest  = 5
    case integrityCheckResponse = 6
}

public enum SOFLOWNet {
    public static let baseURL = URL(string: "http://47.52.238.166:8080/")!
    public static let networkAESKey = "cnplgolf"
}
