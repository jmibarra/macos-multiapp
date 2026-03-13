import Foundation
import Combine

// Administrador de las pestanas del espacio de trabajo
class WorkspaceManager: ObservableObject {
    @Published var tabs: [WorkspaceTab] = [] {
        didSet {
            saveToUserDefaults()
        }
    }
    
    private let userDefaultsKey = "WorkspaceTabs"
    
    init() {
        loadFromUserDefaults()
    }
    
    // MARK: - Manejo de datos
    
    // Carga la configuracion guardada o crea las pestanas por defecto si no hay nada
    private func loadFromUserDefaults() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let savedTabs = try? JSONDecoder().decode([WorkspaceTab].self, from: data) {
            self.tabs = savedTabs
        } else {
            createDefaultTabs()
        }
    }
    
    // Guarda el array de pestanas actual
    private func saveToUserDefaults() {
        if let encoded = try? JSONEncoder().encode(tabs) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    // Inicializa la app con valores por defecto
    private func createDefaultTabs() {
        let commsTab = WorkspaceTab(
            name: "Comunicacion",
            layout: .verticalSplit,
            services: [
                ServiceInstance(service: .whatsapp),
                ServiceInstance(service: .slack)
            ]
        )
        
        let tasksTab = WorkspaceTab(
            name: "Tareas",
            layout: .verticalSplit,
            services: [
                ServiceInstance(service: .googleTasks, customSuffix: "personal"),
                ServiceInstance(service: .googleTasks, customSuffix: "work")
            ]
        )
        
        self.tabs = [commsTab, tasksTab]
    }
    
    // MARK: - API
    
    // Agrega una nueva pestana recibiendo los servicios seleccionados
    func addTab(name: String, layout: LayoutType, services: [Service]) {
        var instances: [ServiceInstance] = []
        for (index, service) in services.enumerated() {
            // Asegurar unicamente aislar los sessionID
            let suffix = "\(Date().timeIntervalSince1970)_\(index)"
            instances.append(ServiceInstance(service: service, customSuffix: suffix))
        }
        
        let newTab = WorkspaceTab(name: name, layout: layout, services: instances)
        tabs.append(newTab)
    }
    
    // Elimina una pestana segun su indice (o ID si se prefiere)
    func removeTab(at index: Int) {
        guard index >= 0 && index < tabs.count else { return }
        tabs.remove(at: index)
    }
    
    // Elimina una pestaña según su ID único
    func removeTab(withId id: UUID) {
        tabs.removeAll { $0.id == id }
    }
}
