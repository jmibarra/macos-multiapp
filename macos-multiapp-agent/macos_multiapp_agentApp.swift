//
//  macos_multiapp_agentApp.swift
//  macos-multiapp-agent
//
//  Created by Juan Ibarra on 12/03/2026.
//

import SwiftUI

@main
struct macos_multiapp_agentApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
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
        
        // Un ícono en la barra de menú que permite al usuario gestionar la app
        // cuando esta corre en segundo plano sin ventanas activas.
        MenuBarExtra("Workspace", systemImage: "macwindow.badge.plus") {
            Button("Mostrar Ventana Principal") {
                appDelegate.showMainWindow()
            }
            Divider()
            Button("Cerrar Aplicación") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}
