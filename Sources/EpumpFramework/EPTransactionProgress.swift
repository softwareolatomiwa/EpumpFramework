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
        
        public init(){
            self.displayText = ""
        }
        
        public var body: some View{
            VStack{
                Text(displayText).foregroundColor(.white)
                    .frame(alignment: .center)
                
                Button(action: {
                    self.presentationMode.wrappedValue.dismiss()
                    NotificationCenter.default.post(name: NSNotification.Name("tcp_close_connection"), object: nil, userInfo: ["socketMessage": true])
                    
                    NotificationCenter.default.removeObserver(self, name: Notification.Name("tcp_message"), object: nil)
                    NotificationCenter.default.removeObserver(self, name: Notification.Name("tcp_connection_status"), object: nil)
                }){
                    Text("Cancel")
                }
            }
            .padding()
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            .background(Color.red)
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
            .onDisappear(){
                NotificationCenter.default.removeObserver(self, name: Notification.Name("tcp_message"), object: nil)
                NotificationCenter.default.removeObserver(self, name: Notification.Name("tcp_connection_status"), object: nil)
            }
        }
    }
}
