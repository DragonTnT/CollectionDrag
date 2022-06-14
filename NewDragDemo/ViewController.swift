//
//  ViewController.swift
//  NewDragDemo
//
//  Created by Allen long on 2022/5/19.
//

import UIKit

class ViewController: UIViewController {

    var subScrollVC: [UIViewController] = [] {
        didSet {
            scrollView.contentSize = CGSize(width: kScreenW * CGFloat(subScrollVC.count), height: kScreenH)
            pageControll.numberOfPages = subScrollVC.count
        }
    }
    let messageVC = MessViewController()
    
    lazy var bottomSubVC = BottomVC(items: DataSourceManager.main.bottomDataSource)
    
    lazy var pageControll: UIPageControl = {
        let it = UIPageControl()
        it.pageIndicatorTintColor = .gray
        it.currentPageIndicatorTintColor = .black
        return it
    }()
    
    lazy var scrollView: UIScrollView = {
        let it = UIScrollView(frame: self.view.bounds)
        it.isPagingEnabled = true
        it.backgroundColor = UIColor.white.withAlphaComponent(0)
        it.showsHorizontalScrollIndicator = false
        it.delegate = self
        return it
    }()
    
    lazy var outsideCell: DragSortCollectionCell = {
        let it = DragSortCollectionCell.loadViewFromNib()
        it.isHidden = true
        it.frame = CGRect(origin: .zero, size: ConstHelper.itemSize)
        it.closeBtn.isHidden = true
        view.addSubview(it)
        return it
    }()
    
    var outsideCellCenterOffset: CGPoint = .zero

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNotifications()
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPressAction(_:)))
        view.addGestureRecognizer(longPress)
        
        let tapGes = UITapGestureRecognizer(target: self, action: #selector(tapAction))
        view.addGestureRecognizer(tapGes)
        
        HomeEditingManager.main.homeVC = self
    }
    
}

extension ViewController: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        setCurrentScrollVCWithOffsetX(scrollView.contentOffset.x)
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        setCurrentScrollVCWithOffsetX(scrollView.contentOffset.x)
    }
}

// MARK: - Helper
extension ViewController {
    private func setupUI() {
        let imgV = UIImageView(image: UIImage(named: "background")!)
        view.addSubview(imgV)
        view.addSubview(scrollView)
        view.addSubview(pageControll)
        imgV.snp.makeConstraints { $0.edges.equalToSuperview() }
        scrollView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        pageControll.snp.makeConstraints {
            $0.height.equalTo(30)
            $0.centerX.equalToSuperview()
            $0.bottom.equalTo(-140)
        }
        
        addMessageVC()
        
        // 添加滑动控制器
        for (index,pageSource) in DataSourceManager.main.scrollDataSource.enumerated() {
            addCollectionVC(dataSourceIndex: index, items: pageSource, isFromStartEditingMode: false)
        }
        
        //添加底部控制器
        addChild(bottomSubVC)
        view.addSubview(bottomSubVC.view)
        bottomSubVC.view.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(120)
        }

        // 默认在第二屏
        setCurrentScrollVCWithOffsetX(kScreenW)
        scrollView.contentOffset = CGPoint(x: kScreenW, y: 0)
        pageControll.currentPage = 1
        pageControll.addTarget(self, action: #selector(pageControllValueChanged(controll:)), for: .valueChanged)
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(homeStartEditingMode), name: .homeStartEditingMode, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(homeEndEditingMode), name: .homeEndEditingMode, object: nil)
    }
    
    private func addMessageVC() {
        subScrollVC.append(messageVC)
        scrollView.addSubview(messageVC.view)
        messageVC.view.frame = view.bounds
    }
    
    /// 添加控制器
    /// - Parameters:
    ///   - dataSourceIndex: Items数据源对应的index
    ///   - items: items数据源
    ///   - isFromStartEditingMode: 方法是否来源于开启编辑模式
    private func addCollectionVC(dataSourceIndex: Int, items: [HomeItem], isFromStartEditingMode: Bool) {
        let vc = CollectionDragSortViewController(dataSourceIndex: dataSourceIndex, items: items)
        subScrollVC.append(vc)
        setScrollVCViewFrameWith(index: dataSourceIndex+1, scrollVC: vc)
        scrollView.addSubview(vc.view)
        
        if isFromStartEditingMode {
            DataSourceManager.main.addScrollPage(items: [])
        }
    }
    
    private func setScrollVCViewFrameWith(index: Int, scrollVC: CollectionDragSortViewController) {
        let origin = CGPoint(x: CGFloat(index) * view.bounds.width, y: 0)
        scrollVC.view.frame = CGRect(origin: origin, size: view.bounds.size)
    }
    
    @objc func longPressAction(_ longPress: UILongPressGestureRecognizer) {
        let pointInView = longPress.location(in: view)
        let editingManager = HomeEditingManager.main
        if editingManager.currentScrollVC.isKind(of: MessViewController.self) { return }
        
        switch longPress.state {
        case .began:
            editingManager.startEditingMode()
            editingManager.beginEditingAt(pointInView) { [weak self] position,item in
                guard let self = self else { return }
                self.outsideCell.isHidden = false
                self.outsideCell.animateToBigger()
                self.outsideCell.center = position
                self.outsideCell.titleLabel.text = item.title
                self.outsideCellCenterOffset = CGPoint(x: position.x - pointInView.x, y: position.y - pointInView.y)
            }
        case .changed:
            editingManager.updatePositionAt(pointInView, outsideCellCenterOffset: outsideCellCenterOffset)
            outsideCell.center = CGPoint(x: pointInView.x + outsideCellCenterOffset.x, y: pointInView.y + outsideCellCenterOffset.y)
        case .ended,.cancelled:
            editingManager.endEditAt(pointInView)
            outsideCell.isHidden = true
            outsideCell.animateToNormal()
        default:
            return
        }
    }
    
    // 单击关闭编辑模式
    // TODO: 系统表现为点击空白区域（即非cell的区域）关闭编辑模式，目前是点击所有区域都会关闭
    @objc private func tapAction() {
        if HomeEditingManager.main.isEditing {
            HomeEditingManager.main.isEditing = false
        }
    }
    
    @objc private func homeStartEditingMode() {
        let index = subScrollVC.count - 1
        addCollectionVC(dataSourceIndex: index, items: [], isFromStartEditingMode: true)
    }
    
    // 结束编辑模式并保存数据到`DataSourceManager`
    @objc private func homeEndEditingMode() {

        var needToShowScrollVC: CollectionDragSortViewController?
        var newSubScrollVCs: [UIViewController] = [messageVC]
        
        // for循环中的处理：1.删除items为空的控制器 2.获取到结束编辑模式后，显示在当前屏幕的控制器
        for (index,vc) in subScrollVC.enumerated() {
            guard let scrollVC = vc as? CollectionDragSortViewController else { continue }
            if scrollVC.items.isEmpty {
                // 删除items为空的控制器
                let view = scrollVC.view
                view?.removeFromSuperview()
            } else {
                newSubScrollVCs.append(vc)
            }
            if scrollVC == HomeEditingManager.main.currentScrollVC {
                if scrollVC.items.isEmpty {
                    // 若当前显示控制器items为空，则显示前一个控制器
                    if index > 1 {
                        needToShowScrollVC = subScrollVC[index - 1] as? CollectionDragSortViewController
                    }
                } else {
                    needToShowScrollVC = scrollVC
                }
            }
        }

        subScrollVC = newSubScrollVCs
        
        // 保存数据到`DataSourceManager`
        DataSourceManager.main.removeAllScrollDataSource()
        for (index,vc) in subScrollVC.enumerated() {
            guard let scrollVC = vc as? CollectionDragSortViewController else { continue }
            scrollVC.scrollDataSourceIndex = index - 1
            setScrollVCViewFrameWith(index: index, scrollVC: scrollVC)
            if needToShowScrollVC == vc {
                let offsetX = kScreenW * CGFloat(index)
                setCurrentScrollVCWithOffsetX(offsetX)
                scrollView.contentOffset = CGPoint(x: offsetX, y: 0)
            }
            DataSourceManager.main.addScrollPage(items: scrollVC.items)
        }
        DataSourceManager.main.bottomDataSource = bottomSubVC.items
    }
    
    @objc private func pageControllValueChanged(controll: UIPageControl) {
        let page = controll.currentPage
        let offsetX = kScreenW * CGFloat(page)
        scrollView.setContentOffset(CGPoint(x: offsetX, y: 0), animated: true)
    }
    
    private func setCurrentScrollVCWithOffsetX(_ offsetX: CGFloat) {
        let index = Int(offsetX/kScreenW)
        let scrollVC = subScrollVC[index]
        HomeEditingManager.main.currentScrollVC = scrollVC
        pageControll.currentPage = index
    }
    
    
    func pageJump(direction: ScrollDirection) {
        let currentX = scrollView.contentOffset.x
        let jumpX: CGFloat
        if direction == .left {
            if currentX <= kScreenW { return }
            jumpX = currentX - kScreenW
        } else {
            if currentX >= kScreenW * CGFloat(subScrollVC.count - 1) { return }
            jumpX = currentX + kScreenW
        }
        let offset = CGPoint(x: jumpX, y: 0)
        scrollView.setContentOffset(offset, animated: true)
    }
}

