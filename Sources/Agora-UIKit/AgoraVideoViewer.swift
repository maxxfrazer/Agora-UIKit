//
//  AgoraVideoViewer.swift
//  Agora-UIKit
//
//  Created by Max Cobb on 25/11/2020.
//

#if os(iOS)
import UIKit
public typealias MPButton=UIButton
public typealias MPImage=UIImage
public typealias MPView = UIView
public typealias MPViewController = UIViewController
#elseif os(macOS)
import AppKit
public typealias MPButton=NSButton
public typealias MPImage=NSImage
public typealias MPView = NSView
public typealias MPViewController = NSViewController
#endif
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

@objc public protocol AgoraVideoViewerDelegate: AnyObject {
    @objc optional func joinedChannel(channel: String)
    @objc optional func tokenWillExpire(_ engine: AgoraRtcEngineKit, tokenPrivilegeWillExpire token: String)
    @objc optional func tokenDidExpire(_ engine: AgoraRtcEngineKit)
}

open class AgoraVideoViewer: MPView {

    var delegate: AgoraVideoViewerDelegate?

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

    internal var parentViewController: MPViewController?
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

    internal var currentToken: String? {
        get { self.connectionData.appToken }
        set { self.connectionData.appToken = newValue }
    }

    lazy var floatingVideoHolder: MPCollectionView = {

        let collView = AgoraCollectionViewer()
        self.addSubview(collView)
        collView.translatesAutoresizingMaskIntoConstraints = false
        #if os(macOS)
        [
            collView.widthAnchor.constraint(equalTo: self.widthAnchor),
            collView.heightAnchor.constraint(greaterThanOrEqualToConstant: 100 + 2 * AgoraCollectionViewer.cellSpacing),
            collView.topAnchor.constraint(equalTo: self.topAnchor),
            collView.centerXAnchor.constraint(equalTo: self.centerXAnchor)
        ].forEach { $0.isActive = true }
        self.addSubview(collView, positioned: .above, relativeTo: nil)
        #else
        [
            collView.widthAnchor.constraint(equalTo: self.safeAreaLayoutGuide.widthAnchor),
            collView.heightAnchor.constraint(greaterThanOrEqualToConstant: 100 + 2 * AgoraCollectionViewer.cellSpacing),
            collView.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor),
            collView.centerXAnchor.constraint(equalTo: self.safeAreaLayoutGuide.centerXAnchor)
        ].forEach { $0.isActive = true }
        self.bringSubviewToFront(collView)
        #endif
        collView.delegate = self
        collView.dataSource = self
        return collView
    }()

    lazy var backgroundVideoHolder: MPView = {
        let rtnView = MPView()
        #if os(macOS)
        self.addSubview(rtnView, positioned: .below, relativeTo: nil)
        #else
        self.addSubview(rtnView)
        self.sendSubviewToBack(rtnView)
        #endif
        rtnView.translatesAutoresizingMaskIntoConstraints = false
        [
            rtnView.widthAnchor.constraint(equalTo: self.widthAnchor),
            rtnView.heightAnchor.constraint(equalTo: self.heightAnchor)
        ].forEach { $0.isActive = true }
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

    public init(connectionData: AgoraConnectionData, viewController: MPViewController, style: AgoraVideoViewer.Style = .grid) {
        self.connectionData = connectionData
        self.parentViewController = viewController
        self.style = style
        super.init(frame: .zero)
        self.addVideoButtons()
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    lazy var videoView: MPView = {
        let vview = MPView()
        vview.translatesAutoresizingMaskIntoConstraints = false
        return vview
    }()

    internal var userVideoLookup: [UInt: AgoraSingleVideoView] = [:] {
        didSet {
            reorganiseVideos()
        }
    }

    public func fills(view: MPView) {
        view.addSubview(self)
        self.translatesAutoresizingMaskIntoConstraints = false
        #if os(macOS)
        self.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        self.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
        #else
        self.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor).isActive = true
        self.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor).isActive = true
        #endif
    }

    var controlContainer: MPView?
    var camButton: MPButton?
    var micButton: MPButton?
    var flipButton: MPButton?
    var beautyButton: MPButton?

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
