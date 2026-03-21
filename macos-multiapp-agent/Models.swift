import Foundation
import UniformTypeIdentifiers

// Servicio web disponible
enum Service: String, CaseIterable, Identifiable, Codable {
    case googleTasks = "Google Tasks"
    case slack = "Slack"
    case whatsapp = "WhatsApp"
    case teams = "Microsoft Teams"
    case googleCalendar = "Google Calendar"
    case outlookMail = "Outlook Mail"
    case custom = "Custom"
    
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
        case .custom: return ""
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
        case .custom: return "custom"
        }
    }
}

// Interfaz (Layout) para una pestana — notación F×C (Filas × Columnas)
enum LayoutType: String, Codable, CaseIterable, Identifiable {
    case single       = "1×1"          // Pantalla completa
    case columns2     = "1×2"          // 2 columnas lado a lado
    case rows2        = "2×1"          // 2 filas apiladas
    case grid2x2      = "2×2"          // Grilla 2 filas por 2 columnas
    case columns3     = "1×3"          // 3 columnas
    case rows3        = "3×1"          // 3 filas apiladas
    case leftSplit    = "1(2×1)×1"     // Columna izq dividida + columna der completa
    case rightSplit   = "1×1(2×1)"     // Columna izq completa + columna der dividida
    
    var id: String { self.rawValue }
    
    // Nombre legible para mostrar en la UI
    var displayName: String {
        switch self {
        case .single:     return "Pantalla Completa"
        case .columns2:   return "2 Columnas"
        case .rows2:      return "2 Filas"
        case .grid2x2:    return "Grilla 2×2"
        case .columns3:   return "3 Columnas"
        case .rows3:      return "3 Filas"
        case .leftSplit:  return "Izq. Dividido"
        case .rightSplit: return "Der. Dividido"
        }
    }
    
    // Cantidad de servicios web que necesita el layout
    var serviceCount: Int {
        switch self {
        case .single:                return 1
        case .columns2, .rows2:     return 2
        case .columns3, .rows3,
             .leftSplit, .rightSplit: return 3
        case .grid2x2:              return 4
        }
    }
    
    // Etiquetas descriptivas para cada posición dentro del layout
    var serviceLabels: [String] {
        switch self {
        case .single:
            return ["App Principal"]
        case .columns2:
            return ["Panel Izquierdo", "Panel Derecho"]
        case .rows2:
            return ["Panel Superior", "Panel Inferior"]
        case .grid2x2:
            return ["Superior Izq.", "Superior Der.", "Inferior Izq.", "Inferior Der."]
        case .columns3:
            return ["Columna 1", "Columna 2", "Columna 3"]
        case .rows3:
            return ["Fila 1", "Fila 2", "Fila 3"]
        case .leftSplit:
            return ["Sup. Izquierdo", "Inf. Izquierdo", "Panel Derecho"]
        case .rightSplit:
            return ["Panel Izquierdo", "Sup. Derecho", "Inf. Derecho"]
        }
    }
    
    // Decodificación con migración de valores anteriores.
    // Los datos guardados en UserDefaults pueden tener los rawValue viejos
    // ("Pantalla Completa", "Dividida Verticalmente") que ya no coinciden.
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        
        // Intentar decodificar con los nuevos raw values
        if let layout = LayoutType(rawValue: rawValue) {
            self = layout
            return
        }
        
        // Migración: mapear raw values anteriores a los nuevos cases
        switch rawValue {
        case "Pantalla Completa":
            self = .single
        case "Dividida Verticalmente":
            self = .columns2
        default:
            // Si no se reconoce, usar pantalla completa como fallback
            self = .single
        }
    }
}

// Representa una instancia de un servicio dentro de un tab (necesario para manejar multiples instancias del mismo servicio)
struct ServiceInstance: Identifiable, Codable {
    var id = UUID()
    var service: Service
    var sessionID: String // El ID de sesion especifico para aislamiento
    var customName: String?
    var customURL: String?
    
    init(service: Service, customSuffix: String = "", customName: String? = nil, customURL: String? = nil) {
        self.service = service
        self.sessionID = customSuffix.isEmpty ? service.defaultSessionPrefix : "\(service.defaultSessionPrefix)_\(customSuffix)"
        self.customName = customName
        self.customURL = customURL
    }
    
    var displayURL: String {
        if service == .custom {
            let urlStr = (customURL?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")
            if urlStr.isEmpty {
                return "https://google.com"
            }
            if !urlStr.lowercased().hasPrefix("http://") && !urlStr.lowercased().hasPrefix("https://") {
                return "https://" + urlStr
            }
            return urlStr
        }
        return service.url
    }
}

// Modelo principal de una pestana del Workspace
struct WorkspaceTab: Identifiable, Codable {
    var id = UUID()
    var name: String
    var icon: String? // SF Symbol opcional para retro-compatibilidad
    var layout: LayoutType
    var services: [ServiceInstance]
}
