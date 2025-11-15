//
//  NotchView.swift
//  whynotch
//
//  Created by ChatGPT on 14/11/2025.
//
import SwiftUI

struct NotchView: View {
    private enum Layout {
        static let width: CGFloat = 255
        static let height: CGFloat = 33
        static let topCornerRadius: CGFloat = 6
        static let bottomCornerRadius: CGFloat = 11
    }
    
    var body: some View {
        NotchShape(
            topCornerRadius: Layout.topCornerRadius,
            bottomCornerRadius: Layout.bottomCornerRadius
        )
        .fill(.black)
        .frame(width: Layout.width, height: Layout.height)
        .overlay(
            NotchShape(
                topCornerRadius: Layout.topCornerRadius,
                bottomCornerRadius: Layout.bottomCornerRadius
            )
            .stroke(.white.opacity(0.12), lineWidth: 0.6)
        )
        .overlay(CompactContent())
    }
}

private struct CompactContent: View {
    var body: some View {
        HStack {
            Image("ladygaga")
                .resizable()
                .scaledToFill()
                .frame(width: 20, height: 20)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .stroke(Color.white.opacity(0.55), lineWidth: 0.3)
                )
            
            Spacer()
            
            PlayerIndicator()
        }
        .padding(.horizontal, 12.5)
    }
}

private struct PlayerIndicator: View {
    private let barWidth: CGFloat = 2.5
    
    var body: some View {
        TimelineView(.animation) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            HStack(spacing: 2) {
                ForEach(0..<3, id: \.self) { index in
                    Capsule()
                        .fill(Color.gray.opacity(0.75))
                        .frame(width: barWidth, height: barHeight(for: time, index: index))
                }
            }
            .frame(height: 10)
        }
        .padding(.trailing, 4)
    }
    
    private func barHeight(for time: TimeInterval, index: Int) -> CGFloat {
        let offset = Double(index) * 0.2
        let sine = (sin(time * 3.2 + offset) + 1) / 2
        return CGFloat(5 + sine * 4)
    }
}

#Preview {
    NotchView()
        .padding()
        .background(Color.gray.opacity(0))
}
