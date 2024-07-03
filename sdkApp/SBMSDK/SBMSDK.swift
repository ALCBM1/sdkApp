//
//  SBMSDK.swift
//  SbmsdkCapacitor
//
//  Created by Satoshi Tanaka on 2023/08/04.
//

import Foundation

final public class SBMSDK: NSObject {
    // シングルトンパターン実装
    public static let shared = SBMSDK()
    // 関連するUUID
    public static let UUID = SBMUUID()
    // Notificationの名前
    public static let NotificationName = SBMNotificationName()
    // コマンド文の先頭に付与
    private static let commandPrefix = "\r\n"
    // コマンド文の末尾に付与
    private static let commandSuffix = "\r\n"
    // コマンド文の区切り文字
    private static let commandDelimiter = " "
    /// 初期化
    private override init() {
        super.init()
        self.initialize()
    }
    // MARK: - 初期化処理
    //------------------------------------------------------------------------
    public func initialize() {
        // Bluetoothの初期化
        Bluetooth.shared.initialize(nil)
        // 接続成功時のコールバック関数
        Bluetooth.shared.connected = {name in
            guard self.isSBMName(name) else {
                return
            }
            self.notify(SBMSDK.NotificationName.connected,name,nil,nil,nil,nil,nil)
        }
        // 接続失敗時のコールバック関数
        Bluetooth.shared.connectFail = {name,error in
            guard self.isSBMName(name) else {
                return
            }
            self.notify(SBMSDK.NotificationName.connectFail,name,nil,nil,nil,nil,error)
        }
        // 接続解除時のコールバック関数
        Bluetooth.shared.disconnected = {name in
            guard self.isSBMName(name) else {
                return
            }
            self.notify(SBMSDK.NotificationName.disconnected,name,nil,nil,nil,nil,nil)
        }
        // 接続解除失敗時のコールバック関数
        Bluetooth.shared.disconnectFail = {name,error in
            guard self.isSBMName(name) else {
                return
            }
            self.notify(SBMSDK.NotificationName.disconnectFail,name,nil,nil,nil,nil,error)
        }
        // 電波強度取得時のコールバック関数
        Bluetooth.shared.gotRSSI = {name,value in
            guard self.isSBMName(name) else {
                return
            }
            self.notify(SBMSDK.NotificationName.gotRSSI,name,nil,nil,nil,value! * -1,nil)
        }
        // 電波強度取得失敗時のコールバック関数
        Bluetooth.shared.getRSSIFail = {name,error in
            guard self.isSBMName(name) else {
                return
            }
            self.notify(SBMSDK.NotificationName.getRSSIFail,name,nil,nil,nil,nil,error)
        }
        // セントラルマネージャーの接続状態変化検出時コールバック関数
        Bluetooth.shared.changeCentralManagerState = {state in
            self.notify(SBMSDK.NotificationName.changeCentralManagerState,nil,nil,nil,nil,state,nil)
        }
        // 更新検知時のコールバック関数
        Bluetooth.shared.updated = {name,service_uuid,characteristic_uuid,value in
            guard self.isSBMName(name) else {
                return
            }
            self.recept(name, service_uuid, characteristic_uuid, value)
        }
        // 更新検知失敗時のコールバック関数
        Bluetooth.shared.notifyFail = {name,service_uuid,characteristic_uuid,error in
            guard self.isSBMName(name) else {
                return
            }
            self.notify(SBMSDK.NotificationName.notifyFail,name,service_uuid,characteristic_uuid,nil,nil,error)
        }
        // 購読完了時のコールバック関数
        Bluetooth.shared.subscribed = {name,service_uuid,characteristic_uuid in
            guard self.isSBMName(name) else {
                return
            }
            self.notify(SBMSDK.NotificationName.subscribed,name,service_uuid,characteristic_uuid,nil,nil,nil)
        }
        // 購読解除完了時のコールバック関数
        Bluetooth.shared.unsubscribed = {name,service_uuid,characteristic_uuid in
            guard self.isSBMName(name) else {
                return
            }
            self.notify(SBMSDK.NotificationName.unsubscribed,name,service_uuid,characteristic_uuid,nil,nil,nil)
        }
        // 購読／購読解除時のコールバック関数
        Bluetooth.shared.subscribeFail = {name,service_uuid,characteristic_uuid,error in
            guard self.isSBMName(name) else {
                return
            }
            self.notify(SBMSDK.NotificationName.subscribeFail,name,service_uuid,characteristic_uuid,nil,nil,error)
        }
        // ペリフェラルへの書き込み命令失敗時コールバック関数
        Bluetooth.shared.writeFail = {name,service_uuid,characteristic_uuid,descriptor_uuid,value,error in
            guard self.isSBMName(name) else {
                return
            }
            self.notify(SBMSDK.NotificationName.writeFail,name,service_uuid,characteristic_uuid,descriptor_uuid,value,error)
        }
        // 書き込み命令受信時のコールバック関数
        Bluetooth.shared.willWrite = {name,service_uuid,characteristic_uuid,oldValue in
            guard self.isSBMName(name) else {
                return
            }
            self.notify(SBMSDK.NotificationName.willWrite,name,service_uuid,characteristic_uuid,nil,oldValue,nil)
        }
        // 書き込み命令受信失敗時のコールバック関数
        Bluetooth.shared.willWriteFail = {name,service_uuid,characteristic_uuid,error in
            guard self.isSBMName(name) else {
                return
            }
            self.notify(SBMSDK.NotificationName.willWriteFail,name,service_uuid,characteristic_uuid,nil,nil,error)
        }
        // 書き込み完了時のコールバック関数
        Bluetooth.shared.didWrite = {name,service_uuid,characteristic_uuid,descriptor_uuid in
            guard self.isSBMName(name) else {
                return
            }
            self.notify(SBMSDK.NotificationName.didWrite,name,service_uuid,characteristic_uuid,descriptor_uuid,nil,nil)
        }
        // 書き込み失敗時のコールバック関数
        Bluetooth.shared.didWriteFail = {name,service_uuid,characteristic_uuid,descriptor_uuid,error in
            guard self.isSBMName(name) else {
                return
            }
            self.notify(SBMSDK.NotificationName.didWriteFail,name,service_uuid,characteristic_uuid,descriptor_uuid,nil,error)
        }
        // ペリフェラル検出時のコールバック関数
        Bluetooth.shared.discoverPeripheral = {name,rssi in
            guard self.isSBMName(name) else {
                return
            }
            self.notify(SBMSDK.NotificationName.discoverPeripheral,name,nil,nil,nil,rssi,nil)
        }
        Bluetooth.shared.discoverServices = {name,service_uuid,error in
            guard self.isSBMName(name) else {
                return
            }
            guard self.isSBMService(service_uuid) else {
                return
            }
            self.notify(SBMSDK.NotificationName.discoverServices,name,service_uuid,nil,nil,nil,error)
        }
        Bluetooth.shared.discoverCharacteristic = {name,characteristic_uuid,error in
            guard self.isSBMName(name) else {
                return
            }
            guard self.isSBMCharacteristic(characteristic_uuid) else {
                return
            }
            self.notify(SBMSDK.NotificationName.discoverCharacteristic,name,nil,characteristic_uuid,nil,nil,error)
        }
        Bluetooth.shared.isNotifyCharacteristic = {name,characteristic_uuid in
            guard self.isSBMName(name) else {
                return nil
            }
            guard self.isSBMCharacteristic(characteristic_uuid) else {
                return false
            }
            return true
        }
    }
    // 通知を送信する
    private func notify(_ notify_name:String,_ sbm_name:String?,_ service_uuid:String?,_ characteristic_uuid:String?,_ descriptor_uuid:String?,_ value:Any?,_ error: Error?) {
        let notifyName = Notification.Name(notify_name)
        let userInfo = [
            "NotificationName":notify_name,
            "SBM":sbm_name,
            "Service":service_uuid,
            "Characteristic":characteristic_uuid,
            "Descriptor":descriptor_uuid,
            "Error":error?.localizedDescription,
            "Value":value,
        ]
        if notify_name.hasPrefix(SBMSDK.NotificationName.recept) {
            print( "recept" )
        }
        NotificationCenter.default.post(name:notifyName, object: nil, userInfo: userInfo as [AnyHashable : Any])
    }
    // SBMの変更を検知する
    private func recept(_ name:String?,_ service_uuid:String?,_ characteristic_uuid:String?,_ value: Data?) {
        // nil判断
        guard value != nil else {
            let notifyName = SBMSDK.NotificationName.receptNilValue
            notify(notifyName,name,service_uuid,characteristic_uuid,nil,value,NSError(domain: notifyName, code: 0))
            return
        }
        // デコードを行う
        guard let decoded = String(data: value!, encoding: .utf8) else {
            let notifyName = SBMSDK.NotificationName.receptDecodeFail
            notify(notifyName,name,service_uuid,characteristic_uuid,nil,value,NSError(domain: notifyName, code: 0))
            return
        }
        // ターミネーター除外
        var replaced = decoded.replacingOccurrences(of: "\r\n", with: "")
        // SBMの情報通知か
        guard !isSBMInformation(decoded) else {
            notify(SBMSDK.NotificationName.receptIsSBMInformation,name,service_uuid,characteristic_uuid,nil,[replaced],nil)
            return
        }
        // RDSコマンドとアドレスの間にデリミタを挿入
        if replaced.hasPrefix("RDS") {
            let index = replaced.index(replaced.startIndex, offsetBy: 3)
            replaced.insert(contentsOf: SBMSDK.commandDelimiter, at: index)
        }
        // RDコマンドとアドレスの間にデリミタを挿入
        if !replaced.hasPrefix("RDS") && replaced.hasPrefix("RD") {
            let index = replaced.index(replaced.startIndex, offsetBy: 2)
            replaced.insert(contentsOf: SBMSDK.commandDelimiter, at: index)
        }
        // WRSコマンドとアドレスの間にデリミタを挿入
        if replaced.hasPrefix("WRS") {
            let index = replaced.index(replaced.startIndex, offsetBy: 3)
            replaced.insert(contentsOf: SBMSDK.commandDelimiter, at: index)
        }
        // WRコマンドとアドレスの間にデリミタを挿入
        if !replaced.hasPrefix("WRS") && replaced.hasPrefix("WR") {
            let index = replaced.index(replaced.startIndex, offsetBy: 2)
            replaced.insert(contentsOf: SBMSDK.commandDelimiter, at: index)
        }
        // 前後の空白を削除
        replaced = replaced.trimmingCharacters(in: .whitespaces)
        // デリミタで分割
        var values = replaced.components(separatedBy: SBMSDK.commandDelimiter)
        // アドレスの「:」を削除
        if values.count >= 2 && values[1].hasSuffix(":") {
            values[1] = String(values[1].dropLast())
        }
        // OK通知か
        if isOK(values) {
            notify(SBMSDK.NotificationName.receptIsOK,name,service_uuid,characteristic_uuid,nil,values,nil)
            return
        }
        // NG通知か
        if isNG(values) {
            notify(SBMSDK.NotificationName.receptIsNG,name,service_uuid,characteristic_uuid,nil,values,nil)
            return
        }
        // イレギュラーデータか
        if isIllegal(values) {
            let notifyName = SBMSDK.NotificationName.receptIsIllegal
            notify(notifyName,name,service_uuid,characteristic_uuid,nil,values,NSError(domain: notifyName, code: 0))
            return
        }
        // 空か
        if isEmpty(values) {
            notify(SBMSDK.NotificationName.receptIsEmpty,name,service_uuid,characteristic_uuid,nil,values,nil)
            return
        }
        // 履歴数か
        if isHistoryCount(values) {
            notify(SBMSDK.NotificationName.receptIsHistoryCount,name,service_uuid,characteristic_uuid,nil,values,nil)
            return
        }
        // ブザー音量か
        if isTone(values) {
            notify(SBMSDK.NotificationName.receptIsTone,name,service_uuid,characteristic_uuid,nil,values,nil)
            return
        }
        // 照度か
        if isBright(values) {
            notify(SBMSDK.NotificationName.receptIsBright,name,service_uuid,characteristic_uuid,nil,values,nil)
            return
        }
        // バッテリーレベルか
        if isBatteryLevel(values) {
            notify(SBMSDK.NotificationName.receptIsBatteryLevel,name,service_uuid,characteristic_uuid,nil,values,nil)
            return
        }
        // 計測結果か
        if isMeasureResult(values) {
            notify(SBMSDK.NotificationName.receptIsMeasureResult,name,service_uuid,characteristic_uuid,nil,values,nil)
            return
        }
        // 最新計測結果か
        if isLatestMeasureResult(values) {
            notify(SBMSDK.NotificationName.receptIsLatestMeasureResult,name,service_uuid,characteristic_uuid,nil,values,nil)
            return
        }
        // 日付か
        if isDate(values) {
            notify(SBMSDK.NotificationName.receptIsDate,name,service_uuid,characteristic_uuid,nil,values,nil)
            return
        }
        // 時刻か
        if isTime(values) {
            notify(SBMSDK.NotificationName.receptIsTime,name,service_uuid,characteristic_uuid,nil,values,nil)
            return
        }
        // 個別のRDコマンド結果か
        if isRD(values) {
            notify(SBMSDK.NotificationName.receptIsRD,name,service_uuid,characteristic_uuid,nil,values,nil)
            return
        }
        // 個別のRDSコマンド結果か
        if isRDS(values) {
            notify(SBMSDK.NotificationName.receptIsRDS,name,service_uuid,characteristic_uuid,nil,values,nil)
            return
        }
        // 個別のWRコマンド結果か
        if isWR(values) {
            notify(SBMSDK.NotificationName.receptIsWR,name,service_uuid,characteristic_uuid,nil,values,nil)
            return
        }
        // 個別のWRSコマンド結果か
        if isWRS(values) {
            notify(SBMSDK.NotificationName.receptIsWRS,name,service_uuid,characteristic_uuid,nil,values,nil)
            return
        }
        // 上記全てに該当しない内容か
        notify(SBMSDK.NotificationName.recept,name,service_uuid,characteristic_uuid,nil,values,nil)
    }
// MARK: - 判断
//------------------------------------------------------------------------
    private func isSBMInformation(_ value:String) -> Bool {
        guard value.hasPrefix("Skin barrier meter -01 ") else {
            return false
        }
        return true
    }
    // イレギュラーデータか
    private func isIllegal(_ values:[String]) -> Bool {
        guard values.count > 1 else {
            print( "isIllegal : " + values.joined(separator: ",") )
            return true
        }
        guard values[0].hasPrefix("RD") || values[0].hasPrefix("RDS") || values[0].hasPrefix("WR") || values[0].hasPrefix("WRS") else {
            print( "isIllegal : " + values.joined(separator: ",") )
            return true
        }
        guard values[0].count >= 2 else {
            print( "isIllegal : " + values.joined(separator: ",") )
            return true
        }
        return false
    }
    // 空か
    private func isEmpty(_ values:[String]) -> Bool {
        guard values[1] == "0.000" else {
            return false
        }
        return true
    }
    // OKか
    private func isOK(_ values:[String]) -> Bool {
        guard values[0] == "OK" else {
            return false
        }
        return true
    }
    // NGか
    private func isNG(_ values:[String]) -> Bool {
        guard values[0] == "NG" else {
            return false
        }
        return true
    }
    // RDコマンドか
    private func isRD(_ values:[String]) -> Bool {
        guard !values[0].hasPrefix("RDS") else {
            return false
        }
        guard values[0].hasPrefix("RD") else {
            return false
        }
        return true
    }
    // RDSコマンドか
    private func isRDS(_ values:[String]) -> Bool {
        guard values[0].hasPrefix("RDS") else {
            return false
        }
        return true
    }
    // WRコマンドか
    private func isWR(_ values:[String]) -> Bool {
        guard !values[0].hasPrefix("WRS") else  {
            return false
        }
        guard values[0].hasPrefix("WR") else {
            return false
        }
        return true
    }
    // WRSコマンドか
    private func isWRS(_ values:[String]) -> Bool {
        guard values[0].hasPrefix("WRS") else {
            return false
        }
        return true
    }
    // 測定結果か
    private func isMeasureResult(_ values:[String]) -> Bool {
        guard values[0] == "RD" else {
            return false
        }
        let address:Int = Int(values[1], radix: 16)!
        guard 0x0500 <= address && address <= 0x0564 else {
            return false
        }
        guard values.count >= 10 else {
            return false
        }
        return true
    }
    // 最新測定結果か
    private func isLatestMeasureResult(_ values:[String]) -> Bool {
        guard values[0] == "RDS" else {
            return false
        }
        guard values[1] == "0566" else {
            return false
        }
        guard values.count == 10 else {
            return false
        }
        return true
    }
    // 日付か
    private func isDate(_ values:[String]) -> Bool {
        guard values[0] == "RD" else {
            return false
        }
        guard values[1] == "00F1" else {
            return false
        }
        guard values.count == 3 else {
            return false
        }
        return true
    }
    // 時刻か
    private func isTime(_ values:[String]) -> Bool {
        guard values[0] == "RD" else {
            return false
        }
        guard values[1] == "00F2" else {
            return false
        }
        guard values.count == 3 else {
            return false
        }
        return true
    }
    // ブザー音量か
    private func isTone(_ values:[String]) -> Bool {
        guard values[0] == "RD" else {
            return false
        }
        guard values[1] == "00FB" else {
            return false
        }
        guard values.count == 3 else {
            return false
        }
        return true
    }
    // 照度か
    private func isBright(_ values:[String]) -> Bool {
        guard values[0] == "RD" else {
            return false
        }
        guard values[1] == "00FC" else {
            return false
        }
        guard values.count == 3 else {
            return false
        }
        return true
    }
    // バッテリーレベルか
    private func isBatteryLevel(_ values:[String]) -> Bool {
        guard values[0] == "RD" else {
            return false
        }
        guard values[1] == "00FD" else {
            return false
        }
        return true
    }
    // 履歴数か
    private func isHistoryCount(_ values:[String]) -> Bool {
        guard values[0] == "RD" else {
            return false
        }
        guard values[1] == "00FE" else {
            return false
        }
        return true
    }
    private func isSBMName(_ name:String?) -> Bool {
        guard name!.prefix(2) == "RN" else {
            return false
        }
        return true
    }
    private func isSBMService(_ uuid:String?) -> Bool {
        guard uuid == SBMSDK.UUID.Service else {
            return false
        }
        return true
    }
    private func isSBMCharacteristic(_ uuid:String?) -> Bool {
        guard uuid == SBMSDK.UUID.Characteristic || uuid == SBMSDK.UUID.Service || uuid == SBMSDK.UUID.periheral else {
            return false
        }
        return true
    }
// MARK: - 基本機能実装
//------------------------------------------------------------------------
    // SBMのスキャンを開始する
    public func startScan() {
        Bluetooth.shared.startScan()
    }
    // SBMのスキャンを停止する
    public func stopScan() {
        Bluetooth.shared.stopScan()
    }
    // SBMに接続する
    public func connect(_ name:String) {
        Bluetooth.shared.connect(name)
    }
    // SBMとの接続を解除する
    public func disconnect(_ name:String) {
        Bluetooth.shared.disconnect(name)
    }
    // SBMから電波強度を取得する
    public func getRSSI(_ name:String) {
        Bluetooth.shared.getRSSI(name)
    }
    // コマンド文を作成して返す（RD用）
    private func createCommandForRD(_ address:Int) -> Data {
        let hexStr = String(format: "%04X", address)
        let command = "RD \(hexStr)"
        print("SBMSDK Bluetooth COMMAND : \(command)")
        let commandStr = "\(SBMSDK.commandPrefix)\(command)\(SBMSDK.commandSuffix)"
        let result = commandStr.data(using: .ascii)!
        return result
    }
    // SBMに値取得を要求する（単一データ）
    public func requestRD(_ name:String,_ address:Int) {
        let command = createCommandForRD(address)
        print("SBMSDK Bluetooth COMMAND : \(command)")
        Bluetooth.shared.write(name, SBMSDK.UUID.Service, SBMSDK.UUID.Characteristic, command)
    }
    // コマンド文を作成して返す（RDS用）
    private func createCommandForRDS(_ address:Int,_ length:Int) -> Data {
        let hexStr = String(format: "%04X", address)
        let command = "RDS \(hexStr) \(length)"
        print("SBMSDK Bluetooth COMMAND : \(command)")
        let commandStr = "\(SBMSDK.commandPrefix)\(command)\(SBMSDK.commandSuffix)"
        let result = commandStr.data(using: .ascii)!
        return result
    }
    // SBMに値取得を要求する（複数の連続データ）
    public func requestRDS(_ name:String,_ address:Int,_ length:Int) {
        let command = createCommandForRDS(address,length)
        Bluetooth.shared.write(name, SBMSDK.UUID.Service, SBMSDK.UUID.Characteristic, command)
    }
    // コマンド文を作成して返す（WR用）
    private func createCommandForWR(_ address:Int,_ value:String) -> Data {
        let hexStr = String(format: "%04X", address)
        let command = "WR \(hexStr) \(value)"
        print("SBMSDK Bluetooth COMMAND : \(command)")
        let commandStr = "\(SBMSDK.commandPrefix)\(command)\(SBMSDK.commandSuffix)"
        let result = commandStr.data(using: .ascii)!
        return result
    }
    // SBMに書き込みを要求する（単一データ）
    public func requestWR(_ name:String,_ address:Int,_ value:String) {
        let command = createCommandForWR(address,value)
        Bluetooth.shared.write(name, SBMSDK.UUID.Service, SBMSDK.UUID.Characteristic, command)
        requestRD(name, address)
    }
    // コマンド文を作成して返す（WRS用）
    private func createCommandForWRS(_ address:Int,_ values:[String]) -> Data {
        let hexStr = String(format: "%04X", address)
        let value = values.joined(separator: SBMSDK.commandDelimiter)
        let length = values.count
        let command = "WRS \(hexStr) \(length) \(value)"
        print("SBMSDK Bluetooth COMMAND : \(command)")
        let commandStr = "\(SBMSDK.commandPrefix)\(command)\(SBMSDK.commandSuffix)"
        let result = commandStr.data(using: .ascii)!
        return result
    }
    // SBMに書き込みを要求する（複数の連続データ）
    public func requestWRS(_ name:String,_ address:Int,_ values:[String]) {
        let command = createCommandForWRS(address,values)
        Bluetooth.shared.write(name, SBMSDK.UUID.Service, SBMSDK.UUID.Characteristic, command)
        requestRDS(name, address, values.count)
    }
// MARK: - モード別仕様
//------------------------------------------------------------------------
    // 計測器独立モードに変更する
    public func setupStandaloneMode(_ name:String) {
        requestWR(name,0x00F0,"0")
    }
    // 計測器通信モードに変更する
    public func setupCommunicationMode(_ name:String) {
        requestWR(name,0x00F0,"1")
    }
    // 計測器履歴モードに変更する
    public func setupHistoryMode(_ name:String) {
        requestWR(name,0x00F0,"3")
    }
// MARK: - 特別機能
//------------------------------------------------------------------------
    // バージョン情報取得
    public func getDeviceInformation(_ name:String) {
        requestRD(name,0x0000)
    }
    // バージョン情報取得
    public func getDeviceNo(_ name:String) {
        requestRD(name,0x0001)
    }
    // バージョン情報取得
    public func getMcuVersion(_ name:String) {
        requestRD(name,0x0002)
    }
    // バージョン情報取得
    public func getMcuBuildNumber(_ name:String) {
        requestRD(name,0x0003)
    }
    // バージョン情報取得
    public func getMcuBuildDate(_ name:String) {
        requestRD(name,0x0004)
    }
    // バージョン情報取得
    public func getFpgaVersion(_ name:String) {
        requestRD(name,0x0005)
    }
    // 動作状態取得
    public func getStatus(_ name:String) {
        requestRD(name,0x0010)
    }
    // 測定進捗取得
    public func getProgress(_ name:String) {
        requestRD(name,0x0013)
    }
    // 測定結果ステータス取得
    public func getMeasureResultStatus100Hz(_ name:String) {
        requestRD(name,0x0014)
    }
    // 測定結果ステータス取得
    public func getMeasureResultStatus500Hz(_ name:String) {
        requestRD(name,0x0015)
    }
    // 測定結果ステータス取得
    public func getMeasureResultStatus1kHz(_ name:String) {
        requestRD(name,0x0016)
    }
    // 測定結果ステータス取得
    public func getMeasureResultStatus100kHz(_ name:String) {
        requestRD(name,0x0017)
    }
    // 測定開始(電気的計測測定)
    public func doMeasure(_ name:String) {
        requestWR(name,0x0020,"1")
    }
    // 測定モード
    public func getMode(_ name:String) {
        requestRD(name,0x0021)
    }
    // 測定許可
    public func getEnable(_ name:String) {
        requestRD(name,0x0022)
    }
    // 日付時刻取得
    public func getDate(_ name:String) {
        requestRD(name,0x00F1)
    }
    // 日付時刻取得
    public func getTime(_ name:String) {
        requestRD(name,0x00F2)
    }
    // 日付時刻設定
    public func setDate(_ name:String) {
        let nowDate = Date()
        let formater = DateFormatter()
        let locale = Locale(identifier: "ja_JP")
        formater.dateFormat = DateFormatter.dateFormat(fromTemplate: "yyyy/MM/dd", options: 0, locale: locale)
        let dateStr = formater.string(from: nowDate)
        requestWR(name,0x00F1,dateStr)
    }
    // 日付時刻設定
    public func setTime(_ name:String) {
        let nowDate = Date()
        let formater = DateFormatter()
        let locale = Locale(identifier: "ja_JP")
        formater.dateFormat = DateFormatter.dateFormat(fromTemplate: "HH:mm:ss", options: 0, locale: locale)
        let timeStr = formater.string(from: nowDate)
        requestWR(name,0x00F2,timeStr)
    }
    // 被測定者情報取得
    public func getSubjectId(_ name:String) {
        requestRD(name,0x00F3)
    }
    // 被測定者情報取得
    public func getSubjectAge(_ name:String) {
        requestRD(name,0x00F4)
    }
    // 被測定者情報取得
    public func getSubjectName(_ name:String) {
        requestRD(name,0x00F5)
    }
    // 被測定者情報設定
    public func setSubjectInformation(_ name:String,_ subjectId:String,_ subjectName:String,_ subjectAge:Int) {
        requestWR(name,0x00F3,subjectId)
        requestWR(name,0x00F4,String(subjectAge))
        requestWR(name,0x00F5,subjectName)
    }
    // 装置名称取得
    public func getName(_ name:String) {
        requestRD(name,0x00F8)
    }
    // 装置名称変更
    public func setName(_ name:String,_ after:String) {
        requestWR(name,0x00F8,after)
    }
    // 測定回数取得
    public func getMeasureCount(_ name:String) {
        requestRD(name,0x00FA)
    }
    // 測定回数変更
    public func setMeasureCount(_ name:String,_ after:Int) {
        requestWR(name,0x00FA,String(after) )
    }
    // ブザー音量変更
    public func getTone(_ name:String) {
        requestRD(name,0x00FB)
    }
    // ブザー音量変更
    public func setTone(_ name:String,_ after:Int) {
        requestWR(name,0x00FB,String(after) )
    }
    // 照度取得
    public func getBright(_ name:String) {
        requestRD(name,0x00FC)
    }
    // 照度変更
    public func setBright(_ name:String,_ after:Int) {
        requestWR(name,0x00FC,String(after) )
    }
    // バッテリー残量取得
    public func getBatteryLevel(_ name:String) {
        requestRD(name,0x00FD)
    }
    // 履歴数取得
    public func getHistoryCount(_ name:String) {
        requestRD(name,0x00FE)
    }
    // 履歴全消去
    public func removeHistoryAll(_ name:String) {
        requestWR(name,0x00FF,"4444")
    }
    // 履歴数取得
    public func getHistory(_ name:String,_ count:Int) {
        // 後ろから一つずつ読む
        let startAddress = 0x0500 + count - 1
        for i in 0..<count {
            let doAddress = startAddress - i
            requestRD(name,doAddress)
        }
    }
// MARK: - Getter
//------------------------------------------------------------------------
    public func getPeripheralNames() -> [String] {
        let names = Bluetooth.shared.getPeripheralNames(nil)
        var result:[String] = []
        for name in names {
            if isSBMName(name) {
                result.append(name)
            }
        }
        return result
    }
}
// MARK: - 関連
// 関連するUUID
public struct SBMUUID {
    let periheral = "F2CBAD10-BBBD-8710-690A-A8BAC182A30B"
    let Service = "49535343-FE7D-4AE5-8FA9-9FAFD205E455"
    let Characteristic = "49535343-1E4D-4BD9-BA61-23C647249616"
}
// 関連する通知名
public struct SBMNotificationName {
    let connected = "SBMSDK Bluetooth connected"
    let connectFail = "SBMSDK Bluetooth connectFail"
    let disconnected = "SBMSDK Bluetooth disconnected"
    let disconnectFail = "SBMSDK Bluetooth disconnectFail"
    let gotRSSI = "SBMSDK Bluetooth gotRSSI"
    let getRSSIFail = "SBMSDK Bluetooth getRSSIFail"
    let changeCentralManagerState = "SBMSDK Bluetooth changeCentralManagerState"
    let notifyFail = "SBMSDK Bluetooth notifyFail"
    let subscribed = "SBMSDK Bluetooth subscribed"
    let unsubscribed = "SBMSDK Bluetooth unsubscribed"
    let subscribeFail = "SBMSDK Bluetooth subscribeFail"
    let writeFail = "SBMSDK Bluetooth writeFail"
    let willWrite = "SBMSDK Bluetooth willWrite"
    let willWriteFail = "SBMSDK Bluetooth willWriteFail"
    let didWrite = "SBMSDK Bluetooth didWrite"
    let didWriteFail = "SBMSDK Bluetooth didWriteFail"
    let discoverPeripheral = "SBMSDK Bluetooth discoverPeripheral"
    let receptNilValue = "SBMSDK Bluetooth recept nil value"
    let receptDecodeFail = "SBMSDK Bluetooth recept decode fail"
    let receptIsIllegal = "SBMSDK Bluetooth recept isIllegal"
    let receptIsEmpty = "SBMSDK Bluetooth recept isEmpty"
    let receptIsOK = "SBMSDK Bluetooth recept isOK"
    let receptIsNG = "SBMSDK Bluetooth recept isNG"
    let receptIsMeasureResult = "SBMSDK Bluetooth recept isMeasureResult"
    let receptIsLatestMeasureResult = "SBMSDK Bluetooth recept isLatestMeasureResult"
    let receptIsDate = "SBMSDK Bluetooth recept isDate"
    let receptIsTime = "SBMSDK Bluetooth recept isTime"
    let receptIsRD = "SBMSDK Bluetooth recept isRD"
    let receptIsRDS = "SBMSDK Bluetooth recept isRDS"
    let receptIsWR = "SBMSDK Bluetooth recept isWR"
    let receptIsWRS = "SBMSDK Bluetooth recept isWRS"
    let receptIsSBMInformation = "SBMSDK Bluetooth recept isSBMInformation"
    let receptIsTone = "SBMSDK Bluetooth recept isTone"
    let receptIsBright = "SBMSDK Bluetooth recept isBright"
    let receptIsBatteryLevel = "SBMSDK Bluetooth recept isBatteryLevel"
    let receptIsHistoryCount = "SBMSDK Bluetooth recept isHistoryCount"
    let recept = "SBMSDK Bluetooth recept"
    let discoverServices = "SBMSDK Bluetooth discoverServices"
    let discoverCharacteristic = "SBMSDK Bluetooth discoverCharacteristic"
}
