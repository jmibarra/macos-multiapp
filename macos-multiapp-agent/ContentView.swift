import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            // PESTAÑA 1: COMUNICACIÓN
            CommunicationView()
                .tabItem {
                    Label("Comunicación", systemImage: "bubble.left.and.bubble.right")
                }
            
            // PESTAÑA 2: TAREAS
            TasksView()
                .tabItem {
                    Label("Tareas", systemImage: "checklist")
                }
        }
        .frame(minWidth: 1000, minHeight: 700)
    }
}

// MARK: - Vistas de Pestañas

struct CommunicationView: View {
    var body: some View {
        // HSplitView principal (50% / 50%)
        HSplitView {
            // Mitad Izquierda: WhatsApp
            WorkspaceWebView(urlString: "https://web.whatsapp.com", sessionID: "whatsapp")
                .frame(minWidth: 300)
            
            // Mitad Derecha: Teams arriba, Slack abajo
            VSplitView {
                WorkspaceWebView(urlString: "https://teams.microsoft.com", sessionID: "teams")
                    .frame(minHeight: 200)
                
                WorkspaceWebView(urlString: "https://app.slack.com", sessionID: "slack")
                    .frame(minHeight: 200)
            }
            .frame(minWidth: 300)
        }
    }
}

struct TasksView: View {
    var body: some View {
        // Layout para dos instancias de Google Tasks
        // Utilizo HSplitView para una vista lado a lado cómoda para tareas
        HSplitView {
            WorkspaceWebView(urlString: "https://tasks.google.com/tasks/", sessionID: "tasks_personal")
                .frame(minWidth: 400)
            
            WorkspaceWebView(urlString: "https://tasks.google.com/tasks/", sessionID: "tasks_work")
                .frame(minWidth: 400)
        }
    }
}

#Preview {
    ContentView()
}
