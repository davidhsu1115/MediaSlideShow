//
//  ViewController.swift
//  CustomSlideShow
//
//  Created by Mtaxi on 2022/3/16.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UINib(nibName: "ImageCollectionCell", bundle: nil), forCellWithReuseIdentifier: "ImageCollectionCell")
        collectionView.register(UINib(nibName: "MediaCollectionCell", bundle: nil), forCellWithReuseIdentifier: "MediaCollectionCell")
        collectionView.collectionViewLayout = generateLayout()
        collectionView.alwaysBounceVertical = false
        collectionView.backgroundColor = .black
        view.backgroundColor = .black.withAlphaComponent(0.5)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        playFirstVisibleVideo()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        playFirstVisibleVideo(false)
    }
    
    func generateLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .paging
        section.visibleItemsInvalidationHandler = { [weak self] visibleItems, point, environment in
            self?.playFirstVisibleVideo()
        }
        return UICollectionViewCompositionalLayout(section: section)
    }
    
    
}

extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource{
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 4
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        if indexPath.item % 2 == 0 {
            return photoCellGenerator(indexPath: indexPath)
        }else{
            return mediaCellGenerator(indexPath: indexPath)
        }
        
    }
    
    private func photoCellGenerator(indexPath: IndexPath) -> UICollectionViewCell{
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCollectionCell", for: indexPath) as! ImageCollectionCell
        cell.imageView.image = UIImage(named: "bbb")
        return cell
    }
    
    private func mediaCellGenerator(indexPath: IndexPath) -> UICollectionViewCell{
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MediaCollectionCell", for: indexPath) as! MediaCollectionCell
        cell.configure("https://www.mtaxi.com.tw/wp-content/uploads/2022/03/寵物專車15秒2-1.mp4".urlEncoded())
        return cell
    }
    
    
    
    
}

extension ViewController {
    
    /// play first visible video
    func playFirstVisibleVideo(_ shouldPlay: Bool = true){
        
        // 1. sort visible cell
        let cells = collectionView.visibleCells.sorted{
            collectionView.indexPath(for: $0)?.item ?? 0 < collectionView.indexPath(for: $1)?.item ?? 0
        }
        
        // 2. map cell as media collection cell
        let mediaCells = cells.compactMap({ $0 as? MediaCollectionCell })
        
        if mediaCells.count > 0 {
            // 3. check if cell is fully visible
            let firstVisibleCell = mediaCells.first(where: { checkVideoFrameVisibility(of: $0) })
            
            // 4. Loop cell for variable shouldPlay and pause rest of videos
            for mediaCell in mediaCells {
                if shouldPlay && firstVisibleCell == mediaCell {
                    mediaCell.play()
                }else{
                    mediaCell.pause()
                    mediaCell.mute()
                }
            }
        }
        
    }
    
    
    /// Check video frame visiblility
    func checkVideoFrameVisibility(of cell: MediaCollectionCell) -> Bool {
        var cellRect = cell.playerView.bounds
        cellRect = cell.playerView.convert(cell.playerView.bounds, to: collectionView.superview)
        return collectionView.frame.contains(cellRect)
    }
    
}


extension String {
     
    //将原始的url编码为合法的url
    func urlEncoded() -> String {
        let encodeUrlString = self.addingPercentEncoding(withAllowedCharacters:
            .urlQueryAllowed)
        return encodeUrlString ?? ""
    }
     
    //将编码后的url转换回原始的url
    func urlDecoded() -> String {
        return self.removingPercentEncoding ?? ""
    }
}
