//
//  BottomVC.swift
//  NewDragDemo
//
//  Created by Allen long on 2022/5/19.
//

import UIKit

class BottomVC: UIViewController {
        
    var dealingCell: DragSortCollectionCell?
    var items: [HomeItem] = []
    var hasAddItemFromOtherVC: Bool = false
    
    lazy var layout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.itemSize = CGSize(width: adapter(80), height: adapter(100))
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
        collection.backgroundColor = .lightGray.withAlphaComponent(0.3)
        collection.showsVerticalScrollIndicator = false
        collection.showsHorizontalScrollIndicator = false
        collection.isScrollEnabled = false
        return collection
    }()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        items = DataSourceManager.main.bottomDataSource
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { $0.edges.equalToSuperview() }
        
        NotificationCenter.default.addObserver(self, selector: #selector(homeEditingDidStartEdit), name: .homeStartEditing, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(homeEditingDidEndEdit), name: .homeEndEditing, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(homeSaveItemsToManager), name: .homeSaveItemsToManager, object: nil)
    }

}
 
extension BottomVC: UICollectionViewDelegate,UICollectionViewDataSource {
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
//        DataSourceManager.main.bottomDataSource = items
    }
    
}

extension BottomVC: HomeEditingAble {
    
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
        DataSourceManager.main.bottomDataSource = items
    }
    func homeEditingManagerBeginEditAt(point: CGPoint, positionCallBack: (_ positon: CGPoint, _ item: HomeItem, _ itemIndex: Int)->()) {
        let homeVC = HomeEditingManager.main.homeVC!
        let pointInCollectionView = homeVC.view.convert(point, to: collectionView)
        if let indexPath = collectionView.indexPathForItem(at: pointInCollectionView) {
            dealingCell = collectionView.cellForItem(at: indexPath) as? DragSortCollectionCell
            dealingCell?.hide()
            collectionView.beginInteractiveMovementForItem(at: indexPath)
            guard var position = dealingCell?.convert(CGPoint(x: ConstHelper.itemSize.width/2, y: ConstHelper.itemSize.height/2), to: view) else { return }
            position.y = position.y + kScreenH - adapter(120)
            positionCallBack(position,dealingCell!.item,indexPath.item)
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
    // FIXME: 从第一个vc先向右，再向下
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
