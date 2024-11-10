//
//  ContentView.swift
//  procks
//
//  Created by Tom Pickard on 11/9/24.
//
import SwiftUI

struct ContentView: View {
    @StateObject var centralManager = CentralManager()

    var body: some View {
        NavigationView {
            VStack {
                List(centralManager.devices) { device in
                    VStack(alignment: .leading) {
                        Text(device.name).font(.headline)
                        Text("UUID: \(device.uuid)").font(.subheadline)
                        Text("RSSI: \(device.rssi)").font(.subheadline)
                        Text("Status: \(device.status.rawValue.capitalized)")
                            .font(.subheadline)
                            .foregroundColor(statusColor(for: device.status))
                    }
                    .opacity(self.getOpacity(for: device))
                    .contextMenu {
                        Button("Mark as Known") {
                            centralManager.updateDeviceStatus(uuid: device.uuid, status: .known)
                        }
                        Button("Mark as Not Known") {
                            centralManager.updateDeviceStatus(uuid: device.uuid, status: .notKnown)
                        }
                        Button("Ignore") {
                            centralManager.updateDeviceStatus(uuid: device.uuid, status: .ignore)
                        }
                    }
                }
                
                Button("Unignore All Devices") {
                    centralManager.unignoreAllDevices()
                }
                .padding()
                
                Button("Close and Delete Database") {
                    closeAndDeleteDatabaseAndExit()
                }
                .foregroundColor(.red)
                .padding()
            }
            .navigationTitle("Bluetooth Devices")
        }
    }
    
    private func getOpacity(for device: BluetoothDevice) -> Double {
        let currentTime = Date()
        let fiveMinutesAgo = Calendar.current.date(byAdding: .minute, value: -5, to: currentTime)!
        
        return device.lastSeen < fiveMinutesAgo ? 0.5 : 1.0
    }

    private func statusColor(for status: DeviceStatus) -> Color {
        switch status {
        case .known:
            return .green
        case .notKnown:
            return .orange
        case .ignore:
            return .gray
        }
    }

    private func closeAndDeleteDatabaseAndExit() {
        DatabaseManager.shared.deleteDatabase()
        
        // Exit the app with an abnormal termination
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            exit(0)
        }
    }
}
