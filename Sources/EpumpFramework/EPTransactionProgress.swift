//
//  EPTransactionProgress.swift
//  EpumpFramework
//
//  Created by Fuelmetrics Limited on 28/01/2021.
//

import SwiftUI

public struct EPTransactionProgress{
    public struct ProgressView: View{
        @Environment(\.presentationMode) var presentationMode
        @State var displayText: String = ""
        
        public var body: some View{
            VStack{
                Text(displayText).foregroundColor(.white)
                    .frame(alignment: .center)
                
                Button(action: {
                    self.presentationMode.wrappedValue.dismiss()
                }){
                    Text("Cancel")
                }
            }
            .padding()
            .background(Color.red)
            .frame(minWidth: .infinity, minHeight: .infinity)
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("tcp_message"))){
                (output) in
                let ww = output.userInfo?["socketMessage"] as? String ?? "{}"
                debugPrint(ww)
                displayText = ww
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("tcp_connection_status"))){
                (output) in
                debugPrint(output)
            }
        }
    }
}
