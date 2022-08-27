//
//  ContentView.swift
//  VideoIssue
//

import SwiftUI

struct ContentView: View {
    @StateObject var videoViewModel: VideoViewModel
    
    var body: some View {
        if videoViewModel.state == .loading {
            Text("Loading")
        } else if videoViewModel.state == .finished {
            if let playerLayer = videoViewModel.avPlayerLayer {
                CustomPlayerView(playerLayer: playerLayer)
                    .edgesIgnoringSafeArea(.all)
            } else {
                Text("Failed: No avPlayerLayer found")
            }
        } else  {
            if videoViewModel.state == .error {
                Text("An error occured")
            }
            Button("Generate Video") {
                videoViewModel.generateVideo()
            }
        }
    }
}

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}
