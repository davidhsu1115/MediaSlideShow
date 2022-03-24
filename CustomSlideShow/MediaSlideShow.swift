//
//  MediaSlideShow.swift
//  CustomSlideShow
//
//  Created by Mtaxi on 2022/3/17.
//

import Foundation
import UIKit
import Schedule
import SDWebImage

@objc protocol MediaSlideShowDelegate: AnyObject {
    /// slideshow item did select
    @objc func slideItemDidSelect(indexPath: Int)
}

class MediaSlideShow: UIView, NibOwnerLoadable {
    
    enum SourceType {
        case media(url: String)
        case mediaFile(path: String)
        case imageLink(url: String)
        case image(image: UIImage)
        case stackMediaUrls(mediaUrl: String, imageUrl: String)
        case stackMediaFile(mediaPath: String, imagePath: String)
    }
    
    /// slideshow data source
    var dataSource: Array<SourceType> = []{
        didSet {
            collectionView.reloadData()
            addPageControl()
        }
    }
    
    /// delegate called on slideshow state changes
    weak var delegate: MediaSlideShowDelegate?
    
    /// Timer interval
    var slideShowInterval = 0.0 {
        didSet{
            slideshowTimer?.invalidate()
            slideshowTimer = nil
            setTimerIfNeeded()
        }
    }
    
    /// Multiple timer interval
    var slideShowMultipleInterval: [Double] = []{
        didSet {
            slideshowTimer?.invalidate()
            slideshowTimer = nil
            setTimerIfNeeded()
        }
    }
    
    /// Slide timer
    private var slideshowTimer: Timer?

    lazy var collectionView: UICollectionView = {
        let layout = generateLayout()
        let cv = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.delegate = self
        cv.dataSource = self
        cv.register(UINib(nibName: "ImageCollectionCell", bundle: nil), forCellWithReuseIdentifier: "ImageCollectionCell")
        cv.register(UINib(nibName: "MediaCollectionCell", bundle: nil), forCellWithReuseIdentifier: "MediaCollectionCell")
        cv.register(UINib(nibName: "StackMediaCollectionCell", bundle: nil), forCellWithReuseIdentifier: "StackMediaCollectionCell")
        cv.alwaysBounceVertical = false
        cv.backgroundColor = .clear
        return cv
    }()

    /// Default UIPageControl
    let pageControl = UIPageControl()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        customInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        customInit()
    }
    
    override class func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
    }
    
    private func customInit() {
        
        addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(0)
            make.trailing.equalToSuperview().inset(0)
            make.top.equalToSuperview().inset(0)
            make.bottom.equalToSuperview().inset(0)
        }
        self.backgroundColor = .clear
        setTimerIfNeeded()
    }
    
    
    override class func awakeFromNib() {
        super.awakeFromNib()
    }
    
    
    private func addPageControl() {

        pageControl.translatesAutoresizingMaskIntoConstraints = false
        pageControl.layer.zPosition = 1
        pageControl.numberOfPages = dataSource.count
        pageControl.pageIndicatorTintColor = .gray
        pageControl.currentPageIndicatorTintColor = .orange
        addSubview(pageControl)
        pageControl.snp.makeConstraints { make in
            make.bottom.equalToSuperview().inset(16)
            make.centerX.equalToSuperview()
        }
        pageControl.addTarget(self, action: #selector(changePage(_:)), for: .valueChanged)
    }
    
    @objc private func changePage(_ sender: UIPageControl) {
        collectionView.scrollToItem(at: IndexPath(item: sender.currentPage, section: 0), at: .left, animated: true)
        restartMultupleTimer(index: sender.currentPage)
    }
    
    private func pageScroll(){
        if self.pageControl.currentPage == self.pageControl.numberOfPages - 1 {
            self.pageControl.currentPage = 0
        }else{
            self.pageControl.currentPage += 1
        }
        self.collectionView.scrollToItem(at: IndexPath(item: self.pageControl.currentPage, section: 0), at: .left, animated: true)
        restartMultupleTimer(index: pageControl.currentPage)
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        if newSuperview == nil {
            terminateTimer()
        }
    }
    
    override func removeFromSuperview() {
        super.removeFromSuperview()
        terminateTimer()
    }
    
    
}

extension MediaSlideShow {
    
    private func generateLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .paging
        section.visibleItemsInvalidationHandler = { [weak self] visibleItems, point, environment in
            
            if (point.x / (self?.collectionView.bounds.width ?? 0)) != round(point.x / (self?.collectionView.bounds.width ?? 0)) {
                self?.restartTimer()
            }
            
            self?.playFirstVisibleVideo()
            if let page = Int(exactly: CGFloat(point.x / (self?.collectionView.bounds.width ?? 0))){
                self?.pageControl.currentPage = page
                self?.restartMultupleTimer(index: page)
            }
        }
        return UICollectionViewCompositionalLayout(section: section)
    }
    
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
            let firstVisibleCell = mediaCells.first(where: { checkVideoFrameVisible(of: $0) })
            
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
        
        let stackMediaCells = cells.compactMap({ $0 as? StackMediaCollectionCell })
        if stackMediaCells.count > 0 {
            // 3. check if cell is fully visible
            let firstVisibleCell = stackMediaCells.first(where: { checkStackVideoFrameVisible(of: $0) })
            
            // 4. Loop cell for variable shouldPlay and pause rest of videos
            for mediaCell in stackMediaCells {
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
    func checkVideoFrameVisible(of cell: MediaCollectionCell) -> Bool {
        var cellRect = cell.playerView.bounds
        cellRect = cell.playerView.convert(cell.playerView.bounds, to: collectionView.superview)
        return collectionView.frame.contains(cellRect)
    }
    
    /// Check video frame visiblility
    func checkStackVideoFrameVisible(of cell: StackMediaCollectionCell) -> Bool {
        var cellRect = cell.playerView.bounds
        cellRect = cell.playerView.convert(cell.playerView.bounds, to: collectionView.superview)
        return collectionView.frame.contains(cellRect)
    }
    
    
}

extension MediaSlideShow: UICollectionViewDelegate, UICollectionViewDataSource, MediaCellDelegate, StackMediaDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.slideItemDidSelect(indexPath: indexPath.item)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let data = dataSource[indexPath.item]
        switch data {
        case .media(let url):
            return mediaCellGenerator(indexPath: indexPath, url: url)
        case .imageLink(let url):
            return photoCellGenerator(indexPath: indexPath, image: nil, imageUrl: url)
        case .image(let image):
            return photoCellGenerator(indexPath: indexPath, image: image, imageUrl: "")
        case .mediaFile(let path):
            return mediaCellGenerator(indexPath: indexPath, filePath: path)
        case .stackMediaUrls(let mediaUrl, let imageUrl):
            return stackMediaCellGenerator(indexPath: indexPath, mediaUrl: mediaUrl, imageUrl: imageUrl)
        case .stackMediaFile(let mediaPath, let imagePath):
            return stackMediaCellGenerator(indexPath: indexPath, mediaPath: mediaPath, imagePath: imagePath)
        }
        
    }
    
    
    private func photoCellGenerator(indexPath: IndexPath, image: UIImage? = nil, imageUrl: String) -> UICollectionViewCell{
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCollectionCell", for: indexPath) as! ImageCollectionCell
        
        if image != nil {
            cell.imageView.image = image
        }else{
            cell.imageView.sd_setImage(with: URL(string: imageUrl), completed: nil)
        }
        
        return cell
    }
    
    private func mediaCellGenerator(indexPath: IndexPath, url: String) -> UICollectionViewCell{
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MediaCollectionCell", for: indexPath) as! MediaCollectionCell
        cell.configure(url.urlEncoded())
        cell.delegate = self
        return cell
    }
    
    private func mediaCellGenerator(indexPath: IndexPath, filePath: String) -> UICollectionViewCell{
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MediaCollectionCell", for: indexPath) as! MediaCollectionCell
        cell.file(filePath)
        cell.delegate = self
        return cell
    }
    
    private func stackMediaCellGenerator(indexPath: IndexPath, mediaUrl: String, imageUrl: String) -> UICollectionViewCell{
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "StackMediaCollectionCell", for: indexPath) as! StackMediaCollectionCell
        cell.configure(mediaUrl.urlEncoded(), imageUrl: imageUrl.urlEncoded())
        cell.delegate = self
        return cell
    }
    
    private func stackMediaCellGenerator(indexPath: IndexPath, mediaPath: String, imagePath: String) -> UICollectionViewCell{
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "StackMediaCollectionCell", for: indexPath) as! StackMediaCollectionCell
        cell.file(mediaPath, imageFilePath: imagePath)
        cell.delegate = self
        return cell
    }
    
    func videoIsPlaying(isPlaying: Bool) {
        guard slideShowMultipleInterval.count == 0 else { return }
        if isPlaying {
            terminateTimer()
        }else{
            restartTimer()
        }
    }
    
    func videoDidEnd() {
        guard slideShowMultipleInterval.count == 0 else { return }
        pageScroll()
        restartTimer()
    }
    
}

// Timer
extension MediaSlideShow {
    private func setTimerIfNeeded(){
        if slideShowInterval > 0 && dataSource.count > 1 && slideshowTimer == nil {
            slideshowTimer = Timer.scheduledTimer(timeInterval: slideShowInterval, target: self, selector: #selector(MediaSlideShow.slideTick(_:)), userInfo: nil, repeats: true)
        }
    }
    
    @objc func slideTick(_ timer: Timer){
        pageScroll()
    }
    
    private func restartTimer(){
        if slideshowTimer?.isValid != nil {
            slideshowTimer?.invalidate()
            slideshowTimer = nil
        }
        
        setTimerIfNeeded()
    }
    
    private func restartMultupleTimer(index: Int){
        guard slideShowMultipleInterval.count != 0 else { return }
        if slideshowTimer?.isValid != nil {
            slideshowTimer?.invalidate()
            slideshowTimer = nil
        }
        slideshowTimer = Timer.scheduledTimer(timeInterval: slideShowMultipleInterval[index], target: self, selector: #selector(MediaSlideShow.slideTick(_:)), userInfo: nil, repeats: true)
        
    }
    
    private func terminateTimer(){
        slideshowTimer?.invalidate()
        slideshowTimer = nil
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

