import Foundation
import UserNotifications
import AppKit

/// Gestor centralizado de notificaciones nativas de macOS.
/// Usa UNUserNotificationCenter para publicar notificaciones con sonido, badge y previsualización.
/// También mantiene el badge del Dock actualizado sumando contadores de todas las web views.
class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    
    static let shared = NotificationManager()
    
    /// Contadores de notificaciones por sessionID (ej: "slack" → 3, "whatsapp" → 5)
    private var badgeCounts: [String: Int] = [:]
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    // MARK: - Permisos
    
    /// Solicita permisos de notificación al usuario.
    /// Debe llamarse al iniciar la app.
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, error in
            if let error = error {
                print("❌ Error solicitando permisos de notificación: \(error)")
            }
            print("🔔 Permisos de notificación: \(granted ? "concedidos" : "denegados")")
        }
    }
    
    // MARK: - Publicar Notificaciones
    
    /// Muestra una notificación nativa de macOS.
    /// - Parameters:
    ///   - title: Título de la notificación (nombre del servicio o remitente)
    ///   - body: Cuerpo/contenido del mensaje
    ///   - sessionID: Identificador de la sesión que originó la notificación
    func showNotification(title: String, body: String, sessionID: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        
        // Identificador único para la categoría, permite agrupar por servicio
        content.threadIdentifier = sessionID
        
        // Crear la request con un ID único
        let requestID = "\(sessionID)-\(UUID().uuidString)"
        let request = UNNotificationRequest(
            identifier: requestID,
            content: content,
            trigger: nil // Entrega inmediata
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error al publicar notificación: \(error)")
            }
        }
    }
    
    // MARK: - Badge del Dock
    
    /// Actualiza el contador de badges para un sessionID específico.
    /// Recalcula el total y actualiza el badge del Dock.
    /// - Parameters:
    ///   - count: Número de notificaciones pendientes para esta sesión
    ///   - sessionID: Identificador de la sesión
    func updateBadgeCount(_ count: Int, for sessionID: String) {
        badgeCounts[sessionID] = count
        
        let totalCount = badgeCounts.values.reduce(0, +)
        
        DispatchQueue.main.async {
            if totalCount > 0 {
                NSApp.dockTile.badgeLabel = "\(totalCount)"
            } else {
                NSApp.dockTile.badgeLabel = nil
            }
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    /// Permite que las notificaciones se muestren incluso cuando la app está en primer plano.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
    
    /// Maneja la interacción del usuario con una notificación (ej: click en ella).
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Traer la app al frente cuando el usuario clickea la notificación
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
        }
        completionHandler()
    }
}
