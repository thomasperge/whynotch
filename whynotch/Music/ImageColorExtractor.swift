//
//  ImageColorExtractor.swift
//  whynotch
//
//  Extracts the dominant color from an NSImage
//

import AppKit

enum ImageColorExtractor {
    /// Extracts the dominant color from an image
    /// - Parameter image: The image to analyze
    /// - Returns: The dominant color, or nil if extraction fails
    static func extractDominantColor(from image: NSImage) -> NSColor? {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }
        
        // Resize image for performance (analyze a smaller version)
        let targetSize = CGSize(width: 50, height: 50)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        guard let context = CGContext(
            data: nil,
            width: Int(targetSize.width),
            height: Int(targetSize.height),
            bitsPerComponent: 8,
            bytesPerRow: Int(targetSize.width) * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }
        
        context.interpolationQuality = .low
        context.draw(cgImage, in: CGRect(origin: .zero, size: targetSize))
        
        guard let pixelData = context.data else {
            return nil
        }
        
        let data = pixelData.assumingMemoryBound(to: UInt8.self)
        var colorCounts: [UInt32: (count: Int, brightness: CGFloat)] = [:]
        
        // Sample pixels (every 2nd pixel for performance)
        let width = Int(targetSize.width)
        let height = Int(targetSize.height)
        
        for y in stride(from: 0, to: height, by: 2) {
            for x in stride(from: 0, to: width, by: 2) {
                let pixelIndex = (y * width + x) * 4
                
                let r = UInt32(data[pixelIndex])
                let g = UInt32(data[pixelIndex + 1])
                let b = UInt32(data[pixelIndex + 2])
                
                // Quantize colors to reduce noise (group similar colors)
                let quantizedR = (r / 8) * 8
                let quantizedG = (g / 8) * 8
                let quantizedB = (b / 8) * 8
                
                // Calculate brightness (perceived luminance)
                let rFloat = CGFloat(quantizedR) / 255.0
                let gFloat = CGFloat(quantizedG) / 255.0
                let bFloat = CGFloat(quantizedB) / 255.0
                let brightness = (0.299 * rFloat + 0.587 * gFloat + 0.114 * bFloat)
                
                let colorKey = (quantizedR << 16) | (quantizedG << 8) | quantizedB
                
                if let existing = colorCounts[colorKey] {
                    colorCounts[colorKey] = (count: existing.count + 1, brightness: brightness)
                } else {
                    colorCounts[colorKey] = (count: 1, brightness: brightness)
                }
            }
        }
        
        // Filter out very dark colors (brightness < 0.25) and find the most frequent bright color
        let brightColors = colorCounts.filter { $0.value.brightness >= 0.25 }
        
        let selectedColor: UInt32
        if let brightest = brightColors.max(by: { $0.value.count < $1.value.count || ($0.value.count == $1.value.count && $0.value.brightness < $1.value.brightness) }) {
            selectedColor = brightest.key
        } else if let mostFrequent = colorCounts.max(by: { $0.value.count < $1.value.count }) {
            // If all colors are dark, take the most frequent and brighten it
            selectedColor = mostFrequent.key
        } else {
            return nil
        }
        
        var r = CGFloat((selectedColor >> 16) & 0xFF) / 255.0
        var g = CGFloat((selectedColor >> 8) & 0xFF) / 255.0
        var b = CGFloat(selectedColor & 0xFF) / 255.0
        
        // Calculate current brightness
        let currentBrightness = 0.299 * r + 0.587 * g + 0.114 * b
        
        // If the color is too dark, brighten it to at least 0.75 brightness (more vivid)
        if currentBrightness < 0.75 {
            let targetBrightness: CGFloat = 0.8 // Increased from 0.65 to 0.8 for more vivid colors
            let scale = targetBrightness / max(currentBrightness, 0.01)
            
            r = min(1.0, r * scale)
            g = min(1.0, g * scale)
            b = min(1.0, b * scale)
        }
        
        return NSColor(red: r, green: g, blue: b, alpha: 1.0)
    }
}

