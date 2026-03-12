import SwiftUI
import WebKit

// El modelo WorkspaceWebView actúa como un puente entre SwiftUI y el WKWebView de UIKit/AppKit.
// Implementamos NSViewRepresentable para poder usar WKWebView dentro de una interfaz de SwiftUI en macOS.
struct WorkspaceWebView: NSViewRepresentable {
    let urlString: String
    let sessionID: String

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        
        // El inicializador init(forIdentifier:) está disponible a partir de macOS 14.0.
        // Crea un DataStore persistente basado en un identificador único (UUID).
        let sessionUUID = deterministicUUID(from: sessionID)
        let dataStore = WKWebsiteDataStore(forIdentifier: sessionUUID)
        configuration.websiteDataStore = dataStore
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
        
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
        
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
    }
    
    // Genera un UUID determinista a partir de un string de sesión.
    private func deterministicUUID(from string: String) -> UUID {
        if let uuid = UUID(uuidString: string) {
            return uuid
        }
        
        // Si el sessionID no es un UUID, generamos uno basado en el hash del string.
        var hash = abs(string.hashValue)
        let bytes = withUnsafeBytes(of: &hash) { Array($0) }
        
        // Rellenamos con ceros para completar el formato de UUID
        var uuidBytes: [UInt8] = Array(repeating: 0, count: 16)
        for (i, byte) in bytes.enumerated() {
            uuidBytes[i % 16] = byte
        }
        
        // Marcamos como UUID versión 4 (aleatorio) para cumplir con el estándar,
        // aunque sea derivado de un hash.
        uuidBytes[6] = (uuidBytes[6] & 0x0f) | 0x40
        uuidBytes[8] = (uuidBytes[8] & 0x3f) | 0x80
        
        return UUID(uuid: (uuidBytes[0], uuidBytes[1], uuidBytes[2], uuidBytes[3],
                           uuidBytes[4], uuidBytes[5], uuidBytes[6], uuidBytes[7],
                           uuidBytes[8], uuidBytes[9], uuidBytes[10], uuidBytes[11],
                           uuidBytes[12], uuidBytes[13], uuidBytes[14], uuidBytes[15]))
    }
}
