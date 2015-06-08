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
        // This is an example of a functional test case.
        let expectation = expectationWithDescription("Websocket test")
        
        var numberOfStringsReceived = 0
        
        let socketCommunication = { (event: WebSocketEvent) -> Void in
            switch event {
            case .Connected(socket: let socket):
                socket.writeString("Sending string 1")
                socket.writeString("Sending string 2")
                socket.writeString("Sending string 3")
            case .DataMessage(data: let data):
                println("Recevied data: \(data)")
            case .TextMessage(message: let message):
                println("Received string: \(message)")
                numberOfStringsReceived++
                if numberOfStringsReceived == 3 {
                    expectation.fulfill()
                }
            }
        }
        
        let subscription = self.ws
            >- subscribe({ (event) -> Void in
                
                switch event {
                case .Completed:
                    XCTAssert(false, "This should never happen")
                    break
                case .Next(let boxedNext):
                    socketCommunication(boxedNext.value)
                case .Error(let err):
                    println("Error occurred :\n")
                    println(err)
                }
            })
        
        setTimeout(5, { () -> () in
            println("running after 5 seconds")
            subscription.dispose()
        })
        
        waitForExpectationsWithTimeout(10, handler: { (e) -> Void in
            if e != nil {
                println("Error Occurred : \n")
                println(e!)
                return
            }
            
            println("Completed Successfully")
        })
    }
}