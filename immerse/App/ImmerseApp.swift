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
        .defaultSize(CGSize(width: 100, height: 100))
        
        ImmersiveSpace(id: "Environment") {
            //Struct with the RealityView
            CustomScreenView()
        }
        .immersionStyle(selection: $immersionStyle, in: .full)
        
    }
}
