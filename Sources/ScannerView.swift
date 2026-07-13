import SwiftUI
import CoreBluetooth

public struct ScannerView: View {
    @StateObject private var manager = BLEConnectionManager()
    @State private var isScanning = false

    public init() {}

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                statusBar
                if manager.connectionState.isConnected {
                    connectedView
                } else {
                    scannerContent
                }
            }
            .navigationTitle("SoFlow")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .onAppear { startScan() }
            .onDisappear { manager.stopScan() }
        }
    }

    private var statusBar: some View {
        HStack {
            Circle()
                .fill(connectionColor)
                .frame(width: 10, height: 10)
            Text(manager.connectionState.label)
                .font(.caption)
                .foregroundColor(.secondary)
            if case .reconnecting = manager.connectionState {
                ProgressView()
                    .scaleEffect(0.7)
            }
            Spacer()
            if manager.connectionState.isConnected {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.caption)
                Text("\(manager.rssi) dBm")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .background(Color(.systemGray6))
    }

    private var scannerContent: some View {
        VStack {
            if manager.connectionState == .timeout || manager.connectionState == .failed {
                errorBanner
            }
            if isScanning {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Scanning for scooters...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
            if manager.discovered.isEmpty {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "scooter")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("No scooters found")
                        .font(.headline)
                    Text("Make sure your scooter is powered on\nand within range")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                Spacer()
            } else {
                List {
                    ForEach(manager.discovered) { scooter in
                        scooterRow(scooter)
                    }
                }
                .listStyle(.plain)
                .refreshable { startScan() }
            }
        }
    }

    private func scooterRow(_ scooter: ScannedScooter) -> some View {
        Button {
            manager.connect(to: scooter)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(scooter.name.isEmpty ? "Unknown Scooter" : scooter.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    HStack(spacing: 12) {
                        Label(factoryLabel(scooter.factory), systemImage: "chip")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Label("\(scooter.rssi) dBm", systemImage: "antenna.radiowaves.left.and.right")
                            .font(.caption)
                            .foregroundColor(rssiColor(scooter.rssi))
                    }
                }
                Spacer()
                signalBars(scooter.rssi)
            }
            .padding(.vertical, 4)
        }
    }

    private var connectedView: some View {
        DashboardView(manager: manager)
    }

    private var errorBanner: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text(manager.connectionState == .timeout
                 ? "Connection timed out. Retrying..."
                 : "Connection failed. Retrying...")
                .font(.caption)
            Spacer()
            Button("Stop") { manager.disconnect() }
                .font(.caption)
                .foregroundColor(.red)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.orange.opacity(0.1))
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                if isScanning { manager.stopScan(); isScanning = false }
                else { startScan() }
            } label: {
                Image(systemName: isScanning ? "stop.circle" : "arrow.clockwise")
            }
        }
        if manager.lastKnownPeripheralUUID != nil {
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Button("Forget Saved Device", role: .destructive) {
                        manager.forgetDevice()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }

    private func startScan() {
        isScanning = true
        manager.startScan()
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            isScanning = false
            manager.stopScan()
        }
    }

    private var connectionColor: Color {
        switch manager.connectionState {
        case .connected: return .green
        case .connecting, .discovering, .reconnecting: return .orange
        case .timeout, .failed: return .red
        default: return .gray
        }
    }

    private func factoryLabel(_ f: ScooterFactory) -> String {
        switch f {
        case .kingMeter: return "KING-METER"
        case .nordic: return "Nordic UART"
        case .walkiz: return "Walkiz"
        }
    }

    private func rssiColor(_ rssi: Int) -> Color {
        if rssi >= -50 { return .green }
        if rssi >= -70 { return .orange }
        return .red
    }

    private func signalBars(_ rssi: Int) -> some View {
        let bars: Int
        if rssi >= -50 { bars = 4 }
        else if rssi >= -65 { bars = 3 }
        else if rssi >= -80 { bars = 2 }
        else { bars = 1 }
        return HStack(alignment: .bottom, spacing: 2) {
            ForEach(0..<4) { i in
                RoundedRectangle(cornerRadius: 1)
                    .fill(i < bars ? Color.green : Color.gray.opacity(0.3))
                    .frame(width: 4, height: CGFloat(6 + i * 4))
            }
        }
    }
}

#Preview {
    ScannerView()
}
