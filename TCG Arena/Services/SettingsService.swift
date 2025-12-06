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
        }
    }
    
    init() {
        self.isDarkMode = UserDefaults.standard.bool(forKey: "darkModeEnabled")
    }
}