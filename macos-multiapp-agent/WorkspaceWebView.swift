import SwiftUI
import WebKit

/// WorkspaceWebView actúa como un puente entre SwiftUI y el WKWebView de AppKit.
/// Implementa NSViewRepresentable para poder usar WKWebView dentro de una interfaz de SwiftUI en macOS.
struct WorkspaceWebView: NSViewRepresentable {
    let urlString: String
    let sessionID: String

    // MARK: - Coordinator (delegados de WKWebView)
    
    /// Coordinator maneja eventos del WKWebView como apertura de nuevas ventanas
    /// y decisiones de navegación. Esto es clave para que servicios como Slack
    /// funcionen, ya que intentan abrir enlaces en nuevas pestañas.
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, WKUIDelegate, WKNavigationDelegate {
        
        /// Se invoca cuando una página intenta abrir una nueva ventana/pestaña
        /// (ej: window.open(), target="_blank", etc.).
        /// En lugar de ignorar la solicitud, cargamos la URL en el mismo WebView.
        func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            // Si el frame destino es nil, significa que quiere abrir nueva ventana.
            if navigationAction.targetFrame == nil || !(navigationAction.targetFrame!.isMainFrame) {
                webView.load(navigationAction.request)
            }
            // Retornamos nil para indicar que NO creamos un WKWebView nuevo.
            return nil
        }
        
        /// Maneja decisiones de navegación para permitir redirecciones normales.
        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            decisionHandler(.allow)
        }
    }

    // MARK: - NSViewRepresentable

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        
        // Aislamiento de Sesiones:
        // El inicializador identifier permite crear DataStores independientes.
        // Esto separa cookies, caché y almacenamiento local por cada sessionID.
        if let sessionUUID = deterministicUUID(from: sessionID) {
            let dataStore = WKWebsiteDataStore(forIdentifier: sessionUUID)
            configuration.websiteDataStore = dataStore
        }
        
        // Optimizaciones de rendimiento y comportamiento
        configuration.allowsAirPlayForMediaPlayback = false
        
        // Permitimos JavaScript para abrir ventanas sin interacción del usuario.
        // Necesario para flujos de autenticación de Slack, Teams, etc.
        let preferences = WKPreferences()
        preferences.javaScriptCanOpenWindowsAutomatically = true
        configuration.preferences = preferences
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        
        // Asignamos los delegados del Coordinator
        webView.uiDelegate = context.coordinator
        webView.navigationDelegate = context.coordinator
        
        // User-Agent de Safari 26 (o superior) para soportar Slack y MS Teams.
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Safari/605.1.15"
        
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
        
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        // No se requiere actualización dinámica por ahora.
    }
    
    // MARK: - Utilidades
    
    /// Genera un UUID determinista a partir de un string de sesión.
    /// Esto asegura que el mismo sessionID siempre acceda al mismo DataStore persistente.
    private func deterministicUUID(from string: String) -> UUID? {
        if let uuid = UUID(uuidString: string) {
            return uuid
        }
        
        // Generamos un UUID basado en el hash del string para consistencia.
        var hash = abs(string.hashValue)
        let bytes = withUnsafeBytes(of: &hash) { Array($0) }
        
        var uuidBytes: [UInt8] = Array(repeating: 0, count: 16)
        for (i, byte) in bytes.enumerated() {
            uuidBytes[i % 16] = byte
        }
        
        // Seteamos bits de versión 4 (aunque sea determinista) para validez.
        uuidBytes[6] = (uuidBytes[6] & 0x0f) | 0x40
        uuidBytes[8] = (uuidBytes[8] & 0x3f) | 0x80
        
        return UUID(uuid: (uuidBytes[0], uuidBytes[1], uuidBytes[2], uuidBytes[3],
                           uuidBytes[4], uuidBytes[5], uuidBytes[6], uuidBytes[7],
                           uuidBytes[8], uuidBytes[9], uuidBytes[10], uuidBytes[11],
                           uuidBytes[12], uuidBytes[13], uuidBytes[14], uuidBytes[15]))
    }
}
