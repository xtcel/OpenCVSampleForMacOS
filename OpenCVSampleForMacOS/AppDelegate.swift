//
//  AppDelegate.swift
//  OpenCVSampleForMacOS
//
//  Created by CaiDan on 2020/7/29.
//  Copyright © 2020 mapnext. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var mainWindowController: NSWindowController!
    
    lazy var window: NSWindow = {
        let w = NSWindow(contentRect: NSMakeRect(0, 0, 1007 , 641), styleMask: [.titled, .resizable, .miniaturizable, .closable, .fullSizeContentView], backing: .buffered, defer: false)
        w.center()
        w.backgroundColor = NSColor(calibratedRed: 0, green: 0, blue: 0, alpha: 1)
        w.minSize = NSMakeSize(320, 240)

        return w
    }()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        mainWindowController = NSWindowController(window: window)
        mainWindowController.showWindow(nil)
        mainWindowController.window?.makeKeyAndOrderFront(nil)
        
        NSApplication.shared.mainWindow?.title = "OpenCV Sample"
        let scanViewCtrl = ScanViewController()
        window.contentViewController = scanViewCtrl
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

