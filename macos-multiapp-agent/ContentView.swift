import SwiftUI

struct ContentView: View {
    @StateObject private var workspaceManager = WorkspaceManager()
    @State private var showingAddTab = false
    
    var body: some View {
        TabView {
            ForEach(workspaceManager.tabs) { tab in
                buildTabContent(for: tab)
                    .tabItem {
                        Label(tab.name, systemImage: "app.window")
                    }
            }
        }
        .frame(minWidth: 1000, minHeight: 700)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    showingAddTab = true
                }) {
                    Label("Añadir Pestaña", systemImage: "plus")
                }
                .help("Añadir una nueva pestaña personalizada")
            }
        }
        .sheet(isPresented: $showingAddTab) {
            EditTabView(workspaceManager: workspaceManager)
        }
    }
    
    @ViewBuilder
    private func buildTabContent(for tab: WorkspaceTab) -> some View {
        if tab.layout == .fullScreen, let firstService = tab.services.first {
            WorkspaceWebView(urlString: firstService.service.url, sessionID: firstService.sessionID)
                .frame(minWidth: 300)
        } else if tab.layout == .verticalSplit, tab.services.count >= 2 {
            HSplitView {
                WorkspaceWebView(urlString: tab.services[0].service.url, sessionID: tab.services[0].sessionID)
                    .frame(minWidth: 300)
                
                WorkspaceWebView(urlString: tab.services[1].service.url, sessionID: tab.services[1].sessionID)
                    .frame(minWidth: 300)
            }
        } else {
            Text("Configuración de pestaña no válida")
        }
    }
}

#Preview {
    ContentView()
}
