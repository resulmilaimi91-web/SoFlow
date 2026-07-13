import SwiftUI

public struct SettingsView: View {
    @ObservedObject var manager: BLEConnectionManager
    @State private var speedLimit: Double = 25
    @State private var isLocked = false
    @State private var lightsOn = false
    @State private var cruiseControl = false
    @State private var boostMode = false
    @State private var ecoLevel: Double = 1
    @State private var speedMode = 1
    @State private var brightness: Double = 5
    @State private var darkMode = false
    @State private var useMetric = true
    @State private var connectionLight = false
    @State private var showRenameAlert = false
    @State private var newName = ""

    private let speedRange = 5...45

    public init(manager: BLEConnectionManager) {
        self.manager = manager
    }

    public var body: some View {
        NavigationStack {
            Form {
                connectionSection
                controlSection
                displaySection
                renameSection
                aboutSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Rename Scooter", isPresented: $showRenameAlert) {
                TextField("New name", text: $newName)
                Button("Cancel", role: .cancel) {}
                Button("Save") { renameScooter() }
            }
        }
    }

    private var connectionSection: some View {
        Section("Connection") {
            HStack {
                Label("Status", systemImage: "antenna.radiowaves.left.and.right")
                Spacer()
                Text(manager.connectionState.label)
                    .foregroundColor(.secondary)
            }
            HStack {
                Label("Signal", systemImage: "chart.bar")
                Spacer()
                Text("\(manager.rssi) dBm")
                    .foregroundColor(rssiColor)
            }
            Button("Disconnect", role: .destructive) {
                manager.disconnect()
                dismiss()
            }
        }
    }

    private var controlSection: some View {
        Section("Controls") {
            VStack {
                HStack {
                    Label("Speed Limit", systemImage: "speedometer")
                    Spacer()
                    Text("\(Int(speedLimit)) km/h")
                        .foregroundColor(.blue)
                }
                Slider(value: $speedLimit, in: 5...45, step: 1) {
                    Text("Speed")
                } onEditingChanged: { _ in
                    manager.sendCommand(BleDataOperateManage.setSpeedMax(Int(speedLimit)))
                }
            }

            Toggle(isOn: $isLocked) {
                Label("Lock Scooter", systemImage: "lock.fill")
            }
            .onChange(of: isLocked) { _, v in
                manager.sendCommand(BleDataOperateManage.lockMode(on: v))
            }

            Toggle(isOn: $lightsOn) {
                Label("Lights", systemImage: "lightbulb.fill")
            }
            .onChange(of: lightsOn) { _, v in
                manager.sendCommand(BleDataOperateManage.lampSetting(on: v))
            }

            Toggle(isOn: $cruiseControl) {
                Label("Cruise Control", systemImage: "arrow.trianglehead.merge.path")
            }
            .onChange(of: cruiseControl) { _, v in
                manager.sendCommand(BleDataOperateManage.cruiseSetting(on: v))
            }

            Toggle(isOn: $boostMode) {
                Label("Boost Mode", systemImage: "bolt.fill")
            }
            .onChange(of: boostMode) { _, v in
                manager.sendCommand(BleDataOperateManage.boostSetting(on: v))
            }

            Picker("Drive Mode", selection: $speedMode) {
                Text("Eco").tag(0)
                Text("Comfort").tag(1)
                Text("Sport").tag(2)
            }
            .onChange(of: speedMode) { _, v in
                manager.sendCommand(BleDataOperateManage.speedMode(level: v))
            }

            VStack {
                HStack {
                    Label("Eco Level", systemImage: "leaf.fill")
                    Spacer()
                    Text("\(Int(ecoLevel))")
                        .foregroundColor(.green)
                }
                Slider(value: $ecoLevel, in: 0...3, step: 1) {
                    Text("Eco")
                } onEditingChanged: { _ in
                    manager.sendCommand(BleDataOperateManage.eco(level: Int(ecoLevel)))
                }
            }
        }
    }

    private var displaySection: some View {
        Section("Display") {
            VStack {
                HStack {
                    Label("Brightness", systemImage: "sun.max.fill")
                    Spacer()
                    Text("\(Int(brightness))")
                        .foregroundColor(.orange)
                }
                Slider(value: $brightness, in: 0...10, step: 1) {
                    Text("Brightness")
                } onEditingChanged: { _ in
                    manager.sendCommand(BleDataOperateManage.brightness(level: Int(brightness)))
                }
            }

            Toggle(isOn: $darkMode) {
                Label("Dark Mode", systemImage: "moon.fill")
            }
            .onChange(of: darkMode) { _, v in
                manager.sendCommand(BleDataOperateManage.darkMode(on: v))
            }

            Toggle(isOn: $useMetric) {
                Label("Metric (km/h)", systemImage: "ruler")
            }
            .onChange(of: useMetric) { _, v in
                manager.sendCommand(BleDataOperateManage.unit(metric: v))
            }

            Toggle(isOn: $connectionLight) {
                Label("Status Light", systemImage: "circle.led")
            }
            .onChange(of: connectionLight) { _, v in
                manager.sendCommand(BleDataOperateManage.connectionLight(on: v))
            }
        }
    }

    private var renameSection: some View {
        Section("Scooter") {
            Button {
                showRenameAlert = true
            } label: {
                Label("Rename Scooter", systemImage: "pencil")
            }
            Button(role: .destructive) {
                manager.sendCommand(BleDataOperateManage.reset())
            } label: {
                Label("Factory Reset", systemImage: "arrow.counterclockwise")
            }
        }
    }

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Label("App Version", systemImage: "info.circle")
                Spacer()
                Text("1.0.0")
                    .foregroundColor(.secondary)
            }
            HStack {
                Label("Protocol", systemImage: "waveform.path")
                Spacer()
                Text("AES-ECB-128")
                    .foregroundColor(.secondary)
            }
        }
    }

    private func renameScooter() {
        guard !newName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        manager.sendCommand(BleDataOperateManage.changeBleName(newName))
    }

    private var rssiColor: Color {
        let rssi = manager.rssi
        if rssi >= -50 { return .green }
        if rssi >= -70 { return .orange }
        return .red
    }

    @Environment(\.dismiss) private var dismiss
}
