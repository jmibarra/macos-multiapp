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
        // Intercepta el botón de cerrado de la ventana para ocultarla y no destruirla
        .background(WindowAccessor())
    }
    
    // Helper para construir un WebView a partir de un ServiceInstance
    @ViewBuilder
    private func webView(for service: ServiceInstance) -> some View {
        WorkspaceWebView(urlString: service.service.url, sessionID: service.sessionID)
            .frame(minWidth: 200, minHeight: 150)
    }
    
    @ViewBuilder
    private func buildTabContent(for tab: WorkspaceTab) -> some View {
        let s = tab.services
        
        // Validación genérica: verificar que hay suficientes servicios para el layout
        if s.count >= tab.layout.serviceCount {
            switch tab.layout {
            case .single:
                // 1×1: Pantalla completa
                webView(for: s[0])
                
            case .columns2:
                // 1×2: Dos columnas lado a lado
                HSplitView {
                    webView(for: s[0])
                    webView(for: s[1])
                }
                
            case .rows2:
                // 2×1: Dos filas apiladas
                VSplitView {
                    webView(for: s[0])
                    webView(for: s[1])
                }
                
            case .grid2x2:
                // 2×2: Grilla de 4 servicios
                VSplitView {
                    HSplitView {
                        webView(for: s[0])
                        webView(for: s[1])
                    }
                    HSplitView {
                        webView(for: s[2])
                        webView(for: s[3])
                    }
                }
                
            case .columns3:
                // 1×3: Tres columnas
                HSplitView {
                    webView(for: s[0])
                    webView(for: s[1])
                    webView(for: s[2])
                }
                
            case .rows3:
                // 3×1: Tres filas apiladas
                VSplitView {
                    webView(for: s[0])
                    webView(for: s[1])
                    webView(for: s[2])
                }
                
            case .leftSplit:
                // 1(2×1)×1: Columna izquierda dividida en 2 + columna derecha completa
                HSplitView {
                    VSplitView {
                        webView(for: s[0])
                        webView(for: s[1])
                    }
                    webView(for: s[2])
                }
                
            case .rightSplit:
                // 1×1(2×1): Columna izquierda completa + columna derecha dividida en 2
                HSplitView {
                    webView(for: s[0])
                    VSplitView {
                        webView(for: s[1])
                        webView(for: s[2])
                    }
                }
            }
        } else {
            Text("Configuración de pestaña no válida: se necesitan \(tab.layout.serviceCount) servicios")
        }
    }
}

#Preview {
    ContentView()
}
