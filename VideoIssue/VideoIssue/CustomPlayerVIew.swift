//
//  CustomPlayerView.swift
//  Grow
//

import Foundation
import UIKit
import SwiftUI
import AVKit
import AVFoundation

struct CustomPlayerView: UIViewRepresentable {
    
    let playerLayer: AVPlayerLayer
    
    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<CustomPlayerView>) {
    }
    
    func makeUIView(context: Context) -> UIView {
        let customPlayerUIView = CustomPlayerUIView(frame: .zero)
        customPlayerUIView.initPlayer(playerLayer: playerLayer)
        return customPlayerUIView
    }
}


class CustomPlayerUIView: UIView {
    private var playerLayer: AVPlayerLayer?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    func initPlayer(playerLayer: AVPlayerLayer) {
        self.playerLayer = playerLayer
        layer.addSublayer(playerLayer)
        playerLayer.player?.play()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
}
