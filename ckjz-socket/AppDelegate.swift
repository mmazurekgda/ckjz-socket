//
//  AppDelegate.swift
//  CKJZ
//
//  Created by johnny on 08/06/2019.
//  Copyright © 2019 JohnnyBros. All rights reserved.
//

import Cocoa


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    let topBarStatusUrl = "http://192.168.3.114:3000/t/sensors/top_bar_status"
    let client = ActionCableClient(url: URL(string: "ws://192.168.3.114:3000/cable")!);
    
    let statusItems: [String: NSStatusItem] = [
        "male": NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength),
        "female": NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength)
    ]
    
    func setButton(gender: String, status: String) {
        if let button = self.statusItems[gender]!.button {
            print("Received", gender + status)
            button.image = NSImage(named:NSImage.Name(gender + status))
        }
    }
    
    
    func connect() {
    
        client.connect()
        
        client.onConnected = {
            print("Connected!")
        }
        
        client.onDisconnected = {(error: Error?) in
            print("Disconnected!")
            self.setButton(gender: "male", status: "unknown")
            self.setButton(gender: "female", status: "unknown")
            self.setMenu(reconnectButton: true)
        }
        
        self.client.willReconnect = {
            print("Reconnecting to \(self.client.url)")
            self.setButton(gender: "male", status: "unknown")
            self.setButton(gender: "female", status: "unknown")
            self.setMenu(reconnectButton: true)
            return true
        }
        
        if(client.socket.isConnected) {
            print("connected")
            
        }else {
            print("not connected")
        }
        
        let sensorsChannel = client.create("SensorsChannel")
        
        // Receive a message from the server. Typically a Dictionary.
        sensorsChannel.onReceive = { (data, error) in
            let JSONObject = JSON(data!)
            if let status = JSONObject["mode"] == true ? "closed" : "open" {
                let gender = JSONObject["name"]
                self.setButton(gender: gender.string!, status: status)
            }
        }
        
        // A channel has successfully been subscribed to.
        sensorsChannel.onSubscribed = {
            print("Subscribed to a SensorsChannel!")
            self.setMenu(reconnectButton: false)
            let url = NSURL(string: self.topBarStatusUrl)
            let request = NSURLRequest(url: url! as URL)
            
            NSURLConnection.sendAsynchronousRequest(request as URLRequest, queue: OperationQueue.main) {(response, data, error) in
                let JSONObject = JSON(data!)
                if let status = JSONObject["male"] == true ? "closed" : "open" {
                    self.setButton(gender: "male", status: status)
                }
                if let status = JSONObject["female"] == true ? "closed" : "open" {
                    self.setButton(gender: "female", status: status)
                }
            }
            
        }
        
        // A channel was unsubscribed, either manually or from a client disconnect.
        sensorsChannel.onUnsubscribed = {
            print("Unsubscribed")
            self.setButton(gender: "male", status: "unknown")
            self.setButton(gender: "female", status: "unknown")
            self.setMenu(reconnectButton: true)
        }
        
        // The attempt at subscribing to a channel was rejected by the server.
        sensorsChannel.onRejected = {
            print("Rejected")
            self.setButton(gender: "male", status: "unknown")
            self.setButton(gender: "female", status: "unknown")
            self.setMenu(reconnectButton: true)
        }
    
    
    }
    
    @objc func reconnect(_ sender: Any?) {
        client.reconnect()
    }
    
    func setMenu(reconnectButton: Bool) {
        let menu = NSMenu()
    
        if (reconnectButton) {
            menu.addItem(NSMenuItem(title: "Reconnect to CKJZ", action: #selector(AppDelegate.reconnect(_:)),  keyEquivalent: "a"))
        }
        menu.addItem(NSMenuItem(title: "Quit CKJZ", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItems["male"]?.menu = menu
        statusItems["female"]?.menu = menu
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        self.setButton(gender: "male", status: "unknown")
        self.setButton(gender: "female", status: "unknown")
        setMenu(reconnectButton: true)
        
        connect()
        
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

