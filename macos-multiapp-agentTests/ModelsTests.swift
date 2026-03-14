import Testing
@testable import WorkHub

@Suite("Models Tests")
struct ModelsTests {
    
    @Test("Service Returns Correct URLs")
    func serviceURLs() {
        #expect(Service.googleTasks.url == "https://tasks.google.com/tasks/")
        #expect(Service.slack.url == "https://app.slack.com")
        #expect(Service.whatsapp.url == "https://web.whatsapp.com")
        #expect(Service.teams.url == "https://teams.microsoft.com/v2/")
        #expect(Service.googleCalendar.url == "https://calendar.google.com")
        #expect(Service.outlookMail.url == "https://outlook.live.com/mail/")
    }
    
    @Test("Service Returns Correct Session Prefixes")
    func serviceSessionPrefixes() {
        #expect(Service.googleTasks.defaultSessionPrefix == "tasks")
        #expect(Service.slack.defaultSessionPrefix == "slack")
    }
    
    @Test("LayoutType Service Count and Labels")
    func layoutTypeProperties() {
        #expect(LayoutType.single.serviceCount == 1)
        #expect(LayoutType.single.serviceLabels == ["App Principal"])
        
        #expect(LayoutType.columns2.serviceCount == 2)
        #expect(LayoutType.columns2.serviceLabels == ["Panel Izquierdo", "Panel Derecho"])
        
        #expect(LayoutType.grid2x2.serviceCount == 4)
    }
    
    @Test("Service Instance Generation")
    func serviceInstanceGeneration() {
        // Without custom suffix
        let instance1 = ServiceInstance(service: .slack)
        #expect(instance1.sessionID == "slack")
        
        // With custom suffix
        let instance2 = ServiceInstance(service: .slack, customSuffix: "work")
        #expect(instance2.sessionID == "slack_work")
    }
}
