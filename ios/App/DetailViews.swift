import SwiftUI
import HandbookCore

private struct SectionPositions: PreferenceKey {
    static var defaultValue: [String: CGFloat] = [:]
    static func reduce(value: inout [String: CGFloat], nextValue: () -> [String: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { _, next in next })
    }
}

struct PetDetailView: View {
    let session: HandbookSession
    let petID: String
    @EnvironmentObject private var app: AppModel
    @State private var detail: PetDetail?
    @State private var skills: PetSkillBundle?
    @State private var evolution: EvolutionGraph?
    @State private var relationships: TypeRelationships?
    @State private var error: String?
    @State private var shiny = false
    @State private var skillTypes: [String] = []
    @State private var skillElement = ""
    @State private var currentSection = "Basic information"
    @State private var hint: String?
    private let sections = ["Basic information", "Feature", "Base stats", "Skills", "Evolution", "Type relationships", "My library", "Source"]

    var body: some View {
        Group {
            if let detail {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 16) {
                            anchor("Basic information") { basic(detail) }
                            anchor("Feature") { feature }
                            anchor("Base stats") { stats(detail) }
                            anchor("Skills") { skillPanel }
                            anchor("Evolution") { evolutionPanel }
                            anchor("Type relationships") { typePanel }
                            anchor("My library") {
                                PersonalPanel(session: session, object: object(detail.summary), handbookID: detail.summary.handbookID)
                            }
                            anchor("Source") { SourcePanel(references: detail.sources) }
                        }.padding(16).padding(.bottom, 24)
                    }.coordinateSpace(name: "petDetail")
                        .onPreferenceChange(SectionPositions.self) { positions in
                            let passed = positions.filter { $0.value <= 90 }.max { $0.value < $1.value }
                            currentSection = passed?.key ?? sections[0]
                        }
                        .overlay(alignment: .trailing) {
                            VStack(spacing: 15) {
                                ForEach(sections, id: \.self) { section in
                                    Button {
                                        withAnimation { proxy.scrollTo(section, anchor: .top) }
                                    } label: {
                                        Circle().fill(currentSection == section ? Color.accentColor : Color.secondary.opacity(0.35))
                                            .frame(width: 7, height: 7).frame(width: 30, height: 30)
                                    }.accessibilityLabel(tr(section)).accessibilityIdentifier("detail.section.\(section)")
                                        .onLongPressGesture { hint = section }
                                }
                            }.padding(.trailing, 2)
                                .overlay(alignment: .trailing) {
                                    if let hint {
                                        Text(tr(hint)).font(.caption).padding(10).background(HandbookTheme.surface)
                                            .clipShape(Capsule()).offset(x: -34).fixedSize()
                                            .onTapGesture { self.hint = nil }
                                    }
                                }
                        }
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) { FavoriteButton(session: session, object: object(detail.summary)) }
                }
            } else if let error {
                VStack { EmptyState(text: error); Button(tr("Retry")) { Task { await load() } } }
            } else { ProgressView() }
        }.background(HandbookTheme.background)
            .navigationTitle(detail?.summary.name ?? tr("Creature"))
            .navigationBarTitleDisplayMode(.inline).navigationBarHidden(false)
            .task(id: petID) { await load() }
    }
    private func object(_ pet: PetSummary) -> ObjectRef { ObjectRef(type: .pet, objectID: pet.id, name: pet.name) }
    private func load() async {
        error = nil
        do {
            async let record = session.catalog.petDetail(petID)
            async let kit = session.catalog.petSkills(petID)
            async let graph = session.catalog.evolutions(petID)
            let loaded = try await record
            let loadedKit = try await kit
            let loadedGraph = try await graph
            let loadedTypes = try await session.assets.relationships(for: loaded.summary.types)
            guard !Task.isCancelled else { return }
            detail = loaded; skills = loadedKit; evolution = loadedGraph; relationships = loadedTypes
        } catch { if !Task.isCancelled { self.error = "This creature is unavailable in the current Catalog." } }
    }
    private func anchor<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        content().id(title).background(GeometryReader { geometry in
            Color.clear.preference(key: SectionPositions.self, value: [title: geometry.frame(in: .named("petDetail")).minY])
        })
    }
    private func basic(_ detail: PetDetail) -> some View {
        ReadingPanel(title: "Basic information") {
            HStack {
                Text(detail.summary.name).font(HandbookTheme.display(26, relativeTo: .title))
                TypeIcons(types: detail.summary.types)
            }
            Text("NO.\(detail.summary.dexNo)").font(.subheadline.monospacedDigit()).foregroundColor(.secondary)
            if detail.summary.hasShiny {
                Picker(tr("Illustration"), selection: $shiny) {
                    Text(tr("Original")).tag(false); Text(tr("Shiny")).tag(true)
                }.pickerStyle(.segmented).accessibilityIdentifier("detail.shiny")
            }
            AssetImage(path: CatalogAssets.pet(detail.summary.illustrationKey, shiny: shiny), label: detail.summary.name, size: 250)
                .frame(maxWidth: .infinity)
            if let description = detail.description { Text(description).textSelection(.enabled) }
            if let className = detail.className { fact("Class", className) }
            if detail.summary.isLordEvolution { fact("Form", tr("Lord form")) }
            else if let stage = detail.summary.stage {
                fact("Form", tr(stage == 1 ? "First form" : stage == 2 ? "Second form" : stage == 3 ? "Third form" : "Unknown"))
            }
            if let form = detail.summary.form, !detail.summary.isDefaultForm { fact("Regional form", form) }
            if let season = detail.summary.season { fact("Season", season) }
            fact("Height", detail.height ?? "—")
            fact("Weight", detail.weight ?? "—")
            fact("Starlight", detail.starlight.map(String.init) ?? "—")
            fact("Review gold", detail.reviewGold.map(String.init) ?? "—")
            if let ride = detail.canDoubleRide { fact("Double ride", tr(ride ? "Yes" : "No")) }
        }
    }
    private var feature: some View {
        ReadingPanel(title: "Feature") {
            if let feature = skills?.feature {
                NavigationLink(destination: SkillDetailView(session: session, skillID: feature.id)) { SkillCard(skill: feature) }
                    .buttonStyle(.plain)
            } else { Text(tr("None")).foregroundColor(.secondary) }
        }
    }
    private func stats(_ detail: PetDetail) -> some View {
        ReadingPanel(title: "Base stats") {
            ForEach(detail.stats) { stat in
                HStack {
                    Text(tr(stat.id)).frame(minWidth: 100, alignment: .leading)
                    ProgressView(value: Double(stat.value ?? 0), total: Double(max(1, detail.stats.compactMap(\.value).max() ?? 1)))
                        .accessibilityHidden(true)
                    Text(stat.value.map(String.init) ?? "—").monospacedDigit().frame(minWidth: 35, alignment: .trailing)
                }.accessibilityElement(children: .combine)
            }
            fact("Total base stats", detail.totalBaseStats.map(String.init) ?? "—")
        }
    }
    private var skillPanel: some View {
        ReadingPanel(title: "Skills") {
            Menu {
                ForEach(SkillTerms.types, id: \.self) { type in
                    Button {
                        if skillTypes.contains(type) { skillTypes.removeAll { $0 == type } } else { skillTypes.append(type) }
                    } label: { Label(type, systemImage: skillTypes.contains(type) ? "checkmark" : "circle") }
                }
                Button(tr("Reset filters")) { skillTypes = []; skillElement = "" }
            } label: { Label(tr("Skill type"), systemImage: "line.3.horizontal.decrease") }
            if let skills {
                Picker(tr("Types"), selection: $skillElement) {
                    Text(tr("Any")).tag("")
                    ForEach(Array(Set(skills.learned.compactMap(\.skill.element))).sorted(), id: \.self) { Text($0).tag($0) }
                }
                learnedSection("Pet skills", skills.learned.filter { $0.sourceKind == "native" })
                learnedSection("Bloodline effects", skills.learned.filter { $0.sourceKind == "blood" })
                learnedSection("Learnable skills", skills.learned.filter { $0.sourceKind != "native" && $0.sourceKind != "blood" })
            }
        }
    }
    @ViewBuilder private func learnedSection(_ title: String, _ learned: [LearnableSkill]) -> some View {
        Text(tr(title)).font(.headline)
        let filtered = learned.filter {
            (skillTypes.isEmpty || skillTypes.contains($0.skill.damageClass ?? "") || skillTypes.contains($0.skill.category ?? "")) &&
                (skillElement.isEmpty || $0.skill.element == skillElement)
        }
        if filtered.isEmpty { Text(tr("None")).foregroundColor(.secondary) }
        ForEach(filtered) { source in
            VStack(alignment: .leading, spacing: 5) {
                NavigationLink(destination: SkillDetailView(session: session, skillID: source.skill.id)) { SkillCard(skill: source.skill) }
                    .buttonStyle(.plain)
                acquisition(source.sourceKind, level: source.learnLevel, stage: source.sourceStage,
                            blood: source.bloodRaw, requirement: source.requirement)
            }
        }
    }
    private var evolutionPanel: some View {
        ReadingPanel(title: "Evolution") {
            if let evolution, !evolution.edges.isEmpty {
                ForEach(evolution.edges) { edge in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            evolutionLink(edge.fromID, graph: evolution)
                            Image(systemName: "arrow.right").accessibilityLabel(tr("Evolves to"))
                            evolutionLink(edge.toID, graph: evolution)
                        }
                        if let level = edge.level { Text("\(tr("Level")) \(level)").font(.caption) }
                        if let condition = edge.condition { Text(condition).font(.subheadline) }
                        Text(edge.method).font(.caption).foregroundColor(.secondary)
                    }.padding(.vertical, 6)
                }
            } else { Text(tr("No evolution route is recorded.")).foregroundColor(.secondary) }
        }
    }
    private func evolutionLink(_ id: String, graph: EvolutionGraph) -> some View {
        NavigationLink(destination: PetDetailView(session: session, petID: id)) {
            Text(graph.nodes.first { $0.id == id }?.name ?? id).font(.headline)
        }
    }
    private var typePanel: some View {
        ReadingPanel(title: "Type relationships") {
            if let relationships {
                ForEach(relationships.outgoing) { relation in
                    Text(relation.name).font(.headline)
                    fact("Strong against", relation.strongAgainst.joined(separator: " · "))
                    fact("Resisted by", relation.resistedBy.joined(separator: " · "))
                }
                Text(tr("Incoming damage")).font(.headline)
                ForEach(relationships.incoming) { entry in
                    HStack { TypeIcons(types: [entry.type]); Text(entry.type); Spacer(); Text("\(entry.multiplier.formatted())×").monospacedDigit() }
                }
            }
        }
    }
}

@ViewBuilder func fact(_ label: String, _ value: String) -> some View {
    HStack(alignment: .top) {
        Text(tr(label)).foregroundColor(.secondary)
        Spacer(minLength: 12)
        Text(value).multilineTextAlignment(.trailing).textSelection(.enabled)
    }
}
@ViewBuilder func acquisition(_ kind: String, level: Int?, stage: Int?, blood: String?, requirement: String?) -> some View {
    VStack(alignment: .leading, spacing: 4) {
        Text(tr(["native": "Native", "blood": "Bloodline", "stone": "Skill stone", "legendary": "Legendary", "feature": "Feature"][kind] ?? "Unknown source"))
        if let level { Text("\(tr("Level")) \(level)") }
        if let stage { Text("\(tr("Source stage")) \(stage)") }
        if let blood { Text(blood) }
        if let requirement { Text(requirement) }
    }.font(.caption).foregroundColor(.secondary).textSelection(.enabled)
}

struct SkillDetailView: View {
    let session: HandbookSession
    let skillID: String
    @State private var detail: SkillDetail?
    @State private var featureUsers: [SkillUser] = []
    @State private var learnedUsers: [SkillUser] = []
    @State private var definitions: [GameDescription] = []
    @State private var error: String?
    var body: some View {
        Group {
            if let detail {
                ScrollView {
                    VStack(spacing: 16) {
                        ReadingPanel(title: detail.summary.name) {
                            SkillCard(skill: detail.summary)
                            if let target = detail.target { fact("Target", target) }
                        }
                        if !definitions.isEmpty {
                            ReadingPanel(title: "Game descriptions") {
                                ForEach(definitions) { entry in
                                    Text(entry.name).font(.headline)
                                    Text(entry.description).textSelection(.enabled)
                                }
                            }
                        }
                        users("Feature users", featureUsers)
                        users("Learning sources", learnedUsers)
                        PersonalPanel(session: session, object: object(detail.summary))
                        SourcePanel(references: detail.sources)
                    }.padding(16)
                }.toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) { FavoriteButton(session: session, object: object(detail.summary)) }
                }
            } else if let error {
                VStack { EmptyState(text: error); Button(tr("Retry")) { Task { await load() } } }
            } else { ProgressView() }
        }.background(HandbookTheme.background).navigationTitle(detail?.summary.name ?? tr("Skill"))
            .navigationBarTitleDisplayMode(.inline).task(id: skillID) { await load() }
    }
    private func object(_ skill: SkillSummary) -> ObjectRef { ObjectRef(type: .skill, objectID: skill.id, name: skill.name) }
    private func load() async {
        error = nil
        do {
            let record = try await session.catalog.skillDetail(skillID)
            let features = try await session.catalog.skillUsers(skillID, feature: true)
            let learned = try await session.catalog.skillUsers(skillID, feature: false)
            let glossary = try await session.assets.descriptions()
            guard !Task.isCancelled else { return }
            detail = record; featureUsers = features; learnedUsers = learned
            definitions = glossary.entries.filter { record.descriptionNoteIDs.contains($0.id) }
        } catch { if !Task.isCancelled { self.error = "This skill is unavailable in the current Catalog." } }
    }
    @ViewBuilder private func users(_ title: String, _ users: [SkillUser]) -> some View {
        if !users.isEmpty {
            ReadingPanel(title: title) {
                ForEach(users) { user in
                    NavigationLink(destination: PetDetailView(session: session, petID: user.pet.id)) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(user.pet.name).font(.headline)
                            acquisition(user.relationship, level: user.learnLevel, stage: user.sourceStage,
                                        blood: user.bloodRaw, requirement: user.requirement)
                        }
                    }
                }
            }
        }
    }
}
