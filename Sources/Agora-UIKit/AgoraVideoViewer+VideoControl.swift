//
//  AgoraVideoViewer+VideoControl.swift
//  Agora-UIKit
//
//  Created by Max Cobb on 25/11/2020.
//

import AgoraRtcKit

extension AgoraVideoViewer {

    /// Setup the canvas and rendering for the device's local video
    func setupAgoraVideo() {
        if self.agkit.enableVideo() < 0 {
            AgoraVideoViewer.agoraPrint(.error, message: "Could not enable video")
            return
        }
    }

    /// Toggle the camera between on and off
    @objc func toggleCam() {
        guard let camButton = self.getCameraButton() else {
            return
        }
        #if os(iOS)
        camButton.isSelected.toggle()
        camButton.backgroundColor = camButton.isSelected ? .systemRed : .systemGray
        self.agkit.enableLocalVideo(!camButton.isSelected)
        #else
        camButton.isHighlighted.toggle()
        camButton.layer?.backgroundColor = camButton.isHighlighted ?
            NSColor.systemRed.cgColor : NSColor.systemGray.cgColor
        self.agkit.enableLocalVideo(!camButton.isHighlighted)
        #endif
    }

    /// Toggle the microphone between on and off
    @objc func toggleMic() {
        guard let micButton = self.getMicButton() else {
            return
        }
        #if os(iOS)
        micButton.isSelected.toggle()
        micButton.backgroundColor = micButton.isSelected ? .systemRed : .systemGray
        self.agkit.muteLocalAudioStream(micButton.isSelected)
        self.userVideoLookup[self.userID]?.audioMuted = micButton.isSelected
        #else
        micButton.isHighlighted.toggle()
        micButton.layer?.backgroundColor = (micButton.isHighlighted ?
                                              NSColor.systemRed : NSColor.systemGray).cgColor
        self.agkit.muteLocalAudioStream(micButton.isHighlighted)
        self.userVideoLookup[self.userID]?.audioMuted = micButton.isHighlighted
        #endif
    }

    /// Turn on/off the 'beautify' effect. Visual and voice change.
    @objc internal func toggleBeautify() {
        guard let beautifyButton = self.getBeautifyButton() else {
            return
        }
        #if os(iOS)
        beautifyButton.isSelected.toggle()
        beautifyButton.backgroundColor = beautifyButton.isSelected ? .systemGreen : .systemGray
        self.agkit.setLocalVoiceChanger(beautifyButton.isSelected ? .voiceBeautyClear : .voiceChangerOff)
        self.agkit.setBeautyEffectOptions(beautifyButton.isSelected, options: self.beautyOptions)
        #else
        beautifyButton.isHighlighted.toggle()
        beautifyButton.layer?.backgroundColor = (beautifyButton.isHighlighted ?
                                                  NSColor.systemGreen : NSColor.systemGray).cgColor
        self.agkit.setLocalVoiceChanger(beautifyButton.isHighlighted ?
                                          .voiceBeautyClear : .voiceChangerOff)
        self.agkit.setBeautyEffectOptions(beautifyButton.isHighlighted, options: self.beautyOptions)
        #endif
    }

    #if os(iOS)
    @objc internal func flipCamera() {
        self.agkit.switchCamera()
    }
    #endif

    /// Toggle between being a host or a member of the audience.
    /// On changing to being a broadcaster, the app first checks
    /// that it has access to both the microphone and camera on the device.
    @objc public func toggleBroadcast() {
        // Check if we have access to mic + camera
        // before changing the user role.
        if !self.checkForPermissions(callback: self.toggleBroadcast) {
            return
        }
        // Swap the userRole
        self.userRole = self.userRole == .audience ? .broadcaster : .audience

        // Disable the button, it is re-enabled once the change of role is successful
        // as dictated by the delegate method
        DispatchQueue.main.async {
            // Need to point to the main thread due to the permission popups
            self.agkit.setClientRole(self.userRole)
        }
    }

    /// Join the Agora channel
    public func joinChannel(channel: String) {
        self.setupAgoraVideo()
        self.connectionData.channel = channel
        self.agkit.joinChannel(
            byToken: self.currentToken,
            channelId: channel,
            info: nil, uid: self.userID
        ) { [weak self] _, uid, _ in
            self?.userID = uid
            if self?.userRole == .broadcaster {
                self?.addLocalVideo()
            }
        }
    }

    public func updateToken(_ newToken: String) {
        self.currentToken = newToken
        self.agkit.renewToken(newToken)
    }

    public func exit() {
        self.agkit.setupLocalVideo(nil)
        self.agkit.leaveChannel(nil)
        if self.userRole == .broadcaster {
            agkit.stopPreview()
        }
        AgoraRtcEngineKit.destroy()
    }
}
