import Foundation
import SwiftUI
import HandbookCore

struct HandbookSession {
    let generation = UUID()
    let catalog: CatalogRepository
    let user: UserRepository
    let assets: AssetRepository
    let info: CatalogInfo
    let attribution: String
    let outcome: String
    let updateService: CatalogUpdateService
    let assetRoot: URL
}

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var session: HandbookSession?
    @Published private(set) var startupError: String?
    @Published var operationError: String?
    @Published private(set) var layout: PetCatalogLayout = .threeColumn
    @Published private(set) var skillLayout: SkillCatalogLayout = .twoColumn
    @Published private(set) var userRevision = 0
    @Published private(set) var busy = false
    private var supportURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    }
    private var assetRoot: URL { Bundle.main.resourceURL!.appendingPathComponent("assets") }

    func load(restore: Bool = false) async {
        guard !busy, session == nil || restore else { return }
        busy = true; startupError = nil
        defer { busy = false }
        do {
            let root = assetRoot
            let support = supportURL
            let bundle = try await Task.detached(priority: .userInitiated) { try CatalogBundle.load(assetRoot: root) }.value
            let installer = CatalogInstaller(supportURL: support)
            let open = try await installer.prepare(bundle, restore: restore)
            let user: UserRepository
            if let existing = session?.user { user = existing }
            else {
                user = try await Task.detached(priority: .userInitiated) {
                    try UserRepository(supportURL: support, schemaSQL: String(contentsOf: root.appendingPathComponent("database/user_v1.sql")))
                }.value
            }
            let catalog = CatalogRepository(databaseURL: open.databaseURL)
            let info = try await catalog.info()
            let trustData = try Data(contentsOf: root.appendingPathComponent("catalog/catalog_trust_store.json"))
            let updates = CatalogUpdateService(trustData: trustData, installer: installer,
                                               appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.2.0")
            layout = try await user.layout()
            skillLayout = try await user.skillLayout()
            session = HandbookSession(catalog: catalog, user: user, assets: AssetRepository(assetRoot: root),
                                      info: info, attribution: open.attribution, outcome: open.outcome,
                                      updateService: updates, assetRoot: root)
        } catch {
            if session == nil { startupError = message(error) }
            else { operationError = message(error) }
        }
    }
    func acceptUpdate(_ open: CatalogOpenResult) async throws {
        guard let existing = session else { return }
        let catalog = CatalogRepository(databaseURL: open.databaseURL)
        let info = try await catalog.info()
        session = HandbookSession(catalog: catalog, user: existing.user, assets: existing.assets,
                                  info: info, attribution: open.attribution, outcome: "Installed a verified Catalog package",
                                  updateService: existing.updateService, assetRoot: existing.assetRoot)
    }
    func setLayout(_ value: PetCatalogLayout) async {
        guard let session else { return }
        do { try await session.user.setLayout(value); layout = value; changed() }
        catch { operationError = message(error) }
    }
    func setSkillLayout(_ value: SkillCatalogLayout) async {
        guard let session else { return }
        do { try await session.user.setSkillLayout(value); skillLayout = value; changed() }
        catch { operationError = message(error) }
    }
    func changed() { userRevision += 1 }
    func report(_ error: Error) { operationError = message(error) }
    private func message(_ error: Error) -> String {
        if let error = error as? HandbookError { return error.message }
        return "The local data operation failed. Your saved data has been preserved."
    }
}

@MainActor
final class PetListModel: ObservableObject {
    @Published private(set) var rows: [PetSummary] = []
    @Published private(set) var loading = false
    @Published private(set) var error: String?
    @Published private(set) var hasMore = false
    private var generation = 0
    private let repository: CatalogRepository
    init(_ repository: CatalogRepository) { self.repository = repository }
    func load(_ query: PetQuery, append: Bool = false) async {
        if append && loading { return }
        generation += 1
        let request = generation
        loading = true; error = nil
        if !append { rows = [] }
        var page = query
        page.offset = append ? rows.count : 0
        defer { if request == generation { loading = false } }
        do {
            let result = try await repository.searchPets(page)
            guard !Task.isCancelled, request == generation else { return }
            if append { rows += result } else { rows = result }
            hasMore = result.count == page.limit
        } catch {
            if !Task.isCancelled, request == generation { self.error = "The creatures could not be loaded." }
        }
    }
}

@MainActor
final class SkillListModel: ObservableObject {
    @Published private(set) var rows: [SkillSummary] = []
    @Published private(set) var loading = false
    @Published private(set) var error: String?
    @Published private(set) var hasMore = false
    private var generation = 0
    private let repository: CatalogRepository
    init(_ repository: CatalogRepository) { self.repository = repository }
    func load(_ query: SkillQuery, append: Bool = false) async {
        if append && loading { return }
        generation += 1; let request = generation
        loading = true; error = nil
        if !append { rows = [] }
        var page = query; page.offset = append ? rows.count : 0
        defer { if request == generation { loading = false } }
        do {
            let result = try await repository.searchSkills(page)
            guard !Task.isCancelled, request == generation else { return }
            if append { rows += result } else { rows = result }
            hasMore = result.count == page.limit
        } catch {
            if !Task.isCancelled, request == generation { self.error = "The skills could not be loaded." }
        }
    }
}
