//
//  RxStarscream.swift
//  RxStarscream
//
//  Created by Harish Subramanium on 4/06/2015.
//
//

import RxSwift
import Starscream

public enum WebSocketEvent {
    case Connected(socket: WebSocket)
    case Disconnected(socket: WebSocket)
    case DataMessage(socket: WebSocket, data: NSData)
    case TextMessage(socket: WebSocket, message: String)
}

public let RxWebSocketErrorDomain = "RxWebSocketErrorDomain"


/** @hsubra89's approach

 * Trying to keep this as a subclass of WebSocket so that the source interface isn't changed.

 * The source websocket could also be exposed using @kzaher's approach but that would mean the customizations on them would be lost and would need a minimal amount of code refactoring.

 * There are a few reasons why access to the source `WebSocket` object is required.

 * 1) Customizing headers on the source WebSocket object. For example, services that are hidden behind a secure layer might need additional headers/cookies attached (in some cases, XSRF-TOKEN's), which can only happen when the source layer is exposed.

 * 2) Serve as a drop-in replacement to existing implementations of Starscream. i.e, projects that currently use Starscream can simply change the constructor from `WebSocket` to `RxWebSocket` and then all the original modifications on them continue to work (such as adding additional header's from the above point). It also allows them to call the RxObservable function on the resulting class to start the sequence.

 * 3) Allows the websocket to be disconnected when the app goes into the background; ( `ws.disconnect()`) effectively pausing the sequence. When the app comes back to the foreground, calling `ws.connect()` will restore the connection resuming the sequence. This scenario is ideal for most apps.

 * Since the source WebSocket needs to be exposed, i've implemented a private delegate class with handling happening within them. I attempted to follow @kzaher's approach by having the handling passed through the Websocket constructor; but those closures are marked as private within starscream and dosen't let me override them, which means the only viable approach was a private delegate class. (Not sure if there's a better way to deal with this)

 */
class RxWebSocket: WebSocket {
    
    private class RxWebSocketDelegate: WebSocketDelegate {
        
        var observable: ObserverOf<WebSocketEvent>
        
        init(observable: ObserverOf<WebSocketEvent>) {
            self.observable = observable
        }
        
        func websocketDidReceiveData(socket: WebSocket, data: NSData) {
            sendNext(observable, WebSocketEvent.DataMessage(socket: socket, data: data))
        }
        
        func websocketDidReceiveMessage(socket: WebSocket, text: String) {
            sendNext(observable, WebSocketEvent.TextMessage(socket: socket, message: text))
        }
        
        func websocketDidConnect(socket: WebSocket) {
            sendNext(observable, WebSocketEvent.Connected(socket: socket))
        }
        
        func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
            
            // Clean Disconnect
            if error?.code == 1000 {
                sendNext(observable, WebSocketEvent.Disconnected(socket: socket))
                return
            }
            
            // Thrown after disconnection. Not sure if this is a bug with starscream.
            // Temporarily handling it this way
            if error == nil || error?.code == 1 {
                return
            }
            
            // Websocket Error
            sendError(observable, error ?? NSError(domain: RxWebSocketErrorDomain, code: -1, userInfo: nil))
            
            // Remove Delegate
            socket.delegate = nil
        }
    }
    
    // Setting this so that a weak reference for websocket within Starscream is maintained.
    // https://github.com/daltoniam/Starscream/issues/35
    private var rxDelegate: RxWebSocketDelegate!
    
    func rxObservable() -> Observable<WebSocketEvent> {
        
        return create { observable in
            
            self.rxDelegate = RxWebSocketDelegate(observable: observable)
            self.delegate = self.rxDelegate
            
            if !self.isConnected {
                self.connect()
            }
            
            return AnonymousDisposable {
                self.delegate = nil
                self.disconnect()
                sendCompleted(observable)
            }
        }
    }
}

// @kzaher's approach
// fix for generic Apple compiler message
//public typealias RxWebSocket = RxWebSocket_<Void>
//public class RxWebSocket_<_Void>: Observable<WebSocketEvent> {
//    
//    let url: NSURL
//    let protocols: [String]
//    
//    init(url: NSURL, protocols: [String]) {
//        self.url = url
//        self.protocols = protocols
//    }
//    
//    public override func subscribe<O : ObserverType where O.Element == WebSocketEvent>(observer: O) -> Disposable {
//        weak var weakWebSocket: WebSocket? = nil
//        let webSocket = WebSocket(url: url, protocols: protocols, connect: { () -> Void in
//            if let webSocket = weakWebSocket {
//                sendNext(observer, .Connected(socket: webSocket))
//            }
//            }, disconnect: { (error) -> Void in
//                println(error)
//                sendError(observer, error ?? NSError(domain: RxWebSocketErrorDomain, code: -1, userInfo: nil))
//            }, text: { text -> Void in
//                sendNext(observer, .TextMessage(message: text))
//            }, data: { data -> Void in
//                sendNext(observer, .DataMessage(data: data))
//        })
//        
//        weakWebSocket = webSocket
//        
//        webSocket.connect()
//        
//        return AnonymousDisposable {
//            webSocket.disconnect()
//        }
//    }
//}