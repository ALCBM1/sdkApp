//
//  CommandView.swift
//  SbmSdk
//
//  Created by shoma on 2022/08/09.
//

import SwiftUI

struct CommandView: View {
    @State private var selectedTone = 1
    @State private var selectedBright = 1
    @State var inputText: String = ""
    @State var outputText: String = ""
    @State var deviceName: String = ""
    @State var conditionColor = Color.gray
    @State var batteryColor = Color.gray
    @State var deviceList: [String] = ["OFF"]
    @State var inputCommandList: [String] = []
    @State var isConnect: Bool = false
    @FocusState private var focus: Bool

    //ファイル出力関連
    @State private var outputErrorAlert = false
    @State private var outputCompleteAlert = false

    var body: some View {
        VStack {
            VStack {
                HStack {
                    // 他画面と実装同じ
                    Text("Device Name:")
                    Picker(selection: $deviceName, label: Text("デバイス名"), content: {
                        if deviceList.count != 0 {
                            ForEach(deviceList, id:\.self) { value in
                                Text("\(value)")
                            }
                        }
                    })
                    .onChange(of: deviceName) { newValue in
                        deviceName = newValue
//                        selectedDevice(deviceName)
//                            DataParse.shared.changeMode(modeStr: Const.goModeThree)
                        if DataParse.shared.tmpDeviceName != nil {
                            APICommand.shared.execute(command: "Set_BT-SBM disconnect")
                            DataParse.shared.tmpDeviceName = nil
                        }
                        if deviceName == "OFF" {
                            APICommand.shared.execute(command: "Set_BT-SBM disconnect")
                            DataParse.shared.tmpDeviceName = nil
                        }  else {
                            //選択したデバイスをbluetooth接続する。接続が完了したらセットアップを開始
                            DataParse.shared.tmpDeviceName = deviceName
                            SBMSDK.shared.connect(DataParse.shared.tmpDeviceName!)
                        }
                    }
                    .pickerStyle(.menu)
                    Text("Connect:")
                    Circle()
                        .fill(conditionColor)
                        .frame(width: 20, height: 20)
                    Text("Battery:")
                    Circle()
                        .fill(batteryColor)
                        .frame(width: 20, height: 20)
                }
                HStack {
                    // 他画面と実装同じ
                    Text("Tone")
                    Picker(selection: $selectedTone, label: Text(""))
                    {
                        ForEach(0 ..< 4) {
                            index in
                            Text(index.description)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: selectedTone) {newValue in
                        // 1:消音、2:小、3:中、4:大でデータを送るのでプラス1する
                        APICommand.shared.execute(command: "SetSBM-Tone[0\(newValue+1)]")
                    }
                    .padding()
                    Text("Bright")
                    Picker(selection: $selectedBright, label: Text(""))
                    {
                        ForEach(2 ..< 5) {
                            index in
                            Text(index.description)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: selectedBright) {newValue in
                        APICommand.shared.execute(command: "SetSBM-Disp[0\(newValue+2)]")
                    }
                }
            }
            // ここまで他画面と実装同じ
            HStack {
                VStack {
                    TextEditor(text: $inputText)
                        .foregroundColor(Color.gray)
                        .border(Color.gray,width: 1)
                        .font(.custom("HelveticaNeue", size: 13))
                        .focused(self.$focus)
                        .onTapGesture {
                            self.focus = false
                        }
                    Button(action: {
                        print("Enter")
                        executeEnteredCommands()
                        // 結果表示
                    }, label: {
                        Text("Enter")
                            .padding(10)
                            .border(Color.gray, width: 1)
                    }).background(Color.black)
                }
                VStack {
                    TextEditor(text: $outputText)
                        .foregroundColor(Color.gray)
                        .border(Color.gray,width: 1)
                        .font(.custom("HelveticaNeue", size: 13))
                        .disabled(true)
                    Button(action: {
                        print("Output")
                        outputTextFile()
                    }, label: {
                        Text("Output")
                            .padding(10)
                            .border(Color.gray, width: 1)
                    }).background(Color.black)
                }
            }
        }
        //Output用のアラート
        .alert("ファイルの書き込みに失敗しました。", isPresented: $outputErrorAlert) {}
        .alert("ファイル出力完了。テキストをクリップボードにコピーしました。", isPresented: $outputCompleteAlert) {}
        .onAppear{
            // セントラルマネージャーを初期化する。
//            Bluetooth.shared.setCentralManager()
            // 他画面と実装同じ
            SBMSDK.shared.initialize()
            // セントラルのBluetoothがONになっているか確認、OFFの場合は通知表示->接続可能な全てのペリフェラルを検知
            SBMSDK.shared.startScan()
            APICommand.shared.execute(command: "Set_BT-SBM disconnect")
            // 前回接続したデバイスに自動で接続
            if let connectedDeviceName = UserDefaults.standard.string(forKey: "connectedDeviceName") {
                APICommand.shared.execute(command: "Set_BT-SBM pairing [\(connectedDeviceName)]")
            }
        }
        //バッテリー残量取得
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name(SBMSDK.NotificationName.receptIsBatteryLevel))) { notification in
            // 他画面と実装同じ
            print("----------------1getBatteryNotify",notification)
            //バッテリー残量によってドットの色を変える
            let value: [String] = notification.userInfo!["Value"] as! [String]
            if let bat = Int(value[2]) {
                if bat > 50 {
                    batteryColor = Color.green
                } else if bat < 50 {
                    batteryColor = Color.yellow
                } else if bat < 10 {
                    batteryColor = Color.gray
                } else {
                    batteryColor = Color.gray
                }
            }
        }
        //SBM接続後、コマンド実行後の通知処理
        //SBM接続解除
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name(SBMSDK.NotificationName.disconnected))) { notification in
            // 他画面と実装同じ
            print("----------------",notification)
            isConnect = false
            conditionColor = Color.gray
            batteryColor = Color.gray
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name(SBMSDK.NotificationName.subscribed))) { notification in
            // 他画面と実装同じ
            print("----------------",notification)
            SBMSDK.shared.getRSSI(deviceName)
            SBMSDK.shared.getBatteryLevel(deviceName)
            SBMSDK.shared.getDeviceInformation(deviceName)
            SBMSDK.shared.getMode(deviceName)
            SBMSDK.shared.getName(deviceName)
            SBMSDK.shared.setDate(deviceName)
            SBMSDK.shared.setTime(deviceName)
            SBMSDK.shared.setupHistoryMode(deviceName)
            SBMSDK.shared.removeHistoryAll(deviceName)
            //前回接続したデバイスがあれば初期値に設定する
            if let connectedDeviceName = UserDefaults.standard.string(forKey: "connectedDeviceName") {
                deviceName = connectedDeviceName
            }
//            SBMSDK.shared.getHistoryCount(deviceName)
//            APICommand.shared.execute(command: "Get_SBM-StackedData")
        }
        // ペリフェラルを検知した際に呼び出される
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name(SBMSDK.NotificationName.discoverPeripheral))) { notification in
//            deviceList = Bluetooth.shared.peripherals
//            deviceList = SBMSDK.shared.getPeripheralNames()
//            deviceList.insert("OFF", at: 0)
            // 他画面と実装同じ
            print("----------------",notification)
            deviceList = ["OFF"] + SBMSDK.shared.getPeripheralNames()
            print(deviceList)
        }
        //SBM接続状態
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name(SBMSDK.NotificationName.connected))) { notification in
            // 他画面と実装同じ
            print("----------------",notification)
            isConnect = true
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) {timer in
                if isConnect {
//                    APICommand.shared.execute(command: Const.getBTCondition)
//                    APICommand.shared.execute(command: Const.getSBMBattery)
                    SBMSDK.shared.getRSSI(deviceName)
                    SBMSDK.shared.getBatteryLevel(deviceName)
                    SBMSDK.shared.getDeviceInformation(deviceName)
                    SBMSDK.shared.getMode(deviceName)
                    SBMSDK.shared.getName(deviceName)
                    SBMSDK.shared.setupHistoryMode(deviceName)
                    SBMSDK.shared.getHistoryCount(deviceName)
//                    APICommand.shared.execute(command: "Get_SBM-StackedData")
                    SBMSDK.shared.getHistory(DataParse.shared.tmpDeviceName!, 100)
                } else {
                    timer.invalidate()
                }
            }
        }
        //通信状態取得
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name(SBMSDK.NotificationName.gotRSSI))) { notification in
            // 他画面と実装同じ
            print("----------------",notification)
            if let reads:Int = notification.userInfo!["Value"] as? Int{
                outputText += "\(Const.getBTCondition)\n>>\(reads)\n"
                if isConnect {
                    //接続状態によってドットの色を変える
                    if reads > -75 {
                        conditionColor = Color.green
                    } else if reads > -95 {
                        conditionColor = Color.yellow
                    } else {
                        conditionColor = Color.red
                    }
                } else {
                    conditionColor = Color.gray
                }
            }
        }
        //システム情報取得
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name(SBMSDK.NotificationName.receptIsSBMInformation))) { notification in
            // 他画面と実装同じ
            print("----------------",notification)
            if let reads:[String] = notification.userInfo![Const.readResultKey] as? [String]{
                outputText += "\(Const.getSystemVersion)\n>>\(reads)\n"
            }
        }
        //日付設定
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name(SBMSDK.NotificationName.receptIsDate))) { notification in
            // 他画面と実装同じ
            print("----------------",notification)
            if let reads:String = notification.userInfo![Const.readResultKey] as? String{
                outputText += "\(Const.setSBMIpadDate)\n>>\(reads)\n"
            }
        }
        //時刻設定
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name(SBMSDK.NotificationName.receptIsTime))) { notification in
            // 他画面と実装同じ
            print("----------------",notification)
            if let reads:String = notification.userInfo![Const.readResultKey] as? String{
                outputText += "\(Const.setSBMIpadDate)\n>>\(reads)\n"
            }
        }
        //音量設定
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name(SBMSDK.NotificationName.receptIsTone))) { notification in
            // 他画面と実装同じ
            print("----------------",notification)
            if let reads:String = notification.userInfo![Const.readResultKey] as? String{
                outputText += "\(Const.setSBMTone)\n>>\(reads)\n"
            }
        }
        //輝度設定
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name(SBMSDK.NotificationName.receptIsBright))) { notification in
            // 他画面と実装同じ
            print("----------------",notification)
            if let reads:String = notification.userInfo![Const.readResultKey] as? String{
                outputText += "\(Const.setSBMDisp)\n>>\(reads)\n"
            }
        }
        //測定開始可否
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("startMeasureStatusNotify"))) { notification in
            print("----------------",notification)
            if let reads:String = notification.userInfo![Const.readResultKey] as? String{
                outputText += "\(Const.setSBMRemoteStart)\n>>\(reads)\n"
            }
        }
        //ログ履歴取得
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("getLogNotify"))) { notification in
            print("----------------",notification)
            if let reads:String = notification.userInfo![Const.readResultKey] as? String{
                outputText += "\(Const.getLog)\n>>\(reads)\n"
            }
        }
        //最新の履歴1件取得
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name(SBMSDK.NotificationName.receptIsLatestMeasureResult))) { notification in
            print("----------------",notification)
            if let reads:String = notification.userInfo![Const.readResultKey] as? String{
                outputText += "\(Const.getSBMSingleData)\n>>\(reads)\n"
            }
        }
        //履歴件数取得
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name(SBMSDK.NotificationName.receptIsHistoryCount))) { notification in
            print("----------------",notification)
            if let reads:String = notification.userInfo![Const.readResultKey] as? String{
                outputText += "\(Const.getSBMStackedDataNum)\n>>\(reads)\n"
            }
        }
        //全履歴データ取得
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("finishReadNotify"))) { notification in
            print("----------------",notification)
            if let reads:[String] = notification.userInfo![Const.readResultKey] as? [String]{
                outputText += "\(Const.getSBMStackedData)\n>>\(reads)\n"
            }
        }
    }
    
    private func isSBMName(_ name:String?) -> Bool {
        guard name!.prefix(2) == "RN" else {
            return false
        }
        return true
    }

    //選択したデバイスをbluetooth接続する。接続が完了したらセットアップを開始
//    func selectedDevice(_ selected: String) {
//        APICommand.shared.execute(command: "Set_BT-SBM pairing [\(selected)]")
//        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) {timer in
//            if isConnect {
//                APICommand.shared.execute(command: Const.getBTCondition)
//                APICommand.shared.execute(command: Const.getSBMBattery)
//            } else {
//                timer.invalidate()
//            }
//        }
//    }
    //入力されたコマンドを実行する
    func executeEnteredCommands() {
        //セミコロン区切りでコマンドを分けて順番に実行する
        inputCommandList = inputText.components(separatedBy: ";")
        for command in inputCommandList {
            APICommand.shared.execute(command: command.deleteNewLineLF())
        }
        //Enter押下で入力フォームを空欄にする
        inputText = ""
    }
//    func getResultsEveryTimer(commandStr: String) {
        // コマンド実行結果が更新されるまで0.1秒事に結果を取得する
//        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) {timer in
//            if APICommand.shared.resultMessage != "" {
//                 timer.invalidate()
//                outputText += "\(commandStr)\n >> \(APICommand.shared.resultMessage)\n"
//            }
//        }
//    }
    //出力テキストをアプリ内のファイルに保存する
    func outputTextFile() {
        let fileName = "output_sbm.txt"
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last {
            let path = dir.appendingPathComponent(fileName)

            do {
                try outputText.write(to: path, atomically: true, encoding: String.Encoding.utf8)
            } catch let error as NSError {
                print("エラー：\(error)")
                outputErrorAlert = true
            }
        }
        //クリップボードにコピーする
        UIPasteboard.general.string = outputText
        outputCompleteAlert = true
    }
}

struct CommandView_Previews: PreviewProvider {
    static var previews: some View {
        if #available(iOS 15.0, *) {
            CommandView()
                .previewInterfaceOrientation(.landscapeLeft)
        } else {
            // Fallback on earlier versions
            CommandView()
        }
    }
}

