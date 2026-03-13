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
            Text("Nueva Pestaña")
                .font(.headline)
                .padding()
            
            Form {
                Section {
                    TextField("Nombre de la pestaña", text: $tabName)
                }
                
                Section(header: Text("Diseño")) {
                    Picker("Layout", selection: $selectedLayout) {
                        ForEach(LayoutType.allCases) { layout in
                            Text(layout.rawValue).tag(layout)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text("Servicios")) {
                    if selectedLayout == .fullScreen {
                        Picker("Servicio", selection: $selectedService1) {
                            ForEach(Service.allCases) { service in
                                Text(service.rawValue).tag(service)
                            }
                        }
                    } else if selectedLayout == .verticalSplit {
                        Picker("Panel Izquierdo", selection: $selectedService1) {
                            ForEach(Service.allCases) { service in
                                Text(service.rawValue).tag(service)
                            }
                        }
                        
                        Picker("Panel Derecho", selection: $selectedService2) {
                            ForEach(Service.allCases) { service in
                                Text(service.rawValue).tag(service)
                            }
                        }
                    }
                }
            }
            .padding()
            
            HStack {
                Button("Cancelar") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Guardar") {
                    saveTab()
                }
                .buttonStyle(.borderedProminent)
                .disabled(tabName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(width: 400, height: 350)
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
