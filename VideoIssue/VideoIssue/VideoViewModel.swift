//
//  VideoViewModel.swift
//  VideoIssue
//


import Foundation
import SwiftUI
import AVFoundation
import AVKit


enum VideoState {
    case actionRequired
    case loading
    case error
    case finished
}

class VideoViewModel: ObservableObject {

    
    @Published var state: VideoState = .actionRequired
    
    private (set) var avPlayerLayer: AVPlayerLayer?
   
    func generateVideo() {
        state = .loading
        Task {
            do {
                let generatedAvPlayerLayer = try await VideoHelper.shared.createVideo()
                self.avPlayerLayer = generatedAvPlayerLayer
                
                DispatchQueue.main.async {
                    self.state = .finished
                }
            } catch {
                print("Error \(error)")
//                state = .error
//                videoExportState = .none
            }
        }
    }
    
    
}
