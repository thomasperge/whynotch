//
//  PlayerView.swift
//  whynotch
//
//  Full player view with controls, shown on hover
//

import SwiftUI
import AppKit

struct PlayerView: View {
    let artwork: NSImage?
    let title: String?
    let artist: String?
    let textColor: NSColor?
    let isPlaying: Bool
    let currentTime: TimeInterval
    let duration: TimeInterval
    let onPlayPause: () -> Void
    let onNext: () -> Void
    let onPrevious: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top section - Artwork and animation (same position as Compact/Info)
            HStack {
                ArtworkView(image: artwork)
                
                Spacer()
                
                PlayerIndicator(color: textColor)
            }
            .padding(.horizontal, 24.5)
            .frame(height: 33)
            
            // Title/artist below artwork
            if let artist = artist, let title = title {
                Text("\(artist) - \(title)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(textColor != nil ? Color(nsColor: textColor!).opacity(0.7) : .white.opacity(0.4))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .padding(.horizontal, 24.5)
                    .padding(.top, 6)
            } else if let title = title {
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(textColor != nil ? Color(nsColor: textColor!).opacity(0.7) : .white.opacity(0.4))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .padding(.horizontal, 24.5)
                    .padding(.top, 6)
            }
            
            // Progress bar with timer
            VStack(spacing: 4) {
                ProgressBarView(
                    progress: duration > 0 ? currentTime / duration : 0,
                    currentTime: currentTime,
                    duration: duration,
                    color: textColor
                )
            }
            .padding(.horizontal, 24.5)
            .padding(.top, 10)
            
            // Control buttons
            HStack(spacing: 12) {
                Spacer()
                
                Button(action: onPrevious) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: onPlayPause) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(.white.opacity(0.15)))
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: onNext) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
            }
            .padding(.horizontal, 25)
            .padding(.top, 10)
            .padding(.bottom, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

