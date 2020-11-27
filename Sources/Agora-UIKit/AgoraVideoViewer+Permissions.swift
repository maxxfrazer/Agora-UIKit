//
//  AgoraVideoViewer+Permissions.swift
//  Agora-UIKit
//
//  Created by Max Cobb on 25/11/2020.
//

// This file just contains some helper functions for requesting
// Camera + Microphone permissions.

import AVFoundation
import UIKit

extension AgoraVideoViewer {
    public func checkForPermissions(callback: @escaping (() -> Void)) -> Bool {
        if self.userRole == .audience {
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized: break
            case .notDetermined:
                AgoraVideoViewer.requestCameraAccess { success in
                    if success {
                        callback()
                    } else {
                        AgoraVideoViewer.errorVibe()
                    }
                }
                return false
            default:
                cameraMicSessingsPopup {
                    AgoraVideoViewer.goToSettingsPage()
                }
                return false
            }
            switch AVCaptureDevice.authorizationStatus(for: .audio) {
            case .authorized: break
            case .notDetermined:
                AgoraVideoViewer.requestMicrophoneAccess { success in
                    if success {
                        callback()
                    } else {
                        AgoraVideoViewer.errorVibe()
                    }
                }
                return false
            default:
                cameraMicSessingsPopup { AgoraVideoViewer.goToSettingsPage() }
                return false
            }
        }
        return true
    }

    public static func requestCameraAccess(handler: ((Bool) -> Void)? = nil) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            handler?(granted)
        }
    }

    public static func requestMicrophoneAccess(handler: ((Bool) -> Void)? = nil) {
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            handler?(granted)
        }
    }

    static func goToSettingsPage() {
        UIApplication.shared.open(
            URL(string: UIApplication.openSettingsURLString)!,
            options: [:]
        )
    }

    static func errorVibe() {
        let notificationFeedbackGenerator = UINotificationFeedbackGenerator()
        notificationFeedbackGenerator.prepare()
        notificationFeedbackGenerator.notificationOccurred(.error)
    }

    func cameraMicSessingsPopup(successHandler: @escaping () -> Void) {
        let alertView = UIAlertController(
            title: "Camera and Microphone",
            message: "To become a host, you must enable the microphone and camera",
            preferredStyle: .alert
        )
        alertView.addAction(UIAlertAction(title: "Not Now", style: .cancel, handler: { _ in
            AgoraVideoViewer.errorVibe()
        }))
        alertView.addAction(UIAlertAction(title: "Give Access", style: .default, handler: { _ in
            successHandler()
        }))
        DispatchQueue.main.async {
            self.parentViewController?.present(alertView, animated: true)
        }
    }
}
