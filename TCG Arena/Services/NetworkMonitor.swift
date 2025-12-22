//
//  NetworkMonitor.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 12/17/25.
//
//  Monitors network connectivity and publishes state changes.
//

import Foundation
import Network
import SwiftUI

/// A service that monitors network connectivity using NWPathMonitor.
/// Use the shared instance or inject via @EnvironmentObject.
final class NetworkMonitor: ObservableObject {
    
    static let shared = NetworkMonitor()
    
    @Published private(set) var isConnected: Bool = true
    @Published private(set) var connectionType: ConnectionType = .unknown
    
    enum ConnectionType {
        case wifi
        case cellular
        case ethernet
        case unknown
    }
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    private init() {
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - Monitoring
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.connectionType = self?.getConnectionType(path) ?? .unknown
            }
        }
        monitor.start(queue: queue)
    }
    
    private func stopMonitoring() {
        monitor.cancel()
    }
    
    private func getConnectionType(_ path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .ethernet
        }
        return .unknown
    }
    
    // MARK: - Manual Refresh
    
    /// Force a connectivity check. The monitor auto-updates, but this can be called
    /// to give user feedback when tapping "Retry".
    /// Performs a lightweight HTTP request to verify actual internet access.
    func checkConnectivity() {
        // Force manual check by pinging a reliable server (Google DNS)
        guard let url = URL(string: "https://www.google.com") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 3.0 // Short timeout for UI responsiveness
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] _, response, error in
            DispatchQueue.main.async {
                if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                    // Actual connection confirmed
                    self?.isConnected = true
                } else if let error = error {
                    // Still failing
                }
            }
        }
        task.resume()
    }
}
