//
//  EPWifi.swift
//  EpumpFramework
//
//  Created by Fuelmetrics Limited on 26/01/2021.
//

import Network
import NetworkExtension


public class EPWifi{
    //var status: String = ""
    var notifier: NotificationCenter?
    var connection: NWConnection?
    var ip: Network.NWEndpoint.Host
    var port: Network.NWEndpoint.Port
    var ssid: String
    var password: String
    
    
    /// Connect to WiFi ssid with passphrase and upon successful coonnection, connect to socket using the IP and Port
    /// - Parameters:
    ///   - ssid: SSID to connect to
    ///   - passphrase: Passphrase of the WiFi
    ///   - ip: Socket IP
    ///   - port: Socket Port
    public init(ssid: String, passphrase: String, ip: String, port: Int){
        self.ssid = ssid
        self.password = passphrase
        self.ip = NWEndpoint.Host.init(ip)
        self.port = NWEndpoint.Port.init(rawValue: UInt16(port)) ?? 5555
        
        self.connectWifi(ssid: ssid, password: password)
        
        notifier = NotificationCenter.default
    }
    
    private func connectWifi(ssid: String, password: String){
        let configuration = NEHotspotConfiguration.init(ssid: ssid, passphrase: password, isWEP: false)
        configuration.joinOnce = true
        NEHotspotConfigurationManager.shared.apply(configuration, completionHandler: {
            (error) in
            if error != nil{
                if let errorStr = error?.localizedDescription {
                    self.manageStatus("Error Information:\(errorStr)")
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
        case .waiting(let error):
            debugPrint(error.debugDescription)
            manageStatus("Waiting for Connection")
        case .preparing:
            manageStatus("Preparing Connection")
        case .ready:
            manageStatus("Successfully Connected")
        case .failed(let error):
            self.connectionDidFail(error: error)
        case .cancelled:
            break
        @unknown default:
            break
        }
    }
    
    private func setupReceive(on connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 1024) { (data, contentContext, isComplete, error) in
            if let data = data, !data.isEmpty {
                // … process the data …
                let msg = String(data: data, encoding: .utf8)
                self.notify(receiver: "remote_message", message: msg!)
            }
            if let error = error {
                NSLog("did receive, error: %@", "\(error)")
                self.connectSocket()
                return
            }
            if isComplete {
                // … handle end of stream …
                self.EOF(status: "EOF")
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
    
    public func endConnection(){
        self.connection?.cancel()
    }
    
    private func connectionDidFail(error: Error) {
        manageStatus(error.localizedDescription)
    }

    private func EOF(status: String) {
        manageStatus(status)
    }
    
    private func manageStatus(_ status: String){
        debugPrint(status)
        self.notify(receiver: "connection_status", message: status)
    }
    
    private func notify(receiver: String, message: String){
        notifier?.post(name: NSNotification.Name(receiver), object: message as AnyObject)
    }
}
