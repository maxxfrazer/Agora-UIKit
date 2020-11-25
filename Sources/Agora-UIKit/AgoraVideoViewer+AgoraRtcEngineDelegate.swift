//
//  AgoraVideoViewer+AgoraRtcEngineDelegate.swift
//  Agora-UIKit
//
//  Created by Max Cobb on 25/11/2020.
//

import AgoraRtcKit

extension AgoraVideoViewer: AgoraRtcEngineDelegate {

    open func rtcEngine(_ engine: AgoraRtcEngineKit, firstRemoteVideoDecodedOfUid uid: UInt, size: CGSize, elapsed: Int) {
        self.addUserVideo(with: uid, size: size).videoMuted = false
    }

    /// Called when the user role successfully changes
    /// - Parameters:
    ///   - engine: AgoraRtcEngine of this session.
    ///   - oldRole: Previous role of the user.
    ///   - newRole: New role of the user.
    open func rtcEngine(
        _ engine: AgoraRtcEngineKit,
        didClientRoleChanged oldRole: AgoraClientRole,
        newRole: AgoraClientRole
    ) {
        let isHost = newRole == .broadcaster
        if !isHost {
            self.userVideoLookup.removeValue(forKey: self.userID)
        } else {
            if self.userVideoLookup[self.userID] == nil {
                self.addLocalVideo()
            }
        }

        // Only show the camera options when we are a broadcaster
        self.getControlContainer().isHidden = !isHost
    }

    open func rtcEngine(
        _ engine: AgoraRtcEngineKit,
        didJoinedOfUid uid: UInt,
        elapsed: Int
    ) {
        // Keeping track of all people in the session
        self.remoteUserIDs.insert(uid)
    }

    open func rtcEngine(_ engine: AgoraRtcEngineKit, remoteAudioStateChangedOfUid uid: UInt, state: AgoraAudioRemoteState, reason: AgoraAudioRemoteStateReason, elapsed: Int) {
        if state == .stopped || state == .starting {
            if let videoView = self.userVideoLookup[uid] {
                videoView.audioMuted = state == .stopped
            } else if state != .stopped {
                self.addUserVideo(with: uid, size: .zero).audioMuted = false
            }
        }
    }

    open func rtcEngine(
        _ engine: AgoraRtcEngineKit,
        didOfflineOfUid uid: UInt,
        reason: AgoraUserOfflineReason
    ) {
        // Removing on quit and dropped only
        // the other option is `.becomeAudience`,
        // which means it's still relevant.
        if reason == .quit || reason == .dropped {
            self.remoteUserIDs.remove(uid)
        }
        if self.userVideoLookup[uid] != nil {
            // User is no longer hosting, need to change the lookups
            // and remove this view from the list
            self.removeUserVideo(with: uid)
        }
    }

    open func rtcEngine(_ engine: AgoraRtcEngineKit, remoteVideoStateChangedOfUid uid: UInt, state: AgoraVideoRemoteState, reason: AgoraVideoRemoteStateReason, elapsed: Int) {
//        if state == .stopped {
//            self.removeUserVideo(with: uid)
//        }
        if state == .starting {
            print("starting \(uid)")
        }
        switch state {
        case .decoding:
            self.userVideoLookup[uid]?.videoMuted = false
        case .stopped:
            self.userVideoLookup[uid]?.videoMuted = true
        default:
            break
        }
    }

    open func rtcEngine(_ engine: AgoraRtcEngineKit, localVideoStateChange state: AgoraLocalVideoStreamState, error: AgoraLocalVideoStreamError) {
        switch state {
        case .capturing, .stopped:
            self.userVideoLookup[self.userID]?.videoMuted = state == .stopped
        default:
            print(state)
        }
    }

    /// - TODO: See why this isn't called.
    open func rtcEngine(_ engine: AgoraRtcEngineKit, localAudioStateChange state: AgoraAudioLocalState, error: AgoraAudioLocalError) {
        print("local user set Audio: \(state)")
        switch state {
        case .recording, .stopped:
            self.userVideoLookup[self.userID]?.audioMuted = state == .stopped
        default:
            break
        }
    }

    open func rtcEngine(_ engine: AgoraRtcEngineKit, firstLocalAudioFrame elapsed: Int) {
        self.addLocalVideo()?.audioMuted = false
    }

    open func rtcEngine(_ engine: AgoraRtcEngineKit, didVideoMuted muted: Bool, byUid uid: UInt) {
        print("remote user with uid: \(uid), set Video Muted: \(muted)")
        self.userVideoLookup[self.userID]?.audioMuted = muted
    }

}
