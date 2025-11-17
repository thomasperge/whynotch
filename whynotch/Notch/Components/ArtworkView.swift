//
//  ArtworkView.swift
//  whynotch
//
//  Displays album artwork with fade animation
//

import SwiftUI
import AppKit

struct ArtworkView: View {
    let image: NSImage?
    
    var body: some View {
        Group {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .id(image.tiffRepresentation?.hashValue ?? 0)
                    .transition(.opacity.animation(.easeInOut(duration: 0.3)))
            } else {
                LinearGradient(colors: [.white.opacity(0.2), .white.opacity(0.05)],
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
            }
        }
        .frame(width: 20, height: 20)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .stroke(Color.white.opacity(0.55), lineWidth: 0.3)
        )
        .clipped()
        .animation(.easeInOut(duration: 0.3), value: image?.tiffRepresentation?.hashValue)
    }
}

