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
        }
    }
    var bottomSubVC = BottomVC()
    
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
        view.addSubview(it)
        return it
    }()
    
    var outsideCellCenterOffset: CGPoint = .zero

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        // 默认在第二屏
        setCurrentScrollVCWithOffsetX(kScreenW)
        scrollView.contentOffset = CGPoint(x: kScreenW, y: 0)
        
        // TODO: 编辑状态和非编辑状态下，手势是否有两个；建议按住变为编辑模式，再重新按住挪动。然后点击空白区域取消编辑模式
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPressAction(_:)))
        view.addGestureRecognizer(longPress)
        
        HomeEditingManager.main.homeVC = self
    }
    
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        addMessageVC()
        
        // 添加滑动控制器
        for (index,pageSource) in DataSourceManager.main.scrollDataSource.enumerated() {
            addCollectionVC(dataSourceIndex: index, items: pageSource)
        }
        
        //添加底部控制器
        addChild(bottomSubVC)
        view.addSubview(bottomSubVC.view)
        bottomSubVC.view.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(120)
        }
    }
    
    private func addMessageVC() {
        let vc = MessViewController()
        subScrollVC.append(vc)
        scrollView.addSubview(vc.view)
        vc.view.frame = view.bounds
    }
    
    private func addCollectionVC(dataSourceIndex: Int, items: [HomeItem]) {
        let vc = CollectionDragSortViewController(dataSourceIndex: dataSourceIndex, items: items)
        subScrollVC.append(vc)
        
        let origin = CGPoint(x: CGFloat(dataSourceIndex + 1) * view.bounds.width, y: 0)
        vc.view.frame = CGRect(origin: origin, size: view.bounds.size)
        scrollView.addSubview(vc.view)
    }
    
    private func removeCollectionVC() {
        guard let vc = subScrollVC.last as? CollectionDragSortViewController,
              vc.items.isEmpty
        else { return }
        let view = vc.view
        vc.removeFromParent()
        view?.removeFromSuperview()        
    }
    
    @objc func longPressAction(_ longPress: UILongPressGestureRecognizer) {
        let pointInView = longPress.location(in: view)
        let editingManager = HomeEditingManager.main
        if editingManager.currentScrollVC.isKind(of: MessViewController.self) { return }
        
        switch longPress.state {
        case .began:
            let index = subScrollVC.count - 1
            addCollectionVC(dataSourceIndex: index, items: [])
            editingManager.beginEditingAt(pointInView) { [weak self] position,item in
                guard let self = self else { return }
                self.outsideCell.isHidden = false 
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
            
        default:
            return
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        setCurrentScrollVCWithOffsetX(scrollView.contentOffset.x)
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        setCurrentScrollVCWithOffsetX(scrollView.contentOffset.x)
    }
    
    private func setCurrentScrollVCWithOffsetX(_ offsetX: CGFloat) {
        let scrollVC = subScrollVC[Int(offsetX/kScreenW)]
        HomeEditingManager.main.currentScrollVC = scrollVC
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

extension ViewController: UIScrollViewDelegate {
    
}

