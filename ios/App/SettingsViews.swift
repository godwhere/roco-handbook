import SwiftUI
import HandbookCore

struct SettingsView: View {
    let session: HandbookSession
    @EnvironmentObject private var app: AppModel
    @State private var confirmRestore = false
    @State private var candidate: CatalogUpdateCandidate?
    @State private var updateTask: Task<Void, Never>?
    @State private var updating = false
    @State private var verifying = false
    @State private var receivedBytes = 0
    @State private var totalBytes = 0
    @State private var updateStatus: String?
    var body: some View {
        Form {
            Section(header: Text(tr("Appearance"))) {
                Picker(tr("Creature catalog layout"), selection: Binding(
                    get: { app.layout }, set: { value in Task { await app.setLayout(value) } }
                )) {
                    Text(tr("Three columns")).tag(PetCatalogLayout.threeColumn)
                    Text(tr("Grid")).tag(PetCatalogLayout.grid)
                    Text(tr("List")).tag(PetCatalogLayout.list)
                }.pickerStyle(.segmented).accessibilityIdentifier("settings.layout")
                Picker(tr("Skill card layout"), selection: Binding(
                    get: { app.skillLayout }, set: { value in Task { await app.setSkillLayout(value) } }
                )) {
                    ForEach(SkillCatalogLayout.allCases, id: \.self) { layout in Text(layout.title).tag(layout) }
                }.pickerStyle(.segmented).accessibilityIdentifier("settings.skillLayout")
            }
            Section(header: Text(tr("My library"))) {
                NavigationLink(destination: PersonalLibraryView(session: session)) {
                    Label(tr("Favorites, collection marks, and notes"), systemImage: "star")
                }
                Text(tr("Saved only on this device")).font(.caption).foregroundColor(.secondary)
            }
            Section(header: Text(tr("Catalog"))) {
                NavigationLink(tr("Catalog information"), destination: CatalogInfoView(session: session))
                Button(tr("Check for Catalog updates")) { check() }
                    .disabled(updating || app.busy).accessibilityIdentifier("settings.checkUpdates")
                if let candidate {
                    Text("\(tr("Data version")) \(candidate.dataVersion)").font(.headline)
                    Text(ByteCountFormatter.string(fromByteCount: Int64(candidate.archiveBytes), countStyle: .file)).font(.caption)
                    Text(tr("Download over your current connection?")).font(.caption).foregroundColor(.secondary)
                    Button(tr("Download")) { install(candidate) }.disabled(updating)
                }
                if updating {
                    if totalBytes > 0, !verifying {
                        ProgressView(value: Double(receivedBytes), total: Double(totalBytes))
                        Text("\(receivedBytes) / \(totalBytes)").font(.caption.monospacedDigit())
                    } else { ProgressView() }
                    if !verifying { Button(tr("Cancel"), role: .cancel) { updateTask?.cancel() } }
                }
                if let updateStatus { Text(tr(updateStatus)).font(.caption).foregroundColor(.secondary) }
                Button(tr("Restore bundled Catalog")) { confirmRestore = true }
                    .disabled(updating || app.busy).accessibilityIdentifier("settings.restore")
                Text(tr("Favorites, collection marks, and notes are kept.")).font(.caption).foregroundColor(.secondary)
                Text(tr(session.outcome)).font(.caption).foregroundColor(.secondary)
            }
            Section(header: Text(tr("About"))) {
                fact("App version", "\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""))")
                Text(tr("Independent, non-commercial, and unofficial."))
                NavigationLink(destination: AttributionView(session: session)) { Text(tr("Source and licenses")) }
                Text(tr("The handbook works offline. Updates are checked only when you ask."))
                    .font(.caption).foregroundColor(.secondary)
            }
        }.navigationTitle(tr("Settings")).accessibilityIdentifier("settings.home")
            .alert(tr("Restore bundled Catalog?"), isPresented: $confirmRestore) {
                Button(tr("Cancel"), role: .cancel) {}
                Button(tr("Restore Catalog")) { Task { await app.load(restore: true) } }
            } message: {
                Text(tr("This replaces only the offline Catalog with the version included in this App. Favorites, collection marks, and notes are kept. The bundled version may be older than the current Catalog."))
            }.onDisappear { updateTask?.cancel() }
    }
    private func check() {
        updating = true; candidate = nil; verifying = false; totalBytes = 0; updateStatus = "Checking for Catalog updates..."
        updateTask = Task {
            defer { updating = false }
            do {
                candidate = try await session.updateService.check(currentDataVersion: session.info.dataVersion)
                updateStatus = candidate == nil ? "No Catalog update is published." : "A verified Catalog update is available."
            } catch is CancellationError { updateStatus = "Catalog update cancelled. Current Catalog unchanged." }
            catch let error as URLError where error.code == .cancelled { updateStatus = "Catalog update cancelled. Current Catalog unchanged." }
            catch { updateStatus = nil; app.report(error) }
        }
    }
    private func install(_ candidate: CatalogUpdateCandidate) {
        updating = true; verifying = false; updateStatus = "Downloading Catalog update..."
        updateTask = Task {
            defer { updating = false }
            do {
                let open = try await session.updateService.install(candidate, currentDataVersion: session.info.dataVersion) { progress in
                    await MainActor.run {
                        switch progress {
                        case .downloading(let received, let total): receivedBytes = received; totalBytes = total
                        case .verifying: verifying = true; updateStatus = "Verifying and installing..."
                        }
                    }
                }
                try await app.acceptUpdate(open)
                self.candidate = nil; updateStatus = "Installed a verified Catalog package"
            } catch is CancellationError { updateStatus = "Catalog update cancelled. Current Catalog unchanged." }
            catch let error as URLError where error.code == .cancelled { updateStatus = "Catalog update cancelled. Current Catalog unchanged." }
            catch { updateStatus = nil; app.report(error) }
        }
    }
}

struct CatalogInfoView: View {
    let session: HandbookSession
    var body: some View {
        List {
            Section(header: Text(tr("Catalog information"))) {
                fact("Data version", String(session.info.dataVersion))
                fact("Schema version", String(session.info.schemaVersion))
                fact("Dataset", session.info.datasetID)
                fact("Snapshot", session.info.snapshotID)
                fact("Catalog built", session.info.builtAt)
                fact("Builder version", session.info.builderVersion)
                fact("Adapter version", session.info.adapterVersion)
                fact("Earliest source revision", session.info.earliestRevision)
                fact("Latest source revision", session.info.latestRevision)
            }
            Section(header: Text(tr("Coverage"))) {
                ForEach(session.info.coverage.keys.sorted(), id: \.self) { key in
                    fact(key.replacingOccurrences(of: "_", with: " "), tr(session.info.coverage[key] == true ? "Yes" : "No"))
                }
            }
            NavigationLink(destination: AttributionView(session: session)) { Text(tr("Source and licenses")) }
        }.navigationTitle(tr("Catalog information")).navigationBarTitleDisplayMode(.inline)
    }
}

struct AttributionView: View {
    let session: HandbookSession
    @State private var sources: [VisualSource] = []
    @State private var sourceError = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(session.attribution)
                Text(tr("Frozen image and font sources")).font(.headline)
                if sourceError { Text(tr("The frozen visual sources could not be loaded.")) }
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(sources) { source in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(source.name).font(.headline)
                            Text(source.url).font(.caption)
                            if let date = source.frozenAt { Text(date).font(.caption).foregroundColor(.secondary) }
                        }
                    }
                }
            }.font(.subheadline).textSelection(.enabled).padding()
        }.navigationTitle(tr("Source and licenses")).navigationBarTitleDisplayMode(.inline)
            .task {
                do { sources = try await session.assets.visualSources() }
                catch { sourceError = true }
            }
    }
}
