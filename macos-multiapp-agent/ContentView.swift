import SwiftUI

struct ContentView: View {
    var body: some View {
        // HSplitView principal que divide el área de Comunicación (Izquierda) de Tareas (Derecha)
        HSplitView {
            // Panel Izquierdo: Comunicación (3 columnas)
            HSplitView {
                VStack(spacing: 0) {
                    Text("WhatsApp")
                        .font(.caption)
                        .padding(4)
                    WorkspaceWebView(urlString: "https://web.whatsapp.com", sessionID: "whatsapp")
                }
                .frame(minWidth: 200)
                
                VStack(spacing: 0) {
                    Text("Teams")
                        .font(.caption)
                        .padding(4)
                    WorkspaceWebView(urlString: "https://teams.microsoft.com", sessionID: "teams")
                }
                .frame(minWidth: 200)
                
                VStack(spacing: 0) {
                    Text("Slack")
                        .font(.caption)
                        .padding(4)
                    WorkspaceWebView(urlString: "https://app.slack.com", sessionID: "slack")
                }
                .frame(minWidth: 200)
            }
            .frame(minWidth: 600)
            
            // Panel Derecho: Gestión de Tareas (2 filas)
            VSplitView {
                VStack(spacing: 0) {
                    Text("Tasks Personal")
                        .font(.caption)
                        .padding(4)
                    WorkspaceWebView(urlString: "https://tasksboard.com", sessionID: "tasks_personal")
                }
                .frame(minHeight: 200)
                
                VStack(spacing: 0) {
                    Text("Tasks Trabajo")
                        .font(.caption)
                        .padding(4)
                    WorkspaceWebView(urlString: "https://tasksboard.com", sessionID: "tasks_work")
                }
                .frame(minHeight: 200)
            }
            .frame(minWidth: 300)
        }
        .frame(minWidth: 900, minHeight: 600)
    }
}

#Preview {
    ContentView()
}
