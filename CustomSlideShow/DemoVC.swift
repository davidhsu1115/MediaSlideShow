//
//  DemoVC.swift
//  CustomSlideShow
//
//  Created by Mtaxi on 2022/3/17.
//

import UIKit
import AVFoundation

class DemoVC: UIViewController {
    
    @IBOutlet weak var slideShowView: MediaSlideShow!
    private var testFilePath = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        FileDownloader.loadFileAsync(url: URL(string: "https://www.mtaxi.com.tw/wp-content/uploads/2022/03/寵物專車15秒2-1.mp4".urlEncoded())!) { path, error in
            print("\(path)")
            UserDefaults.standard.set(path, forKey: "AAA")
            UserDefaults.standard.synchronize()
            self.testFilePath = path!
            let a = AVAsset(url: URL(fileURLWithPath: path!))
            print(a.duration)
        }
        
        let source: Array<MediaSlideShow.SourceType> = [.stackMediaUrls(mediaUrl: "https://oneapi.hostar.com.tw/oneLoginAdAndHelp/pic/Ice.MP4", imageUrl: "https://oneapi.hostar.com.tw/oneLoginAdAndHelp/pic/jer.gif"),
                                                        .stackMediaUrls(mediaUrl: "https://oneapi.hostar.com.tw/oneLoginAdAndHelp/pic/Ice2.mp4", imageUrl: "https://oneapi.hostar.com.tw/oneLoginAdAndHelp/pic/jer.gif"),
                                                        .imageLink(url: "https://oneapi.hostar.com.tw/oneLoginAdAndHelp/pic/jer.gif"),
                                                        .mediaFile(path: UserDefaults.standard.string(forKey: "AAA")!),
                                                        .image(image: UIImage(named: "bbb")!),
                                                        .media(url: "https://www.mtaxi.com.tw/wp-content/uploads/2022/03/寵物專車15秒2-1.mp4")
        ]
        slideShowView.delegate = self
        slideShowView.dataSource = source
        slideShowView.slideShowInterval = 5
        self.view.backgroundColor = .black
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        slideShowView.playFirstVisibleVideo()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        slideShowView.playFirstVisibleVideo(false)
    }
    
    
}

extension DemoVC: MediaSlideShowDelegate {
    func slideItemDidSelect(indexPath: Int) {
        print(indexPath)
    }
}
