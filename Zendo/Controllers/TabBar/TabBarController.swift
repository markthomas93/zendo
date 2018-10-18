//
//  TabBarViewController.swift
//  Zendo
//
//  Created by Anton Pavlov on 02/08/2018.
//  Copyright © 2018 zenbf. All rights reserved.
//

import UIKit


class TabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tabBar.unselectedItemTintColor = UIColor.zenLightGreen
        
        tabBar.layer.shadowOffset = CGSize(width: 0, height: 0)
        tabBar.layer.shadowRadius = 2
        tabBar.layer.shadowColor = UIColor.black.cgColor
        tabBar.layer.shadowOpacity = 0.3
        
        for item in tabBar.items! {
            item.image = item.selectedImage!.with(color: UIColor.zenLightGreen).withRenderingMode(.alwaysOriginal)
        }
        
    }
    
//    override var preferredStatusBarStyle: UIStatusBarStyle {
//        return .lightContent
//    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
}
