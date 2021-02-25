//
//  Enums.swift
//  Picflix
//
//  Created by Khalid on 25/09/2019.
//  Copyright © 2019 Black Ace Media. All rights reserved.
//

import Foundation

enum BorderStyle {
    case bottom, top, left, right
}


enum TransitionType: String {
    case transition_fade
    case transition_linearblur
    case transition_directional
    case transition_flyeye
    case transition_windowslice
    case transition_bowtievertical
    case transition_simplezoom
    case transition_polkadotscurtain
    case transition_directionalwarp
    case transition_luminance_melt
    case transition_morph
    case transition_crosszoom
    case transition_crosshatch
    case transition_kaleidoscope
    case transition_crosswrap
    case transition_dreamy
    case transition_pixelize
    case transition_hexagonalize
    case transition_glitchmemories
    case transition_wind
    case transition_randomsquares
    case transition_squareswire
    case transition_DoomScreenTransition
    case transition_none
    
    static func getTransition(_ theme: VideoTheme, index: Int) -> TransitionType {
        switch theme {
        case .none:
            return .transition_none
        case .fade:
            return .transition_fade
        case .blur:
            return .transition_linearblur
        case .magical:
            let rem = index % 3
            if rem == 0 {
                return .transition_dreamy
            }
            else if rem == 1 {
                return .transition_crosszoom
            }
            else {
                return .transition_crosswrap
            }
        case .lively:
            let rem = index % 4
            if rem == 0 {
                return .transition_directional
            }
            else if rem == 1 {
                return .transition_flyeye
            }
            else if rem == 2 {
                return .transition_simplezoom
            }
            else {
                return .transition_bowtievertical
            }
        case .robotic:
            let rem = index % 4
            if rem == 0 {
                return .transition_pixelize
            }
            else if rem == 1 {
                return .transition_hexagonalize
            }
            else if rem == 2 {
                return .transition_glitchmemories
            }
            else {
                return .transition_flyeye
            }
        case .rockstar:
            let rem = index % 4
            if rem == 0 {
                return .transition_randomsquares
            }
            else if rem == 1 {
                return .transition_wind
            }
            else if rem == 2 {
                return .transition_squareswire
            }
            else {
                return .transition_DoomScreenTransition
            }
        case .dreamy:
            let rem = index % 5
            if rem == 0 {
                return .transition_crosszoom
            }
            else if rem == 1 {
                return .transition_dreamy
            }
            else if rem == 2 {
                return .transition_crosshatch
            }
            else if rem == 3 {
                return .transition_polkadotscurtain
            }
            else {
                return .transition_morph
            }
        }
    }
    
}

enum VideoTheme: String, CaseIterable {
    case none
    case fade
    case blur
    case magical
    case lively
    case robotic
    case rockstar
    case dreamy
    
    func isPremium() -> Bool {
        if self == .none || self == .fade {
            return false
        }
        else {
            return true
        }
    }
    
}

enum SelectedTimelineType {
    case video
    case asset(item: Int)
}
