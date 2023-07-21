//
//  NWCode.swift
//  TestNW
//
//  Created by Ken Hardy on 21/11/2022.
//

import Foundation
import Network

/*
var socket: TcpSocket!
var loop = 2
var count = 0

func canSend() -> Void {

    let data = loop == 2 ? "First Message".data(using: .utf8)!
                         : "Second Message".data(using: .utf8)!
    if loop > 0 {
        socket.send(data: data)
        loop -= 1
    }
}

func didReceive(_ data: Data) -> Void {
    count += 1
    print(data)
    if count > 1 {
        socket.stop()
    }
}

func didFail() -> Void {
    
}

func startNW() -> Void {
    loop = 2
    count = 0
    socket = TcpSocket(hostName: "192.168.0.158", hostPort: 8011, canSend: canSend, didReceive: didReceive)
    socket.start()
    socket.receive()
}
 */

enum SocketStatus {
    case created
    case connected
    case closed
}

class TcpSocket {
    let connection: NWConnection
    var queue = DispatchQueue(label: "TCP Client Queue", qos: .userInitiated)
    var retResult: Bool
    var retError: String = ""
    var socketStatus = SocketStatus.created
    
    let debug = false
    
    var tag : String = ""
    
    var timer: Timer?
    
    var didFail: () -> Void
    var canSend: () -> Void
    var didReceive: (_ data: Data, _ isComplete: Bool) -> Void
    
    init(hostName: String, hostPort: Int, canSend: @escaping () -> Void, didReceive: @escaping (_ data: Data, _ isComplete: Bool) -> Void, didFail: @escaping () -> Void) {
        let host = NWEndpoint.Host(hostName)
        let port = NWEndpoint.Port("\(hostPort)")!
        let options = NWProtocolTCP.Options()
        options.connectionTimeout = 5
        let params = NWParameters(tls: nil, tcp: options)
        self.connection = NWConnection(host: host, port: port, using: params)
        self.retResult = false
        self.retError = ""
        self.canSend = canSend
        self.didReceive = didReceive
        self.didFail = didFail
        self.socketStatus = .created
    }
    
    func start() {
        self.connection.stateUpdateHandler = self.didChange(state:)
        self.connection.start(queue: queue)
    }
    
    func stop() {
        self.connection.cancel()
        socketStatus = .closed
    }
    
    func didChange(state: NWConnection.State) {
        if debug { print("\(self.tag) SocketStatus \(state)") }
        switch state {
        case .setup:
            break
        case .ready:
            socketStatus = .connected
            self.canSend()
        case .waiting(let error):
            self.retResult = false
            if self.retError == "" { self.retError = error.debugDescription }
            self.didFail()
            self.socketStatus = .closed
        case .preparing:
            break
        case .failed(let error):
            self.retResult = false
            if self.retError == "" { self.retError = error.debugDescription }
            self.didFail()
            self.socketStatus = .closed
        case .cancelled:
            self.socketStatus = .closed
        default:
            break
        }
    }
    
    func send(data: Data) -> Void {
        connection.send(content: data, completion: NWConnection.SendCompletion.contentProcessed({error in
            if error != nil {
                if self.debug { print("\(self.tag) \(error!)") }
                self.retResult = false
                if self.retError == "" { self.retError = error!.debugDescription }
                self.stop()
            } else {
                if self.debug { print("\(self.tag) \(data.count) bytes sent") }
                self.canSend()
            }
        }))
        
    }
    
    @objc func timerFired() {
        self.stop()
        self.retResult = false
        if self.retError == "" { self.retError = "Receive timeout" }
        self.didFail()
    }
    
    func receive() -> Void {

        //self.timer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(self.timerFired), userInfo: nil, repeats: false)
        //RunLoop.current.add(self.timer!, forMode: .common)
        //self.timer = Timer.scheduledTimer(withTimeInterval: 1 * 10, repeats:false) {_ in
        //    self.stop()
        //    self.retResult = false
        //    if self.retError == "" { self.retError = "Receive timeout" }
        //    self.didFail()
        //}
        //}
        connection.receive(minimumIncompleteLength: 1, maximumLength: 4096, completion: {
            (data, context, isComplete, error) in
            self.timer?.invalidate()
            if let error = error {
                self.stop()
                self.retResult = false
                if self.retError == "" { self.retError = error.debugDescription }
                if self.debug { print("\(self.tag) \(error)") }
            } else {
                if let data = data {
                    if self.debug { print("\(self.tag) \(data.count) bytes received") }
                    self.didReceive(data, isComplete)
                } else {
                    if self.debug { print("\(self.tag) no data") }
                    self.retResult = false
                    if self.retError == "" { self.retError = "Receive timeout" }
                    self.didFail()
                }
            }
        })
    }
}
