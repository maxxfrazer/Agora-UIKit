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

    public enum Style {
        case grid
        case custom(customFunction: (AgoraVideoViewer, EnumeratedSequence<[UInt: AgoraSingleVideoView]>, Int) -> Void)
    }

    internal var parentViewController: UIViewController?

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

    lazy var userVideoHolder: UIView = {
        let rtnView = UIView()
        self.addSubview(rtnView)
        rtnView.translatesAutoresizingMaskIntoConstraints = false
        rtnView.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
        rtnView.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
        self.sendSubviewToBack(rtnView)
        return rtnView
    }()

    lazy public internal(set) var agkit: AgoraRtcEngineKit = {
        let engine = AgoraRtcEngineKit.sharedEngine(
            withAppId: connectionData.appId,
            delegate: self
        )
        engine.setChannelProfile(.liveBroadcasting)
        engine.setClientRole(self.userRole)
        return engine
    }()

    var style: AgoraVideoViewer.Style

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
        self.safeAreaLayoutGuide.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor).isActive = true
        self.safeAreaLayoutGuide.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor).isActive = true
        self.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        self.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
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
    }

}
