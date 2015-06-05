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
        self.ws = RxWebSocket(url: NSURL(string: "wss://echo.websocket.org")!)
    }
    
    func testRxStream() {
        // This is an example of a functional test case.
        let expectation = expectationWithDescription("Websocket test")
        
        var wsSequence = self.ws.rxObservable()
        
        wsSequence
            >- subscribe({ (event) -> Void in
                
                switch event {
                case .Completed:
                    println("Disconnected")
                    expectation.fulfill()
                    
                case .Next(let boxedVal):
                    let val: AnyObject = boxedVal.value
                    
                    if let text = val as? String {
                        println("Received string: \(text)")
                    }
                    
                    if let data = val as? NSData {
                        println("Recevied data: \(data)")
                    }
                
                case .Error(let err):
                    println("Error occurred :\n")
                    println(err)
                }
            })
        
        ws.writeString("Sending string 1")
        ws.writeString("Sending string 2")
        ws.writeString("Sending string 3")
        
        setTimeout(5, { () -> () in
            println("running after 5 seconds")
            self.ws.disconnect()
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
