//
//  NotchView.swift
//  whynotch
//
//
import SwiftUI

struct NotchView: View {
    private enum Layout {
        static let width: CGFloat = 255
        static let compactHeight: CGFloat = 33
        static let expandedHeight: CGFloat = 53 // 33 + 20
        static let topCornerRadius: CGFloat = 6
        static let bottomCornerRadius: CGFloat = 13
    }
    
    @StateObject private var nowPlaying = NowPlayingViewModel()
    
    var body: some View {
        let currentHeight = nowPlaying.shouldShowExpanded ? Layout.expandedHeight : Layout.compactHeight
        
        ZStack(alignment: .top) {
            // Background shape with hover detection
            NotchShape(
                topCornerRadius: Layout.topCornerRadius,
                bottomCornerRadius: Layout.bottomCornerRadius
            )
            .fill(.black)
            .frame(width: Layout.width, height: currentHeight)
            .onHover { isHovering in
                nowPlaying.setHoverExpansion(isHovering)
            }
            
            // Stroke border
            NotchShape(
                topCornerRadius: Layout.topCornerRadius,
                bottomCornerRadius: Layout.bottomCornerRadius
            )
            .stroke(.white.opacity(0.12), lineWidth: 0.6)
            .frame(width: Layout.width, height: currentHeight)
            .allowsHitTesting(false)
            
            // Content
            NotchContent(
                artwork: nowPlaying.artwork,
                title: nowPlaying.title,
                artist: nowPlaying.artist,
                isExpanded: nowPlaying.shouldShowExpanded,
                textColor: nowPlaying.dominantColor
            )
            .allowsHitTesting(false)
        }
        .frame(width: Layout.width, height: Layout.expandedHeight, alignment: .top)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: nowPlaying.shouldShowExpanded)
    }
}

private struct NotchContent: View {
    let artwork: NSImage?
    let title: String?
    let artist: String?
    let isExpanded: Bool
    let textColor: NSColor?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top section (always visible) - always at the top
            HStack {
                ArtworkView(image: artwork)
                
                Spacer()
                
                PlayerIndicator(color: textColor)
            }
            .padding(.horizontal, 13.5)
            .frame(height: 33)
            
            // Expanded section (title/artist) - appears below
            if isExpanded {
                HStack(spacing: 6) {
                    Image(systemName: "music.note")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    if let artist = artist, let title = title {
                        Text("\(artist) - \(title)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(textColor != nil ? Color(nsColor: textColor!).opacity(0.7) : .white.opacity(0.4))
                            .lineLimit(1)
                            .truncationMode(.tail)
                    } else if let title = title {
                        Text(title)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(textColor != nil ? Color(nsColor: textColor!).opacity(0.7) : .white.opacity(0.4))
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 13.5)
                .padding(.top, 0)
                .frame(height: 16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

private struct PlayerIndicator: View {
    let color: NSColor?
    private let barWidth: CGFloat = 2.5
    
    // Random offsets and speeds for each bar to make them independent
    private let barConfigs: [(offset: Double, speed: Double)] = [
        (offset: 0.0, speed: 6.2),
        (offset: 1.3, speed: 5.6),
        (offset: 2.7, speed: 5.9)
    ]
    
    var body: some View {
        TimelineView(.animation) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            let indicatorColor = color != nil ? Color(nsColor: color!).opacity(0.7) : Color.gray.opacity(0.75)
            
            HStack(spacing: 2) {
                ForEach(0..<3, id: \.self) { index in
                    Capsule()
                        .fill(indicatorColor)
                        .frame(width: barWidth, height: barHeight(for: time, index: index))
                }
            }
            .frame(height: 10)
        }
        .padding(.trailing, 4)
    }
    
    private func barHeight(for time: TimeInterval, index: Int) -> CGFloat {
        let config = barConfigs[index]
        let sine = (sin(time * config.speed + config.offset) + 1) / 2
        return CGFloat(5 + sine * 4)
    }
}

#Preview {
    NotchView()
        .padding()
        .background(Color.gray.opacity(0))
}

private struct ArtworkView: View {
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

