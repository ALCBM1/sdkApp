//
//  Bluetooth.swift
//
//  Created by Satoshi Tanaka at GlobalPocket on 2023/08/04.
//

import Foundation
import CoreBluetooth

final public class Bluetooth: NSObject,CBCentralManagerDelegate,CBPeripheralDelegate, ObservableObject {
    // シングルトンパターン実装
    public static let shared = Bluetooth()
    // iOSのBluetoothサービス（セントラルマネージャー）
    private var centralManager : CBCentralManager!
    // クラスの初期化
    private override init() {
        super.init()
    }
    private var uuids : Set<CBUUID> = []
    private var peripherals : [CBPeripheral] = []
    private var services : [CBService] = []
    private var subscribers : [CBCharacteristic] = []
    private var characteristics : [CBCharacteristic] = []
    // Bluetooth識別子のセット（重複なし）
    private var descriptors : [CBDescriptor] = []
    // MARK: - 初期化処理
    //------------------------------------------------------------------------
    // セントラルマネージャーを初期化する
    public func initialize(_ uuids:[String]?) {
        // 初期化した時点でPermissionの許諾のpopupが出てBoluetoothの電源がONになる
        centralManager = CBCentralManager(delegate: self, queue: nil)
        guard uuids != nil else {
            return
        }
        for uuid in uuids! {
            self.uuids.insert(CBUUID(string: uuid))
        }
    }
    // MARK: - コールバック関数の変数
    //------------------------------------------------------------------------
    // 接続成功時のコールバック関数
    public var connected:(_ name: String?) -> Void = {name in}
    // 接続失敗時のコールバック関数
    public var connectFail:(_ name: String?,_ error:Error?) -> Void = {name,error in }
    // 接続解除時のコールバック関数
    public var disconnected : (_ name:String?) -> Void = {name in }
    // 接続解除失敗時のコールバック関数
    public var disconnectFail : (_ name:String?,_ error:Error?) -> Void = {name,error in }
    // 電波強度取得時のコールバック関数
    public var gotRSSI:(_ name: String?,_ value: Int?) -> Void = {name,value in }
    // 電波強度取得失敗時のコールバック関数
    public var getRSSIFail:(_ name: String?,_ error:Error?) -> Void = {name,error in }
    // 接続状態変化検出時コールバック関数
    public var changeCentralManagerState : (_ state:Int?)->Void = {state in }
    // 更新検知時のコールバック関数
    public var updated : (_ name:String?,_ service_uuid:String?,_ characteristic_uuid:String?,_ value: Data?) -> Void = {name,service_uuid,characteristic_uuid,value in }
    // 更新検知失敗時のコールバック関数
    public var notifyFail : (_ name:String?,_ service_uuid:String?,_ characteristic_uuid:String?,_ error:Error?) -> Void = {name,service_uuid,characteristic_uuid,error in }
    // 購読完了時のコールバック関数
    public var subscribed: (_ name:String?,_ service_uuid:String?,_ characteristic_uuid:String?) -> Void = {name,service_uuid,characteristic_uuid in }
    // 購読解除完了時のコールバック関数
    public var unsubscribed: (_ name:String?,_ service_uuid:String?,_ characteristic_uuid:String?) -> Void = {name,service_uuid,characteristic_uuid in }
    // 購読／購読解除時のコールバック関数
    public var subscribeFail: (_ name:String?,_ service_uuid:String?,_ characteristic_uuid:String?,_ error: Error?) -> Void = {name,service_uuid,characteristic_uuid,error in }
    // ペリフェラルへの書き込み命令失敗時コールバック関数
    public var writeFail : (_ name:String?,_ service_uuid:String?,_ characteristic_uuid:String?,_ descriptor_uuid:String?,_ value: Any?,_ error:Error?) -> Void = {name,service_uuid,characteristic_uuid,descriptor_uuid,value,error in }
    // 書き込み命令受信時のコールバック関数
    public var willWrite : (_ name:String?,_ service_uuid:String?,_ characteristic_uuid:String?,_ oldValue:Any?) -> Void = {name,service_uuid,characteristic_uuid,oldValue in }
    // 書き込み命令受信失敗時のコールバック関数
    public var willWriteFail : (_ name:String?,_ service_uuid:String?,_ characteristic_uuid:String?,_ error: Error?) -> Void = {name,service_uuid,characteristic_uuid,error in }
    // 書き込み完了時のコールバック関数
    public var didWrite : (_ name:String?,_ service_uuid:String?,_ characteristic_uuid:String?,_ descriptor_uuid:String?) -> Void = {name,service_uuid,characteristic_uuid,descriptor_uuid in }
    // 書き込み失敗時のコールバック関数
    public var didWriteFail : (_ name:String?,_ service_uuid:String?,_ characteristic_uuid:String?,_ descriptor_uuid:String?,_ error: Error?) -> Void = {name,service_uuid,characteristic_uuid,descriptor_uuid,error in }
    public var discoverPeripheral : (_ name:String?,_ rssi:Int) -> Void = {name,rssi in }
    public var discoverServices : (_ name:String?,_ service_uuid:String?,_ error:Error?) -> Void = {name,service_uuid,error in }
    public var discoverCharacteristic : (_ name:String?,_ characteristic_uuid : String?,_ error:Error?) -> Void = {name,characteristic_uuid,error in}
    public var isNotifyCharacteristic : (_ name:String,_ characteristic_uuid : String) -> Bool? = {name,characteristic_uuid in
        return nil
    }

    // MARK: - Getter/Setter
    //------------------------------------------------------------------------
    // 指定したUUIDを持つペリフェラルの名前のSetを取得する
    public func getPeripheralNames(_ uuid:String?) -> Set<String> {
        var result : Set<String> = []
        for peripheral in self.peripherals {
            if uuid == nil {
                result.insert(peripheral.name!)
                continue
            }
            if peripheral.identifier.uuidString == uuid {
                result.insert(peripheral.name!)
                continue
            }
        }
        return result
    }
    private func isSubscribed(_ peripheral: CBPeripheral,_ characteristic: CBCharacteristic) -> Bool {
        // 既に同じものが登録済みの場合は処理しない
        for subscriber in subscribers {
            guard subscriber.uuid.uuidString == characteristic.uuid.uuidString else {
                continue
            }
            guard subscriber.service != nil else {
                continue
            }
            guard subscriber.service!.uuid.uuidString == characteristic.service!.uuid.uuidString else {
                continue
            }
            guard subscriber.service!.peripheral!.name == characteristic.service!.peripheral!.name else {
                continue
            }
            return true
        }
        return false
    }
    // MARK: - Util
    //------------------------------------------------------------------------
    // 指定した名前を持つペリフェラルを取得
    private func getPeripheral(_ name:String) -> CBPeripheral?{
        for peripheral in self.peripherals {
            guard peripheral.name == name else {
                continue
            }
            return peripheral
        }
        return nil
    }
    // MARK: - スキャン関連
    // ------------------------------------------------------------------------
    // スキャン開始
    public func startScan() {
        // 識別子の配列をクリアする
        self.descriptors.removeAll()
        self.characteristics.removeAll()
        self.services.removeAll()
        self.peripherals.removeAll()
        guard self.uuids.count > 0 else {
            // ペリフェラルの検索を行う
            centralManager?.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey:true])
            return
        }
        // ペリフェラルの検索を行う
        centralManager?.scanForPeripherals(withServices: Array(self.uuids), options: [CBCentralManagerScanOptionAllowDuplicatesKey:true])
    }
    // ペリフェラル検知時イベント
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // ペリフェラルに自身を登録しGCされるのを防ぐ
        peripheral.delegate = self
        guard peripheral.name != nil else {
            return
        }
        self.peripherals.append(peripheral)
        discoverPeripheral(peripheral.name!,Int(truncating: RSSI))
    }
    // スキャン停止
    public func stopScan() {
        centralManager?.stopScan()
    }
    // MARK: - 接続関連
    // ------------------------------------------------------------------------
    // ペリフェラルに接続する
    public func connect (_ name:String) {
        // ペリフェラルのインスタンスを取得する
        guard let peripheral = getPeripheral(name) else {
            connectFail(name,NSError(domain: "Not Found Peripheral", code: -4))
            return
        }
        // 接続する
        centralManager?.connect(peripheral, options: nil)
    }
    // ペリフェラルへの接続成功時イベント
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        // ペリフェラルが持つ全てのサービスの検索を開始する
        peripheral.discoverServices(nil)
        connected(peripheral.name!)
    }
    // ペリフェラルへの接続失敗時イベント
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        guard error == nil else {
            connectFail(peripheral.name!,error!)
            return
        }
    }
    // サービス検索の完了時イベント
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            connectFail(peripheral.name!, error!)
            return
        }
        guard let services = peripheral.services else {
            connectFail(peripheral.name!,NSError(domain: "Service Not Found", code: -1))
            return
        }
        for service in services {
            self.services.append(service)
            /// ペリフェラルのサービスが持つ全てのキャラクタリスティックの検索を開始する
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    // キャラクタリスティック検索の完了時イベント
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else {
            connectFail(peripheral.name!, error!)
            return
        }
        guard let characteristics = service.characteristics else {
            connectFail(peripheral.name!,NSError(domain: "Characteristic Not Found", code: -2))
            return
        }
        for characteristic in characteristics {
            self.characteristics.append(characteristic)
            peripheral.discoverDescriptors(for: characteristic)
            let isNotifyCharacteristic = isNotifyCharacteristic(peripheral.name!,characteristic.uuid.uuidString)
            if isNotifyCharacteristic != nil && isNotifyCharacteristic! {
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
        guard characteristics.count > 0 else {
            return
        }
        discoverServices(peripheral.name!,service.uuid.uuidString,error)
    }
    // 識別子検索完了時イベント
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            connectFail(peripheral.name!, error!)
            return
        }
        guard let descriptors = characteristic.descriptors else {
            connectFail(peripheral.name!,NSError(domain: "Descriptor Not Found", code: -3))
            return
        }
        for descriptor in descriptors{
            self.descriptors.append(descriptor)
        }
        guard descriptors.count > 0 else {
            return
        }
        let isNotifyCharacteristic = isNotifyCharacteristic(peripheral.name!,characteristic.uuid.uuidString)
        if isNotifyCharacteristic != nil && isNotifyCharacteristic! {
            peripheral.setNotifyValue(true,for: characteristic)
        }
        discoverCharacteristic(peripheral.name!,characteristic.uuid.uuidString,error)
    }
    // MARK: - 接続解除関連
    // ------------------------------------------------------------------------
    // ペリフェラルの接続解除
    func disconnect(_ name:String) {
        // ペリフェラルのインスタンスを取得する
        guard let peripheral = getPeripheral(name) else {
            disconnectFail(name,NSError(domain: "Not Found Peripheral", code: -5))
            return
        }
        centralManager?.cancelPeripheralConnection(peripheral)
        UserDefaults.standard.removeObject(forKey: "connectedDeviceName")
    }
    // ペリフェラルへの接続解除時イベント
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        guard error == nil else {
            disconnectFail(peripheral.name!,error!)
            return
        }
        disconnected(peripheral.name!)
    }
    // MARK: - 電波強度関連処理
    // ------------------------------------------------------------------------
    // 電波強度の取得を開始する
    public func getRSSI(_ name:String) {
        guard let peripheral = getPeripheral(name) else {
            getRSSIFail(name,NSError(domain: "Read RSSI Failed", code: -6))
            return
        }
        peripheral.readRSSI()
    }
    // 電波強度取得完了時イベント
    public func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        guard error == nil else {
            getRSSIFail(peripheral.name!,error!)
            return
        }
        gotRSSI(peripheral.name!,Int(truncating: RSSI))
    }
    // MARK: - 接続状態関連処理
    // ------------------------------------------------------------------------
    // Bluetoothの状態変化検知イベント
    @objc public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        changeCentralManagerState(central.state.rawValue)
        startScan()
    }
    // MARK: - 更新検知処理
    //------------------------------------------------------------------------
    // キャラクタリスティック更新検知時イベント
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        let name = peripheral.name!
        let service = characteristic.service!
        let service_uuid = service.uuid.uuidString
        let characteristic_uuid = characteristic.uuid.uuidString
        guard error == nil else {
            notifyFail(name,service_uuid,characteristic_uuid,error!)
            return
        }
        let value: Data = characteristic.value!
        updated(name,service_uuid,characteristic_uuid,value)
    }
    // キャラクタリスティックの通知の設定が変更された際のイベント
    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        let name = peripheral.name!
        let service = characteristic.service!
        let service_uuid = service.uuid.uuidString
        let characteristic_uuid = characteristic.uuid.uuidString
        guard error == nil else {
            subscribeFail(name,service_uuid,characteristic_uuid,error!)
            return
        }
        // 通知の設定が成功しているかチェックする
//        characteristic.properties.contains(<#T##member: CBCharacteristicProperties##CBCharacteristicProperties#>)
        if characteristic.isNotifying {
            if !isSubscribed(peripheral, characteristic) {
                subscribers.append(characteristic)
                subscribed(name,service_uuid,characteristic_uuid)
            }
        } else {
            var index = 0
            for subscriber in subscribers {
                guard subscriber.uuid.uuidString == characteristic_uuid else {
                    index += 1
                    continue
                }
                guard subscriber.service?.uuid.uuidString == service_uuid else {
                    index += 1
                    continue
                }
                guard subscriber.service?.peripheral?.name == name else {
                    index += 1
                    continue
                }
                subscribers.remove(at: index)
            }
            unsubscribed(name,service_uuid,characteristic_uuid)
        }
    }
    // MARK: - 書き込み関連
    // ------------------------------------------------------------------------
    // ペリフェラルへの書き込み命令
    public func write(_ name:String,_ service_uuid:String?,_ characteristic_uuid:String,_ value: Data) {
        guard let peripheral = getPeripheral(name) else {
            writeFail(name,service_uuid,characteristic_uuid,nil,value,NSError(domain: "Not found peripheral", code: -11))
            return
        }
        // 探した書き込み対象を格納する変数
        var target : CBCharacteristic? = nil
        // 検知済みのキャラクタリスティックから探す
        for characteristic in self.subscribers {
            // サービスのUUIDが指定されている場合
            if service_uuid != nil {
                guard let service = characteristic.service else {
                    // サービスがない場合は対象じゃない
                    continue
                }
                let uuid = CBUUID(string: service_uuid!)
                guard uuid.uuidString == service.uuid.uuidString else {
                    // サービスのUUIDが異なる場合は対象じゃない
                    continue
                }
            }
            let uuid = CBUUID(string: characteristic_uuid)
            // UUIDが一致するもののみが対象
            guard characteristic.uuid.uuidString == uuid.uuidString else {
                // UUIDが違ったら対象じゃない
                continue
            }
            guard let parentPeripheral = characteristic.service?.peripheral else {
                // ペリフェラルがない場合は対象じゃない
                continue
            }
            guard parentPeripheral.name == name else {
                // ペリフェラルの名前が異なる場合は対象じゃない
                continue
            }
            guard parentPeripheral.state == .connected else {
                // ペリフェラルが接続状態じゃない場合は対象じゃない
                continue
            }
            // 条件にあったものが対象
            target = characteristic
            break
        }
        // 書き込み対象が無かった場合
        if target == nil {
            writeFail(name,service_uuid,characteristic_uuid,nil,value,NSError(domain: "Not found target", code: -12))
            return
        }
//        peripheral.setNotifyValue(true,for: target!)
        // データの書き込み命令を送信
        peripheral.writeValue(value, for: target!, type: CBCharacteristicWriteType.withResponse)
        willWrite(name,service_uuid,characteristic_uuid,nil)
    }
    // 送信した書き込み命令をペリフェラルが完了した際のイベント
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        let name = peripheral.name!
        let service = characteristic.service!
        let service_uuid = service.uuid.uuidString
        let characteristic_uuid = characteristic.uuid.uuidString
        guard error == nil else {
            didWriteFail(name,service_uuid,characteristic_uuid,nil,error!)
            return
        }
        didWrite(name,service_uuid,characteristic_uuid,nil)
    }
    // 送信した書き込み命令をペリフェラルが完了した際のイベント
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        let name = peripheral.name!
        let descriptor_uuid = descriptor.uuid.uuidString
        let characteristic = descriptor.characteristic
        let characteristic_uuid = characteristic?.uuid.uuidString
        let service = characteristic?.service
        let service_uuid = service?.uuid.uuidString
        guard error == nil else {
            didWriteFail(name,service_uuid!,characteristic_uuid!,descriptor_uuid,error!)
            return
        }
        didWrite(name,service_uuid!,characteristic_uuid!,descriptor_uuid)
    }
}
