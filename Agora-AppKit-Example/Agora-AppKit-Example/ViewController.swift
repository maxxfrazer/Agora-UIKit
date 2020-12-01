//
//  ViewController.swift
//  Agora-AppKit-Example
//
//  Created by Max Cobb on 30/11/2020.
//

import Cocoa
import Agora_AppKit

class ViewController: NSViewController {

    var agoraView: AgoraVideoViewer?
    override func viewDidLoad() {
        super.viewDidLoad()

        let agoraView = AgoraVideoViewer(
            connectionData: AgoraConnectionData(
                appId: <#Agora App ID#>,
                appToken: <#Agora Token or nil#>
            ),
            viewController: self,
            style: .floating
        )
        agoraView.fills(view: self.view)

        agoraView.joinChannel(channel: "test")

        self.agoraView = agoraView
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

