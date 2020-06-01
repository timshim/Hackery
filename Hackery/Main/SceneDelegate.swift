//
//  SceneDelegate.swift
//  Hackery
//
//  Created by Tim Shim on 6/10/19.
//  Copyright © 2019 Tim Shim. All rights reserved.
//

import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        let feedView = FeedView().environmentObject(FeedController())
        
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: feedView)
            self.window = window
            window.makeKeyAndVisible()
        }
    }

}
