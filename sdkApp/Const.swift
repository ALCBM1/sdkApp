//
//  Const.swift
//  SbmSdk
//
//  Created by Yurie Shibata on 2022/07/21.
//

import Foundation
import UIKit

struct Const {

    //MARK: - title
    static let deviceConstName = "RN"
    static let hexadimalUnit = 16
    static let hexaMax = 100
    static let idMax = 999999999999
    static let illegalTitle = "Illegal data received."
    static let illegalNilTitle = "Illegal(nil) data received."
    static let incorrectCommand = "不適切なコマンドです。"
    static let incorrectSetValue = "この値は設定できません。"
    static let nothingSetValue = "コマンドに設定値がありません。"
    //MARK: - APIComamnd
    //SDK入力コマンド
    static let getSystemVersion = "Get_System version"
    static let getLog = "Get_Log"
    static let getBTCondition = "Get_BT-Condition"
    static let setBTSBMPairing = "Set_BT-SBM pairing"
    static let setBTSBMDisconnect = "Set_BT-SBM disconnect"
    static let getSBMBattery = "GetSBM-BATT"
    static let setSBMIpadDate = "Set_SBM-RTC"
    static let setSBMTone = "SetSBM-Tone"
    static let setSBMDisp = "SetSBM-Disp"
    static let setSBMMode = "Set_SBM-Mode"
    static let setSBMRemoteStart = "Set_SBM-RemoteStart"
    static let getSBMSingleData = "Get_SBM-StackedData-Single"
    static let getSBMStackedData = "Get_SBM-StackedData"
    static let getSBMStackedDataNum = "Get_SBM-StackedData-Num"
    static let deleteSBMStackedData = "Get_SBM-StackedData-Del"
    //MARK: - command
    //データの読み出しコマンド
    static let getDataheader = "RD "
    static let getRdZeroHeader = "RD0"
    static let modelVersionCommand = "RD 0000 "
    static let serialVersionCommand = "RD 0001 "
    static let mcuVersionCommand = "RD 0002 "
    static let fpgaVersionCommand = "RD 0005 "
    static let versionRead = "Read"
    static let pollingCommand = "RD 0010"
    static let smallStatusCommand = "RD 0015"
    static let largeStatusCommand = "RD 0017"
    static let ipadDateCommand = "WR 00F1 "
    static let ipadTimeCommand = "WR 00F2 "
    static let goModeZero = "WR 00F0 0"
    static let goModeOne = "WR 00F0 1"
    static let goModeTwo = "WR 00F0 2"
    static let goModeThree = "WR 00F0 3"
    static let getIpadDate = "RD 00F1"
    static let getIpadTime = "RD 00F2"
    static let dataSeparatStr = ":"
    static let batteryCommand = "RD 00FD"
    static let historyCommand = "RD 00FE"
    static let rdReadStartNum = 500
    static let latestHistoryCommand = "RD 0566"
    static let startMeasureStatusCommand = "WR 0020 1"
    static let startMeasureCommand = "WR 0022 1"
    static let initMeasureCommand = "WR 0022 0"
    static let headStatusPollingCommand = "RD 0012"
    static let deletePollingCommand = "WR 00FF 4444"
    static let setUserIdCommand = "WR 00F3 "
    static let soundCommand = "WR 00FB "
    static let lightCommand = "WR 00FC "
    static let measureCommand = "WR 0020 1"
    static let measureErrorCode = "3"
    static let measureErrorCodeFive = "5"
    static let oneCommondNum = 1
    static let twoCommondNum = 2
    static let fiveCommondNum = 5
    static let tenCommondNum = 10
    static let lastData = " 0.000 0.000 0.000 0.000 0.000 0.000 0.000 0.000 \r\n"
    static let standardTimeoutCnt = 3
    static let timeOutInterval = 3.0
    static let lateTime = 0.5
    static let startMeasureStatus = "OK\r\n"
    static let startMeasureErrorStatus = "NG\r\n"
    //MARK: - dateformat
    static let scheduleFormat = "yyyy/MM/dd"
    static let ipadTimeFormat = "HH:mm:ss"
    //MARK: - nsuserdefault
    static let isDeleteKey = "isDelete"
    static let readResultKey = "readResultKey"
    //MARK: - bluetooth
    static let periheralId = "F2CBAD10-BBBD-8710-690A-A8BAC182A30B"
    static let periheralServiceId = "49535343-FE7D-4AE5-8FA9-9FAFD205E455"
    static let periheralWriteId = "49535343-1E4D-4BD9-BA61-23C647249616"
    //MARK: - log
    static let errorLogMaxNum = 100
    static let accessLogMaxNum = 10000
    static let Logs: [LogType] = [.Result, .Error, .System]
    static let ErrorStatus:[String] = ["正常", "発振波形異常", "受信波形異常", "波高値下限越え", "波高値上限越え", "過電流検出", "リトライ1回", "計算エラー"]

    //ログタイプに対応する出力ファイル名
    enum LogType:String{
        case Result = "ResultLog.txt"//測定エラー
        case Error = "ErrorLog.txt"//その他のエラー
        case System = "SystemLog.txt"//APIコマンドアクセス
    }

    //SBMの測定状態タイプ
    enum sbmMeasureStatus:Int{
        case stop = 0//停止
        case measuring = 1//測定中
        case touchError = 3//タッチエラー
    }
    
    //端末の設定タイプ
    enum DeviceSettingType:Int{
        case sound = 1//音量
        case light = 2//輝度
    }
        
    //MARK: - logic
    //SBMからのタイムをdateに変換する。
    static func changeTimeFloatToStr(time:Double,standardDate:Date?)->Date?{
        if let sdate = standardDate{
            let modifiedDate = Calendar(identifier: .japanese).date(byAdding: .second, value: Int(time), to: sdate)
            return modifiedDate
        }
        return nil
//        let str = getTimeStr(time: time)
//        let now = Date()
//        let nowStr = now.getDateStr(format: Const.scheduleFormat)
//
//        let all = nowStr + " " + str
//        return all.getDateFromStr(format: Const.csvDateFormat)
    }
}
