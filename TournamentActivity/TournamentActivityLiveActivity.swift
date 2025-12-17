//
//  TournamentActivityLiveActivity.swift
//  TournamentActivity
//
//  Created by Patrizio Pezzilli on 16/12/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Activity Attributes
struct TournamentActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var status: TournamentLiveStatus
        var startDate: Date
        var currentRound: Int?
        var totalRounds: Int?
    }
    
    // Static properties - don't change during activity
    var tournamentId: Int64
    var tournamentName: String
    var shopName: String
    var tcgType: String
    var tcgColor: String // Hex color string
}

// MARK: - Tournament Status
enum TournamentLiveStatus: String, Codable, Hashable {
    case upcoming = "UPCOMING"
    case countdown = "COUNTDOWN"
    case inProgress = "IN_PROGRESS"
    
    var displayText: String {
        switch self {
        case .upcoming: return "STA PER INIZIARE"
        case .countdown: return "INIZIA TRA"
        case .inProgress: return "IN CORSO"
        }
    }
    
    var icon: String {
        switch self {
        case .upcoming: return "clock.fill"
        case .countdown: return "timer"
        case .inProgress: return "play.fill"
        }
    }
}

// MARK: - Live Activity Widget
struct TournamentActivityLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TournamentActivityAttributes.self) { context in
            // Lock Screen / Banner UI
            LockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded Dynamic Island
                DynamicIslandExpandedRegion(.leading) {
                    ExpandedLeadingView(context: context)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    ExpandedTrailingView(context: context)
                }
                DynamicIslandExpandedRegion(.center) {
                    ExpandedCenterView(context: context)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ExpandedBottomView(context: context)
                }
            } compactLeading: {
                // Compact - Left side
                CompactLeadingView(context: context)
            } compactTrailing: {
                // Compact - Right side
                CompactTrailingView(context: context)
            } minimal: {
                // Minimal - only icon
                MinimalView(context: context)
            }
            .widgetURL(URL(string: "tcgarena://tournament/\(context.attributes.tournamentId)"))
            .keylineTint(Color(hex: context.attributes.tcgColor) ?? .blue)
        }
    }
}

// MARK: - Lock Screen View (Main Banner)
struct LockScreenView: View {
    let context: ActivityViewContext<TournamentActivityAttributes>
    
    var baseColor: Color {
        Color(hex: context.attributes.tcgColor) ?? .blue
    }
    
    // Pastel background
    var pastelColor: Color {
        baseColor.opacity(0.15)
    }
    
    // Darker accent for text
    var accentColor: Color {
        baseColor
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Left Side: Big Icon & Time/Status
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: context.state.status.icon)
                        .font(.system(size: 16, weight: .black))
                        .foregroundColor(accentColor)
                    
                    Text(context.state.status.displayText)
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundColor(accentColor.opacity(0.8))
                        .tracking(0.5)
                }
                
                if context.state.status == .inProgress {
                    HStack(spacing: 6) {
                        Text("ROUND")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("\(context.state.currentRound ?? 1)")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundColor(accentColor)
                        
                        Text("/ \(context.state.totalRounds ?? 1)")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text(context.state.startDate, style: .timer)
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundColor(accentColor)
                        .minimumScaleFactor(0.8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Right Side: Tournament Info
            VStack(alignment: .trailing, spacing: 4) {
                Text(context.attributes.tournamentName)
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.trailing)
                    .lineLimit(2)
                
                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 10))
                    Text(context.attributes.shopName)
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(20)
        .background(
            ZStack {
                Color.white
                pastelColor
            }
        )
        .activityBackgroundTint(nil) // Let the view background handle it
        .activitySystemActionForegroundColor(.black)
    }
}

// MARK: - Dynamic Island Views
struct CompactLeadingView: View {
    let context: ActivityViewContext<TournamentActivityAttributes>
    
    var tcgColor: Color {
        Color(hex: context.attributes.tcgColor) ?? .blue
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(tcgColor.opacity(0.2))
                .frame(width: 26, height: 26)
            
            Image(systemName: "trophy.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(tcgColor)
        }
    }
}

struct CompactTrailingView: View {
    let context: ActivityViewContext<TournamentActivityAttributes>
    
    var tcgColor: Color {
        Color(hex: context.attributes.tcgColor) ?? .blue
    }
    
    var body: some View {
        Group {
            if context.state.status == .inProgress {
                HStack(spacing: 4) {
                    Text("R\(context.state.currentRound ?? 1)")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundColor(tcgColor)
                }
            } else {
                Text(context.state.startDate, style: .timer)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(tcgColor)
                    .frame(width: 44)
            }
        }
    }
}

struct MinimalView: View {
    let context: ActivityViewContext<TournamentActivityAttributes>
    
    var tcgColor: Color {
        Color(hex: context.attributes.tcgColor) ?? .blue
    }
    
    var body: some View {
        Image(systemName: "trophy.fill")
            .font(.system(size: 12))
            .foregroundColor(tcgColor)
    }
}

struct ExpandedLeadingView: View {
    let context: ActivityViewContext<TournamentActivityAttributes>
    
    var tcgColor: Color {
        Color(hex: context.attributes.tcgColor) ?? .blue
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(tcgColor.opacity(0.15))
                .frame(width: 50, height: 50)
            
            Image(systemName: "trophy.fill")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(tcgColor)
        }
    }
}

struct ExpandedTrailingView: View {
    let context: ActivityViewContext<TournamentActivityAttributes>
    
    var tcgColor: Color {
        Color(hex: context.attributes.tcgColor) ?? .blue
    }
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            if context.state.status == .inProgress {
                Text("ROUND")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
                    .tracking(1)
                
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text("\(context.state.currentRound ?? 1)")
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundColor(tcgColor)
                    Text("/\(context.state.totalRounds ?? 1)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                }
            } else {
                Text("INIZIO")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
                    .tracking(1)
                
                Text(context.state.startDate, style: .timer)
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundColor(tcgColor)
                    .multilineTextAlignment(.trailing)
            }
        }
    }
}

struct ExpandedCenterView: View {
    let context: ActivityViewContext<TournamentActivityAttributes>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(context.attributes.tournamentName)
                .font(.system(size: 14, weight: .heavy))
                .foregroundColor(.white)
                .lineLimit(1)
            
            Text(context.attributes.shopName)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
    }
}

struct ExpandedBottomView: View {
    let context: ActivityViewContext<TournamentActivityAttributes>
    
    var tcgColor: Color {
        Color(hex: context.attributes.tcgColor) ?? .blue
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            
            Text(context.state.status.displayText)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding(.top, 8)
    }
}

// MARK: - Color Extension
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Previews
extension TournamentActivityAttributes {
    fileprivate static var preview: TournamentActivityAttributes {
        TournamentActivityAttributes(
            tournamentId: 1,
            tournamentName: "Pokemon Regional",
            shopName: "GameStop Milano",
            tcgType: "pokemon",
            tcgColor: "#F5A623"
        )
    }
}

extension TournamentActivityAttributes.ContentState {
    fileprivate static var upcoming: TournamentActivityAttributes.ContentState {
        TournamentActivityAttributes.ContentState(
            status: .upcoming,
            startDate: Date().addingTimeInterval(3600)
        )
    }
    
    fileprivate static var inProgress: TournamentActivityAttributes.ContentState {
        TournamentActivityAttributes.ContentState(
            status: .inProgress,
            startDate: Date(),
            currentRound: 3,
            totalRounds: 5
        )
    }
}

#Preview("Upcoming", as: .content, using: TournamentActivityAttributes.preview) {
    TournamentActivityLiveActivity()
} contentStates: {
    TournamentActivityAttributes.ContentState.upcoming
}

#Preview("In Progress", as: .content, using: TournamentActivityAttributes.preview) {
    TournamentActivityLiveActivity()
} contentStates: {
    TournamentActivityAttributes.ContentState.inProgress
}
