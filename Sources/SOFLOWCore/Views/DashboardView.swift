import SwiftUI
import MapKit

public struct DashboardView: View {
    @ObservedObject var manager: BLEConnectionManager
    @State private var selectedTab = 0
    @State private var showSettings = false
    @State private var showMap = false

    public init(manager: BLEConnectionManager) {
        self.manager = manager
    }

    public var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $selectedTab) {
                Text("Dashboard").tag(0)
                Text("Map").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 8)

            TabView(selection: $selectedTab) {
                dashboardContent.tag(0)
                RideMapView(manager: manager).tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(manager: manager)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showSettings = true } label: {
                    Image(systemName: "gearshape")
                }
            }
            ToolbarItem(placement: .topBarLeading) {
                Button("Disconnect") { manager.disconnect() }
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }

    private var dashboardContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                speedSection
                batterySection
                rideSection
                statusSection
                if let state = manager.lastState {
                    faultsSection(state)
                }
            }
            .padding()
        }
    }

    private var speedSection: some View {
        VStack(spacing: 4) {
            Text("\(manager.lastState?.speedKmh ?? 0)")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundColor(.blue)
            Text(manager.lastState?.unit == true ? "km/h" : "MPH")
                .font(.title3)
                .foregroundColor(.secondary)
            HStack(spacing: 20) {
                if let state = manager.lastState {
                    Label(state.speedMode == 0 ? "Eco" : state.speedMode == 1 ? "Comfort" : "Sport",
                          systemImage: "bolt.fill")
                        .font(.caption)
                    if state.lockStatus {
                        Label("Locked", systemImage: "lock.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    if state.lampStatus {
                        Label("Lights On", systemImage: "lightbulb.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    private var batterySection: some View {
        HStack(spacing: 16) {
            batteryGauge
            VStack(alignment: .leading, spacing: 4) {
                Text("Battery")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(manager.lastState?.remainingCharge ?? 0)%")
                    .font(.title2)
                    .fontWeight(.semibold)
                if let v = manager.lastState?.batteryVoltage {
                    Text(String(format: "%.1f V", Double(v) / 100.0))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            if let c = manager.lastState?.batteryCurrent {
                VStack(alignment: .trailing) {
                    Text("Current")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f A", Double(c) / 100.0))
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    private var batteryGauge: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray4), lineWidth: 6)
            Circle()
                .trim(from: 0, to: CGFloat(manager.lastState?.remainingCharge ?? 0) / 100.0)
                .stroke(batteryColor, lineWidth: 6)
                .rotationEffect(.degrees(-90))
            Text("\(manager.lastState?.remainingCharge ?? 0)%")
                .font(.caption2)
                .fontWeight(.bold)
        }
        .frame(width: 60, height: 60)
    }

    private var batteryColor: Color {
        let pct = manager.lastState?.remainingCharge ?? 100
        if pct > 60 { return .green }
        if pct > 20 { return .orange }
        return .red
    }

    private var rideSection: some View {
        HStack(spacing: 16) {
            statBox(title: "Trip", value: "\(manager.lastState?.distanceSingle ?? 0)", unit: "m")
            statBox(title: "Total", value: "\(manager.lastState?.distanceAll ?? 0)", unit: "m")
            if let t = manager.lastState?.singleRideTime {
                statBox(title: "Time", value: "\(t / 60)", unit: "min")
            }
        }
    }

    private func statBox(title: String, value: String, unit: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
            Text(unit)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("System Status")
                .font(.headline)
            if let state = manager.lastState {
                HStack {
                    statusRow("Brake", state.faultBrake)
                    statusRow("Controller", state.faultController)
                    statusRow("Motor", state.faultMotor)
                    statusRow("Comm", state.faultCommunication)
                }
                if state.stealingAlert || state.transferFault || state.systemStatus {
                    HStack {
                        if state.stealingAlert {
                            Label("Theft Alert", systemImage: "exclamationmark.triangle")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        if state.systemStatus {
                            Label("System", systemImage: "gear")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func statusRow(_ label: String, _ fault: Bool) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(fault ? Color.red : Color.green)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private func faultsSection(_ state: MPStateData) -> some View {
        Group {
            if state.faults.contains(true) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Fault Codes")
                        .font(.headline)
                    ForEach(Array(state.faults.enumerated()), id: \.offset) { idx, active in
                        if active {
                            Text("Fault \(idx)")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
}

public struct RideMapView: View {
    @ObservedObject var manager: BLEConnectionManager
    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var route: [CLLocationCoordinate2D] = []
    @State private var isTracking = false

    private let locationManager = CLLocationManager()

    public init(manager: BLEConnectionManager) {
        self.manager = manager
    }

    public var body: some View {
        VStack(spacing: 0) {
            Map(position: $position) {
                UserAnnotation()
                if !route.isEmpty {
                    MapPolyline(coordinates: route)
                        .stroke(.blue, lineWidth: 3)
                }
                if let loc = locationManager.location?.coordinate {
                    Annotation("Start", coordinate: route.first ?? loc) {
                        Image(systemName: "flag.fill")
                            .foregroundColor(.green)
                            .font(.title2)
                    }
                    Annotation("Now", coordinate: loc) {
                        Image(systemName: "scooter")
                            .foregroundColor(.blue)
                            .font(.title2)
                    }
                }
            }
            .mapStyle(.standard)
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapScaleView()
            }

            HStack {
                Button {
                    if isTracking { stopTracking() }
                    else { startTracking() }
                } label: {
                    Label(isTracking ? "Stop" : "Track Ride",
                          systemImage: isTracking ? "stop.fill" : "location.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(isTracking ? .red : .blue)

                Spacer()

                Button {
                    route.removeAll()
                } label: {
                    Label("Clear", systemImage: "trash")
                }
                .buttonStyle(.bordered)
                .disabled(route.isEmpty)
            }
            .padding()
        }
        .onAppear {
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
        }
    }

    private func startTracking() {
        isTracking = true
        route.removeAll()
        if let loc = locationManager.location?.coordinate {
            route.append(loc)
        }
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { timer in
            guard isTracking, let loc = locationManager.location?.coordinate else {
                timer.invalidate()
                return
            }
            route.append(loc)
        }
    }

    private func stopTracking() {
        isTracking = false
    }
}
