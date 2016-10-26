//
//  AppDelegate.swift
//  InspirationalQuotes
//
//  Created by RJ Militante on 9/17/16.
//  Copyright (c) 2016 Kraftwerking. All rights reserved.
//

import UIKit

@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var status : Int?
    var strDBpath : NSString = ""

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        Utility.copyFile("QuoteDB.db")
        
        strDBpath=Utility.getPath("QuoteDB.db") as NSString
        
        let userNotificationTypes: UIUserNotificationType = [.alert, .badge, .sound]
        let settings = UIUserNotificationSettings(types: userNotificationTypes, categories: nil)
        application.registerUserNotificationSettings(settings)
        application.registerForRemoteNotifications()
        
        // Override point for customization after application launch.
        UIApplication.shared.statusBarStyle = .lightContent
        
        status=fromHome
        
        var storyboard:UIStoryboard!
   
        storyboard = UIStoryboard(name:"Main", bundle: nil);

         self.window?.rootViewController=storyboard.instantiateInitialViewController()

        return true
    }

    func sharedInstance() -> AppDelegate{
        return UIApplication.shared.delegate as! AppDelegate
    }
    
    func showMessage(_ msg: NSString) {
        
        let alert = UIAlertView()
        alert.title = "Inspirational Quotes"
        alert.message = msg as String
        alert.addButton(withTitle: "Ok")
        alert.show()
    }
    
    func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
      
        let state=application.applicationState as UIApplicationState;
        
        if (state==UIApplicationState.active) {
            UIApplication.shared.applicationIconBadgeNumber=0

            // Show notification
            
            /*let alert = UIAlertView()
            alert.title = "Quotes"
            alert.message = "Your daily quote has arrived" as String
            alert.addButtonWithTitle("Ok")
            alert.show()*/
            
        } else {
            var storyboard:UIStoryboard!
            
            storyboard = UIStoryboard(name:"Main", bundle: nil);
            
            self.window?.rootViewController=storyboard.instantiateInitialViewController()

            
        }
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        UIApplication.shared.applicationIconBadgeNumber=0
        
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

