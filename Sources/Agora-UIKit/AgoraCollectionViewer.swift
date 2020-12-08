//
//  AgoraCollectionViewer.swift
//  Agora-UIKit
//
//  Created by Max Cobb on 26/11/2020.
//

#if os(iOS)
import UIKit
public typealias MPEdgeInsets = UIEdgeInsets
public typealias MPCollectionView = UICollectionView
public typealias MPCollectionViewCell = UICollectionViewCell
public typealias MPCollectionViewLayout = UICollectionViewLayout
public typealias MPCollectionViewFlowLayout = UICollectionViewFlowLayout
public typealias MPCollectionViewDelegate = UICollectionViewDelegate
public typealias MPCollectionViewDataSource = UICollectionViewDataSource
#elseif os(macOS)
import AppKit
public typealias MPEdgeInsets = NSEdgeInsets
public typealias MPCollectionView = NSCollectionView
public typealias MPCollectionViewCell = NSCollectionViewItem
public typealias MPCollectionViewLayout = NSCollectionViewLayout
public typealias MPCollectionViewFlowLayout = NSCollectionViewFlowLayout
public typealias MPCollectionViewDelegate = NSCollectionViewDelegate
public typealias MPCollectionViewDataSource = NSCollectionViewDataSource
#endif

class AgoraCollectionViewer: MPCollectionView {

    static let cellSpacing: CGFloat = 5


    #if os(iOS)
    override init(frame: CGRect, collectionViewLayout layout: MPCollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        self.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.9)
        self.register(AgoraCollectionItem.self, forCellWithReuseIdentifier: "collectionCell")
    }
    #else
    init(frame: CGRect, collectionViewLayout layout: MPCollectionViewLayout) {
        super.init(frame: frame)
        self.collectionViewLayout = collectionViewLayout

        self.register(
            AgoraCollectionItem.self,
            forItemWithIdentifier: NSUserInterfaceItemIdentifier("collectionCell")
        )
    }
    #endif

    convenience init() {
        let flowLayout = MPCollectionViewFlowLayout()
        flowLayout.itemSize = CGSize(width: 100, height: 100)
        flowLayout.scrollDirection = .horizontal
        flowLayout.sectionInset = MPEdgeInsets(
            top: AgoraCollectionViewer.cellSpacing,
            left: AgoraCollectionViewer.cellSpacing,
            bottom: AgoraCollectionViewer.cellSpacing,
            right: AgoraCollectionViewer.cellSpacing
        )
        flowLayout.minimumInteritemSpacing = AgoraCollectionViewer.cellSpacing
        self.init(frame: .zero, collectionViewLayout: flowLayout)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class AgoraCollectionItem: MPCollectionViewCell {
    var agoraVideoView: AgoraSingleVideoView? {
        didSet {
            guard let avv = self.agoraVideoView else {
                return
            }
            #if os(macOS)
            avv.frame = self.view.bounds
            self.view.addSubview(avv)
            #else
            avv.frame = self.bounds
            self.addSubview(avv)
            #endif
        }
    }
    #if os(macOS)
    override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nil, bundle: nil)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.lightGray.cgColor
    }
    #else
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    #endif

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension AgoraVideoViewer: MPCollectionViewDelegate, MPCollectionViewDataSource {

    #if os(macOS)
    public func collectionView(_ itemForRepresentedObjectAtcollectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        guard let cell = itemForRepresentedObjectAtcollectionView.item(at: indexPath) else {
            fatalError("no item at index")
        }
        cell.view.wantsLayer = true
        cell.view.layer?.backgroundColor = NSColor.blue.withAlphaComponent(0.4).cgColor
        return cell
    }

    public func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return 1
    }
    public func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        let count = self.videosToShow.count
        collectionView.isHidden = count == 0
        return count
    }

    #else
    public func collectionView(_ collectionView: MPCollectionView, cellForItemAt indexPath: IndexPath) -> MPCollectionViewCell {

            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "collectionCell", for: indexPath) as! AgoraCollectionItem
        cell.backgroundColor = UIColor.blue.withAlphaComponent(0.4)
        return cell
    }

    public func collectionView(_ collectionView: MPCollectionView, numberOfItemsInSection section: Int) -> Int {
        let count = self.videosToShow.count
        collectionView.isHidden = count == 0
        return count
    }
    #endif

    var videosToShow: [AgoraSingleVideoView] {
        self.style == .floating ? Array(self.userVideoLookup.values) : []
    }
    public func collectionView(_ collectionView: MPCollectionView, didEndDisplaying cell: MPCollectionViewCell, forItemAt indexPath: IndexPath) {
        // ok ending here

        guard let _ = cell as? AgoraCollectionItem else {
            fatalError("cell not valid")
        }
    }

    public func collectionView(_ collectionView: MPCollectionView, willDisplay cell: MPCollectionViewCell, forItemAt indexPath: IndexPath) {
        #if os(macOS)
        let newVid = self.videosToShow[indexPath.item]
        #else
        let newVid = self.videosToShow[indexPath.row]
        #endif
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

    public func collectionView(_ collectionView: MPCollectionView, didSelectItemAt indexPath: IndexPath) {
        #if os(macOS)
        guard let agoraColItem = collectionView.item(at: indexPath) as? AgoraCollectionItem else {
            return
        }
        #else
        guard let agoraColItem = collectionView.cellForItem(at: indexPath) as? AgoraCollectionItem else {
            return
        }
        #endif
        if self.overrideActiveSpeaker == agoraColItem.agoraVideoView?.uid {
            self.overrideActiveSpeaker = nil
            return
        }
        self.overrideActiveSpeaker = agoraColItem.agoraVideoView?.uid
    }
}
