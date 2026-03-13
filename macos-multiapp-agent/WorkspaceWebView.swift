import SwiftUI
import WebKit

/// WorkspaceWebView actúa como un puente entre SwiftUI y el WKWebView de AppKit.
/// Implementa NSViewRepresentable para poder usar WKWebView dentro de una interfaz de SwiftUI en macOS.
struct WorkspaceWebView: NSViewRepresentable {
    let urlString: String
    let sessionID: String

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
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        
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
