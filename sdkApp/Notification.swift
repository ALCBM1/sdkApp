//
//  Notification.swift
//  SbmSdk
//
//  Created by Yurie Shibata on 2022/08/01.
//

import Foundation

extension Notification.Name {
    //測定したデータの通知
    static let blueToothData = Notification.Name("blueToothData")
    static let blueToothNotify = Notification.Name("Notify")
    static let getMeasureData = Notification.Name("getMeasureData")
    static let getPeriferalNotify = Notification.Name("getPeriferalNotify") //ペリフェラルを検知した際に使用
    static let getVersionNotify = Notification.Name("getVersionNotify")
    static let getBatteryNotify = Notification.Name("getBatteryNotify")
    static let getHistoryNotify = Notification.Name("getHistoryNotify") //履歴に変更があった際使用
    static let getHistoryNumNotify = Notification.Name("getHistoryNumNotify") //履歴件数に変更があった際使用
    static let getLogNotify = Notification.Name("getLogNotify") //ログファイルを取得した際使用
    static let getRssiNotify = Notification.Name("getRssiNotify")
    static let getReadNotify = Notification.Name("getReadNotify")
    static let getTouchErrorNotify = Notification.Name("getTouchErrorNotify")
    static let getMeasureErrorNotify = Notification.Name("getMeasureErrorNotify")
    static let getIllegalDataNotify = Notification.Name("getIllegalDataNotify")
    static let setSBMRTCNotify = Notification.Name("setSBMRTCNotify")//日付情報を設定した際に使用
    static let setSBMToneNotify = Notification.Name("setSBMToneNotify")//音量を設定した際に使用
    static let setSBMDispNotify = Notification.Name("setSBMDispNotify")//輝度を設定した際に使用
    static let blueToothDisConnectNotify = Notification.Name("blueToothDisConnectNotify")
    static let notConnectErrorNotify = Notification.Name("notConnectErrorNotify")
    static let startBLEConnectionNotify = Notification.Name("startBLEConnectionNotify")
    static let startBLEWriteNotify = Notification.Name("startBLEWriteNotify")
    static let startReadNotify = Notification.Name("startReadNotify")
    static let startMeasureNotify = Notification.Name("startMeasureNotify")
    static let startMeasureStatusNotify = Notification.Name("startMeasureStatusNotify")//計測開始の可否を取得した際使用
    static let startCharacteristicConnectionNotify = Notification.Name("startCharacteristicConnectionNotify")
    static let finishReadNotify = Notification.Name("finishReadNotify") //履歴を呼び出した際に使用

}
