//
//  CollectionDragSortViewController.swift
//  DemosInSwift
//
//  Created by 古创 on 2021/9/9.
//  Copyright © 2021 c. All rights reserved.
//

import UIKit

protocol HomeEditingAble: UIViewController {
    var hasAddItemFromOtherVC: Bool {get set}
    
    func homeEditingManagerBeginEditAt(point: CGPoint, positionCallBack: (_ positon: CGPoint, _ item: HomeItem, _ itemIndex: Int)->())
    func homeEditingManagerUpdatePositionAt(point: CGPoint, outsideCellCenterOffset: CGPoint)
    func homeEditingManagerAddItemFromOtherVC(item: HomeItem)
    func homeEditingManagerRemoveItemFromOtherVC()
    func homeEditingEndEdit()
    func homeEditingRemoveItemAt(index: Int)
}

class CollectionDragSortViewController: UIViewController {
    
    var dataSourceIndex: Int
    var items: [HomeItem]
    var hasAddItemFromOtherVC: Bool = false
    
    init(dataSourceIndex: Int, items: [HomeItem]) {
        self.dataSourceIndex = dataSourceIndex
        self.items = items
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    /// scrollView是否正在翻页
    var isTurningPage = false
    var isShaking = false
    var isInsertingItem = false
    
    var dealingCell: DragSortCollectionCell?
    
    lazy var layout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.itemSize = ConstHelper.itemSize
        layout.minimumLineSpacing = adapter(10)
        layout.minimumInteritemSpacing = adapter(5)
        layout.scrollDirection = .vertical
        layout.sectionInset = UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15)
        return layout
    }()   
    
    lazy var collectionView: UICollectionView = {
        let collection = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        collection.delegate = self
        collection.dataSource = self
        collection.register(UINib.init(nibName: "DragSortCollectionCell", bundle: Bundle.main), forCellWithReuseIdentifier: "cell")
        collection.backgroundColor = .clear
        collection.showsVerticalScrollIndicator = false
        collection.showsHorizontalScrollIndicator = false
        collection.isPagingEnabled = true
        collection.contentSize = CGSize(width: kScreenW * 2, height: kScreenH - adapter(120))
        return collection
    }()

    var isStartDragInMain:Bool = false // 开始拖拽是否在collectionView中
    var dragingIndexPath:IndexPath?
    var insideCell:DragSortCollectionCell? // 拖拽的cell
    var didMoveToDifferentCollection:Bool = false // 是否移动cell到不同的collection中
    
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
        setUI()
        NotificationCenter.default.addObserver(self, selector: #selector(homeEditingDidStartEdit), name: .homeStartEditing, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(homeEditingDidEndEdit), name: .homeEndEditing, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(homeSaveItemsToManager), name: .homeSaveItemsToManager, object: nil)
    }
}

// MARK; - setUI
extension CollectionDragSortViewController {
    func setUI() {
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.top.left.right.equalTo(0)
            make.bottom.equalTo(-120)
        }
    }
        
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource
extension CollectionDragSortViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! DragSortCollectionCell
        cell.item = items[indexPath.item]
        cell.show()
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        
        let item = items.remove(at: sourceIndexPath.row)
        items.insert(item, at: destinationIndexPath.row)
        print("将Item从第\(sourceIndexPath.row)移到\(destinationIndexPath.row)")
    }
}

extension CollectionDragSortViewController: HomeEditingAble {
    
    @objc func homeEditingDidStartEdit() {
        for item in items {
            item.isEditing = true
        }
        collectionView.reloadData()
        // 保证`homeEditingManagerBeginEditAt`中能获取到dealingCell
        collectionView.layoutIfNeeded()
    }
    @objc func homeEditingDidEndEdit() {
        for item in items {
            item.isEditing = false
        }
        collectionView.reloadData()
    }
    @objc private func homeSaveItemsToManager() {
        DataSourceManager.main.updateScrollItems(items, at: dataSourceIndex)
    }
    func homeEditingManagerBeginEditAt(point: CGPoint, positionCallBack: (_ positon: CGPoint, _ item: HomeItem, _ itemIndex: Int)->()) {
        let homeVC = HomeEditingManager.main.homeVC!
        let pointInCollectionView = homeVC.view.convert(point, to: collectionView)
        if let indexPath = collectionView.indexPathForItem(at: pointInCollectionView) {
            dealingCell = collectionView.cellForItem(at: indexPath) as? DragSortCollectionCell
            dealingCell?.hide()
            collectionView.beginInteractiveMovementForItem(at: indexPath)
            guard let position = dealingCell?.convert(CGPoint(x: ConstHelper.itemSize.width/2, y: ConstHelper.itemSize.height/2), to: view) else { return }
            positionCallBack(position,dealingCell!.item, indexPath.item)
        }
    }
    
    func homeEditingManagerUpdatePositionAt(point: CGPoint, outsideCellCenterOffset: CGPoint) {
        let homeVC = HomeEditingManager.main.homeVC!
        let pointInCollectionView = homeVC.view.convert(point, to: collectionView)
        let fixedPoint = CGPoint(x: pointInCollectionView.x + outsideCellCenterOffset.x, y: pointInCollectionView.y + outsideCellCenterOffset.y)
        collectionView.updateInteractiveMovementTargetPosition(fixedPoint)
    }
    
    func homeEditingManagerAddItemFromOtherVC(item: HomeItem) {        
        let itemIndex = items.count
        let indexPath = IndexPath(item: itemIndex, section: 0)
        items.append(item)
        collectionView.insertItems(at: [indexPath])
        
        dealingCell = collectionView.cellForItem(at: indexPath) as? DragSortCollectionCell
        dealingCell?.hide()
        collectionView.beginInteractiveMovementForItem(at: indexPath)
    }
    
    func homeEditingManagerRemoveItemFromOtherVC() {        
        // FIXME: cancelInteractiveMovement会触发reloadData，所以能短暂看见cell恢复位置的动画
        collectionView.cancelInteractiveMovement()
        let itemIndex = items.count - 1
        let indexPath = IndexPath(item: itemIndex, section: 0)
        items.removeLast()
        collectionView.deleteItems(at: [indexPath])
    }
    
    func homeEditingRemoveItemAt(index: Int) {
        collectionView.endInteractiveMovement()
        items.remove(at: index)
    }
    
    func homeEditingEndEdit() {
        collectionView.endInteractiveMovement()
        dealingCell?.show()
    }    
}
