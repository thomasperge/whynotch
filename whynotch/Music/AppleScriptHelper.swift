//
//  AppleScriptHelper.swift
//  whynotch
//
//  Helper for executing AppleScript commands asynchronously
//

import Foundation
import AppKit

enum AppleScriptHelper {
    static func execute(_ script: String) async throws -> NSAppleEventDescriptor? {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let appleScript = NSAppleScript(source: script)
                var error: NSDictionary?
                
                guard let appleScript = appleScript else {
                    continuation.resume(throwing: NSError(domain: "AppleScriptHelper", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create AppleScript"]))
                    return
                }
                
                let result = appleScript.executeAndReturnError(&error)
                
                if let error = error {
                    let errorCode = error[NSAppleScript.errorNumber] as? Int ?? -1
                    let errorMessage = error[NSAppleScript.errorMessage] as? String ?? "Unknown error"
                    continuation.resume(throwing: NSError(domain: "AppleScriptHelper", code: errorCode, userInfo: [NSLocalizedDescriptionKey: errorMessage]))
                } else {
                    continuation.resume(returning: result)
                }
            }
        }
    }
    
    static func executeVoid(_ script: String) async throws {
        _ = try await execute(script)
    }
}

