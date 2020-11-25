//
//  AgoraVideoViewer+Ordering.swift
//  Agora-UIKit
//
//  Created by Max Cobb on 25/11/2020.
//

import Foundation

extension AgoraVideoViewer {
    /// Shuffle around the videos if multiple people are hosting, grid formation.
    internal func reorganiseVideos() {
        switch self.style {
        case .grid:
            self.organiseGrid()
        case .custom(let orgCustom):
            // no custom setup yet
            orgCustom(self, self.userVideoLookup.enumerated(), self.userVideoLookup.count)
            break
        }
    }
    func organiseGrid() {
        var prevView: UIView?
        if userVideoLookup.isEmpty {
            return
        } else if userVideoLookup.count == 2 {
            // when there are 2 videos we display them ontop of eachother
            for (_, videoSessionView) in userVideoLookup {
                videoSessionView.removeFromSuperview()
                self.userVideoHolder.addSubview(videoSessionView)
                videoSessionView.translatesAutoresizingMaskIntoConstraints = false
                [
                    // Set the width and height the same as the full area
                    // Multiplied by the precalculated multiplier
                    videoSessionView.widthAnchor.constraint(
                        equalTo: self.superview!.safeAreaLayoutGuide.widthAnchor
                    ), videoSessionView.heightAnchor.constraint(
                        equalTo: self.superview!.safeAreaLayoutGuide.heightAnchor,
                        multiplier: 0.5
                    ), videoSessionView.leadingAnchor.constraint(
                        equalTo: self.superview!.safeAreaLayoutGuide.leadingAnchor
                    )
                ].forEach { $0.isActive = true }
                videoSessionView.topAnchor.constraint(
                    equalTo: prevView?.bottomAnchor ?? self.superview!.safeAreaLayoutGuide.topAnchor
                ).isActive = true
                prevView = videoSessionView
            }
            return
        }
        let vidCounts = userVideoLookup.count

        // I'm always applying an NxN grid, so if there are 12
        // We take on a grid of 4x4 (16).
        let maxSqrt = ceil(sqrt(CGFloat(vidCounts)))
        let multDim = 1 / maxSqrt
        for (idx, (_, videoSessionView)) in userVideoLookup.enumerated() {

            // clear the constraints.
            videoSessionView.removeFromSuperview()
            self.userVideoHolder.addSubview(videoSessionView)
            videoSessionView.translatesAutoresizingMaskIntoConstraints = false
            [
                // Set the width and height the same as the full area
                // Multiplied by the precalculated multiplier
                videoSessionView.widthAnchor.constraint(
                    equalTo: self.superview!.safeAreaLayoutGuide.widthAnchor,
                    multiplier: multDim
                ), videoSessionView.heightAnchor.constraint(
                    equalTo: self.superview!.safeAreaLayoutGuide.heightAnchor,
                    multiplier: multDim
                )
            ].forEach { $0.isActive = true }
            if idx == 0 {
                // First video in the list, so just put it at the top left
                [
                    videoSessionView.leftAnchor.constraint(equalTo: self.superview!.safeAreaLayoutGuide.leftAnchor),
                    videoSessionView.topAnchor.constraint(equalTo: self.superview!.safeAreaLayoutGuide.topAnchor)
                ].forEach { $0.isActive = true }
            } else {
                if (idx % Int(maxSqrt)) == 0 {
                    // New row, so go to the far left, and align the top of this
                    // view with the bottom of the previous view.
                    videoSessionView.leftAnchor.constraint(equalTo: self.superview!.safeAreaLayoutGuide.leftAnchor).isActive = true
                    videoSessionView.topAnchor.constraint(equalTo: prevView!.bottomAnchor).isActive = true
                } else {
                    // Go to the end of current row
                    videoSessionView.leftAnchor.constraint(equalTo: prevView!.rightAnchor).isActive = true
                    videoSessionView.topAnchor.constraint(equalTo: prevView!.topAnchor).isActive = true
                }
            }
            prevView = videoSessionView
        }
    }
}
