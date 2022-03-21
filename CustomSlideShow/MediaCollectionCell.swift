//
//  MediaCollectionCell.swift
//  CustomSlideShow
//
//  Created by Mtaxi on 2022/3/16.
//

import UIKit
import AVFoundation
import SnapKit

protocol MediaCellDelegate: AnyObject {
    
    func videoIsPlaying(isPlaying: Bool)
    
    func videoDidEnd()
    
}

class MediaCollectionCell: UICollectionViewCell {
    
    let playerView = PlayerView()
    
    private let muteButton = UIButton()
    
    var url: URL?
    
    weak var delegate: MediaCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    private func setupUI(){
        self.backgroundColor = .clear
        self.addSubview(playerView)
        playerView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
        
        muteButton.setTitleColor(.white, for: .normal)
        
        muteButton.setImage(UIImage(named: "audio_off")?.withRenderingMode(.alwaysTemplate), for: .normal)
        muteButton.tintColor = .white
        playerView.addSubview(muteButton)
        muteButton.snp.makeConstraints { make in
            make.top.equalTo(playerView.snp.top).inset(32)
            make.leading.equalTo(playerView.snp.leading).inset(16)
        }
        playerView.delegate = self
        
        muteButton.addTarget(self, action: #selector(muteToggle), for: .touchUpInside)
        
    }
    
    /// Play
    func play(){
        if let url = url {
            playerView.prepareToPlay(with: url, shouldPlayImmediately: true)
        }
    }
    
    /// Pause
    func pause(){
        playerView.pause()
    }
    
    /// mute toggle
    @objc func muteToggle(){
        playerView.muteToggle()
        if muteButton.imageView?.image == UIImage(named: "audio_off") {
            muteButton.setImage(UIImage(named: "audio")?.withRenderingMode(.alwaysTemplate), for: .normal)
        }else{
            muteButton.setImage(UIImage(named: "audio_off")?.withRenderingMode(.alwaysTemplate), for: .normal)
        }
    }
    
    /// mute
    func mute(){
        playerView.mute()
        muteButton.setImage(UIImage(named: "audio_off")?.withRenderingMode(.alwaysTemplate), for: .normal)
    }
    
    /// configure
    func configure(_ videoUrl: String){
        guard let url = URL(string: videoUrl) else { return }
        self.url = url
        playerView.prepareToPlay(with: url, shouldPlayImmediately: true)
    }
    
    /// configure filepath
    func file(_ filePath: String?){
        guard let path = filePath else { return }
        let finalPath = URL(fileURLWithPath: path)
        self.url = finalPath
        playerView.prepareToPlay(filePath: finalPath, shouldPlayImmediately: true)
    }
    
}

extension MediaCollectionCell: PlayerDelegate {
    
    func videoIsPlaying(isPlaying: Bool) {
        delegate?.videoIsPlaying(isPlaying: isPlaying)
    }
    
    func videoDidEnd() {
        delegate?.videoDidEnd()
    }
    
    
}


