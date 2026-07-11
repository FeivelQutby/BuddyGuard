//
//  WatchWidgetBG.swift
//  WatchWidgetBG
//
//  Created by Benedicta Joyce Sutandyo on 09/07/26.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void){
        completion(SimpleEntry(date: Date()))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void){
        let entry = SimpleEntry(date: Date())
        completion(Timeline(entries: [entry], policy: .never))
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
}

struct WatchWidgetBGEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        Link(destination: URL(string: "buddyguard://sos")!){
            ZStack{
                Circle().fill(Color.red)
                Text("SOS").foregroundStyle(.white).font(.system(size: 10, weight: .semibold)).minimumScaleFactor(0.5)
            }
        }
        .containerBackground(for: .widget){
            Color.clear
        }
    }
}

struct WatchWidgetBG: Widget {
    let kind: String = "WatchWidgetBG"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WatchWidgetBGEntryView(entry: entry)
        }
        .supportedFamilies([.accessoryRectangular])
    }
}

#Preview(as: .accessoryRectangular) {
    WatchWidgetBG()
} timeline: {
    SimpleEntry(date: .now)
}    
