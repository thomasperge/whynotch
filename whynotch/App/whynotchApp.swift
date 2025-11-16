//
//  whynotchApp.swift
//  whynotch
//
//

import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let notchController = NotchWindowController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        notchController.show()
    }

    func applicationWillTerminate(_ notification: Notification) {
        notchController.close()
    }
}

@main
struct whynotchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            ContentView()
        }
    }
}

