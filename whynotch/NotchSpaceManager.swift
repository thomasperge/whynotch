//
//  NotchSpaceManager.swift
//  whynotch
//
//  Keeps a dedicated CGSSpace so the notch window survives Space switches.
//

import Foundation

final class NotchSpaceManager {
    static let shared = NotchSpaceManager()

    let notchSpace: CGSSpace

    private init() {
        notchSpace = CGSSpace(level: Int(Int32.max))
    }
}

