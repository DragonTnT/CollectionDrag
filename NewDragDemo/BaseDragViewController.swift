//
//  BaseDragViewController.swift
//  NewDragDemo
//
//  Created by Allen long on 2022/6/7.
//

import UIKit

class BaseDragViewController: UIViewController {

    var items: [HomeItem]
    var hasAddItemFromOtherVC: Bool = false
    var dealingCell: DragSortCollectionCell?
    var dragBeginOriginY: CGFloat?
    var dealingCellCurrentIndex: Int?

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
        collection.showsVerticalScrollIndicator = false
        collection.showsHorizontalScrollIndicator = false
        collection.isScrollEnabled = false
        collection.contentInsetAdjustmentBehavior = .never
        return collection
    }()

    init(items: [HomeItem]) {
        self.items = items
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNotifications()
        // Do any additional setup after loading the view.        
    }
    
}

extension BaseDragViewController: HomeEditingAble {
    
    func homeEditingManagerBeginEditAt(point: CGPoint, positionCallBack: (CGPoint, HomeItem, Int) -> ()) {
        let homeVC = HomeEditingManager.main.homeVC!
        let pointInCollectionView = homeVC.view.convert(point, to: collectionView)
        if let indexPath = collectionView.indexPathForItem(at: pointInCollectionView) {
            dealingCell = collectionView.cellForItem(at: indexPath) as? DragSortCollectionCell
            dragBeginOriginY = dealingCell?.frame.origin.y
            dealingCell?.hide()
            collectionView.beginInteractiveMovementForItem(at: indexPath)
            guard let position = dealingCell?.convert(CGPoint(x: ConstHelper.itemSize.width/2, y: ConstHelper.itemSize.height/2), to: view) else { return }
            let changedPosition = changePositonForCallBack(position: position)
            positionCallBack(changedPosition,items[indexPath.item],indexPath.item)
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
        saveItemsToManager()

        dealingCell = collectionView.cellForItem(at: indexPath) as? DragSortCollectionCell
        dealingCell?.hide()
        collectionView.beginInteractiveMovementForItem(at: indexPath)
    }

    func homeEditingManagerRemoveItemFromOtherVC() {
        collectionView.cancelInteractiveMovement()
        let itemIndex = items.count - 1
        let indexPath = IndexPath(item: itemIndex, section: 0)
        items.removeLast()
        collectionView.deleteItems(at: [indexPath])
        saveItemsToManager()
    }

    func homeEditingRemoveStartItem() {
        guard let index = dealingCellCurrentIndex else { return }
        collectionView.performBatchUpdates {
            collectionView.endInteractiveMovement()
            items.remove(at: index)
            collectionView.deleteItems(at: [IndexPath(item: index, section: 0)])
            saveItemsToManager()
        } completion: { _ in
//            self.collectionView.reloadData()
        }
    }
    
    func homeEditingManagerGestureEndOrCanceled() {
        collectionView.endInteractiveMovement()
        dealingCell?.show(isCloseHidden: !HomeEditingManager.main.isEditing)
    }
}

extension BaseDragViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! DragSortCollectionCell
        let isEditing = HomeEditingManager.main.isEditing
        cell.refreshWithItem(items[indexPath.item], isEditing: HomeEditingManager.main.isEditing)
        cell.show(isCloseHidden: !isEditing)
        cell.closeCallBack = { thisCell in
            guard let thisIndexPath = collectionView.indexPath(for: thisCell) else { return }
            self.items.remove(at: thisIndexPath.item)
            collectionView.deleteItems(at: [thisIndexPath])
            self.saveItemsToManager()
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("xixi")
    }

    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let item = items.remove(at: sourceIndexPath.row)
        items.insert(item, at: destinationIndexPath.row)
        saveItemsToManager()
    }
    
    func collectionView(_ collectionView: UICollectionView, targetIndexPathForMoveOfItemFromOriginalIndexPath originalIndexPath: IndexPath, atCurrentIndexPath currentIndexPath: IndexPath, toProposedIndexPath proposedIndexPath: IndexPath) -> IndexPath {
        
        // TODO: 目前这里只能处理scrollVC的cell往空白处移动，bottomVC的cell移动到scrollVC，collectionView重新布局。
        // 但没有解决的是cell先和本vc的cell互换位置后，再执行上面的操作；因为和本vc互换位置后，originalIndexPath == proposedIndexPath不相等，就不会执行以下逻辑。
        var resultIndexPath: IndexPath = proposedIndexPath
        if originalIndexPath == proposedIndexPath, let dealingCell = dealingCell  {
            if self.isKind(of: CollectionDragSortViewController.self) {
                   if let originCellOriginY = dragBeginOriginY {
                       if dealingCell.frame.origin.y - originCellOriginY > adapter(100) {
                            resultIndexPath = IndexPath(item: items.count - 1, section: 0)
                        }
                }
            } else if self.isKind(of: BottomVC.self) {
                let pointInScreen = view.convert(dealingCell.center, to: HomeEditingManager.main.homeVC.view)
                if pointInScreen.y >= kScreenH - adapter(120) && pointInScreen.y < kScreenH - adapter(70) {
                    resultIndexPath = IndexPath(item: items.count - 1, section: 0)
                }
            }
            
        }
        dealingCellCurrentIndex = resultIndexPath.item
        return resultIndexPath
    }

}

// MARK: - Helper
extension BaseDragViewController {
    @objc func setupUI() {
        view.addSubview(collectionView)
    }
    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(homeStartEditingMode), name: .homeStartEditingMode, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(homeEndEditingMode), name: .homeEndEditingMode, object: nil)
    }
    @objc func homeStartEditingMode() {
        collectionView.reloadData()
        // 保证`homeEditingManagerBeginEditAt`中能获取到dealingCell
        collectionView.layoutIfNeeded()
    }
    @objc func homeEndEditingMode() {
        collectionView.reloadData()
    }

    @objc func saveItemsToManager() {}

    @objc func changePositonForCallBack(position: CGPoint) -> CGPoint {
        return position
    }
    
}
