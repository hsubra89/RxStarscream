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
    case DataMessage(data: NSData)
    case TextMessage(message: String)
}

public let RxWebSocketErrorDomain = "RxWebSocketErrorDomain"

// fix for generic Apple compiler message
public typealias RxWebSocket = RxWebSocket_<Void>
public class RxWebSocket_<_Void>: Observable<WebSocketEvent> {
    
    let url: NSURL
    let protocols: [String]
    
    init(url: NSURL, protocols: [String]) {
        self.url = url
        self.protocols = protocols
    }
    
    public override func subscribe<O : ObserverType where O.Element == WebSocketEvent>(observer: O) -> Disposable {
        weak var weakWebSocket: WebSocket? = nil
        let webSocket = WebSocket(url: url, protocols: protocols, connect: { () -> Void in
            if let webSocket = weakWebSocket {
                sendNext(observer, .Connected(socket: webSocket))
            }
            }, disconnect: { (error) -> Void in
                println(error)
                sendError(observer, error ?? NSError(domain: RxWebSocketErrorDomain, code: -1, userInfo: nil))
            }, text: { text -> Void in
                sendNext(observer, .TextMessage(message: text))
            }, data: { data -> Void in
                sendNext(observer, .DataMessage(data: data))
        })
        
        weakWebSocket = webSocket
        
        webSocket.connect()
        
        return AnonymousDisposable {
            webSocket.disconnect()
        }
    }
}