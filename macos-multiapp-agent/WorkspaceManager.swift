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
            icon: "message.fill",
            layout: .columns2,
            services: [
                ServiceInstance(service: .whatsapp),
                ServiceInstance(service: .slack)
            ]
        )
        
        let tasksTab = WorkspaceTab(
            name: "Tareas",
            icon: "checkmark.circle",
            layout: .columns2,
            services: [
                ServiceInstance(service: .googleTasks, customSuffix: "personal"),
                ServiceInstance(service: .googleTasks, customSuffix: "work")
            ]
        )
        
        self.tabs = [commsTab, tasksTab]
    }
    
    // MARK: - API
    
    // Agrega una nueva pestana recibiendo los servicios seleccionados
    func addTab(name: String, icon: String?, layout: LayoutType, services: [ServiceInstance]) {
        var instances: [ServiceInstance] = []
        for (index, mutService) in services.enumerated() {
            // Asegurar unicamente aislar los sessionID
            let suffix = "\(Date().timeIntervalSince1970)_\(index)"
            var newInstance = mutService
            newInstance.sessionID = "\(newInstance.service.defaultSessionPrefix)_\(suffix)"
            instances.append(newInstance)
        }
        
        let newTab = WorkspaceTab(name: name, icon: icon, layout: layout, services: instances)
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
    
    // Mueve una pestaña desde su posición actual a la posición de otra pestaña (para drag and drop)
    func moveTab(fromId: UUID, toId: UUID) {
        guard fromId != toId,
              let fromIndex = tabs.firstIndex(where: { $0.id == fromId }),
              let toIndex = tabs.firstIndex(where: { $0.id == toId }) else { return }
        
        let tab = tabs.remove(at: fromIndex)
        tabs.insert(tab, at: toIndex)
    }
    
    // Actualiza una pestaña existente, preservando los sessionID de los servicios que se mantienen
    func updateTab(id: UUID, name: String, icon: String?, layout: LayoutType, services: [ServiceInstance]) {
        guard let index = tabs.firstIndex(where: { $0.id == id }) else { return }
        
        let existingTab = tabs[index]
        let existingServices = existingTab.services
        var newInstances: [ServiceInstance] = []
        
        for (i, incomingInstance) in services.enumerated() {
            // Si en esta posición ya había un servicio del mismo tipo, preservamos su sessionID
            // para que no se pierda la sesión (cookies, login, etc)
            if i < existingServices.count && existingServices[i].service == incomingInstance.service {
                var reused = existingServices[i]
                reused.customName = incomingInstance.customName
                if incomingInstance.service == .custom && reused.customURL != incomingInstance.customURL {
                    let suffix = "\(Date().timeIntervalSince1970)_\(i)"
                    reused.sessionID = "\(reused.service.defaultSessionPrefix)_\(suffix)"
                }
                reused.customURL = incomingInstance.customURL
                newInstances.append(reused)
            } else {
                // Es un servicio nuevo en esta posición o cambió de tipo, generamos uno nuevo
                let suffix = "\(Date().timeIntervalSince1970)_\(i)"
                var newInstance = incomingInstance
                newInstance.sessionID = "\(newInstance.service.defaultSessionPrefix)_\(suffix)"
                newInstances.append(newInstance)
            }
        }
        
        tabs[index].name = name
        tabs[index].icon = icon
        tabs[index].layout = layout
        tabs[index].services = newInstances
    }
}
