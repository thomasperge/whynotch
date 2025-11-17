//
//  NotchWindowController.swift
//  whynotch
//
//

import AppKit
import SwiftUI

final class NotchWindowController: NSObject {
    private enum Constants {
        static let notchWidth: CGFloat = 255
        static let playerWidth: CGFloat = 345
        static let notchMaxHeight: CGFloat = 130 // Player height (max)
        static let topInset: CGFloat = 0
    }

    private var window: NSWindow?
    private var screenObserver: Any?
    private var spaceObserver: Any?

    func show() {
        guard window == nil else {
            window?.orderFrontRegardless()
            return
        }

        let hostingController = NSHostingController(rootView: NotchView())
        let notchRect = computeNotchFrame(for: NSScreen.main)

        let window = NotchPanel(
            contentRect: notchRect,
            styleMask: [.borderless, .nonactivatingPanel, .utilityWindow, .hudWindow],
            backing: .buffered,
            defer: false
        )

        window.contentViewController = hostingController
        window.isOpaque = false
        window.backgroundColor = .clear
        window.ignoresMouseEvents = false
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovable = false

        NotchSpaceManager.shared.notchSpace.windows.insert(window)
        self.window = window

        positionWindow()
        window.orderFrontRegardless()

        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.positionWindow()
        }

        spaceObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.positionWindow()
        }
    }

    func close() {
        if let observer = screenObserver {
            NotificationCenter.default.removeObserver(observer)
            screenObserver = nil
        }

        if let observer = spaceObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            spaceObserver = nil
        }

        window?.close()
        window = nil
    }

    private func positionWindow() {
        guard let window,
              let targetScreen = NSScreen.main else { return }

        let frame = computeNotchFrame(for: targetScreen)
        window.setFrame(frame, display: true, animate: false)
    }

    private func computeNotchFrame(for screen: NSScreen?) -> NSRect {
        guard let screen else {
            return NSRect(origin: .zero, size: CGSize(width: Constants.playerWidth, height: Constants.notchMaxHeight))
        }

        // Always position from the top of the screen
        // originY is the bottom-left corner in Cocoa coordinates
        // So we need: screen.maxY - windowHeight to get the top aligned
        // Use playerWidth as max width to accommodate all states
        let originX = screen.frame.midX - (Constants.playerWidth / 2)
        let originY = screen.frame.maxY - Constants.notchMaxHeight - Constants.topInset

        return NSRect(x: originX, y: originY, width: Constants.playerWidth, height: Constants.notchMaxHeight)
    }
}

