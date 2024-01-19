//
//  TikTokCloneApp.swift
//  TikTokClone
//
//  Created by Stephan Dowless on 10/6/23.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct EnvironmentApp: App {
    //Select immersionStyle
    @State private var immersionStyle: ImmersionStyle = .full
    var body: some Scene {
        // StartView WindowGroup is completely unused currently, you can remove it and nothing will change (perhaps edit the plist to have the window display properly)
        WindowGroup {
            //Starting Window to control entry in the ImmersiveSpace
            StartView()
        }
        
        ImmersiveSpace(id: "Environment") {
            //struct with the RealityView
            EnvironmentRV()
        }
        .immersionStyle(selection: $immersionStyle, in: .full)
        
    }
}
