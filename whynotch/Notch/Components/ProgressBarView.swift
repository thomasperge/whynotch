//
//  ProgressBarView.swift
//  whynotch
//
//  Progress bar with time labels for the player view
//

import SwiftUI
import AppKit

struct ProgressBarView: View {
    let progress: Double
    let currentTime: TimeInterval
    let duration: TimeInterval
    let color: NSColor?
    
    var body: some View {
        VStack(spacing: 4) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    Capsule()
                        .fill(.white.opacity(0.15))
                        .frame(height: 3)
                    
                    // Progress - use dominant color if available
                    Capsule()
                        .fill(color != nil ? Color(nsColor: color!).opacity(0.7) : .white.opacity(0.7))
                        .frame(width: geometry.size.width * CGFloat(progress), height: 3)
                }
            }
            .frame(height: 3)
            
            // Time labels
            HStack {
                Text(formatTime(currentTime))
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                
                Spacer()
                
                Text(formatTime(duration))
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

