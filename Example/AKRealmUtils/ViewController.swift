//
//  ViewController.swift
//  AKRealmUtils
//
//  Created by ArKalmykov on 10/17/2017.
//  Copyright (c) 2017 ArKalmykov. All rights reserved.
//

import UIKit
import RealmSwift
import AKRealmUtils

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

class CustomObject: Object {
    override func deleteFromRealm() {
        super.deleteFromRealm()
    }
}
