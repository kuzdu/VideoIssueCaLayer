//
//  VideoHelper.swift
//  VideoIssue
//

import Foundation
import SwiftUI
import AVFoundation
import AVKit


enum ConstructionError: Error {
    case invalidImage
    case invalidURL
    case invalidVideoTrack
}


class VideoHelper {
    
    private let duration = 3
    
    static let shared = VideoHelper()
    
    func createVideo() async throws -> AVPlayerLayer {
        var urls: [URL] = []
        let imageNames = ["1", "2","3","4","5"]
        let images = imageNames.map { UIImage(named: $0) }
 
        // this takes a while
        for i in 0...4 {
            let savedUrl = try! await convertImageToAThreeSecondsVideo(image: images[i]!, imageName: imageNames[i])
            urls.append(savedUrl)
        }
        
        let playerItem = try createOneVideoWithTransitions(from: urls)

        
        let synchronizedLayer = AVSynchronizedLayer(playerItem: playerItem)
        synchronizedLayer.frame = CGRect(x: 0, y: 0, width: 500, height: 500)
        synchronizedLayer.opacity = 1.0
        synchronizedLayer.beginTime = 0
        synchronizedLayer.backgroundColor = UIColor.yellow.cgColor
        
        let textlayer = CATextLayer()
        textlayer.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        textlayer.fontSize = 20
        let myAttributes = [
            NSAttributedString.Key.font: UIFont(name: "Chalkduster", size: 30.0)! , // font
            NSAttributedString.Key.foregroundColor: UIColor.cyan,                   // text color
            
        ]
        let myAttributedString = NSAttributedString(string: "My text", attributes: myAttributes )
        
        textlayer.alignmentMode = .center
        textlayer.string = myAttributedString
        textlayer.backgroundColor = UIColor.brown.cgColor
        textlayer.isWrapped = true
        textlayer.beginTime = 0.0
        textlayer.opacity = 1.0
        textlayer.truncationMode = .end
        textlayer.allowsFontSubpixelQuantization = true
        
        synchronizedLayer.addSublayer(textlayer)
        synchronizedLayer.setNeedsDisplay()
        
        let player = AVPlayer(playerItem: playerItem)
        let playerLayer = AVPlayerLayer(player: player)
        
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.player?.volume = 1
        playerLayer.player?.isMuted = false
        
        
        playerLayer.frame = await CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        
        playerLayer.addSublayer(synchronizedLayer)

        playerLayer.layoutIfNeeded()
        playerLayer.setNeedsDisplay()
        playerLayer.display()
        synchronizedLayer.layoutIfNeeded()
        synchronizedLayer.layoutIfNeeded()
        synchronizedLayer.setNeedsDisplay()
        synchronizedLayer.display()
        
        return playerLayer
    }
    

    private func convertImageToAThreeSecondsVideo(image: UIImage, imageName: String) async throws -> URL {
        
        return try await withCheckedThrowingContinuation { continuation in
            //create a CIImage
            guard let staticImage = CIImage(image: image) else {
                continuation.resume(throwing: ConstructionError.invalidImage)
                return
            }
            
            //create a variable to hold the pixelBuffer
            var pixelBuffer: CVPixelBuffer?
            
            //set some standard attributes
            let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                 kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
            
            //create the width and height of the buffer to match the image
            let width:Int = Int(staticImage.extent.size.width)
            let height:Int = Int(staticImage.extent.size.height)
            
            //create a buffer (notice it uses an in/out parameter for the pixelBuffer variable)
            CVPixelBufferCreate(kCFAllocatorDefault,
                                width,
                                height,
                                kCVPixelFormatType_32BGRA,
                                attrs,
                                &pixelBuffer)
            
            //create a CIContext
            let context = CIContext()
            //use the context to render the image into the pixelBuffer
            context.render(staticImage, to: pixelBuffer!)
            
            //generate a file url to store the video. some_image.jpg becomes some_image.mov
            guard let imageNameRoot = imageName.split(separator: ".").first,
                  let outputMovieURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("\(imageNameRoot).mov") else {
                continuation.resume(throwing: ConstructionError.invalidURL)
                return
            }
            
            //delete any old file
            do {
                try FileManager.default.removeItem(at: outputMovieURL)
            } catch {
                print("Could not remove file \(error.localizedDescription)")
            }
            
            //create an assetwriter instance
            guard let assetwriter = try? AVAssetWriter(outputURL: outputMovieURL, fileType: .mov) else {
                abort()
            }
            
            //generate 1080p settings
            let settingsAssistant = AVOutputSettingsAssistant(preset: .preset1920x1080)?.videoSettings
            
            //create a single video input
            let assetWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: settingsAssistant)
            
            //create an adaptor for the pixel buffer
            let assetWriterAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: assetWriterInput, sourcePixelBufferAttributes: nil)
            
            //add the input to the asset writer
            assetwriter.add(assetWriterInput)
            //begin the session
            assetwriter.startWriting()
            assetwriter.startSession(atSourceTime: CMTime.zero)
            //determine how many frames we need to generate
            let framesPerSecond = 30
            //duration is the number of seconds for the final video
            
            let totalFrames = duration * framesPerSecond
            var frameCount = 0
            while frameCount < totalFrames {
                if assetWriterInput.isReadyForMoreMediaData {
                    let frameTime = CMTimeMake(value: Int64(frameCount), timescale: Int32(framesPerSecond))
                    //append the contents of the pixelBuffer at the correct time
                    assetWriterAdaptor.append(pixelBuffer!, withPresentationTime: frameTime)
                    frameCount+=1
                }
            }
            
            //close everything
            assetWriterInput.markAsFinished()
            assetwriter.finishWriting {
                pixelBuffer = nil
                //outputMovieURL now has the video
                continuation.resume(returning: outputMovieURL)
                //print("Finished video location: \(outputMovieURL)")
            }
        }
    }
    
    
    private func createOneVideoWithTransitions(from urls: [URL]) throws -> AVPlayerItem {
        
        let mixComposition = AVMutableComposition()
        var instructions = [AVMutableVideoCompositionLayerInstruction]()
        let assets = urls.map { AVAsset(url: $0) }
        
        
        var naturalSize: CGSize = .zero
        for (index, asset) in assets.enumerated() {
            
        
            // create track
            guard let videoTrack = mixComposition.addMutableTrack(withMediaType: .video, preferredTrackID: Int32(kCMPersistentTrackID_Invalid)), let _ = mixComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: Int32(kCMPersistentTrackID_Invalid)) else {
                throw ConstructionError.invalidVideoTrack
            }

          
            let timeRange = CMTimeRangeMake(start: CMTime.zero, duration: asset.duration)
            var startTime = CMTime.zero
            
            if index != 0 {
                startTime = CMTime(seconds: Double(index + index - 1), preferredTimescale: 60)
            }
            
            
            do {
                try videoTrack.insertTimeRange(timeRange, of: asset.tracks(withMediaType: .video)[0], at: startTime)
                print("Videotrack start time \(startTime.seconds)")
            } catch {
                print(error)
            }
            
            naturalSize = videoTrack.naturalSize
           // print("Natural size \(naturalSize)")
            
            // Setup Layer Instruction 1
            let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
           
        
            let insertTime = CMTime(seconds:  Double(index + index + 1), preferredTimescale: 60)
  
                
            print("Insert times animation \(insertTime.seconds)")
            let duration = CMTime(seconds: 1, preferredTimescale: 60)
            layerInstruction.setOpacityRamp(
                fromStartOpacity: 1.0,
                toEndOpacity: 0.0,
                timeRange: CMTimeRangeMake(start: insertTime, duration: duration)
            )
            
            instructions.append(layerInstruction)
        }
        
        // Setup Video Composition
        let mainInstruction = AVMutableVideoCompositionInstruction()
        
        let arrayOfSeconds = assets.map { $0.duration.seconds }

        let timeOfTheWholeInstruction = arrayOfSeconds.reduce(0,+)
        mainInstruction.timeRange = CMTimeRangeMake(start: .zero, duration: CMTime(seconds: timeOfTheWholeInstruction, preferredTimescale: 60))
        mainInstruction.layerInstructions = instructions

        let mainComposition = AVMutableVideoComposition()
        mainComposition.instructions = [mainInstruction]
        mainComposition.frameDuration = CMTimeMake(value: 1, timescale: 60)
        mainComposition.renderSize = naturalSize

        let item = AVPlayerItem(asset: mixComposition)
        item.videoComposition = mainComposition
        
        
        return item
    }
    
}
