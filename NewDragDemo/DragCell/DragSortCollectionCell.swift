//
//  DragSortCollectionCell.swift
//  DemosInSwift
//
//  Created by 古创 on 2021/9/9.
//  Copyright © 2021 c. All rights reserved.
//

import UIKit

class DragSortCollectionCell: UICollectionViewCell,NibLoadable {
    
    static let shakeAniKey = "shake"
    
    var closeCallBack: ((_ cell: DragSortCollectionCell)->())?
    
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var iconImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var closeBtn: UIButton!
    @IBAction func closeAction(_ sender: Any) {
        closeCallBack?(self)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        
        bgView.layer.cornerRadius = adapter(15)
        bgView.layer.masksToBounds = true

    }
    
    func refreshWithItem(_ item: HomeItem, isEditing: Bool) {
        if isEditing {
            startShake()
        } else {
            stopShake()
        }
        titleLabel.text = item.title
        closeBtn.isHidden = !isEditing
    }
    
    func startShake() {
        if let _ = contentView.layer.animation(forKey: DragSortCollectionCell.shakeAniKey) { return }
        
        let shakeAnimation = CAKeyframeAnimation(keyPath: "transform.rotation")
        shakeAnimation.values = [-5 / 180 * Double.pi, 5 / 180 * Double.pi, -5 / 180 * Double.pi]
        shakeAnimation.isRemovedOnCompletion = false
        shakeAnimation.fillMode = .forwards
        shakeAnimation.duration = 0.3
        shakeAnimation.repeatCount = MAXFLOAT
        contentView.layer.add(shakeAnimation, forKey: DragSortCollectionCell.shakeAniKey)
        
    }

    func stopShake() {
        contentView.layer.removeAnimation(forKey: DragSortCollectionCell.shakeAniKey)
    }
    
    /// 展示
    /// - Parameter isCloseHidden: 关闭按钮是否隐藏
    func show(isCloseHidden: Bool) {
        bgView.isHidden = false
        iconImage.isHidden = false
        titleLabel.isHidden = false
        closeBtn.isHidden = isCloseHidden
    }
    
    /// 隐藏
    func hide() {
        bgView.isHidden = true
        iconImage.isHidden = true
        titleLabel.isHidden = true
        closeBtn.isHidden = true
    }
    
    func animateToBigger() {
        let animation = CABasicAnimation(keyPath: "transform")
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        animation.duration = 0.2
        animation.toValue = NSValue(caTransform3D: CATransform3DMakeScale(1.1, 1.1, 1.0))
        contentView.layer.add(animation, forKey: "toBigger")
    }
    
    func animateToNormal() {
        contentView.layer.removeAnimation(forKey: "toBigger")
        
        // TODO: 缺少outsideCell移向正确位置的动画，目前是直接隐藏
    }
}
