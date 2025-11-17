//
//  NotchContent.swift
//  whynotch
//
//  Compact and expanded content view for the Notch
//

import SwiftUI
import AppKit

struct NotchContent: View {
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

