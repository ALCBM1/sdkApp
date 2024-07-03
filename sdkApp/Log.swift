//
//  Log.swift
//  SbmSdk
//
//  Created by Yurie Shibata on 2022/09/29.
//

import Foundation

class Log {
    
    /// ログファイル作成・更新
    /// - parameters type: コマンド
    /// - parameters date: ログ取得日時
    /// - parameters log: ログ情報（計測結果、実行コマンド等）
    /// - parameters error: エラー情報
    func logger(type: Const.LogType, date: Date, log: String, error: String) {
        let fileManager = FileManager.default
        //出力先のパスを取得
        if let dir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).last {
            let path = dir.appendingPathComponent(type.rawValue)
            //ログファイルの存在チェック
            if !fileManager.fileExists(atPath: path.path){
                // ファイルがない場合は作成する
                FileManager.default.createFile(atPath: path.path, contents: nil, attributes: nil)
            }
            do {
                //ファイル読み込み
                let logStr = try String(contentsOf: path, encoding: .utf8)
                //ログの上限チェックのため配列に変換する
                var logList = logStr.components(separatedBy: "\n")
                logList.insert("\(date) : \(log) \(error)", at: 0)
                //エラー関連ログの更新処理
                if type == Const.LogType.Result || type == Const.LogType.Error {
                    //ログ情報が100件を超える場合、一番古いログを削除する
                    if logList.count > Const.errorLogMaxNum {
                        logList.removeLast()
                    }
                }
                //APICommandアクセス関連ログの更新処理
                if type == Const.LogType.System {
                    //ログ情報が10000件を超える場合、一番古いログを削除する
                    if logList.count > Const.accessLogMaxNum {
                        logList.removeLast()
                    }
                }
                //ファイル書き込み
                let wFile = try FileHandle(forWritingTo: path)
                let stringToWrite = logList.joined(separator: "\n")
                //ログ情報を上書き更新
                wFile.write(stringToWrite.data(using: String.Encoding.utf8)!)
            } catch let error as NSError {
                print("*******************************************************")
                print(error)
            }
        }
    }
}
