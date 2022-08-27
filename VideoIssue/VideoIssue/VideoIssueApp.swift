//
//  VideoIssueApp.swift
//  VideoIssue
//
//

import SwiftUI

@main
struct VideoIssueApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(videoViewModel: VideoViewModel())
        }
    }
}
