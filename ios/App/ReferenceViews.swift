import SwiftUI
import HandbookCore

extension ReferenceCatalogKind {
    var titleKey: String {
        switch self {
        case .items: return "Item reference"
        case .research: return "Handbook research"
        case .medals: return "Medal reference"
        case .trials: return "Trial encounters"
        case .habitats: return "Areas and habitats"
        }
    }
    var entranceImagePath: String {
        switch self {
        case .items: return "wiki/references/v1/icons/Item_100002.png"
        case .research: return "wiki/v4/pets/illustrations/JL_dimo.png"
        case .medals: return "wiki/references/v1/icons/Medal_1001.png"
        case .trials: return "wiki/v4/pets/illustrations/JL_miaomiao.png"
        case .habitats: return "wiki/v4/ui/types/water.png"
        }
    }
}

struct ReferenceCatalogView: View {
    let session: HandbookSession
    let kind: ReferenceCatalogKind
    @EnvironmentObject private var app: AppModel
    @State private var catalog: ReferenceCatalog?
    @State private var keyword = ""
    @State private var groupID = ""
    @State private var progress: Set<String> = []
    @State private var progressLoaded = false
    @State private var failed = false
    @State private var showingSources = false
    @FocusState private var searchFocused: Bool
    private var entries: [ReferenceEntry] {
        let query = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        let groupNames = Dictionary(uniqueKeysWithValues: (catalog?.groups ?? []).map { ($0.id, $0.title) })
        return catalog?.visibleEntries.filter { entry in
            guard groupID.isEmpty || entry.groupId == groupID else { return false }
            guard !query.isEmpty else { return true }
            let text = [entry.id, entry.name, groupNames[entry.groupId] ?? "", entry.subtitle ?? "", entry.description ?? ""] + entry.sections.flatMap(\.lines)
            return text.contains { $0.localizedCaseInsensitiveContains(query) }
        } ?? []
    }
    var body: some View {
        VStack(spacing: 0) {
            if let catalog {
                let visible = entries
                controls(catalog, entries: visible)
                ScrollView {
                    LazyVStack(spacing: 10) {
                        if kind == .habitats { habitatNotice }
                        if kind == .trials {
                            referenceNotice("Mark encounters manually. This does not record creature ownership.")
                        }
                        ForEach(visible) { entry in
                            NavigationLink(destination: ReferenceEntryDetailView(session: session, kind: kind, entry: entry,
                                                                               sources: catalog.sources, snapshotID: catalog.snapshotId)) {
                                ReferenceEntryCard(entry: entry,
                                                   groupTitle: catalog.groups.first { $0.id == entry.groupId }?.title,
                                                   completed: kind.supportsProgress && progressLoaded
                                                       ? progress.contains(entry.progressId ?? "") : nil)
                            }.buttonStyle(.plain).accessibilityIdentifier("reference.\(kind.rawValue).entry.\(entry.id)")
                        }
                        if visible.isEmpty { EmptyState(text: "No results.") }
                    }.padding(16).padding(.bottom, 12)
                }
            } else if failed {
                Button(tr("Retry")) { Task { await load() } }.frame(minWidth: 44, minHeight: 44)
            } else { ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity) }
        }.background(HandbookWikiBackground()).tint(HandbookWikiTheme.accent)
            .navigationTitle(tr(kind.titleKey)).navigationBarTitleDisplayMode(.inline)
            .task { await load() }.task(id: app.userRevision) { await loadProgress() }
            .sheet(isPresented: $showingSources) {
                if let catalog { ReferenceSourcesView(sources: catalog.sources, snapshotID: catalog.snapshotId) }
            }
    }
    private func controls(_ catalog: ReferenceCatalog, entries: [ReferenceEntry]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundColor(HandbookWikiTheme.secondary).accessibilityHidden(true)
                TextField(tr("Search reference entries"), text: $keyword).font(.subheadline)
                    .textInputAutocapitalization(.never).disableAutocorrection(true).submitLabel(.search)
                    .focused($searchFocused).onSubmit { searchFocused = false }
                    .accessibilityIdentifier("reference.\(kind.rawValue).search")
                if !keyword.isEmpty {
                    Button { keyword = ""; searchFocused = false } label: {
                        Image(systemName: "xmark.circle.fill").frame(minWidth: 44, minHeight: 44).contentShape(Rectangle())
                    }.accessibilityLabel(tr("Clear search")).accessibilityIdentifier("reference.\(kind.rawValue).clear")
                }
            }.padding(.leading, 10).frame(minHeight: 44).background(HandbookWikiTheme.background)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            HStack(alignment: .top, spacing: 8) {
                Menu {
                    Picker(tr("Group"), selection: $groupID) {
                        Text(tr("All groups")).tag("")
                        ForEach(catalog.groups) { group in Text(group.title).tag(group.id) }
                    }.pickerStyle(.inline)
                } label: {
                    HStack(spacing: 8) {
                        Text(catalog.groups.first { $0.id == groupID }?.title ?? tr("All groups"))
                            .font(.subheadline).fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.down").font(.caption).accessibilityHidden(true)
                    }.padding(.horizontal, 10).frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        .contentShape(Rectangle()).background(HandbookWikiTheme.background)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }.accessibilityLabel(tr("Group"))
                    .accessibilityValue(catalog.groups.first { $0.id == groupID }?.title ?? tr("All groups"))
                    .accessibilityIdentifier("reference.\(kind.rawValue).group")
                    .onChange(of: groupID) { _ in searchFocused = false }
                referenceSourceButton(identifier: "reference.\(kind.rawValue).sources") { showingSources = true }
            }
            Text("\(tr("Entries")) · \(entries.count)").font(.caption).foregroundColor(HandbookWikiTheme.secondary)
                .accessibilityIdentifier("reference.\(kind.rawValue).count")
            if kind.supportsProgress, progressLoaded {
                Text("\(tr("Completed")) · \(entries.filter { progress.contains($0.progressId ?? "") }.count) / \(entries.count)")
                    .font(.caption).foregroundColor(HandbookWikiTheme.secondary)
                    .accessibilityIdentifier("reference.\(kind.rawValue).progressCount")
            }
        }.padding(.horizontal, 16).padding(.vertical, 10).background(HandbookWikiTheme.surface)
            .overlay(alignment: .bottom) { Divider().overlay(HandbookWikiTheme.line) }
    }
    private func load() async {
        failed = false
        do { catalog = try await session.assets.referenceCatalog(kind) }
        catch { failed = true; app.report(error) }
    }
    private func loadProgress() async {
        guard kind.supportsProgress else { return }
        let revision = app.userRevision
        do {
            let saved = try await session.user.referenceProgress(kind)
            guard !Task.isCancelled, app.userRevision == revision else { return }
            progress = saved; progressLoaded = true
        } catch {
            guard !Task.isCancelled, app.userRevision == revision else { return }
            progressLoaded = false; app.report(error)
        }
    }
}

private struct ReferenceEntryCard: View {
    let entry: ReferenceEntry
    let groupTitle: String?
    let completed: Bool?
    var body: some View {
        ReferencePanel {
            HStack(alignment: .top, spacing: 12) {
                AssetImage(path: entry.imagePath, label: "", size: 60).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 6) {
                    Text(entry.name).font(HandbookTheme.display(16)).foregroundColor(HandbookWikiTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    if let subtitle = entry.subtitle ?? groupTitle { Text(subtitle).font(.caption).foregroundColor(HandbookWikiTheme.secondary) }
                    if let description = entry.description { Text(description).font(.caption).foregroundColor(HandbookWikiTheme.secondary).lineLimit(2) }
                    if let completed {
                        Label(tr(completed ? "Completed" : "Incomplete"), systemImage: completed ? "checkmark.circle.fill" : "circle")
                            .font(.caption).foregroundColor(HandbookWikiTheme.accent)
                    }
                }.frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right").font(.caption).foregroundColor(HandbookWikiTheme.secondary).accessibilityHidden(true)
            }.frame(minHeight: 60).accessibilityElement(children: .combine)
        }
    }
}

struct ReferenceEntryDetailView: View {
    let session: HandbookSession
    let kind: ReferenceCatalogKind
    let entry: ReferenceEntry
    let sources: [ReferenceSource]
    let snapshotID: String
    @EnvironmentObject private var app: AppModel
    @Environment(\.sizeCategory) private var sizeCategory
    @State private var completed = false
    @State private var progressLoaded = false
    @State private var saving = false
    @State private var showingSources = false
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                ReferencePanel {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top, spacing: 12) {
                            AssetImage(path: entry.imagePath, label: entry.name, size: 76).accessibilityHidden(true)
                            if !sizeCategory.isAccessibilityCategory { identity }
                            Spacer(minLength: 0)
                            referenceSourceButton(identifier: "reference.detail.sources") { showingSources = true }
                        }
                        if sizeCategory.isAccessibilityCategory { identity }
                        if let description = entry.description { Text(description).font(.subheadline).textSelection(.enabled) }
                        if kind.supportsProgress, let progressID = entry.progressId {
                            Button { save(progressID) } label: {
                                Label(tr(completed ? "Completed" : "Mark complete"), systemImage: completed ? "checkmark.circle.fill" : "circle")
                                    .font(.subheadline.weight(.semibold)).fixedSize(horizontal: false, vertical: true)
                                    .padding(.horizontal, 10).padding(.vertical, 8)
                                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading).contentShape(Rectangle())
                                    .background(completed ? HandbookWikiTheme.blue : HandbookWikiTheme.background)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }.buttonStyle(.plain).disabled(!progressLoaded || saving)
                                .accessibilityValue(tr(completed ? "Yes" : "No"))
                                .accessibilityAddTraits(completed ? .isSelected : [])
                                .accessibilityIdentifier("reference.\(kind.rawValue).completion.\(progressID)")
                            Text(tr("Saved only on this device")).font(.caption).foregroundColor(HandbookWikiTheme.secondary)
                            if kind == .research {
                                Text(tr("Completion is shared across handbook forms.")).font(.caption).foregroundColor(HandbookWikiTheme.secondary)
                            }
                        }
                    }
                }
                if kind == .habitats { habitatNotice }
                if kind == .trials { referenceNotice("Mark encounters manually. This does not record creature ownership.") }
                ForEach(Array(entry.sections.enumerated()), id: \.offset) { index, section in
                    ReferencePanel {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(tr(section.title)).font(HandbookTheme.display(16)).accessibilityAddTraits(.isHeader)
                                .accessibilityIdentifier("reference.section.title.\(index)")
                            ForEach(Array(section.lines.enumerated()), id: \.offset) { lineIndex, line in
                                Text(line).font(.subheadline).fixedSize(horizontal: false, vertical: true).textSelection(.enabled)
                                    .accessibilityIdentifier("reference.section.\(index).line.\(lineIndex)")
                            }
                        }
                    }
                }
                if !entry.links.isEmpty {
                    ReferencePanel {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(tr("Related references")).font(HandbookTheme.display(16)).accessibilityAddTraits(.isHeader)
                            ForEach(Array(entry.links.enumerated()), id: \.offset) { _, link in
                                linkedEntry(link)
                            }
                        }
                    }
                }
            }.padding(16).padding(.bottom, 12)
        }.background(HandbookWikiBackground()).tint(HandbookWikiTheme.accent)
            .navigationTitle(entry.name).navigationBarTitleDisplayMode(.inline)
            .task(id: app.userRevision) { await loadProgress() }
            .sheet(isPresented: $showingSources) { ReferenceSourcesView(sources: sources, snapshotID: snapshotID) }
    }
    private var identity: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(entry.name).font(HandbookTheme.display(18)).fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("reference.detail.name")
            if let subtitle = entry.subtitle { Text(subtitle).font(.caption).foregroundColor(HandbookWikiTheme.secondary) }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
    @ViewBuilder private func linkedEntry(_ link: ReferenceLink) -> some View {
        if link.kind == "pet" {
            NavigationLink(destination: PetDetailView(session: session, petID: link.id)) { linkLabel(link.name) }
                .accessibilityIdentifier("reference.link.pet.\(link.id)")
        } else if link.kind == "item" {
            NavigationLink(destination: ReferenceLinkedItemView(session: session, itemID: link.id)) { linkLabel(link.name) }
                .accessibilityIdentifier("reference.link.item.\(link.id)")
        }
    }
    private func linkLabel(_ name: String) -> some View {
        HStack(spacing: 10) {
            Text(name).font(.subheadline).fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(.caption).accessibilityHidden(true)
        }.padding(.horizontal, 10).padding(.vertical, 8).frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .contentShape(Rectangle()).background(HandbookWikiTheme.background).clipShape(RoundedRectangle(cornerRadius: 8))
    }
    private func loadProgress() async {
        guard kind.supportsProgress, let progressID = entry.progressId else { return }
        let revision = app.userRevision
        do {
            let saved = try await session.user.referenceProgress(kind)
            guard !Task.isCancelled, app.userRevision == revision, !saving else { return }
            completed = saved.contains(progressID); progressLoaded = true
        } catch {
            guard !Task.isCancelled, app.userRevision == revision, !saving else { return }
            progressLoaded = false; app.report(error)
        }
    }
    private func save(_ progressID: String) {
        saving = true
        Task {
            defer { saving = false }
            do {
                let next = !completed
                try await session.user.setReferenceProgress(kind, id: progressID, completed: next)
                completed = next; app.changed()
            } catch { app.report(error) }
        }
    }
}

private struct ReferenceLinkedItemView: View {
    let session: HandbookSession
    let itemID: String
    @EnvironmentObject private var app: AppModel
    @State private var catalog: ReferenceCatalog?
    @State private var failed = false
    var body: some View {
        Group {
            if let catalog, let entry = catalog.entries.first(where: { $0.id == itemID }) {
                ReferenceEntryDetailView(session: session, kind: .items, entry: entry, sources: catalog.sources, snapshotID: catalog.snapshotId)
            } else if failed || catalog != nil { EmptyState(text: "This reference is unavailable in the offline supplement.") }
            else { ProgressView() }
        }.task {
            do { catalog = try await session.assets.referenceCatalog(.items) }
            catch { failed = true; app.report(error) }
        }
    }
}

private struct ReferenceSourcesView: View {
    let sources: [ReferenceSource]
    let snapshotID: String
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Text(tr("Source")).font(HandbookTheme.display(18)).accessibilityAddTraits(.isHeader)
                Spacer()
                Button { dismiss() } label: {
                    Text(tr("Done")).frame(minWidth: 44, minHeight: 44).contentShape(Rectangle())
                }.accessibilityIdentifier("reference.sources.done")
            }.padding(.horizontal, 16).padding(.top, 8)
            ScrollView {
                LazyVStack(spacing: 12) {
                    Text(snapshotID).font(.caption).foregroundColor(HandbookWikiTheme.secondary)
                        .accessibilityIdentifier("reference.source.snapshot")
                    ForEach(sources) { source in
                        ReferencePanel {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(source.title).font(.headline).textSelection(.enabled)
                                fact("Source revision", String(source.revisionId))
                                Text(source.revisedAtUtc).font(.caption).foregroundColor(HandbookWikiTheme.secondary)
                                Text(source.url).font(.footnote).textSelection(.enabled)
                                    .accessibilityIdentifier("reference.source.url.\(source.pageId)")
                                Text("SHA-1 · \(source.sha1)").font(.caption2.monospaced()).textSelection(.enabled)
                                Text("SHA-256 · \(source.sha256)").font(.caption2.monospaced()).textSelection(.enabled)
                            }
                        }
                    }
                }.padding(16)
            }
        }.background(HandbookWikiBackground()).tint(HandbookWikiTheme.accent)
    }
}

private struct ReferencePanel<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        content.padding(14).frame(maxWidth: .infinity, alignment: .leading)
            .background(HandbookWikiTheme.surface).clipShape(RoundedRectangle(cornerRadius: 9))
            .overlay(RoundedRectangle(cornerRadius: 9).stroke(HandbookWikiTheme.line, lineWidth: 0.5))
    }
}

private func referenceSourceButton(identifier: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        Image(systemName: "doc.text").font(.subheadline).frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle()).background(HandbookWikiTheme.background).clipShape(RoundedRectangle(cornerRadius: 8))
    }.buttonStyle(.plain).accessibilityLabel(tr("Source")).accessibilityIdentifier(identifier)
}

private func referenceNotice(_ text: String) -> some View {
    ReferencePanel { Text(tr(text)).font(.caption).foregroundColor(HandbookWikiTheme.secondary) }
}

private var habitatNotice: some View {
    referenceNotice("Habitat records describe areas and layers. Some locations are estimated and are not exact spawn points.")
        .accessibilityIdentifier("reference.habitat.notice")
}
