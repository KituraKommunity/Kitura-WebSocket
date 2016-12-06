/**
 * Copyright IBM Corporation 2016
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

import XCTest

@testable import KituraWebSocket
@testable import KituraNet
import Socket

import Foundation
import Dispatch

protocol KituraTest {
    func expectation(line: Int, index: Int) -> XCTestExpectation
    func waitExpectation(timeout t: TimeInterval, handler: XCWaitCompletionHandler?)
}

extension KituraTest {
    
    func doSetUp() {
        PrintLogger.use()
    }
    
    func doTearDown() {
        ConnectionUpgrader.clear()
    }
    
    func performServerTest(_ router: ServerDelegate, line: Int = #line,
                           asyncTasks: @escaping (XCTestExpectation) -> Void...) {
        let server = HTTP.createServer()
        server.delegate = router
        
        do {
            try server.listen(on: 8090)
        
            let requestQueue = DispatchQueue(label: "Request queue")
        
            for (index, asyncTask) in asyncTasks.enumerated() {
                let expectation = self.expectation(line: line, index: index)
                requestQueue.async() {
                    asyncTask(expectation)
                }
            }
        
            waitExpectation(timeout: 100) { error in
                // blocks test until request completes
                server.stop()
                XCTAssertNil(error)
            }
        }
        catch {
            XCTFail("Test failed. Error=\(error)")
        }
    }
    
    func sendUpgradeRequest(forProtocolVersion: String?, toPath: String, usingKey: String?) -> Socket? {
        var socket: Socket?
        do {
            socket = try Socket.create()
            try socket?.connect(to: "localhost", port: 8090)
            
            var request = "GET " + toPath + " HTTP/1.1\r\n" +
                "Host: localhost:8090\r\n" +
                "Upgrade: websocket\r\n" +
                "Connection: Upgrade\r\n"
            
            if let protocolVersion = forProtocolVersion {
                request += "Sec-WebSocket-Version: " + protocolVersion + "\r\n"
            }
            if let key = usingKey {
                request += "Sec-WebSocket-Key: " + key + "\r\n"
            }
            
            request += "\r\n"
            
            guard let data = request.data(using: .utf8) else { return nil }
            
            try socket?.write(from: data)
        }
        catch let error {
            socket = nil
            XCTFail("Failed to send upgrade request. Error=\(error)")
        }
        return socket
    }
    
    func processUpgradeResponse(socket: Socket) -> (HTTPIncomingMessage?, NSData?) {
        let response: HTTPIncomingMessage = HTTPIncomingMessage(isRequest: false)
        var unparsedData: NSData?
        var errorFlag = false
        
        var keepProcessing = true
        let buffer = NSMutableData()
        
        do {
            while keepProcessing {
                buffer.length = 0
                let count = try socket.read(into: buffer)
                
                if count != 0 {
                    let parserStatus = response.parse(buffer)
                    
                    if parserStatus.state == .messageComplete {
                        keepProcessing = false
                        if parserStatus.bytesLeft != 0 {
                            unparsedData = NSData(bytes: buffer.bytes+buffer.length-parserStatus.bytesLeft, length: parserStatus.bytesLeft)
                        }
                    }
                }
                else {
                    keepProcessing = false
                    errorFlag = true
                    XCTFail("Server closed socket prematurely")
                }
            }
        }
        catch let error {
            errorFlag = true
            XCTFail("Failed to send upgrade request. Error=\(error)")
        }
        return (errorFlag ? nil : response, unparsedData)
    }
}

extension XCTestCase: KituraTest {
    func expectation(line: Int, index: Int) -> XCTestExpectation {
        return self.expectation(description: "\(type(of: self)):\(line)[\(index)]")
    }
    
    func waitExpectation(timeout t: TimeInterval, handler: XCWaitCompletionHandler?) {
        self.waitForExpectations(timeout: t, handler: handler)
    }
}

