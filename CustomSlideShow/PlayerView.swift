//
//  PlayerView.swift
//  CustomSlideShow
//
//  Created by Mtaxi on 2022/3/17.
//

import Foundation
import UIKit
import AVFoundation

protocol PlayerDelegate: AnyObject {
    
    /// video is playing
    func videoIsPlaying(isPlaying: Bool)
    
    /// video remaining time
    func videoRemainingTimedidUpdate(second: Int)
    
    /// video did end
    func videoDidEnd()
    
}

class PlayerView: UIView {
    
    /// Video loop
    var videoLoop = false
    
    /// player delegate
    weak var delegate: PlayerDelegate?
    
    /// Video rect
    private(set) var videoRect = CGRect()
    
    /// Url
    private var url: URL?
    
    /// value key
    private let valueKey = "tracks"
    
    /// asset url
    private var urlAsset: AVURLAsset?
    
    /// player item
    private var playerItem: AVPlayerItem?
    
    /// timeObsToken
    private var timeObserverToken: Any?
    
    /// asset player
    private(set) var assetPlayer: AVPlayer?
    
    override class var layerClass: AnyClass{
        return AVPlayerLayer.self
    }
    
    init() {
        super.init(frame: .zero)
        initialSetup()
    }
    
    required init?(coder: NSCoder) {
        super.init(frame: .zero)
        initialSetup()
    }
    
    private func initialSetup(){
        
        if let layer = self.layer as? AVPlayerLayer {
            // initial video setup here
            layer.videoGravity = .resizeAspect
        }
    }
    
    /// Prepare to play
    func prepareToPlay(with url: URL, shouldPlayImmediately: Bool = false){
        
        guard !(self.url == url && assetPlayer != nil && assetPlayer?.error == nil) else{
            if shouldPlayImmediately {
                play()
            }
            return
        }
        
        cleanUp()
        
        self.url = url
        
        // 1. load the video from url
        let options = [AVURLAssetPreferPreciseDurationAndTimingKey: true]
        let urlAsset = AVURLAsset(url: url, options: options)
        self.urlAsset = urlAsset
        
        // 2. load video tracks aysnchronously
        let keys = [valueKey]
        urlAsset.loadValuesAsynchronously(forKeys: keys) { [weak self] in
            print("Assets loaded")
            self?.startLoading(urlAsset, shouldPlayImmediately)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.playerItemDidReachEnd), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
    }
    
    /// Prepare to play
    func prepareToPlay(filePath path: URL, shouldPlayImmediately: Bool = false){
        
        guard !(self.url == url && assetPlayer != nil && assetPlayer?.error == nil) else{
            if shouldPlayImmediately {
                play()
            }
            return
        }
        
        cleanUp()
        
        self.url = path
        
        let asset = AVAsset(url: path)
        
        startLoading(asset, true)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.playerItemDidReachEnd), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
    }
    
    /// Play
    func play(){
        guard assetPlayer?.isPlaying == false else { return }
        DispatchQueue.main.async {
            self.assetPlayer?.play()
            self.delegate?.videoIsPlaying(isPlaying: true)
        }
    }
    
    /// Pause
    func pause(){
        guard assetPlayer?.isPlaying == true else { return }
        DispatchQueue.main.async {
            self.assetPlayer?.pause()
            self.delegate?.videoIsPlaying(isPlaying: false)
        }
    }
    
    /// Mute toggle
    func muteToggle(){
        guard let player = self.assetPlayer else { return }
        DispatchQueue.main.async {
            player.isMuted = !player.isMuted
        }
    }
    
    func mute(){
        guard let player = self.assetPlayer else { return }
        DispatchQueue.main.async {
            player.isMuted = true
        }
    }
    
    /// clean asset and cancel loading
    func cleanUp(){
        pause()
        urlAsset?.cancelLoading()
        urlAsset = nil
        assetPlayer = nil
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        if let timeObserverToken = timeObserverToken {
            assetPlayer?.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }
    }
    
    
    deinit {
        cleanUp()
    }
    
    
}

extension PlayerView {
    
    @objc private func playerItemDidReachEnd(_ notification: Notification) {
         guard notification.object as? AVPlayerItem == self.playerItem else { return }
         DispatchQueue.main.async {
             guard let videoPlayer = self.assetPlayer else { return }
             videoPlayer.seek(to: .zero)
             
             if self.videoLoop {
                 videoPlayer.play()
                 print("videoEnd")
             }else{
                 // Delegate notify video ends
                 self.delegate?.videoDidEnd()
             }
             
         }
     }
        
    /// Start loading
    private func startLoading(_ asset: AVURLAsset, _ shouldPlayImmdiately: Bool) {
        // get status for the track
        var error: NSError?
        let status: AVKeyValueStatus = asset.statusOfValue(forKey: valueKey, error: &error)
        
        switch status {
        case .unknown:
            print("asset unknown")
        case .loading:
            print("Asset loading")
        case .loaded:
            let item = AVPlayerItem(asset: asset)
            self.playerItem = item
            
            let player = AVPlayer(playerItem: item)
            self.assetPlayer = player
            
            DispatchQueue.main.async {
                if let layer = self.layer as? AVPlayerLayer {
                    layer.player = self.assetPlayer
                }
            }
            
            if shouldPlayImmdiately {
                self.addPeriodicTimeObs()
                DispatchQueue.main.async {
                    player.play()
                    player.isMuted = true
                    
                    self.delegate?.videoIsPlaying(isPlaying: true)
                }
            }
            
        case .failed:
            print(String(describing: error))
        case .cancelled:
            print("asset loading canceled")
        @unknown default:
            print("Asset Error - \(#function)")
        }
        
    }
    
    /// Start loading
    private func startLoading(_ asset: AVAsset, _ shouldPlayImmdiately: Bool) {
        // get status for the track
        var error: NSError?
        let status: AVKeyValueStatus = asset.statusOfValue(forKey: valueKey, error: &error)
        
        switch status {
        case .unknown:
            print("asset unknown")
        case .loading:
            print("Asset loading")
        case .loaded:
            let item = AVPlayerItem(asset: asset)
            self.playerItem = item
            
            let player = AVPlayer(playerItem: item)
            self.assetPlayer = player
            
            if shouldPlayImmdiately {
                DispatchQueue.main.async {
                    player.play()
                    player.isMuted = true
                    
                    self.delegate?.videoIsPlaying(isPlaying: true)
                }
            }
            
        case .failed:
            print(String(describing: error))
        case .cancelled:
            print("asset loading canceled")
        @unknown default:
            print("Asset Error - \(#function)")
        }
        
    }
    
    private func addPeriodicTimeObs(){
        let timeScale = CMTimeScale(NSEC_PER_SEC)
        let time = CMTime(seconds: 0.5, preferredTimescale: timeScale)
        timeObserverToken = assetPlayer?.addPeriodicTimeObserver(forInterval: time, queue: .main, using: { [weak self] time in
            let interval = Int((self?.assetPlayer?.currentItem?.asset.duration.seconds ?? 0) - time.seconds)
            self?.delegate?.videoRemainingTimedidUpdate(second: interval)
        })
        
    }
    
    
}

extension AVPlayer {
    
    var isPlaying: Bool {
        get {
            return (self.rate != 0 && self.error == nil)
        }
    }
    
}
