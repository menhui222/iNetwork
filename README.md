# iNetwork
####对Alamofire进行再次封装  结合实际开发

##使用
```
///组建请求配置 请求 解析 返回  
let _ =  iNetWork.request(API: APIStype.login(phone: "15990013156", code: "11020"))
        .responseJSON()
        .parseToObejct(type:User.self)
        .subscribe(onNext: { (user) in
           print(user)
        }, onError: { (error) in
         print(error.massage)
        })
```

```
  let _ = iNetWork.request(API: APIStype.getPhoneCode(phone: "15990013156"))
        .responseJSON()
        .parseToObejct(type: String.self)
        .subscribe { (event) in
            switch event{
            case .next( let str):
                log.info(str)
            case .completed:
                log.info("成功")
            case.error(let error):
                log.info(error)
            }
        }
```
####接口参数配置
```
///。。。。。。
enum APIStype {
    //手机号登录
    case login(phone:String,code:String)

    //
    case users(userName:String)
    
    
    
    
    
    var path:String{
        get{
            switch self {
            case .login(phone: let phone, code: let code ):
              return "api/login/\(phone)/\(code)"
     
                
            case .users(let userName):
                return "users/\(userName)"
            }
        }
    }
    
    
    var params :[String:Any]{
        switch self {
        case .login(phone: let phone, code: let code ):
            return ["phone":phone,"code":code]

        case .users(_)://可以不写
           return [String:Any]()
        default:
            return [String:Any]()
        }
      
    }
  
    
    
    var  method: Alamofire.HTTPMethod{
        switch self {
        case .login(phone:_, code: _ ):
            return .post
        //case .getPhoneCode(phone: _):
            //return .get
            
        case .users(_):
            return .get
            
        default:
            return .post
        }
    }
    var hostPath:String {
        
        return "https://api.github.com/"
    }
    var urlStr:String {
        
        return hostPath + path
    }
    var url :URL{
        
            return  URL(string: urlStr)!
       
        
    }
    
}
```
####数据返回
```
enum Result<T:OutfitJson> {
    case success(T)
    case failure(NetworkError)
}



/// 处理异常累
///
/// - NoNetwor: 没网络
/// - NetworkError: 网络通讯异常  包括 404...
/// - ParseFailure: 解析失败
/// - ServerError: 服务器异常  error  服务器传过来的 信息
/// - DataError: 数据异常
enum NetworkError:Error{
    case NoNetwor
    case NetworkError
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
            case .NetworkError:
                return "网络异常"
            }
        }
    }
    
}
```
####请求和解析部分代码        

```
struct iNetWork {
   
    //
    public static func request(API:APIStype) -> DataRequest{
      return  Alamofire.request(API.url, method:API.method, parameters:API.params)
    }
    //
    
}

extension DataRequest{
    
  
    public func responseJSON()->Observable<OutfitJson>{
        
        
        /// 根据自己的实际
        ///
        /// - Parameter response: DataResponse
        /// - Returns: 合理
        /// - Throws: 异常
        func transactionData(response:DataResponse<Any>) throws -> OutfitJson {
            if (response.result.error != nil){
                throw NetworkError.NetworkError
                
            }
            guard  let data = response.result.value else  {
                throw NetworkError.NetworkError
                
            }
            guard let dic = data as? [String:Any] else {
                throw NetworkError.DataError
                
            }
           //OutfitJson().data
            let json = OutfitJson.deserialize(from: dic)
            if (json == nil)   {
                throw NetworkError.ParseFailure
                
            }
            
             if json?.code != 2000 {
                throw NetworkError.ServerError(error: json?.massage ?? "服务器异常")
            }
            print(dic)
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
        
        return  Disposables.create(with: {
            self.cancel()
        })
        
        }
        
        
      
    }
   


}

// MARK: - 解析
extension Observable where Element:OutfitJson{
   
    
    ///  单个解析
    ///
    /// - Parameter type: 类型
    /// - Returns: 解析结果
    public func parseToObejct<T:HandyJSON>(type:T.Type)  -> Observable<T>{
    
        return  self.map({ (json) -> T in
            guard let o = T.deserialize(from: json.data) else{
                throw NetworkError.ParseFailure
            }
            return o
        })
    }
    ///  数组解析
    ///
    /// - Parameter type: 类型
    /// - Returns: 解析结果 [T]
    public func parseToObejctArray<T:HandyJSON>(type:T.Type) -> Observable<[T]>{
        
        return  self.map({ (json) -> [T] in
            guard let o = [T].deserialize(from: json.data)else{
                throw NetworkError.ParseFailure
            }
            return o as! [T]
        })
    }
}

```
