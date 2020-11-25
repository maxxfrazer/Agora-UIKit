//
//  AgoraVideoViewer+Buttons.swift
//  Agora-UIKit
//
//  Created by Max Cobb on 25/11/2020.
//

import UIKit

// This file mostly contains programatically created UIButtons,
// The buttons call the following methods found in AgoraVideoViewer+VideoControl.swift:
// leaveChannel, toggleCam, toggleMic, flipCamera, toggleBroadcast, toggleBeautify

extension AgoraVideoViewer {
    /// Add all the relevant buttons.
    /// The buttons are set to add to their respective parent views
    /// Whenever called, so I'm discarding the result for most of them here.
    func addVideoButtons() {
        let container = self.getControlContainer()
        container.isHidden = true

        let buttons = [
            self.getCameraButton(), self.getMicButton(),
            self.getFlipButton(), self.getBeautifyButton()
        ].compactMap { $0 }
        let buttonSize: CGFloat = 60
        buttons.enumerated().forEach({ (elem) in
            let button = elem.element
            container.addSubview(button)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 60, height: 60))
            [
                button.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -10),
                button.centerXAnchor.constraint(
                    equalTo: container.centerXAnchor,
                    constant: (CGFloat(elem.offset) + 0.5 - CGFloat(buttons.count) / 2) * (buttonSize + 10)
                ),
                button.widthAnchor.constraint(equalToConstant: buttonSize),
                button.heightAnchor.constraint(equalToConstant: buttonSize),
            ].forEach { $0.isActive = true }
            button.layer.cornerRadius = buttonSize / 2
            button.backgroundColor = .systemGray
        })
    }

    func getControlContainer() -> UIView {
        if let controlContainer = self.controlContainer {
            return controlContainer
        }
        let container = UIView()
        self.addSubview(container)

        container.translatesAutoresizingMaskIntoConstraints = false
        [
            container.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            container.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor),
            container.widthAnchor.constraint(equalTo: self.widthAnchor),
            container.heightAnchor.constraint(equalTo: self.heightAnchor)
        ].forEach { $0.isActive = true }

        container.isUserInteractionEnabled = true
        self.controlContainer = container
        return container
    }

    func getCameraButton() -> UIButton? {
        if let camButton = self.camButton { return camButton }

        let button = UIButton.newToggleButton(unselected: "video", selected: "video.slash")
        button.addTarget(self, action: #selector(toggleCam), for: .touchUpInside)

        self.camButton = button
        return button
    }

    func getMicButton() -> UIButton? {
        if let micButton = self.micButton { return micButton }

        let button = UIButton.newToggleButton(
            unselected: "mic", selected: "mic.slash"
        )
        button.addTarget(self, action: #selector(toggleMic), for: .touchUpInside)

        self.micButton = button
        return button
    }

    func getFlipButton() -> UIButton? {
        if let flipButton = self.flipButton { return flipButton }

        let button = UIButton.newToggleButton(unselected: "camera.rotate")
        button.addTarget(self, action: #selector(flipCamera), for: .touchUpInside)

        self.flipButton = button
        return button
    }

    func getBeautifyButton() -> UIButton? {
        if let beautyButton = self.beautyButton { return beautyButton }

        let button = UIButton.newToggleButton(unselected: "wand.and.stars.inverse")
        button.addTarget(self, action: #selector(toggleBeautify), for: .touchUpInside)

        self.beautyButton = button
        return button
    }
}
