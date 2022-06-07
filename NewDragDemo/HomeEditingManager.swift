//
//  HomeEditingManager.swift
//  NewDragDemo
//
//  Created by Allen long on 2022/5/20.
//

import Foundation
import UIKit

enum ScrollDirection {
    case left
    case right
}


class HomeEditingManager {
    private init() {}
    static let main = HomeEditingManager()
    var homeVC: ViewController!
    var currentScrollVC: UIViewController!
    
    var startEditVC: HomeEditingAble?
    var endEditVC: HomeEditingAble? {
        didSet {
            guard let start = startEditVC, let newEnd = endEditVC, let oldEnd = oldValue else { return }
            guard !newEnd.isEqual(oldEnd) else { return }
                    
            if oldEnd.hasAddItemFromOtherVC && !oldEnd.isEqual(start)  {
                oldEnd.homeEditingManagerRemoveItemFromOtherVC()
                oldEnd.hasAddItemFromOtherVC = false
//                print("移除增加的item")
            }
            if !newEnd.hasAddItemFromOtherVC && !newEnd.isEqual(start) {
//                print("增加item")
                if newEnd == homeVC.bottomSubVC && homeVC.bottomSubVC.items.count == ConstHelper.bottomItemsMaxCount { return }
                newEnd.homeEditingManagerAddItemFromOtherVC(item: editingItem!)
                newEnd.hasAddItemFromOtherVC = true
            }
        }
    }
    var lastAddItemVC: HomeEditingAble?
    var scrollTimer: Timer?
    var scrollDirection: ScrollDirection?
    
    var editingItem: HomeItem?
    var editingIndex: Int?
    var isInsertingItem = false
    
    var isHomeEditing = false {
        didSet {
            if isHomeEditing {
                NotificationCenter.default.post(name: .homeStartEditing, object: nil)
            } else {
                NotificationCenter.default.post(name: .homeEndEditing, object: nil)
                editingItem = nil
            }
        }
    }
    // TODO: 根据系统动画，直接加一屏
    func beginEditingAt(_ point: CGPoint, positionCallBack: (_ positon: CGPoint, _ item: HomeItem)->()) {
        if !isHomeEditing {
            isHomeEditing = true
        }
        if isPointInSrollView(point: point) {
            startEditVC = currentScrollVC as! CollectionDragSortViewController
        } else {
            startEditVC = homeVC.bottomSubVC
        }
        startEditVC?.homeEditingManagerBeginEditAt(point: point) { [weak self] positon, item, itemIndex in
            guard let self = self else { return }
            positionCallBack(positon,item)
            self.editingItem = item
            self.editingIndex = itemIndex
        }
    }
    // TODO: 顶部数量的限制，当挪向下一屏，下一屏已满时，下一屏的最后一个，自动跳动下下屏
    func updatePositionAt(_ point: CGPoint, outsideCellCenterOffset: CGPoint) {
        
        if let direction = isPointNeedToScroll(point: point) {
            scrollDirection = direction
            fireScrollTimer()
        } else {
            invalidScrollTimer()
        }

        if isPointInSrollView(point: point) {
            endEditVC = currentScrollVC as! CollectionDragSortViewController
        } else {
            endEditVC = homeVC.bottomSubVC
        }
        
        endEditVC!.homeEditingManagerUpdatePositionAt(point: point, outsideCellCenterOffset: outsideCellCenterOffset)
    }
    
    func endEditAt(_ point: CGPoint) {
        delay(0.2) {
            if self.isHomeEditing {
                // fixme: 直接关闭修改状态，会导致cell没有归位的动画；并且由于collectionView执行reloadData，而不调用moveItemAt方法
                self.isHomeEditing = false
            }
        }

        if let endVC = endEditVC {
            endVC.homeEditingEndEdit()
            
            if !endVC.isEqual(startEditVC) {
                print("移除第\(editingIndex!)个item")
                            startEditVC?.homeEditingRemoveItemAt(index: editingIndex!)
            }
        }
        
        NotificationCenter.default.post(name: .homeSaveItemsToManager, object: nil)
        
        clearOptional()
    }
    
    private func isPointInSrollView(point: CGPoint) -> Bool {
        return point.y < kScreenH - adapter(120)
    }
    
    private func isPointNeedToScroll(point: CGPoint) -> ScrollDirection? {
        if point.y > kScreenH - adapter(120) {
            return nil
        }
        if point.x < 50 { return .left }
        if point.x > kScreenW - 50 { return .right }
        return nil
    }
    
    private func clearOptional() {
        if let start = startEditVC {
            if start.hasAddItemFromOtherVC {
                start.hasAddItemFromOtherVC = false
            }
            startEditVC = nil
        }
        if let end = endEditVC {
            if end.hasAddItemFromOtherVC {
                end.hasAddItemFromOtherVC = false
            }
            endEditVC = nil
        }
        editingItem = nil
        editingIndex = nil
        invalidScrollTimer()
    }
    
    private func fireScrollTimer() {
        if scrollTimer == nil {
            scrollTimer = Timer(fire: Date() + 0.8, interval: 0.5, repeats: true, block: { [weak self] timer in
                guard let self = self else { return }
                if let direction = self.scrollDirection {
                    self.homeVC.pageJump(direction: direction)
                }
            })
            RunLoop.main.add(scrollTimer!, forMode: .common)
        }
    }
    
    private func invalidScrollTimer() {
        if scrollTimer != nil {
            scrollTimer?.invalidate()
            scrollTimer = nil
            scrollDirection = nil
        }
    }

}


extension Notification.Name {
    static let homeStartEditing = Notification.Name("homeStartEditing")
    static let homeEndEditing = Notification.Name("homeEndEditing")
    static let homeSaveItemsToManager = Notification.Name("homeSaveItemsToManager")
    static let homeDataSourceUpdated = Notification.Name("homeDataSourceUpdated")
}
