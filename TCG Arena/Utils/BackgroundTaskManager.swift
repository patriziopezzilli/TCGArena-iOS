//
//  BackgroundTaskManager.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 12/22/24.
//

import BackgroundTasks
import UIKit

/// Manager for scheduling and handling background refresh tasks
final class BackgroundTaskManager {
    
    static let shared = BackgroundTaskManager()
    
    // Task identifiers - must match Info.plist entries
    private let shopNewsRefreshTaskId = "com.tcgarena.shopnews.refresh"
    private let collectionSyncTaskId = "com.tcgarena.collection.sync"
    
    private init() {}
    
    // MARK: - Registration
    
    /// Register background tasks - call in AppDelegate.didFinishLaunchingWithOptions
    func registerTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: shopNewsRefreshTaskId, using: nil) { task in
            self.handleShopNewsRefresh(task: task as! BGAppRefreshTask)
        }
        
        BGTaskScheduler.shared.register(forTaskWithIdentifier: collectionSyncTaskId, using: nil) { task in
            self.handleCollectionSync(task: task as! BGProcessingTask)
        }
    }
    
    // MARK: - Scheduling
    
    /// Schedule shop news refresh - call when app enters background
    func scheduleShopNewsRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: shopNewsRefreshTaskId)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes from now
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("📅 BackgroundTaskManager: Shop news refresh scheduled")
        } catch {
            print("❌ BackgroundTaskManager: Could not schedule shop news refresh - \(error.localizedDescription)")
        }
    }
    
    /// Schedule collection sync - for longer running tasks
    func scheduleCollectionSync() {
        let request = BGProcessingTaskRequest(identifier: collectionSyncTaskId)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 60) // 1 hour from now
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("📅 BackgroundTaskManager: Collection sync scheduled")
        } catch {
            print("❌ BackgroundTaskManager: Could not schedule collection sync - \(error.localizedDescription)")
        }
    }
    
    // MARK: - Task Handlers
    
    private func handleShopNewsRefresh(task: BGAppRefreshTask) {
        print("🔄 BackgroundTaskManager: Executing shop news refresh")
        
        // Schedule next refresh
        scheduleShopNewsRefresh()
        
        // Create task to fetch shop news
        let refreshTask = Task { @MainActor in
            // Get subscribed shop IDs from UserDefaults
            let subscribedShopIds = UserDefaults.standard.array(forKey: "subscribedShopIds") as? [Int] ?? []
            
            if subscribedShopIds.isEmpty {
                print("📭 BackgroundTaskManager: No subscribed shops to refresh")
                task.setTaskCompleted(success: true)
                return
            }
            
            let shopService = ShopService()
            
            // Load news for each subscribed shop
            for shopId in subscribedShopIds {
                await shopService.loadShopNewsFromAPI(shopId: String(shopId))
            }
            
            print("✅ BackgroundTaskManager: Shop news refresh completed for \(subscribedShopIds.count) shops")
            task.setTaskCompleted(success: true)
        }
        
        // Handle task expiration
        task.expirationHandler = {
            refreshTask.cancel()
            task.setTaskCompleted(success: false)
        }
    }
    
    private func handleCollectionSync(task: BGProcessingTask) {
        print("🔄 BackgroundTaskManager: Executing collection sync")
        
        // Schedule next sync
        scheduleCollectionSync()
        
        let syncTask = Task {
            await MainActor.run {
                // Sync user's card collection using CardService
                let cardService = CardService()
                cardService.getUserCardCollection { result in
                    switch result {
                    case .success(let cards):
                        print("✅ BackgroundTaskManager: Collection synced - \(cards.count) cards")
                        task.setTaskCompleted(success: true)
                    case .failure(let error):
                        print("❌ BackgroundTaskManager: Collection sync failed - \(error.localizedDescription)")
                        task.setTaskCompleted(success: false)
                    }
                }
            }
        }
        
        task.expirationHandler = {
            syncTask.cancel()
            task.setTaskCompleted(success: false)
        }
    }
    
    // MARK: - Debug Helpers
    
    /// For testing: trigger background refresh manually via debugger
    /// e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.tcgarena.shopnews.refresh"]
    func debugInfo() -> String {
        return """
        Background Tasks Debug Info:
        - Shop News Refresh ID: \(shopNewsRefreshTaskId)
        - Collection Sync ID: \(collectionSyncTaskId)
        
        To test in debugger:
        e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"\(shopNewsRefreshTaskId)"]
        """
    }
}
