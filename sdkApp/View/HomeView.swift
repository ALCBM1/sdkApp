//
//  HomeView.swift
//  SbmSdk
//
//  Created by shoma on 2022/08/09.
//

import SwiftUI

struct HomeView: View {
    @State var displayContentViewView: Bool = false
    @State var displayCommandViewView: Bool = false
    @State var displayMeasureViewView: Bool = false
    var body: some View {
        Text("Ver 01.02.03(2024/01/31)")
        NavigationView {
            VStack{
//                NavigationLink(destination: ContentView(), isActive: $displayContentViewView) {
//                    Text("動作検証画面")
//                }.padding()
                NavigationLink(destination: CommandView(), isActive: $displayCommandViewView) {
                    Text("コマンド画面")
                }.padding()
                NavigationLink(destination: MeasureView(), isActive: $displayMeasureViewView) {
                    Text("計測機能簡易画面")
                }.padding()
            }
            
        }.navigationViewStyle(.stack)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
