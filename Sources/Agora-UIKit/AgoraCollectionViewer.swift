//
//  AgoraCollectionViewer.swift
//  Agora-UIKit
//
//  Created by Max Cobb on 26/11/2020.
//

import UIKit

class AgoraCollectionViewer: UICollectionView {

    static let cellSpacing: CGFloat = 5

    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        self.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.9)
        self.register(AgoraCollectionItem.self, forCellWithReuseIdentifier: "collectionCell")
    }

    convenience init() {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        flowLayout.itemSize = CGSize(width: 100, height: 100)
        flowLayout.minimumInteritemSpacing = AgoraCollectionViewer.cellSpacing
        flowLayout.sectionInset = UIEdgeInsets(
            top: AgoraCollectionViewer.cellSpacing,
            left: AgoraCollectionViewer.cellSpacing,
            bottom: AgoraCollectionViewer.cellSpacing,
            right: AgoraCollectionViewer.cellSpacing
        )
        self.init(frame: .zero, collectionViewLayout: flowLayout)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class AgoraCollectionItem: UICollectionViewCell {
    var agoraVideoView: AgoraSingleVideoView? {
        didSet {
            guard let avv = self.agoraVideoView else {
                return
            }
            avv.frame = self.bounds
            self.addSubview(avv)

        }
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension AgoraVideoViewer: UICollectionViewDelegate, UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let count = self.videosToShow.count
        collectionView.isHidden = count == 0
        return count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "collectionCell", for: indexPath) as! AgoraCollectionItem
        cell.backgroundColor = UIColor.blue.withAlphaComponent(0.4)
        return cell
    }

    var videosToShow: [AgoraSingleVideoView] {
        self.style == .floating ? Array(self.userVideoLookup.values) : []
    }
    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        // ok ending here

        guard let leavingCell = cell as? AgoraCollectionItem else {
            fatalError("cell not valid")
        }
    }

    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let newVid = self.videosToShow[indexPath.row]
        guard let cell = cell as? AgoraCollectionItem else {
            fatalError("cell not valid")
        }
        let myActiveSpeaker = self.overrideActiveSpeaker ?? self.activeSpeaker
        if newVid.uid == myActiveSpeaker {
            newVid.removeFromSuperview()
            self.backgroundVideoHolder.addSubview(newVid)
            newVid.translatesAutoresizingMaskIntoConstraints = false
            [
                // Set the width and height the same as the full area
                // Multiplied by the precalculated multiplier
                newVid.widthAnchor.constraint(
                    equalTo: self.backgroundVideoHolder.widthAnchor
                ), newVid.heightAnchor.constraint(
                    equalTo: self.backgroundVideoHolder.heightAnchor
                ), newVid.centerXAnchor.constraint(
                    equalTo: self.backgroundVideoHolder.centerXAnchor
                ), newVid.centerYAnchor.constraint(
                    equalTo: self.backgroundVideoHolder.centerYAnchor
                )
            ].forEach { $0.isActive = true }
        } else {
            cell.agoraVideoView = newVid
        }
        if self.userID == newVid.uid {
            self.agkit.setupLocalVideo(newVid.canvas)
        } else {
            self.agkit.setupRemoteVideo(newVid.canvas)
        }
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let agoraColItem = collectionView.cellForItem(at: indexPath) as? AgoraCollectionItem else {
            return
        }
        self.overrideActiveSpeaker = agoraColItem.agoraVideoView?.uid
    }
}
