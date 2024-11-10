//
//  BluetoothDevice.swift
//  procks
//
//  Created by Tom Pickard on 11/9/24.
//
import Foundation

enum DeviceStatus: String, Codable {
    case known
    case notKnown
    case ignore
}

struct BluetoothDevice: Identifiable, Codable {
    let id = UUID()
    let name: String
    let uuid: String
    var rssi: Int
    var lastSeen: Date
    var status: DeviceStatus = .notKnown
}
