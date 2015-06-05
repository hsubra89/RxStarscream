//
//  RxStarscream.swift
//  RxStarscream
//
//  Created by Harish Subramanium on 4/06/2015.
//
//

import RxSwift
import Starscream

// Approach 1
class RxWebSocket: WebSocket {
    
    // Setting this so that a weak reference for websocket within Starscream is maintained.
    // https://github.com/daltoniam/Starscream/issues/35
    var rxDelegate: RxWebSocketDelegate!
    var rxSequence: Observable<AnyObject>? = nil
    
    func rxObservable() -> Observable<AnyObject> {
        
        if self.rxSequence != nil {
            return self.rxSequence!
        }
        
        var rxSequence: Observable<AnyObject> = create { observable in
            
            self.rxDelegate = RxWebSocketDelegate(observable: observable)
            self.delegate = self.rxDelegate
            
            if !self.isConnected {
                self.connect()
            }
            
            return AnonymousDisposable {
                self.disconnect()
            }
        }
        
        self.rxSequence = rxSequence
        return rxSequence
    }
    
}

class RxWebSocketDelegate: WebSocketDelegate {
    
    var observable: ObserverOf<AnyObject>
    
    init(observable: ObserverOf<AnyObject>) {
        self.observable = observable
    }
    
    func websocketDidReceiveData(socket: WebSocket, data: NSData) {
        sendNext(observable, data)
    }
    
    func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        sendNext(observable, text)
    }
    
    func websocketDidConnect(socket: WebSocket) { }
    
    func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        sendCompleted(observable)
        socket.delegate = nil
    }
    
}