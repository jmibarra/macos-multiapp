//
//  macos_multiapp_agentApp.swift
//  macos-multiapp-agent
//
//  Created by Juan Ibarra on 12/03/2026.
//

import SwiftUI

@main
struct macos_multiapp_agentApp: App {
    
    init() {
        // Solicitar permisos de notificación al iniciar la app.
        // Esto dispara el diálogo nativo de macOS para que el usuario autorice
        // alertas, sonidos y badges.
        NotificationManager.shared.requestPermission()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
