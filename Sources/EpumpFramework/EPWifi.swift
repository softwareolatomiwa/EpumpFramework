//
//  EPWifi.swift
//  EpumpFramework
//
//  Created by Fuelmetrics Limited on 26/01/2021.
//

import Network
import NetworkExtension
import SwiftUI

public class EPWifi {
    //var status: String = ""
    var notifier: NotificationCenter?
    var connection: NWConnection?
    var ip: Network.NWEndpoint.Host
    var port: Network.NWEndpoint.Port
    var ssid: String
    var password: String
    var comm_channel: String
    var pump_name: String
    var encryptionKey: String
    var phone: String
    var wifiConnect: NEHotspotConfigurationManager
    var disconnected: Bool
    
    /// Connect to WiFi ssid with passphrase and upon successful coonnection, connect to socket using the IP and Port and send intialization message to server
    /// - Parameters:
    ///   - ssid: SSID to connect to
    ///   - passphrase: Passphrase of the WiFi
    ///   - ip: Socket IP
    ///   - port: Socket Port
    ///   - encryptionKey: Epump Daily Encryption Key
    ///   - comm_channel: Communication Channel (Remis - r, Voucher - v)
    ///   - pump_name: Communication Channel (Remis - r, Voucher - v)
    ///   - phone: User Phone Number (optional for voucher)
    public init(ssid: String, passphrase: String, ip: String, port: Int, encryptionKey: String, comm_channel: String, pump_name: String, phone: String){
        self.ssid = ssid
        self.password = passphrase
        self.ip = NWEndpoint.Host.init(ip)
        self.port = NWEndpoint.Port.init(rawValue: UInt16(port)) ?? 5555
        self.comm_channel = comm_channel
        self.pump_name = pump_name
        self.phone = phone
        self.encryptionKey = encryptionKey
        self.wifiConnect = NEHotspotConfigurationManager.shared
        self.disconnected = false
        
        self.connectWifi(ssid: ssid, password: password)
        
        notifier = NotificationCenter.default
        NotificationCenter.default.addObserver(self, selector: #selector(connectionCloseEvent), name: Notification.Name("tcp_close_connection"), object: nil)
    }
    
    @objc func connectionCloseEvent(_:Notification) {
        self.endConnection()
    }
    
    private func connectWifi(ssid: String, password: String){
        let configuration = NEHotspotConfiguration.init(ssid: ssid, passphrase: password, isWEP: false)
        configuration.joinOnce = true
        self.wifiConnect.apply(configuration, completionHandler: {
            (error) in
            if error != nil{
                if let errorStr = error?.localizedDescription {
                    self.manageStatus(errorStr)
                }
                if (error?.localizedDescription == "already associated.") {
                    self.manageStatus("Connected to WiFi!")
                    self.connectSocket()
                } else {
                    self.manageStatus("Not Connected!")
                }
            }
            else{
                self.manageStatus("Connected to WiFi!")
                self.connectSocket()
            }
        })
    }
    
    private func connectSocket() {
        let connection = NWConnection(host: self.ip, port: self.port, using: .tcp)
        connection.stateUpdateHandler = self.stateDidChange(to:)
        self.setupReceive(on: connection)
        connection.start(queue: .main)
        self.connection = connection
    }
    
    private func stateDidChange(to state: NWConnection.State) {
        switch state {
        case .setup:
            manageStatus("Setting Up Connection")
            break
        case .waiting( _):
            manageStatus("Waiting for Connection")
            break
        case .preparing:
            manageStatus("Preparing Connection")
            break
        case .ready:
            if !self.disconnected{
                manageStatus("Successfully Connected")
                manageConnectedStatus("true")
                initMessage()
            }
            break
        case .failed(let error):
            self.connectionDidFail(error: error)
            break
        case .cancelled:
            manageStatus("Disconnected")
            self.wifiConnect.removeConfiguration(forSSID: self.ssid)
            break
        @unknown default:
            break
        }
    }
    
    private func initMessage(){
        let conn_id = Utility.randomString(len: 6)
        let serverKey = self.encryptionKey
        let phone = self.phone
        let stringToHash = "\(serverKey)\(phone)\(self.pump_name)\(conn_id)"
        let hash = Utility.sha1Hash(message: stringToHash)
        var conn_msg = EPConnectionMessage()
        conn_msg.ch = self.comm_channel
        
        switch self.comm_channel {
            case Comm_Channel.Remis.rawValue:
                conn_msg.sh = hash
                conn_msg.tg = phone
            default:
                break
        }
        
        conn_msg.sid = conn_id
        conn_msg.pn = self.pump_name
        
        let jsonEncoder = JSONEncoder()
        let jsonData = try? jsonEncoder.encode(conn_msg)
        let json = String(data: jsonData!, encoding: .utf8)
        
        self.sendMessage(message: json!)
    }
    
    private func setupReceive(on connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 1024) { (data, contentContext, isComplete, error) in
            if let data = data, !data.isEmpty {
                // … process the data …
                let msg = String(data: data, encoding: .utf8)
                self.notify(receiver: "tcp_message", message: msg!)
                
                let decoder = JSONDecoder()
                let socketResp = try! decoder.decode(SocketResponse.self, from: data)
                
                if socketResp.tk != -1 && socketResp.tk != 0 {
                    self.replyToken(token: socketResp.tk)
                }
            }
            if let error = error {
                NSLog("did receive, error: %@", "\(error)")
                self.connectSocket()
                return
            }
            if isComplete {
                // … handle end of stream …
                //self.endConnection()
            } else if let error = error {
                // … handle error …
                self.connectionDidFail(error: error)
            } else {
                self.setupReceive(on: connection)
            }
        }
    }
    
    public func sendMessage(message: String){
        let data = message.data(using: .utf8)
        if connection != nil {
            connection?.send(content: data, completion: NWConnection.SendCompletion.contentProcessed { error in
                if let error = error {
                    NSLog("did send, error: %@", "\(error)")
                    self.endConnection()
                } else {
                    NSLog("did send, data: %@", data! as NSData)
                }
            })
        }
    }
    
    private func replyToken(token: CLong){
        let msg = "{\"tk\":\(token),\"st\":0}"
        sendMessage(message: msg)
    }
    
    public func endConnection(){
        self.connection?.forceCancel()
        manageConnectedStatus("false")
        self.connection = nil
        self.disconnected = true
    }
    
    private func connectionDidFail(error: Error) {
        manageStatus(error.localizedDescription)
    }

    private func EOF(status: String) {
        manageStatus(status)
    }
    
    private func manageStatus(_ status: String){
        self.notify(receiver: "tcp_connection_status", message: status)
    }
    
    private func manageConnectedStatus(_ status: String){
        self.notify(receiver: "tcp_connection", message: status)
    }
    
    private func notify(receiver: String, message: String){
        notifier?.post(name: NSNotification.Name(receiver), object: nil, userInfo: ["socketMessage": message])
    }
    
    
    public struct showTransactionProgress: View {
        public var body: some View{
            EPTransactionProgress.ProgressView()
        }
    }
}
