//
//  SettingsViewController.swift
//  InspirationalQuotes
//
//  Created by RJ Militante on 9/17/16.
//  Copyright (c) 2016 Kraftwerking. All rights reserved.
//

import UIKit
import StoreKit
import SystemConfiguration

class SettingsViewController:UIViewController, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    @IBOutlet var menuButton:UIButton!
    @IBOutlet var timerButton:UIButton!
    @IBOutlet var alertSwitch: UISwitch!
    
    @IBOutlet var pickerDate:UIDatePicker!
    @IBOutlet var viewDone:UIView!
    //@IBOutlet var viewShowHide:UIView!
    
    @IBOutlet var viewRemoveAd:UIView!
    @IBOutlet var viewRestorePur:UIView!
    @IBOutlet var lblExtras:UILabel!
    
    let userDefaults = UserDefaults.standard
    
    var product_id : NSString = "com.kraftwerking.inspirationalquotes.removeads"
    //com.app.fashionquotes.removead
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.revealViewController().panGestureRecognizer().isEnabled=false
        
        SKPaymentQueue.default().add(self)
        
        //Check if product is purchased
        let defaults = UserDefaults.standard
        if (defaults.bool(forKey: "purchased")){
            removeAds()
        }
        else {
            // print("false")
        }
        
        pickerDate.datePickerMode = UIDatePickerMode.time
        // pickerDate.locale = NSLocale(localeIdentifier: "da_DK")
        //viewShowHide.hidden=true
        self.navigationController?.isNavigationBarHidden=true
        
        if revealViewController() != nil {
            menuButton.addTarget(self.revealViewController(), action: #selector(SWRevealViewController.revealToggle(_:)), for: UIControlEvents.touchUpInside)
            revealViewController().rightViewRevealWidth = 150
            view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        let date = UserDefaults.standard.object(forKey: "time") as! Date
        pickerDate.date=date
        //let strdate = NSUserDefaults.standardUserDefaults().objectForKey("strtime") as! NSString
        alertSwitch.setOn(userDefaults.bool(forKey: "AlertsOn"), animated: true)
        
    }
    
    internal class Reachability {
        class func isConnectedToNetwork() -> Bool {
            var zeroAddress = sockaddr_in()
            zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
            zeroAddress.sin_family = sa_family_t(AF_INET)
            let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                    SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
                }
            }
            var flags = SCNetworkReachabilityFlags()
            if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
                return false
            }
            let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
            let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
            return (isReachable && !needsConnection)
        }
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
    @IBAction func selectBGTapped(_ sender:UIButton!)
    {
        let appdelegate = UIApplication.shared.delegate as! AppDelegate
        appdelegate.status=fromHome
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "GalleryVC")
        self.navigationController!.pushViewController(vc, animated: true)
        
        //                    let rvc:SWRevealViewController = self.revealViewController() as SWRevealViewController
        //                    rvc.pushFrontViewController(vc, animated: true)
    }
    
    @IBAction func alertSwitchAction(_ sender: AnyObject) {
        
        if(alertSwitch.isOn){
            print("Load NSUserDefaults and notifications")
            
            let dateFormatter = DateFormatter()
            let date = Date()
            print("Date \(date)")
            
            dateFormatter.dateFormat = "hh:mm a"
            let time=pickerDate.date
            print("Time \(time)")
            
            UserDefaults.standard.set(time, forKey: "time") //just stores alert time
            UserDefaults.standard.synchronize()
            
            UserDefaults.standard.set(true, forKey: "AlertsOn")
            UserDefaults.standard.synchronize()
            
            UserDefaults.standard.set(dateFormatter.string(from: pickerDate.date), forKey: "strtime")
            UserDefaults.standard.synchronize()
            
            UIApplication.shared.cancelAllLocalNotifications()
            
            //timerButton.setTitle(dateFormatter.stringFromDate(pickerDate.date), forState: .Normal)
            
            //date = NSDate()
            //KeyChainViewController().syncNotifications(date)
            
            let appdelegate = UIApplication.shared.delegate as! AppDelegate
            appdelegate.status=fromHome
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "KeyChainVC")
            self.navigationController!.pushViewController(vc, animated: true)
            
        }
        else {
            userDefaults.set(false, forKey: "AlertsOn")
            UIApplication.shared.cancelAllLocalNotifications()
            
        }
        userDefaults.synchronize()
        
        
    }
    
    @IBAction func purchasebtnTapped(_ sender:UIButton!)
    {
        if(Reachability.isConnectedToNetwork()) {
            if (SKPaymentQueue.canMakePayments())
            {
                let productID:NSSet = NSSet(object: product_id);
                print("productID \(productID)")
                let productsRequest:SKProductsRequest = SKProductsRequest(productIdentifiers: productID as! Set<String>);
                productsRequest.delegate = self;
                productsRequest.start();
                print("Fetching Products");
            }else{
                print("can't make purchases");
            }
        }
        else {
            let appdelegate = UIApplication.shared.delegate as! AppDelegate
            appdelegate.showMessage("Please check your network connection.")
        }
        
    }
    
    func buyProduct(_ product: SKProduct){
        print("Sending the Payment Request to Apple");
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment);
        
    }
    
    //-----------------------------------------------------------------------
    
    @IBAction func backTapped(_ sender:UIButton!)
    {
        self.navigationController?.popViewController(animated: true);
        
    }
    
    override var prefersStatusBarHidden : Bool {
        return true;
    }
    
    func productsRequest (_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        
        let count : Int = response.products.count
        if (count>0) {
            var validProducts = response.products
            let validProduct: SKProduct = response.products[0] as SKProduct
            if (validProduct.productIdentifier == self.product_id as String) {
                print(validProduct.localizedTitle)
                print(validProduct.localizedDescription)
                print(validProduct.price)
                buyProduct(validProduct);
            } else {
                print(validProduct.productIdentifier)
            }
        } else {
            print("nothing")
        }
    }
    
    func request(_ request: SKRequest!, didFailWithError error: Error) {
        print("Error Fetching product information");
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction])    {
        let defaults = UserDefaults.standard
        
        print("Received Payment Transaction Response from Apple");
        
        for transaction:AnyObject in transactions {
            if let trans:SKPaymentTransaction = transaction as? SKPaymentTransaction{
                switch trans.transactionState {
                case .purchased:
                    print("Product Purchased");
                    SKPaymentQueue.default().finishTransaction(transaction as! SKPaymentTransaction)
                    defaults.set(true , forKey: "purchased")
                    defaults.synchronize()
                    //  overlayView.hidden = true
                    removeAds()
                    
                    break;
                case .failed:
                    print("Purchased Failed");
                    SKPaymentQueue.default().finishTransaction(transaction as! SKPaymentTransaction)
                    break;
                    
                case .restored:
                    print("Already Purchased");
                    defaults.set(true , forKey: "purchased")
                    defaults.synchronize()
                    
                    let appdelegate = UIApplication.shared.delegate as! AppDelegate
                    appdelegate.showMessage("You've restored your purchases succesfully")
                    removeAds()
                    
                default:
                    break;
                }
            }
        }
        
    }
    
    func removeAds() {
        //viewRemoveAd.isHidden=true
        //viewRestorePur.isHidden=true
        //lblExtras.isHidden=true
        UserDefaults.standard.set(true, forKey: "purchased")
        UserDefaults.standard.synchronize()
    }
    
    @IBAction func restorebtnTapped(_ sender:UIButton!)
    {
        if(Reachability.isConnectedToNetwork()) {
            SKPaymentQueue.default().restoreCompletedTransactions()
        }
        else {
            let appdelegate = UIApplication.shared.delegate as! AppDelegate
            appdelegate.showMessage("Please check your network connection.")
        }
        
    }
    
}
