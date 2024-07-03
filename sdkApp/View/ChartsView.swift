//
//  ChartsView.swift
//  SbmSdk
//
//  Created by shoma on 2022/08/23.
//

import SwiftUI
import Charts

struct LineChart : UIViewRepresentable {
    
    @Binding var chartLabel: String?
    @Binding var xValue: [String]?
    @Binding var yValue: [Double]
    let scale: CGFloat?
    
    typealias UIViewType = LineChartView
 
    func makeUIView(context: Context) -> LineChartView {
        let lineChartView = LineChartView()
        lineChartView.backgroundColor = UIColor.white
        lineChartView.zoom(scaleX: scale ?? 3, scaleY: 0, x: 0, y: 0)
        
        var dataSets = [LineChartDataSet]()
        
        // y軸に値をぶち込む
        let entries = yValue.enumerated().map{ ChartDataEntry(x: Double($0.offset), y: $0.element as! Double) }
        let dataSet = LineChartDataSet(entries: entries, label: chartLabel ?? "")
        dataSets.append(dataSet)
        lineChartView.data = LineChartData(dataSets: dataSets)
        
        // x軸に値をぶち込む
        if let xValue = xValue {
            lineChartView.xAxis.valueFormatter = IndexAxisValueFormatter(values:xValue)
            lineChartView.xAxis.labelCount = xValue.count
            lineChartView.xAxis.granularity = 1.0
        }
        // x軸ラベルをグラフの下に表示する
        lineChartView.xAxis.labelPosition = .bottom
        // 右側の縦軸ラベルを非表示
        lineChartView.rightAxis.enabled = false
        // x軸の線を非表示
        lineChartView.xAxis.drawGridLinesEnabled = false
        lineChartView.xAxis.drawAxisLineEnabled = false
        
        return lineChartView
    }
    
    func updateUIView(_ uiView: LineChartView, context: Context) {
        uiView.backgroundColor = UIColor.white
        uiView.zoom(scaleX: scale ?? 3, scaleY: 0, x: 0, y: 0)
        
        var dataSets = [LineChartDataSet]()
        
        // y軸に値をぶち込む
        let entries = yValue.enumerated().map{ ChartDataEntry(x: Double($0.offset), y: $0.element as! Double) }
        let dataSet = LineChartDataSet(entries: entries, label: chartLabel ?? "")
        dataSets.append(dataSet)
        uiView.data = LineChartData(dataSets: dataSets)
        
        // x軸に値をぶち込む
        if let xValue = xValue {
            uiView.xAxis.valueFormatter = IndexAxisValueFormatter(values:xValue)
            uiView.xAxis.labelCount = xValue.count
            uiView.xAxis.granularity = 1.0
        }
        // x軸ラベルをグラフの下に表示する
        uiView.xAxis.labelPosition = .bottom
        // 右側の縦軸ラベルを非表示
        uiView.rightAxis.enabled = false
        // x軸の線を非表示
        uiView.xAxis.drawGridLinesEnabled = false
        uiView.xAxis.drawAxisLineEnabled = false
    }
    
}
