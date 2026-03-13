import SwiftUI

struct ContentView: View {
    @StateObject private var workspaceManager = WorkspaceManager()
    @State private var showingAddTab = false
    
    // Control de la pestaña activa y borrado
    @State private var selectedTabId: UUID?
    @State private var tabToDelete: UUID?
    @State private var showingDeleteAlert = false
    
    var body: some View {
        TabView(selection: $selectedTabId) {
            ForEach(workspaceManager.tabs) { tab in
                buildTabContent(for: tab)
                    .tabItem {
                        Label(tab.name, systemImage: "app.window")
                    }
                    .tag(tab.id as UUID?)
            }
        }
        .frame(minWidth: 1000, minHeight: 700)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                // Botón de eliminar, solo si hay algo seleccionado
                Button(action: {
                    if let id = selectedTabId {
                        tabToDelete = id
                        showingDeleteAlert = true
                    }
                }) {
                    Label("Eliminar Pestaña", systemImage: "trash")
                        .foregroundColor(.red)
                }
                .help("Elimina la pestaña actual")
                .disabled(workspaceManager.tabs.isEmpty || selectedTabId == nil)
                
                // Botón para añadir nueva pestaña
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
        .alert("¿Eliminar pestaña?", isPresented: $showingDeleteAlert) {
            Button("Cancelar", role: .cancel) { }
            Button("Eliminar", role: .destructive) {
                if let id = tabToDelete {
                    workspaceManager.removeTab(withId: id)
                    // Seleccionar la primera pestaña disponible si la borrada era la actual y quedan pestañas
                    if selectedTabId == id, let first = workspaceManager.tabs.first {
                        selectedTabId = first.id
                    } else if workspaceManager.tabs.isEmpty {
                        selectedTabId = nil
                    }
                }
            }
        } message: {
            Text("Esta acción no se puede deshacer.")
        }
        // Seleccionamos la primera pestaña por defecto si no hay ninguna activa
        .onAppear {
            if selectedTabId == nil, let first = workspaceManager.tabs.first {
                selectedTabId = first.id
            }
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
