import SwiftUI
import HandbookCore

struct FavoriteButton: View {
    let session: HandbookSession
    let object: ObjectRef
    @EnvironmentObject private var app: AppModel
    @State private var selected = false
    @State private var busy = true
    var body: some View {
        Button {
            busy = true
            Task {
                defer { busy = false }
                do {
                    try await session.user.setFavorite(object, enabled: !selected)
                    selected.toggle(); app.changed()
                } catch { app.report(error) }
            }
        } label: {
            Image(systemName: selected ? "star.fill" : "star")
        }.disabled(busy).accessibilityLabel(tr(selected ? "Remove favorite" : "Add favorite"))
            .accessibilityIdentifier("personal.favorite")
            .task(id: app.userRevision) {
                do { selected = try await session.user.isFavorite(object); busy = false }
                catch { app.report(error) }
            }
    }
}

private struct NoteDraft: Identifiable {
    let id = UUID()
    let noteID: String?
    let content: String
}
struct PersonalPanel: View {
    let session: HandbookSession
    let object: ObjectRef
    var handbookID: String?
    @EnvironmentObject private var app: AppModel
    @State private var notes: [PersonalNote] = []
    @State private var collected = false
    @State private var loading = true
    @State private var saving = false
    @State private var draft: NoteDraft?
    @State private var deleting: PersonalNote?
    var body: some View {
        ReadingPanel(title: "My library") {
            if let handbookID {
                Button {
                    saving = true
                    Task {
                        defer { saving = false }
                        do {
                            try await session.user.setCollected(handbookID, name: object.name, collected: !collected)
                            collected.toggle(); app.changed()
                        } catch { app.report(error) }
                    }
                } label: {
                    Label(tr("Handbook entry collected"), systemImage: collected ? "checkmark.circle.fill" : "circle")
                }.disabled(loading || saving).accessibilityIdentifier("personal.collected")
                    .accessibilityValue(tr(collected ? "Yes" : "No"))
            }
            if loading { ProgressView() }
            if notes.isEmpty, !loading { Text(tr("No notes saved for this item.")).foregroundColor(.secondary) }
            ForEach(notes) { note in
                VStack(alignment: .leading, spacing: 10) {
                    Text(note.content).textSelection(.enabled)
                    HStack {
                        Button(tr("Edit note")) { draft = NoteDraft(noteID: note.id, content: note.content) }
                        Spacer()
                        Button(tr("Delete note"), role: .destructive) { deleting = note }
                    }.font(.caption)
                }.padding(.vertical, 8)
            }
            Button { draft = NoteDraft(noteID: nil, content: "") } label: {
                Label(tr("Personal note"), systemImage: "square.and.pencil")
            }.accessibilityIdentifier("personal.addNote")
            Text(tr("Saved only on this device")).font(.caption).foregroundColor(.secondary)
        }
        .task(id: app.userRevision) { await load() }
        .sheet(item: $draft) { draft in
            AppNavigation { NoteEditorView(session: session, object: object, noteID: draft.noteID, initialContent: draft.content) }
        }
        .confirmationDialog(tr("Delete note?"), isPresented: Binding(
            get: { deleting != nil }, set: { if !$0 { deleting = nil } }
        ), titleVisibility: .visible) {
            Button(tr("Delete"), role: .destructive) {
                guard let note = deleting else { return }
                Task {
                    do { try await session.user.deleteNote(note.id); app.changed(); deleting = nil }
                    catch { app.report(error) }
                }
            }
        } message: { Text(tr("This removes the note from this device.")) }
    }
    private func load() async {
        loading = true
        defer { loading = false }
        do {
            notes = try await session.user.notes(object)
            if let handbookID { collected = try await session.user.isCollected(handbookID) }
        } catch { app.report(error) }
    }
}

struct NoteEditorView: View {
    let session: HandbookSession
    let object: ObjectRef
    let noteID: String?
    @EnvironmentObject private var app: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var content: String
    @State private var saving = false
    @State private var failed = false
    init(session: HandbookSession, object: ObjectRef, noteID: String?, initialContent: String) {
        self.session = session; self.object = object; self.noteID = noteID
        _content = State(initialValue: initialContent)
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(object.name).font(.headline)
            TextEditor(text: $content).accessibilityLabel(tr("Personal note")).accessibilityIdentifier("note.editor")
            Text(tr("Saved only on this device")).font(.caption).foregroundColor(.secondary)
        }.padding().navigationTitle(tr(noteID == nil ? "Personal note" : "Edit note"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(tr("Cancel")) { dismiss() }.disabled(saving) }
                ToolbarItem(placement: .confirmationAction) {
                    Button(tr(noteID == nil ? "Save note" : "Save edit")) {
                        saving = true
                        Task {
                            defer { saving = false }
                            do {
                                _ = try await session.user.saveNote(object, content: content, id: noteID)
                                app.changed(); dismiss()
                            } catch { failed = true }
                        }
                    }.disabled(saving || content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .accessibilityIdentifier("note.save")
                }
            }.interactiveDismissDisabled(saving)
            .alert(tr("The note could not be saved. Your draft is still here."), isPresented: $failed) {
                Button(tr("OK"), role: .cancel) {}
            }
    }
}

struct PersonalLibraryView: View {
    let session: HandbookSession
    @EnvironmentObject private var app: AppModel
    @State private var favorites: [FavoriteItem] = []
    @State private var marks: [CollectionMark] = []
    @State private var loading = true
    @State private var error = false
    var body: some View {
        List {
            if loading { ProgressView() }
            if error { Button(tr("Retry")) { Task { await load() } } }
            Section(header: Text(tr("Favorites"))) {
                if favorites.isEmpty, !loading { Text(tr("No favorites yet.")).foregroundColor(.secondary) }
                ForEach(favorites) { favorite in
                    NavigationLink(destination: SavedItemView(session: session, object: favorite.object)) {
                        VStack(alignment: .leading) {
                            Text(favorite.object.name)
                            Text(favorite.object.objectID).font(.caption).foregroundColor(.secondary)
                        }
                    }.accessibilityIdentifier("favorite.\(favorite.object.type.rawValue).\(favorite.object.objectID)")
                }
            }
            Section(header: Text(tr("Collected"))) {
                if marks.isEmpty, !loading { Text(tr("No collected handbook entries yet.")).foregroundColor(.secondary) }
                ForEach(marks) { mark in
                    NavigationLink(destination: SavedItemView(session: session, object: ObjectRef(
                        datasetID: mark.datasetID, type: .handbook, objectID: mark.handbookID, name: mark.name
                    ))) { Text(mark.name) }
                }
            }
        }.navigationTitle(tr("My library")).accessibilityIdentifier("personal.library")
            .task(id: app.userRevision) { await load() }
    }
    private func load() async {
        loading = true; error = false
        defer { loading = false }
        do { favorites = try await session.user.favorites(); marks = try await session.user.collectionMarks() }
        catch { self.error = true; app.report(error) }
    }
}

struct SavedItemView: View {
    let session: HandbookSession
    let object: ObjectRef
    @State private var resolvedPetID: String?
    @State private var resolvedSkillID: String?
    @State private var loading = true
    @State private var failed = false
    var body: some View {
        Group {
            if let resolvedPetID { PetDetailView(session: session, petID: resolvedPetID) }
            else if let resolvedSkillID { SkillDetailView(session: session, skillID: resolvedSkillID) }
            else if loading { ProgressView() }
            else {
                ScrollView {
                    VStack(spacing: 16) {
                        ReadingPanel(title: object.name) {
                            Text(tr(failed ? "The saved item could not be opened." : "Currently unavailable in this Catalog."))
                            Text(object.objectID).font(.caption).textSelection(.enabled)
                            if failed { Button(tr("Retry")) { Task { await resolve() } } }
                        }
                        PersonalPanel(session: session, object: object,
                                      handbookID: object.type == .handbook ? object.objectID : nil)
                        FavoriteButton(session: session, object: object)
                    }.padding()
                }
            }
        }.navigationTitle(object.name).task { await resolve() }
    }
    private func resolve() async {
        loading = true; failed = false
        defer { loading = false }
        guard object.datasetID == session.info.datasetID else { return }
        do {
            switch object.type {
            case .pet: resolvedPetID = try await session.catalog.petDetail(object.objectID).summary.id
            case .skill: resolvedSkillID = try await session.catalog.skillDetail(object.objectID).summary.id
            case .handbook:
                resolvedPetID = try await session.catalog.forms(object.objectID).first(where: \.isDefaultForm)?.id
            }
        } catch let error as HandbookError { failed = error.code != "not_found" }
        catch { failed = true }
    }
}
