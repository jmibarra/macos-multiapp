import SwiftUI

struct EditTabView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var workspaceManager: WorkspaceManager
    
    @State private var tabName: String = ""
    @State private var selectedLayout: LayoutType = .fullScreen
    
    // Servicios seleccionados segun el layout
    @State private var selectedService1: Service = .googleTasks
    @State private var selectedService2: Service = .googleTasks
    
    var body: some View {
        VStack(spacing: 0) {
            // Cabecera superior envolvente
            ZStack {
                Color(NSColor.controlBackgroundColor)
                    .edgesIgnoringSafeArea(.top)
                
                VStack(spacing: 8) {
                    Image(systemName: "macwindow.badge.plus")
                        .font(.system(size: 32))
                        .foregroundColor(.accentColor)
                    
                    Text("Nueva Pestaña")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                .padding(.vertical, 20)
            }
            .frame(height: 100)
            
            Divider()
            
            // Contenido del Formulario
            VStack(alignment: .leading, spacing: 20) {
                // Nombre
                VStack(alignment: .leading, spacing: 6) {
                    Text("Nombre de la pestaña")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextField("Ej: Comunicación, Trabajo...", text: $tabName)
                        .textFieldStyle(.roundedBorder)
                        .controlSize(.large)
                }
                
                // Diseño
                VStack(alignment: .leading, spacing: 6) {
                    Text("Disposición")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Picker("", selection: $selectedLayout) {
                        ForEach(LayoutType.allCases) { layout in
                            Text(layout.rawValue).tag(layout)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
                
                // Servicios
                VStack(alignment: .leading, spacing: 10) {
                    Text("Servicios Web")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 12) {
                        if selectedLayout == .fullScreen {
                            HStack {
                                Text("App Principal:")
                                    .frame(width: 110, alignment: .trailing)
                                Picker("", selection: $selectedService1) {
                                    ForEach(Service.allCases) { service in
                                        Text(service.rawValue).tag(service)
                                    }
                                }
                                .labelsHidden()
                                
                                Spacer()
                            }
                        } else if selectedLayout == .verticalSplit {
                            HStack {
                                Text("Panel Izquierdo:")
                                    .frame(width: 110, alignment: .trailing)
                                Picker("", selection: $selectedService1) {
                                    ForEach(Service.allCases) { service in
                                        Text(service.rawValue).tag(service)
                                    }
                                }
                                .labelsHidden()
                                
                                Spacer()
                            }
                            
                            HStack {
                                Text("Panel Derecho:")
                                    .frame(width: 110, alignment: .trailing)
                                Picker("", selection: $selectedService2) {
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
            
            Spacer(minLength: 0)
            
            Divider()
            
            // Botones de acción
            HStack {
                Button("Cancelar") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                .controlSize(.large)
                
                Spacer()
                
                Button("Crear Pestaña") {
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
        .frame(width: 480, height: 500)
    }
    
    private func saveTab() {
        var servicesToSave: [Service] = []
        
        if selectedLayout == .fullScreen {
            servicesToSave.append(selectedService1)
        } else if selectedLayout == .verticalSplit {
            servicesToSave.append(selectedService1)
            servicesToSave.append(selectedService2)
        }
        
        workspaceManager.addTab(
            name: tabName.trimmingCharacters(in: .whitespacesAndNewlines),
            layout: selectedLayout,
            services: servicesToSave
        )
        
        dismiss()
    }
}
