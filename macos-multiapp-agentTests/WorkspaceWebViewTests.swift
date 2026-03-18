import Foundation
import Testing
import WebKit
@testable import WorkHub

@Suite("WorkspaceWebView Coordinator Tests")
struct WorkspaceWebViewTests {
    
    // Mock class para simular un WKScriptMessage ya que en testing no podemos
    // invocar la inyección de JS de manera tan fácil sin una vista activa.
    class MockScriptMessage: WKScriptMessage {
        var mockName: String
        var mockBody: Any
        
        init(name: String, body: Any) {
            self.mockName = name
            self.mockBody = body
            super.init()
        }
        
        override var name: String { return mockName }
        override var body: Any { return mockBody }
    }
    
    @Test("Coordinator Handles cmdClickBridge Message")
    func testCmdClickBridgeMessage() async throws {
        // En una prueba unitaria, simplemente validamos que la clase
        // Coordinator existe y se inicializa correctamente y que el manejador script funciona sin crashear.
        let coordinator = WorkspaceWebView.Coordinator(sessionID: "test-session")
        let controller = WKUserContentController()
        
        let message = MockScriptMessage(name: "cmdClickBridge", body: "https://www.apple.com")
        
        // Llamar la función que procesa el mensaje de swift/JS bridge.
        // Dado que llama a NSWorkspace.shared.open, esto podría intentar abrir el navegador, 
        // lo que es aceptable durante las pruebas que se ejecutan a nivel de SO local en este contexto limitado.
        coordinator.userContentController(controller, didReceive: message)
        
        // Solo verificamos completitud sin excepciones, que es un test de humo válido en este caso.
        #expect(coordinator.sessionID == "test-session")
    }
}
