//
//  HomeEditingAble.swift
//  NewDragDemo
//
//  Created by Allen long on 2022/6/9.
//

import Foundation
import UIKit

protocol HomeEditingAble: UIViewController {
    var items: [HomeItem] {get set}
    var hasAddItemFromOtherVC: Bool {get set}
    var dealingCell: DragSortCollectionCell? {get set}
    
    func homeEditingManagerBeginEditAt(point: CGPoint, positionCallBack: (_ positon: CGPoint, _ item: HomeItem, _ itemIndex: Int)->())
    func homeEditingManagerUpdatePositionAt(point: CGPoint, outsideCellCenterOffset: CGPoint)
    func homeEditingManagerAddItemFromOtherVC(item: HomeItem)
    func homeEditingManagerRemoveItemFromOtherVC()
    func homeEditingManagerGestureEndOrCanceled()
    func homeEditingRemoveStartItem()
//    func homeEditingClose
}
