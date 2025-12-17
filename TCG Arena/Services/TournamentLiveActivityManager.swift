//
//  TournamentLiveActivityManager.swift
//  TCG Arena
//
//  Manages Tournament Live Activities - start, update, and end
//

import Foundation
import ActivityKit
import SwiftUI

// Import the shared types from the widget extension
// Note: TournamentActivityAttributes is defined in the widget extension

@MainActor
class TournamentLiveActivityManager: ObservableObject {
    static let shared = TournamentLiveActivityManager()
    
    @Published var currentActivity: Activity<TournamentActivityAttributes>?
    @Published var isActivityRunning: Bool = false
    
    private var updateTimer: Timer?
    
    private init() {
        // Check for any existing activities
        checkExistingActivities()
    }
    
    // MARK: - Public Methods
    
    /// Check if Live Activities are supported
    var areActivitiesSupported: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }
    
    /// Start a Live Activity for a tournament
    /// - Parameters:
    ///   - tournament: The tournament to track
    ///   - shopName: Name of the shop hosting the tournament
    /// - Returns: True if activity was started successfully
    func startActivity(
        tournamentId: Int64,
        tournamentName: String,
        shopName: String,
        tcgType: String,
        startDate: Date
    ) -> Bool {
        guard areActivitiesSupported else {
            print("⚠️ Live Activities are not supported or enabled")
            return false
        }
        
        // End any existing activity first
        endAllActivities()
        
        let attributes = TournamentActivityAttributes(
            tournamentId: tournamentId,
            tournamentName: tournamentName,
            shopName: shopName,
            tcgType: tcgType,
            tcgColor: getTCGColor(for: tcgType)
        )
        
        let initialStatus = determineStatus(for: startDate)
        let initialState = TournamentActivityAttributes.ContentState(
            status: initialStatus,
            startDate: startDate,
            currentRound: nil,
            totalRounds: nil
        )
        
        let content = ActivityContent(state: initialState, staleDate: nil)
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
            
            currentActivity = activity
            isActivityRunning = true
            
            print("✅ Live Activity started for tournament: \(tournamentName)")
            
            // Start monitoring for status changes
            startStatusMonitoring(startDate: startDate)
            
            return true
        } catch {
            print("❌ Failed to start Live Activity: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Update the activity status
    func updateStatus(_ status: TournamentLiveStatus, currentRound: Int? = nil, totalRounds: Int? = nil) async {
        guard let activity = currentActivity else { return }
        
        let newState = TournamentActivityAttributes.ContentState(
            status: status,
            startDate: activity.content.state.startDate,
            currentRound: currentRound,
            totalRounds: totalRounds
        )
        
        await activity.update(
            ActivityContent(state: newState, staleDate: nil)
        )
        
        print("🔄 Live Activity updated: \(status.rawValue)")
    }
    
    /// Update to "In Progress" with round information
    func updateToInProgress(currentRound: Int, totalRounds: Int) async {
        await updateStatus(.inProgress, currentRound: currentRound, totalRounds: totalRounds)
    }
    
    /// End the current Live Activity
    func endActivity() async {
        guard let activity = currentActivity else { return }
        
        stopStatusMonitoring()
        
        await activity.end(nil, dismissalPolicy: .default)
        currentActivity = nil
        isActivityRunning = false
        
        print("🏁 Live Activity ended")
    }
    
    /// End all active tournament activities
    func endAllActivities() {
        stopStatusMonitoring()
        
        Task {
            for activity in Activity<TournamentActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            currentActivity = nil
            isActivityRunning = false
        }
    }
    
    // MARK: - Private Methods
    
    private func checkExistingActivities() {
        let activities = Activity<TournamentActivityAttributes>.activities
        if let existingActivity = activities.first {
            currentActivity = existingActivity
            isActivityRunning = true
            print("📱 Found existing Live Activity")
        }
    }
    
    private func determineStatus(for startDate: Date) -> TournamentLiveStatus {
        let minutesUntilStart = startDate.timeIntervalSinceNow / 60
        
        if minutesUntilStart <= 0 {
            return .inProgress
        } else if minutesUntilStart <= 30 {
            return .countdown
        } else {
            return .upcoming
        }
    }
    
    private func startStatusMonitoring(startDate: Date) {
        stopStatusMonitoring()
        
        // Check every 30 seconds for status changes
        updateTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                let newStatus = self.determineStatus(for: startDate)
                
                // Only update if status changed
                if let currentStatus = self.currentActivity?.content.state.status,
                   currentStatus != newStatus {
                    await self.updateStatus(newStatus)
                }
                
                // Stop monitoring if tournament has started
                if newStatus == .inProgress {
                    self.stopStatusMonitoring()
                }
            }
        }
    }
    
    private func stopStatusMonitoring() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    private func getTCGColor(for tcgType: String) -> String {
        switch tcgType.lowercased() {
        case "pokemon": return "#FFD700"      // Yellow
        case "magic": return "#9B59B6"         // Purple
        case "yugioh": return "#E74C3C"        // Red
        case "onepiece": return "#E91E63"      // Pink
        case "digimon": return "#3498DB"       // Blue
        case "dragonballsuper", "dragonballfusion": return "#F39C12"  // Orange
        case "lorcana": return "#8E44AD"       // Deep Purple
        case "fleshandblood": return "#C0392B" // Dark Red
        default: return "#3498DB"              // Default Blue
        }
    }
}

// MARK: - Tournament Extension for Live Activity
extension Tournament {
    /// Check if this tournament should show Live Activity option
    var canEnableLiveActivity: Bool {
        guard let startDateParsed = parsedStartDate else { return false }
        let minutesUntilStart = startDateParsed.timeIntervalSinceNow / 60
        
        // Show option if tournament is 60 min or less away and not completed/cancelled
        return minutesUntilStart <= 60 && minutesUntilStart > -120 // Also allow up to 2h after start
            && status != .completed && status != .cancelled
    }
    
    /// Parse the startDate string to Date
    var parsedStartDate: Date? {
        let formatters: [DateFormatter] = [
            {
                let f = DateFormatter()
                f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                f.locale = Locale(identifier: "en_US_POSIX")
                return f
            }(),
            {
                let f = DateFormatter()
                f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
                f.locale = Locale(identifier: "en_US_POSIX")
                return f
            }(),
            {
                let f = DateFormatter()
                f.dateFormat = "dd MMM yyyy, HH:mm"
                f.locale = Locale(identifier: "en_US_POSIX")
                return f
            }()
        ]
        
        for formatter in formatters {
            if let date = formatter.date(from: startDate) {
                return date
            }
        }
        return nil
    }
    
    /// Start Live Activity for this tournament
    @MainActor
    func startLiveActivity(shopName: String) -> Bool {
        guard let id = self.id,
              let startDateParsed = parsedStartDate else {
            return false
        }
        
        return TournamentLiveActivityManager.shared.startActivity(
            tournamentId: id,
            tournamentName: title,
            shopName: shopName,
            tcgType: tcgType.rawValue,
            startDate: startDateParsed
        )
    }
}
