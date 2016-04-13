//
//  ViewController.swift
//  WKWebViewT1
//
//  Created by ZhangXu on 16/4/12.
//  Copyright © 2016年 zhangXu. All rights reserved.
//

import UIKit
import WebKit


class ViewController: UIViewController,WKScriptMessageHandler,WKNavigationDelegate,WKUIDelegate{
    
    var  webView:WKWebView!
    
    var  progressView :UIProgressView!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.edgesForExtendedLayout = .None
        
        //创建webView
        //创建一个webView的配置项
        let configuretion = WKWebViewConfiguration()
        
        //WebView的编好设置
        configuretion.preferences = WKPreferences()
        configuretion.preferences.minimumFontSize = 10
        configuretion.preferences.javaScriptEnabled = true
        
        //默认是不能通过JS自动打开窗口的,必须通过用户交互才能打开
        configuretion.preferences.javaScriptCanOpenWindowsAutomatically = false
        
        //通过js与webview内容交互配置
        configuretion.userContentController = WKUserContentController()
        
        // 添加一个JS到HTML中,这样就可以接在JS中调用我们添加的JS方法
        
        let script = WKUserScript(source: "function showAlert() { alert('在载入webView时通过siwft注入JS的方法'); }",
             injectionTime: .AtDocumentStart,//在加载时就添加JS
             forMainFrameOnly: true // 只添加到MainFrame中
        )
        configuretion.userContentController.addUserScript(script)
        
        //添加一个名称,就可以在JS通过这个名称发送消息:
        // window.webkit.messageHandlers.AppModel.postMessage({body: 'xxx'})
        configuretion.userContentController.addScriptMessageHandler(self, name: "AppModel")
        
        self.webView = WKWebView(frame: self.view.bounds, configuration:  configuretion)
        let url = NSBundle.mainBundle().URLForResource("test", withExtension: "html")
        
        self.webView.loadRequest(NSURLRequest(URL: url!))
        self.view.addSubview(self.webView)
    
        //监听支持KVO的属性
        self.webView.addObserver(self, forKeyPath: "loading", options: .New, context: nil)
        self.webView.addObserver(self, forKeyPath: "title", options: .New, context: nil)
        self.webView.addObserver(self, forKeyPath: "estimatedProgress", options: .New, context: nil)
        
        //遵循协议
        self.webView.navigationDelegate = self
        self.webView.UIDelegate = self
        
        //我们再添加前进、后退按钮和添加一个加载进度的控制显示在Webview上：
        self.progressView = UIProgressView(progressViewStyle :.Default)
        self.progressView.frame.size.width = self.view.frame.size.width
        self.progressView.backgroundColor = UIColor.greenColor()
        self.view.addSubview(self.progressView)
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "前进",style: .Done,target: self,action:#selector(ViewController.previousPage))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "后退",style: .Done,target: self,action: #selector(ViewController.nextPage))
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    // MARK: - WKScriptMessageHandler

    func previousPage(){
        if self.webView.canGoBack {
            self.webView.goBack()
        }
    }
    
    func nextPage(){
        
        if self.webView.canGoForward {
            self.webView.goForward()
        }
    }
    
    
    
    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        print(message.body)
        if message.name == "AppModel" {
            print("message name is AppModel")
        }
        
    }
    
    /**
      增加KVO
     */
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        
        if keyPath == "loading" {
            print("loading")
        }else if keyPath == "title" {
            print("title")
        }else if keyPath == "estimateProgress"{
            print(webView.estimatedProgress)
            self.progressView.setProgress(Float(webView.estimatedProgress), animated: true)
        }
        
        if !webView.loading {
            //手动调用JS代码
            let JS = "calljsAlert()"
            self.webView.evaluateJavaScript(JS, completionHandler: { (_, _) in
                print("call js alert")
            })
            
            UIView.animateWithDuration(0.55, animations: { 
                self.progressView.alpha = 0.0
            })
        }
    }
    
    /**
        实现导航代理
     */
    // 决定导航的动作,通常用于处理跨越的链接能否导航,webkit对跨越进行了安全监测限制,不允许跨越,因此我们要对不能跨越的链接单独出去  但是对于safari不用这么处理  
    func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
        
        print(#function)
        
        let hostname = navigationAction.request.URL?.host?.lowercaseString
        print(hostname)
        //处理跨越问题
        
        if navigationAction.navigationType == .LinkActivated && !hostname!.containsString(".baidu.com") {
            //手动跳转
            UIApplication.sharedApplication().openURL(navigationAction.request.URL!)
            
            //不允许导航
            decisionHandler(.Cancel)
        }else{
            self.progressView.alpha = 1.0
            
            decisionHandler(.Allow)
            
        }
    }
    
    /**
          实现WKUIDelegate
     // 这个方法是在HTML中调用了JS的alert()方法时，就会回调此API。
     // 注意，使用了`WKWebView`后，在JS端调用alert()就不会在HTML
     // 中显示弹出窗口。因此，我们需要在此处手动弹出ios系统的alert。

     */
    
    func webView(webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: () -> Void) {
        
        let alert = UIAlertController (title: "Tip",message: message,preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Ok",style: .Default,handler: {(_)->Void in
           
            completionHandler()
        }))
        
        self.presentViewController(alert, animated: true, completion: nil)
        
    }
    
    
    func webView(webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: (Bool) -> Void) {
        
        let alert = UIAlertController(title: "Tip",message: message,preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Ok",style: .Default,handler: {(_) -> Void in
             // 点击完成后，可以做相应处理，最后再回调js端
            completionHandler(true)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel",style: .Cancel,handler: {(_) ->Void in
           
             // 点击取消后，可以做相应处理，最后再回调js端
            completionHandler(true)
        }))
        self.presentViewController(alert, animated: true, completion: nil)
        
    }
    
    
    func webView(webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: (String?) -> Void) {
        
        let alert = UIAlertController(title: prompt,message: defaultText,preferredStyle: .Alert)
        alert.addTextFieldWithConfigurationHandler { (textField:UITextField) -> Void in
            textField.textColor = UIColor.greenColor()
        }
        
        alert.addAction(UIAlertAction(title: "Ok",style: .Default,handler: {(_) ->Void in
           completionHandler(alert.textFields![0].text)
            
        }))
        
        self.presentViewController(alert, animated: true, completion: nil)
        
        
    }
    
    
    
//Invoked when content starts arriving for the main frame.这是API的原注释。也就是在页面内容加载到达mainFrame时会回调此API。如果我们要在mainFrame中注入什么JS，也可以在此处添加。
    func  webView(webView: WKWebView, didCommitNavigation navigation: WKNavigation!) {
        print(#function)
    }
    
    
//加载完成的回调
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        print(#function)
    }
    
//如果加载失败了，会回调下面的代理方法：
    func webView(webView: WKWebView, didFailNavigation navigation: WKNavigation!, withError error: NSError) {
         print(#function)
    }
    

//开始加载页面内容时就会回调此代理方法，与UIWebView的didStartLoad功能相当
    
    func webView(webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print(#function)
    }
    
//当我们终止页面加载时，我们会可以处理下面的代理方法，如果不需要处理，则不用实现之：
    func webViewWebContentProcessDidTerminate(webView: WKWebView) {
        print(#function)
    }
    
 //其实在还有一些API，一般情况下并不需要。如果我们需要处理在重定向时，需要实现下面的代理方法就可以接收到。
    func webView(webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        print(#function)
    }
    
    func webView(webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: NSError) {
        print(#function)
    }
    

    //决定是否允许导航响应，如果不允许就不会跳转到该链接的页面。
    
    func webView(webView: WKWebView, decidePolicyForNavigationResponse navigationResponse: WKNavigationResponse, decisionHandler: (WKNavigationResponsePolicy) -> Void) {
        print(#function)
        decisionHandler(.Allow)
    }
    
    
//    如果我们的请求要求授权、证书等，我们需要处理下面的代理方法，以提供相应的授权处理等：
    func webView(webView: WKWebView, didReceiveAuthenticationChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
        
        print(#function)
        completionHandler(.PerformDefaultHandling,nil)
    }
    
    func webViewDidClose(webView: WKWebView) {
        print(#function)
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}


