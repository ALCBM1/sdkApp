//
//  ApiCommand.swift
//  SbmSdk
//
//  Created by Yurie Shibata on 2022/08/05.
//

import Foundation

class APICommand: ObservableObject {
    public static let shared = APICommand()
    let log = Log()

    /// viewで入力されたコマンドを実行する
    /// - parameters command: コマンド
    func execute(command: String){
        //入力コマンドを保管
        DataParse.shared.inputCommand = command
        log.logger(type: Const.LogType.System, date: Date(), log: command, error: "")

        //データ取得関連コマンド
        if command == Const.getSystemVersion {
            // システム情報取得
            DataParse.shared.getSystemVersion()
        } else if command == Const.getLog {
            //ログ・履歴情報取得
            // ファイルアプリ内のログ履歴参照
            DataParse.shared.getLog()
        } else if command == Const.getBTCondition {
            //SBM通信接続
            Bluetooth.shared.initialize(nil)
//            Bluetooth.shared.setCentralManager()
            Bluetooth.shared.startScan()
        } else if command == Const.getSBMBattery {
            //SBM機器の現在のバッテリー残量レベルを受信する。
            DataParse.shared.getBattery()
        } else if command == Const.getSBMSingleData {
            //SBM機器から最新の測定結果を受信する。
            DataParse.shared.getSingleHistory()
        } else if command == Const.getSBMStackedData {
            //SBM 機器からOFF LINE 時などに保存された測定結果を受信する。最大100件のデータ
            DataParse.shared.getAllHistory()
        } else if command == Const.getSBMStackedDataNum {
            //SBM 機器からOFF LINE 時などに保存された測定結果の件数を受信する。
            DataParse.shared.getOneHistoryNumber()
        }

        //SBM設定関連コマンド
        if command == Const.setBTSBMDisconnect {
//            Bluetooth.shared.terminateBLE()
            if DataParse.shared.tmpDeviceName != nil {
                Bluetooth.shared.disconnect(DataParse.shared.tmpDeviceName!)
                DataParse.shared.tmpDeviceName = nil
                DataParse.shared.batteryCnt = nil
                Bluetooth.shared.startScan()
            }
        } else if command == Const.setSBMRemoteStart {
            //アプリからSBM 機器に対して“測定開始”を送信する。
            DataParse.shared.initPolling()
        }  else if command == Const.deleteSBMStackedData {
            //SBM 機器からOFF LINE 時などに保存された測定結果を全て消去する。
            DataParse.shared.deleteAllHistory()
        }

        if command.contains(Const.setBTSBMPairing) {
            //指定したSBM機器とBluetooth接続を行う。
            self.connectSBMDevice(command: command)
        } else if command.contains(Const.setSBMIpadDate) {
            //BT接続時にSBM機器へiPad のシステム日時・時刻を送信する。
            DataParse.shared.setIpadTime()
        } else if command.contains(Const.setSBMTone) {
            //SBM機器へ音量レベルを送信する。
            self.setToneDispSettings(command: command, seg: 1)
        } else if command.contains(Const.setSBMDisp) {
            //SBM機器へ輝度レベルを送信する。
            self.setToneDispSettings(command: command, seg: 2)
        } else if command.contains(Const.setSBMMode) {
            //SBM機器の動作モードを送信・設定する。
            self.setModeChange(command: command)
        }
    }

    // MARK: - コマンドの設定値チェック
    /// コマンド指定の数値を取り出す
    /// - parameters str: 数値入り文字列
    func extractingNumbers(str: String) -> String {
        let splitCommand = str.components(separatedBy: NSCharacterSet.decimalDigits.inverted)
        return splitCommand.joined()
    }

    /// 音量・輝度設定
    /// - parameters command: コマンド
    /// - parameters seg: 1 音量、2 輝度
    func setToneDispSettings(command: String, seg: Int) {
        let settingNumberStr = self.extractingNumbers(str: command)
        do {
            if seg == 1 {
                try self.checkToneSettingValue(value: settingNumberStr)
            } else {
                try self.checkDispSettingValue(value: settingNumberStr)
            }
            DataParse.shared.pushSegmentV(seg, selectValue: Int(settingNumberStr)!)
        } catch {
            print("*******************************************************")
            print("throw error : ")
            print(error)
            print("command : ", command)
        }
    }

    /// 計測モード変更
    /// - parameters command: コマンド
    func setModeChange(command: String) {
        let settingNumberStr = self.extractingNumbers(str: command)
        do {
            try checkModeChange(value: settingNumberStr)
            switch settingNumberStr {
            case Const.goModeZero:
                SBMSDK.shared.setupStandaloneMode(DataParse.shared.tmpDeviceName!)
                break
            case Const.goModeOne:
                SBMSDK.shared.setupCommunicationMode(DataParse.shared.tmpDeviceName!)
                break
            case Const.goModeThree:
                SBMSDK.shared.setupHistoryMode(DataParse.shared.tmpDeviceName!)
                break
            default:
                break
            }
        } catch {
            print("*******************************************************")
            print("throw error : ")
            print(error)
            print("command : ", command)
        }
    }

    /// 指定したSBMデバイスをBluetooth接続する
    /// - parameters command: コマンド
    func connectSBMDevice(command: String) {
        //コマンドからデバイス名を取り出す
        var selectedDevice = command.replacingOccurrences(of: Const.setBTSBMPairing, with: "")
        let delStr: Set<Character> = ["[","]"]
        selectedDevice.removeAll(where: { delStr.contains($0) })
        //デバイス名を接続用変数にセットする
        DataParse.shared.tmpDeviceName = selectedDevice.deleteWhiteSpace()
    }


    // MARK: - 設定値のチェック
    /// 音量の設定値チェック
    /// - parameters value: 設定値の文字列
    func checkToneSettingValue(value: String) throws {
        if value == "" {
            // コマンドに設定値がない場合は処理中断
            throw NSError(domain: "コマンドに設定値がありません。", code: -1, userInfo: nil)
        } else if Int(value)! < 0 || Int(value)! > 4 {
            // コマンドの設定値が0〜3以外の場合は処理中断
            throw NSError(domain: "この値は設定できません。", code: -1, userInfo: nil)
        }
    }

    /// 輝度の設定値チェック
    /// - parameters value: 設定値の文字列
    func checkDispSettingValue(value: String) throws {
        if value == "" {
            // コマンドに設定値がない場合は処理中断
            throw NSError(domain: "コマンドに設定値がありません。", code: -1, userInfo: nil)
        } else if Int(value)! < 2 || Int(value)! > 5 {
            // コマンドの設定値が2〜4以外の場合は処理中断
            throw NSError(domain: "この値は設定できません。", code: -1, userInfo: nil)
        }
    }

    /// 計測モードの設定値チェック
    /// - parameters value: 設定値の文字列
    func checkModeChange(value: String) throws {
        if value == "" {
            // コマンドに設定値がない場合は処理中断
            throw NSError(domain: "コマンドに設定値がありません。", code: -1, userInfo: nil)
        } else if Int(value)! < 0 || Int(value)! > 3 || Int(value) == 2 {
            // コマンドの設定値が0、1、３以外の場合は処理中断
            throw NSError(domain: "この値は設定できません。", code: -1, userInfo: nil)
        }
    }
}
