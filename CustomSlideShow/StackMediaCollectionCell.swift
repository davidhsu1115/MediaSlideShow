//
//  StackMediaCollectionCell.swift
//  CustomSlideShow
//
//  Created by Mtaxi on 2022/3/22.
//

import UIKit
import SDWebImage

protocol StackMediaDelegate: AnyObject{
    
    func videoIsPlaying(isPlaying: Bool)
    
    func videoDidEnd()
    
}

class StackMediaCollectionCell: UICollectionViewCell {
    
    /// avplayer
    let playerView = PlayerView()
    
    /// image view
    let imageView = SDAnimatedImageView()
    
    /// remain time label
    let remainTimeLabel = UILabel()
    
    /// mute button
    private let muteButton = UIButton()
    
    /// Url
    var url: URL?
    
    /// image URL
    var imageUrl: URL?
    
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
        self.addSubview(muteButton)
        self.addSubview(playerView)
        self.addSubview(imageView)
        self.addSubview(remainTimeLabel)
        
        muteButton.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.equalToSuperview().inset(16)
        }
        
        muteButton.setTitleColor(.white, for: .normal)
        muteButton.setImage(audioOffImage, for: .normal)
        muteButton.tintColor = .white
        
        remainTimeLabel.snp.makeConstraints { make in
            make.centerY.equalTo(muteButton.snp.centerY)
            make.leading.equalTo(muteButton.snp.trailing).offset(16)
        }
        
        remainTimeLabel.textColor = .white
        remainTimeLabel.font = .boldSystemFont(ofSize: 14)
        
        playerView.snp.makeConstraints { make in
            make.top.equalTo(muteButton.snp.bottom).inset(4)
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.height.equalToSuperview().dividedBy(2.5)
        }
        
        imageView.snp.makeConstraints { make in
            make.top.equalTo(playerView.snp.bottom)
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        imageView.contentMode = .scaleAspectFit
        
        
        
        
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
    func configure(_ videoUrl: String, imageUrl: String){
        guard let url = URL(string: videoUrl) else { return }
        guard let image = URL(string: imageUrl) else { return }
        self.url = url
        self.imageUrl = image
        imageView.sd_setImage(with: image, completed: nil)
        playerView.prepareToPlay(with: url, shouldPlayImmediately: true)
    }
    
    /// configure filepath
    func file(_ videoFilePath: String?, imageFilePath: String?){
        guard let path = videoFilePath else { return }
        guard let image = imageFilePath else { return }
        let finalPath = URL(fileURLWithPath: path)
        let finalImagePath = URL(fileURLWithPath: image)
        self.url = finalPath
        self.imageUrl = finalImagePath
        imageView.sd_setImage(with: finalImagePath, completed: nil)
        playerView.prepareToPlay(filePath: finalPath, shouldPlayImmediately: true)
    }
    
}


extension StackMediaCollectionCell: PlayerDelegate {
    
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

