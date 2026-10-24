import SwiftUI
import HandbookCore

struct ToolsView: View {
    let session: HandbookSession
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HandbookPageHeader(
                    title: tr("Your adventure notebook"),
                    subtitle: tr("Everything for your next discovery"),
                    artworkPath: "wiki/v4/pets/illustrations/JL_miaomiao.png"
                )
                VStack(spacing: 10) {
                    NavigationLink(destination: SeasonArchiveView(session: session)) {
                        ToolCardLabel(title: tr("Season archive"), subtitle: tr("Follow every season"),
                                      systemImage: "calendar", accent: HandbookTheme.forestAccent)
                    }.accessibilityIdentifier("tools.seasons")
                    NavigationLink(destination: SkillCatalogView(session: session, features: true)) {
                        ToolCardLabel(title: tr("Feature handbook"), subtitle: tr("Discover what makes each creature special"),
                                      systemImage: "sparkle", accent: HandbookTheme.goldAccent)
                    }.accessibilityIdentifier("tools.features")
                    NavigationLink(destination: EggGroupsView(session: session)) {
                        ToolCardLabel(title: tr("Egg groups"), subtitle: tr("Find companions in the same egg group"),
                                      systemImage: "oval.portrait", accent: HandbookTheme.forestAccent)
                    }.accessibilityIdentifier("tools.eggGroups")
                    NavigationLink(destination: GameDescriptionsView(session: session)) {
                        ToolCardLabel(title: tr("Game descriptions"), subtitle: tr("Read battle terms and effects"),
                                      systemImage: "text.book.closed", accent: HandbookTheme.forestAccent)
                    }.accessibilityIdentifier("tools.descriptions")
                    NavigationLink(destination: ActivityTimelineView(session: session)) {
                        ToolCardLabel(title: tr("Activity timeline"), subtitle: tr("Browse events and their stories"),
                                      systemImage: "clock", accent: HandbookTheme.goldAccent)
                    }.accessibilityIdentifier("tools.activities")
                    NavigationLink(destination: OutfitsView(session: session)) {
                        ToolCardLabel(title: tr("Outfit inspiration"), subtitle: tr("Find your next favorite outfit"),
                                      systemImage: "tshirt", accent: HandbookTheme.forestAccent)
                    }.accessibilityIdentifier("tools.outfits")
                    NavigationLink(destination: PersonalLibraryView(session: session)) {
                        ToolCardLabel(title: tr("My library"), subtitle: tr("Keep your favorite discoveries"),
                                      systemImage: "star", accent: HandbookTheme.goldAccent)
                    }.accessibilityIdentifier("tools.library")
                }.buttonStyle(.plain)
            }.padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 28)
        }
        .background(HandbookTheme.paperBackground.ignoresSafeArea())
        .navigationTitle(tr("Tools"))
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("tools.home")
    }
}

private struct ToolCardLabel: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let accent: Color
    @Environment(\.dynamicTypeSize) private var textSize

    var body: some View {
        HStack(spacing: 12) {
            if !textSize.isAccessibilitySize {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(accent)
                    .frame(width: 36, height: 36)
                    .background(accent.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(HandbookTheme.display(16)).foregroundColor(.primary)
                Text(subtitle).font(.footnote).foregroundColor(HandbookTheme.paperSecondary)
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold)).foregroundColor(HandbookTheme.forestAccent)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
        .background(HandbookTheme.paperSurface)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(HandbookTheme.paperLine, lineWidth: 1))
        .contentShape(RoundedRectangle(cornerRadius: 18))
        .accessibilityElement(children: .combine)
    }
}

struct SeasonArchiveView: View {
    let session: HandbookSession
    var body: some View {
        List(["S1", "S2", "S3", "S4"], id: \.self) { season in
            NavigationLink(destination: PetCatalogView(session: session, title: season, initialQuery: query(season))) {
                Label(season, systemImage: "calendar")
            }
        }.navigationTitle(tr("Season archive"))
    }
    private func query(_ season: String) -> PetQuery { var result = PetQuery(); result.seasons = [season]; return result }
}

struct EggGroupsView: View {
    let session: HandbookSession
    @EnvironmentObject private var app: AppModel
    @State private var groups: [EggGroup] = []
    @State private var query = PetQuery()
    @State private var loading = true
    @State private var selected: [Int] = []
    @State private var error = false
    var body: some View {
        List {
            Section {
                TextField(tr("Search creatures or handbook number"), text: $query.keyword)
                    .textInputAutocapitalization(.never).disableAutocorrection(true)
            }
            Section(header: Text(tr("Egg groups"))) {
                if loading { ProgressView() }
                if error { Button(tr("Retry")) { Task { await load() } } }
                ForEach(groups) { group in
                    Button {
                        if selected.contains(group.id) { selected.removeAll { $0 == group.id } }
                        else { selected.append(group.id) }
                    } label: {
                        HStack {
                            Text("\(tr("Egg group")) \(group.id)").foregroundColor(.primary)
                            Spacer()
                            Text("\(group.memberCount)").foregroundColor(.secondary)
                            if selected.contains(group.id) { Image(systemName: "checkmark") }
                        }
                    }
                }
            }
            NavigationLink(destination: PetCatalogView(session: session, title: "Egg groups", initialQuery: resultQuery)) {
                Label(tr("Show creatures"), systemImage: "pawprint")
            }.accessibilityIdentifier("eggs.results")
        }.navigationTitle(tr("Egg groups")).task { await load() }
    }
    private var resultQuery: PetQuery { var result = query; result.eggGroupIDs = selected; return result }
    private func load() async {
        loading = true; error = false; defer { loading = false }
        do { groups = try await session.catalog.eggGroups() }
        catch { self.error = true; app.report(error) }
    }
}

struct GameDescriptionsView: View {
    let session: HandbookSession
    @EnvironmentObject private var app: AppModel
    @State private var catalog: DescriptionCatalog?
    @State private var keyword = ""
    @State private var category = ""
    @State private var error = false
    private var entries: [GameDescription] {
        catalog?.entries.filter {
            (category.isEmpty || $0.category == category) &&
                (keyword.isEmpty || $0.name.localizedCaseInsensitiveContains(keyword) || $0.description.localizedCaseInsensitiveContains(keyword))
        } ?? []
    }
    var body: some View {
        List {
            if let catalog {
                Picker(tr("Category"), selection: $category) {
                    Text(tr("All")).tag("")
                    ForEach(catalog.categoryOrder, id: \.self) { Text(catalog.categoryLabels[$0] ?? $0).tag($0) }
                }
                ForEach(entries) { entry in
                    NavigationLink(destination: DescriptionDetailView(session: session, entry: entry)) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(entry.name).font(.headline)
                            Text(entry.description).font(.subheadline).foregroundColor(.secondary).lineLimit(3)
                        }.padding(.vertical, 6)
                    }
                }
                if entries.isEmpty { EmptyState(text: "No results.") }
            } else if error { Button(tr("Retry")) { Task { await load() } } }
            else { ProgressView() }
        }.navigationTitle(tr("Game descriptions")).searchable(text: $keyword, prompt: tr("Search descriptions"))
            .task { await load() }.accessibilityIdentifier("tools.descriptionCatalog")
    }
    private func load() async {
        error = false
        do { catalog = try await session.assets.descriptions() } catch { self.error = true; app.report(error) }
    }
}

struct DescriptionDetailView: View {
    let session: HandbookSession
    let entry: GameDescription
    @EnvironmentObject private var app: AppModel
    @State private var skills: [SkillSummary] = []
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ReadingPanel(title: entry.name) { Text(entry.description).textSelection(.enabled) }
                if !skills.isEmpty {
                    ReadingPanel(title: "Related skills") {
                        ForEach(skills) { skill in
                            NavigationLink(destination: SkillDetailView(session: session, skillID: skill.id)) { SkillCard(skill: skill) }
                                .buttonStyle(.plain)
                        }
                    }
                }
            }.padding()
        }.background(HandbookTheme.background).navigationTitle(entry.name)
            .task { do { skills = try await session.catalog.skillsForNote(entry.id) } catch { app.report(error) } }
    }
}

struct ActivityTimelineView: View {
    let session: HandbookSession
    @EnvironmentObject private var app: AppModel
    @State private var catalog: ActivityCatalog?
    @State private var keyword = ""
    @State private var category = ""
    @State private var month = ""
    @State private var status = ""
    @State private var error = false
    private var entries: [ActivityEntry] {
        catalog?.entries.filter {
            (keyword.isEmpty || $0.name.localizedCaseInsensitiveContains(keyword) || ($0.summary ?? "").localizedCaseInsensitiveContains(keyword)) &&
                (category.isEmpty || $0.category == category) &&
                (month.isEmpty || monthKey($0.startDate) == month) &&
                (status.isEmpty || $0.status() == status)
        } ?? []
    }
    var body: some View {
        List {
            if let catalog {
                Section(header: Text(tr("Filters"))) {
                    Picker(tr("Month"), selection: $month) {
                        Text(tr("All")).tag("")
                        ForEach(Array(Set(catalog.entries.map { monthKey($0.startDate) })).sorted().reversed(), id: \.self) {
                            Text($0 == "undated" ? tr("Undated") : $0).tag($0)
                        }
                    }
                    Picker(tr("Category"), selection: $category) {
                        Text(tr("All")).tag("")
                        ForEach(catalog.categoryOrder, id: \.self) { Text(catalog.categoryLabels[$0] ?? $0).tag($0) }
                    }
                    Picker(tr("Status"), selection: $status) {
                        Text(tr("All")).tag("")
                        ForEach(["Upcoming", "Active", "Ended", "Unknown"], id: \.self) { Text(tr($0)).tag($0) }
                    }
                }
                ForEach(entries) { entry in
                    NavigationLink(destination: ActivityDetailView(entry: entry)) {
                        HStack(alignment: .top, spacing: 12) {
                            AssetImage(path: entry.iconPath.flatMap { try? AssetRepository.toolImage($0, prefix: "activities/icons/") },
                                       label: entry.name, size: 48)
                            VStack(alignment: .leading, spacing: 5) {
                                Text(entry.name).font(.headline)
                                Text("\(entry.kindLabel) · \(tr(entry.status()))").font(.caption).foregroundColor(.secondary)
                                if let start = entry.startAt { Text(start).font(.caption.monospacedDigit()).foregroundColor(.secondary) }
                                if let summary = entry.summary { Text(summary).font(.subheadline).lineLimit(2) }
                            }
                        }.padding(.vertical, 5)
                    }
                }
                if entries.isEmpty { EmptyState(text: "No results.") }
            } else if error { Button(tr("Retry")) { Task { await load() } } }
            else { ProgressView() }
        }.navigationTitle(tr("Activity timeline")).searchable(text: $keyword, prompt: tr("Search activities"))
            .task { await load() }.accessibilityIdentifier("tools.activityTimeline")
    }
    private func monthKey(_ date: Date?) -> String {
        guard let date else { return "undated" }
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian); formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Shanghai"); formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: date)
    }
    private func load() async {
        error = false
        do { catalog = try await session.assets.activities() } catch { self.error = true; app.report(error) }
    }
}

struct ActivityDetailView: View {
    let entry: ActivityEntry
    var body: some View {
        ScrollView {
            ReadingPanel(title: entry.name) {
                AssetImage(path: entry.iconPath.flatMap { try? AssetRepository.toolImage($0, prefix: "activities/icons/") },
                           label: entry.name, size: 90)
                fact("Category", entry.kindLabel)
                fact("Status", tr(entry.status()))
                if let start = entry.startAt { fact("Starts", start) }
                if let end = entry.endAt { fact("Ends", end) }
                if entry.masked { Text(tr("Some source details are masked.")).font(.caption) }
                if let description = entry.description { Text(description).textSelection(.enabled) }
                else if let summary = entry.summary { Text(summary).textSelection(.enabled) }
            }.padding()
        }.background(HandbookTheme.background).navigationTitle(entry.name).navigationBarTitleDisplayMode(.inline)
    }
}

struct OutfitsView: View {
    let session: HandbookSession
    @EnvironmentObject private var app: AppModel
    @State private var catalog: FashionCatalog?
    @State private var gender = "female"
    @State private var keyword = ""
    @State private var grade = ""
    @State private var error = false
    private var entries: [FashionEntry] {
        catalog?.entries.filter {
            (grade.isEmpty || $0.gradeName == grade) &&
                (keyword.isEmpty || $0.name.localizedCaseInsensitiveContains(keyword) || ($0.description ?? "").localizedCaseInsensitiveContains(keyword))
        } ?? []
    }
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if let catalog {
                    Picker(tr("Gender"), selection: $gender) {
                        Text(tr("Female")).tag("female"); Text(tr("Male")).tag("male")
                    }.pickerStyle(.segmented)
                    Picker(tr("Grade"), selection: $grade) {
                        Text(tr("All")).tag("")
                        ForEach(Array(Set(catalog.entries.map(\.gradeName))).sorted(), id: \.self) { Text($0).tag($0) }
                    }
                    ForEach(entries) { entry in
                        if let variant = entry.variants.first(where: { $0.gender == gender }) {
                            ReadingPanel(title: entry.name) {
                                AssetImage(path: try? AssetRepository.toolImage(variant.imagePath, prefix: "fashions/cards/"),
                                           label: "\(entry.name) · \(variant.genderLabel)", size: 270).frame(maxWidth: .infinity)
                                fact("Grade", entry.gradeName)
                                if let description = variant.description ?? entry.description { Text(description).textSelection(.enabled) }
                                Text(variant.acquisition.joined(separator: " · ")).font(.subheadline)
                                fact("Items", String(variant.itemCount))
                            }
                        }
                    }
                    if entries.isEmpty { EmptyState(text: "No results.") }
                } else if error { Button(tr("Retry")) { Task { await load() } } }
                else { ProgressView() }
            }.padding()
        }.background(HandbookTheme.background).navigationTitle(tr("Outfit inspiration"))
            .searchable(text: $keyword, prompt: tr("Search outfits")).task { await load() }
            .accessibilityIdentifier("tools.outfitsCatalog")
    }
    private func load() async {
        error = false
        do { catalog = try await session.assets.fashions() } catch { self.error = true; app.report(error) }
    }
}
