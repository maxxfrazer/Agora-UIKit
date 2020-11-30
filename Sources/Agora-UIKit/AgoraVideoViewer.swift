//
//  AgoraVideoViewer.swift
//  Agora-UIKit
//
//  Created by Max Cobb on 25/11/2020.
//

import UIKit
import AgoraRtcKit


/// Storing struct for holding data about the connection to Agora service
public struct AgoraConnectionData {
    var appId: String
    var appToken: String?
    var channel: String?
    public init(appId: String, appToken: String? = nil, channel: String? = nil) {
        self.appId = appId
        self.appToken = appToken
        self.channel = channel
    }
}

open class AgoraVideoViewer: UIView {

    public enum Style: Equatable {
        case grid
        case floating
        case custom(customFunction: (AgoraVideoViewer, EnumeratedSequence<[UInt: AgoraSingleVideoView]>, Int) -> Void)

        public static func ==(lhs: AgoraVideoViewer.Style, rhs: AgoraVideoViewer.Style) -> Bool {
            switch (lhs, rhs) {
            case (.grid, .grid), (.floating, .floating):
                return true
            default:
                return false
            }
        }
    }

    internal var parentViewController: UIViewController?
    public internal(set) var activeSpeaker: UInt? {
        didSet {
            self.reorganiseVideos()
        }
    }

    public var overrideActiveSpeaker: UInt? {
        didSet {
            if oldValue != overrideActiveSpeaker {
                self.reorganiseVideos()
            }
        }
    }

    /// Setting to zero will tell Agora to assign one for you
    lazy var userID: UInt = 0
    var connectionData: AgoraConnectionData

    public var userRole: AgoraClientRole = .broadcaster {
        didSet {
            self.agkit.setClientRole(self.userRole)
        }
    }

    internal var currentToken: String?{
        get { self.connectionData.appToken }
        set { self.connectionData.appToken = newValue }
    }

    lazy var floatingVideoHolder: UICollectionView = {

        let collView = AgoraCollectionViewer()
        self.addSubview(collView)
        collView.translatesAutoresizingMaskIntoConstraints = false
        [
            collView.widthAnchor.constraint(equalTo: self.safeAreaLayoutGuide.widthAnchor),
            collView.heightAnchor.constraint(greaterThanOrEqualToConstant: 100 + 2 * AgoraCollectionViewer.cellSpacing),
            collView.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor),
            collView.centerXAnchor.constraint(equalTo: self.safeAreaLayoutGuide.centerXAnchor)
        ].forEach { $0.isActive = true }
        self.bringSubviewToFront(collView)
        collView.delegate = self
        collView.dataSource = self
        return collView
    }()

    lazy var backgroundVideoHolder: UIView = {
        let rtnView = UIView()
        self.addSubview(rtnView)
        rtnView.translatesAutoresizingMaskIntoConstraints = false
        [
            rtnView.widthAnchor.constraint(equalTo: self.widthAnchor),
            rtnView.heightAnchor.constraint(equalTo: self.heightAnchor)
        ].forEach { $0.isActive = true }
        self.sendSubviewToBack(rtnView)
        return rtnView
    }()

    lazy public internal(set) var agkit: AgoraRtcEngineKit = {
        let engine = AgoraRtcEngineKit.sharedEngine(
            withAppId: connectionData.appId,
            delegate: self
        )
        engine.enableAudioVolumeIndication(1000, smooth: 3, report_vad: true)
        engine.setChannelProfile(.liveBroadcasting)
        engine.setClientRole(self.userRole)
        return engine
    }()

    public var style: AgoraVideoViewer.Style {
        didSet {
            if oldValue != self.style {
                AgoraVideoViewer.agoraPrint(.info, message: "changed style")
                self.reorganiseVideos()
            }
        }
    }

    public init(connectionData: AgoraConnectionData, viewController: UIViewController, style: AgoraVideoViewer.Style = .grid) {
        self.connectionData = connectionData
        self.parentViewController = viewController
        self.style = style
        super.init(frame: .zero)
        self.addVideoButtons()
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    lazy var videoView: UIView = {
        let vview = UIView()
        vview.translatesAutoresizingMaskIntoConstraints = false
        return vview
    }()

    internal var userVideoLookup: [UInt: AgoraSingleVideoView] = [:] {
        didSet {
            reorganiseVideos()
        }
    }

    public func fills(view: UIView) {
        view.addSubview(self)
        self.translatesAutoresizingMaskIntoConstraints = false
        self.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor).isActive = true
        self.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor).isActive = true
    }

    var controlContainer: UIView?
    var camButton: UIButton?
    var micButton: UIButton?
    var flipButton: UIButton?
    var beautyButton: UIButton?

    var beautyOptions: AgoraBeautyOptions = {
        let bOpt = AgoraBeautyOptions()
        bOpt.smoothnessLevel = 1
        bOpt.rednessLevel = 0.1
        return bOpt
    }()

    var remoteUserIDs: Set<UInt> = []

    @discardableResult
    internal func addLocalVideo() -> AgoraSingleVideoView? {
        if self.userID == 0 || self.userVideoLookup[self.userID] != nil {
            return self.userVideoLookup[self.userID]
        }
        let vidView = AgoraSingleVideoView(uid: self.userID)
        self.agkit.setupLocalVideo(vidView.canvas)
        self.userVideoLookup[self.userID] = vidView
        return vidView
    }

    /// Shuffle around the videos if multiple people are hosting, grid formation.

    @discardableResult
    func addUserVideo(with userId: UInt, size: CGSize) -> AgoraSingleVideoView {
        if let remoteView = self.userVideoLookup[userId] {
            return remoteView
        }
        let remoteVideoView = AgoraSingleVideoView(uid: userId)
        self.agkit.setupRemoteVideo(remoteVideoView.canvas)
        self.userVideoLookup[userId] = remoteVideoView
        return remoteVideoView
    }

    func removeUserVideo(with userId: UInt) {
        guard let userSingleView = userVideoLookup[userId],
              let canView = userSingleView.canvas.view else {
            return
        }
        self.agkit.muteRemoteVideoStream(userId, mute: true)
        userSingleView.canvas.view = nil
        canView.removeFromSuperview()
        self.userVideoLookup.removeValue(forKey: userId)
        if let activeSpeaker = self.activeSpeaker, activeSpeaker == userId {
            if let randomNotMe = self.userVideoLookup.keys.shuffled().filter({ $0 != self.userID }).randomElement() {
                // active speaker has left, reassign activeSpeaker to a random member
                self.activeSpeaker = randomNotMe
            } else {
                self.activeSpeaker = nil
            }
        }

    }
}
