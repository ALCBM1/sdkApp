//
//  Date+Add.swift
//  SbmSdk
//
//  Created by Yurie Shibata on 2022/07/29.
//

import Foundation

extension Date {
    //fomatを与えて文字列を取得
    func getDateStr(format:String)->String{
        let dateFormater = DateFormatter()
        dateFormater.locale = Locale(identifier: "ja_JP")
        dateFormater.dateFormat = format
        let date = dateFormater.string(from: self)
        return date
    }
}
