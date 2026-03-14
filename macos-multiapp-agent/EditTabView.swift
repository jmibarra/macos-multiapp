import SwiftUI

// MARK: - Mini Preview del Layout
// Componente visual que dibuja una representación miniatura del layout
// usando rectángulos con colores diferenciados

struct LayoutPreviewView: View {
    let layout: LayoutType
    let isSelected: Bool
    
    // Paleta de colores para distinguir los paneles
    private let panelColors: [Color] = [
        .blue.opacity(0.6),
        .green.opacity(0.6),
        .orange.opacity(0.6),
        .purple.opacity(0.6)
    ]
    
    private let spacing: CGFloat = 2
    
    var body: some View {
        VStack(spacing: 6) {
            // Mini representación visual del layout
            layoutShape
                .frame(width: 80, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.3),
                                lineWidth: isSelected ? 2.5 : 1)
                )
                .shadow(color: isSelected ? Color.accentColor.opacity(0.3) : .clear, radius: 4)
            
            // Nombre y notación del layout
            VStack(spacing: 1) {
                Text(layout.displayName)
                    .font(.caption2)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .accentColor : .primary)
                
                Text(layout.rawValue)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // Construye la forma visual del layout usando rectángulos con colores
    @ViewBuilder
    private var layoutShape: some View {
        switch layout {
        case .single:
            // ┌──────┐
            // │  S0  │
            // └──────┘
            panelColors[0]
            
        case .columns2:
            // ┌──┬──┐
            // │S0│S1│
            // └──┴──┘
            HStack(spacing: spacing) {
                panelColors[0]
                panelColors[1]
            }
            
        case .rows2:
            // ┌─────┐
            // │ S0  │
            // ├─────┤
            // │ S1  │
            // └─────┘
            VStack(spacing: spacing) {
                panelColors[0]
                panelColors[1]
            }
            
        case .grid2x2:
            // ┌──┬──┐
            // │S0│S1│
            // ├──┼──┤
            // │S2│S3│
            // └──┴──┘
            VStack(spacing: spacing) {
                HStack(spacing: spacing) {
                    panelColors[0]
                    panelColors[1]
                }
                HStack(spacing: spacing) {
                    panelColors[2]
                    panelColors[3]
                }
            }
            
        case .columns3:
            // ┌──┬──┬──┐
            // │S0│S1│S2│
            // └──┴──┴──┘
            HStack(spacing: spacing) {
                panelColors[0]
                panelColors[1]
                panelColors[2]
            }
            
        case .rows3:
            // ┌──────┐
            // │  S0  │
            // ├──────┤
            // │  S1  │
            // ├──────┤
            // │  S2  │
            // └──────┘
            VStack(spacing: spacing) {
                panelColors[0]
                panelColors[1]
                panelColors[2]
            }
            
        case .leftSplit:
            // ┌──┬───┐
            // │S0│   │
            // ├──┤S2 │
            // │S1│   │
            // └──┴───┘
            HStack(spacing: spacing) {
                VStack(spacing: spacing) {
                    panelColors[0]
                    panelColors[1]
                }
                panelColors[2]
            }
            
        case .rightSplit:
            // ┌───┬──┐
            // │   │S1│
            // │S0 ├──┤
            // │   │S2│
            // └───┴──┘
            HStack(spacing: spacing) {
                panelColors[0]
                VStack(spacing: spacing) {
                    panelColors[1]
                    panelColors[2]
                }
            }
        }
    }
}

// MARK: - EditTabView (Formulario de creación de pestañas)

struct EditTabView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var workspaceManager: WorkspaceManager
    
    // Tab a editar (nil si es creación nueva)
    var tabToEdit: WorkspaceTab?
    
    @State private var tabName: String = ""
    @State private var selectedLayout: LayoutType = .single
    
    // Array dinámico de servicios seleccionados (se ajusta al serviceCount del layout)
    @State private var selectedServices: [Service] = [.googleTasks, .googleTasks, .googleTasks, .googleTasks]
    
    // Grid de 4 columnas para los previews de layout
    private let previewColumns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Cabecera superior
            ZStack {
                Color(NSColor.controlBackgroundColor)
                    .edgesIgnoringSafeArea(.top)
                
                VStack(spacing: 8) {
                    Image(systemName: tabToEdit == nil ? "macwindow.badge.plus" : "pencil.and.outline")
                        .font(.system(size: 32))
                        .foregroundColor(.accentColor)
                    
                    Text(tabToEdit == nil ? "Nueva Pestaña" : "Editar Pestaña")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                .padding(.vertical, 20)
            }
            .frame(height: 100)
            
            Divider()
            
            // Contenido del formulario con scroll para layouts grandes
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Nombre de la pestaña
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Nombre de la pestaña")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        TextField("Ej: Comunicación, Trabajo...", text: $tabName)
                            .textFieldStyle(.roundedBorder)
                            .controlSize(.large)
                    }
                    
                    // Selector de Layout con mini previews
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Disposición")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(columns: previewColumns, spacing: 14) {
                            ForEach(LayoutType.allCases) { layout in
                                LayoutPreviewView(
                                    layout: layout,
                                    isSelected: selectedLayout == layout
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedLayout = layout
                                    }
                                }
                            }
                        }
                        .padding(12)
                        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                    }
                    
                    // Servicios — pickers dinámicos según el layout
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Servicios Web (\(selectedLayout.serviceCount))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        VStack(spacing: 12) {
                            ForEach(0..<selectedLayout.serviceCount, id: \.self) { index in
                                HStack {
                                    // Indicador de color que coincide con el preview
                                    Circle()
                                        .fill(previewColor(for: index))
                                        .frame(width: 10, height: 10)
                                    
                                    Text("\(selectedLayout.serviceLabels[index]):")
                                        .frame(width: 120, alignment: .trailing)
                                        .font(.callout)
                                    
                                    Picker("", selection: $selectedServices[index]) {
                                        ForEach(Service.allCases) { service in
                                            Text(service.rawValue).tag(service)
                                        }
                                    }
                                    .labelsHidden()
                                    
                                    Spacer()
                                }
                            }
                        }
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                    }
                }
                .padding(24)
            }
            
            Divider()
            
            // Botones de acción
            HStack {
                Button("Cancelar") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                .controlSize(.large)
                
                Spacer()
                
                Button(tabToEdit == nil ? "Crear Pestaña" : "Guardar Cambios") {
                    saveTab()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(tabName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 520, height: 600)
        .onAppear {
            if let tab = tabToEdit {
                tabName = tab.name
                selectedLayout = tab.layout
                for (index, serviceInstance) in tab.services.enumerated() {
                    if index < selectedServices.count {
                        selectedServices[index] = serviceInstance.service
                    }
                }
            }
        }
    }
    
    // Color del indicador, debe coincidir con la paleta del LayoutPreviewView
    private func previewColor(for index: Int) -> Color {
        let colors: [Color] = [
            .blue.opacity(0.6),
            .green.opacity(0.6),
            .orange.opacity(0.6),
            .purple.opacity(0.6)
        ]
        return index < colors.count ? colors[index] : .gray
    }
    
    private func saveTab() {
        // Tomar solo los servicios necesarios según el layout seleccionado
        let servicesToSave = Array(selectedServices.prefix(selectedLayout.serviceCount))
        
        let finalName = tabName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let tab = tabToEdit {
            workspaceManager.updateTab(
                id: tab.id,
                name: finalName,
                layout: selectedLayout,
                services: servicesToSave
            )
        } else {
            workspaceManager.addTab(
                name: finalName,
                layout: selectedLayout,
                services: servicesToSave
            )
        }
        
        dismiss()
    }
}