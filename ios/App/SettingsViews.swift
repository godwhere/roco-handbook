import SwiftUI
import HandbookCore

struct SettingsView: View {
    let session: HandbookSession
    @EnvironmentObject private var app: AppModel
    @Environment(\.sizeCategory) private var sizeCategory
    @State private var confirmRestore = false
    @State private var candidate: CatalogUpdateCandidate?
    @State private var updateTask: Task<Void, Never>?
    @State private var updating = false
    @State private var verifying = false
    @State private var receivedBytes = 0
    @State private var totalBytes = 0
    @State private var updateStatus: String?
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HandbookPageHeader(title: tr("Make it your handbook"),
                                   subtitle: tr("A little preparation for your next adventure"),
                                   artworkPath: "wiki/v4/pets/illustrations/JL_shuilanlan.png")
                SettingsPanel(title: tr("Appearance"), symbol: "paintpalette.fill") {
                    Text(tr("Creature catalog layout")).font(.subheadline.weight(.semibold))
                    creatureLayoutPicker
                    Divider().overlay(HandbookTheme.paperLine.opacity(0.5))
                    Text(tr("Skill card layout")).font(.subheadline.weight(.semibold))
                    skillLayoutPicker
                }
                SettingsPanel(title: tr("My library"), symbol: "star.fill") {
                    NavigationLink(destination: PersonalLibraryView(session: session)) {
                        actionLabel("Favorites, collection marks, and notes", symbol: "bookmark", disclosure: true)
                    }.accessibilityIdentifier("settings.library")
                    Text(tr("Saved only on this device")).font(.caption).foregroundColor(HandbookTheme.paperSecondary)
                }
                SettingsPanel(title: tr("Catalog"), symbol: "book.closed.fill") {
                    NavigationLink(destination: CatalogInfoView(session: session)) {
                        actionLabel("Catalog information", symbol: "info.circle", disclosure: true)
                    }.accessibilityIdentifier("settings.catalogInfo")
                    Divider().overlay(HandbookTheme.paperLine.opacity(0.5))
                    Button { check() } label: {
                        actionLabel("Check for Catalog updates", symbol: "arrow.down.circle")
                    }
                        .disabled(updating || app.busy).accessibilityIdentifier("settings.checkUpdates")
                    if let candidate {
                        Text("\(tr("Data version")) \(candidate.dataVersion)").font(.headline)
                        Text(ByteCountFormatter.string(fromByteCount: Int64(candidate.archiveBytes), countStyle: .file)).font(.caption)
                        Text(tr("Download over your current connection?")).font(.caption).foregroundColor(HandbookTheme.paperSecondary)
                    Button { install(candidate) } label: {
                        Text(tr("Download")).frame(maxWidth: .infinity, minHeight: 44)
                            .contentShape(Rectangle())
                    }.buttonStyle(.borderedProminent).disabled(updating)
                    }
                    if updating {
                        if totalBytes > 0, !verifying {
                            ProgressView(value: Double(receivedBytes), total: Double(totalBytes))
                            Text("\(receivedBytes) / \(totalBytes)").font(.caption.monospacedDigit())
                        } else { ProgressView() }
                        if !verifying {
                            Button(role: .cancel) { updateTask?.cancel() } label: {
                                Text(tr("Cancel")).frame(maxWidth: .infinity, minHeight: 44)
                                    .contentShape(Rectangle())
                            }.buttonStyle(.bordered)
                        }
                    }
                    if let updateStatus { Text(tr(updateStatus)).font(.caption).foregroundColor(HandbookTheme.paperSecondary) }
                    Divider().overlay(HandbookTheme.paperLine.opacity(0.5))
                    Button { confirmRestore = true } label: {
                        actionLabel("Restore bundled Catalog", symbol: "arrow.counterclockwise")
                    }
                        .disabled(updating || app.busy).accessibilityIdentifier("settings.restore")
                    Text(tr("Favorites, collection marks, and notes are kept.")).font(.caption).foregroundColor(HandbookTheme.paperSecondary)
                    Text(tr(session.outcome)).font(.caption).foregroundColor(HandbookTheme.paperSecondary)
                }
                SettingsPanel(title: tr("About"), symbol: "leaf.fill") {
                    fact("App version", "\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""))")
                        .font(.subheadline)
                    Text(tr("Independent, non-commercial, and unofficial.")).font(.subheadline)
                    NavigationLink(destination: AttributionView(session: session)) {
                        actionLabel("Source and licenses", symbol: "doc.text", disclosure: true)
                    }.accessibilityIdentifier("settings.licenses")
                    Text(tr("The handbook works offline. Updates are checked only when you ask."))
                        .font(.caption).foregroundColor(HandbookTheme.paperSecondary)
                }
            }.padding(16).padding(.bottom, 24)
        }.background(HandbookTheme.paperBackground.ignoresSafeArea())
            .tint(HandbookTheme.forestAccent).buttonStyle(.plain)
            .navigationTitle(tr("Settings")).navigationBarTitleDisplayMode(.inline)
            .accessibilityIdentifier("settings.home")
            .alert(tr("Restore bundled Catalog?"), isPresented: $confirmRestore) {
                Button(tr("Cancel"), role: .cancel) {}
                Button(tr("Restore Catalog")) { Task { await app.load(restore: true) } }
            } message: {
                Text(tr("This replaces only the offline Catalog with the version included in this App. Favorites, collection marks, and notes are kept. The bundled version may be older than the current Catalog."))
            }.onDisappear { updateTask?.cancel() }
    }
    @ViewBuilder private var creatureLayoutPicker: some View {
        let picker = Picker(tr("Creature catalog layout"), selection: Binding(
            get: { app.layout }, set: { value in Task { await app.setLayout(value) } }
        )) {
            Text(tr("Three columns")).tag(PetCatalogLayout.threeColumn)
            Text(tr("Grid")).tag(PetCatalogLayout.grid)
            Text(tr("List")).tag(PetCatalogLayout.list)
        }.accessibilityIdentifier("settings.layout")
        if sizeCategory.isAccessibilityCategory {
            picker.pickerStyle(.menu).frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        } else { picker.pickerStyle(.segmented) }
    }
    @ViewBuilder private var skillLayoutPicker: some View {
        let picker = Picker(tr("Skill card layout"), selection: Binding(
            get: { app.skillLayout }, set: { value in Task { await app.setSkillLayout(value) } }
        )) {
            ForEach(SkillCatalogLayout.allCases, id: \.self) { layout in Text(layout.title).tag(layout) }
        }.accessibilityIdentifier("settings.skillLayout")
        if sizeCategory.isAccessibilityCategory {
            picker.pickerStyle(.menu).frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        } else { picker.pickerStyle(.segmented) }
    }
    private func actionLabel(_ title: String, symbol: String, disclosure: Bool = false) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol).frame(width: 22).foregroundColor(HandbookTheme.forestAccent)
                .accessibilityHidden(true)
            Text(tr(title)).font(.subheadline).foregroundColor(.primary).fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            if disclosure {
                Image(systemName: "chevron.right").font(.caption.weight(.semibold))
                    .foregroundColor(HandbookTheme.goldAccent).accessibilityHidden(true)
            }
        }.frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .contentShape(Rectangle())
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

private struct SettingsPanel<Content: View>: View {
    let title: String
    let symbol: String
    @ViewBuilder let content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 9) {
                Image(systemName: symbol).foregroundColor(HandbookTheme.goldAccent).accessibilityHidden(true)
                Text(title).font(HandbookTheme.display(17)).foregroundColor(HandbookTheme.forestAccent)
            }.accessibilityAddTraits(.isHeader)
            content
        }.padding(14).frame(maxWidth: .infinity, alignment: .leading)
            .background(HandbookTheme.paperSurface)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(HandbookTheme.paperLine.opacity(0.8), lineWidth: 1))
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
