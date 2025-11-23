//
//  SettingsService.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/10/25.
//

import SwiftUI

class SettingsService: ObservableObject {
    @Published var isDarkMode: Bool {
        didSet {
            UserDefaults.standard.set(isDarkMode, forKey: "darkModeEnabled")
            print("Dark mode changed to: \(isDarkMode)")
        }
    }
    
    @Published var showMarketValues: Bool {
        didSet {
            UserDefaults.standard.set(showMarketValues, forKey: "showMarketValues")
        }
    }
    
    init() {
        self.isDarkMode = UserDefaults.standard.bool(forKey: "darkModeEnabled")
        self.showMarketValues = UserDefaults.standard.bool(forKey: "showMarketValues")
        
        print("SettingsService initialized - Dark mode: \(isDarkMode)")
    }
}