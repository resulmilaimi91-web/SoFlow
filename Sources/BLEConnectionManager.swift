import Foundation
import CoreBluetooth
import Combine

@MainActor
public final class BLEConnectionManager: NSObject, ObservableObject {
    @Published public private(set) var state: CBManagerState = .unknown
    @Published public private(set) var discovered: [ScannedScooter] = []
    @Published public private(set) var connectedPeripheral: CBPeripheral?
    @Published public private(set) var connectionState: ConnectionState = .disconnected
    @Published public private(set) var lastNotify: Data?
    @Published public private(set) var lastState: MPStateData?
    @Published public private(set) var rssi: Int = 0

    public var factory: ScooterFactory = .walkiz
    public var deviceAESKey: Data = AESKeyDerivation.masterKey
    public var onDisconnect: ((Error?) -> Void)?
    public var onStateUpdate: ((MPStateData) -> Void)?

    private var central: CBCentralManager!
    private var writeChar: CBCharacteristic?
    private var notifyChar: CBCharacteristic?
    private var connectedPeripheralName: String?

    private var reconnectTimer: Timer?
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 10
    private let reconnectDelay: TimeInterval = 2.0

    private var rssiPollingTimer: Timer?
    private var keepAliveTimer: Timer?
    private let keepAliveInterval: TimeInterval = 10.0

    private var connectTimeoutTimer: Timer?
    private let connectTimeout: TimeInterval = 10.0

    private let minRSSI: Int = -85
    private let scannerNameFilter = "HIBOY"

    var lastKnownPeripheralUUID: UUID? {
        get { UserDefaults.standard.object(forKey: "last_known_peripheral") as? UUID }
        set { UserDefaults.standard.set(newValue?.uuidString, forKey: "last_known_peripheral") }
    }

    private var lastKnownFactoryRaw: Int {
        get { UserDefaults.standard.integer(forKey: "last_known_factory") }
        set { UserDefaults.standard.set(newValue, forKey: "last_known_factory") }
    }

    public override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: .main)
    }

    public func startScan(minRSSI: Int? = nil) {
        guard central.state == .poweredOn else { return }
        discovered.removeAll()
        let options: [String: Any] = [
            CBCentralManagerScanOptionAllowDuplicatesKey: false
        ]
        central.scanForPeripherals(withServices: nil, options: options)
    }

    public func stopScan() {
        central.stopScan()
    }

    public func connect(to scooter: ScannedScooter) {
        guard central.state == .poweredOn else { return }
        factory = scooter.factory
        reconnectAttempts = 0
        connectionState = .connecting
        scooter.peripheral.delegate = self
        central.connect(scooter.peripheral, options: [
            CBConnectPeripheralOptionNotifyOnDisconnectionKey: true
        ])
        startConnectTimeout()
    }

    public func connectToLast() {
        guard let uuid = lastKnownPeripheralUUID,
              let factory = ScooterFactory(rawValue: lastKnownFactoryRaw) else { return }
        self.factory = factory
        let peripherals = central.retrievePeripherals(withIdentifiers: [uuid])
        if let peripheral = peripherals.first {
            peripheral.delegate = self
            connectionState = .connecting
            central.connect(peripheral, options: [
                CBConnectPeripheralOptionNotifyOnDisconnectionKey: true
            ])
            startConnectTimeout()
        }
    }

    public func disconnect() {
        stopTimers()
        reconnectAttempts = maxReconnectAttempts
        if let p = connectedPeripheral {
            central.cancelPeripheralConnection(p)
        }
        connectionState = .disconnected
        connectedPeripheral = nil
        writeChar = nil
        notifyChar = nil
        lastState = nil
    }

    public func forgetDevice() {
        disconnect()
        lastKnownPeripheralUUID = nil
        lastKnownFactoryRaw = 0
    }

    public func sendCommand(_ data: Data) {
        guard let writeChar, let connectedPeripheral else { return }
        connectedPeripheral.writeValue(data, for: writeChar, type: .withoutResponse)
    }

    public func sendEncrypted(frameHex: String, padLength: Int = 32) throws {
        guard let writeChar, let connectedPeripheral else {
            throw BLEError.notConnected
        }
        let cipherHex = try AESKeyDerivation.encryptParser(frameHex, padLength: padLength)
        let cipher = HexParser.hexToBytes(cipherHex)
        connectedPeripheral.writeValue(cipher, for: writeChar, type: .withoutResponse)
    }

    private func startConnectTimeout() {
        connectTimeoutTimer?.invalidate()
        connectTimeoutTimer = Timer.scheduledTimer(withTimeInterval: connectTimeout, repeats: false) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, self.connectionState == .connecting else { return }
                self.disconnect()
                self.connectionState = .timeout
                self.startReconnect()
            }
        }
    }

    private func startReconnect() {
        guard reconnectAttempts < maxReconnectAttempts else {
            connectionState = .failed
            return
        }
        reconnectAttempts += 1
        connectionState = .reconnecting(reconnectAttempts, maxReconnectAttempts)
        reconnectTimer?.invalidate()
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: reconnectDelay, forMode: .common) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, let uuid = self.lastKnownPeripheralUUID else { return }
                let peripherals = self.central.retrievePeripherals(withIdentifiers: [uuid])
                if let p = peripherals.first {
                    p.delegate = self
                    self.connectionState = .connecting
                    self.central.connect(p, options: [
                        CBConnectPeripheralOptionNotifyOnDisconnectionKey: true
                    ])
                    self.startConnectTimeout()
                }
            }
        }
        reconnectTimer?.fire()
    }

    private func stopTimers() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        rssiPollingTimer?.invalidate()
        rssiPollingTimer = nil
        keepAliveTimer?.invalidate()
        keepAliveTimer = nil
        connectTimeoutTimer?.invalidate()
        connectTimeoutTimer = nil
    }

    private func startKeepAlive() {
        keepAliveTimer?.invalidate()
        keepAliveTimer = Timer.scheduledTimer(withTimeInterval: keepAliveInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.sendKeepAlive()
            }
        }
    }

    private func sendKeepAlive() {
        guard connectionState == .connected else { return }
        let data = BleDataOperateManage.query()
        sendCommand(data)
    }

    private func startRSSIPolling() {
        rssiPollingTimer?.invalidate()
        rssiPollingTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.connectedPeripheral?.readRSSI()
            }
        }
    }
}

extension BLEConnectionManager: CBCentralManagerDelegate {
    nonisolated public func centralManagerDidUpdateState(_ c: CBCentralManager) {
        Task { @MainActor in
            self.state = c.state
            if c.state == .poweredOn {
                self.connectToLast()
            }
        }
    }

    nonisolated public func centralManager(_ c: CBCentralManager,
                                           didDiscover peripheral: CBPeripheral,
                                           advertisementData: [String: Any],
                                           rssi RSSI: NSNumber) {
        let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String
                   ?? peripheral.name ?? ""
        let rssiValue = RSSI.intValue

        guard rssiValue >= minRSSI else { return }
        guard name.hasPrefix(scannerNameFilter) || name.contains("SO") || name.contains("SCOOTER") else {
            if rssiValue >= -60 {
                Task { @MainActor in self.discovered.append(ScannedScooter(peripheral: peripheral, name: name, rssi: rssiValue, factory: self.factory)) }
            }
            return
        }

        let detectedFactory: ScooterFactory
        if let manuData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data {
            let hex = manuData.map { String(format: "%02X", $0) }.joined()
            if hex.hasPrefix("4B") { detectedFactory = .kingMeter }
            else if hex.hasPrefix("6E") { detectedFactory = .nordic }
            else { detectedFactory = .walkiz }
        } else {
            detectedFactory = .walkiz
        }

        Task { @MainActor in
            let scooter = ScannedScooter(
                peripheral: peripheral,
                name: name,
                rssi: rssiValue,
                factory: detectedFactory
            )
            if let idx = self.discovered.firstIndex(where: { $0.id == peripheral.identifier }) {
                self.discovered[idx] = scooter
            } else {
                self.discovered.append(scooter)
            }
            self.discovered.sort { $0.rssi > $1.rssi }
        }
    }

    nonisolated public func centralManager(_ c: CBCentralManager, didConnect peripheral: CBPeripheral) {
        Task { @MainActor in
            self.connectTimeoutTimer?.invalidate()
            self.connectedPeripheral = peripheral
            self.connectedPeripheralName = peripheral.name
            self.lastKnownPeripheralUUID = peripheral.identifier
            self.lastKnownFactoryRaw = self.factory.rawValue
            self.connectionState = .discovering
            peripheral.discoverServices([self.factory.serviceUUID, BLEUUIDs.shieldService])
        }
    }

    nonisolated public func centralManager(_ c: CBCentralManager,
                                           didFailToConnect peripheral: CBPeripheral,
                                           error: Error?) {
        Task { @MainActor in
            self.connectTimeoutTimer?.invalidate()
            self.connectionState = .failed
            self.startReconnect()
        }
    }

    nonisolated public func centralManager(_ c: CBCentralManager,
                                           didDisconnectPeripheral peripheral: CBPeripheral,
                                           error: Error?) {
        Task { @MainActor in
            self.stopTimers()
            self.writeChar = nil
            self.notifyChar = nil
            self.rssi = 0
            if self.connectedPeripheral?.identifier == peripheral.identifier {
                self.connectedPeripheral = nil
            }
            self.connectionState = .disconnected
            self.onDisconnect?(error)
            if self.reconnectAttempts < self.maxReconnectAttempts {
                self.startReconnect()
            }
        }
    }
}

extension BLEConnectionManager: CBPeripheralDelegate {
    nonisolated public func peripheral(_ p: CBPeripheral, didDiscoverServices error: Error?) {
        Task { @MainActor in
            guard error == nil else {
                self.connectionState = .failed
                return
            }
            for svc in p.services ?? [] {
                if svc.uuid == self.factory.serviceUUID {
                    p.discoverCharacteristics(
                        [self.factory.writeCharUUID, self.factory.notifyCharUUID],
                        for: svc
                    )
                }
            }
        }
    }

    nonisolated public func peripheral(_ p: CBPeripheral,
                                       didDiscoverCharacteristicsFor service: CBService,
                                       error: Error?) {
        Task { @MainActor in
            guard error == nil else {
                self.connectionState = .failed
                return
            }
            for ch in service.characteristics ?? [] {
                if ch.uuid == self.factory.writeCharUUID {
                    self.writeChar = ch
                }
                if ch.uuid == self.factory.notifyCharUUID {
                    self.notifyChar = ch
                    p.setNotifyValue(true, for: ch)
                }
            }
            if self.writeChar != nil && self.notifyChar != nil {
                self.connectionState = .connected
                self.startKeepAlive()
                self.startRSSIPolling()
                self.sendKeepAlive()
            }
        }
    }

    nonisolated public func peripheral(_ p: CBPeripheral,
                                       didUpdateValueFor characteristic: CBCharacteristic,
                                       error: Error?) {
        let raw = characteristic.value ?? Data()
        let uuid = characteristic.uuid
        Task { @MainActor in
            guard uuid == self.factory.notifyCharUUID else { return }
            self.lastNotify = raw
            let item = BeaconItem(type: 0, len: raw.count, bytes: raw)
            if let st = MPStateParser.parse(item) {
                self.lastState = st
                self.onStateUpdate?(st)
                return
            }
            _ = MPSwitchParser.parse(item)
        }
    }

    nonisolated public func peripheral(_ p: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        Task { @MainActor in
            self.rssi = RSSI.intValue
        }
    }
}

public struct ScannedScooter: Identifiable, Equatable {
    public let peripheral: CBPeripheral
    public let name: String
    public let rssi: Int
    public let factory: ScooterFactory

    public var id: UUID { peripheral.identifier }

    public static func == (lhs: ScannedScooter, rhs: ScannedScooter) -> Bool {
        lhs.id == rhs.id
    }
}

public enum ConnectionState: Equatable {
    case disconnected
    case scanning
    case connecting
    case discovering
    case connected
    case reconnecting(Int, Int)
    case timeout
    case failed

    public var label: String {
        switch self {
        case .disconnected: return "Disconnected"
        case .scanning: return "Scanning"
        case .connecting: return "Connecting"
        case .discovering: return "Discovering Services"
        case .connected: return "Connected"
        case .reconnecting(let n, let max): return "Reconnecting (\(n)/\(max))"
        case .timeout: return "Connection Timeout"
        case .failed: return "Connection Failed"
        }
    }

    public var isConnected: Bool { self == .connected }
}

public enum BLEError: LocalizedError {
    case notConnected
    case bluetoothOff
    case connectionTimeout
    case serviceNotFound
    case characteristicNotFound

    public var errorDescription: String? {
        switch self {
        case .notConnected: return "Scooter not connected"
        case .bluetoothOff: return "Bluetooth is turned off"
        case .connectionTimeout: return "Connection timed out"
        case .serviceNotFound: return "BLE service not found on scooter"
        case .characteristicNotFound: return "Characteristic not found on scooter"
        }
    }
}
