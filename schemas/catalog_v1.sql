-- catalog.db is writable by the builder and read-only in the released App.
-- Foreign keys must be enabled outside transactions on every write connection.
PRAGMA foreign_keys = ON;
PRAGMA user_version = 1;

BEGIN;

CREATE TABLE catalog_meta (
    singleton INTEGER PRIMARY KEY CHECK (singleton = 1),
    dataset_id TEXT NOT NULL,
    schema_version INTEGER NOT NULL CHECK (schema_version = 1),
    data_version INTEGER NOT NULL CHECK (data_version > 0),
    snapshot_id TEXT NOT NULL,
    adapter_version TEXT NOT NULL,
    builder_version TEXT NOT NULL,
    built_at_utc TEXT NOT NULL,
    coverage_json TEXT NOT NULL
);

CREATE TABLE source_revisions (
    source_ref TEXT PRIMARY KEY NOT NULL,
    source_key TEXT NOT NULL,
    source_name TEXT NOT NULL,
    requested_title TEXT NOT NULL,
    canonical_title TEXT NOT NULL,
    page_id INTEGER NOT NULL CHECK (page_id > 0),
    revision_id INTEGER NOT NULL CHECK (revision_id > 0),
    revised_at_utc TEXT NOT NULL,
    fetched_at_utc TEXT NOT NULL,
    content_bytes INTEGER NOT NULL CHECK (content_bytes >= 0),
    api_sha1 TEXT,
    content_sha256 TEXT NOT NULL CHECK (length(content_sha256) = 64),
    source_url TEXT NOT NULL,
    attribution_text TEXT NOT NULL,
    license_id TEXT NOT NULL,
    UNIQUE (source_key, revision_id)
);

CREATE TABLE handbook_entries (
    handbook_id TEXT PRIMARY KEY NOT NULL,
    dex_no TEXT,
    display_name TEXT,
    sort_order INTEGER,
    status TEXT NOT NULL DEFAULT 'active'
        CHECK (status IN ('active', 'retired'))
);

CREATE TABLE types (
    type_id TEXT PRIMARY KEY NOT NULL,
    name TEXT NOT NULL UNIQUE
);

CREATE TABLE skills (
    skill_id TEXT PRIMARY KEY NOT NULL,
    upstream_numeric_id INTEGER,
    name TEXT NOT NULL,
    category TEXT,
    element_raw TEXT,
    type_id TEXT REFERENCES types(type_id),
    description TEXT,
    energy_value REAL,
    energy_text TEXT,
    power_value REAL,
    power_text TEXT,
    target_text TEXT,
    icon_key TEXT,
    extra_json TEXT NOT NULL DEFAULT '{}',
    status TEXT NOT NULL DEFAULT 'active'
        CHECK (status IN ('active', 'retired'))
);

CREATE TABLE skill_description_notes (
    skill_id TEXT NOT NULL REFERENCES skills(skill_id),
    ordinal INTEGER NOT NULL CHECK (ordinal >= 0),
    note_id TEXT NOT NULL,
    PRIMARY KEY (skill_id, ordinal)
);

CREATE TABLE pets (
    pet_id TEXT PRIMARY KEY NOT NULL,
    handbook_id TEXT REFERENCES handbook_entries(handbook_id),
    name TEXT NOT NULL,
    title TEXT NOT NULL,
    form TEXT,
    class_name TEXT,
    description TEXT,
    stage INTEGER CHECK (stage IS NULL OR stage >= 0),
    belong_season_raw TEXT,
    starlight INTEGER,
    review_gold INTEGER,
    height_text TEXT,
    weight_text TEXT,
    can_double_ride INTEGER CHECK (can_double_ride IN (0, 1)),
    has_shiny INTEGER CHECK (has_shiny IN (0, 1)),
    is_lord_evolution INTEGER CHECK (is_lord_evolution IN (0, 1)),
    hide_entry_name INTEGER CHECK (hide_entry_name IN (0, 1)),
    show_topics INTEGER CHECK (show_topics IN (0, 1)),
    feature_skill_id TEXT REFERENCES skills(skill_id),
    hp INTEGER CHECK (hp IS NULL OR hp >= 0),
    atk INTEGER CHECK (atk IS NULL OR atk >= 0),
    def INTEGER CHECK (def IS NULL OR def >= 0),
    spa INTEGER CHECK (spa IS NULL OR spa >= 0),
    spd INTEGER CHECK (spd IS NULL OR spd >= 0),
    spe INTEGER CHECK (spe IS NULL OR spe >= 0),
    illustration_key TEXT,
    head_key TEXT,
    extra_json TEXT NOT NULL DEFAULT '{}',
    status TEXT NOT NULL DEFAULT 'active'
        CHECK (status IN ('active', 'retired'))
);

-- Store the default card separately to avoid an insertion cycle between
-- handbook_entries and pets. This is a display choice, not a game rule or ID.
CREATE TABLE handbook_display (
    handbook_id TEXT PRIMARY KEY NOT NULL
        REFERENCES handbook_entries(handbook_id),
    default_pet_id TEXT NOT NULL REFERENCES pets(pet_id),
    selection_reason TEXT NOT NULL
);

CREATE TABLE pet_aliases (
    pet_id TEXT NOT NULL REFERENCES pets(pet_id),
    alias TEXT NOT NULL,
    alias_kind TEXT NOT NULL,
    PRIMARY KEY (pet_id, alias, alias_kind)
);

CREATE TABLE pet_types (
    pet_id TEXT NOT NULL REFERENCES pets(pet_id),
    slot INTEGER NOT NULL CHECK (slot > 0),
    type_id TEXT NOT NULL REFERENCES types(type_id),
    PRIMARY KEY (pet_id, slot),
    UNIQUE (pet_id, type_id)
);

CREATE TABLE learnsets (
    learnset_id TEXT PRIMARY KEY NOT NULL,
    feature_skill_id TEXT REFERENCES skills(skill_id),
    extra_json TEXT NOT NULL DEFAULT '{}'
);

CREATE TABLE pet_learnsets (
    pet_id TEXT PRIMARY KEY NOT NULL REFERENCES pets(pet_id),
    learnset_id TEXT NOT NULL REFERENCES learnsets(learnset_id)
);

CREATE TABLE learnset_native_skills (
    learnset_id TEXT NOT NULL REFERENCES learnsets(learnset_id),
    ordinal INTEGER NOT NULL CHECK (ordinal >= 0),
    skill_id TEXT NOT NULL REFERENCES skills(skill_id),
    learn_level INTEGER CHECK (learn_level IS NULL OR learn_level >= 0),
    source_stage INTEGER CHECK (source_stage IS NULL OR source_stage >= 0),
    PRIMARY KEY (learnset_id, ordinal)
);

CREATE TABLE learnset_blood_skills (
    learnset_id TEXT NOT NULL REFERENCES learnsets(learnset_id),
    ordinal INTEGER NOT NULL CHECK (ordinal >= 0),
    skill_id TEXT NOT NULL REFERENCES skills(skill_id),
    blood_raw TEXT NOT NULL,
    blood_type_id TEXT REFERENCES types(type_id),
    learn_level INTEGER CHECK (learn_level IS NULL OR learn_level >= 0),
    PRIMARY KEY (learnset_id, ordinal)
);

CREATE TABLE learnset_skill_stones (
    learnset_id TEXT NOT NULL REFERENCES learnsets(learnset_id),
    ordinal INTEGER NOT NULL CHECK (ordinal >= 0),
    skill_id TEXT NOT NULL REFERENCES skills(skill_id),
    PRIMARY KEY (learnset_id, ordinal)
);

CREATE TABLE learnset_legendary_skills (
    learnset_id TEXT NOT NULL REFERENCES learnsets(learnset_id),
    ordinal INTEGER NOT NULL CHECK (ordinal >= 0),
    skill_id TEXT NOT NULL REFERENCES skills(skill_id),
    requirement_text TEXT,
    PRIMARY KEY (learnset_id, ordinal)
);

CREATE TABLE evolution_groups (
    evolution_group_id TEXT PRIMARY KEY NOT NULL,
    label TEXT,
    status TEXT NOT NULL DEFAULT 'active'
        CHECK (status IN ('active', 'retired'))
);

CREATE TABLE pet_evolution_groups (
    evolution_group_id TEXT NOT NULL
        REFERENCES evolution_groups(evolution_group_id),
    pet_id TEXT NOT NULL REFERENCES pets(pet_id),
    source_order INTEGER CHECK (source_order IS NULL OR source_order >= 0),
    PRIMARY KEY (evolution_group_id, pet_id)
);

CREATE TABLE evolution_edges (
    evolution_group_id TEXT NOT NULL,
    ordinal INTEGER NOT NULL CHECK (ordinal >= 0),
    from_pet_id TEXT NOT NULL,
    to_pet_id TEXT NOT NULL,
    method_code TEXT,
    level_requirement INTEGER
        CHECK (level_requirement IS NULL OR level_requirement >= 0),
    condition_text TEXT,
    condition_json TEXT NOT NULL DEFAULT '{}',
    PRIMARY KEY (evolution_group_id, ordinal),
    FOREIGN KEY (evolution_group_id, from_pet_id)
        REFERENCES pet_evolution_groups(evolution_group_id, pet_id),
    FOREIGN KEY (evolution_group_id, to_pet_id)
        REFERENCES pet_evolution_groups(evolution_group_id, pet_id)
);

-- The builder validates polymorphic entity sources because one SQL foreign key
-- cannot target pets, skills, learnsets, and other entity tables at once.
CREATE TABLE entity_sources (
    entity_kind TEXT NOT NULL CHECK (entity_kind IN
        ('pet', 'handbook', 'skill', 'learnset', 'evolution_group')),
    entity_id TEXT NOT NULL,
    source_ref TEXT NOT NULL REFERENCES source_revisions(source_ref),
    source_record_key TEXT NOT NULL,
    PRIMARY KEY (entity_kind, entity_id, source_ref, source_record_key)
);

CREATE INDEX idx_handbooks_order
    ON handbook_entries(status, sort_order, handbook_id);
CREATE INDEX idx_pets_handbook ON pets(handbook_id, status);
CREATE INDEX idx_pets_name ON pets(name);
CREATE INDEX idx_pets_title ON pets(title);
CREATE INDEX idx_pets_speed ON pets(status, spe, pet_id);
CREATE INDEX idx_pets_atk ON pets(status, atk, pet_id);
CREATE INDEX idx_pets_spa ON pets(status, spa, pet_id);
CREATE INDEX idx_pet_aliases_alias ON pet_aliases(alias);
CREATE INDEX idx_pet_types_type ON pet_types(type_id, pet_id);
CREATE INDEX idx_skills_name ON skills(name);
CREATE INDEX idx_skills_filter ON skills(status, category, type_id);
CREATE INDEX idx_pet_learnsets_learnset ON pet_learnsets(learnset_id, pet_id);
CREATE INDEX idx_native_skill ON learnset_native_skills(skill_id, learnset_id);
CREATE INDEX idx_blood_skill ON learnset_blood_skills(skill_id, learnset_id);
CREATE INDEX idx_stone_skill ON learnset_skill_stones(skill_id, learnset_id);
CREATE INDEX idx_legendary_skill
    ON learnset_legendary_skills(skill_id, learnset_id);
CREATE INDEX idx_evolution_members_pet
    ON pet_evolution_groups(pet_id, evolution_group_id);
CREATE INDEX idx_evolution_edges_to ON evolution_edges(to_pet_id);
CREATE INDEX idx_entity_sources_source ON entity_sources(source_ref);

-- Expose skill sources uniformly without losing bloodline, level, stage, or
-- source order. UNION ALL deliberately preserves multiple acquisition methods.
CREATE VIEW pet_skill_sources AS
SELECT p.pet_id, l.learnset_id, n.skill_id,
       'native' AS source_kind, n.learn_level,
       n.source_stage, NULL AS blood_raw, NULL AS requirement_text, n.ordinal
FROM pets p
JOIN pet_learnsets l ON l.pet_id = p.pet_id
JOIN learnset_native_skills n ON n.learnset_id = l.learnset_id
WHERE p.status = 'active'
UNION ALL
SELECT p.pet_id, l.learnset_id, b.skill_id,
       'blood', b.learn_level, NULL, b.blood_raw, NULL, b.ordinal
FROM pets p
JOIN pet_learnsets l ON l.pet_id = p.pet_id
JOIN learnset_blood_skills b ON b.learnset_id = l.learnset_id
WHERE p.status = 'active'
UNION ALL
SELECT p.pet_id, l.learnset_id, s.skill_id,
       'stone', NULL, NULL, NULL, NULL, s.ordinal
FROM pets p
JOIN pet_learnsets l ON l.pet_id = p.pet_id
JOIN learnset_skill_stones s ON s.learnset_id = l.learnset_id
WHERE p.status = 'active'
UNION ALL
SELECT p.pet_id, l.learnset_id, g.skill_id,
       'legendary', NULL, NULL, NULL, g.requirement_text, g.ordinal
FROM pets p
JOIN pet_learnsets l ON l.pet_id = p.pet_id
JOIN learnset_legendary_skills g ON g.learnset_id = l.learnset_id
WHERE p.status = 'active';

-- Core takes precedence and Learnset is a missing-value fallback. Build reports
-- must explain conflicts; this view must not hide them or mix features with
-- learnable active skills.
CREATE VIEW pet_feature_skills AS
SELECT p.pet_id,
       COALESCE(p.feature_skill_id, s.feature_skill_id) AS skill_id,
       CASE WHEN p.feature_skill_id IS NOT NULL THEN 'core'
            WHEN s.feature_skill_id IS NOT NULL THEN 'learnset'
            ELSE 'missing' END AS resolution_source
FROM pets p
LEFT JOIN pet_learnsets l ON l.pet_id = p.pet_id
LEFT JOIN learnsets s ON s.learnset_id = l.learnset_id
WHERE p.status = 'active';

COMMIT;
