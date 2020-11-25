//
//  AgoraSingleVideoView.swift
//  Agora-UIKit
//
//  Created by Max Cobb on 25/11/2020.
//

import UIKit
import AgoraRtcKit

public class AgoraSingleVideoView: UIView {
    var videoMuted: Bool = true {
        didSet {
            if oldValue != videoMuted {
                self.canvas.view?.isHidden = videoMuted
            }
        }
    }
    var audioMuted: Bool = true {
        didSet {
            self.mutedFlag.isHidden = !audioMuted
        }
    }

    var canvas: AgoraRtcVideoCanvas
    var hostingView: UIView? {
        self.canvas.view
    }
    lazy var mutedFlag: UIView = {
        let muteFlag = UIButton(type: .custom)
        muteFlag.setImage(UIImage(systemName: "mic.slash.fill", withConfiguration: UIImage.SymbolConfiguration(scale: .large)), for: .normal)
        self.addSubview(muteFlag)
        muteFlag.frame = CGRect(origin: CGPoint(x: self.frame.width - 50, y: self.frame.height - 50), size: CGSize(width: 50, height: 50))
        muteFlag.autoresizingMask = [.flexibleTopMargin, .flexibleLeftMargin]
        return muteFlag
    }()

    init(uid: UInt) {
        self.canvas = AgoraRtcVideoCanvas()
        super.init(frame: .zero)
        self.setBackground()
        self.canvas.uid = uid
        let hostingView = UIView()
        hostingView.frame = self.bounds
        hostingView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.canvas.view = hostingView
        self.addSubview(hostingView)
        self.canvas.renderMode = .hidden
        self.setupMutedFlag()
    }

    private func setupMutedFlag() {
        self.audioMuted = true
    }

    func setBackground() {
        let backgroundView = UIView()
        backgroundView.backgroundColor = .secondarySystemBackground
        let bgButton = UIButton(type: .custom)
        bgButton.setImage(UIImage(systemName: "person.circle", withConfiguration: UIImage.SymbolConfiguration(scale: .large)), for: .normal)
        backgroundView.addSubview(bgButton)
        bgButton.frame = backgroundView.bounds
        bgButton.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.addSubview(backgroundView)
        backgroundView.frame = self.bounds
        backgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
