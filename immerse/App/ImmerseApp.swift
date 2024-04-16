//
//  ImmerseApp.swift
//  immerse
//
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let sceneConfig = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        sceneConfig.delegateClass = SceneDelegate.self
        return sceneConfig
    }
}

class SceneDelegate: NSObject, UIWindowSceneDelegate {
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let preferences = UIWindowScene.GeometryPreferences.Vision()
        preferences.resizingRestrictions = UIWindowScene.ResizingRestrictions.uniform
        windowScene.requestGeometryUpdate(preferences)
    }
}

@main
struct ImmerseApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    private let authService = AuthService()
    private let userService = UserService()
    
    var body: some Scene {
        WindowGroup {
            ContentView(authService: authService, userService: userService)
        }
        .defaultSize(CGSize(width: 2400, height: 1350))
    }
}
