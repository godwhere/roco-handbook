-- user.db stores only personal data, migrates independently, and has no
-- foreign keys into catalog.db.
PRAGMA foreign_keys = ON;
PRAGMA user_version = 1;

BEGIN;
CREATE TABLE user_meta (
    singleton INTEGER PRIMARY KEY CHECK (singleton = 1),
    schema_version INTEGER NOT NULL CHECK (schema_version > 0),
    created_at_utc TEXT NOT NULL
);

CREATE TABLE favorites (
    dataset_id TEXT NOT NULL,
    object_type TEXT NOT NULL CHECK (object_type IN ('pet', 'skill', 'handbook')),
    object_id TEXT NOT NULL,
    name_snapshot TEXT NOT NULL,
    created_at_utc TEXT NOT NULL,
    PRIMARY KEY (dataset_id, object_type, object_id)
);

-- A V1 collection mark applies to one handbook entry and does not imply that
-- every form is owned.
CREATE TABLE collection_marks (
    dataset_id TEXT NOT NULL,
    handbook_id TEXT NOT NULL,
    collected INTEGER NOT NULL CHECK (collected IN (0, 1)),
    name_snapshot TEXT NOT NULL,
    updated_at_utc TEXT NOT NULL,
    PRIMARY KEY (dataset_id, handbook_id)
);

CREATE TABLE notes (
    note_id TEXT PRIMARY KEY NOT NULL,
    dataset_id TEXT NOT NULL,
    object_type TEXT NOT NULL CHECK (object_type IN ('pet', 'skill', 'handbook')),
    object_id TEXT NOT NULL,
    name_snapshot TEXT NOT NULL,
    content TEXT NOT NULL,
    created_at_utc TEXT NOT NULL,
    updated_at_utc TEXT NOT NULL
);

CREATE TABLE settings (
    setting_key TEXT PRIMARY KEY NOT NULL,
    value_json TEXT NOT NULL,
    updated_at_utc TEXT NOT NULL
);

CREATE INDEX idx_favorites_created ON favorites(created_at_utc);
CREATE INDEX idx_notes_object ON notes(dataset_id, object_type, object_id);
COMMIT;
