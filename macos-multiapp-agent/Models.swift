import Foundation

// Servicio web disponible
enum Service: String, CaseIterable, Identifiable, Codable {
    case googleTasks = "Google Tasks"
    case slack = "Slack"
    case whatsapp = "WhatsApp"
    case teams = "Microsoft Teams"
    case googleCalendar = "Google Calendar"
    case outlookMail = "Outlook Mail"
    
    var id: String { self.rawValue }
    
    // URL por defecto para el servicio
    var url: String {
        switch self {
        case .googleTasks: return "https://tasks.google.com/tasks/"
        case .slack: return "https://app.slack.com"
        case .whatsapp: return "https://web.whatsapp.com"
        case .teams: return "https://teams.microsoft.com/v2/"
        case .googleCalendar: return "https://calendar.google.com"
        case .outlookMail: return "https://outlook.live.com/mail/"
        }
    }
    
    // Prefijo base para generar el sessionID unico de cada instancia
    var defaultSessionPrefix: String {
        switch self {
        case .googleTasks: return "tasks"
        case .slack: return "slack"
        case .whatsapp: return "whatsapp"
        case .teams: return "teams"
        case .googleCalendar: return "gcalendar"
        case .outlookMail: return "outlook"
        }
    }
}

// Interfaz (Layout) para una pestana
enum LayoutType: String, Codable, CaseIterable, Identifiable {
    case fullScreen = "Pantalla Completa"
    case verticalSplit = "Dividida Verticalmente"
    
    var id: String { self.rawValue }
}

// Representa una instancia de un servicio dentro de un tab (necesario para manejar multiples instancias del mismo servicio)
struct ServiceInstance: Identifiable, Codable {
    var id = UUID()
    var service: Service
    var sessionID: String // El ID de sesion especifico para aislamiento
    
    init(service: Service, customSuffix: String = "") {
        self.service = service
        self.sessionID = customSuffix.isEmpty ? service.defaultSessionPrefix : "\(service.defaultSessionPrefix)_\(customSuffix)"
    }
}

// Modelo principal de una pestana del Workspace
struct WorkspaceTab: Identifiable, Codable {
    var id = UUID()
    var name: String
    var layout: LayoutType
    var services: [ServiceInstance]
}
