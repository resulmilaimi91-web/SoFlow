import Foundation

public struct MPStateData: Equatable {
    public var speed: Int = 0
    public var factoryCode: Int = 0
    public var lampStatus: Bool = false
    public var speedMode: Int = 0
    public var unit: Bool = false
    public var modifyMode: Int = 0
    public var lockStatus: Bool = false
    public var batteryVoltage: Int = 0
    public var batteryCurrent: Int = 0
    public var remainingCharge: Int = 0
    public var distanceSingle: Int = 0
    public var distanceAll: Int = 0
    public var communicationLeft: Int = 0
    public var communicationRight: Int = 0
    public var displayLeft: Int = 0
    public var displayRight: Int = 0
    public var cpuLeft: Int = 0
    public var cpuRight: Int = 0
    public var faultBrake: Bool = false
    public var faultController: Bool = false
    public var faultMotor: Bool = false
    public var faultCommunication: Bool = false
    public var stealingAlert: Bool = false
    public var transferFault: Bool = false
    public var systemStatus: Bool = false
    public var singleRideTime: Int = 0
    public var darkMode: Int = 0
    public var faults: [Bool] = []

    public var batteryPercent: Double {
        guard batteryVoltage > 0 else { return 0 }
        let minV = 36.0
        let maxV = 50.4
        let v = Double(batteryVoltage) / 100.0
        return min(100, max(0, ((v - minV) / (maxV - minV)) * 100))
    }

    public var speedKmh: Int { speed }
    public var speedMph: Int { Int(Double(speed) * 0.621371) }

    public init() {}
}

public struct MPSwitchData {
    public let command: Int
    public let operand: Int
    public let success: Bool

    public init(command: Int, operand: Int, success: Bool) {
        self.command = command
        self.operand = operand
        self.success = success
    }
}
