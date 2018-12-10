//
//  Network.swift
//  SwiftLaboratory
//
//  Created by 孟辉 on 2018/12/6.
//  Copyright © 2018 孟辉. All rights reserved.
//

import Foundation
import Alamofire
import RxSwift
import HandyJSON



enum NetworkError:Error{
    case NoNetwor
    case NetworeError
    case ParseFailure
    case ServerError(error:String)
    case DataError
    var massage :String{
        get{
            switch self {
            case .NoNetwor:
                return "没网络"
            case .DataError:
                return "数据异常"
            case .ParseFailure:
                return "解析失败"
            case .ServerError(let error):
                return error;
            case .NetworeError:
                return "网络异常"
            }
        }
    }
    
}

extension Error{
    var massage :String{
        if self is NetworkError {
            return self.localizedDescription
        }
        let netError = self as! NetworkError
      
        return netError.massage;
            
    }
    
}


protocol Json :HandyJSON {}
public class OutfitJson:Json {
    required public init() {
        code = -1
        massage = "这不是你数据"
        data = "空"
    }
    
    var code : Int
    var massage : String
    var data :String
}
extension Data:HandyJSON{}




public enum APIStype {
    //手机号登录
    case login(phone:String,code:String)
    
    //code
    case getPhoneCode(phone:String)
    
    //....... 更多请求。。。。
    

    
    var path:String{
        get{
            switch self {
            case .login(phone: let phone, code: let code ):
              return "api/login/\(phone)/\(code)"
            case .getPhoneCode(phone: let phone):
             return "api/getPhoneCode/\(phone)"
                
                
            }
        }
    }
    
    var params :[String:Any]{
        switch self {
        case .login(phone: let phone, code: let code ):
            return ["phone":phone,"code":code]
        case .getPhoneCode(phone: _):
            return [String:Any]()

        }
      
    }
    
    var  method: Alamofire.HTTPMethod{
        switch self {
        case .login(phone:_, code: _ ):
            return .post
        case .getPhoneCode(phone: _):
            return .get
            
        }
    }
    var hostPath:String {
        
        return "www.baidu.com"
    }
    var urlStr:String {
        
        return hostPath + path
    }
    var url :URL{
        
            return  URL(string: urlStr)!
       
        
    }
    
}


struct iNetWork {
   
    
    public static func request(API:APIStype) -> DataRequest{
      return  Alamofire.request(API.url, method:API.method, parameters:API.params)
    }
    
}

extension DataRequest{
    
  
    public func responseJSON()->Observable<OutfitJson>{
        
        func transactionData(response:DataResponse<Any>) throws -> OutfitJson {
            if (response.result.error != nil){
                throw NetworkError.NetworeError
                
            }
            guard  let data = response.result.value else  {
                throw NetworkError.NetworeError
                
            }
            guard let dic = data as? [String:Any] else {
                throw NetworkError.DataError
                
            }
           
            let json = OutfitJson.deserialize(from: dic)
            if (json == nil)   {
                throw NetworkError.ParseFailure
                
            }
             if json?.code != 2000 {
                throw NetworkError.ServerError(error: json?.massage ?? "服务器异常")
            }
            return json!
            
        }
        
       return Observable<OutfitJson>.create { (o) -> Disposable in
        
        self.responseJSON(completionHandler: { (response) in
            do{
                let json = try transactionData(response: response)
                o.onNext(json)
            }catch(let error){
              o.onError(error)
            }
           
        })
        
            return  Disposables.create()
        }
        
        
      
    }
   
    
    //。。。
    
    
    
    //。。。。

}

extension Observable where Element:OutfitJson{
   
    public func parseToObejct<T:HandyJSON>(type:T.Type)  -> Observable<T>{
    
        return  self.map({ (json) -> T in
            guard let o = T.deserialize(from: json.data) else{
                throw NetworkError.ParseFailure
            }
            return o
        })
    }
    
    public func parseToObejctArray<T:HandyJSON>(type:T.Type) -> Observable<[T]>{
        
        return  self.map({ (json) -> [T] in
            guard let o = [T].deserialize(from: json.data)else{
                throw NetworkError.ParseFailure
            }
            return o as! [T]
        })
    }
}

