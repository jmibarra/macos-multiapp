import SwiftUI
import AppKit

// MARK: - App Delegate
class AppDelegate: NSObject, NSApplicationDelegate {
    
    // Se ejecuta cuando el usuario hace clic en el icono del Dock
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            showMainWindow()
        }
        // Retornar false previene que SwiftUI (o macOS) intente crear una nueva 
        // ventana de WindowGroup de forma automática cuando no hay ninguna visible.
        return false
    }
    
    // Muestra la ventana principal si estaba oculta
    func showMainWindow() {
        for window in NSApplication.shared.windows {
            // Buscamos la ventana principal de SwiftUI
            if window.className == "SwiftUI.AppKitWindow" {
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
                break
            }
        }
    }
}

// MARK: - Window Accessor
// Permite acceder a la ventana subyacente de SwiftUI y modificar su comportamiento
struct WindowAccessor: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        
        // El view a veces no tiene la ventana inmediatamente, así que esperamos un ciclo
        DispatchQueue.main.async {
            if let window = view.window {
                window.delegate = context.coordinator
            }
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, NSWindowDelegate {
        // Intercepta el evento de cerrar la ventana (botón rojo)
        func windowShouldClose(_ sender: NSWindow) -> Bool {
            // En vez de cerrar y destruir la ventana (lo que termina sesiones),
            // simplemente la ocultamos. Así la app queda en segundo plano.
            sender.orderOut(nil)
            return false
        }
    }
}
