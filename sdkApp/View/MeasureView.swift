//
//  MeasureView.swift
//  SbmSdk
//
//  Created by shoma on 2022/08/23.
//

import SwiftUI

struct MeasureView: View {
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

//    @State var isPhone: Bool = false
    @State var resultText: String = ""
    @State var result: [[String]] = []
    @State var TSCyValue:[Double] = []
    @State var WCSCyValue:[Double] = []
    @State var eTEWLyValue:[Double] = []

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
            VStack {
//                if isPhone {
//                    VStack{
//                        MeasureResultView(result: $result)
//                        MeasureChartView(result: $result,TSCyValue:$TSCyValue,WCSCyValue:$WCSCyValue,eTEWLyValue:$eTEWLyValue)
//                    }
//                } else {
                    HStack{
                        MeasureResultView(result: $result)
                        MeasureChartView(result: $result,TSCyValue:$TSCyValue,WCSCyValue:$WCSCyValue,eTEWLyValue:$eTEWLyValue)
                    }
//                }
            }
        }
        .padding()
        .onAppear {
            //　デバイスの種類を取得
//            if UIDevice.current.userInterfaceIdiom == .phone {
//                isPhone = true
//            } else {
//                isPhone = false
//            }
            // セントラルマネージャーを初期化する。
//            Bluetooth.shared.setCentralManager()
            // 他画面と実装同じ
            SBMSDK.shared.initialize()
            // セントラルのBluetoothがONになっているか確認、OFFの場合は通知表示->接続可能な全てのペリフェラルを検知
            SBMSDK.shared.startScan()
            APICommand.shared.execute(command: "Set_BT-SBM disconnect")
            // 前回接続したデバイスに自動で接続
            if let connectedDeviceName = UserDefaults.standard.string(forKey: "connectedDeviceName") {
//                DataParse.shared.tmpDeviceName = connectedDeviceName
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
        //SBM接続解除
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name(SBMSDK.NotificationName.disconnected))) { notification in
            // 他画面と実装同じ
            print("----------------2blueToothDisConnectNotify",notification)
            isConnect = false
            conditionColor = Color.gray
            batteryColor = Color.gray
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name(SBMSDK.NotificationName.subscribed))) { notification in
            // 他画面と実装同じ
            print("----------------3startBLEConnectionNotify",notification)
            isConnect = true
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
//            print(Bluetooth.shared.peripherals)
//            for i in 0 ..< Bluetooth.shared.peripherals.count {
//                print(Bluetooth.shared.peripherals[i])
////                if Bluetooth.shared.peripherals[i].contains("RN4871") {
//                    deviceList.append(Bluetooth.shared.peripherals[i])
////                }
//            }
            // 他画面と実装同じ
            print("----------------5getPeriferalNotify",notification)
            deviceList = ["OFF"] + SBMSDK.shared.getPeripheralNames()
            print(deviceList)
        }
        //SBM接続状態
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name(SBMSDK.NotificationName.connected))) { notification in
            // 他画面と実装同じ
            print("----------------",notification)
            isConnect = true
            Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) {timer in
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
        // 履歴を取得した際に呼び出される
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name(SBMSDK.NotificationName.receptIsMeasureResult))) { notification in
            print("----------------4finishReadNotify",notification)
            print(notification.userInfo!)
//            for i in 0 ..< DataParse.shared.readResults.count {
//                if i > 100 { return } // 最大100個まで取得
            let tmp = notification.userInfo!["Value"] as! [String]
            if tmp[2] == "0.000" && tmp[3] == "0.000" {} else {
                var resultCheckerArray = result
                resultCheckerArray.append(tmp)
                let resultChecker = Set(resultCheckerArray)
                if resultChecker.count == result.count {
                    return
                } else {
                    result.append(tmp)
                    let tsc = Double(tmp[3])
                    let wcsc = Double(tmp[4])
                    let etewl = Double(tmp[2])
                    TSCyValue.insert(tsc ?? 0, at: 0)
                    WCSCyValue.insert(wcsc ?? 0, at: 0)
                    eTEWLyValue.insert(etewl ?? 0, at: 0)
                }
            }
            if tmp[1] == "0500" {
                SBMSDK.shared.removeHistoryAll(deviceName)
            }
//            }
            // バッテリー残量の取得
            // Get_Logと同時に処理できないのでGet_Logが完了してからバッテリー残量を取得する
            APICommand.shared.execute(command: Const.getSBMBattery)
        }
    }
}

struct MeasureView_Previews: PreviewProvider {
    static var previews: some View {
        MeasureView()
    }
}


struct MeasureResultView: View {
    @Binding var result:[[String]]
    var headers : [String] = ["TSC", "WCSC", "eTEWL"]
    @State var currentDate:String = ""
    let timeDateFormatter = DateFormatter()
    let dt = Date()
    let dateFormatter = DateFormatter()
    
    var body: some View {
        VStack {
            List {
                HStack {
                    Spacer()
                    Text(headers[0])
                        .fontWeight(.bold)
                        .frame(width: 70)
                    Spacer()
                    Text(headers[1])
                        .fontWeight(.bold)
                    Spacer()
                    Text(headers[2])
                        .fontWeight(.bold)
                    Spacer()
                }
                ForEach (0..<result.count ,id: \.self) { index in
                    HStack {
                        Spacer()
                        Text(result[index][3])
                        Spacer()
                        Text(result[index][4])
                        Spacer()
                        Text(result[index][2])
                        Spacer()
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
        }
        .onAppear{
            // 年月日
            dateFormatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "yMd", options: 0, locale: Locale(identifier: "ja_JP"))
            currentDate  = dateFormatter.string(from: dt)
        }
    }
    func convertTime(basis: Date) -> String {
        // 秒数をhh:mm:ssに変換
        timeDateFormatter.dateFormat = "hh:mm:ss"
        return timeDateFormatter.string(from: basis)
    }
}

struct MeasureChartView: View {
    // chart関連
    @Binding var result:[[String]]
    @Binding var TSCyValue:[Double]
    @Binding var WCSCyValue:[Double]
    @Binding var eTEWLyValue:[Double]
    @State private var xValue: [String]? = []
    @State private var chartLabel1: String? = "TSC"
    @State private var chartLabel2: String? = "WCSC"
    @State private var chartLabel3: String? = "eTEWL"

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom){
                ScrollView {
                    VStack {
                        if eTEWLyValue.count != 0 {
                            LineChart(chartLabel: $chartLabel3, xValue: $xValue, yValue: $eTEWLyValue, scale: 0)
                                .frame(height: 200)
                        }
                        if TSCyValue.count != 0 {
                            LineChart(chartLabel: $chartLabel1, xValue: $xValue, yValue: $TSCyValue, scale: 0)
                                .frame(height: 200)
                        }
                        if WCSCyValue.count != 0 {
                            LineChart(chartLabel: $chartLabel2, xValue: $xValue, yValue: $WCSCyValue, scale: 0)
                                .frame(height: 200)
                        }
                    }
                }
            }
//            .onChange(of: result) { result in
//                print("onChange of: result",result.count,TSCyValue.count)
//                if result.count > 0 {
//                    // 最新の1〜10回分
//                    for i in 0 ..< result.count {
//                        if i < 10 {
////                            if result.indices.contains(i) {
//                                let tsc = Double(result[i][3])
//                                let wcsc = Double(result[i][4])
//                                let etewl = Double(result[i][2])
//                                TSCyValue.insert(tsc ?? 0, at: 0)
//                                WCSCyValue.insert(wcsc ?? 0, at: 0)
//                                eTEWLyValue.insert(etewl ?? 0, at: 0)
////                            }
//                        } else {
//                            break
//                        }
//                    }
//                } else {
//                    TSCyValue = []
//                    WCSCyValue = []
//                    eTEWLyValue = []
//                }
//            }
        }
    }
}

struct MeasureSettingView: View {
    @State private var selectedTone = 1
    @State private var selectedBright = 1
    var body: some View {
        HStack {
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
        }
        HStack {
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
}
