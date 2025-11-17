//
//  NotchView.swift
//  whynotch
//
//  Main Notch view that orchestrates all states (compact, expanded, player)
//

import SwiftUI

struct NotchView: View {
    @StateObject private var nowPlaying = NowPlayingViewModel()
    
    var body: some View {
        ZStack(alignment: .top) {
            // Background shape with hover detection (only when not in player mode)
            HStack {
                Spacer()
                NotchShape(
                    topCornerRadius: NotchLayout.topCornerRadius,
                    bottomCornerRadius: NotchLayout.bottomCornerRadius
                )
                .fill(.black)
                .frame(width: nowPlaying.shouldShowPlayer ? NotchLayout.playerWidth : NotchLayout.width, 
                       height: nowPlaying.shouldShowPlayer ? NotchLayout.playerHeight : (nowPlaying.shouldShowExpanded ? NotchLayout.expandedHeight : NotchLayout.compactHeight))
                .contentShape(Rectangle())
                .onHover { isHovering in
                    // Only handle hover when not in player mode
                    if !nowPlaying.shouldShowPlayer {
                        nowPlaying.setHoverExpansion(isHovering)
                    }
                }
                Spacer()
            }
            
            // Stroke border
            HStack {
                Spacer()
                NotchShape(
                    topCornerRadius: NotchLayout.topCornerRadius,
                    bottomCornerRadius: NotchLayout.bottomCornerRadius
                )
                .stroke(.white.opacity(0.12), lineWidth: 0.6)
                .frame(width: nowPlaying.shouldShowPlayer ? NotchLayout.playerWidth : NotchLayout.width,
                       height: nowPlaying.shouldShowPlayer ? NotchLayout.playerHeight : (nowPlaying.shouldShowExpanded ? NotchLayout.expandedHeight : NotchLayout.compactHeight))
                Spacer()
            }
            .allowsHitTesting(false)
            
            // Content - Player view when hovering, otherwise Compact/Info
            if nowPlaying.shouldShowPlayer {
                PlayerView(
                    artwork: nowPlaying.artwork,
                    title: nowPlaying.title,
                    artist: nowPlaying.artist,
                    textColor: nowPlaying.dominantColor,
                    isPlaying: nowPlaying.isPlaying,
                    currentTime: nowPlaying.currentTime,
                    duration: nowPlaying.duration,
                    onPlayPause: { nowPlaying.togglePlayPause() },
                    onNext: { nowPlaying.nextTrack() },
                    onPrevious: { nowPlaying.previousTrack() }
                )
                .allowsHitTesting(true)
                .contentShape(Rectangle())
                .onHover { isHovering in
                    // Handle hover exit when in player mode
                    if !isHovering {
                        nowPlaying.setHoverExpansion(false)
                    }
                }
            } else {
                ZStack {
                    NotchContent(
                        artwork: nowPlaying.artwork,
                        title: nowPlaying.title,
                        artist: nowPlaying.artist,
                        isExpanded: nowPlaying.shouldShowExpanded,
                        textColor: nowPlaying.dominantColor
                    )
                    .frame(width: NotchLayout.width)
                }
                .frame(maxWidth: .infinity)
                .allowsHitTesting(false)
            }
        }
        .frame(
            width: NotchLayout.playerWidth,
            height: NotchLayout.playerHeight,
            alignment: .top
        )
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: nowPlaying.shouldShowPlayer)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: nowPlaying.shouldShowExpanded)
    }
}

#Preview {
    NotchView()
        .padding()
        .background(Color.gray.opacity(0))
}

