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

class AppDependency: NSObject {
    static var shared = AppDependency()
    private var launchRouter: LaunchRouting?

    var interfaceImageDownloader: ImageDownloader = ImageDownloader()

    func startApp(with window: UIWindow) {
        let launchRouter = RootBuilder(dependency: AppComponent()).build()
        self.launchRouter = launchRouter
        launchRouter.launchFromWindow(window)
    }
    
    
  
}
