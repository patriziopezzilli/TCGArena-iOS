//
//  TournamentActivity.swift
//  TournamentActivity
//
//  Created by Patrizio Pezzilli on 16/12/25.
//
//  Home Screen Widget - Shows upcoming tournaments the user is registered for
//

import WidgetKit
import SwiftUI

// MARK: - Widget Entry
struct TournamentWidgetEntry: TimelineEntry {
    let date: Date
    let tournament: WidgetTournament?
    let isEmpty: Bool
}

// MARK: - Widget Tournament Model
struct WidgetTournament {
    let id: Int64
    let name: String
    let shopName: String
    let startDate: Date
    let tcgType: String
    let tcgColor: String
    let isRegistered: Bool
}

// MARK: - Timeline Provider
struct TournamentWidgetProvider: TimelineProvider {
    
    func placeholder(in context: Context) -> TournamentWidgetEntry {
        TournamentWidgetEntry(
            date: Date(),
            tournament: WidgetTournament(
                id: 1,
                name: "Pokemon Championship",
                shopName: "GameStop Milano",
                startDate: Date().addingTimeInterval(3600),
                tcgType: "pokemon",
                tcgColor: "#D4A017",
                isRegistered: true
            ),
            isEmpty: false
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (TournamentWidgetEntry) -> ()) {
        // Show sample data for gallery preview
        let entry = TournamentWidgetEntry(
            date: Date(),
            tournament: WidgetTournament(
                id: 1,
                name: "Pokemon Regional",
                shopName: "Card Shop Roma",
                startDate: Date().addingTimeInterval(7200),
                tcgType: "pokemon",
                tcgColor: "#D4A017",
                isRegistered: true
            ),
            isEmpty: false
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<TournamentWidgetEntry>) -> ()) {
        // TODO: In production, read from shared UserDefaults (App Group)
        // For now, show placeholder
        let entry = TournamentWidgetEntry(
            date: Date(),
            tournament: nil,
            isEmpty: true
        )
        
        // Refresh every 30 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Widget Entry View
struct TournamentWidgetEntryView: View {
    var entry: TournamentWidgetProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        if let tournament = entry.tournament {
            tournamentView(tournament)
        } else {
            emptyView
        }
    }
    
    // MARK: - Tournament View
    @ViewBuilder
    private func tournamentView(_ tournament: WidgetTournament) -> some View {
        let tcgColor = Color(hex: tournament.tcgColor) ?? .blue
        
        Group {
            switch family {
            case .systemSmall:
                smallWidget(tournament, color: tcgColor)
            case .systemMedium:
                mediumWidget(tournament, color: tcgColor)
            default:
                smallWidget(tournament, color: tcgColor)
            }
        }
        .widgetBackground(tcgColor.opacity(0.15))
    }
    
    // MARK: - Small Widget
    private func smallWidget(_ tournament: WidgetTournament, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            // Header: Icon
            Image(systemName: getIcon(for: tournament.tcgType))
                .font(.system(size: 24, weight: .black))
                .foregroundColor(color)
                .padding(.bottom, 4)
            
            // Countdown (Main Focus)
            Text(tournament.startDate, style: .timer)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundColor(.black)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
            
            Spacer()
            
            // Tournament Name
            Text(tournament.name)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            // Shop Name
            Text(tournament.shopName)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color.secondary.opacity(0.7))
                .lineLimit(1)
        }
        .padding(14)
    }
    
    // MARK: - Medium Widget
    private func mediumWidget(_ tournament: WidgetTournament, color: Color) -> some View {
        HStack(spacing: 20) {
            // Left: Big Icon Area
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(color.opacity(0.15))
                    .frame(width: 80, height: 80)
                
                Image(systemName: getIcon(for: tournament.tcgType))
                    .font(.system(size: 36, weight: .black))
                    .foregroundColor(color)
            }
            
            // Right: Info
            VStack(alignment: .leading, spacing: 4) {
                ViewHelpers.statusBadge(text: "ISCRITTO", color: .green)
                
                // Countdown (Big & Clean)
                Text(tournament.startDate, style: .timer)
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)
                    .minimumScaleFactor(0.8)
                
                Text(tournament.name)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 12))
                    Text(tournament.shopName)
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(Color.secondary.opacity(0.7))
            }
        }
        .padding(16)
    }
    
    // MARK: - Empty View
    private var emptyView: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(.systemGray6))
                    .frame(width: 60, height: 60)
                
                Image(systemName: "trophy.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 4) {
                Text("Nessun Torneo")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Iscriviti per vedere qui il tuo prossimo evento")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetBackground(Color.white)
    }
    
    private func getIcon(for tcgType: String) -> String {
        switch tcgType.lowercased() {
        case "pokemon": return "flame.fill"
        case "magic": return "sparkles"
        case "yugioh": return "star.fill"
        case "onepiece": return "flag.fill"
        case "digimon": return "cpu.fill"
        case "dragonball", "dragonballsuper", "dragonballfusion": return "bolt.fill"
        case "lorcana": return "wand.and.stars"
        case "fleshandblood": return "shield.fill"
        default: return "gamecontroller.fill"
        }
    }
}

// MARK: - View Helpers
struct ViewHelpers {
    static func statusBadge(text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .cornerRadius(8)
    }
}

// MARK: - Widget Configuration
struct TournamentActivity: Widget {
    let kind: String = "TournamentActivity"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TournamentWidgetProvider()) { entry in
            TournamentWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Prossimo Torneo")
        .description("Mostra il prossimo torneo a cui sei iscritto")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}

extension View {
    func widgetBackground(_ color: Color) -> some View {
        if #available(iOS 17.0, *) {
            return containerBackground(color, for: .widget)
        } else {
            return background(color)
        }
    }
}



// MARK: - Previews
#Preview("Small - Pokemon", as: .systemSmall) {
    TournamentActivity()
} timeline: {
    TournamentWidgetEntry(
        date: .now,
        tournament: WidgetTournament(
            id: 1,
            name: "Pokemon Regional Championship",
            shopName: "GameStop Milano",
            startDate: Date().addingTimeInterval(3600),
            tcgType: "pokemon",
            tcgColor: "#D4A017",
            isRegistered: true
        ),
        isEmpty: false
    )
}

#Preview("Small - Magic", as: .systemSmall) {
    TournamentActivity()
} timeline: {
    TournamentWidgetEntry(
        date: .now,
        tournament: WidgetTournament(
            id: 2,
            name: "Modern Horizons Draft",
            shopName: "Libreria del Fumetto",
            startDate: Date().addingTimeInterval(7200),
            tcgType: "magic",
            tcgColor: "#6B21A8",
            isRegistered: true
        ),
        isEmpty: false
    )
}

#Preview("Medium - Pokemon", as: .systemMedium) {
    TournamentActivity()
} timeline: {
    TournamentWidgetEntry(
        date: .now,
        tournament: WidgetTournament(
            id: 1,
            name: "Pokemon Regional Championship",
            shopName: "GameStop Milano Centro",
            startDate: Date().addingTimeInterval(1800),
            tcgType: "pokemon",
            tcgColor: "#D4A017",
            isRegistered: true
        ),
        isEmpty: false
    )
}

#Preview("Medium - Yu-Gi-Oh", as: .systemMedium) {
    TournamentActivity()
} timeline: {
    TournamentWidgetEntry(
        date: .now,
        tournament: WidgetTournament(
            id: 3,
            name: "Yu-Gi-Oh! Regional Qualifier",
            shopName: "Card Market Store",
            startDate: Date().addingTimeInterval(5400),
            tcgType: "yugioh",
            tcgColor: "#B91C1C",
            isRegistered: true
        ),
        isEmpty: false
    )
}

#Preview("Empty State", as: .systemSmall) {
    TournamentActivity()
} timeline: {
    TournamentWidgetEntry(date: .now, tournament: nil, isEmpty: true)
}
