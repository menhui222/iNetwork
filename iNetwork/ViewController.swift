//
//  ViewController.swift
//  iNetwork
//
//  Created by 孟辉 on 2018/12/10.
//  Copyright © 2018 孟辉. All rights reserved.
//

import UIKit
import HandyJSON
class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let _ =  iNetWork.request(API: APIStype.login(phone: "10086100861", code: "11020"))
            .responseJSON()
            .parseToObejct(type:User.self)
            .subscribe(onNext: { (user) in
            
        }, onError: { (error) in
            
            print(error.massage)
            
        })
        
        
        
        let o = iNetWork.request(API: APIStype
            .getPhoneCode(phone: "15990013156"))
            .responseJSON().parseToObejct(type: User.self)
            .subscribe { (event) in
            switch event{
            case .next( let user):
                print(user)
            case .completed:
                print("完成")
            case.error(let error):
                
                print(error.massage)
            }
        }
        //销毁
        o.dispose()
    }

    
}

struct User:HandyJSON {
    
}
extension String :HandyJSON{
    
}
