import SwiftUI
import CoreText
import HandbookCore

func tr(_ key: String) -> String { HandbookLocalization.shared.string(forKey: key) }

enum HandbookTheme {
    static let background = Color(uiColor: .systemGroupedBackground)
    static let surface = Color(uiColor: .secondarySystemGroupedBackground)
    static let detailAccent = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(red: 1, green: 0.60, blue: 0.44, alpha: 1)
        : UIColor(red: 0.72, green: 0.29, blue: 0.17, alpha: 1) })
    static let detailWash = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark
        ? .tertiarySystemGroupedBackground : UIColor(red: 0.99, green: 0.96, blue: 0.94, alpha: 1) })
    static func display(_ size: CGFloat = 20, relativeTo style: Font.TextStyle = .headline) -> Font {
        guard let path = Bundle.main.resourceURL?.appendingPathComponent("assets/fonts/v1/roco-display.ttf"),
              let descriptors = CTFontManagerCreateFontDescriptorsFromURL(path as CFURL) as? [CTFontDescriptor],
              let descriptor = descriptors.first,
              let name = CTFontDescriptorCopyAttribute(descriptor, kCTFontNameAttribute) as? String else {
            return .system(style, design: .rounded)
        }
        return .custom(name, size: size, relativeTo: style)
    }
    static func typeColor(_ name: String) -> Color {
        let names = ["\u{666e}\u{901a}", "\u{8349}", "\u{706b}", "\u{6c34}", "\u{5149}", "\u{5730}", "\u{51b0}", "\u{9f99}", "\u{7535}",
                     "\u{6bd2}", "\u{866b}", "\u{6b66}", "\u{7ffc}", "\u{840c}", "\u{5e7d}", "\u{6076}", "\u{673a}\u{68b0}", "\u{5e7b}"]
        let colors: [Color] = [.gray, .green, .red, .blue, .yellow, .brown, .cyan, .indigo, .orange,
                               .purple, .mint, .orange, .teal, .pink, .purple, .indigo, .gray, .pink]
        let short = name.hasSuffix("\u{7cfb}") ? String(name.dropLast()) : name
        return names.firstIndex(of: short).map { colors[$0] } ?? .blue
    }
}

enum HandbookWikiTheme {
    private static func adaptive(_ light: UInt32, _ dark: UInt32) -> Color {
        Color(uiColor: UIColor { traits in
            let value = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat((value >> 16) & 255) / 255,
                           green: CGFloat((value >> 8) & 255) / 255,
                           blue: CGFloat(value & 255) / 255, alpha: 1)
        })
    }
    static let background = adaptive(0xE9EDF6, 0x171F2E)
    static let paper = adaptive(0xF6F5EC, 0x191F29)
    static let surface = adaptive(0xFAFBFE, 0x242E40)
    static let paperSurface = adaptive(0xFFFEF7, 0x252B35)
    static let ink = adaptive(0x2C3956, 0xEDF2FC)
    static let secondary = adaptive(0x5C6880, 0xBAC6DA)
    static let accent = adaptive(0x34476D, 0xAFC9F0)
    static let gold = adaptive(0x8B682C, 0xE6C572)
    static let line = adaptive(0xD5DAE5, 0x455268)
    static let navy = adaptive(0x34476D, 0x2D4165)
    static let lavender = adaptive(0xE4E0F1, 0x3D3553)
    static let blue = adaptive(0xDCEAF3, 0x2D4558)
    static let lavenderInk = adaptive(0x554872, 0xEEE5FF)
    static let blueInk = adaptive(0x3C617C, 0xDBF0FF)
    static let heading = adaptive(0x292C30, 0x111822)
}

struct HandbookWikiBackground: View {
    var paper = false
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            paper ? HandbookWikiTheme.paper : HandbookWikiTheme.background
            AssetImage(path: "wiki/v4/ui/info/starlight.png", label: "", size: 230, renderingMode: .template)
                .foregroundColor(.white).opacity(0.09).rotationEffect(.degrees(-18))
                .padding(.bottom, 110).offset(x: 55).accessibilityHidden(true)
        }.clipped().ignoresSafeArea()
    }
}

struct EdgeRoundedRectangle: Shape {
    var radius: CGFloat
    var corners: UIRectCorner
    func path(in rect: CGRect) -> Path {
        Path(UIBezierPath(roundedRect: rect, byRoundingCorners: corners,
                          cornerRadii: CGSize(width: radius, height: radius)).cgPath)
    }
}

struct AssetImage: View {
    let path: String?
    let label: String
    var size: CGFloat = 48
    var renderingMode: Image.TemplateRenderingMode? = nil
    private static let cache = NSCache<NSString, UIImage>()
    private var image: UIImage? {
        guard let path, !path.contains(".."), !path.hasPrefix("/"),
              let root = Bundle.main.resourceURL?.appendingPathComponent("assets") else { return nil }
        if let cached = Self.cache.object(forKey: path as NSString) { return cached }
        guard let result = UIImage(contentsOfFile: root.appendingPathComponent(path).path) else { return nil }
        Self.cache.setObject(result, forKey: path as NSString, cost: Int(result.size.width * result.size.height * 4))
        Self.cache.totalCostLimit = 32 * 1024 * 1024
        return result
    }
    var body: some View {
        Group {
            if let image { Image(uiImage: image).renderingMode(renderingMode).resizable().scaledToFit() }
            else { Image(systemName: "photo").resizable().scaledToFit().foregroundColor(.secondary).padding(size * 0.2) }
        }.frame(width: size, height: size).accessibilityLabel(label)
    }
}

struct TypeIcons: View {
    let types: [String]
    var body: some View {
        HStack(spacing: 3) {
            ForEach(types, id: \.self) { type in
                AssetImage(path: CatalogAssets.type(type), label: type, size: 22)
            }
        }
    }
}

struct PetCard: View {
    let pet: PetSummary
    @ScaledMetric(relativeTo: .headline) private var denseNameHeight: CGFloat = 44
    var compact = false
    var dense = false
    var illustrationSize: CGFloat = 136
    var body: some View {
        Group {
            if compact {
                HStack(spacing: 14) {
                    AssetImage(path: CatalogAssets.pet(pet.illustrationKey), label: pet.name, size: 82)
                    nameBlock
                    Spacer(minLength: 0)
                    TypeIcons(types: pet.types)
                }.padding(12)
            } else {
                VStack(alignment: .leading, spacing: dense ? 6 : 10) {
                    HStack {
                        Text("NO.\(pet.dexNo)").font((dense ? Font.caption2 : .caption).monospacedDigit()).foregroundColor(.secondary)
                        Spacer(minLength: 0)
                        if !dense { TypeIcons(types: pet.types) }
                    }
                    AssetImage(path: CatalogAssets.pet(pet.illustrationKey), label: pet.name, size: illustrationSize)
                        .frame(maxWidth: .infinity)
                    nameBlock.frame(minHeight: dense ? denseNameHeight : nil, alignment: .topLeading)
                    if dense { TypeIcons(types: pet.types) }
                }.padding(dense ? 8 : 14).frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(LinearGradient(colors: [HandbookTheme.typeColor(pet.types.first ?? "").opacity(0.16), HandbookTheme.surface],
                                   startPoint: .topLeading, endPoint: .bottomTrailing))
        .clipShape(RoundedRectangle(cornerRadius: dense ? 16 : 22))
        .accessibilityElement(children: .combine)
    }
    private var nameBlock: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(pet.name).font(HandbookTheme.display(dense ? 16 : 19)).foregroundColor(pet.hasShiny ? .purple : .primary)
                .lineLimit(dense ? 2 : nil)
            if let form = pet.form, !pet.isDefaultForm { Text(form).font(.caption).foregroundColor(.secondary) }
            if compact { Text("NO.\(pet.dexNo)").font(.caption.monospacedDigit()).foregroundColor(.secondary) }
        }
    }
}

extension SkillCatalogLayout {
    var title: String {
        switch self {
        case .twoColumn: return tr("Grid")
        case .threeColumn: return tr("Three columns")
        case .detailed: return tr("Detailed descriptions")
        }
    }
    var symbol: String {
        switch self {
        case .twoColumn: return "square.grid.2x2"
        case .threeColumn: return "square.grid.3x2"
        case .detailed: return "list.bullet.rectangle"
        }
    }
}

struct SkillLayoutMenu: View {
    @EnvironmentObject private var app: AppModel
    var identifier = "skills.layout"
    var body: some View {
        Menu {
            Picker(tr("Skill card layout"), selection: Binding(
                get: { app.skillLayout }, set: { value in Task { await app.setSkillLayout(value) } }
            )) {
                ForEach(SkillCatalogLayout.allCases, id: \.self) { layout in
                    Label(layout.title, systemImage: layout.symbol).tag(layout)
                }
            }
        } label: {
            Image(systemName: app.skillLayout.symbol).frame(minWidth: 44, minHeight: 44)
        }.accessibilityLabel(tr("Skill card layout")).accessibilityIdentifier(identifier)
    }
}

struct SkillGrid<Content: View>: View {
    let layout: SkillCatalogLayout
    @ViewBuilder let content: (_ compact: Bool, _ dense: Bool) -> Content
    @Environment(\.dynamicTypeSize) private var textSize
    var body: some View {
        let count = textSize.isAccessibilitySize || layout == .detailed ? 1 : layout == .threeColumn ? 3 : 2
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10, alignment: .top), count: count), spacing: 10) {
            content(count > 1, count == 3)
        }
    }
}

struct CompactSkillCard: View {
    let skill: SkillSummary
    var level: Int?
    var dense = false
    var body: some View {
        HStack(alignment: .center, spacing: dense ? 5 : 6) {
            AssetImage(path: CatalogAssets.skill(skill), label: skill.name, size: dense ? 40 : 60)
                .accessibilityHidden(true)
                .overlay(alignment: .bottomLeading) {
                    if !skill.isFeature {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill").font(.system(size: 8))
                            Text(metric(skill.energyText, skill.energyValue)).font(.system(size: dense ? 10 : 12, weight: .bold, design: .rounded))
                        }.padding(3).background(Color.black.opacity(0.75)).clipShape(RoundedRectangle(cornerRadius: 5))
                            .offset(x: -2, y: 4).accessibilityHidden(true)
                    }
                }
            VStack(alignment: .leading, spacing: dense ? 4 : 5) {
                Text(skill.name).font(HandbookTheme.display(dense ? 13 : 16)).lineLimit(2).minimumScaleFactor(0.75)
                    .padding(.trailing, dense ? 12 : 14).fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if skill.isFeature {
                    Label(tr("Feature"), systemImage: "star.circle.fill").font(.caption2.bold()).foregroundColor(.white.opacity(0.8))
                } else {
                    HStack(spacing: dense ? 3 : 4) {
                        if let type = skill.element {
                            AssetImage(path: CatalogAssets.type(type), label: type, size: dense ? 12 : 16).accessibilityHidden(true)
                        }
                        Text(metric(skill.powerText, skill.powerValue)).font(.system(size: dense ? 12 : 14, weight: .heavy, design: .rounded))
                            .monospacedDigit().lineLimit(1).minimumScaleFactor(0.65)
                    }.padding(.horizontal, dense ? 4 : 6).frame(maxWidth: .infinity, minHeight: dense ? 21 : 24)
                        .background(HandbookTheme.typeColor(skill.element ?? "").opacity(0.32)).clipShape(Capsule())
                }
            }.frame(maxWidth: .infinity, alignment: .leading)
        }.padding(.bottom, level == nil ? 0 : 18).padding(.horizontal, dense ? 6 : 8).padding(.vertical, 8)
            .frame(maxWidth: .infinity, minHeight: level == nil ? (dense ? 72 : 80) : (dense ? 88 : 94), alignment: .center)
            .foregroundColor(.white)
            .background(Color(red: 0.14, green: 0.16, blue: 0.16))
            .overlay(alignment: .topTrailing) {
                if let icon = SkillTerms.icon(skill.damageClass ?? skill.category ?? "") {
                    AssetImage(path: icon, label: skill.damageClass ?? skill.category ?? "", size: dense ? 12 : 16)
                        .opacity(0.35).padding(6).accessibilityHidden(true)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if let level {
                    Text("LV\(level)").font(.caption2.bold().monospacedDigit()).padding(.horizontal, 6).padding(.vertical, 2)
                        .foregroundColor(.white.opacity(0.8))
                        .background(Color.white.opacity(0.10)).clipShape(RoundedRectangle(cornerRadius: 5)).padding(5)
                        .accessibilityHidden(true)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .accessibilityElement(children: .combine).accessibilityLabel(accessibleSummary)
    }
    private var accessibleSummary: String {
        var parts = [skill.name, skill.element, skill.damageClass ?? skill.category].compactMap { $0 }
        if !skill.isFeature {
            parts += ["\(tr("Energy")) \(metric(skill.energyText, skill.energyValue))", "\(tr("Power")) \(metric(skill.powerText, skill.powerValue))"]
        }
        if let level { parts.append("\(tr("Level")) \(level)") }
        return parts.joined(separator: ", ")
    }
}

struct SkillCard: View {
    let skill: SkillSummary
    var prominent = false
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AssetImage(path: CatalogAssets.skill(skill), label: skill.name, size: prominent ? 72 : 48)
            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    Text(skill.name).font(HandbookTheme.display(19))
                    if let type = skill.element { TypeIcons(types: [type]) }
                }
                HStack(spacing: 12) {
                    Text(skill.damageClass ?? skill.category ?? tr("Unknown"))
                    Text("\(tr("Energy")) \(metric(skill.energyText, skill.energyValue))")
                    Text("\(tr("Power")) \(metric(skill.powerText, skill.powerValue))")
                }.font(.caption).foregroundColor(.secondary)
                if let description = skill.description { Text(description).font(.subheadline).foregroundColor(.secondary) }
            }
            Spacer(minLength: 0)
        }.padding(14).frame(maxWidth: .infinity, alignment: .leading)
            .background(HandbookTheme.surface).clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

func metric(_ text: String?, _ value: Double?) -> String {
    if let text, !text.isEmpty { return text }
    return value.map { $0.formatted(.number.precision(.fractionLength(0...2))) } ?? "—"
}

struct ReadingPanel<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(tr(title)).font(HandbookTheme.display()).accessibilityAddTraits(.isHeader)
            content()
        }.padding(18).frame(maxWidth: .infinity, alignment: .leading)
            .background(HandbookTheme.surface).clipShape(RoundedRectangle(cornerRadius: 22))
    }
}

struct EmptyState: View {
    let text: String
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "magnifyingglass").font(.title)
            Text(tr(text)).multilineTextAlignment(.center)
        }.foregroundColor(.secondary).frame(maxWidth: .infinity).padding(32)
    }
}

struct MultiSelectSection<Value: Hashable>: View {
    let title: String
    let values: [Value]
    @Binding var selection: [Value]
    var icon: (Value) -> String? = { _ in nil }
    var symbol: (Value) -> String? = { _ in nil }
    var minimumWidth: CGFloat = 90
    var loading = false
    let label: (Value) -> String
    @Environment(\.dynamicTypeSize) private var textSize
    var body: some View {
        ReadingPanel(title: title) {
            if loading { ProgressView().frame(maxWidth: .infinity).padding(8).accessibilityLabel(tr(title)) }
            LazyVGrid(columns: textSize.isAccessibilitySize ? [GridItem(.flexible())] : [GridItem(.adaptive(minimum: minimumWidth), spacing: 8)], spacing: 8) {
                ForEach(values, id: \.self) { value in
                    FilterChoice(title: label(value), icon: icon(value), symbol: symbol(value), selected: selection.contains(value),
                                 identifier: "filter.\(title).\(String(describing: value))") {
                        if selection.contains(value) { selection.removeAll { $0 == value } }
                        else { selection.append(value) }
                    }
                }
            }
        }
    }
}

struct FilterChoice: View {
    let title: String
    var icon: String?
    var symbol: String?
    let selected: Bool
    var identifier: String?
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Group {
                if let icon {
                    VStack(spacing: 5) {
                        AssetImage(path: icon, label: title, size: 30).accessibilityHidden(true)
                        Text(title).font(.caption.weight(.medium)).multilineTextAlignment(.center)
                    }.padding(.vertical, 10)
                } else {
                    HStack(spacing: 6) {
                        if let symbol { Image(systemName: symbol).accessibilityHidden(true) }
                        Text(title).font(.subheadline.weight(.medium)).multilineTextAlignment(.center)
                    }.padding(.vertical, 10)
                }
            }.padding(.horizontal, 8).frame(maxWidth: .infinity, minHeight: 44)
                .foregroundColor(selected ? HandbookTheme.detailAccent : .primary)
                .background(selected ? HandbookTheme.detailAccent.opacity(0.10) : HandbookTheme.detailWash)
                .clipShape(RoundedRectangle(cornerRadius: 13))
                .overlay(RoundedRectangle(cornerRadius: 13).stroke(selected ? HandbookTheme.detailAccent : .clear, lineWidth: 1.5))
                .overlay(alignment: .topTrailing) {
                    if selected {
                        Image(systemName: "checkmark.circle.fill").font(.caption2.bold())
                            .foregroundColor(HandbookTheme.detailAccent).padding(3).accessibilityHidden(true)
                    }
                }
        }.buttonStyle(.plain).accessibilityLabel(title)
            .accessibilityAddTraits(selected ? .isSelected : [])
            .accessibilityIdentifier(identifier ?? title)
    }
}

struct SourcePanel: View {
    let references: [SourceReference]
    var body: some View {
        ReadingPanel(title: "Source") {
            ForEach(references) { reference in
                VStack(alignment: .leading, spacing: 4) {
                    Text(reference.name).font(.headline)
                    Text("\(tr("Revision")) \(reference.revisionID) · \(reference.licenseID)").font(.caption)
                    Text(reference.url).font(.caption).textSelection(.enabled)
                }
            }
        }
    }
}
