//
//  ImmerseApp.swift
//  immerse
//
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
struct ImmerseApp: App {
    //Select immersionStyle
    @State private var immersionStyle: ImmersionStyle = .full
    var body: some Scene {

        WindowGroup {
            //Starting Window to control entry in the ImmersiveSpace
            StartView()
        }
        
        ImmersiveSpace(id: "Environment") {
            //Struct with the RealityView
            EnvironmentRV()
        }
        .immersionStyle(selection: $immersionStyle, in: .full)
        
    }
}
