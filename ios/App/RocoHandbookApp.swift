import SwiftUI
import HandbookCore

@main
struct RocoHandbookApp: App {
    @StateObject private var model = AppModel()
    var body: some Scene {
        WindowGroup {
            RootView().environmentObject(model).environment(\.locale, model.locale)
                .task { await model.load() }
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var model: AppModel
    var body: some View {
        Group {
            if let session = model.session {
                HandbookTabs(session: session).id(session.generation)
            } else if let error = model.startupError {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle").font(.largeTitle)
                    Text(tr("The offline handbook could not be opened.")).font(.headline)
                    Text(tr(error)).foregroundColor(.secondary).multilineTextAlignment(.center)
                    Button(tr("Retry")) { Task { await model.load() } }.buttonStyle(.borderedProminent)
                    Button(tr("Restore bundled Catalog")) { Task { await model.load(restore: true) } }
                }.padding()
            } else {
                ProgressView(tr("Preparing offline Catalog...")).padding()
            }
        }
        .alert(tr("The operation could not be completed."), isPresented: Binding(
            get: { model.operationError != nil }, set: { if !$0 { model.operationError = nil } }
        )) { Button(tr("OK"), role: .cancel) { model.operationError = nil } }
        message: { Text(tr(model.operationError ?? "")) }
    }
}

private struct HandbookTabs: View {
    let session: HandbookSession
    @EnvironmentObject private var model: AppModel
    @State private var selectedTab = 0
    var body: some View {
        TabView(selection: $selectedTab) {
            AppNavigation { PetCatalogView(session: session) }.id(model.language)
                .tabItem { Label(tr("Creatures"), systemImage: "pawprint.fill") }.tag(0)
            AppNavigation { SkillCatalogView(session: session) }.id(model.language)
                .tabItem { Label(tr("Skills"), systemImage: "sparkles") }.tag(1)
            AppNavigation { ToolsView(session: session) }.id(model.language)
                .tabItem { Label(tr("Tools"), systemImage: "square.grid.2x2") }.tag(2)
            AppNavigation { SettingsView(session: session) }
                .tabItem { Label(tr("Settings"), systemImage: "gearshape") }.tag(3)
        }.tint(.blue)
    }
}

struct AppNavigation<Content: View>: View {
    @ViewBuilder let content: () -> Content
    var body: some View {
        if #available(iOS 16, *) {
            NavigationStack { content() }
        } else {
            NavigationView { content() }.navigationViewStyle(.stack)
        }
    }
}
