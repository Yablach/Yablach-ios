//
//  AppDependency.swift
//  Chan
//
//  Created by Mikhail Malyshev on 08.09.2018.
//  Copyright © 2018 Mikhail Malyshev. All rights reserved.
//

import UIKit
import Moya
import RIBs
import AlamofireImage
import RxSwift
import Firebase
import FirebaseDatabase
import Fabric
import Crashlytics
import AVKit
import AppCenter
import AppCenterAnalytics
import AppCenterCrashes
import AppCenter
import GoogleMobileAds


enum AppAction {
    case willActive
}

class AppDependency: NSObject {
    
    let disposeBag = DisposeBag()
    
    static var shared = AppDependency()
    private var launchRouter: LaunchRouting?
    
    
    private let _appAction: PublishSubject<AppAction> = PublishSubject()
    var appAction: Observable<AppAction> {
        return self._appAction.asObservable()
    }

    var interfaceImageDownloader: ImageDownloader = ImageDownloader()

    func startApp(with window: UIWindow) {

        self.commonSetup()
        
        let launchRouter = RootBuilder(dependency: AppComponent()).build()
        self.launchRouter = launchRouter
        launchRouter.launchFromWindow(window)
        
        self.prepareUIElements()
    }
    
    func commonSetup() {
        
        ConfigManager.shared.start()
        
        self.setupMainAppearance()
        self.setupFirebase()
        
        FirebaseManager.setup()
      
        Fabric.with([Crashlytics.self])
        MSAppCenter.start("66600e45-de1a-45c9-a0f7-10210663c7ef", withServices: [
            MSAnalytics.self,
            MSCrashes.self
        ])

        
        CoreDataStore.shared.setup()
        self.initializeData()
        
        do {
            if #available(iOS 10.0, *) {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback, mode: AVAudioSession.Mode.moviePlayback, options: AVAudioSession.CategoryOptions.allowBluetoothA2DP)
            } else {
//                try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
                
            }
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print(error)
        }
        
//        let copyOrigianlText = UIMenuItem(title: "Скопировать оригинал", action: Selector(("copyOrigianlText")))
//        let copyText = UIMenuItem(title: "Скопировать", action: Selector(("copyText")))
        let copyLink = UIMenuItem(title: "copy_link".localized, action: Selector(("copyLink")))
        let makeScreenshot = UIMenuItem(title: "screenshot".localized, action: Selector(("screenshot")))
        let openBrowser = UIMenuItem(title: "open_in_browser".localized, action: Selector(("openBrowser")))


        UIMenuController.shared.menuItems = [openBrowser, copyLink, makeScreenshot]
        UIMenuController.shared.update()
        UIMenuController.shared.setMenuVisible(true, animated: true)
        
        UIApplication.shared.isIdleTimerDisabled = true
        
        
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        
        HiddenThreadManager.shared.clear()
        
        
    }
    
    func prepareUIElements() {
        StatusbarBackground.shared.changeBG()
    }

    
    func setupMainAppearance() {
        UIBarButtonItem.appearance().tintColor = .main
        
    }
    
    func setupFirebase() {
//      #if RELEASE
        FirebaseApp.configure()
        Database.database().isPersistenceEnabled = true
//      #endif
    }
    
    func updateAction(app action: AppAction) {
        self._appAction.on(.next(action))
    }
    
    func initializeData() {
        ImageboardService.instance().reload()
    }
  
}
