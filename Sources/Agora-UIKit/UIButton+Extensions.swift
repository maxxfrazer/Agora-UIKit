//
//  MPButton+Extensions.swift
//  Agora-UIKit
//
//  Created by Max Cobb on 25/11/2020.
//

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

internal extension MPButton {
    /// Create a custom UI/NSButton made up of one or two SF Symbol images to alternate between
    /// - Parameters:
    ///   - unselected: SF Symbol present by default, when button has not yet been selected
    ///   - selected: SF Symbol to be displayed after the button is selected
    /// - Returns: A new MPButton of type `.custom` which will alternate between the given SF Symbols on selecting
    static func newToggleButton(unselected: String, selected: String? = nil) -> MPButton {
        #if os(iOS)
        let button = MPButton(type: .custom)
        #else
        let button = MPButton()
        button.wantsLayer = true
        #endif
        if let selected = selected {
            #if os(iOS)
            button.setImage(MPImage(
                systemName: selected,
                withConfiguration: MPImage.SymbolConfiguration(scale: .large)
            ), for: .selected)
            #else
            button.title = selected
            #endif
        }
        #if os(iOS)
        button.setImage(MPImage(
            systemName: unselected,
            withConfiguration: MPImage.SymbolConfiguration(scale: .large)
        ), for: .normal)
        #else
        button.title = unselected
        #endif
        return button
    }
}
