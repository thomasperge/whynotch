//
//  PlayerIndicator.swift
//  whynotch
//
//  Animated music indicator bars
//

import SwiftUI
import AppKit

struct PlayerIndicator: View {
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
            let indicatorColor = color != nil ? Color(nsColor: color!).opacity(0.85) : Color.gray.opacity(0.75)
            
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

