//
//  ViewController.swift
//  Agora-UIKit-Example
//
//  Created by Max Cobb on 26/11/2020.
//

import UIKit

import Agora_UIKit

class ViewController: UIViewController {

    var agoraView: AgoraVideoViewer?
    override func viewDidLoad() {
        super.viewDidLoad()

        let agoraView = AgoraVideoViewer(
            connectionData: AgoraConnectionData(
                appId: <#Agora App ID#>,
                appToken: <#Agora Token or nil#>
            ),
            viewController: self
        )

        self.view.backgroundColor = .tertiarySystemBackground
        agoraView.fills(view: self.view)

        agoraView.joinChannel(channel: "test")

        self.agoraView = agoraView
    }


}

