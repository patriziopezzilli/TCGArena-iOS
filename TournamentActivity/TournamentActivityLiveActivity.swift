//
//  TournamentActivityLiveActivity.swift
//  TournamentActivity
//
//  Created by Patrizio Pezzilli on 16/12/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct TournamentActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct TournamentActivityLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TournamentActivityAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension TournamentActivityAttributes {
    fileprivate static var preview: TournamentActivityAttributes {
        TournamentActivityAttributes(name: "World")
    }
}

extension TournamentActivityAttributes.ContentState {
    fileprivate static var smiley: TournamentActivityAttributes.ContentState {
        TournamentActivityAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: TournamentActivityAttributes.ContentState {
         TournamentActivityAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: TournamentActivityAttributes.preview) {
   TournamentActivityLiveActivity()
} contentStates: {
    TournamentActivityAttributes.ContentState.smiley
    TournamentActivityAttributes.ContentState.starEyes
}
