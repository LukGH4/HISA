//
//  AppDelegate.swift
//  HISA
//
//  Created by Hoyeon Kang on 11/16/24.
//

import UIKit
import FirebaseCore
import FirebaseAuth

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        window?.overrideUserInterfaceStyle = .light
        // Override point for customization after application launch.
        if let currentUser = Auth.auth().currentUser {
                    navigateToMainScreen(userId: currentUser.uid)
                } else {
                    navigateToLoginScreen()
                }
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    func navigateToMainScreen(userId: String) {
            if let tabBarController = UIStoryboard(name: "Main", bundle: nil)
                .instantiateViewController(withIdentifier: "MainTabBarController") as? UITabBarController {
                tabBarController.selectedIndex = 0

                if let window = self.window {
                    window.rootViewController = tabBarController
                    window.makeKeyAndVisible()
                }
            }
        }

        func navigateToLoginScreen() {
            if let loginVC = UIStoryboard(name: "Main", bundle: nil)
                .instantiateViewController(withIdentifier: "LoginViewController") as? LoginViewController {
                if let window = self.window {
                    window.rootViewController = loginVC
                    window.makeKeyAndVisible()
                }
            }
        }
    
    


}
