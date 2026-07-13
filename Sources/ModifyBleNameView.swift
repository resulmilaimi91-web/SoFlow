import SwiftUI

public struct ModifyBleNameView: View {
    let manager: BLEConnectionManager
    @State private var name = ""
    @Environment(\.dismiss) private var dismiss

    public init(manager: BLEConnectionManager) {
        self.manager = manager
    }

    public var body: some View {
        NavigationStack {
            Form {
                TextField("New scooter name", text: $name)
                    .onSubmit(save)
                Section {
                    Text("Name must be 1-16 characters")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Rename Scooter")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        manager.sendCommand(BleDataOperateManage.changeBleName(trimmed))
        dismiss()
    }
}
