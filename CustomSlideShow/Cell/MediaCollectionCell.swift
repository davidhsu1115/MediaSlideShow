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
    
    /// avplayer
    let playerView = PlayerView()
    
    /// mute button
    private let muteButton = UIButton()
    
    /// remain time label
    let remainTimeLabel = UILabel()
    
    /// Url
    var url: URL?
    
    /// Media cell delegate
    weak var delegate: MediaCellDelegate?
    
    /// default audio off button image
    var audioOffImage = UIImage(named: "audio_off")?.withRenderingMode(.alwaysTemplate)
    
    /// default audio on button image
    var audioOnImage = UIImage(named: "audio")?.withRenderingMode(.alwaysTemplate)

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
        muteButton.setImage(audioOffImage, for: .normal)
        muteButton.tintColor = .white
        
        playerView.addSubview(muteButton)
        muteButton.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.equalTo(playerView.snp.leading).inset(16)
        }
        
        playerView.addSubview(remainTimeLabel)
        remainTimeLabel.snp.makeConstraints { make in
            make.centerY.equalTo(muteButton.snp.centerY)
            make.leading.equalTo(muteButton.snp.trailing).offset(16)
        }
        remainTimeLabel.textColor = .white
        remainTimeLabel.font = .boldSystemFont(ofSize: 14)
        
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
        
        if muteButton.imageView?.image == audioOffImage {
            muteButton.setImage(audioOnImage, for: .normal)
        }else{
            muteButton.setImage(audioOffImage, for: .normal)
        }
    }
    
    /// mute
    func mute(){
        playerView.mute()
        muteButton.setImage(audioOffImage, for: .normal)
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
    
    func videoRemainingTimedidUpdate(second: Int) {
        remainTimeLabel.text = "\(second)秒"
    }
    
    
}


