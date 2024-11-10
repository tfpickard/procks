//
//  CentralManager.swift
//  procks
//
//  Created by Tom Pickard on 11/9/24.
//

import CoreBluetooth
import Foundation

class CentralManager: NSObject, ObservableObject, CBCentralManagerDelegate {
    private var centralManager: CBCentralManager!
    @Published var devices: [BluetoothDevice] = []
    private var lastRefreshTime: Date = Date()

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: NSNumber(value: true)])
        } else {
            print("Bluetooth not available.")
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        let deviceName = peripheral.name ?? "Unknown"
        if (deviceName.lowercased().contains("welfare") || deviceName.lowercased().contains("unknown") || deviceName.lowercased().contains("dogg")) {
            return
        }

        let currentDate = Date()
        let device = BluetoothDevice(name: deviceName, uuid: peripheral.identifier.uuidString, rssi: RSSI.intValue, lastSeen: currentDate)
        
        if let existingIndex = devices.firstIndex(where: { $0.uuid == device.uuid }) {
            devices[existingIndex].lastSeen = currentDate
            devices[existingIndex].rssi = RSSI.intValue
            DatabaseManager.shared.saveDevice(devices[existingIndex])
        } else {
            devices.append(device)
            DatabaseManager.shared.saveDevice(device)
        }
        
        // Refresh the list every 10 seconds
        if currentDate.timeIntervalSince(lastRefreshTime) >= 10 {
            lastRefreshTime = currentDate
            refreshDeviceList()
        }
    }
    
    private func refreshDeviceList() {
        let fifteenMinutesAgo = Calendar.current.date(byAdding: .minute, value: -15, to: Date())!
        devices = devices
            .filter { $0.status != .ignore && $0.lastSeen >= fifteenMinutesAgo }
            .sorted { $0.rssi > $1.rssi }
    }

    func updateDeviceStatus(uuid: String, status: DeviceStatus) {
        if let index = devices.firstIndex(where: { $0.uuid == uuid }) {
            devices[index].status = status
            DatabaseManager.shared.saveDevice(devices[index])
            refreshDeviceList()
        }
    }
    
    func unignoreAllDevices() {
        for i in devices.indices {
            if devices[i].status == .ignore {
                devices[i].status = .notKnown
                DatabaseManager.shared.saveDevice(devices[i])
            }
        }
        refreshDeviceList()
    }
}
