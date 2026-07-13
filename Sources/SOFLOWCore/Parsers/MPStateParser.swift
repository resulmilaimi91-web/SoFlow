import Foundation

public enum MPStateParser {
    public static func parse(_ item: BeaconItem) -> MPStateData? {
        guard item.len >= 20 else { return nil }
        let p = BeaconParser(item)

        let lengthEcho = p.readByte()
        let factoryCode = p.readByte()
        let status = p.readByte()
        let statusByte = status & 0xFF

        let lampStatus = p.getBit(status, 0)
        let speedMode = p.getBits(statusByte, 1, 3)
        let unit = p.getBit(status, 4)
        let modifyMode = p.getBits(statusByte, 5, 6)
        let lockStatus = p.getBit(status, 7)

        let sb1 = p.readByte()
        let sb2 = p.readByte()
        let speed = p.readShort(sb1, sb2)

        let bv1 = p.readByte(); let bv2 = p.readByte()
        let bc1 = p.readByte(); let bc2 = p.readByte()
        let batteryVoltage = p.readShort(bv1, bv2)
        let batteryCurrent = p.readShort(bc1, bc2)

        let faultByte1 = p.readByte()

        let faultByte2: Int
        let faultByte3: Int
        let faultByte4: Int
        if item.len == 25 {
            faultByte2 = 0; faultByte3 = 0; faultByte4 = 0
        } else {
            faultByte2 = p.readByte()
            faultByte3 = p.readByte()
            faultByte4 = p.readByte()
        }

        let comm = p.readByte() & 0xFF
        let communicationRight = p.getBits(comm, 0, 4)
        let communicationLeft  = p.getBits(comm, 4, 8)

        let display = p.readByte() & 0xFF
        let displayRight = p.getBits(display, 0, 4)
        let displayLeft  = p.getBits(display, 4, 8)

        let cpu = p.readByte() & 0xFF
        let cpuRight = p.getBits(cpu, 0, 4)
        let cpuLeft  = p.getBits(cpu, 4, 8)

        let ds1 = p.readByte(); let ds2 = p.readByte()
        let da1 = p.readByte(); let da2 = p.readByte()
        let distanceSingle = p.readShort(ds1, ds2)
        let distanceAll    = p.readShort(da1, da2)

        let faultBrake         = p.getBit(faultByte1, 0)
        let faultController    = p.getBit(faultByte1, 1)
        let faultMotor         = p.getBit(faultByte1, 2)
        let faultCommunication = p.getBit(faultByte1, 3)
        let stealingAlert      = p.getBit(faultByte1, 4)
        let transferFault      = p.getBit(faultByte1, 5)
        let systemStatus       = p.getBit(faultByte1, 6)

        var faults = [Bool](repeating: false, count: 24)
        for i in 0..<8 { faults[i]      = p.getBit(faultByte2, i) }
        for i in 0..<8 { faults[8 + i]  = p.getBit(faultByte3, i) }
        for i in 0..<8 { faults[16 + i] = p.getBit(faultByte4, i) }

        let remainingCharge = p.readByte()

        let timerOffset = item.len == 25 ? 18 : 21
        let singleRideTime = item.len > timerOffset + 2
            ? p.getInt3(item.bytes, at: timerOffset) : 0

        let darkMode = p.readByte()
        let checksumByte = p.readByte()

        let computed =
            item.len + lengthEcho + factoryCode + sb1 + sb2 +
            bv1 + bv2 + bc1 + bc2 + faultByte1 +
            faultByte2 + faultByte3 + faultByte4 +
            status + comm + display + cpu +
            ds1 + ds2 + da1 + da2 +
            remainingCharge + darkMode
        let computedLast = computed & 0xFF

        guard computedLast == checksumByte else { return nil }

        var s = MPStateData()
        s.speed              = speed
        s.factoryCode        = factoryCode
        s.lampStatus         = lampStatus
        s.speedMode          = speedMode
        s.unit               = unit
        s.modifyMode         = modifyMode
        s.lockStatus         = lockStatus
        s.batteryVoltage     = batteryVoltage
        s.batteryCurrent     = batteryCurrent
        s.remainingCharge    = remainingCharge
        s.distanceSingle     = distanceSingle
        s.distanceAll        = distanceAll
        s.communicationLeft  = communicationLeft
        s.communicationRight = communicationRight
        s.displayLeft        = displayLeft
        s.displayRight       = displayRight
        s.cpuLeft            = cpuLeft
        s.cpuRight           = cpuRight
        s.faultBrake         = faultBrake
        s.faultController    = faultController
        s.faultMotor         = faultMotor
        s.faultCommunication = faultCommunication
        s.stealingAlert      = stealingAlert
        s.transferFault      = transferFault
        s.systemStatus       = systemStatus
        s.singleRideTime     = singleRideTime
        s.darkMode           = darkMode
        s.faults             = faults
        return s
    }
}

public enum MPSwitchParser {
    public static var lastWasSuccess = false

    public static func parse(_ item: BeaconItem) -> MPSwitchData? {
        let p = BeaconParser(item)
        let len = item.len
        let cmd = p.readByte()
        let result: Int
        if cmd == 170 {
            _ = p.readByte()
            _ = p.readByte()
            result = p.readByte()
        } else {
            result = p.readByte()
        }
        _ = p.readByte()
        let checksumByte = p.readByte()
        guard (item.len + cmd + result + 0) & 0xFF == checksumByte else { return nil }
        lastWasSuccess = (result == 0)
        return MPSwitchData(command: cmd, operand: 0, success: result == 0)
    }
}
