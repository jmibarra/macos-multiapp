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
        
        Window("Configuración", id: "settings") {
            SettingsView()
        }
        .defaultSize(width: 450, height: 280)
        .windowResizability(.contentSize)
        
        // Un ícono en la barra de menú que permite al usuario gestionar la app
        // cuando esta corre en segundo plano sin ventanas activas.
        MenuBarExtra("Workspace", systemImage: "macwindow.badge.plus") {
            Button("Mostrar Ventana Principal") {
                appDelegate.showMainWindow()
            }
            OpenSettingsButton()
            Divider()
            Button("Cerrar Aplicación") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}

struct OpenSettingsButton: View {
    @Environment(\.openWindow) var openWindow
    
    var body: some View {
        Button("Configuración...") {
            openWindow(id: "settings")
        }
    }
}

// MARK: - Settings Views

struct SettingsView: View {
    var body: some View {
        TabView {
            InfoSettingsView()
                .tabItem {
                    Label("Info", systemImage: "info.circle")
                }
            
            // Espacio futuro para agregar pestañas como:
            // - Tema (Claro/Oscuro/Sistema)
            // - Idioma
            // - Opciones Avanzadas
        }
        .frame(width: 450, height: 280)
    }
}

struct InfoSettingsView: View {
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Desconocida"
    }
    
    var appBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Desconocido"
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "macwindow.badge.plus")
                .font(.system(size: 56))
                .foregroundColor(.accentColor)
                .padding(.top, 10)
            
            VStack(spacing: 4) {
                Text("macOS MultiApp Workspace")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Versión \(appVersion) (\(appBuild))")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Divider()
                .padding(.horizontal, 40)
            
            VStack(spacing: 12) {
                Text("Desarrollado en Swift & SwiftUI para macOS.")
                    .font(.callout)
                    .foregroundColor(.secondary)
                
                Button(action: {
                    if let url = URL(string: "https://github.com/jmibarra/macos-multiapp/issues") {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    Label("Reportar Problema o Sugerencia", systemImage: "ladybug")
                }
                .buttonStyle(.link)
            }
            
            Spacer()
        }
        .padding()
    }
}
