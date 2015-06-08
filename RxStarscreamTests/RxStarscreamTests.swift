//
//  RxStarscreamTests.swift
//  RxStarscreamTests
//
//  Created by Harish Subramanium on 4/06/2015.
//
//

import UIKit
import XCTest

import RxSwift
import Starscream

func setTimeout(duration: Int, callback: ()->()) {
    var delta: Int64 = Int64(duration) * Int64(NSEC_PER_SEC)
    var time = dispatch_time(DISPATCH_TIME_NOW, delta)
    dispatch_after(time, dispatch_get_main_queue(), callback)
}

class RxStarscreamTests: XCTestCase {
    
    var ws: RxWebSocket!
    
    override func setUp() {
        self.ws = RxWebSocket(url: NSURL(string: "wss://echo.websocket.org")!, protocols: [])
    }
    
    func testRxStream() {

        let expectation = expectationWithDescription("Websocket test")
        
        let socketCommunication = { (event: WebSocketEvent) -> Void in
            switch event {
            case .Connected(socket: let socket):
                println("Connected to WebSocket")
            case .DataMessage(_, data: let data):
                println("Recevied data: \(data)")
            case .TextMessage(_, message: let message):
                println("Received string: \(message)")
            case .Disconnected(socket: let socket):
                println("Disconnected")
            }
        }
        
        let subscription = self.ws.rxObservable()
            >- subscribe({ (event) -> Void in
                switch event {
                case .Completed:
                    expectation.fulfill()
                case .Next(let boxedNext):
                    socketCommunication(boxedNext.value)
                case .Error(let err):
                    println("Error occurred :\n")
                    println(err)
                }
            })
        
        self.ws.writeString("Hello 1")
        self.ws.writeString("Hello 2")
        
        setTimeout(7, { () -> () in
            self.ws.disconnect()
            
            setTimeout(3, { () -> () in
                
                self.ws.connect()
                self.ws.writeString("Hello 3")
                
                setTimeout(7, { () -> () in
                    subscription.dispose()
                })
            })
            
        })
        
        waitForExpectationsWithTimeout(100, handler: { (e) -> Void in
            if e != nil {
                println("Error Occurred : \n")
                println(e!)
                return
            }
            
            println("Completed Successfully")
        })
    }
}