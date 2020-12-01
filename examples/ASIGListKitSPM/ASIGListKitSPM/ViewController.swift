//
//  ViewController.swift
//  ASIGListKitSPM
//
//  Created by Petro Rovenskyy on 01.12.2020.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let main = MainListViewController(flowLayout: UICollectionViewFlowLayout())
        let nav = UINavigationController(rootViewController: main)
        self.present(nav, animated: true, completion: nil)
    }

}

