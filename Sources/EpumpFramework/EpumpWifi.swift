//
//  EpumpWifi.swift
//  EpumpFramework
//
//  Created by Fuelmetrics Limited on 26/01/2021.
//

import Network
import NetworkExtension

public class EpumpWifi{
    //var status: String = ""
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
    }
    
    private func connectWifi(ssid: String, password: String){
        let configuration = NEHotspotConfiguration.init(ssid: ssid, passphrase: password, isWEP: true)
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
            self.connectionDidFail(error: error)
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
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { (data, contentContext, isComplete, error) in
            if let data = data, !data.isEmpty {
                // … process the data …
                self.manageStatus("did receive \(data.count) bytes")
            }
            if isComplete {
                // … handle end of stream …
                self.stop(status: "EOF")
            } else if let error = error {
                // … handle error …
                self.connectionDidFail(error: error)
            } else {
                self.setupReceive(on: connection)
            }
        }
    }
    
    private func connectionDidFail(error: Error) {
        manageStatus(error.localizedDescription)
    }

    private func stop(status: String) {
        manageStatus(status)
    }
    
    private func manageStatus(_ status: String){
        debugPrint(status)
    }
}
