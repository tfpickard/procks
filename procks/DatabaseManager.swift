
//
//  DatabaseManager.swift
//  procks
//
//  Created by Tom Pickard on 11/9/24.
//
import SQLite3
import Foundation

class DatabaseManager {
    static let shared = DatabaseManager()
    private var db: OpaquePointer?

    private init() {
        openDatabase()
        createTableIfNeeded()
    }

    private func databasePath() -> String {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsDirectory.appendingPathComponent("devices.sqlite").path
    }

    func openDatabase() {
        let path = databasePath()
        if sqlite3_open(path, &db) != SQLITE_OK {
            print("Unable to open database.")
        }
    }

    func createTableIfNeeded() {
        let createTableString = """
        CREATE TABLE IF NOT EXISTS Device(
        Id TEXT PRIMARY KEY,
        Name TEXT,
        RSSI INTEGER,
        LastSeen DOUBLE,
        Status TEXT);
        """
        var createTableStatement: OpaquePointer?
        if sqlite3_prepare_v2(db, createTableString, -1, &createTableStatement, nil) == SQLITE_OK {
            if sqlite3_step(createTableStatement) == SQLITE_DONE {
                print("Device table created.")
            } else {
                print("Device table not created.")
            }
        }
        sqlite3_finalize(createTableStatement)
    }

    func saveDevice(_ device: BluetoothDevice) {
        let insertStatementString = "INSERT OR REPLACE INTO Device (Id, Name, RSSI, LastSeen, Status) VALUES (?, ?, ?, ?, ?);"
        var insertStatement: OpaquePointer?
        if sqlite3_prepare_v2(db, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK {
            sqlite3_bind_text(insertStatement, 1, device.uuid, -1, nil)
            sqlite3_bind_text(insertStatement, 2, device.name, -1, nil)
            sqlite3_bind_int(insertStatement, 3, Int32(device.rssi))
            sqlite3_bind_double(insertStatement, 4, device.lastSeen.timeIntervalSince1970)
            sqlite3_bind_text(insertStatement, 5, device.status.rawValue, -1, nil)

            if sqlite3_step(insertStatement) == SQLITE_DONE {
                /// print("Successfully inserted/updated device.")
            } else {
                print("Could not insert/update device.")
            }
        }
        sqlite3_finalize(insertStatement)
    }

    func fetchAllDevices() -> [BluetoothDevice] {
        let queryStatementString = "SELECT * FROM Device;"
        var queryStatement: OpaquePointer?
        var devices: [BluetoothDevice] = []
        
        if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                let uuid = String(cString: sqlite3_column_text(queryStatement, 0))
                let name = String(cString: sqlite3_column_text(queryStatement, 1))
                let rssi = sqlite3_column_int(queryStatement, 2)
                let lastSeen = Date(timeIntervalSince1970: sqlite3_column_double(queryStatement, 3))
                let statusString = String(cString: sqlite3_column_text(queryStatement, 4))
                let status = DeviceStatus(rawValue: statusString) ?? .notKnown
                
                devices.append(BluetoothDevice(name: name, uuid: uuid, rssi: Int(rssi), lastSeen: lastSeen, status: status))
            }
        }
        sqlite3_finalize(queryStatement)
        return devices
    }

    func closeDatabase() {
        if db != nil {
            sqlite3_close(db)
            db = nil
            print("Database closed.")
        }
    }

    func deleteDatabase() {
        closeDatabase()
        let path = databasePath()
        do {
            try FileManager.default.removeItem(atPath: path)
            print("Database deleted.")
        } catch {
            print("Failed to delete database: \(error.localizedDescription)")
        }
    }
}
/*
import SQLite3
import Foundation

class DatabaseManager {
    static let shared = DatabaseManager()
    private var db: OpaquePointer?

    private init() {
        openDatabase()
        createTableIfNeeded()
    }

    private func databasePath() -> String {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsDirectory.appendingPathComponent("devices.sqlite").path
    }

    func openDatabase() {
        let path = databasePath()
        if sqlite3_open(path, &db) != SQLITE_OK {
            print("Unable to open database.")
        }
    }

    func createTableIfNeeded() {
        let path = databasePath()
        if FileManager.default.fileExists(atPath: path) {
            print("Database already exists. Skipping table creation.")
            return
        }

        let createTableString = """
        CREATE TABLE IF NOT EXISTS Device(
        Id TEXT PRIMARY KEY,
        Name TEXT,
        RSSI INTEGER,
        LastSeen DOUBLE,
        Status TEXT);
        """
        var createTableStatement: OpaquePointer?
        if sqlite3_prepare_v2(db, createTableString, -1, &createTableStatement, nil) == SQLITE_OK {
            if sqlite3_step(createTableStatement) == SQLITE_DONE {
                print("Device table created.")
            } else {
                print("Device table not created.")
            }
        }
        sqlite3_finalize(createTableStatement)
    }

    func saveDevice(_ device: BluetoothDevice) {
        let insertStatementString = "INSERT OR REPLACE INTO Device (Id, Name, RSSI, LastSeen, Status) VALUES (?, ?, ?, ?, ?);"
        var insertStatement: OpaquePointer?
        if sqlite3_prepare_v2(db, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK {
            sqlite3_bind_text(insertStatement, 1, device.uuid, -1, nil)
            sqlite3_bind_text(insertStatement, 2, device.name, -1, nil)
            sqlite3_bind_int(insertStatement, 3, Int32(device.rssi))
            sqlite3_bind_double(insertStatement, 4, device.lastSeen.timeIntervalSince1970)
            sqlite3_bind_text(insertStatement, 5, device.status.rawValue, -1, nil)

            if sqlite3_step(insertStatement) == SQLITE_DONE {
                //print("Successfully inserted/updated device.")
            } else {
                print("Could not insert/update device.")
            }
        }
        sqlite3_finalize(insertStatement)
    }

    func fetchAllDevices() -> [BluetoothDevice] {
        let queryStatementString = "SELECT * FROM Device;"
        var queryStatement: OpaquePointer?
        var devices: [BluetoothDevice] = []
        
        if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                let uuid = String(cString: sqlite3_column_text(queryStatement, 0))
                let name = String(cString: sqlite3_column_text(queryStatement, 1))
                let rssi = sqlite3_column_int(queryStatement, 2)
                let lastSeen = Date(timeIntervalSince1970: sqlite3_column_double(queryStatement, 3))
                let statusString = String(cString: sqlite3_column_text(queryStatement, 4))
                let status = DeviceStatus(rawValue: statusString) ?? .notKnown
                
                devices.append(BluetoothDevice(name: name, uuid: uuid, rssi: Int(rssi), lastSeen: lastSeen, status: status))
            }
        }
        sqlite3_finalize(queryStatement)
        return devices
    }
    func deleteDatabase() {
            closeDatabase()
            let path = databasePath()
            do {
                try FileManager.default.removeItem(atPath: path)
                print("Database deleted.")
            } catch {
                print("Failed to delete database: \(error.localizedDescription)")
            }
        }
    func closeDatabase() {
           if db != nil {
               sqlite3_close(db)
               db = nil
               print("Database closed.")
           }
       }
}
*/
