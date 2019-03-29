//
//  SuccessSubscriptionViewController.swift
//  Zendo
//
//  Created by Anton Pavlov on 01/03/2019.
//  Copyright © 2019 zenbf. All rights reserved.
//

import UIKit
import Lottie

class SuccessSubscriptionViewController: UIViewController {
    
    @IBOutlet weak var animationView: UIView!
    
    let checkAnimation = LOTAnimationView(name: "checkAnimation")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        animationView.insertSubview(checkAnimation, at: 0)
        
        checkAnimation.contentMode = .scaleAspectFill
        checkAnimation.frame = animationView.bounds
        checkAnimation.animationSpeed = 0.6
    }
    
    static func loadFromStoryboard() -> SuccessSubscriptionViewController {
        let storyboard =  UIStoryboard(name: "Discover", bundle: nil).instantiateViewController(withIdentifier: "SuccessSubscriptionViewController") as! SuccessSubscriptionViewController
        return storyboard
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        checkAnimation.play()
    }
    
    @IBAction func buttonAction(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    
}