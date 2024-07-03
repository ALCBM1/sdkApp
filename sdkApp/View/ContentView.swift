//
//  ContentView.swift
//  SbmSdk
//
//  Created by shoma on 2022/07/21.
//

import SwiftUI

struct ContentView: View {

    @State private var selectedSound = 1
    @State private var selectedLight = 1
    @State var deviceList: [String?] = []
    @State var rssi: String = ""
    @State var battery: String = ""

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom){
                ScrollView {
                    VStack {
                        Button(action: {
                            Task {
                                print("--------- Start Test ----------")
//                                print("testScanPeripheral:",testScanPeripheral())
//                                print("testConnectPeripheral:", testConnectPeripheral())
//                                print("testDisConnectPeripheral:", testDisconnectPeripheral())
                            }
                        }, label: {
                            Text("!button!")
                                .padding()
                        })
                        //ペリフェラル検知中に押下すると検知したデバイス名をリスト表示する
                        Button(action: {
                                peripheralList()
                            }, label: {
                                Text("検知したデバイス一覧を表示")
                                    .padding(10)
                            }
                        )
                        //検知したデバイスの中からSBM機器のデバイス名を選択するとBluetooth接続する
                        List {
                            Text("デバイス一覧")
                            ForEach(deviceList, id: \.self) { device in
                                    HStack {
                                        Text(device!)
                                        Spacer()
                                    }
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedDevice(device!)
                                }
                            }
                        }
                        .frame(height: 100)
                        //計測開始押下してからSBM機器を肌に押し当てると計測結果をコンソールに出力する
                        Button(action: {
                            DataParse.shared.initPolling()
                        }, label: {
                            Text("計測開始")
                                .padding(10)
                        })
                        //音量変更
                        HStack(spacing: 10) {
                            Text("▼音量")
                            Button(action: {
                                DataParse.shared.pushSegmentV(1, selectValue: selectedSound)
                            }, label: {
                                Text("音量変更")
                                    .padding(10)
                            })
                        }
                        Picker(selection: self.$selectedSound, label: Text(""))
                        {
                            ForEach(0 ..< 3) {
                                index in
                                Text(index.description)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        //輝度変更
                        HStack(spacing: 10) {
                            Text("▼輝度")
                            Button(action: {
                                DataParse.shared.pushSegmentV(2, selectValue: selectedLight)
                            }, label: {
                                Text("輝度変更")
                                    .padding(10)
                            })
                        }
                        Picker(selection: self.$selectedLight, label: Text(""))
                        {
                            ForEach(1 ..< 4) {
                                index in
                                Text(index.description)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        // モード変更
                        HStack {
                            Button(action: {
//                                DataParse.shared.changeMode(modeStr: Const.goModeOne)
                                SBMSDK.shared.setupStandaloneMode(DataParse.shared.tmpDeviceName!)
                            }, label: {
                                Text("モード変更(モード1)")
                                    .padding(10)
                            })
                            Button(action: {
//                                DataParse.shared.changeMode(modeStr: Const.goModeTwo)
                                SBMSDK.shared.setupCommunicationMode(DataParse.shared.tmpDeviceName!)
                            }, label: {
                                Text("モード変更(モード2)")
                                    .padding(10)
                            })
                            Button(action: {
//                                DataParse.shared.changeMode(modeStr: Const.goModeThree)
                                SBMSDK.shared.setupHistoryMode(DataParse.shared.tmpDeviceName!)
                            }, label: {
                                Text("モード変更(モード3)")
                                    .padding(10)
                            })
                        }
                        VStack {
                            // 現在の電波状況を取得する
                            Button(action: {
                                // 再検知しcentralManagerのdidDiscoverを呼び出し電波状況を取得する
//                                Bluetooth.shared.setCentralManager()
                                Bluetooth.shared.initialize(nil)
                                Bluetooth.shared.startScan()
//                                rssi = "\(Bluetooth.shared.selectedDeviceRssi)"
                                rssi = "\(Bluetooth.shared.getRSSI(DataParse.shared.tmpDeviceName!))"
                            }, label: {
                                Text("電波状況取得")
                                    .padding(10)
                            })
                            Text(rssi)
                            //バッテリー残量取得
                            Button(action: {
                                DataParse.shared.getBattery()
                                battery = String(describing: DataParse.shared.batteryCnt)
                            }, label: {
                                Text("バッテリー残量取得")
                                    .padding(10)
                            })
                            Text(battery)
                            //履歴取得
                            Button(action: {
//                                DataParse.shared.changeMode(modeStr: Const.goModeOne)
                                SBMSDK.shared.setupHistoryMode(DataParse.shared.tmpDeviceName!)
                                DataParse.shared.initMeasure(isRead: true)
                                DataParse.shared.getAllHistory()
                            }, label: {
                                Text("履歴取得")
                                    .padding(10)
                            })
                            //日付の設定
                            Button(action: {
                                DataParse.shared.setIpadTime()
                            }, label: {
                                Text("日付の設定")
                                    .padding(10)
                            })
                        }
                        .onAppear{
                            // セントラルマネージャーを初期化する。
//                            Bluetooth.shared.setCentralManager()
                            SBMSDK.shared.initialize()
                            // セントラルのBluetoothがONになっているか確認、OFFの場合は通知表示->接続可能な全てのペリフェラルを検知
                            SBMSDK.shared.stopScan()
                        }
                    }
                }
            }
        }
        
        
    }
    // ペリフェラルを一つ以上検知できていれば成功
//    func testScanPeripheral() -> String {
//        if Bluetooth.shared.peripheralSet.count > 0 {
//            return "test succeed"
//        } else {
//            return "test failed"
//        }
//    }
    // ペリフェラルに接続できていれば成功
//    func testConnectPeripheral() -> String {
//        if Bluetooth.shared.isConnect {
//            return "test succeed"
//        } else {
//            return "test failed"
//        }
//    }
    // ペリフェラルの接続を解除する
//    func testDisconnectPeripheral() -> String {
//        Bluetooth.shared.disconnectPeripheral()
//        if Bluetooth.shared.connectPeri?.state == .disconnected {
//            return "test succeed"
//        } else {
//            return "test failed"
//        }
//    }
    private func isSBMName(_ name:String?) -> Bool {
        guard name!.prefix(2) == "RN" else {
            return false
        }
        return true
    }

    //デバイス検知後にデバイスの一覧を取得する
    func peripheralList() {
//        let names = Bluetooth.shared.getPeripheralNames(nil)
//        var result:[String] = []
//        for name in names {
//            if isSBMName(name) {
//                result.append(name)
//            }
//        }
        deviceList = SBMSDK.shared.getPeripheralNames()
    }
    //選択したデバイスをbluetooth接続する
    func selectedDevice(_ selected: String) {
        // 検知の処理は動き続け、検知したデバイス一覧の中にtmpDeviceがあれば接続し、検知の処理をストップする
        DataParse.shared.tmpDeviceName = selected
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
        }
    }
}


