//
//  OpenSOSIntent.swift
//  WatchWidgetBG
//
//  Created by Benedicta Joyce Sutandyo on 09/07/26.
//

import WidgetKit
import AppIntents

struct OpenSOSIntent: AppIntent {
    static var title: LocalizedStringResource = "BuddyGuard Emergency"
    static var openAppWhenRun: Bool = true
    
    func perform() async throws -> some IntentResult & OpensIntent{
        let url = URL(string: "buddguard://sos")!
        return .result(opensIntent: OpenURLIntent(url))
    }
}
