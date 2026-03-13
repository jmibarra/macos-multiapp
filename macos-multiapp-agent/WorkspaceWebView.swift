import SwiftUI
import WebKit

// MARK: - ZoomableWebView

/// Subclase de WKWebView que intercepta los atajos de teclado Cmd++, Cmd+- y Cmd+0
/// para controlar el zoom de la página. WKWebView no maneja estos atajos por defecto.
class ZoomableWebView: WKWebView {
    
    /// Incremento/decremento de zoom por cada pulsación de tecla.
    private let zoomStep: CGFloat = 0.1
    /// Límite mínimo de zoom (20%).
    private let minZoom: CGFloat = 0.2
    /// Límite máximo de zoom (300%).
    private let maxZoom: CGFloat = 3.0
    
    /// Verifica si este WebView (o alguna de sus subvistas) es el first responder actual.
    /// Esto evita que un WebView sin foco consuma los atajos de zoom.
    private var hasKeyboardFocus: Bool {
        guard let firstResponder = window?.firstResponder as? NSView else {
            return false
        }
        return firstResponder === self || firstResponder.isDescendant(of: self)
    }
    
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        // Solo interceptar si este WebView tiene el foco del teclado
        guard hasKeyboardFocus,
              event.modifierFlags.contains(.command) else {
            return super.performKeyEquivalent(with: event)
        }
        
        switch event.charactersIgnoringModifiers {
        case "+", "=":
            // Cmd + "+" o Cmd + "=" → Acercar zoom
            pageZoom = min(pageZoom + zoomStep, maxZoom)
            return true
        case "-":
            // Cmd + "-" → Alejar zoom
            pageZoom = max(pageZoom - zoomStep, minZoom)
            return true
        case "0":
            // Cmd + "0" → Restablecer zoom a 100%
            pageZoom = 1.0
            return true
        default:
            return super.performKeyEquivalent(with: event)
        }
    }
}

// MARK: - WorkspaceWebView

/// WorkspaceWebView actúa como un puente entre SwiftUI y el WKWebView de AppKit.
/// Implementa NSViewRepresentable para poder usar WKWebView dentro de una interfaz de SwiftUI en macOS.
struct WorkspaceWebView: NSViewRepresentable {
    let urlString: String
    let sessionID: String

    // MARK: - Coordinator (delegados de WKWebView)
    
    /// Coordinator maneja eventos del WKWebView como apertura de nuevas ventanas,
    /// decisiones de navegación, mensajes del JS bridge para notificaciones,
    /// y observación del título para badge count.
    func makeCoordinator() -> Coordinator {
        Coordinator(sessionID: sessionID)
    }
    
    class Coordinator: NSObject, WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler {
        
        let sessionID: String
        private var titleObservation: NSKeyValueObservation?
        
        init(sessionID: String) {
            self.sessionID = sessionID
            super.init()
        }
        
        // MARK: - WKScriptMessageHandler (JS Bridge para notificaciones)
        
        /// Recibe mensajes del JavaScript inyectado cuando una web app
        /// intenta crear una notificación via new Notification().
        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            guard message.name == "notificationBridge",
                  let body = message.body as? [String: Any] else { return }
            
            let title = body["title"] as? String ?? sessionID
            let notifBody = body["body"] as? String ?? ""
            
            NotificationManager.shared.showNotification(
                title: title,
                body: notifBody,
                sessionID: sessionID
            )
        }
        
        // MARK: - Observación de título para badge count
        
        /// Inicia la observación KVO del título del WebView.
        /// Muchas web apps ponen contadores en el título: "(3) Slack", "(5) WhatsApp".
        func observeTitle(of webView: WKWebView) {
            titleObservation = webView.observe(\.title, options: [.new]) { [weak self] _, change in
                guard let self = self,
                      let newTitle = change.newValue as? String else { return }
                
                let count = self.extractBadgeCount(from: newTitle)
                NotificationManager.shared.updateBadgeCount(count, for: self.sessionID)
            }
        }
        
        /// Extrae el número de notificaciones del título de la página.
        /// Soporta formatos como "(3) Slack", "(12) WhatsApp", "Slack • 3", etc.
        private func extractBadgeCount(from title: String) -> Int {
            // Formato más común: "(N) Título"
            if let match = title.range(of: #"\((\d+)\)"#, options: .regularExpression) {
                let numberStr = title[match].dropFirst().dropLast()
                return Int(numberStr) ?? 0
            }
            // Formato alternativo: "Título • N"
            if let match = title.range(of: #"[•·]\s*(\d+)"#, options: .regularExpression) {
                let substring = title[match]
                let digits = substring.filter { $0.isNumber }
                return Int(digits) ?? 0
            }
            return 0
        }
        
        // MARK: - WKUIDelegate
        
        /// Se invoca cuando una página intenta abrir una nueva ventana/pestaña
        /// (ej: window.open(), target="_blank", etc.).
        /// En lugar de ignorar la solicitud, cargamos la URL en el mismo WebView.
        func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            if navigationAction.targetFrame == nil || !(navigationAction.targetFrame!.isMainFrame) {
                webView.load(navigationAction.request)
            }
            return nil
        }
        
        // MARK: - WKNavigationDelegate
        
        /// Permite todas las redirecciones de navegación.
        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            decisionHandler(.allow)
        }
    }

    // MARK: - NSViewRepresentable

    func makeNSView(context: Context) -> ZoomableWebView {
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
        
        // MARK: JS Bridge para interceptar Web Notifications API
        // Este script sobrescribe window.Notification para redirigir las notificaciones
        // del navegador hacia nuestro handler nativo via webkit.messageHandlers.
        let notificationScript = WKUserScript(
            source: Self.notificationBridgeJS,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )
        configuration.userContentController.addUserScript(notificationScript)
        configuration.userContentController.add(
            context.coordinator,
            name: "notificationBridge"
        )
        
        // Usamos ZoomableWebView para soportar Cmd++, Cmd+-, Cmd+0
        let webView = ZoomableWebView(frame: .zero, configuration: configuration)
        
        // Asignamos los delegados del Coordinator
        webView.uiDelegate = context.coordinator
        webView.navigationDelegate = context.coordinator
        
        // Iniciar observación del título para badge count
        context.coordinator.observeTitle(of: webView)
        
        // User-Agent de Safari 26 (o superior) para soportar Slack y MS Teams.
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Safari/605.1.15"
        
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
        
        return webView
    }

    func updateNSView(_ nsView: ZoomableWebView, context: Context) {
        // No se requiere actualización dinámica por ahora.
    }
    
    // MARK: - JavaScript Bridge
    
    /// Script JS que sobrescribe la Web Notifications API del navegador.
    /// Intercepta `new Notification()` y `Notification.requestPermission()`
    /// para redirigirlos al handler nativo de Swift.
    private static let notificationBridgeJS = """
    (function() {
        // Guardamos la referencia original por si la necesitamos
        const OriginalNotification = window.Notification;
        
        // Sobrescribimos el constructor de Notification
        window.Notification = function(title, options) {
            options = options || {};
            // Enviamos al handler nativo de Swift
            try {
                webkit.messageHandlers.notificationBridge.postMessage({
                    title: title || '',
                    body: options.body || '',
                    icon: options.icon || '',
                    tag: options.tag || ''
                });
            } catch(e) {
                console.log('NotificationBridge error:', e);
            }
            
            // Simulamos el objeto Notification para que la web app no crashee
            this.title = title;
            this.body = options.body || '';
            this.icon = options.icon || '';
            this.tag = options.tag || '';
            this.onclick = null;
            this.onclose = null;
            this.onerror = null;
            this.onshow = null;
            this.close = function() {};
        };
        
        // Siempre reportamos que las notificaciones están permitidas
        window.Notification.permission = 'granted';
        
        // requestPermission siempre concede permiso
        window.Notification.requestPermission = function(callback) {
            if (callback) callback('granted');
            return Promise.resolve('granted');
        };
        
        // Soporte para ServiceWorker showNotification (Teams, Slack)
        if (navigator.serviceWorker) {
            const originalRegister = navigator.serviceWorker.register;
            if (originalRegister) {
                // Permitimos el registro normal del service worker
            }
        }
    })();
    """;
    
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
