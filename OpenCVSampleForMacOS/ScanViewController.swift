//
//  ScanViewController.swift
//  OpenCVSampleForMacOS
//
//  Created by CaiDan on 2020/7/29.
//  Copyright © 2020 mapnext. All rights reserved.
//

import Foundation

class ScanViewController: NSViewController, CVCameraDelegate {
    
    lazy var previewImageView: NSImageView = {
        let imgView = NSImageView(frame: NSRect(x: 10, y: 10, width: 480, height: 320))
        
        return imgView
    }()
    
    lazy var processImageView: NSImageView = {
        let imgView = NSImageView(frame: NSRect(x: 520, y: 10, width: 480, height: 320))
        
        return imgView
    }()
    
    lazy var label: NSTextField = {
        let v = NSTextField(labelWithString: "Press the button")
        v.translatesAutoresizingMaskIntoConstraints = false

        return v
    }()


    lazy var button: NSButton = {
        let v = NSButton(frame: .zero)
        v.translatesAutoresizingMaskIntoConstraints = false

        return v
    }()
    
    var camera: CVCamera!

    override func loadView() {
        // 设置 ViewController 大小同 mainWindow
        guard let windowRect = NSApplication.shared.mainWindow?.frame else { return }
        view = NSView(frame: windowRect)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(label)
        view.addSubview(button)
        view.addSubview(previewImageView)
        view.addSubview(processImageView)
        
        camera = CVCamera(controller: self, andCameraImageView: previewImageView, processImage:processImageView);
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),

            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 20),
            button.heightAnchor.constraint(equalToConstant: 30),
            button.widthAnchor.constraint(equalToConstant: 100)
            ])

        button.title = "开始"
        button.target = self
        button.action = #selector(onClickme)
    }
    
    func matchedItem() {
        
    }
    
    @objc func onClickme(_ sender: NSButton) {
        label.textColor = .red
        label.stringValue = "👌!"
        
        camera.start()
    }
}
