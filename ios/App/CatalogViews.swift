import SwiftUI
import HandbookCore

struct PetCatalogView: View {
    let session: HandbookSession
    let title: String?
    @EnvironmentObject private var app: AppModel
    @Environment(\.dynamicTypeSize) private var textSize
    @StateObject private var model: PetListModel
    @State private var query: PetQuery
    @State private var types: [CatalogType] = []
    @State private var showFilters = false
    init(session: HandbookSession, title: String? = nil, initialQuery: PetQuery = PetQuery()) {
        self.session = session; self.title = title
        _model = StateObject(wrappedValue: PetListModel(session.catalog))
        _query = State(initialValue: initialQuery)
    }
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 16) {
                    if title == nil { hero(topInset: geometry.safeAreaInsets.top) }
                    else { controls.padding(.horizontal, 16) }
                    if let error = model.error {
                        EmptyState(text: error)
                        Button(tr("Retry")) { Task { await model.load(query) } }
                    }
                    if app.layout == .list {
                        LazyVStack(spacing: 12) { cards(compact: true) }.padding(.horizontal, 16)
                    } else {
                        let count = textSize.isAccessibilitySize ? 1 : (app.layout == .threeColumn || geometry.size.width >= 700 ? 3 : 2)
                        let spacing: CGFloat = count == 3 ? 8 : 12
                        let cardWidth = (geometry.size.width - 32 - spacing * CGFloat(count - 1)) / CGFloat(count)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: spacing, alignment: .top), count: count), spacing: spacing) {
                            cards(compact: false, dense: count == 3, illustrationSize: min(136, max(44, cardWidth - (count == 3 ? 16 : 28))))
                        }.padding(.horizontal, 16)
                    }
                    if model.loading { ProgressView().padding() }
                    else if model.rows.isEmpty, model.error == nil { EmptyState(text: "No creatures match these filters.") }
                    if model.hasMore {
                        Button(tr("Load more")) { Task { await model.load(query, append: true) } }
                            .buttonStyle(.bordered).disabled(model.loading).accessibilityIdentifier("pets.loadMore")
                    }
                }.padding(.bottom, 28)
            }.background(HandbookTheme.background)
                .ignoresSafeArea(.container, edges: title == nil ? .top : [])
        }
        .navigationTitle(title.map(tr) ?? "")
        .navigationBarHidden(title == nil)
        .task(id: query) { await model.load(query) }
        .task {
            do { types = try await session.catalog.types() }
            catch { app.report(error) }
        }
        .sheet(isPresented: $showFilters) {
            AppNavigation { PetFiltersView(query: $query, types: $types) }
        }
        .accessibilityIdentifier("pets.catalog")
    }
    @ViewBuilder private func cards(compact: Bool, dense: Bool = false, illustrationSize: CGFloat = 136) -> some View {
        ForEach(model.rows) { pet in
            NavigationLink(destination: PetDetailView(session: session, petID: pet.id)) {
                PetCard(pet: pet, compact: compact, dense: dense, illustrationSize: illustrationSize)
            }.buttonStyle(.plain).accessibilityIdentifier("pet.\(pet.id)")
        }
    }
    private func hero(topInset: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 7) {
                    Text(tr("Roco World Handbook")).font(HandbookTheme.display(30, relativeTo: .largeTitle))
                        .accessibilityAddTraits(.isHeader)
                    Text(tr("An offline guide to every adventure.")).font(.subheadline).foregroundColor(.secondary)
                }
                Spacer(minLength: 0)
                NavigationLink(destination: CatalogInfoView(session: session)) {
                    Image(systemName: "info.circle").font(.title2).padding(8)
                }.accessibilityLabel(tr("Catalog information"))
            }
            Text("\(tr("Data version")) \(session.info.dataVersion)").font(.caption.monospacedDigit()).foregroundColor(.secondary)
            controls
        }.padding(20).padding(.top, topInset + 12)
            .background(LinearGradient(colors: [Color.blue.opacity(0.16), HandbookTheme.surface], startPoint: .topLeading, endPoint: .bottomTrailing))
            .clipShape(EdgeRoundedRectangle(radius: 28, corners: [.bottomLeft, .bottomRight]))
    }
    private var controls: some View {
        HStack(spacing: 8) {
            Menu {
                Picker(tr("Sort"), selection: $query.sort) {
                    ForEach(PetSort.allCases, id: \.self) { Text(sortLabel($0)).tag($0) }
                }
            } label: {
                Image(systemName: "arrow.up.arrow.down").frame(width: 44, height: 44)
                    .background(Color.accentColor.opacity(0.12)).clipShape(RoundedRectangle(cornerRadius: 13))
            }.accessibilityLabel(tr("Sort")).accessibilityIdentifier("pets.sort")
            Button { showFilters = true } label: {
                Image(systemName: filtersActive ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease").frame(width: 44, height: 44)
                    .background(Color.accentColor.opacity(0.12)).clipShape(RoundedRectangle(cornerRadius: 13))
            }.accessibilityLabel(tr("Filters")).accessibilityIdentifier("pets.filters")
                .accessibilityAddTraits(filtersActive ? .isSelected : [])
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                TextField(tr("Name or number"), text: $query.keyword)
                    .textInputAutocapitalization(.never).disableAutocorrection(true)
                    .accessibilityLabel(tr("Search creatures or handbook number"))
                    .accessibilityIdentifier("pets.search")
                if !query.keyword.isEmpty {
                    Button { query.keyword = "" } label: { Image(systemName: "xmark.circle.fill") }
                        .accessibilityLabel(tr("Clear search"))
                }
            }.padding(.horizontal, 10).frame(minHeight: 44)
                .background(HandbookTheme.surface).clipShape(RoundedRectangle(cornerRadius: 13))
        }.buttonStyle(.plain)
    }
    private var filtersActive: Bool {
        !query.typeIDs.isEmpty || !query.stages.isEmpty || !query.forms.isEmpty || !query.seasons.isEmpty || query.shiny != .any
    }
}

func sortLabel(_ sort: PetSort) -> String {
    switch sort {
    case .handbook: return tr("Handbook number")
    case .name: return tr("Name")
    case .attack: return tr("Attack")
    case .magicAttack: return tr("Magic attack")
    case .speed: return tr("Speed")
    }
}

struct PetFiltersView: View {
    @Binding var query: PetQuery
    @Binding var types: [CatalogType]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var textSize
    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                MultiSelectSection(title: "Types", values: types.map(\.id), selection: $query.typeIDs,
                                   icon: { id in CatalogAssets.type(types.first { $0.id == id }?.name ?? id) }, minimumWidth: 60, loading: types.isEmpty) { id in
                    types.first { $0.id == id }?.name ?? id
                }
                MultiSelectSection(title: "Stage", values: [1, 2, 3], selection: $query.stages) { "\(tr("Stage")) \($0)" }
                MultiSelectSection(title: "Form", values: PetFormFilter.allCases, selection: $query.forms,
                                   symbol: { $0 == .main ? "pawprint.fill" : $0 == .regional ? "mappin.and.ellipse" : "crown.fill" }) {
                    tr($0 == .main ? "Main form" : $0 == .regional ? "Regional form" : "Lord form")
                }
                ReadingPanel(title: "Shiny") {
                    LazyVGrid(columns: textSize.isAccessibilitySize ? [GridItem(.flexible())] : [GridItem(.adaptive(minimum: 80), spacing: 8)], spacing: 8) {
                        ForEach(ShinyFilter.allCases, id: \.self) { value in
                            FilterChoice(title: tr(value == .any ? "Any" : value == .hasShiny ? "Has shiny" : "No shiny"),
                                         symbol: value == .hasShiny ? "sparkles" : nil, selected: query.shiny == value) { query.shiny = value }
                        }
                    }
                }
                MultiSelectSection(title: "Season", values: ["S1", "S2", "S3", "S4"], selection: $query.seasons, minimumWidth: 65) { $0 }
            }.padding(16)
        }.background(HandbookTheme.background).navigationTitle(tr("Filters")).navigationBarTitleDisplayMode(.inline)
            .tint(HandbookTheme.detailAccent)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        query.shiny = .any; query.stages = []; query.forms = []; query.seasons = []; query.typeIDs = []
                    } label: { Image(systemName: "arrow.counterclockwise") }
                        .accessibilityLabel(tr("Reset filters")).accessibilityIdentifier("filters.reset")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button { dismiss() } label: { Image(systemName: "checkmark") }.accessibilityLabel(tr("Done"))
                }
            }
    }
}

struct SkillCatalogView: View {
    let session: HandbookSession
    let title: String
    @EnvironmentObject private var app: AppModel
    @StateObject private var model: SkillListModel
    @State private var query: SkillQuery
    @State private var types: [CatalogType] = []
    @State private var showFilters = false
    init(session: HandbookSession, features: Bool = false) {
        self.session = session; title = features ? "Feature handbook" : "Skill handbook"
        var query = SkillQuery(); query.filter = features ? .features : .learnable
        _query = State(initialValue: query)
        _model = StateObject(wrappedValue: SkillListModel(session.catalog))
    }
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if let error = model.error {
                    EmptyState(text: error)
                    Button(tr("Retry")) { Task { await model.load(query) } }
                }
                SkillGrid(layout: app.skillLayout) { compact, dense in
                    ForEach(model.rows) { skill in
                        NavigationLink(destination: SkillDetailView(session: session, skillID: skill.id)) {
                            if compact { CompactSkillCard(skill: skill, dense: dense) }
                            else { SkillCard(skill: skill) }
                        }.buttonStyle(.plain).accessibilityIdentifier("skill.\(skill.id)")
                    }
                }
                if model.loading { ProgressView().padding() }
                else if model.rows.isEmpty, model.error == nil { EmptyState(text: "No skills match these filters.") }
                if model.hasMore {
                    Button(tr("Load more")) { Task { await model.load(query, append: true) } }
                        .buttonStyle(.bordered).disabled(model.loading)
                }
            }.padding(16).padding(.bottom, 20)
        }.background(HandbookTheme.background)
            .navigationTitle(tr(title)).navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query.keyword, prompt: tr("Skill query"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    SkillLayoutMenu()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showFilters = true } label: {
                        Image(systemName: query.typeIDs.isEmpty && query.skillTypes.isEmpty && query.tags.isEmpty
                              ? "line.3.horizontal.decrease" : "line.3.horizontal.decrease.circle.fill")
                    }
                        .accessibilityLabel(tr("Skill filters")).accessibilityIdentifier("skills.filters")
                }
            }
            .task(id: query) { await model.load(query) }
            .task {
                do { types = try await session.catalog.types() } catch { app.report(error) }
            }
            .sheet(isPresented: $showFilters) { AppNavigation { SkillFiltersView(query: $query, types: $types) } }
            .accessibilityIdentifier("skills.catalog")
    }
}

enum SkillTerms {
    static let types = ["\u{7269}\u{653b}", "\u{9b54}\u{653b}", "\u{9632}\u{5fa1}", "\u{72b6}\u{6001}"]
    static let tags = ["\u{5f02}\u{5e38}", "\u{56de}\u{8840}", "\u{56de}\u{80fd}", "\u{5e94}\u{5bf9}", "\u{5370}\u{8bb0}",
                       "\u{9a71}\u{6563}", "\u{5148}\u{624b}", "\u{79bb}\u{573a}", "\u{5929}\u{6c14}", "\u{9009}\u{62e9}",
                       "\u{5de7}\u{53d8}", "\u{5f3a}\u{5316}", "\u{8fde}\u{51fb}", "\u{840c}\u{5316}", "\u{5f15}\u{7535}",
                       "\u{8fc5}\u{6377}", "\u{4f20}\u{52a8}", "\u{8ff8}\u{53d1}", "\u{5949}\u{732e}", "\u{6253}\u{65ad}"]
    static func icon(_ type: String) -> String? {
        guard let index = types.firstIndex(of: type) else { return nil }
        return "wiki/v4/ui/skill-categories/\(["physical-attack", "magic-attack", "defense", "status"][index]).png"
    }
}
struct SkillFiltersView: View {
    @Binding var query: SkillQuery
    @Binding var types: [CatalogType]
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                MultiSelectSection(title: "Skill type", values: SkillTerms.types, selection: $query.skillTypes,
                                   icon: SkillTerms.icon, minimumWidth: 64) { $0 }
                MultiSelectSection(title: "Types", values: types.map(\.id), selection: $query.typeIDs,
                                   icon: { id in CatalogAssets.type(types.first { $0.id == id }?.name ?? id) }, minimumWidth: 60, loading: types.isEmpty) { id in
                    types.first { $0.id == id }?.name ?? id
                }
                MultiSelectSection(title: "Skill tags", values: SkillTerms.tags, selection: $query.tags) { $0 }
            }.padding(16)
        }.background(HandbookTheme.background).navigationTitle(tr("Skill filters")).navigationBarTitleDisplayMode(.inline)
            .tint(HandbookTheme.detailAccent)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { query.skillTypes = []; query.tags = []; query.typeIDs = [] } label: { Image(systemName: "arrow.counterclockwise") }
                        .accessibilityLabel(tr("Reset filters")).accessibilityIdentifier("filters.reset")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button { dismiss() } label: { Image(systemName: "checkmark") }.accessibilityLabel(tr("Done"))
                }
            }
    }
}
