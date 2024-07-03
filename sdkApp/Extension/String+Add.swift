//
//  String+Add.swift
//  SbmSdk
//
//  Created by Yurie Shibata on 2022/07/25.
//

import Foundation

extension String {
    
    /// 日付フォーマットを変換する。
    func getDateFromStr(format:String)->Date?{
        let dateFormater = DateFormatter()
        dateFormater.locale = Locale(identifier: "ja_JP")
        dateFormater.dateFormat = format
        let date = dateFormater.date(from: self)
        return date
    }
    
    /// 空白を削除する。
    func deleteWhiteSpace() -> String{
        return self.replacingOccurrences(of: " ", with: "")
    }

    /// 改行を削除する。
    func deleteNewLine() -> String{
        return self.replacingOccurrences(of: "\r\n", with: "")
    }

    /// 改行を削除する。
    func deleteNewLineLF() -> String{
        return self.replacingOccurrences(of: "\n", with: "")
    }

    /// 1行目の文字列のみ取り出す。
    func separateNewLine() -> String{
        let separate = self.components(separatedBy: "\r\n")
        if separate.count != 0{
            return separate[0]
        }
        return ""
    }
}
