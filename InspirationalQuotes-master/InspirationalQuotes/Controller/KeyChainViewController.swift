//
//  KeyChainViewController.swift
//
//
//  Created by RJ Militante on 9/17/16.
//  Copyright (c) 2016 Kraftwerking. All rights reserved.
//

import UIKit
import GoogleMobileAds
import Social
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}


class KeyChainViewController: UIViewController,GADInterstitialDelegate,GADBannerViewDelegate {
    
    @IBOutlet var bannerView: GADBannerView!
    @IBOutlet var menuButton:UIButton!
    @IBOutlet var quoteButton:UIButton!
    @IBOutlet var quotetext:UITextView!
    @IBOutlet var navigation: UIView!
    
    @IBOutlet var favButton:UIButton!
    @IBOutlet var viewBottom:UIView!
    
    @IBOutlet var lblAuthor:UILabel!
    @IBOutlet var lblCurDate:UILabel!
    @IBOutlet var imgBackground: UIImageView!
    
    @IBOutlet var viewBG:UIView!
    var interstitial:GADInterstitial!
    
    var arrayQuote : NSMutableArray = []
    var arrayColor : NSArray = ["#b95557","#ffffff","#0080ef","#ffee55","#fc7a3f","#a25d85","#808080","#41723d","#f571b5","#91685b"]
    
    var idxQuote:NSInteger=0
    var idxColor:NSInteger=0
    var randomQuoteID:NSInteger=0
    var isRandom:NSInteger=0
    
    var strProductId : NSString = ""
    
    var maxLimit:NSInteger=64
    var maxNumQts:NSInteger=3085 //max quotes in db, quotes in db should be random - 1
    var maxClicks:NSInteger=4
    
    var iMinSessions = 3
    var iTryAgainSessions = 6
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        self.revealViewController().panGestureRecognizer().isEnabled=false
        
        let screenSize: CGRect = UIScreen.main.bounds
        let screenHeight = screenSize.height
        
        if screenHeight == 480.0 {
            
            viewBottom.frame=CGRect(x: 0, y: 458-88, width: 320, height: 60);
            bannerView.frame=CGRect(x: 0, y: 518-88, width: 320, height: 50);
            quotetext.frame=CGRect(x: 8 , y: 60, width: 304, height: 398-88);
        }
        
        quotetext.layer.shadowColor = UIColor.black.cgColor
        quotetext.layer.shadowOffset = CGSize(width: 2.0, height: 2.0)
        quotetext.layer.shadowOpacity = 1.0
        quotetext.layer.shadowRadius = 2.0
        quotetext.layer.backgroundColor = UIColor.clear.cgColor
        
        viewBottom.layer.shadowColor = UIColor.black.cgColor
        viewBottom.layer.shadowOffset = CGSize(width: 2.0, height: 2.0)
        viewBottom.layer.shadowOpacity = 1.0
        viewBottom.layer.shadowRadius = 2.0
        viewBottom.layer.backgroundColor = UIColor.clear.cgColor
        
        navigation.layer.shadowColor = UIColor.black.cgColor
        navigation.layer.shadowOffset = CGSize(width: 2.0, height: 2.0)
        navigation.layer.shadowOpacity = 1.0
        navigation.layer.shadowRadius = 2.0
        navigation.layer.backgroundColor = UIColor.clear.cgColor
        
        let  backgroundImg = UserDefaults.standard.integer(forKey: "idxRow") as NSInteger
        
        let str = NSString(format:"%d.jpg", backgroundImg+1)
        imgBackground.image = UIImage(named:str as String)
        
        isRandom=0;
        
        //        let defaults = NSUserDefaults.standardUserDefaults()
        //        defaults.setBool(true , forKey: "purchased")
        //
        //        defaults.synchronize()
        
        initializeAd()
        checkOnFullVersion()
        setCurrentDate()
        
        print(Utility.getPath("QuoteDB.db"))
        
        let del = (UIApplication.shared.delegate as! AppDelegate)
        let QuoteDB = FMDatabase(path: del.strDBpath as String)
        
        if (QuoteDB?.open())! {
            let querySQL = "SELECT * from Quote order by ID"
            let results:FMResultSet? = QuoteDB?.executeQuery(querySQL,
                                                            withArgumentsIn: nil)
            while results!.next() {
                var parameters = [String: AnyObject]()
                
                parameters = [
                    "ID":(results?.string(forColumn: "ID")!)! as AnyObject,
                    "QuoteText":(results?.string(forColumn: "QuoteText")!)! as AnyObject,
                    "QuoteAuthor":(results?.string(forColumn: "QuoteAuthor")!)! as AnyObject
                ]
                
                arrayQuote.add(parameters)
            }
            
            //print(arrayQuote);
            //print(arrayQuote.count);
            
            QuoteDB?.close()
            
        } else {
            print("Error opening QuoteDB")
        }
        
        let  idxQuote = UserDefaults.standard.integer(forKey: "idxQuote") as NSInteger
        print("idxQuote: " + String(idxQuote))
        let todayQtTxt = getQuoteForIdx(idxQuote) as String;
        
        quoteButton.setTitle(getQuoteForIdx(idxQuote) as String, for: UIControlState())
        print("setting quote text for the day")
        quotetext.text = todayQtTxt
        alignTextVerticalInTextView(quotetext);
        lblAuthor.text=getAuthorForIdx(idxQuote) as String
        
        var parameters = [String: AnyObject]()
        parameters=arrayQuote.object(at: idxQuote) as! [String : AnyObject]
        
        let  quoteId=parameters["ID"] as! NSString
        
        if(isFavQuoteForId(quoteId.integerValue)) {
            favButton .setImage(UIImage(named:"Dislike"), for: UIControlState())
        }
        else {
            favButton .setImage(UIImage(named:"Like"), for: UIControlState())
        }
        
        let  val = UserDefaults.standard.integer(forKey: "idxColor") as NSInteger
        idxColor=val
        UserDefaults.standard.set(val, forKey: "idxColor")
        UserDefaults.standard.synchronize()
        
        //let color1 = colorWithHexString(arrayColor.objectAtIndex(val) as! NSString as String)
        
        //      self.view.backgroundColor=color1
        
        let date = UserDefaults.standard.object(forKey: "time")
        
        if((date == nil)) {
            print("Initial load of NSUserDefaults and notifications")
            
            let dateFormatter = DateFormatter()
            let date = Date()
            print("Date \(date)")
            
            dateFormatter.dateFormat = "hh:mm a"
            let time=dateFormatter.date(from: "09:00 am")!
            print("Time \(time)")
            
            UserDefaults.standard.set(time, forKey: "time") //just stores alert time
            UserDefaults.standard.synchronize()
            
            UserDefaults.standard.set(true, forKey: "AlertsOn")
            UserDefaults.standard.synchronize()
            
            UserDefaults.standard.set("09:00 am", forKey: "strtime")
            UserDefaults.standard.synchronize()
            
            UserDefaults.standard.set(0, forKey: "interstitialAdClicks")
            UserDefaults.standard.synchronize()
            
            UIApplication.shared.cancelAllLocalNotifications()
            
            syncNotifications(date)
            
        } else {
            let alertsOn:Bool = UserDefaults.standard.bool(forKey: "AlertsOn")
            
            if(alertsOn == true) {
                let date = Date()
                print("Date \(date)")
                print("Sync notifications")
                UIApplication.shared.cancelAllLocalNotifications()
                syncNotifications(date)
            }
        }
        
        self.navigationController?.isNavigationBarHidden=true
        
        if revealViewController() != nil {
            
            menuButton.addTarget(self.revealViewController(), action: #selector(SWRevealViewController.revealToggle(_:)), for: UIControlEvents.touchUpInside)
            
            revealViewController().rightViewRevealWidth = 150
            
            //            view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        }
        
        alignTextVerticalInTextView(quotetext);
        //displayInterstitialTimed()
        
    }
    
    override var prefersStatusBarHidden : Bool {
        return true;
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
    func syncNotifications(_ stDate: Date) {
        print("BEGIN Sync notifications")
        
        let calendar: Calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        let formatter = DateFormatter()
        
        //print("maxLimit \(maxLimit)")
        //print("maxNumQts \(maxNumQts)")
        
        // set 64 notifications starting w idxQuote
        // date is the start of next 64 notifications
        var idxQuote = UserDefaults.standard.integer(forKey: "idxQuote")
        var date = stDate
        //print("idxQuote \(idxQuote)")
        //print("date \(date)")
        
        
        print("Number of notifications " + String(describing: UIApplication.shared.scheduledLocalNotifications?.count))
        
        //get alert hr min am
        let time = UserDefaults.standard.object(forKey: "time")
        let comp = (calendar as NSCalendar).components([.hour, .minute], from: time as! Date)
        let hour = comp.hour
        let minute = comp.minute
        
        //print("Hr \(hour)")
        //print("Min \(minute)")
        
        //set new alert hr min am
        date = (calendar as NSCalendar).date(bySettingHour: hour!, minute: minute!, second: 0, of: date, options: NSCalendar.Options.matchFirst)!
        //print("date \(date)")
        
        // create a corresponding local notification
        // same notification repeats daily
        
        print("Notifications being created")
        
        while UIApplication.shared.scheduledLocalNotifications?.count < maxLimit{
            let qtTxt = getQuoteForIdx(idxQuote) as String;
            
            formatter.dateStyle = DateFormatter.Style.long
            formatter.timeStyle = .medium
            
            //print(idxQuote)
            //print(qtTxt)
            //print(formatter.stringFromDate(date))
            
            let notification = UILocalNotification()
            notification.alertBody = qtTxt // text that will be displayed in the notification
            notification.alertAction = "open" // text that is displayed after "slide to..." on the lock screen - defaults to "slide to view"
            notification.fireDate=date // todo item due date (when notification will be fired)
            notification.soundName = UILocalNotificationDefaultSoundName // play default sound
            notification.userInfo = ["idxQuote": idxQuote] // assign a unique identifier to the notification so that we can retrieve it later
            //notification.repeatInterval = NSCalendarUnit.Day
            notification.applicationIconBadgeNumber =
                UIApplication.shared.applicationIconBadgeNumber + 1
            //print("notification.fireDate \(notification.fireDate)")
            //print("notification.userInfo \(notification.userInfo)")
            
            UIApplication.shared.scheduleLocalNotification(notification)
            
            if(idxQuote < maxNumQts){
                idxQuote = idxQuote + 1
            } else {
                idxQuote = 0
            }
            
            let calendar = Calendar.current
            let tomorrowDate = calendar.date(byAdding: .day, value: 1, to: date)
            
            //print("tomorrowDate \(tomorrowDate)")

            date = tomorrowDate!
        }
        print("Number of notifications " + String(describing: UIApplication.shared.scheduledLocalNotifications?.count))
        //print(UIApplication.sharedApplication().scheduledLocalNotifications)
        let arrayOfLocalNotifications = UIApplication.shared.scheduledLocalNotifications
        for row in arrayOfLocalNotifications! {
            print("userInfo \(row.userInfo)")
            print("fireDate \(row.fireDate)")
            print("alertBody \(row.alertBody)")
            
        }
        
        print("idxQuote \(idxQuote)")
        
        print("END Sync notifications")
        
    }
    
    func rateMe() {
        let neverRate = UserDefaults.standard.bool(forKey: "neverRate")
        var numLaunches = UserDefaults.standard.integer(forKey: "numLaunches") + 1
        
        if (!neverRate && (numLaunches == iMinSessions || numLaunches >= (iMinSessions + iTryAgainSessions + 1)))
        {
            showRateMe()
            numLaunches = iMinSessions + 1
        }
        UserDefaults.standard.set(numLaunches, forKey: "numLaunches")
    }
    
    func showRateMe() {
        let alert = UIAlertController(title: "Please rate us!", message: "If you enjoy using the Inspirational Quotes App, please give us a good rating!", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Rate App", style: UIAlertActionStyle.default, handler: { alertAction in
            UIApplication.shared.openURL(URL(string : "itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=id1157056025")!)
            alert.dismiss(animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: "No Thanks", style: UIAlertActionStyle.default, handler: { alertAction in
            UserDefaults.standard.set(true, forKey: "neverRate")
            alert.dismiss(animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: "Maybe Later", style: UIAlertActionStyle.default, handler: { alertAction in
            alert.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func checkOnFullVersion()  {
        let defaults = UserDefaults.standard
        
        if (defaults.bool(forKey: "purchased")){
            // Hide ads and don't show any ads
            self.bannerView.isHidden=true
            
        }
        else {
            self.bannerView.isHidden=false
            
        }
    }
    
    func setCurrentDate()  {
        let dateFormatter = DateFormatter()
        let date = Date()
        
        dateFormatter.dateFormat = "MMM dd"
        print(dateFormatter.string(from: date))
        
        lblCurDate.text=dateFormatter.string(from: date)
        
        let storeddate = UserDefaults.standard.object(forKey: "date")
        
        if((storeddate == nil)) {
            
            UserDefaults.standard.set(lblCurDate.text, forKey: "date")
            UserDefaults.standard.synchronize()
            
            UserDefaults.standard.set(0, forKey: "idxQuote")
            UserDefaults.standard.synchronize()
        }
        else {
            if(storeddate as? String==lblCurDate.text) {
                // same day
            }
            else {
                // other day
                UserDefaults.standard.set(lblCurDate.text, forKey: "date")
                UserDefaults.standard.synchronize()
                
                var val = UserDefaults.standard.integer(forKey: "idxQuote") as NSInteger
                
                if(val<maxNumQts) {
                    val=val+1
                    rateMe()
                }
                else {
                    val=0
                    rateMe()
                }
                
                UserDefaults.standard.set(val, forKey: "idxQuote")
                UserDefaults.standard.synchronize()
            }
        }
    }
    
    func getAuthorForIdx(_ idx:NSInteger)  -> String  {
        
        var parameters = [String: AnyObject]()
        parameters=arrayQuote.object(at: idx) as! [String : AnyObject]
        return parameters["QuoteAuthor"] as! String;
        
    }
    
    func getQuoteForIdx(_ idx:NSInteger)  -> String  {
        
        var parameters = [String: AnyObject]()
        parameters=arrayQuote.object(at: idx) as! [String : AnyObject]
        
        var strTemp : NSString = parameters["QuoteText"] as! String as NSString
        strTemp = NSString(format:"%@\n\n-%@", strTemp,getAuthorForIdx(idx))
        
        return strTemp as String;
    }
    
    func isFavQuoteForId(_ QuoteID:NSInteger)  -> Bool  {
        
        let del = (UIApplication.shared.delegate as! AppDelegate)
        
        let QuoteDB = FMDatabase(path: del.strDBpath as String)
        
        if (QuoteDB?.open())! {
            
            let str = NSString(format:"SELECT * from Favorites where QuoteID='%d'",QuoteID)
            
            let querySQL = str
            
            let results:FMResultSet? = QuoteDB?.executeQuery(querySQL as String,
                                                            withArgumentsIn: nil)
            
            if results!.next() {
                QuoteDB?.close()
                return true
            }
            else {
                QuoteDB?.close()
                return false
            }
        } else {
        }
        
        return true
    }
    
    func initializeAd() {
        interstitial = GADInterstitial(adUnitID: "ca-app-pub-3940256099942544/4411468910")
        //interstitial.delegate=self
        
        let req = GADRequest()
        // Request test ads on devices you specify. Your test device ID is printed to the console when
        // an ad request is made.
        req.testDevices = [ kGADSimulatorID, "2077ef9a63d2b398840261c8221a0c9b" ]
        interstitial.load(req)
        
        let req1 = GADRequest.init()
        //        req1.testDevices=[ kGADSimulatorID ];
        //  self.bannerView.frame=CGRectMake(0, 518, 320, 50);
        
        self.bannerView.adUnitID="ca-app-pub-3940256099942544/2934735716";
        self.bannerView.rootViewController = self;
        self.bannerView.delegate = self
        self.bannerView.load(req1)
    }
    
    func interstitialWillDismissScreen(_ ad: GADInterstitial!) {
        initializeAd()
    }
    
    func interstitialDidDismissScreen(_ ad: GADInterstitial!) {
        initializeAd()
    }
    
    func interstitialDidReceiveAd(_ ad: GADInterstitial!) {
        self.interstitial.present(fromRootViewController: self)
        initializeAd()
    }
    
    /* func respondToSwipeGesture(gesture: UIGestureRecognizer) {
     
     if let swipeGesture = gesture as? UISwipeGestureRecognizer {
     
     switch swipeGesture.direction {
     case UISwipeGestureRecognizerDirection.Right:
     print("Swiped right")
     //     appdelegate.showMessage("Swiped Right")
     var val = NSUserDefaults.standardUserDefaults().integerForKey("idxQuote") as NSInteger
     
     if(idxQuote>0) {
     idxQuote -= 1
     quoteButton.setTitle(getQuoteForIdx(idxQuote) as String, forState: .Normal)
     quotetext.text = getQuoteForIdx(idxQuote) as String;
     alignTextVerticalInTextView(quotetext);
     
     lblAuthor.text=getAuthorForIdx(idxQuote) as String
     
     var parameters = [String: AnyObject]()
     parameters=arrayQuote.objectAtIndex(idxQuote) as! [String : AnyObject]
     
     let  quoteId=parameters["ID"] as! NSString
     
     if(isFavQuoteForId(quoteId.integerValue)) {
     favButton .setImage(UIImage(named:"Dislike"), forState: UIControlState.Normal)
     }
     else {
     favButton .setImage(UIImage(named:"Like"), forState: UIControlState.Normal)
     }
     }
     
     case UISwipeGestureRecognizerDirection.Down:
     print("Swiped down")
     
     if(idxColor<9) {
     idxColor += 1;
     let color1 = colorWithHexString(arrayColor.objectAtIndex(idxColor) as! NSString as String)
     
     NSUserDefaults.standardUserDefaults().setInteger(idxColor, forKey: "idxColor")
     NSUserDefaults.standardUserDefaults().synchronize()
     
     //self.view.backgroundColor=color1
     
     let defaults = NSUserDefaults.standardUserDefaults()
     
     if (defaults.boolForKey("purchased")){
     // Hide ads and don't show any ads
     }
     else {
     
     if (interstitial.isReady) {
     //  interstitial.presentFromRootViewController(self)
     }
     }
     
     }
     
     //   appdelegate.showMessage("Swiped down")
     
     case UISwipeGestureRecognizerDirection.Left:
     print("Swiped left")
     //    appdelegate.showMessage("Swiped left")
     
     let  val = NSUserDefaults.standardUserDefaults().integerForKey("idxQuote") as NSInteger
     
     if(idxQuote<val) {
     if(idxQuote<arrayQuote.count) {
     idxQuote += 1
     quoteButton.setTitle(getQuoteForIdx(idxQuote) as String, forState: .Normal)
     quotetext.text = getQuoteForIdx(idxQuote) as String;
     alignTextVerticalInTextView(quotetext);
     
     lblAuthor.text=getAuthorForIdx(idxQuote) as String
     
     var parameters = [String: AnyObject]()
     parameters=arrayQuote.objectAtIndex(idxQuote) as! [String : AnyObject]
     
     let  quoteId=parameters["ID"] as! NSString
     
     if(isFavQuoteForId(quoteId.integerValue)) {
     favButton .setImage(UIImage(named:"Dislike"), forState: UIControlState.Normal)
     }
     else {
     favButton .setImage(UIImage(named:"Like"), forState: UIControlState.Normal)
     
     }
     
     }
     else {
     }
     }
     
     case UISwipeGestureRecognizerDirection.Up:
     //   appdelegate.showMessage("Swiped up")
     
     if(idxColor>0) {
     idxColor -= 1;
     let color1 = colorWithHexString(arrayColor.objectAtIndex(idxColor) as! NSString as String)
     
     //   self.view.backgroundColor=color1
     
     NSUserDefaults.standardUserDefaults().setInteger(idxColor, forKey: "idxColor")
     NSUserDefaults.standardUserDefaults().synchronize()
     
     let defaults = NSUserDefaults.standardUserDefaults()
     
     if (defaults.boolForKey("purchased")){
     // Hide ads and don't show any ads
     }
     else {
     
     if (interstitial.isReady) {
     //   interstitial.presentFromRootViewController(self)
     }
     }
     
     }
     
     print("Swiped up")
     default:
     break
     }
     }
     } */
    
    @IBAction func favQuoteTapped(_ sender:UIButton!)
    {
        //let appdelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        var parameters = [String: AnyObject]()
        
        if(isRandom==1) {
            parameters=arrayQuote.object(at: randomQuoteID) as! [String : AnyObject]
            
        }
        else {
            parameters=arrayQuote.object(at: idxQuote) as! [String : AnyObject]
            
        }
        
        let  quoteId=parameters["ID"] as! NSString
        
        if(isFavQuoteForId(quoteId.integerValue)) {
            favButton .setImage(UIImage(named:"Like"), for: UIControlState())
            // delete query
            
            let del = (UIApplication.shared.delegate as! AppDelegate)
            
            let QuoteDB = FMDatabase(path: del.strDBpath as String)
            
            if (QuoteDB?.open())! {
                let str = NSString(format:"delete from Favorites where QuoteID=%d", quoteId.integerValue)
                
                let result = QuoteDB?.executeUpdate(str as String,
                                                   withArgumentsIn: nil)
                print(result)
            }
            
            QuoteDB?.close()
        }
        else {
            favButton .setImage(UIImage(named:"Dislike"), for: UIControlState())
            // insert query
            
            let del = (UIApplication.shared.delegate as! AppDelegate)
            
            let QuoteDB = FMDatabase(path: del.strDBpath as String)
            
            if (QuoteDB?.open())! {
                let  val = UserDefaults.standard.integer(forKey: "idxColor") as NSInteger
                
                let str = NSString(format:"INSERT INTO Favorites (QuoteID,ColorIndex) VALUES (%d,%d)", quoteId.integerValue,val)
                
                let result = QuoteDB?.executeUpdate(str as String,
                                                   withArgumentsIn: nil)
                print(result)
            }
            
            QuoteDB?.close()
        }
        
    }
    
    
    
    @IBAction func favTapped(_ sender:UIButton!)
    {
        let appdelegate = UIApplication.shared.delegate as! AppDelegate
        appdelegate.status=fromHome
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "ActivityLogVC")
        self.navigationController!.pushViewController(vc, animated: true)
        
        //        let rvc:SWRevealViewController = self.revealViewController() as SWRevealViewController
        //
        //        rvc.pushFrontViewController(vc, animated: true)
        
        //        let alert = UIAlertController(title: "View", message: "Please Select an Option", preferredStyle: .ActionSheet)
        //
        //        alert.addAction(UIAlertAction(title: "Favorites", style: .Default , handler:{ (UIAlertAction)in
        //            print("Favorites")
        //
        //            let appdelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        //            appdelegate.status=fromHome
        //
        //            let storyboard = UIStoryboard(name: "Main", bundle: nil)
        //            let vc = storyboard.instantiateViewControllerWithIdentifier("ActivityLogVC")
        //            let rvc:SWRevealViewController = self.revealViewController() as SWRevealViewController
        //            rvc.pushFrontViewController(vc, animated: true)
        //        }))
        //
        //        alert.addAction(UIAlertAction(title: "Background", style: .Default , handler:{ (UIAlertAction)in
        //            print("Background")
        //
        //            let appdelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        //            appdelegate.status=fromHome
        //
        //            let storyboard = UIStoryboard(name: "Main", bundle: nil)
        //            let vc = storyboard.instantiateViewControllerWithIdentifier("GalleryVC")
        //            let rvc:SWRevealViewController = self.revealViewController() as SWRevealViewController
        //            rvc.pushFrontViewController(vc, animated: true)
        //
        //        }))
        //
        //        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler:{ (UIAlertAction)in
        //            print("Cancel")
        //
        //        }))
        //
        //        self.presentViewController(alert, animated: true, completion: {
        //            print("completion block")
        //        })
    }
    
    @IBAction func randomQuoteTapped(_ sender:UIButton!)
    {
        isRandom=1;
        
        //let MIN : UInt32 = 0
        //maxLimit
        let nQuote = UInt32(maxNumQts   )                      // Convert to Uint32
        randomQuoteID = Int(arc4random_uniform(nQuote))          // Range between 0 - nQuote
        
        print("setting random quote text")
        quotetext.text = getQuoteForIdx(randomQuoteID) as String;
        
        alignTextVerticalInTextView(quotetext);
        
        displayInterstitial()
        
    }
    
    func displayInterstitial() {
        let defaults = UserDefaults.standard

        var  clicks = UserDefaults.standard.integer(forKey: "interstitialAdClicks") as NSInteger
        
        if (defaults.bool(forKey: "purchased")){
            //no ads
        } else {
            if interstitial.isReady {
                if(clicks < maxClicks) {
                    clicks = clicks + 1
                    UserDefaults.standard.set(clicks, forKey: "interstitialAdClicks")
                    UserDefaults.standard.synchronize()
                } else {
                    clicks = 0
                    UserDefaults.standard.set(clicks, forKey: "interstitialAdClicks")
                    UserDefaults.standard.synchronize()
                    print("Ad is ready")
                    interstitial.present(fromRootViewController: self)
                }
                
            } else {
                print("Ad wasn't ready")
            }
        }

    }
    
    func displayInterstitialTimed() {
        let seconds: Double = 30
        let delayTime = DispatchTime.now() + Double(Int64(seconds * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            // show your ad
            if self.interstitial.isReady {
                print("Ad is ready")
                self.interstitial.present(fromRootViewController: self)
            } else {
                print("Ad wasn't ready")
            }
        }
        
    }
    
    
    func getRandomQuote() -> NSString
    {
        isRandom=1;
        
        //let MIN : UInt32 = 0
        //maxLimit
        let nQuote = UInt32(maxNumQts   )                      // Convert to Uint32
        randomQuoteID = Int(arc4random_uniform(nQuote))          // Range between 0 - nQuote
        
        let qtTxt = getQuoteForIdx(randomQuoteID) as String;
        
        return qtTxt as NSString
        
    }
    
    @IBAction func shareQuoteTapped(_ sender:UIButton!)
    {
        
        let shareText = NSString(format:"Sharing the quote from Inspirational Quotes App :\n%@\nby %@", (quoteButton.titleLabel?.text)!,lblAuthor.text!)
        
        let vc = UIActivityViewController(activityItems: [shareText], applicationActivities: [])
        present(vc, animated: true, completion: nil)
        
    }
    
    @IBAction func shareToFacebook(_ sender: AnyObject) {
        let shareToFacebook : SLComposeViewController = SLComposeViewController(forServiceType: SLServiceTypeFacebook)
        print("Share to facebook \(quotetext.text)")
        //shareToFacebook.setInitialText(quotetext.text)
        
        let alert: UIAlertView = UIAlertView(title: "Copy Quote", message: "Share today's quote on Facebook!\n\nYou can just PASTE for a preset message.", delegate: nil, cancelButtonTitle: "Cancel");
        alert.show()
        // Delay the dismissal by 5 seconds
        let delay = 4.0 * Double(NSEC_PER_SEC)
        let time = DispatchTime.now() + Double(Int64(delay)) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: time, execute: {
            alert.dismiss(withClickedButtonIndex: -1, animated: true)
            let pasteboard: UIPasteboard = UIPasteboard.general
            pasteboard.string = self.quotetext.text;
            print("pasteboard.string \(pasteboard.string)")
            
        })
        
        self.present(shareToFacebook, animated: true, completion: nil)
    }
    
    @IBAction func shareToTwitter(_ sender: AnyObject) {
        let shareToTwitter : SLComposeViewController = SLComposeViewController(forServiceType: SLServiceTypeTwitter)
        shareToTwitter.setInitialText(quotetext.text)
        self.present(shareToTwitter, animated: true, completion: nil)
    }
    
    @IBAction func shareButtonClicked(_ sender: AnyObject) {
        let textToShare = "Swift is awesome!  Check out this website about it!"
        
        if let myWebsite = URL(string: "http://www.codingexplorer.com/") {
            let objectsToShare = [textToShare, myWebsite] as [Any]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            
            activityVC.popoverPresentationController?.sourceView = sender as? UIView
            self.present(activityVC, animated: true, completion: nil)
        }
    }
    
    @IBAction func infoTapped(_ sender:UIButton!)
    {
        let appdelegate = UIApplication.shared.delegate as! AppDelegate
        appdelegate.status=fromHome
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "InfoViewController")
        
        self.navigationController!.pushViewController(vc, animated: true)
        //            let rvc:SWRevealViewController = self.revealViewController() as SWRevealViewController
        //            rvc.pushFrontViewController(vc, animated: true)
    }
    
    @IBAction func settingsTapped(_ sender:UIButton!)
    {
        let appdelegate = UIApplication.shared.delegate as! AppDelegate
        appdelegate.status=fromHome
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "SettingsViewController")
        self.navigationController!.pushViewController(vc, animated: true)
        
        //        let rvc:SWRevealViewController = self.revealViewController() as SWRevealViewController
        //        rvc.pushFrontViewController(vc, animated: true)
    }
}


func alignTextVerticalInTextView(_ textView :UITextView) {
    
    let size = textView.sizeThatFits(CGSize(width: textView.bounds.width, height: CGFloat(MAXFLOAT)))
    
    var topoffset = (textView.bounds.size.height - size.height * textView.zoomScale) / 2.0
    topoffset = topoffset < 0.0 ? 0.0 : topoffset
    
    textView.contentOffset = CGPoint(x: 0, y: -topoffset)
}



func colorWithHexString (_ hex:String) -> UIColor {

    var cString = hex.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).uppercased()

    if (cString.hasPrefix("#")) {
        cString = (cString as NSString).substring(from: 1)
    }
    
    if (cString.characters.count != 6) {
        return UIColor.gray
    }
    
    let rString = (cString as NSString).substring(to: 2)
    let gString = ((cString as NSString).substring(from: 2) as NSString).substring(to: 2)
    let bString = ((cString as NSString).substring(from: 4) as NSString).substring(to: 2)
    
    var r:CUnsignedInt = 0, g:CUnsignedInt = 0, b:CUnsignedInt = 0;
    Scanner(string: rString).scanHexInt32(&r)
    Scanner(string: gString).scanHexInt32(&g)
    Scanner(string: bString).scanHexInt32(&b)
    
    
    return UIColor(red: CGFloat(r) / 255.0, green: CGFloat(g) / 255.0, blue: CGFloat(b) / 255.0, alpha: CGFloat(1))
}

