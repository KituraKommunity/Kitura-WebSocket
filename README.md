
<p align="center">
    <a href="http://kitura.io/">
        <img src="https://raw.githubusercontent.com/KituraKommunity/Kitura/master/Sources/Kitura/resources/kitura-bird.svg?sanitize=true" height="100" alt="Kitura">
    </a>
</p>

<p align="center">
    <a href="https://ibm-swift.github.io/Kitura-WebSocket/index.html">
    <img src="https://img.shields.io/badge/apidoc-KituraWebSocket-1FBCE4.svg?style=flat" alt="APIDoc">
    </a>
    <a href="https://travis-ci.org/KituraKommunity/Kitura-WebSocket">
    <img src="https://travis-ci.org/KituraKommunity/Kitura-WebSocket.svg?branch=master" alt="Build Status - Master">
    </a>
    <img src="https://img.shields.io/badge/os-macOS-green.svg?style=flat" alt="macOS">
    <img src="https://img.shields.io/badge/os-linux-green.svg?style=flat" alt="Linux">
    <img src="https://img.shields.io/badge/license-Apache2-blue.svg?style=flat" alt="Apache 2">
    <a href="http://swift-at-ibm-slack.mybluemix.net/">
    <img src="http://swift-at-ibm-slack.mybluemix.net/badge.svg" alt="Slack Status">
    </a>
</p>

# Kitura-WebSocket

Kitura-WebSocket provides Kitura based servers the ability to receive and send messages to clients using the WebSocket
protocol (RFC 6455). It is compatible with a variety of WebSocket clients, including:
- The built-in WebSocket support in the Chrome, FireFox, and Safari browsers.
- The NPM [websocket](https://www.npmjs.com/package/websocket) package.

Kitura-WebSocket supports version thirteen of the WebSocket protocol.

Both the WS and WSS (SSL/TLS secured WS) protocols are supported by Kitura-WebSocket.
To enable WSS set up your Kitura based server for SSL/TLS support. See the tutorial
[Enabling SSL/TLS on your Kitura server](https://www.kitura.io/guides/building/ssl.html) on
[www.kitura.io](http://www.kitura.io) for details.

## Table of Contents
* [Usage](#usage)
* [API Overview](#api-overview)
* [Autobahn TestSuite](#Autobahn-TestSuite)
* [Example - Simple](#example-simple)
* [Example - Advanced](#example-advanced)
* [API Documentation](#api-documentation)
* [Community](#community)
* [License](#license)

## Usage

#### Add dependencies

Add the `Kitura-WebSocket` package to the dependencies within your application’s `Package.swift` file. Substitute `"x.x.x"` with the latest `Kitura-WebSocket` [release](https://github.com/KituraKommunity/Kitura-WebSocket/releases).

```swift
.package(url: "https://github.com/KituraKommunity/Kitura-WebSocket.git", from: "x.x.x")
```

Add `Kitura-WebSocket` to your target's dependencies:

```swift
.target(name: "example", dependencies: ["Kitura-WebSocket"]),
```

#### Import package

  ```swift
  import KituraWebSocket
  ```

## API Overview
The following is an overview of the Kitura-WebSocket APIs, for more information see the [API reference](https://ibm-swift.github.io/Kitura-WebSocket/index.html).

When using the WebSocket protocol, clients connect to WebSocket services running on a particular server. WebSocket services are identified on a particular server via a path. This path is sent in the upgrade request used to upgrade a connection from HTTP 1.1 to WebSocket.

The Kitura-WebSocket API reflects that interaction using the class `WebSocketConnection` which represents a WebSocket client's connection to a service and the protocol `WebSocketService` which is implemented by classes that are WebSocket services.

A specific `WebSocketConnection` object is connected to a specific `WebSocketService` instance. On the other hand a specific `WebSocketService` instance is connected to many `WebSocketConnection` objects.

### WebSocketConnection
The WebSocketConnection class provides:
- Functions to send text and binary messages to the client.

```swift
WebSocketConnection.send(message: Data)
WebSocketConnection.send(message: String)
```
- Functions to close the connection gracefully and forcefully.

```swift
WebSocketConnection.close(reason: WebSocketCloseReasonCode?=nil, description: String?=nil)
WebSocketConnection.drop(reason: WebSocketCloseReasonCode?=nil, description: String?=nil)
```

In both `close()` and `drop()`, the `WebSocketCloseReasonCode` enum provides the standard WebSocket close reason codes with the ability to specify application specific ones.

- A unique identifier that can be used to help manage the collection of `WebSocketConnection` objects connected to a `WebSocketService`.

```swift
id: String
```

### WebSocketService
The WebSocketService protocol enables Kitura-WebSocket to notify a WebSocket service about a set of events that
occur. These events include:
- A client has connected to the WebSocketService.

```swift
connected(connection: WebSocketConnection)
```

- A client has disconnected from the WebSocketService.

```swift
disconnected(connection: WebSocketConnection, reason: WebSocketCloseReasonCode)
```
The reason parameter contains the reason code associated with the client disconnecting. It may come from either
a close command sent by the client, or be determined by Kitura-WebSocket if the connection's socket suddenly was closed.

- A binary message was received from a client.

```swift
received(message: Data, from: WebSocketConnection)
```
The message parameter contains the bytes of the message in the form of a Data struct.

- A text message was received from a client.

```swift
received(message: String, from: WebSocketConnection)
```
The message parameter contains the message in the form of a String.

#### Detect and close broken connections

WebSocketService protocol has an optional Int property called `connectionTimeout`. This is the time in seconds that a connection must be unresponsive to be automatically closed by the server. If the WebSocket server has not received any messages in the first half of the timeout time it will ping the connection. If a pong is not received in the remaining half of the timeout, the connection will be closed with a 1006 (connection closed abnormally) status code. The `connectionTimeout` defaults to `nil`, meaning no connection cleanup will take place.  

You can set the `connectionTimeout` by assigning a value to the property within your WebSocketService class:

```swift
let connectionTimeout: Int? = 60
```

### WebSocket

Classes which implement the `WebSocketService` protocol are registered with the server as follows:

```swift
WebSocket.register(service: WebSocketService, onPath: String)
```
This function is passed the `WebSocketService` being registered along with the path it is being registered on.

A registered `WebSocketService` can be unregistered from the server as follows:

```swift
WebSocket.unregister(path: String)
```
This function is passed the path which the `WebSocketService` being unregistered was registered on.

## Autobahn TestSuite
Kitura-WebSocket complies to the [Autobahn Testsuite](https://github.com/crossbario/autobahn-testsuite) for web sockets. To create an echo server and run this test suite against it, follow the instructions [here](https://github.com/KituraKommunity/Kitura-WebSocket/blob/master/AutobahnTests.md).

## Example - Simple
This example is a simplistic chat service to demonstrate how to use the Kitura-WebSocket APIs.
The server side is written in Swift using Kitura-WebSocket and the client side is written in JavaScript using
Node.js and the websocket NPM package. The instructions below show you how to create the files for both the server and client and then how to compile and run the application.

### Pre-requisites
In order to run the client one must have Node.js installed.

### The server
The server keeps track of the clients that have connected to it and echoes all text messages sent to it to all
of the clients that have connected to it, with the exception of the client that sent the message.

You will need to create the server's directory structure to be something like this:
<pre>
ServerDirectory
├── Package.swift
└── Sources
    └── ChatServer
        ├── ChatService.swift
        └── main.swift
</pre>

Create a `Package.swift` file with the following content, substituting `"x.x.x"` with the latest releases of Kitura, HeliumLogger and Kitura-WebSocket:

```swift
// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "ChatServer",
    dependencies: [
         .package(url: "https://github.com/KituraKommunity/Kitura.git", .upToNextMinor(from: "x.x.x")),
         .package(url: "https://github.com/KituraKommunity/HeliumLogger.git", from: "x.x.x"),
         .package(url: "https://github.com/KituraKommunity/Kitura-WebSocket.git", from: "x.x.x")
    ],
    targets: [
        .target(
            name: "ChatServer",
            dependencies: ["Kitura", "HeliumLogger", "Kitura-WebSocket"]),
    ]
)
```
The HeliumLogger package, while strictly not required, was added to enable logging.

Create a `ChatService.swift` file which contains:
```swift
// ChatServer is a very simple chat server

import Foundation

import KituraWebSocket

class ChatService: WebSocketService {

    private var connections = [String: WebSocketConnection]()
    
    let connectionTimeout: Int? = 60

    public func connected(connection: WebSocketConnection) {
        connections[connection.id] = connection
    }

    public func disconnected(connection: WebSocketConnection, reason: WebSocketCloseReasonCode) {
        connections.removeValue(forKey: connection.id)
    }

    public func received(message: Data, from: WebSocketConnection) {
        from.close(reason: .invalidDataType, description: "Chat-Server only accepts text messages")

        connections.removeValue(forKey: from.id)
    }

    public func received(message: String, from: WebSocketConnection) {
        for (connectionId, connection) in connections {
            if connectionId != from.id {
                connection.send(message: message)
            }
        }
    }
}
```
The class has a Dictionary, connections, which is used to keep track of the connections of all of the connected clients. The Dictionary is
maintained by the `connected` and `disconnected` functions, which are, respectively, adding and removing connections from the dictionary.

The `received` function, which receives binary messages, is rejecting the message, closing the client connection and removing the connection
from the set of known connections.

Lastly, the `received` function, which receives text messages, simply echoes the message received to all clients except the one who sent the message.

It should be noted that all of these functions can be invoked from many threads simultaneously. In real applications,
one should add locking around the access of non-thread safe artifacts of the application such as the
connections Dictionary in this very simplistic example.

Create a `main.swift` file which contains:
```swift
// ChatServer is a very simple chat server

import Foundation

import KituraNet
import KituraWebSocket

import HeliumLogger
import LoggerAPI

// Using an implementation for a Logger
HeliumLogger.use(.info)

WebSocket.register(service: ChatService(), onPath: "chat")

class ChatServerDelegate: ServerDelegate {
    public func handle(request: ServerRequest, response: ServerResponse) {}
}

// Add HTTP Server to listen on port 8080
let server = HTTP.createServer()
server.delegate = ChatServerDelegate()

do {
    try server.listen(on: 8080)
    ListenerGroup.waitForListeners()
} catch {
    Log.error("Error listening on port 8080: \(error).")
}
```
In the main.swift file:
- The HeliumLogger is set up to log info, warning, and error type messages.
- The ChatService defined in the ChatService.swift file is registered on the path *chat*.
- An HTTP server is created and setup to listen on port 8080.

With this server set up clients should connect to the chat service as *ws://__host__:8080/chat*, where **host** is the host running the server.

### The client
The client has a simple command line interface. At startup one passes the host and port number. The client simply reads
messages to be sent from the terminal and displays messages received on the terminal as well.

You will need to create the client's directory structure to be something like this:
<pre>
ClientDirectory
├── package.json
└── chat.js
</pre>

Create a `package.json` file which, at a minimum, contains:

```javascript
{
  "name": "chat",
  "description": "Simple chat server client",
  "version": "0.0.1",
  "engines": {
    "node": ">=0.8.0"
  },
  "dependencies": {
    "websocket": "^1.0.23"
  }
}
```

Create a `chat.js` file which contains:

```javascript
/* main file of Simple Chat Server Client */

var readline = require('readline');
var WebSocketClient = require('websocket').client

var host = process.argv[2];

rl = readline.createInterface(process.stdin, process.stdout);

rl.setPrompt('> ');
rl.prompt();
var client = new WebSocketClient();

client.on('connectFailed', function(error) {
    console.log('Connect Error: ' + error.toString());
    process.exit();
});

client.on('connect', function(connection) {
    connection.on('error', function(error) {
        console.log("Connection Error: " + error.toString());
        process.exit();
    });

    connection.on('close', function(reasonCode, description) {
        console.log('chat Connection Closed. Code=' + reasonCode + ' (' + description +')');
    });

    connection.on('message', function(message) {
        if (message.type === 'utf8') {
            console.log('\r=> ' + message.utf8Data);
            rl.prompt();
        }   
    });

    rl.on('line', function(line) {
        connection.sendUTF(line);
        rl.prompt();
    });

    rl.on('close', function() {
        connection.close();
        console.log('Have a great day!');
        process.exit(0);
    });

    rl.prompt();
});

client.connect("ws://" + host +"/chat", "chat");
```

### Building and running the example
To build the server, in the server directory, type:
```
swift build
```
To run the server, in the same directory, type:
```
.build/debug/ChatServer
```
The server will now be up and running. The informational log message below will be displayed:

``
[INFO] [HTTPServer.swift:124 listen(on:)] Listening on port 8080
``

### Setting up and running the client
To setup the client, in the client directory, simply:
```
npm install
```
That will install the websocket package.

To run the client, again in the client directory, run:
```
node chat.js host:8080
```
Where **host** is the hostname of the host on which the server is running, e.g. if your server is running on the localhost run:
```
node chat.js localhost:8080
```

As described above, the server echoes all text messages sent to it to all of the clients that have connected to it, with the exception of the client that sent the message. Therefore, in order to see the example in action you will need to connect more than one client to the server. The client can be run in several terminal windows on the same computer. You can then enter a message on one client and see it appear on another client and vice versa.

## Example - Advanced
For a more complete example please see [Kitura-Sample](https://github.com/KituraKommunity/Kitura-Sample).

## API Documentation
For more information visit our [API reference](https://ibm-swift.github.io/Kitura-WebSocket/index.html).

## Community

We love to talk server-side Swift, and Kitura. Join our [Slack](http://swift-at-ibm-slack.mybluemix.net/) to meet the team!

## License
This library is licensed under Apache 2.0. Full license text is available in [LICENSE](https://github.com/KituraKommunity/Kitura-WebSocket/blob/master/LICENSE.txt).
