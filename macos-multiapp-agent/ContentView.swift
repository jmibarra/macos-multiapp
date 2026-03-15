import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var workspaceManager = WorkspaceManager()
    @State private var showingAddTab = false
    @State private var tabToEdit: WorkspaceTab?
    
    // Control de la pestaña activa y borrado
    @State private var selectedTabId: UUID?
    @State private var tabToDelete: UUID?
    @State private var showingDeleteAlert = false
    
    // Estado del drag and drop
    @State private var draggedTabId: UUID?
    @State private var dropTargetId: UUID?
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Tab Bar Custom con Drag & Drop
            tabBar
            
            Divider()
            
            // MARK: - Contenido de las pestañas
            // Usamos un ZStack para mantener todas las pestañas en la vista (vivas en segundo plano)
            // de modo que no se recarguen al cambiar de pestaña.
            if workspaceManager.tabs.isEmpty {
                // Estado vacío cuando no hay pestañas
                VStack(spacing: 12) {
                    Image(systemName: "macwindow.badge.plus")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No hay pestañas configuradas")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    Button("Crear Primera Pestaña") {
                        showingAddTab = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ZStack {
                    ForEach(workspaceManager.tabs) { tab in
                        buildTabContent(for: tab)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .opacity(tab.id == selectedTabId ? 1 : 0)
                            .allowsHitTesting(tab.id == selectedTabId) // Evitar clics en las pestañas ocultas
                    }
                }
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
        .sheet(isPresented: $showingAddTab, onDismiss: { tabToEdit = nil }) {
            EditTabView(workspaceManager: workspaceManager, tabToEdit: tabToEdit)
        }
        .alert("¿Eliminar pestaña?", isPresented: $showingDeleteAlert) {
            Button("Cancelar", role: .cancel) { }
            Button("Eliminar", role: .destructive) {
                if let id = tabToDelete {
                    workspaceManager.removeTab(withId: id)
                    // Seleccionar la primera pestaña disponible si la borrada era la actual
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
    
    // MARK: - Tab Bar con Drag & Drop
    
    private var tabBar: some View {
        HStack {
            Spacer()
            
            HStack(spacing: 1) {
                ForEach(workspaceManager.tabs) { tab in
                    tabItemView(for: tab)
                }
            }
            .padding(3)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(NSColor.controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
            )
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // Cada item individual del tab bar
    private func tabItemView(for tab: WorkspaceTab) -> some View {
        let isSelected = selectedTabId == tab.id
        let isDropTarget = dropTargetId == tab.id && draggedTabId != tab.id
        
        return HStack(spacing: 5) {
            Image(systemName: tab.icon ?? "macwindow")
                .font(.system(size: 11))
                .foregroundColor(isSelected ? .accentColor : .secondary)
                
            Text(tab.name)
                .font(.system(size: 12, weight: isSelected ? .medium : .regular))
                .lineLimit(1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(
            Group {
                if isSelected {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(NSColor.controlColor))
                        .shadow(color: .black.opacity(0.1), radius: 1, y: 0.5)
                } else {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.clear)
                }
            }
        )
        .overlay(
            // Indicador visual del drop target (línea azul a la izquierda)
            HStack(spacing: 0) {
                if isDropTarget {
                    Capsule()
                        .fill(Color.accentColor)
                        .frame(width: 2.5)
                        .padding(.vertical, 4)
                        .transition(.opacity)
                }
                Spacer()
            }
        )
        .foregroundColor(isSelected ? .primary : .secondary)
        .contentShape(Rectangle())
        .onTapGesture {
            selectedTabId = tab.id
        }
        // Drag: iniciar arrastre de esta pestaña
        .onDrag {
            draggedTabId = tab.id
            return NSItemProvider(object: tab.id.uuidString as NSString)
        }
        // Drop: soltar sobre esta pestaña para reordenar
        .onDrop(of: [UTType.text], delegate: TabDropDelegate(
            targetTabId: tab.id,
            workspaceManager: workspaceManager,
            draggedTabId: $draggedTabId,
            dropTargetId: $dropTargetId
        ))
        // Opacidad reducida para la pestaña que se está arrastrando
        .opacity(draggedTabId == tab.id ? 0.4 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isDropTarget)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
        .contextMenu {
            Button {
                tabToEdit = tab
                showingAddTab = true
            } label: {
                Label("Editar Pestaña", systemImage: "pencil")
            }
            
            Divider()
            
            Button(role: .destructive) {
                tabToDelete = tab.id
                showingDeleteAlert = true
            } label: {
                Label("Eliminar Pestaña", systemImage: "trash")
            }
        }
    }
    
    // MARK: - Contenido de las pestañas
    
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
                webView(for: s[0])
                
            case .columns2:
                HSplitView {
                    webView(for: s[0])
                    webView(for: s[1])
                }
                
            case .rows2:
                VSplitView {
                    webView(for: s[0])
                    webView(for: s[1])
                }
                
            case .grid2x2:
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
                HSplitView {
                    webView(for: s[0])
                    webView(for: s[1])
                    webView(for: s[2])
                }
                
            case .rows3:
                VSplitView {
                    webView(for: s[0])
                    webView(for: s[1])
                    webView(for: s[2])
                }
                
            case .leftSplit:
                HSplitView {
                    VSplitView {
                        webView(for: s[0])
                        webView(for: s[1])
                    }
                    webView(for: s[2])
                }
                
            case .rightSplit:
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

// MARK: - Drop Delegate para el reordenamiento de pestañas

/// Maneja la lógica de drag and drop entre pestañas.
/// Cuando el usuario arrastra una pestaña sobre otra, reordena el array en WorkspaceManager.
struct TabDropDelegate: DropDelegate {
    let targetTabId: UUID
    let workspaceManager: WorkspaceManager
    @Binding var draggedTabId: UUID?
    @Binding var dropTargetId: UUID?
    
    // Se invoca cuando el drag entra en la zona de esta pestaña
    func dropEntered(info: DropInfo) {
        dropTargetId = targetTabId
        
        // Reordenar en tiempo real mientras se arrastra
        guard let draggedId = draggedTabId, draggedId != targetTabId else { return }
        
        withAnimation(.easeInOut(duration: 0.2)) {
            workspaceManager.moveTab(fromId: draggedId, toId: targetTabId)
        }
    }
    
    // Se invoca cuando el usuario suelta el item
    func performDrop(info: DropInfo) -> Bool {
        // Limpiar estado de drag
        draggedTabId = nil
        dropTargetId = nil
        return true
    }
    
    // Se invoca cuando el drag sale de la zona de esta pestaña
    func dropExited(info: DropInfo) {
        if dropTargetId == targetTabId {
            dropTargetId = nil
        }
    }
    
    // Validar que se puede hacer drop aquí
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
    
    // Valida que el item arrastrado es compatible
    func validateDrop(info: DropInfo) -> Bool {
        return draggedTabId != nil
    }
}

#Preview {
    ContentView()
}
