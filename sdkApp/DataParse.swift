//
//  CommonController.swift
//  SbmSdk
//
//  Created by Yurie Shibata on 2022/07/25.
//

import Foundation
import AudioToolbox

class DataParse: ObservableObject {

    public static let shared = DataParse()
    let log = Log()
    //SBMに送った日付文字列
    var ipadDate:String?
    //タイムアウトしたかを表すフラグ
    var isTimeout = false
    //連続何回タイムアウトしたかを表す。
    var timeoutCnt =  0
    //BLEタイムアウト時に再度送信するコマンド
    var restartCommand = ""
    //ヘッドのポーリングが可能かどうかを表す
    var isEnableHeadPolling = false
    //測定状態の一時的な保持
    var tmpMeasureStatus:Int = 0
    //測定エラー時にtmpHistoryのカウントをあげるかを判定。trueの場合にあげる
    var isfirstMeasureError = true
    //履歴件数をとるポーリングを終わらせるフラグ
    var historyPollingTimer:Timer?
    //測定状態を決定するポーリング
    var measurePollingTimer:Timer?
    //残数のポーリング確認用
    var tmpHistoryCnt:Int? = nil
    //データ取得時のアドレス
    var commandNum:Int = 0
    //読み取ったデータを一時保管。2回同じデータを読んで検証するため。
    var tmpSameData:String = ""
    //ログ用計測結果の一時的な保持
    var tmpLogData:String = ""
    //履歴から読み取った全データ配列
    var readResults:[String] = []
    var readResult:[String:String] = [:]
    //履歴を1件だけ取得する場合
    var oneHitoryFlg = false
    //取得したシステム情報を格納する配列
    var readVersions:[String] = []
    var historyCnt:Int? = nil{
        didSet{
            if let historyNum = historyCnt {
                //履歴数の変更があったら通知を出す。
                NotificationCenter.default.post(name:.getHistoryNumNotify, object: nil, userInfo: [Const.readResultKey:"\(String(describing: historyNum))(件)"])
            }
        }
    }
    var batteryCnt:Int? = nil{
        didSet{
            if let bat = batteryCnt {
                //バッテリーの変更があったら通知を出す。
                NotificationCenter.default.post(name:.getBatteryNotify, object: nil, userInfo: [Const.readResultKey:"\(String(describing: bat))(%)"])
            }
        }
    }
    //読み取り完了した時に立てるフラグ
    var readFinishFlg:Bool = false{
        didSet{
            if readFinishFlg && !oldValue {
                //読み取り完了時の通知
                NotificationCenter.default.post(name:.finishReadNotify, object: nil,userInfo: [
                    Const.isDeleteKey:false,
                    Const.readResultKey:self.readResults
                ])
            }
        }
    }
    //選択したデバイスを一時保持
    var tmpDeviceName: String?
    //実行中の入力コマンド
    var inputCommand: String = ""

    let startSoundId:SystemSoundID = 1000
    let endSoundId:SystemSoundID = 1000
    let sendSoundId:SystemSoundID = 1001
    let testSoundId:SystemSoundID = 1001
    let finishSoundId:SystemSoundID = 1002
    let centralSoundId:SystemSoundID = 1003


    //MARK: - 初期化・終了処理
    //測定初期化
    func initMeasure(isRead:Bool){
        if !isRead{
            //読み込み場面の場合は読み込み完了まで時間を送らない。
            setIpadTime()
        }

//        self.setMultiCommand(command: Const.getIpadDate, num: 5)
        SBMSDK.shared.getDate(DataParse.shared.tmpDeviceName!)
        getOneHistoryNumber()

        //BLEに接続されていない場合はアラートを表示する。
//        if !Bluetooth.shared.isConnect{
//            NotificationCenter.default.post(name:.notConnectErrorNotify, object: nil)
//        }
    }

    /// 読み取り開始時の処理
    func initRead(){
        readResults = []
        readFinishFlg = false
    }

    ///ポーリング開始
    func initPolling(){
//        self.setMultiCommand(command: Const.startMeasureStatusCommand, num: 5)
        SBMSDK.shared.doMeasure(DataParse.shared.tmpDeviceName!)
        startAllTimer()
//        changeMode(modeStr: Const.goModeThree)
        SBMSDK.shared.setupCommunicationMode(DataParse.shared.tmpDeviceName!)
        setIpadTime()
    }


    //MARK: - timer
    /// - parameters timer:
    @objc func pollingHistory(timer: Timer){
//        self.writeTextData(Const.historyCommand)
        SBMSDK.shared.getHistory(DataParse.shared.tmpDeviceName!, 100)
        //測定状態の取得
//        self.writeTextData(Const.pollingCommand)
        SBMSDK.shared.getStatus(DataParse.shared.tmpDeviceName!)
    }

    /// - parameters timer:
    @objc func pollingMeasure(timer: Timer){
//        self.writeTextData(Const.pollingCommand)
        SBMSDK.shared.getStatus(DataParse.shared.tmpDeviceName!)
    }

    /// 履歴数取得ポーリング
    func createPollingHistoryTimer(){
        stopPollingHistoryTimer()
        historyPollingTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.pollingHistory(timer:)), userInfo: nil, repeats: true)
//        if let timer = historyPollingTimer{
//            if !timer.isValid{
//                stopPollingHistoryTimer()
//                historyPollingTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.pollingHistory(timer:)), userInfo: nil, repeats: true)
//            }else{
//
//            }
//        }else{
//            stopPollingHistoryTimer()
//            historyPollingTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.pollingHistory(timer:)), userInfo: nil, repeats: true)
////            historyPollingTimer?.fire()
//
//        }

    }

    /// 全ポーリング停止
    func stopAllTimer(){
        stopPollingHistoryTimer()
        stopPollingMeasureTimer()
    }

    /// 履歴数取得ポーリングの停止
    func stopPollingHistoryTimer(){
        historyPollingTimer?.invalidate()
        historyPollingTimer = nil
    }

    /// 測定ポーリングの停止
    func stopPollingMeasureTimer(){
        measurePollingTimer?.invalidate()
        measurePollingTimer = nil
    }

    /// 測定状態を取得するポーリングタイマーの作成
    func createPollingMeasureTimer(){
        stopPollingMeasureTimer()
        measurePollingTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.pollingMeasure(timer:)), userInfo: nil, repeats: true)
    }

    ///
    func startAllTimer(){
//        if canMeasure(){
        createPollingMeasureTimer()
//        }
    }


    //MARK: - dataパース本体
    /// 取得したデータの振り分け
    /// - parameter dataStr: BLE機器から取得したデータ
    func processGetValue(dataStr:String){
        //データが返ってきたらペリフェラルのサーチをストップ
//        Bluetooth.shared.stopCentralManager()

        //読み取り開始の応答データを受けた
        if (dataStr == Const.startMeasureStatus || dataStr == Const.startMeasureErrorStatus){
            //読み取り開始可否の通知
            NotificationCenter.default.post(name:.startMeasureStatusNotify, object: nil, userInfo: [Const.readResultKey:dataStr.deleteNewLine()])
        }

        let comAndData:[String] = self.getCommandAndData(str: dataStr)
        if !isCorrectData(datas: comAndData){
            return
        }

        //タイムアウトの処理
        changeTimeOutFlg(comAndData: comAndData)

        let tmpCommand = comAndData[0]
        let tmpValue = comAndData[1].deleteNewLine().deleteWhiteSpace()

        //システム情報パース
        if (tmpCommand == Const.modelVersionCommand.deleteWhiteSpace() || tmpCommand == Const.serialVersionCommand.deleteWhiteSpace() || tmpCommand == Const.mcuVersionCommand.deleteWhiteSpace() || tmpCommand == Const.fpgaVersionCommand.deleteWhiteSpace()){
            print("command:" + tmpCommand + " version:" + tmpValue)
            parseVersion(dataStr: tmpValue)
        }

        //バッテリーパース
        if (tmpCommand == Const.batteryCommand.deleteWhiteSpace()){
            print("battery:" + tmpValue)
            parseBattery(dataStr: tmpValue)
        }

        //最新の測定結果パース
        if (tmpCommand == Const.latestHistoryCommand.deleteWhiteSpace()){
            print("singleHistory:" + dataStr)
            parseSingleHistory(dataStr: dataStr)
        }

        //履歴数パース
        if (tmpCommand == Const.historyCommand.deleteWhiteSpace()){
            print("history:" + tmpValue)
            parseHistory(dataStr: tmpValue)
        }

        //履歴データの取得
//        parseReadHistory(dataStr: dataStr)
        SBMSDK.shared.getHistory(DataParse.shared.tmpDeviceName!, 100)

        //読み取り開始データを受けた
        if (tmpCommand == Const.startMeasureCommand.deleteWhiteSpace()){
            //読み取り開始の通知
            NotificationCenter.default.post(name:.startMeasureNotify, object: nil)
        }

        //押し当て状態のポーリング
        if (tmpCommand == Const.headStatusPollingCommand.deleteWhiteSpace()){
            parseHeadStatus(dataStr: tmpValue)
        }

        //測定状態のポーリング
        if (tmpCommand == Const.pollingCommand.deleteWhiteSpace()){
            parseMeasurePolling(dataStr: tmpValue)
        }

        //ipadの日時を更新したら日時データを取得する
        if (tmpCommand == Const.getIpadDate.deleteWhiteSpace() || tmpCommand == Const.getIpadTime.deleteWhiteSpace()){
            parseIpadDate(dataStr: dataStr)
        }

        //エラーの取得
        if (tmpCommand == Const.smallStatusCommand.deleteWhiteSpace() || tmpCommand == Const.largeStatusCommand.deleteWhiteSpace()){
            parceError(dataStr: dataStr)
        }
    }


    //MARK: - dataパース
    /// システム情報のパース
    /// - parameters dataStr: 取得データ（バージョン）
    func parseVersion(dataStr:String){
        print(dataStr)
        readVersions.append(dataStr)
        //システム情報を全て取得したら通知を出す
        if readVersions.count == 4 {
        NotificationCenter.default.post(name:.getVersionNotify, object: nil, userInfo: [Const.readResultKey: readVersions])
            readVersions = []
        }
    }

    /// バッテリーデータのパース
    /// - parameters dataStr: 取得データ（バッテリー）
    func parseBattery(dataStr:String){
        if let bat = Int(dataStr.deleteNewLine()){
            print(bat)
            batteryCnt = bat
        }
    }

    /// 最新の計測結果データのパース
    /// - parameter dataStr: 取得データ（履歴1件）
    func parseSingleHistory(dataStr:String) {
        let comAndData:[String] = getCommandAndData(str: dataStr)
        //ログ記録用の計測結果データ
        tmpLogData = comAndData[1].deleteNewLine()
        if inputCommand == Const.getSBMSingleData {
            //最新の検索結果取得通知
            NotificationCenter.default.post(name:.getMeasureData, object: nil,userInfo: [Const.readResultKey:tmpLogData])
        }
    }

    /// 履歴数データのパース
    /// - parameter dataStr: 取得データ（履歴）
    func parseHistory(dataStr:String){
        if let cnt = Int(dataStr.separateNewLine()){
            print(cnt)
            //残数を取得してその分のデータ取得処理
            if cnt != 0{
                historyCnt = cnt
            }else{
                NotificationCenter.default.post(name:.finishReadNotify, object: nil,userInfo: [Const.isDeleteKey:true])
                historyCnt = 0
            }
        }
    }

    /// 読み込みデータのパース
    /// - parameters dataStr: 取得データ（履歴）
//    func parseReadHistory(dataStr:String){
//        let comAndData:[String] = getCommandAndData(str: dataStr)
//        //測定するかどうか
////        if !canMeasure(){
////            return
////        }
//        //コマンドと結果を取得したか判定
//        if isCorrectData(datas: comAndData){
//            //実行した結果と受け取ったコマンドが正しいか判定
//            if compareReadCommand(bleCommand: comAndData[0]){
//                //2回連続同じ値か確認する。
//                if tmpSameData == ""{
//                    //tmpSameDataが空の場合は1回目。再度同じcomandを投げる
//                    if !(comAndData[1] == Const.lastData){
//                        //データが0.000 0.000・・・じゃない時に次のデータを読む。
//                        tmpSameData = comAndData[1]
//                        setReadCommand(addressNum: commandNum,commandNum:Const.fiveCommondNum)
//                        return
//                    }else{
//                        finishLogic()
//                    }
//                }else{
//                    //前回の場合と値が同じ場合は次へ進む
//                    if !(comAndData[1] == Const.lastData){
//                        //データが0.000 0.000・・・じゃない時に次のデータを読む。
//                        nextLogic(comAndData: comAndData)
//                    }else{
//                        //終了処理。
//                        finishLogic()
//                    }
//                }
//            }
//        }
//    }

    /// データ読み取りの終了処理
    func finishLogic(){
        //終了処理。
        if readResults.count != 0 {
            AudioServicesPlaySystemSound(self.sendSoundId)
        }
        //終了フラグを立てる。readFinishFlgがfalseからtrueになったらdidsetから通知。測定画面の場合はデータを渡して次の画面に遷移する。
        readFinishFlg = true
        readResults = []
        tmpSameData = ""
    }

    /// 次の読み取りコマンド処理
    /// - parameters comAndData:
//    func nextLogic(comAndData:[String]){
//        if readResults.firstIndex(of: comAndData[1]) == nil{
//            readResults.append(comAndData[1])
//        }
//        commandNum += 1
//        self.setReadCommand(addressNum: commandNum,commandNum:Const.fiveCommondNum)
//        tmpSameData = ""
//    }

    /// 押し当て状態のポーリング
    /// - parameters dataStr: 取得データ（測定状態が押し当て）
    func parseHeadStatus(dataStr:String){
        print("headStatus:" + dataStr)
        //ヘッダのポーリングが可能な画面でしかポーリングしない
        if !isEnableHeadPolling{
            return
        }
        if let status = Int(dataStr.deleteNewLine()){
            if status == 1{
                //ヘッドが押し当てられたので測定開始
                startBLEMeasure()
            }else{
                //ポーリングを続ける
//                self.setMultiCommand(command: Const.headStatusPollingCommand, num: Const.oneCommondNum)
            }
        }
    }

    /// 計測開始
    /// - parameters dataStr: 取得データ（測定状態が測定中）
    func parseMeasurePolling(dataStr:String){
        if let status = Int(dataStr.deleteNewLine()){
            print("measureStatus:\(status),tmpStatus:\(tmpMeasureStatus)")
            if status == Const.sbmMeasureStatus.touchError.rawValue{
                if tmpMeasureStatus == Const.sbmMeasureStatus.measuring.rawValue{
                    //タッチエラーを通知する。
                    NotificationCenter.default.post(name:.getTouchErrorNotify, object: nil)
                }
            }else{
                //測定開始。sbmが測定中でipadが測定前の場合
                if status == Const.sbmMeasureStatus.measuring.rawValue && tmpMeasureStatus == Const.sbmMeasureStatus.stop.rawValue{
                    AudioServicesPlaySystemSound(self.endSoundId)
                    isfirstMeasureError = true
                }

                //測定完了。sbmが測定後、ipadが測定中の場合
                if status == Const.sbmMeasureStatus.stop.rawValue && tmpMeasureStatus == Const.sbmMeasureStatus.measuring.rawValue{
                    //履歴データを全て取得する。
                    stopAllTimer()
                    //計測結果を取得する
                    getSingleHistory()
//                    setMultiCommand(command: Const.smallStatusCommand, num: Const.tenCommondNum)
                    SBMSDK.shared.getMeasureResultStatus500Hz(DataParse.shared.tmpDeviceName!)
                    AudioServicesPlaySystemSound(self.finishSoundId)
                }
            }
            tmpMeasureStatus = status
        }
    }

    /// 日付の取得
    /// - parameters dataStr: 取得データ（iPadの日付）
    func parseIpadDate(dataStr:String){
        if ipadDate == nil {
            //日付データ
            ipadDate = dataStr.deleteNewLine()
        } else {
            ipadDate! += " " + dataStr.deleteNewLine()
            //日付設定の通知
            NotificationCenter.default.post(name:.setSBMRTCNotify, object: nil, userInfo: [Const.readResultKey:ipadDate!])
        }
    }

    /// エラーのパース
    /// - parameters dataStr: 取得データ（エラー）
    func parceError(dataStr:String){
        let comAndData:[String] = self.getCommandAndData(str: dataStr)

        print("errorData:",comAndData)
        let tmpCommand = comAndData[0]
        let tmpValue = comAndData[1].deleteNewLine().deleteWhiteSpace()
        //実行した結果と受け取ったコマンドが正しいか判定
        if tmpCommand == Const.smallStatusCommand.deleteWhiteSpace(){
            print("errorvalue:",tmpValue)
            log.logger(type: Const.LogType.Result, date: Date(), log: tmpLogData, error: tmpValue + Const.ErrorStatus[Int(tmpValue)!])
            //error("3")じゃない。次のエラー確認コードの取得。
            if !(tmpValue == Const.measureErrorCode){
                //1000khzのエラー取得
//                setMultiCommand(command: Const.largeStatusCommand, num: Const.twoCommondNum)
                SBMSDK.shared.getMeasureResultStatus100Hz(DataParse.shared.tmpDeviceName!)
            }else{
                if isfirstMeasureError{
                    isfirstMeasureError = false
                    if let hist = tmpHistoryCnt{
                        tmpHistoryCnt = hist + 1
                    }

                }
                getErrorLogic()
            }
        }

        //1000khzのエラー状態。エラーじゃない場合に測定データ取得
        if tmpCommand == Const.largeStatusCommand.deleteWhiteSpace(){
            print("errorvalue1000:",tmpValue)
            log.logger(type: Const.LogType.Result, date: Date(), log: tmpLogData, error: tmpValue + Const.ErrorStatus[Int(tmpValue)!])
//            AudioServicesPlaySystemSound(self.centralSoundId)
            //error("3")じゃない。次のエラー確認コードの取得。
            if (tmpValue == Const.measureErrorCode || tmpValue == Const.measureErrorCodeFive){
                //1000khzのエラー取得
                getErrorLogic()
            }else{
                getData()
            }
        }
    }

    /// 取得したデータを配列に変更する。
    /// - parameters dataSre 取得データ
    /// - returns: データ配列
    func changeDataToArray(dataStr:String)->[String]{
        var divides:[String] = dataStr.components(separatedBy: " ")
        //最初と最後は改行コードがあるため削除する。
        divides.removeFirst()
        divides.removeLast()
        return divides
    }

    //MARK: - データの取得処理
    /// システム情報取得
    func getSystemVersion(){
        //予約（型番）
//        self.setMultiCommand(command: Const.modelVersionCommand+Const.versionRead, num: Const.oneCommondNum)
        SBMSDK.shared.getDeviceInformation(DataParse.shared.tmpDeviceName!)
        //予約（製造番号）
//        self.setMultiCommand(command: Const.serialVersionCommand+Const.versionRead, num: Const.oneCommondNum)
        SBMSDK.shared.getDeviceNo(DataParse.shared.tmpDeviceName!)
        //MCU バージョン ＊SBM機器のソフトバージョン
//        self.setMultiCommand(command: Const.mcuVersionCommand+Const.versionRead, num: Const.oneCommondNum)
        SBMSDK.shared.getMcuVersion(DataParse.shared.tmpDeviceName!)
        //FPGA バージョン
//        self.setMultiCommand(command: Const.fpgaVersionCommand+Const.versionRead, num: Const.oneCommondNum)
        SBMSDK.shared.getFpgaVersion(DataParse.shared.tmpDeviceName!)
    }

    /// バッテリーの取得
    func getBattery(){
//        self.setMultiCommand(command: Const.batteryCommand, num: 5)
        SBMSDK.shared.getBatteryLevel(DataParse.shared.tmpDeviceName!)
    }

    /// 過去の件数の取得
    func getOneHistoryNumber(){
        oneHitoryFlg = true
//        self.setMultiCommand(command: Const.historyCommand, num: 5)
        SBMSDK.shared.getHistory(DataParse.shared.tmpDeviceName!, 100)
    }

    /// 測定開始コマンドの設定
    func startBLEMeasure(){
//        self.setMultiCommand(command: Const.initMeasureCommand, num: 5)
//        self.setMultiCommand(command: Const.startMeasureCommand, num: 5)
//        self.setMultiCommand(command: Const.measureCommand, num: 5)
        SBMSDK.shared.doMeasure(DataParse.shared.tmpDeviceName!)
    }

    /// 最新のデータ取得
    func getSingleHistory(){
//        self.setMultiCommand(command: Const.latestHistoryCommand, num: Const.oneCommondNum)
        SBMSDK.shared.getHistory(DataParse.shared.tmpDeviceName!, 1)
    }

    /// 履歴データの取得
    func getAllHistory(){
        print(historyCnt)
        initCommandNum()
        initRead()
        readResult = [:]
        readFinishFlg = false
        //履歴データ取得スタートを通知
//        NotificationCenter.default.post(name:.startReadNotify, object: nil)

//        self.setReadCommand(addressNum: commandNum,commandNum:Const.fiveCommondNum)
        SBMSDK.shared.getHistory(DataParse.shared.tmpDeviceName!, 100)
    }

    ///ログファイルの取得
    func getLog(){
        let fileManager = FileManager.default
        var logText = ""

        for logType in Const.Logs {
            //ファイルパス取得
            if let dir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).last {
                let path = dir.appendingPathComponent(logType.rawValue)
                do {
                    //ファイルの存在チェック
                    if FileManager.default.fileExists(atPath: path.path) {
                        //ファイル読み込み
                        let file = try String(contentsOf: path, encoding: .utf8)
                        let logList = file.components(separatedBy: "\n")
                        logText += "\(logType)\(logList)"
                    }
                } catch let error as NSError {
                    print("*******************************************************")
                    print(error)
                }
            }
        }
        //読み取り完了時の通知
        NotificationCenter.default.post(name:.getLogNotify, object: nil, userInfo: [Const.readResultKey:logText])
    }

    /// ipad日時の送信
    func setIpadTime(){
        ipadDate = nil
        //時間の送信
//        self.setMultiCommand(command: self.getIpadTimeCommand(format: Const.ipadTimeFormat, tmpCommand: Const.ipadTimeCommand), num: 5)
        SBMSDK.shared.setTime(DataParse.shared.tmpDeviceName!)
        //日付の送信
//        self.setMultiCommand(command: self.getIpadTimeCommand(format: Const.scheduleFormat, tmpCommand: Const.ipadDateCommand), num: 5)
        SBMSDK.shared.setDate(DataParse.shared.tmpDeviceName!)
//        self.setMultiCommand(command: Const.getIpadDate, num: 5)
//        self.setMultiCommand(command: Const.getIpadTime, num: 5)
        SBMSDK.shared.getDate(DataParse.shared.tmpDeviceName!)
        SBMSDK.shared.getTime(DataParse.shared.tmpDeviceName!)
    }

    /// モードの変更
    /// - parameters modeStr: 0:独立モード 1:通信モード 3：記録モード
//    func changeMode(modeStr:String){
//        self.setMultiCommand(command: modeStr, num: 10)
//    }

    /// SBM 機器からOFF LINE 時などに保存された測定結果を全て消去する。
    func deleteAllHistory(){
//        self.setMultiCommand(command: Const.deletePollingCommand, num: 5)
        SBMSDK.shared.removeHistoryAll(DataParse.shared.tmpDeviceName!)
    }

    /// コマンド初期化
    func initCommandNum(){
        let start = Const.rdReadStartNum
        commandNum = start
    }

    //ipad時間を送るコマンドの作成
    func getIpadTimeCommand(format:String,tmpCommand:String)->String{
        let timeStr = Date().getDateStr(format: format)
        let command = tmpCommand + timeStr
        return command
    }

    //MARK: - データの送信処理
    /// 音量・輝度の設定
    /// - parameters seg: 1:音量、2:輝度
    /// - parameters selectValue: セグメントの選択値
    func pushSegmentV(_ seg: Int, selectValue: Int) {
        var commandStr = ""
        if seg == Const.DeviceSettingType.sound.rawValue {
            // 音量　1:消音、2:小、3:中、4:大
            commandStr = Const.soundCommand + selectValue.description
            //MEMO: 現状SBM機器の設定値を取得できる仕様がないため、応答データはアプリから指定された設定値を返却する
            SBMSDK.shared.setTone(DataParse.shared.tmpDeviceName!, Int(selectValue.description)!)
            NotificationCenter.default.post(name:.setSBMToneNotify, object: nil, userInfo: [Const.readResultKey:"\(selectValue)"])
        } else {
            // 輝度　2:小、3:中、4:大
            commandStr = Const.lightCommand + selectValue.description
            //MEMO: 現状SBM機器の設定値を取得できる仕様がないため、応答データはアプリから指定された設定値を返却する
            SBMSDK.shared.setBright(DataParse.shared.tmpDeviceName!, Int(selectValue.description)!)
            NotificationCenter.default.post(name:.setSBMDispNotify, object: nil, userInfo: [Const.readResultKey:"\(selectValue)"])
        }
//        setMultiCommand(command: commandStr, num: 5)
    }


    //MARK: - timeout
    ///タイムアウトの状態を変更する。
    /// - parameters comAndDara: [コマンド,データ]
    func changeTimeOutFlg(comAndData:[String]){
        let tmpValue = comAndData[1].deleteNewLine().deleteWhiteSpace()
        if (self.isTimeOutCommand(command: tmpValue)){
            //ポーリングコマンドじゃない場合はタイムアウトフラグをfalseに直す。
            isTimeout = false
            timeoutCnt = 0
        }
    }

    /// 与えられたコマンドがtimeoutさせるコマンドか判定。trueの場合はtimeout処理を入れる。
    /// - parameters command: コマンド
    /// - returns: true or false
    func isTimeOutCommand(command:String)->Bool{
        var timeout = true
        if (command == Const.pollingCommand.deleteWhiteSpace() || command == Const.deletePollingCommand.deleteWhiteSpace()){
            timeout = false
        }
        return timeout
    }


    //MARK: - bleのデータパース
    /// BLEから受け取ったデータをコマンドとデータに分解する。
    /// - parameters str: 取得データ
    /// - returns:[コマンド,データ]
    func getCommandAndData(str:String)->[String]{
        var datas:[String] = str.components(separatedBy: Const.dataSeparatStr)
        //時間取得コマンドの場合はコロンが複数含まれるため分割方法を変える
        if datas[0] == Const.getIpadTime.deleteWhiteSpace() {
            let rangeStr = str.range(of: Const.dataSeparatStr)!
            datas = [str[str.startIndex ..< rangeStr.lowerBound].description, str[rangeStr.upperBound ..< str.endIndex].description]
        }
        if datas.count == 2{
            return datas
        }
        return []
    }


    /// 与えられたデータがコマンドとデータを持った配列か判定。
    /// - parameter datas
    /// - returns: true or false
    func isCorrectData(datas:[String])->Bool{
        if datas.count == 2{
            return true
        }
        return false
    }


    //MARK: - bluetooth
    /// - parameters mycommand:
//    func writeTextData (_ mycommand: String) {
//        let PreFixString = "\r\n"  // ""
//        let SuFixfString = "\r\n"  // ""
//        let inputText = mycommand
//
//        Bluetooth.shared.writeString(data: PreFixString + inputText + SuFixfString)
//    }


    //MARK: - service function
    /// エラーを取得した時のロジック
    func getErrorLogic(){
        //1000khzのエラー取得
        getData()
        NotificationCenter.default.post(name:.getMeasureErrorNotify, object: nil)
    }

    /// 全ての履歴を取得する処理
    func getData(){
        DispatchQueue.main.asyncAfter(deadline: .now() + Const.lateTime) {
            //データ記録から取得まで早すぎると、取得ができないので遅延実行する。
            self.getAllHistory()
        }
    }

    /// コマンドが正しいか判定する。
    /// - parameter bleCommand: コマンド
    /// - returns: true or false
    func compareReadCommand(bleCommand:String)->Bool{
        if bleCommand == Const.historyCommand.deleteWhiteSpace() || bleCommand == Const.pollingCommand.deleteWhiteSpace() || bleCommand == Const.getIpadDate.deleteWhiteSpace() || bleCommand == Const.getIpadTime.deleteWhiteSpace() || bleCommand == Const.batteryCommand.deleteWhiteSpace() || bleCommand == Const.smallStatusCommand.deleteWhiteSpace() || bleCommand == Const.largeStatusCommand.deleteWhiteSpace(){
            return false
        }
        //3桁の番号が履歴件数のコマンド番号以内か
        if let comNum = self.changeFromHexadimal(command: String(bleCommand.suffix(3))){
            //下3桁が500以上
            if (comNum >= Const.rdReadStartNum){
                return true
            }
        }
        return false
    }

    /// 16進数のコマンドを10進数のコマンドに変更する。
    /// - parameters command: コマンド
    /// - returns 10進数のコマンド
    func changeFromHexadimal(command:String)->Int?{
        if let value = UInt8(command.suffix(2), radix: Const.hexadimalUnit) {
            return Int(value) + Const.rdReadStartNum
        }

        return nil
    }

    /// 与えられたアドレス番号でコマンド実行
    /// - parameters addressNum:
    /// - parameters commandNum:
//    func setReadCommand(addressNum:Int,commandNum:Int){
//        let com = Const.getDataheader + changeToHexadimal(addressNum: addressNum)
//        print("rdcomand:" + com)
//        setMultiCommand(command: com, num: commandNum)
//
//    }

    /// 履歴アドレス番号の下2桁を16進数に変換
    /// - parameters addressNum: アドレス番号
    /// - returns: 16進数に変換したアドレス番号
    func changeToHexadimal(addressNum:Int)->String{
        //変換するアドレスは500〜550。下2桁を取り出して16進数に変換。
        let addressStr = addressNum.description
        //末尾2文字
        let divide = addressStr.suffix(2)
        //先頭1文字
        let pre = addressStr.prefix(1)

        if pre == "5"{
            //アドレスの先頭が5の場合
            if let di = Int(divide){
                var hexStr = String(di, radix: Const.hexadimalUnit)
                if hexStr.count == 1{
                    hexStr = "0" + hexStr
                }
                hexStr = "0" +  pre + hexStr
                return hexStr.uppercased()
            }
        }else{
            //アドレスの先頭が6の場合
            if let di = Int(divide){
                var hexStr = String(di + Const.hexaMax, radix: Const.hexadimalUnit)
                hexStr = "0" +  "5" + hexStr
                return hexStr.uppercased()
            }
        }
        return addressNum.description
    }

    /// コマンドを複数回実行する。
    /// - parameters command: コマンド
    /// - parameters num: 実行回数
//    func setMultiCommand(command:String,num:Int){
//        //タイムアウト処理を入れる。
//        if (isTimeOutCommand(command: command)){
//            //ポーリングコマンドはタイムアウト設定しない。
//            self.writeTextData(command)
//            self.restartCommand = command
//            self.isTimeout = true
//            self.timeoutCnt = 0
//            //タイムアウト処理
//            DispatchQueue.main.asyncAfter(deadline: .now() + Const.timeOutInterval) {
//                if self.isTimeout {
//                    print("timeout")
//                    if self.timeoutCnt < Const.standardTimeoutCnt{
//                        self.writeTextData(self.restartCommand)
//                        //タイムアウトを1回追加
//                        self.timeoutCnt += 1
//                    }
//                }
//            }
//        }
//        for _ in 0 ..< num{
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                print("writecommand:" + command)
//                self.writeTextData(command)
//            }
//        }
//    }
}
