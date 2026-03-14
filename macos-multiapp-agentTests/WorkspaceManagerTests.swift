import Foundation
import Testing
@testable import WorkHub

@Suite("Workspace Manager Tests")
struct WorkspaceManagerTests {
    
    // Configura un entorno limpio temporal usando UserDefaults suite
    func createCleanManager() -> WorkspaceManager {
        let domain = "TestDomain-\(UUID().uuidString)"
        UserDefaults().removePersistentDomain(forName: domain)
        return WorkspaceManager()
    }
    
    @Test("WorkspaceManager Creates Default Tabs on Load")
    func defaultTabsCreation() {
        // En una ejecución limpia, siempre se deberían crear pestañas por default.
        // Simularemos borrando los datos estándar. Para una app real de SwiftUI idealmente inyectaríamos el UserDefaults, pero aquí borramos la clave usada.
        UserDefaults.standard.removeObject(forKey: "WorkspaceTabs")
        
        let manager = WorkspaceManager()
        
        #expect(manager.tabs.count == 2)
        #expect(manager.tabs[0].name == "Comunicacion")
        #expect(manager.tabs[1].name == "Tareas")
        
        // Verifica los servicios por omisión
        #expect(manager.tabs[0].services.count == 2)
        #expect(manager.tabs[0].services[0].service == .whatsapp)
        #expect(manager.tabs[0].services[1].service == .slack)
    }
    
    @Test("WorkspaceManager Add Tab")
    func addTab() {
        let manager = createCleanManager()
        let initialCount = manager.tabs.count
        
        manager.addTab(name: "Nueva Pestaña", layout: .single, services: [.googleCalendar])
        
        #expect(manager.tabs.count == initialCount + 1)
        #expect(manager.tabs.last?.name == "Nueva Pestaña")
        #expect(manager.tabs.last?.layout == .single)
        #expect(manager.tabs.last?.services.count == 1)
        #expect(manager.tabs.last?.services.first?.service == .googleCalendar)
        #expect(manager.tabs.last?.services.first?.sessionID.contains("gcalendar") == true)
    }
    
    @Test("WorkspaceManager Remove Tab By Index")
    func removeTabIndex() {
        let manager = createCleanManager()
        
        // Aseguramos que hay al menos 2
        manager.tabs = [
            WorkspaceTab(name: "A", layout: .single, services: []),
            WorkspaceTab(name: "B", layout: .single, services: [])
        ]
        
        manager.removeTab(at: 0)
        
        #expect(manager.tabs.count == 1)
        #expect(manager.tabs.first?.name == "B")
    }
    
    @Test("WorkspaceManager Remove Tab By ID")
    func removeTabId() {
        let manager = createCleanManager()
        let idToRemove = UUID()
        
        manager.tabs = [
            WorkspaceTab(id: idToRemove, name: "A", layout: .single, services: []),
            WorkspaceTab(id: UUID(), name: "B", layout: .single, services: [])
        ]
        
        manager.removeTab(withId: idToRemove)
        
        #expect(manager.tabs.count == 1)
        #expect(manager.tabs.first?.name == "B")
    }
    
    @Test("WorkspaceManager Move Tab")
    func moveTab() {
        let manager = createCleanManager()
        let idA = UUID()
        let idB = UUID()
        let idC = UUID()
        
        manager.tabs = [
            WorkspaceTab(id: idA, name: "A", layout: .single, services: []),
            WorkspaceTab(id: idB, name: "B", layout: .single, services: []),
            WorkspaceTab(id: idC, name: "C", layout: .single, services: [])
        ]
        
        manager.moveTab(fromId: idC, toId: idA)
        
        #expect(manager.tabs[0].id == idC)
        #expect(manager.tabs[1].id == idA)
        #expect(manager.tabs[2].id == idB)
    }
    
    @Test("WorkspaceManager Update Tab Maintains Existing Sessions")
    func updateTabPreservesSessions() {
        let manager = createCleanManager()
        let tabId = UUID()
        
        // Creamos instancia manual para saber el SessionID simulado viejo
        let originalSlack = ServiceInstance(service: .slack, customSuffix: "oldSuffix")
        let originalTasks = ServiceInstance(service: .googleTasks, customSuffix: "oldSuffix")
        
        manager.tabs = [
            WorkspaceTab(id: tabId, name: "Vieja", layout: .columns2, services: [originalSlack, originalTasks])
        ]
        
        // Actualizamos cambiando el segundo servicio de Tasks a Teams, y mantenemos Slack
        manager.updateTab(id: tabId, name: "Nueva", layout: .columns2, services: [.slack, .teams])
        
        let updatedTab = manager.tabs.first!
        
        #expect(updatedTab.name == "Nueva")
        // El de slack se tiene que haber respetado su sesión (estaba en indice 0)
        #expect(updatedTab.services[0].service == .slack)
        #expect(updatedTab.services[0].sessionID == "slack_oldSuffix")
        
        // El de teams es nuevo, deberia tener otra ID de sesión aleatoria con su timestamp local y el índice 1 anexado.
        #expect(updatedTab.services[1].service == .teams)
        #expect(updatedTab.services[1].sessionID != "teams_oldSuffix")
        #expect(updatedTab.services[1].sessionID != originalTasks.sessionID)
        #expect(updatedTab.services[1].sessionID.hasSuffix("_1") == true)
        
    }
}
