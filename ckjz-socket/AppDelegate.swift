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
    
    let client = ActionCableClient(url: URL(string: "ws://localhost:3000/cable")!);
    
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

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        setButton(gender: "male", status: "open")
        setButton(gender: "female", status: "open")
        
        client.connect()
        
        client.onConnected = {
            print("Connected!")
        }
        
        client.onDisconnected = {(error: Error?) in
            print("Disconnected!")
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
            print("Yay!")
        }
        
        // A channel was unsubscribed, either manually or from a client disconnect.
        sensorsChannel.onUnsubscribed = {
            print("Unsubscribed")
        }
        
        // The attempt at subscribing to a channel was rejected by the server.
        sensorsChannel.onRejected = {
            print("Rejected")
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

