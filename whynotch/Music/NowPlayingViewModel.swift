//
//  NowPlayingViewModel.swift
//  whynotch
//
//  Polls the system Now Playing info (Spotify, Apple Music, etc.)
//  and exposes artwork / metadata for the notch UI.
//

import Foundation
import Combine
import MediaPlayer
import AppKit

@MainActor
final class NowPlayingViewModel: ObservableObject {
    @Published var artwork: NSImage?
    @Published var title: String?
    @Published var artist: String?
    @Published var shouldShowExpanded: Bool = false
    @Published var shouldShowPlayer: Bool = false
    @Published var dominantColor: NSColor?
    @Published var isPlaying: Bool = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    
    private var cancellables = Set<AnyCancellable>()
    private var pollingTask: Task<Void, Never>?
    private var spotifyNotificationTask: Task<Void, Never>?
    private var expansionTask: Task<Void, Never>?
    private var timeUpdateTask: Task<Void, Never>?
    
    init() {
        setupObservers()
        setupSpotifyNotifications()
        startPolling()
    }
    
    deinit {
        pollingTask?.cancel()
        spotifyNotificationTask?.cancel()
        expansionTask?.cancel()
        timeUpdateTask?.cancel()
    }
    
    private func triggerExpansion() {
        expansionTask?.cancel()
        shouldShowExpanded = true
        
        expansionTask = Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000) // 2.5 seconds
            if !Task.isCancelled {
                shouldShowExpanded = false
            }
        }
    }
    
    func setHoverExpansion(_ isHovering: Bool) {
        // Avoid state changes if already in the correct state
        if isHovering && shouldShowPlayer {
            return
        }
        if !isHovering && !shouldShowPlayer {
            return
        }
        
        expansionTask?.cancel()
        
        // Only show player if there's music playing
        if isHovering && (artwork != nil || title != nil || artist != nil) {
            shouldShowPlayer = true
            shouldShowExpanded = false // Hide Info when showing Player
            startTimeUpdates()
        } else if !isHovering {
            shouldShowPlayer = false
            shouldShowExpanded = false // Return to Compact when hover ends
            timeUpdateTask?.cancel()
            timeUpdateTask = nil
        }
    }
    
    private func startTimeUpdates() {
        timeUpdateTask?.cancel()
        timeUpdateTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                await self?.updatePlaybackTime()
                try? await Task.sleep(nanoseconds: 200_000_000) // Update every 0.2 seconds
            }
        }
    }
    
    private func updatePlaybackTime() async {
        guard isSpotifyActive() else { return }
        
        let script = """
        tell application "Spotify"
            try
                set playerPosition to player position
                set durationSeconds to duration of current track
                return {playerPosition, durationSeconds}
            on error
                return {0, 0}
            end try
        end tell
        """
        
        do {
            guard let descriptor = try await AppleScriptHelper.execute(script) else { return }
            guard descriptor.numberOfItems >= 2 else { return }
            
            if let position = descriptor.atIndex(1)?.doubleValue {
                currentTime = position
            }
            if let dur = descriptor.atIndex(2)?.doubleValue {
                // Spotify returns duration in milliseconds
                duration = dur / 1000.0
            }
        } catch {
            // Silently handle errors
        }
    }
    
    func togglePlayPause() {
        Task {
            let script = """
            tell application "Spotify"
                if player state is playing then
                    pause
                else
                    play
                end if
            end tell
            """
            try? await AppleScriptHelper.executeVoid(script)
            await fetchFromSpotify()
        }
    }
    
    func nextTrack() {
        Task {
            let script = """
            tell application "Spotify"
                next track
            end tell
            """
            try? await AppleScriptHelper.executeVoid(script)
            await fetchFromSpotify()
        }
    }
    
    func previousTrack() {
        Task {
            let script = """
            tell application "Spotify"
                previous track
            end tell
            """
            try? await AppleScriptHelper.executeVoid(script)
            await fetchFromSpotify()
        }
    }
    
    private func setupObservers() {
        // Listen to system notifications for playback changes
        NSWorkspace.shared.notificationCenter
            .publisher(for: NSWorkspace.didActivateApplicationNotification)
            .sink { [weak self] _ in
                self?.fetchNowPlayingFromSystem()
            }
            .store(in: &cancellables)
    }
    
    private func setupSpotifyNotifications() {
        // Listen to Spotify's distributed notifications for instant updates
        spotifyNotificationTask = Task { @MainActor [weak self] in
            let notifications = DistributedNotificationCenter.default().notifications(
                named: NSNotification.Name("com.spotify.client.PlaybackStateChanged")
            )
            
            for await _ in notifications {
                await self?.fetchFromSpotify()
            }
        }
    }
    
    private func startPolling() {
        pollingTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                self?.fetchNowPlayingFromSystem()
                try? await Task.sleep(nanoseconds: 500_000_000) // Poll every 0.5 seconds
            }
        }
    }

    private func fetchNowPlayingFromSystem() {
        // Try MPNowPlayingInfoCenter first (for Apple Music, etc.)
        let infoCenter = MPNowPlayingInfoCenter.default()
        let info = infoCenter.nowPlayingInfo
        
        if let info = info, !info.isEmpty {
            processMPNowPlayingInfo(info)
            return
        }
        
        // If MPNowPlayingInfoCenter is empty, try Spotify via AppleScript
        if isSpotifyActive() {
            Task {
                await fetchFromSpotify()
            }
        } else {
            // No music playing
            if artwork != nil || title != nil || artist != nil {
                artwork = nil
                title = nil
                artist = nil
                dominantColor = nil
            }
        }
    }
    
    private func processMPNowPlayingInfo(_ info: [String: Any]) {
        let newTitle = info[MPMediaItemPropertyTitle] as? String
        let newArtist = info[MPMediaItemPropertyArtist] as? String
        
        let titleChanged = newTitle != title
        let artistChanged = newArtist != artist
        
        if titleChanged {
            title = newTitle
        }
        if artistChanged {
            artist = newArtist
        }
        
        // Trigger expansion if title or artist changed
        if titleChanged || artistChanged {
            triggerExpansion()
        }

        // Check artwork
        if let art = info[MPMediaItemPropertyArtwork] as? MPMediaItemArtwork {
            let size = art.bounds.size == .zero ? CGSize(width: 80, height: 80) : art.bounds.size
            
            if let image = art.image(at: size) {
                if artwork?.tiffRepresentation != image.tiffRepresentation {
                    artwork = image
                    extractDominantColor(from: image)
                }
            }
        }
    }
    
    private func isSpotifyActive() -> Bool {
        let runningApps = NSWorkspace.shared.runningApplications
        return runningApps.contains { $0.bundleIdentifier == "com.spotify.client" }
    }
    
    @MainActor
    private func fetchFromSpotify() async {
        // First check that Spotify responds
        let checkScript = """
        tell application "Spotify"
            get name
        end tell
        """
        
        do {
            _ = try await AppleScriptHelper.execute(checkScript)
        } catch {
            return
        }
        
        // Now fetch the playback info
        let script = """
        tell application "Spotify"
            try
                set playerStateStr to player state as string
                set isPlaying to playerStateStr is "playing"
                
                set currentTrackName to name of current track
                set currentTrackArtist to artist of current track
                set artworkURL to artwork url of current track
                return {isPlaying, currentTrackName, currentTrackArtist, artworkURL}
            on error errMsg number errNum
                return {false, errMsg, errNum, ""}
            end try
        end tell
        """
        
        do {
            guard let descriptor = try await AppleScriptHelper.execute(script) else {
                return
            }
            
            guard descriptor.numberOfItems >= 4 else {
                return
            }
            
            // Check if it's an error
            let firstItem = descriptor.atIndex(1)
            let secondItem = descriptor.atIndex(2)
            let thirdItem = descriptor.atIndex(3)
            
            if let errorMsg = secondItem?.stringValue, 
               (errorMsg.contains("error") || 
                errorMsg.contains("isn't running") || 
                errorMsg.contains("n'est pas lancé") ||
                errorMsg.contains("Application")) {
                return
            }
            
            let isPlayingValue = firstItem?.booleanValue ?? false
            let trackName = descriptor.atIndex(2)?.stringValue ?? ""
            let trackArtist = descriptor.atIndex(3)?.stringValue ?? ""
            let artworkURL = descriptor.atIndex(4)?.stringValue ?? ""
            
            // Update playing state (but don't clear data when paused)
            isPlaying = isPlayingValue
            
            // Only return early if we have no track info at all
            if trackName.isEmpty && trackArtist.isEmpty {
                return
            }
            
            // Update title and artist
            let titleChanged = trackName != title
            let artistChanged = trackArtist != artist
            
            if titleChanged {
                title = trackName
            }
            if artistChanged {
                artist = trackArtist
            }
            
            // Trigger expansion if title or artist changed
            if titleChanged || artistChanged {
                triggerExpansion()
            }
            
            // Load artwork from URL
            if !artworkURL.isEmpty, let url = URL(string: artworkURL) {
                do {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    if let image = NSImage(data: data) {
                        artwork = image
                        extractDominantColor(from: image)
                    }
                } catch {
                    // Silently fail artwork loading
                }
            } else {
                if artwork != nil {
                    artwork = nil
                    dominantColor = nil
                }
            }
        } catch {
            // Silently handle errors
        }
    }
    
    private func extractDominantColor(from image: NSImage) {
        Task { @MainActor in
            // Extract color on background thread for performance
            let color = await Task.detached {
                ImageColorExtractor.extractDominantColor(from: image)
            }.value
            
            self.dominantColor = color
        }
    }
}

