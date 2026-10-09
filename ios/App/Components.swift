import SwiftUI
import CoreText
import HandbookCore

func tr(_ key: String) -> String { NSLocalizedString(key, comment: "") }

enum HandbookTheme {
    static let background = Color(uiColor: .systemGroupedBackground)
    static let surface = Color(uiColor: .secondarySystemGroupedBackground)
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

struct AssetImage: View {
    let path: String?
    let label: String
    var size: CGFloat = 48
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
            if let image { Image(uiImage: image).resizable().scaledToFit() }
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
    var compact = false
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
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("NO.\(pet.dexNo)").font(.caption.monospacedDigit()).foregroundColor(.secondary)
                        Spacer(minLength: 0)
                        TypeIcons(types: pet.types)
                    }
                    AssetImage(path: CatalogAssets.pet(pet.illustrationKey), label: pet.name, size: 136)
                        .frame(maxWidth: .infinity)
                    nameBlock
                }.padding(14).frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(LinearGradient(colors: [HandbookTheme.typeColor(pet.types.first ?? "").opacity(0.16), HandbookTheme.surface],
                                   startPoint: .topLeading, endPoint: .bottomTrailing))
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .accessibilityElement(children: .combine)
    }
    private var nameBlock: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(pet.name).font(HandbookTheme.display(19)).foregroundColor(pet.hasShiny ? .purple : .primary)
            if let form = pet.form, !pet.isDefaultForm { Text(form).font(.caption).foregroundColor(.secondary) }
            if compact { Text("NO.\(pet.dexNo)").font(.caption.monospacedDigit()).foregroundColor(.secondary) }
        }
    }
}

struct SkillCard: View {
    let skill: SkillSummary
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AssetImage(path: CatalogAssets.skill(skill), label: skill.name, size: 48)
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
    let label: (Value) -> String
    var body: some View {
        Section(header: Text(tr(title))) {
            ForEach(values, id: \.self) { value in
                Button {
                    if selection.contains(value) { selection.removeAll { $0 == value } }
                    else { selection.append(value) }
                } label: {
                    HStack {
                        Text(label(value)).foregroundColor(.primary)
                        Spacer()
                        if selection.contains(value) { Image(systemName: "checkmark").foregroundColor(.accentColor) }
                    }
                }.accessibilityAddTraits(selection.contains(value) ? .isSelected : [])
            }
        }
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
