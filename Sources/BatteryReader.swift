import Foundation
import CoreBluetooth

final class BatteryReader: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    @Published var levels: [Int?] = [nil, nil, nil]
    @Published var status = "Premi Cerca"
    @Published var deviceName = ""

    private var central: CBCentralManager!
    private var peripheral: CBPeripheral?
    private let batteryService = CBUUID(string: "180F")
    private let batteryLevel = CBUUID(string: "2A19")

    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: nil)
    }

    func start() {
        guard central.state == .poweredOn else {
            status = "Bluetooth spento o non autorizzato"
            return
        }
        levels = [nil, nil, nil]
        status = "Cerco..."
        let connected = central.retrieveConnectedPeripherals(withServices: [batteryService])
        if let p = connected.first(where: { ($0.name ?? "").lowercased().contains("cmf") }) ?? connected.first {
            connect(p)
        } else {
            central.scanForPeripherals(withServices: [batteryService])
            status = "Scansione in corso..."
        }
    }

    private func connect(_ p: CBPeripheral) {
        central.stopScan()
        peripheral = p
        p.delegate = self
        deviceName = p.name ?? "Dispositivo"
        status = "Connessione a \(deviceName)..."
        central.connect(p)
    }

    func centralManagerDidUpdateState(_ c: CBCentralManager) {
        switch c.state {
        case .poweredOn: status = "Premi Cerca"
        case .unauthorized: status = "Permesso Bluetooth negato (Impostazioni)"
        case .poweredOff: status = "Bluetooth spento"
        default: status = "Bluetooth non disponibile"
        }
    }

    func centralManager(_ c: CBCentralManager, didDiscover p: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        connect(p)
    }

    func centralManager(_ c: CBCentralManager, didConnect p: CBPeripheral) {
        p.discoverServices([batteryService])
    }

    func centralManager(_ c: CBCentralManager, didFailToConnect p: CBPeripheral, error: Error?) {
        status = "Connessione fallita"
    }

    func centralManager(_ c: CBCentralManager, didDisconnectPeripheral p: CBPeripheral, error: Error?) {
        status = "Disconnesso"
    }

    func peripheral(_ p: CBPeripheral, didDiscoverServices error: Error?) {
        let svcs = p.services?.filter { $0.uuid == batteryService } ?? []
        if svcs.isEmpty {
            status = "Nessun servizio batteria esposto da questo dispositivo"
            return
        }
        for s in svcs { p.discoverCharacteristics([batteryLevel], for: s) }
    }

    func peripheral(_ p: CBPeripheral, didDiscoverCharacteristicsFor s: CBService, error: Error?) {
        for c in s.characteristics ?? [] {
            p.readValue(for: c)
            if c.properties.contains(.notify) { p.setNotifyValue(true, for: c) }
        }
    }

    func peripheral(_ p: CBPeripheral, didUpdateValueFor c: CBCharacteristic, error: Error?) {
        guard let byte = c.value?.first else { return }
        let svcs = p.services?.filter { $0.uuid == batteryService } ?? []
        guard let idx = svcs.firstIndex(where: { $0 === c.service }), idx < 3 else { return }
        levels[idx] = Int(byte)
        status = "Connesso a \(deviceName)"
    }
}
