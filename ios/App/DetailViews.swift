import SwiftUI
import HandbookCore

private enum PetDetailTab: String, CaseIterable {
    case overview = "Overview", skills = "Skills", types = "Type relationships", eggs = "Egg groups tab"
    var symbol: String {
        switch self {
        case .overview: return "chart.bar.fill"
        case .skills: return "sparkles"
        case .types: return "arrow.left.arrow.right"
        case .eggs: return "oval.portrait.fill"
        }
    }
}
private enum PetSkillTab: String, CaseIterable {
    case native = "Pet skills", blood = "Bloodline effects", other = "Learnable skills"
}
private enum PetDetailSheet: String, Identifiable {
    case personal = "My library", evolution = "Evolution", source = "Source", filters = "Skill filters"
    var id: String { rawValue }
}
private struct DetailScrollOffset: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

struct PetDetailView: View {
    let session: HandbookSession
    let petID: String
    @EnvironmentObject private var app: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var textSize
    @ScaledMetric(relativeTo: .title) private var identityHeight: CGFloat = 80
    @State private var detail: PetDetail?
    @State private var skills: PetSkillBundle?
    @State private var evolution: EvolutionGraph?
    @State private var relationships: TypeRelationships?
    @State private var error: String?
    @State private var shiny = false
    @State private var tab: PetDetailTab = .overview
    @State private var skillTab: PetSkillTab = .native
    @State private var skillQuery = ""
    @State private var skillTypes: [String] = []
    @State private var skillElements: [String] = []
    @State private var defending = false
    @State private var sheet: PetDetailSheet?
    @State private var scrollOffset: CGFloat = 0

    var body: some View {
        Group {
            if let detail {
                detailContent(detail)
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        FavoriteButton(session: session, object: object(detail.summary))
                        Menu {
                            Button(tr("My library")) { sheet = .personal }
                                .accessibilityIdentifier("detail.section.My library")
                            Button(tr("Evolution")) { sheet = .evolution }
                                .accessibilityIdentifier("detail.section.Evolution")
                            Button(tr("Source")) { sheet = .source }
                                .accessibilityIdentifier("detail.section.Source")
                        } label: { Image(systemName: "ellipsis.circle") }
                            .accessibilityLabel(tr("More creature information")).accessibilityIdentifier("detail.more")
                    }
                }
                .sheet(item: $sheet) { destination in
                    AppNavigation {
                        ScrollView {
                            VStack(spacing: 16) {
                                switch destination {
                                case .personal:
                                    PersonalPanel(session: session, object: object(detail.summary), handbookID: detail.summary.handbookID)
                                case .evolution: evolutionPanel
                                case .source: SourcePanel(references: detail.sources)
                                case .filters: skillFilters
                                }
                            }.padding(16)
                        }.background(HandbookTheme.background)
                            .navigationTitle(tr(destination.rawValue)).navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .cancellationAction) {
                                    if destination == .filters {
                                        Button { skillTypes = []; skillElements = [] } label: { Image(systemName: "arrow.counterclockwise") }
                                            .accessibilityLabel(tr("Reset filters")).accessibilityIdentifier("filters.reset")
                                    }
                                }
                                ToolbarItem(placement: .confirmationAction) {
                                    Button { sheet = nil } label: { Image(systemName: "checkmark") }.accessibilityLabel(tr("Done"))
                                }
                            }
                    }
                }
            } else if let error {
                VStack { EmptyState(text: error); Button(tr("Retry")) { Task { await load() } } }
            } else { ProgressView() }
        }.background(HandbookTheme.background).tint(HandbookTheme.detailAccent)
            .navigationTitle(tr("Creature details"))
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
    private func detailContent(_ detail: PetDetail) -> some View {
        GeometryReader { geometry in
            let largeArt = min(250, max(180, geometry.size.width - 120))
            let variantHeight: CGFloat = detail.summary.hasShiny ? 44 : 0
            let expandedHeight = largeArt + identityHeight + 34 + variantHeight
            let compactHeight = max(136, identityHeight + 44) + variantHeight
            let distance = max(1, expandedHeight - compactHeight)
            let fraction = min(1, max(0, scrollOffset / distance))
            let progress = reduceMotion ? (fraction > 0.5 ? 1.0 : 0.0) : fraction
            let tabsHeight: CGFloat = textSize.isAccessibilitySize ? 96 : 76
            ScrollViewReader { reader in
                ScrollView {
                    VStack(spacing: 0) {
                        Color.clear.frame(height: distance).accessibilityHidden(true)
                        Color.clear.frame(height: compactHeight + tabsHeight - 18)
                            .id("detail-browsing-top").accessibilityHidden(true)
                        tabContent(detail).padding(16).padding(.bottom, 28)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }.frame(minHeight: geometry.size.height + distance, alignment: .top)
                        .background {
                            GeometryReader { marker in
                                Color.clear.preference(key: DetailScrollOffset.self,
                                                       value: -marker.frame(in: .named("pet-detail-scroll")).minY)
                            }
                        }
                        .overlay(alignment: .top) {
                            VStack(spacing: -18) {
                                hero(detail, width: geometry.size.width, largeArt: largeArt, progress: progress,
                                     height: expandedHeight - distance * progress, variantHeight: variantHeight)
                                tabBar.padding(.horizontal, 16).frame(height: tabsHeight).background(HandbookTheme.surface)
                                    .clipShape(EdgeRoundedRectangle(radius: 24, corners: [.topLeft, .topRight]))
                            }.offset(y: scrollOffset).accessibilitySortPriority(1)
                        }
                }.coordinateSpace(name: "pet-detail-scroll").background(HandbookTheme.surface)
                    .onPreferenceChange(DetailScrollOffset.self) { scrollOffset = max(0, $0) }
                    .onChange(of: tab) { _ in
                        if scrollOffset > distance { reader.scrollTo("detail-browsing-top", anchor: .top) }
                    }
            }
        }
    }
    private func hero(_ detail: PetDetail, width: CGFloat, largeArt: CGFloat, progress: CGFloat,
                      height: CGFloat, variantHeight: CGFloat) -> some View {
        let artSize = largeArt - (largeArt - 100) * progress
        let compactCenter = (height - variantHeight - 18) / 2
        return ZStack(alignment: .topLeading) {
            AssetImage(path: CatalogAssets.pet(detail.summary.illustrationKey, shiny: shiny), label: detail.summary.name, size: artSize)
                .accessibilityIdentifier("detail.illustration")
                .accessibilityValue(tr(progress < 0.98 ? "Expanded illustration" : "Compact illustration"))
                .position(x: width / 2 + (70 - width / 2) * progress,
                          y: largeArt / 2 + 10 + (compactCenter - largeArt / 2 - 10) * progress)
            VStack(alignment: .leading, spacing: 8) {
                Text("NO.\(detail.summary.dexNo)").font(.caption2.bold().monospacedDigit())
                    .frame(height: 12 * progress).opacity(progress).accessibilityHidden(progress < 0.5)
                Text(detail.summary.name).font(HandbookTheme.display(30 - 6 * progress, relativeTo: .title))
                    .fixedSize(horizontal: false, vertical: true).accessibilityAddTraits(.isHeader)
                if let form = detail.summary.form, !detail.summary.isDefaultForm { Text(form).font(.caption) }
                HStack(spacing: 10) {
                    ForEach(detail.summary.types, id: \.self) { type in
                        HStack(spacing: 4) {
                            AssetImage(path: CatalogAssets.type(type), label: type, size: 23).accessibilityHidden(true)
                            Text(type).font(.caption.bold())
                        }.accessibilityElement(children: .combine)
                    }
                }
            }.frame(width: width - 168, alignment: .leading)
                .position(x: width / 2 + 64 * progress,
                          y: largeArt + identityHeight / 2 + 8 + (compactCenter - largeArt - identityHeight / 2 - 8) * progress)
            Text("NO.\(detail.summary.dexNo)").font(.caption.bold().monospacedDigit())
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(Color.black.opacity(0.25)).clipShape(Capsule())
                .frame(maxWidth: .infinity, alignment: .trailing).padding(.horizontal, 20).padding(.top, 10)
                .opacity(1 - progress).accessibilityHidden(progress > 0.5)
            if detail.summary.hasShiny {
                Picker(tr("Illustration"), selection: $shiny) {
                    Label(tr("Original"), systemImage: "pawprint.fill").tag(false)
                    Label(tr("Shiny"), systemImage: "sparkles").tag(true)
                }.pickerStyle(.segmented).accessibilityIdentifier("detail.shiny")
                    .padding(.horizontal, 20).frame(maxHeight: .infinity, alignment: .bottom).padding(.bottom, 24)
            }
        }.frame(height: height).foregroundColor(.white)
            .background {
                LinearGradient(colors: [Color(red: 0.70, green: 0.29, blue: 0.18), Color(red: 0.72, green: 0.32, blue: 0.20)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                    .overlay(alignment: .topTrailing) {
                        Circle().fill(Color.white.opacity(0.04)).frame(width: 210, height: 210).offset(x: 70, y: -70)
                    }.clipped()
            }
    }
    private var tabBar: some View {
        HStack(spacing: 3) {
            ForEach(PetDetailTab.allCases, id: \.self) { item in
                Button { tab = item } label: {
                    VStack(spacing: 4) {
                        Image(systemName: item.symbol).font(.system(size: 17, weight: .semibold)).accessibilityHidden(true)
                        Text(tr(item.rawValue)).font(.caption.weight(.semibold)).multilineTextAlignment(.center)
                    }
                        .frame(maxWidth: .infinity, minHeight: 44).padding(.horizontal, 2)
                        .foregroundColor(tab == item ? HandbookTheme.detailAccent : .secondary)
                        .background(tab == item ? HandbookTheme.surface : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }.buttonStyle(.plain).accessibilityLabel(tr(item.rawValue)).accessibilityAddTraits(tab == item ? .isSelected : [])
                    .accessibilityIdentifier("detail.tab.\(item.rawValue)")
            }
        }.padding(4).background(HandbookTheme.detailWash).clipShape(RoundedRectangle(cornerRadius: 16))
    }
    @ViewBuilder private func tabContent(_ detail: PetDetail) -> some View {
        switch tab {
        case .overview:
            VStack(alignment: .leading, spacing: 26) {
                stats(detail)
                feature
                if let size = detail.eggSize { eggMeasurements(size) }
                basic(detail)
            }
        case .skills: skillPanel
        case .types: typePanel
        case .eggs: eggGroups(detail)
        }
    }
    private func detailSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Circle().fill(HandbookTheme.detailAccent).frame(width: 6, height: 6).accessibilityHidden(true)
                Text(tr(title)).font(HandbookTheme.display()).accessibilityAddTraits(.isHeader)
            }
            content()
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
    private func stats(_ detail: PetDetail) -> some View {
        let colors: [Color] = [.red, .orange, .blue, .yellow, .green, .pink]
        let order = ["HP", "Attack", "Magic attack", "Defense", "Magic defense", "Speed"]
        let icons = ["health", "physical-attack", "magic-attack", "physical-defense", "magic-defense", "speed"]
        return VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Circle().fill(HandbookTheme.detailAccent).frame(width: 6, height: 6).accessibilityHidden(true)
                Text(tr("Base stats")).font(HandbookTheme.display()).accessibilityAddTraits(.isHeader)
                Spacer(minLength: 4)
                VStack(spacing: 2) {
                    Text(detail.totalBaseStats.map(String.init) ?? "—").font(.headline.monospacedDigit())
                        .foregroundColor(HandbookTheme.detailAccent)
                    Text(tr("Total base stats")).font(.caption2).foregroundColor(.secondary)
                }.padding(.horizontal, 10).padding(.vertical, 6)
                    .background(HandbookTheme.detailWash).clipShape(RoundedRectangle(cornerRadius: 12))
            }
            VStack(spacing: 8) {
                ForEach(Array(order.enumerated()), id: \.element) { index, key in
                    let value = detail.stats.first { $0.id == key }?.value
                    HStack(spacing: 10) {
                        HStack(spacing: 5) {
                            AssetImage(path: "wiki/v3/ui/stats/\(icons[index]).png", label: tr(key), size: 19).accessibilityHidden(true)
                            Text(tr(key)).font(.caption).foregroundColor(.secondary)
                        }.frame(width: 90, alignment: .leading)
                        GeometryReader { geometry in
                            Capsule().fill(HandbookTheme.detailWash)
                            Capsule().fill(LinearGradient(colors: [colors[index].opacity(0.65), colors[index]], startPoint: .leading, endPoint: .trailing))
                                .frame(width: geometry.size.width * CGFloat(max(0, value ?? 0)) /
                                       CGFloat(max(200, detail.stats.compactMap(\.value).max() ?? 200)))
                        }.frame(height: 8).accessibilityHidden(true)
                        Text(value.map(String.init) ?? "—").font(.subheadline.bold().monospacedDigit())
                            .foregroundColor(HandbookTheme.detailAccent).frame(minWidth: 34, alignment: .trailing)
                    }.frame(minHeight: 26).accessibilityElement(children: .combine)
                }
            }
        }
    }
    private var feature: some View {
        detailSection("Feature") {
            if let feature = skills?.feature {
                NavigationLink(destination: SkillDetailView(session: session, skillID: feature.id)) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            AssetImage(path: CatalogAssets.skill(feature), label: feature.name, size: 40)
                            Text(feature.name).font(HandbookTheme.display()).foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption).foregroundColor(.secondary)
                        }
                        if let description = feature.description {
                            Text(description).font(.subheadline).foregroundColor(.secondary).lineSpacing(5)
                                .padding(12).frame(maxWidth: .infinity, alignment: .leading)
                                .background(HandbookTheme.detailWash).clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }.padding(14).background(HandbookTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(HandbookTheme.detailAccent.opacity(0.12)))
                }.buttonStyle(.plain)
            } else { Text(tr("None")).foregroundColor(.secondary) }
        }
    }
    private func eggMeasurements(_ size: EggSize) -> some View {
        detailSection("Egg information") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                measurement("Egg weight", "\(eggWeight(size.minimum, unit: size.unit)) – \(eggWeight(size.maximum, unit: size.unit))")
                measurement("Mini maximum", eggWeight(size.miniMaximum, unit: size.unit))
                measurement("Huge minimum", eggWeight(size.hugeMinimum, unit: size.unit))
            }
        }
    }
    private func eggWeight(_ value: Double?, unit: String?) -> String {
        guard let value else { return "—" }
        return value.formatted(.number.precision(.fractionLength(0...3)).grouping(.never)) + (unit.map { " \($0)" } ?? "")
    }
    private func measurement(_ title: String, _ value: String) -> some View {
        VStack(spacing: 8) {
            Text(tr(title)).font(.caption).foregroundColor(.secondary)
            Text(value).font(.subheadline.bold().monospacedDigit()).multilineTextAlignment(.center)
        }.padding(14).frame(maxWidth: .infinity, minHeight: 84)
            .background(HandbookTheme.detailWash).clipShape(RoundedRectangle(cornerRadius: 14))
            .accessibilityElement(children: .combine)
    }
    private func basic(_ detail: PetDetail) -> some View {
        detailSection("Basic information") {
            if let description = detail.description { Text(description).font(.subheadline).lineSpacing(5).textSelection(.enabled) }
            HStack(alignment: .top, spacing: 10) {
                measurement("Weight", detail.weight ?? "—")
                measurement("Height", detail.height ?? "—")
            }
            if let className = detail.className { fact("Class", className) }
            if detail.summary.isLordEvolution { fact("Form", tr("Lord form")) }
            else if let stage = detail.summary.stage {
                fact("Form", tr(stage == 1 ? "First form" : stage == 2 ? "Second form" : stage == 3 ? "Third form" : "Unknown"))
            }
            if let form = detail.summary.form, !detail.summary.isDefaultForm { fact("Regional form", form) }
            if let season = detail.summary.season { fact("Season", season) }
            fact("Starlight", detail.starlight.map(String.init) ?? "—")
            fact("Review gold", detail.reviewGold.map(String.init) ?? "—")
            if let ride = detail.canDoubleRide { fact("Double ride", tr(ride ? "Yes" : "No")) }
        }
    }
    private var skillPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(PetSkillTab.allCases, id: \.self) { item in
                        Button { skillTab = item } label: {
                            HStack(spacing: 6) {
                                if item == .native { Image(systemName: "pawprint.fill").accessibilityHidden(true) }
                                else {
                                    AssetImage(path: "wiki/v3/ui/sources/\(item == .blood ? "bloodline" : "skill-stone").png",
                                               label: tr(item.rawValue), size: 23).accessibilityHidden(true)
                                }
                                Text(tr(item.rawValue)).font(.subheadline.weight(.semibold))
                            }.padding(.horizontal, 12).frame(minHeight: 44)
                                .background(skillTab == item ? HandbookTheme.detailAccent : HandbookTheme.detailWash)
                                .foregroundColor(skillTab == item ? .white : .secondary)
                                .clipShape(RoundedRectangle(cornerRadius: 13))
                        }.buttonStyle(.plain).accessibilityAddTraits(skillTab == item ? .isSelected : [])
                            .accessibilityIdentifier("detail.skills.\(item.rawValue)")
                    }
                }
            }
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                TextField(tr("Search skills by name, type, or description"), text: $skillQuery)
                    .textInputAutocapitalization(.never).disableAutocorrection(true).accessibilityIdentifier("detail.skills.search")
                if !skillQuery.isEmpty {
                    Button { skillQuery = "" } label: { Image(systemName: "xmark.circle.fill") }
                        .accessibilityLabel(tr("Clear search"))
                }
                Button { sheet = .filters } label: {
                    Image(systemName: skillTypes.isEmpty && skillElements.isEmpty ? "line.3.horizontal.decrease" : "line.3.horizontal.decrease.circle.fill")
                        .frame(minWidth: 44, minHeight: 44)
                }.accessibilityLabel(tr("Skill filters")).accessibilityIdentifier("detail.skills.filters")
            }.padding(.horizontal, 12).background(HandbookTheme.detailWash).clipShape(RoundedRectangle(cornerRadius: 14))
            if filteredSkills.isEmpty { EmptyState(text: "No skills match these filters.") }
            ForEach(filteredSkills) { source in
                VStack(alignment: .leading, spacing: 6) {
                    NavigationLink(destination: SkillDetailView(session: session, skillID: source.skill.id)) {
                        SkillCard(skill: source.skill, prominent: true)
                    }.buttonStyle(.plain).accessibilityIdentifier("detail.skill.\(source.id)")
                    acquisition(source.sourceKind, level: source.learnLevel, stage: source.sourceStage,
                                blood: source.bloodRaw, requirement: source.requirement).padding(.horizontal, 12)
                }.padding(.bottom, 12).background(HandbookTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(HandbookTheme.detailAccent.opacity(0.10)))
                    .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
            }
        }
    }
    private var filteredSkills: [LearnableSkill] {
        let keyword = skillQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        return (skills?.learned ?? []).filter { source in
            let matchesSource = skillTab == .native ? source.sourceKind == "native" :
                skillTab == .blood ? source.sourceKind == "blood" : !["native", "blood"].contains(source.sourceKind)
            let skill = source.skill
            return matchesSource && (skillTypes.isEmpty || skillTypes.contains(skill.damageClass ?? "") || skillTypes.contains(skill.category ?? "")) &&
                (skillElements.isEmpty || skillElements.contains(skill.element ?? "")) &&
                (keyword.isEmpty || [skill.name, skill.element, skill.description, skill.damageClass, skill.category]
                    .compactMap { $0 }.contains { $0.localizedCaseInsensitiveContains(keyword) })
        }
    }
    private var skillFilters: some View {
        VStack(spacing: 14) {
            MultiSelectSection(title: "Skill type", values: SkillTerms.types, selection: $skillTypes,
                               icon: SkillTerms.icon, minimumWidth: 64) { $0 }
            MultiSelectSection(title: "Types", values: Array(Set(skills?.learned.compactMap(\.skill.element) ?? [])).sorted(),
                               selection: $skillElements, icon: CatalogAssets.type, minimumWidth: 60) { $0 }
        }
    }
    private var typePanel: some View {
        VStack(alignment: .leading, spacing: 22) {
            Picker(tr("Relationship direction"), selection: $defending) {
                Label(tr("Attacking"), systemImage: "arrow.up.right").tag(false)
                Label(tr("Defending"), systemImage: "shield.lefthalf.filled").tag(true)
            }.pickerStyle(.segmented).accessibilityIdentifier("detail.types.direction")
            if let relationships {
                if defending {
                    ForEach(Array(Set(relationships.incoming.map(\.multiplier))).sorted(by: >), id: \.self) { multiplier in
                        damageCard(multiplier, types: relationships.incoming.filter { $0.multiplier == multiplier }.map(\.type))
                    }
                    if relationships.incoming.isEmpty { Text(tr("None")).foregroundColor(.secondary) }
                } else {
                    ForEach(relationships.outgoing) { relation in
                        if relationships.outgoing.count > 1 { Text(relation.name).font(.headline) }
                        damageCard(2, types: relation.strongAgainst)
                        damageCard(0.5, types: relation.resistedBy)
                    }
                }
            }
            Text(tr("Damage multipliers follow the recorded type chart. Dual-type incoming damage is capped at 3×."))
                .font(.caption).foregroundColor(.secondary).padding(14).frame(maxWidth: .infinity, alignment: .leading)
                .background(HandbookTheme.detailWash).clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
    private func damageCard(_ multiplier: Double, types: [String]) -> some View {
        let favorable = defending ? multiplier < 1 : multiplier > 1
        let color: Color = favorable ? .green : .red
        return VStack(spacing: 0) {
            HStack(spacing: 8) {
                Text("\(multiplier.formatted())×").font(.title3.bold().monospacedDigit()).foregroundColor(color)
                Text(tr("Damage")).font(.headline)
            }.frame(maxWidth: .infinity).padding(12).background(color.opacity(0.08))
            if types.isEmpty { Text(tr("None")).foregroundColor(.secondary).padding(14) }
            else { typeBadges(types).padding(14) }
        }.background(HandbookTheme.surface).clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(HandbookTheme.detailWash, lineWidth: 1))
            .shadow(color: .black.opacity(0.04), radius: 10, y: 5)
    }
    private func typeBadges(_ types: [String]) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), alignment: .leading)], alignment: .leading, spacing: 8) {
            ForEach(types, id: \.self) { type in
                HStack(spacing: 6) {
                    AssetImage(path: CatalogAssets.type(type), label: type, size: 23).accessibilityHidden(true)
                    Text(type).font(.subheadline.bold())
                }.padding(.horizontal, 10).padding(.vertical, 7).foregroundColor(.white)
                    .background(Color.black.opacity(0.86)).clipShape(Capsule())
            }
        }
    }
    private func eggGroups(_ detail: PetDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if detail.eggGroups.isEmpty {
                Text(tr("No egg-group data is recorded.")).foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 100).background(HandbookTheme.detailWash)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            ForEach(detail.eggGroups, id: \.self) { id in
                NavigationLink(destination: PetCatalogView(session: session, title: "Egg groups", initialQuery: eggQuery(id))) {
                    HStack(spacing: 12) {
                        Image(systemName: "oval.portrait.fill").font(.title2).foregroundColor(HandbookTheme.detailAccent)
                        VStack(alignment: .leading, spacing: 5) {
                            Text(eggGroupName(id)).font(.headline).foregroundColor(.primary)
                            Text("\(tr("Egg group")) \(id)").font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption)
                    }.padding(18).background(HandbookTheme.detailWash).clipShape(RoundedRectangle(cornerRadius: 16))
                }.buttonStyle(.plain).accessibilityIdentifier("detail.eggGroup.\(id)")
            }
        }
    }
    private func eggQuery(_ id: Int) -> PetQuery { var query = PetQuery(); query.eggGroupIDs = [id]; return query }
    private func eggGroupName(_ id: Int) -> String {
        let keys = [1: "Undiscovered", 2: "Giant Spirit Group", 3: "Amphibious Group", 4: "Insect Group", 5: "Sky Group",
                    6: "Animal Group", 7: "Fairy Group", 8: "Plant Group", 9: "Humanoid Group", 10: "Soft-bodied Group",
                    11: "Earth Group", 12: "Magic Group", 13: "Ocean Group", 14: "Flying Dragon Group", 15: "Mechanical Group"]
        return tr(keys[id] ?? "Unknown")
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
