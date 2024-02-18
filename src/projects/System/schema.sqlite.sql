
-- Cult Project Schema for SQLite only.
-- Tested on SQLite 3.45.

CREATE TABLE IF NOT EXISTS language (
  lang_id INTEGER NOT NULL CHECK (lang_id > 0) CONSTRAINT lang_pkey PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  title_path TEXT GENERATED ALWAYS AS (CONCAT('$.', name)) STORED NOT NULL,
  title TEXT NOT NULL,
  status INT NOT NULL DEFAULT 0 CHECK (status >= 0 AND status < 16),
  CONSTRAINT lang_name UNIQUE(name),
  CONSTRAINT lang_path UNIQUE(title_path)
) STRICT;

CREATE TABLE IF NOT EXISTS config (
  config_id INTEGER NOT NULL CHECK (config_id > 0) CONSTRAINT config_pkey PRIMARY KEY AUTOINCREMENT,
  class TEXT NOT NULL,
  title BLOB NOT NULL CHECK (JSON_VALID(title, 8)),
  CONSTRAINT config_class UNIQUE(class)
) STRICT;

CREATE TABLE IF NOT EXISTS role (
  role_id INTEGER NOT NULL CHECK (role_id > 0) CONSTRAINT role_pkey PRIMARY KEY AUTOINCREMENT,
  code TEXT NOT NULL,
  title BLOB NOT NULL CHECK (JSON_VALID(title, 8)),
  status INT NOT NULL DEFAULT 0 CHECK (status >= 0 AND status < 16),
  nocache INT NOT NULL DEFAULT 0 CHECK (nocache = 0 OR nocache = 1),
  CONSTRAINT role_code UNIQUE(code)
) STRICT;

CREATE TABLE IF NOT EXISTS component (
  component_id INTEGER NOT NULL CHECK (component_id > 0) CONSTRAINT component_pkey PRIMARY KEY AUTOINCREMENT,
  config_id INT NOT NULL CHECK (config_id > 0),
  role_id INT NOT NULL DEFAULT 0 CHECK (role_id > 0),
  class TEXT NOT NULL,
  title BLOB NOT NULL CHECK (JSON_VALID(title, 8)),
  cache INT NOT NULL DEFAULT 1 CHECK (cache = 1 OR cache = 0),
  singleton INT NOT NULL DEFAULT 1 CHECK (singleton = 1 OR singleton = 0),
  CONSTRAINT component_config UNIQUE(config_id),
  CONSTRAINT component_class UNIQUE(class),
  FOREIGN KEY (config_id) REFERENCES config (config_id),
  FOREIGN KEY (role_id) REFERENCES role (role_id)
) STRICT;

CREATE TABLE IF NOT EXISTS event (
  event_id INTEGER NOT NULL CHECK (event_id > 0) CONSTRAINT event_pkey PRIMARY KEY AUTOINCREMENT,
  component_id INT NOT NULL CHECK (component_id > 0),
  role_id INT NOT NULL DEFAULT 0 CHECK (role_id > 0),
  name TEXT NOT NULL DEFAULT '',
  title BLOB NOT NULL CHECK (JSON_VALID(title, 8)),
  cache INT NOT NULL DEFAULT 0 CHECK (cache = 0 OR cache = 1),
  access INT NOT NULL DEFAULT 0 CHECK (access = 0 OR access = 1),
  nav INT NOT NULL DEFAULT 0 CHECK (nav = 0 OR nav = 1),
  FOREIGN KEY (component_id) REFERENCES component (component_id),
  FOREIGN KEY (role_id) REFERENCES role (role_id)
) STRICT;

CREATE TABLE IF NOT EXISTS project (
  project_id INTEGER NOT NULL CHECK (project_id > 0) CONSTRAINT project_pkey PRIMARY KEY AUTOINCREMENT,
  config_id INT NOT NULL CHECK (config_id > 0),
  code TEXT NOT NULL,
  class TEXT NOT NULL,
  schema TEXT NOT NULL DEFAULT '',
  title BLOB NOT NULL CHECK (JSON_VALID(title, 8)),
  singleton INT NOT NULL DEFAULT 0 CHECK (singleton = 0 OR singleton = 1),
  open INT NOT NULL DEFAULT 0 CHECK (open = 0 OR open = 1),
  CONSTRAINT project_config UNIQUE(config_id),
  CONSTRAINT project_code UNIQUE(code),
  CONSTRAINT project_class UNIQUE(class),
  FOREIGN KEY (config_id) REFERENCES config (config_id)
) STRICT;

CREATE TABLE IF NOT EXISTS build (
  build_id INTEGER NOT NULL CHECK (build_id > 0) CONSTRAINT build_pkey PRIMARY KEY AUTOINCREMENT,
  project_id INT NOT NULL CHECK (project_id > 0),
  code TEXT NOT NULL,
  title BLOB NOT NULL CHECK (JSON_VALID(title, 8)),
  CONSTRAINT build_code UNIQUE(code),
  FOREIGN KEY (project_id) REFERENCES project (project_id)
) STRICT;

CREATE TABLE IF NOT EXISTS decision (
  decision_id INTEGER NOT NULL CHECK (decision_id > 0) CONSTRAINT decision_pkey PRIMARY KEY AUTOINCREMENT,
  project_id INT NOT NULL CHECK (project_id > 0),
  component_id INT NOT NULL CHECK (component_id > 0),
  name TEXT NOT NULL DEFAULT '',
  title BLOB NOT NULL CHECK (JSON_VALID(title, 8)),
  cache INT NOT NULL DEFAULT 1 CHECK (cache = 1 OR cache = 0),
  FOREIGN KEY (project_id) REFERENCES project (project_id),
  FOREIGN KEY (component_id) REFERENCES component (component_id)
) STRICT;

CREATE TABLE IF NOT EXISTS projectmod (
  project_id INT NOT NULL CHECK (project_id > 0),
  decision_id INT NOT NULL CHECK (decision_id > 0),
  CONSTRAINT projectmod_pkey PRIMARY KEY (project_id, decision_id),
  FOREIGN KEY (project_id) REFERENCES project (project_id),
  FOREIGN KEY (decision_id) REFERENCES decision (decision_id)
) STRICT;

CREATE TABLE IF NOT EXISTS locate (
  locate_id INTEGER NOT NULL CHECK (locate_id > 0) CONSTRAINT locate_pkey PRIMARY KEY AUTOINCREMENT,
  decision_id INT NOT NULL CHECK (decision_id > 0),
  build_id INT NOT NULL CHECK (build_id > 0),
  name TEXT NOT NULL DEFAULT '',
  title BLOB NOT NULL CHECK (JSON_VALID(title, 8)),
  serial INT NOT NULL DEFAULT 1,
  cache INT NOT NULL DEFAULT 1 CHECK (cache = 1 OR cache = 0),
  clear TEXT NOT NULL DEFAULT '',
  FOREIGN KEY (decision_id) REFERENCES decision (decision_id),
  FOREIGN KEY (build_id) REFERENCES build (build_id)
) STRICT;

CREATE TABLE IF NOT EXISTS access (
  locate_id INT NOT NULL CHECK (locate_id > 0),
  role_id INT NOT NULL CHECK (role_id > 0),
  CONSTRAINT access_pkey PRIMARY KEY (locate_id, role_id),
  FOREIGN KEY (locate_id) REFERENCES locate (locate_id),
  FOREIGN KEY (role_id) REFERENCES role (role_id)
) STRICT;

CREATE TABLE IF NOT EXISTS plugin (
  plugin_id INTEGER NOT NULL CHECK (plugin_id > 0) CONSTRAINT plugin_pkey PRIMARY KEY AUTOINCREMENT,
  config_id INT NOT NULL CHECK (config_id > 0),
  class TEXT NOT NULL,
  title BLOB NOT NULL CHECK (JSON_VALID(title, 8)),
  status INT NOT NULL DEFAULT 0 CHECK (status >= 0 AND status < 16),
  CONSTRAINT plugin_config UNIQUE(config_id),
  CONSTRAINT plugin_class UNIQUE(class),
  FOREIGN KEY (config_id) REFERENCES config (config_id)
) STRICT;

CREATE TABLE IF NOT EXISTS addon (
  locate_id INT NOT NULL CHECK (locate_id > 0),
  plugin_id INT NOT NULL CHECK (plugin_id > 0),
  serial INT NOT NULL DEFAULT 100 CHECK (serial > 0),
  active INT NOT NULL DEFAULT 1 CHECK (active = 1 OR active = 0),
  CONSTRAINT addon_pkey PRIMARY KEY (locate_id, plugin_id),
  FOREIGN KEY (locate_id) REFERENCES locate (locate_id),
  FOREIGN KEY (plugin_id) REFERENCES plugin (plugin_id)
) STRICT;

CREATE TABLE IF NOT EXISTS attach (
  plugin_id INT NOT NULL CHECK (plugin_id > 0),
  role_id INT NOT NULL CHECK (role_id > 0),
  CONSTRAINT attach_pkey PRIMARY KEY (plugin_id, role_id),
  FOREIGN KEY (plugin_id) REFERENCES plugin (plugin_id),
  FOREIGN KEY (role_id) REFERENCES role (role_id)
) STRICT;

CREATE TABLE IF NOT EXISTS cache (
  locate_id INT NOT NULL CHECK (locate_id > 0),
  event_id INT NOT NULL CHECK (event_id > 0),
  cache INT NOT NULL DEFAULT 1 CHECK (cache = 1 OR cache = 0),
  CONSTRAINT cache_pkey PRIMARY KEY (locate_id, event_id),
  FOREIGN KEY (locate_id) REFERENCES locate (locate_id),
  FOREIGN KEY (event_id) REFERENCES event (event_id)
) STRICT;

CREATE TABLE IF NOT EXISTS cheat (
  cheat_id INTEGER NOT NULL CHECK (cheat_id > 0) CONSTRAINT cheat_pkey PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL DEFAULT '',
  class TEXT NOT NULL DEFAULT '',
  method TEXT NOT NULL DEFAULT '',
  CONSTRAINT cheat_name UNIQUE (name)
) STRICT;

CREATE TABLE IF NOT EXISTS config_type (
  type_id INTEGER NOT NULL CHECK (type_id > 0) CONSTRAINT config_type_pkey PRIMARY KEY AUTOINCREMENT,
  type TEXT NOT NULL DEFAULT '',
  status INT NOT NULL DEFAULT 0 CHECK (status >= 0 AND status < 16)
) STRICT;

CREATE TABLE IF NOT EXISTS config_slice (
  slice_id INTEGER NOT NULL CHECK (slice_id > 0) CONSTRAINT config_slice_pkey PRIMARY KEY AUTOINCREMENT,
  slice TEXT NOT NULL DEFAULT '',
  title BLOB NOT NULL CHECK (JSON_VALID(title, 8)),
  serial INT NOT NULL DEFAULT 1000,
  CONSTRAINT config_slice_slice UNIQUE (slice)
) STRICT;

CREATE TABLE IF NOT EXISTS config_option (
  option_id INTEGER NOT NULL CHECK (option_id > 0) CONSTRAINT config_option_pkey PRIMARY KEY AUTOINCREMENT,
  config_id INT NOT NULL CHECK (config_id > 0),
  slice_id INT NOT NULL CHECK (slice_id > 0),
  type_id INT NOT NULL CHECK (type_id > 0),
  role_id INT NOT NULL DEFAULT 0 CHECK (role_id >= 0),
  title BLOB NOT NULL CHECK (JSON_VALID(title, 8)),
  serial INT NOT NULL DEFAULT 1000,
  global INT NOT NULL DEFAULT 0 CHECK (global = 0 OR global = 1),
  active INT NOT NULL DEFAULT 1 CHECK (active = 1 OR active = 0),
  name TEXT NOT NULL DEFAULT '',
  input TEXT NOT NULL DEFAULT '',
  output TEXT NOT NULL DEFAULT '',
  CONSTRAINT config_option_name UNIQUE (config_id, name),
  FOREIGN KEY (config_id) REFERENCES config (config_id),
  FOREIGN KEY (slice_id) REFERENCES config_slice (slice_id),
  FOREIGN KEY (type_id) REFERENCES config_type (type_id),
  FOREIGN KEY (role_id) REFERENCES role (role_id)
) STRICT;

CREATE TABLE IF NOT EXISTS config_data (
  option_id INT NOT NULL CHECK (option_id > 0),
  locate_id INT NOT NULL CHECK (locate_id > 0),
  value BLOB NOT NULL CHECK (JSON_VALID(value, 8)),
  mlang INT NOT NULL DEFAULT 0 CHECK (mlang = 0 OR mlang = 1),
  local INT NOT NULL DEFAULT 0 CHECK (local = 0 OR local = 1),
  CONSTRAINT config_data_pkey PRIMARY KEY (option_id, locate_id),
  FOREIGN KEY (option_id) REFERENCES config_option (option_id),
  FOREIGN KEY (locate_id) REFERENCES locate (locate_id)
) STRICT;

CREATE TABLE IF NOT EXISTS config_default (
  option_id INT NOT NULL CHECK (option_id > 0),
  "default" BLOB NOT NULL CHECK (JSON_VALID("default", 8)),
  mlang INT NOT NULL DEFAULT 0 CHECK (mlang = 0 OR mlang = 1),
  CONSTRAINT config_default_pkey PRIMARY KEY (option_id),
  FOREIGN KEY (option_id) REFERENCES config_option (option_id)
) STRICT;

CREATE TABLE IF NOT EXISTS config_enum (
  option_id INT NOT NULL CHECK (option_id > 0),
  valuebykey INT NOT NULL DEFAULT 0 CHECK (valuebykey = 0 OR valuebykey = 1),
  variants BLOB NOT NULL CHECK (JSON_VALID(variants, 8)),
  mlang INT NOT NULL DEFAULT 0 CHECK (mlang = 0 OR mlang = 1),
  CONSTRAINT config_enum_pkey PRIMARY KEY (option_id),
  FOREIGN KEY (option_id) REFERENCES config_option (option_id)
) STRICT;

CREATE TABLE IF NOT EXISTS control (
  control_id INTEGER NOT NULL CHECK (control_id > 0) CONSTRAINT control_pkey PRIMARY KEY AUTOINCREMENT,
  config_id INT NOT NULL CHECK (config_id > 0),
  event_id INT NOT NULL CHECK (event_id > 0),
  class TEXT NOT NULL,
  title BLOB NOT NULL CHECK (JSON_VALID(title, 8)),
  self INT NOT NULL DEFAULT 0 CHECK (self = 0 OR self = 1),
  CONSTRAINT control_config UNIQUE (config_id),
  CONSTRAINT control_class UNIQUE (class),
  FOREIGN KEY (config_id) REFERENCES config (config_id),
  FOREIGN KEY (event_id) REFERENCES event (event_id)
) STRICT;

CREATE TABLE IF NOT EXISTS view (
  control_id INT NOT NULL CHECK (control_id > 0),
  target INT NOT NULL CHECK (target > 0),
  locate_id INT NOT NULL CHECK (locate_id > 0),
  serial INT NOT NULL DEFAULT 1,
  CONSTRAINT view_pkey PRIMARY KEY (control_id, target, locate_id),
  FOREIGN KEY (control_id) REFERENCES control (control_id),
  FOREIGN KEY (target) REFERENCES locate (locate_id),
  FOREIGN KEY (locate_id) REFERENCES locate (locate_id)
) STRICT;

CREATE TABLE IF NOT EXISTS delegate (
  delegate_id INTEGER NOT NULL CHECK (delegate_id > 0) CONSTRAINT delegate_pkey PRIMARY KEY AUTOINCREMENT,
  class TEXT NOT NULL,
  title TEXT NOT NULL DEFAULT ''
) STRICT;

CREATE TABLE IF NOT EXISTS [group] (
  group_id INTEGER NOT NULL CHECK (group_id > 0) CONSTRAINT group_pkey PRIMARY KEY AUTOINCREMENT,
  code TEXT NOT NULL,
  title BLOB NOT NULL CHECK (JSON_VALID(title, 8)),
  users_limit INT NOT NULL DEFAULT 0,
  need_email INT NOT NULL DEFAULT 0 CHECK (need_email = 0 OR need_email = 1),
  need_phone INT NOT NULL DEFAULT 0 CHECK (need_phone = 0 OR need_phone = 1),
  status INT NOT NULL DEFAULT 0 CHECK (status >= 0 AND status < 16),
  CONSTRAINT group_code UNIQUE (code)
) STRICT;

CREATE TABLE IF NOT EXISTS icon (
  icon_id INTEGER NOT NULL CHECK (icon_id > 0) CONSTRAINT icon_pkey PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL DEFAULT ''
) STRICT;

CREATE TABLE IF NOT EXISTS markup_class (
  class_id INTEGER NOT NULL CHECK (class_id > 0) CONSTRAINT markup_class_pkey PRIMARY KEY AUTOINCREMENT,
  class TEXT NOT NULL DEFAULT '',
  title BLOB NOT NULL CHECK (JSON_VALID(title, 8)),
  CONSTRAINT markup_class_class UNIQUE (class)
) STRICT;

CREATE TABLE IF NOT EXISTS markup (
  markup_id INTEGER NOT NULL CHECK (markup_id > 0) CONSTRAINT markup_pkey PRIMARY KEY AUTOINCREMENT,
  class_id INT NOT NULL CHECK (class_id > 0),
  markup TEXT NOT NULL DEFAULT '',
  title BLOB NOT NULL CHECK (JSON_VALID(title, 8)),
  FOREIGN KEY (class_id) REFERENCES markup_class (class_id)
) STRICT;

CREATE TABLE IF NOT EXISTS menu (
  menu_id INTEGER NOT NULL CHECK (menu_id > 0) CONSTRAINT menu_pkey PRIMARY KEY AUTOINCREMENT,
  markup_id INT NOT NULL CHECK (markup_id > 0),
  code TEXT NOT NULL,
  title BLOB NOT NULL CHECK (JSON_VALID(title, 8)),
  active INT NOT NULL DEFAULT 1 CHECK (active = 1 OR active = 0),
  status INT NOT NULL DEFAULT 0 CHECK (status >= 0 AND status < 16),
  CONSTRAINT menu_code UNIQUE (code),
  FOREIGN KEY (markup_id) REFERENCES markup (markup_id)
) STRICT;

CREATE TABLE IF NOT EXISTS menu_responsive (
  menu_id INTEGER NOT NULL CHECK (menu_id > 0) CONSTRAINT menu_responsive_pkey PRIMARY KEY AUTOINCREMENT,
  for_id INT NOT NULL CHECK (for_id > 0),
  markup_id INT NOT NULL CHECK (markup_id > 0),
  source TEXT NOT NULL DEFAULT '',
  icon TEXT NOT NULL DEFAULT '',
  side INT NOT NULL DEFAULT 0 CHECK (side = 0 OR side = 1),
  displace INT NOT NULL DEFAULT 1 CHECK (displace = 1 OR displace = 0),
  CONSTRAINT menu_responsive_for UNIQUE (for_id),
  CONSTRAINT menu_responsive_source UNIQUE (source),
  FOREIGN KEY (for_id) REFERENCES markup (markup_id),
  FOREIGN KEY (markup_id) REFERENCES markup (markup_id)
) STRICT;

CREATE TABLE IF NOT EXISTS reference (
  reference_id INTEGER NOT NULL CHECK (reference_id > 0) CONSTRAINT reference_pkey PRIMARY KEY AUTOINCREMENT,
  locate_id INT NOT NULL CHECK (locate_id > 0),
  event_id INT CHECK (event_id > 0) DEFAULT NULL,
  code TEXT NOT NULL,
  value TEXT NOT NULL DEFAULT '',
  url TEXT NOT NULL DEFAULT '',
  "text" BLOB NOT NULL CHECK (JSON_VALID("text", 8)),
  active BLOB NOT NULL CHECK (JSON_VALID(active, 8)),
  title BLOB NOT NULL CHECK (JSON_VALID(title, 8)),
  status INT NOT NULL DEFAULT 0 CHECK (status >= 0 AND status < 16),
  CONSTRAINT reference_code UNIQUE (code),
  FOREIGN KEY (locate_id) REFERENCES locate (locate_id),
  FOREIGN KEY (event_id) REFERENCES event (event_id)
) STRICT;

CREATE TABLE IF NOT EXISTS menuitem (
  item_id INTEGER NOT NULL CHECK (item_id > 0) CONSTRAINT mainmenu_pkey PRIMARY KEY AUTOINCREMENT,
  menu_id INT NOT NULL CHECK (menu_id > 0),
  submenu_id INT DEFAULT NULL CHECK (submenu_id > 0),
  reference_id INT NOT NULL CHECK (reference_id > 0),
  role_id INT DEFAULT NULL CHECK (role_id > 0),
  serial INT NOT NULL DEFAULT 1,
  active INT NOT NULL DEFAULT 1 CHECK (active = 1 OR active = 0),
  icon TEXT NOT NULL DEFAULT '',
  empty INT NOT NULL DEFAULT 0 CHECK (empty = 0 OR empty = 1),
  follow INT NOT NULL DEFAULT 0 CHECK (follow = 0 OR follow = 1),
  blank INT NOT NULL DEFAULT 0 CHECK (blank = 0 OR blank = 1),
  status INT NOT NULL DEFAULT 0 CHECK (status >= 0 AND status < 16),
  FOREIGN KEY (menu_id) REFERENCES menu (menu_id),
  FOREIGN KEY (submenu_id) REFERENCES menu (menu_id),
  FOREIGN KEY (reference_id) REFERENCES reference (reference_id),
  FOREIGN KEY (role_id) REFERENCES role (role_id)
) STRICT;

CREATE TABLE IF NOT EXISTS navigate (
  locate_id INT NOT NULL CHECK (locate_id > 0),
  menu_id INT NOT NULL CHECK (menu_id >0),
  CONSTRAINT navigate_pkey PRIMARY KEY (locate_id, menu_id),
  FOREIGN KEY (locate_id) REFERENCES locate (locate_id),
  FOREIGN KEY (menu_id) REFERENCES menu (menu_id)
) STRICT;

CREATE TABLE IF NOT EXISTS permit (
  group_id INT NOT NULL CHECK (group_id > 0),
  role_id INT NOT NULL CHECK (role_id > 0),
  CONSTRAINT permit_pkey PRIMARY KEY (group_id, role_id),
  FOREIGN KEY (group_id) REFERENCES [group] (group_id),
  FOREIGN KEY (role_id) REFERENCES role (role_id)
) STRICT;

CREATE TABLE IF NOT EXISTS privilege (
  privilege_id INTEGER NOT NULL CHECK (privilege_id > 0) CONSTRAINT privilege_pkey PRIMARY KEY AUTOINCREMENT,
  locate_id INT NOT NULL CHECK (locate_id > 0),
  event_id INT NOT NULL CHECK (event_id > 0),
  CONSTRAINT privilege_locate_event UNIQUE (locate_id, event_id),
  FOREIGN KEY (locate_id) REFERENCES locate (locate_id),
  FOREIGN KEY (event_id) REFERENCES event (event_id)
) STRICT;

CREATE TABLE IF NOT EXISTS rule (
  role_id INT NOT NULL CHECK (role_id > 0),
  privilege_id INT NOT NULL CHECK (privilege_id > 0),
  CONSTRAINT rule_pkey PRIMARY KEY (role_id, privilege_id),
  FOREIGN KEY (role_id) REFERENCES role (role_id),
  FOREIGN KEY (privilege_id) REFERENCES privilege (privilege_id)
) STRICT;

CREATE TABLE IF NOT EXISTS site_template (
  template_id INTEGER NOT NULL CHECK (template_id > 0) CONSTRAINT site_template_pkey PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL DEFAULT '',
  status INT NOT NULL DEFAULT 0 CHECK (status >= 0 AND status < 16),
  CONSTRAINT site_template_name UNIQUE (name)
) STRICT;

CREATE TABLE IF NOT EXISTS temp (
  temp_id TEXT NOT NULL,
  temp_data TEXT NOT NULL,
  temp_ts TEXT NOT NULL DEFAULT(datetime()),
  CONSTRAINT temp_key UNIQUE (temp_id)
) STRICT;

CREATE TABLE IF NOT EXISTS user (
  user_id INTEGER NOT NULL CHECK (user_id > 0) CONSTRAINT user_pkey PRIMARY KEY AUTOINCREMENT,
  parent_id INT DEFAULT NULL CHECK (parent_id > 0),
  login TEXT NOT NULL DEFAULT '',
  oauth TEXT NOT NULL DEFAULT '',
  team TEXT NOT NULL DEFAULT '',
  password TEXT NOT NULL DEFAULT '',
  email TEXT NOT NULL DEFAULT '',
  phone TEXT NOT NULL DEFAULT '',
  name TEXT NOT NULL DEFAULT '',
  photo TEXT NOT NULL DEFAULT '',
  "create" TEXT NOT NULL DEFAULT(datetime()),
  status INT NOT NULL DEFAULT 0 CHECK (status >= 0 AND status < 16),
  CONSTRAINT user_login UNIQUE (login),
  CONSTRAINT user_email UNIQUE (email),
  FOREIGN KEY (parent_id) REFERENCES user (user_id)
) STRICT;

CREATE TABLE IF NOT EXISTS team (
  user_id INT NOT NULL CHECK (user_id > 0),
  group_id INT NOT NULL CHECK (group_id > 0),
  CONSTRAINT team_pkey PRIMARY KEY (user_id, group_id),
  FOREIGN KEY (user_id) REFERENCES user (user_id),
  FOREIGN KEY (group_id) REFERENCES [group] (group_id)
) STRICT;

CREATE TABLE IF NOT EXISTS user_auth (
  user_id INT NOT NULL CHECK (user_id > 0),
  hash TEXT NOT NULL DEFAULT '',
  auth TEXT NOT NULL,
  CONSTRAINT user_auth_pkey PRIMARY KEY (user_id, hash),
  FOREIGN KEY (user_id) REFERENCES user (user_id)
) STRICT;

CREATE TABLE IF NOT EXISTS user_oauth (
  profile_id INTEGER NOT NULL CHECK (user_id > 0) CONSTRAINT user_oauth_pkey PRIMARY KEY AUTOINCREMENT,
  user_id INT NOT NULL CHECK (user_id > 0),
  network TEXT NOT NULL DEFAULT '',
  uid TEXT NOT NULL DEFAULT '',
  nickname TEXT NOT NULL DEFAULT '',
  email TEXT NOT NULL DEFAULT '',
  verified_email INT NOT NULL DEFAULT 0 CHECK (verified_email >= -1 AND verified_email <= 1),
  first_name TEXT NOT NULL DEFAULT '',
  last_name TEXT NOT NULL DEFAULT '',
  bdate TEXT NOT NULL DEFAULT '0001-01-01',
  sex INT NOT NULL DEFAULT 0 CHECK (sex >= 0 AND sex <= 2),
  phone TEXT NOT NULL DEFAULT '',
  identity TEXT NOT NULL DEFAULT '',
  profile TEXT NOT NULL DEFAULT '',
  photo TEXT NOT NULL DEFAULT '',
  photo_big TEXT NOT NULL DEFAULT '',
  city TEXT NOT NULL DEFAULT '',
  country TEXT NOT NULL DEFAULT '',
  CONSTRAINT user_oauth_uid_net UNIQUE (uid, network),
  FOREIGN KEY (user_id) REFERENCES user (user_id)
) STRICT;

CREATE TABLE IF NOT EXISTS user_phone (
  user_id INT NOT NULL CHECK (user_id > 0),
  phone TEXT NOT NULL DEFAULT '',
  CONSTRAINT user_phone_pkey PRIMARY KEY (user_id),
  FOREIGN KEY (user_id) REFERENCES user (user_id)
) STRICT;


CREATE VIEW IF NOT EXISTS additions AS SELECT
addon.plugin_id                  AS plugin_id,
"group".group_id                 AS group_id,
"group".title->>lng.title_path   AS "group",
"group".users_limit              AS group_limit,
"group".status                   AS group_status,
role.role_id                     AS role_id,
role.title->>lng.title_path      AS role,
role.status                      AS role_status,
addon.locate_id                  AS locate_id,
build.build_id                   AS build_id,
locate.title->>lng.title_path    AS locate,
decision.title->>lng.title_path  AS decision,
build.title->>lng.title_path     AS build,
plugin.config_id                 AS config_id,
p_cfg.class                      AS config_class,
plugin.class                     AS class,
plugin.title->>lng.title_path    AS title,
addon.active                     AS active,
plugin.status                    AS status,
component.title->>lng.title_path AS component,
component.class                  AS component_class,
config.class                     AS config,
lng.lang_id                      AS lang_id,
lng.name                         AS lang,
lng.title                        AS language
FROM addon
JOIN language lng      ON lng.status            = 0
LEFT JOIN plugin       ON addon.plugin_id       = plugin.plugin_id
LEFT JOIN attach       ON plugin.plugin_id      = attach.plugin_id
LEFT JOIN role         ON attach.role_id        = role.role_id
LEFT JOIN permit       ON role.role_id          = permit.role_id
LEFT JOIN "group"      ON permit.group_id       = "group".group_id
LEFT JOIN locate       ON addon.locate_id       = locate.locate_id
LEFT JOIN build        ON locate.build_id       = build.build_id
LEFT JOIN decision     ON locate.decision_id    = decision.decision_id
LEFT JOIN project      ON decision.project_id   = project.project_id
LEFT JOIN component    ON decision.component_id = component.component_id
LEFT JOIN config       ON component.config_id   = config.config_id
LEFT JOIN config p_cfg ON plugin.config_id      = p_cfg.config_id;


CREATE VIEW IF NOT EXISTS application AS SELECT
build.build_id                 AS build_id,
project.project_id             AS project_id,
project.config_id              AS config_id,
build.title->>lng.title_path   AS title,
project.class                  AS class,
config.class                   AS config,
project.title->>lng.title_path AS project,
project.singleton              AS singleton,
lng.lang_id                    AS lang_id,
lng.name                       AS lang,
lng.title                      AS language
FROM build
JOIN language lng ON lng.status        = 0
LEFT JOIN project ON build.project_id  = project.project_id
LEFT JOIN config  ON project.config_id = config.config_id;


CREATE VIEW IF NOT EXISTS attachables AS SELECT
attach.plugin_id                 AS plugin_id,
"group".group_id                 AS group_id,
"group".title->>lng.title_path   AS "group",
"group".users_limit              AS group_limit,
"group".status                   AS group_status,
role.role_id                     AS role_id,
role.title->>lng.title_path      AS role,
role.status                      AS role_status,
addon.locate_id                  AS locate_id,
build.build_id                   AS build_id,
locate.title->>lng.title_path    AS locate,
decision.title->>lng.title_path  AS decision,
build.title->>lng.title_path     AS build,
plugin.config_id                 AS config_id,
"p_cfg".class                    AS config_class,
plugin.class                     AS class,
plugin.title->>lng.title_path    AS title,
addon.active                     AS active,
plugin.status                    AS status,
component.title->>lng.title_path AS component,
component.class                  AS component_class,
config.class                     AS config,
lng.lang_id                      AS lang_id,
lng.name                         AS lang,
lng.title                        AS language
FROM attach
JOIN language lng      ON lng.status            = 0
LEFT JOIN plugin       ON attach.plugin_id      = plugin.plugin_id
LEFT JOIN role         ON attach.role_id        = role.role_id
LEFT JOIN permit       ON role.role_id          = permit.role_id
LEFT JOIN "group"      ON permit.group_id       = "group".group_id
LEFT JOIN addon        ON plugin.plugin_id      = addon.plugin_id
LEFT JOIN locate       ON addon.locate_id       = locate.locate_id
LEFT JOIN build        ON locate.build_id       = build.build_id
LEFT JOIN decision     ON locate.decision_id    = decision.decision_id
LEFT JOIN project      ON decision.project_id   = project.project_id
LEFT JOIN component    ON decision.component_id = component.component_id
LEFT JOIN config       ON component.config_id   = config.config_id
LEFT JOIN config p_cfg ON plugin.config_id      = p_cfg.config_id;


CREATE VIEW IF NOT EXISTS caches AS SELECT DISTINCT
cache.event_id               AS event_id,
cache.locate_id              AS locate_id,
CASE
  WHEN component.cache = 0 THEN 0
  WHEN "c".cache       = 0 THEN 0
  WHEN decision.cache  = 0 THEN 0
  WHEN locate.cache    = 0 THEN 0
  ELSE cache.cache
END                          AS cache,
CASE
  WHEN component.cache = 0 THEN 0
  WHEN	"c".cache      = 0 THEN 0
  WHEN	decision.cache = 0 THEN 0
  WHEN	locate.cache   = 0 THEN 0
  ELSE	event.cache
END                          AS cachable,
config.class                 AS config,
event.name                   AS name,
event.title->>lng.title_path AS title,
event.access                 AS access,
lng.lang_id                  AS lang_id,
lng.name                     AS lang,
lng.title                    AS language
FROM cache
JOIN language lng     ON lng.status            = 0
LEFT JOIN event       ON cache.event_id        = event.event_id
LEFT JOIN component c ON event.component_id    = c.component_id
LEFT JOIN config      ON c.config_id           = config.config_id
LEFT JOIN locate      ON cache.locate_id       = locate.locate_id
LEFT JOIN decision    ON locate.decision_id    = decision.decision_id
LEFT JOIN component   ON decision.component_id = component.component_id;


CREATE VIEW IF NOT EXISTS components AS SELECT DISTINCT
component.component_id           AS component_id,
component.config_id              AS config_id,
component.title->>lng.title_path AS title,
component.role_id                AS role_id,
role.title->>lng.title_path      AS role,
component.class                  AS class,
component.cache                  AS cache,
config.class                     AS config,
config.title->>lng.title_path    AS config_title,
component.singleton              AS singleton,
CASE
  WHEN decision.decision_id IS NULL THEN 1
  WHEN component.singleton = 1 THEN 0
  ELSE 1
END                              AS is_free,
decision.decision_id
  IS NOT NULL                    AS is_decision,
lng.lang_id                      AS lang_id,
lng.name                         AS lang,
lng.title                        AS language
FROM component
JOIN language lng  ON lng.status             = 0
LEFT JOIN config   ON component.config_id    = config.config_id
LEFT JOIN decision ON component.component_id = decision.component_id
LEFT JOIN role     ON component.role_id      = role.role_id;


CREATE VIEW IF NOT EXISTS configs AS SELECT
config.config_id              AS config_id,
config.class                  AS class,
config.title->>lng.title_path AS title,
lng.lang_id                   AS lang_id,
lng.name                      AS lang,
lng.title                     AS language
FROM config
JOIN language lng ON lng.status = 0;


CREATE VIEW IF NOT EXISTS config_options AS SELECT
config_option.option_id  AS option_id,
config_data.locate_id    AS locate_id,
config_option.config_id  AS config_id,
config.class             AS config,
config.title->>lng.title_path              AS config_title,
config_option.slice_id   AS slice_id,
config_slice.slice       AS slice,
config_slice.title->>lng.title_path        AS slice_title,
config_option.type_id    AS type_id,
config_type.type         AS type,
config_option.role_id    AS role_id,
config_option.serial     AS serial_number,
config_option.global     AS global,
config_option.active     AS active,
config_option.name       AS name,
config_option.input      AS input,
config_option.output     AS output,
config_option.title->>lng.title_path       AS title,
config_slice.serial      AS serial,
config_default."default"->>lng.title_path  AS "default",
config_data.value->>lng.title_path         AS value,
config_data.local        AS local,
config_enum.variants->>lng.title_path      AS variants,
config_enum.valuebykey   AS valuebykey,
lng.lang_id                   AS lang_id,
lng.name                      AS lang,
lng.title                     AS language
FROM config_option
JOIN language lng        ON lng.status              = 0
LEFT JOIN config         ON config_option.config_id = config.config_id
LEFT JOIN config_type    ON config_option.type_id   = config_type.type_id
LEFT JOIN config_slice   ON config_option.slice_id  = config_slice.slice_id
LEFT JOIN config_enum    ON config_option.option_id = config_enum.option_id
LEFT JOIN config_default ON config_option.option_id = config_default.option_id
LEFT JOIN config_data    ON config_option.option_id = config_data.option_id;

/*
CREATE VIEW IF NOT EXISTS config_keys AS SELECT
config_option.option_id  AS option_id,
config_option.config_id  AS config_id,
config_option_ml.lang_id AS lang_id,
config_option.slice_id   AS slice_id,
config_option.type_id    AS type_id,
config_option.role_id    AS role_id,
config_option.serial     AS serial_number,
config_option.global     AS global,
config_option.active     AS active,
config_option.name       AS name,
config_option.input      AS input,
config_option.output     AS output
FROM config_option
LEFT JOIN config_option_ml ON config_option.option_id  = config_option_ml.option_id;
*/

CREATE VIEW IF NOT EXISTS config_kits AS SELECT
config_option.option_id AS option_id,
config_option.config_id AS config_id,
config_data.locate_id   AS locate_id,
language.lang_id        AS lang_id,
language.name           AS lang,
config_option.type_id   AS type_id,
config_option.serial    AS serial_number,
config.class            AS config,
config_option.name      AS name,
config_option.input     AS input,
config_option.output    AS output,
config_data.value->>lng.title_path
                        AS value,
config_enum.valuebykey  AS valuebykey,
config_option.global    AS global,
config_option.active    AS active
FROM config_option
JOIN language         ON language.status         = 0
LEFT JOIN config      ON config_option.config_id = config.config_id
LEFT JOIN config_type ON config_option.type_id   = config_type.type_id
LEFT JOIN config_data ON config_option.option_id = config_data.option_id
LEFT JOIN config_enum ON config_option.option_id = config_enum.option_id;


CREATE VIEW IF NOT EXISTS controls AS SELECT
control.control_id     AS control_id,
component.component_id AS component_id,
control.config_id      AS config_id,
control.event_id       AS event_id,
locate.locate_id       AS locate_id,
language.lang_id       AS lang_id,
locate.title->>lng.title_path
                       AS locate,
language.name          AS lang,
language.title         AS language,
decision.name          AS name,
decision.title->>lng.title_path
                       AS decision,
project.project_id     AS project_id,
project.class          AS project_class,
project.title->>lng.title_path
                       AS project,
control.class          AS class,
"cc".class             AS control,
control.self           AS self,
component.class        AS component,
config.class           AS config,
event.name             AS event,
event.access           AS access,
control.title->>lng.title_path
                       AS title
FROM control
JOIN language          ON language.status        = 0
LEFT JOIN config AS cc ON control.config_id      = cc.config_id
LEFT JOIN event        ON control.event_id       = event.event_id
LEFT JOIN component    ON event.component_id     = component.component_id
LEFT JOIN config       ON component.config_id    = config.config_id
LEFT JOIN decision     ON component.component_id = decision.component_id
LEFT JOIN locate       ON decision.decision_id   = locate.decision_id
LEFT JOIN project      ON decision.project_id    = project.project_id;


CREATE VIEW IF NOT EXISTS decisions AS SELECT
decision.decision_id  AS decision_id,
decision.project_id   AS project_id,
decision.component_id AS component_id,
decision.name         AS name,
decision.title->>lng.title_path
                      AS title,
CASE component.cache
  WHEN 1 THEN decision.cache
  ELSE 0
END                   AS cache,
language.lang_id      AS lang_id,
language.name         AS lang,
language.title        AS language
FROM decision
JOIN language       ON language.status       = 0
LEFT JOIN component ON decision.component_id = component.component_id;


CREATE VIEW IF NOT EXISTS events AS SELECT
event.event_id     AS event_id,
event.name         AS name,
event.title->>lng.title_path
                   AS title,
event.component_id AS component_id,
event.role_id      AS role_id,
role.title->>lng.title_path
                   AS role,
CASE component.cache
  WHEN 1 THEN event.cache
  ELSE 0
END                AS cache,
event.access       AS access,
event.nav          AS nav,
language.lang_id   AS lang_id,
language.name      AS lang,
language.title     AS language,
component.title->>lng.title_path
                   AS component,
component.class    AS class,
config.class       AS config
FROM event
JOIN language       ON language.status     = 0
LEFT JOIN role      ON event.role_id       = role.role_id
LEFT JOIN component ON event.component_id  = component.component_id
LEFT JOIN config    ON component.config_id = config.config_id;


CREATE VIEW IF NOT EXISTS groups AS SELECT
"group".group_id    AS group_id,
"group".code        AS code,
"group".title->>lng.title_path
                    AS "group",
"group".users_limit AS users_limit,
"group".need_email  AS need_email,
"group".need_phone  AS need_phone,
"group".status      AS group_status,
language.lang_id    AS lang_id,
language.name       AS lang,
language.title      AS language,
user.user_id        AS user_id,
user.login          AS login,
user.email          AS email,
user.status         AS user_status,
role.role_id        AS role_id,
role.title->>lng.title_path
                    AS role,
role.status         AS role_status
FROM "group"
JOIN language    ON language.status  = 0
LEFT JOIN team   ON "group".group_id = team.group_id
RIGHT JOIN user  ON team.user_id     = user.user_id
LEFT JOIN permit ON "group".group_id = permit.group_id
LEFT JOIN role   ON permit.role_id   = role.role_id;


CREATE VIEW IF NOT EXISTS items AS SELECT DISTINCT
menuitem.item_id      AS item_id,
reference.locate_id   AS locate_id,
CASE
  WHEN reference.locate_id > 0 THEN "group".group_id
  ELSE 0
END                   AS group_id,
CASE
  WHEN reference.locate_id > 0 THEN "group".status
  ELSE 0
END                   AS group_status,
CASE
  WHEN reference.locate_id > 0 THEN role.status
  ELSE 0
END                   AS role_status,
menuitem.menu_id      AS menu_id,
menuitem.role_id      AS role_id,
menu.title            AS menu_title,
role.title            AS role,
menu.active           AS menu_active,
menu.status           AS menu_status,
markup.markup_id      AS markup_id,
markup.markup         AS markup,
markup_class.class_id AS markup_class_id,
markup_class.class    AS markup_class,
menuitem.submenu_id   AS submenu_id,
submenu.title         AS submenu_title,
submenu.active        AS submenu_active,
submenu.status        AS submenu_status,
submarkup.markup_id   AS submarkup_id,
submarkup.markup      AS submarkup,
sub_mc.class_id       AS submarkup_class_id,
sub_mc.class          AS submarkup_class,
menuitem.reference_id AS reference_id,
menuitem.serial       AS serial,
menuitem.icon         AS icon,
reference.url         AS url,
reference.text        AS text,
reference.active      AS active,
reference.status + menuitem.status
                      AS status,
CASE menu.active
	WHEN 1 THEN menuitem.active
	ELSE 0
END                   AS item,
locate.decision_id    AS decision_id,
locate.serial         AS locate_serial,
decision.component_id AS component_id,
locate.build_id       AS build_id,
build.project_id      AS project_id,
decision.name         AS name,
locate.name           AS locate,
decision.title        AS title,
component.class       AS class,
config.class          AS config,
project.class         AS class_project,
component.title       AS component,
build.title           AS build,
project.title         AS project
FROM menuitem
LEFT JOIN menu                ON menuitem.menu_id      = menu.menu_id
LEFT JOIN markup              ON menu.markup_id        = markup.markup_id
LEFT JOIN markup_class        ON markup.class_id       = markup_class.class_id
LEFT JOIN menu submenu        ON menuitem.submenu_id   = submenu.menu_id
LEFT JOIN markup submarkup    ON submenu.markup_id     = submarkup.markup_id
LEFT JOIN markup_class sub_mc ON submarkup.class_id    = sub_mc.class_id
LEFT JOIN reference           ON menuitem.reference_id = reference.reference_id
LEFT JOIN event               ON reference.event_id    = event.event_id
LEFT JOIN locate              ON reference.locate_id   = locate.locate_id
LEFT JOIN decision            ON locate.decision_id    = decision.decision_id
LEFT JOIN component           ON decision.component_id = component.component_id
LEFT JOIN config              ON component.config_id   = config.config_id
LEFT JOIN build               ON locate.build_id       = build.build_id
LEFT JOIN project             ON build.project_id      = project.project_id
LEFT JOIN access              ON locate.locate_id      = access.locate_id
LEFT JOIN role                ON role.role_id          = access.role_id
LEFT JOIN permit              ON permit.role_id        = role.role_id
LEFT JOIN "group"             ON "group".group_id      = permit.group_id;


CREATE VIEW IF NOT EXISTS locs AS SELECT
locate.locate_id      AS locate_id,
locate.decision_id    AS decision_id,
locate.serial         AS serial,
decision.component_id AS component_id,
component.role_id     AS role_id,
locate.build_id       AS build_id,
build.project_id      AS project_id,
config.config_id      AS config_id,
CASE locate.name
	WHEN '' THEN CONCAT(decision.name, locate.locate_id)
  ELSE locate.name
END                   AS name,
locate.title->>lng.title_path
                      AS title,
decision.title->>lng.title_path
                      AS decision,
component.class       AS class,
CASE
	WHEN component.cache = 1 AND decision.cache = 1 THEN locate.cache
	ELSE 0
END                   AS cache,
CASE component.cache
	WHEN 1 THEN decision.cache
	ELSE 0
END                   AS cachable,
config.class          AS config,
project.class         AS class_project,
component.title->>lng.title_path
                      AS component,
build.title->>lng.title_path
                      AS build,
project.title->>lng.title_path
                      AS project,
component.singleton   AS singleton,
language.lang_id      AS lang_id,
language.name         AS lang,
language.title        AS language
FROM locate
JOIN language       ON language.status       = 0
LEFT JOIN decision  ON locate.decision_id    = decision.decision_id
LEFT JOIN component ON decision.component_id = component.component_id
LEFT JOIN config    ON component.config_id   = config.config_id
LEFT JOIN build     ON locate.build_id       = build.build_id
LEFT JOIN project   ON build.project_id      = project.project_id;


CREATE VIEW IF NOT EXISTS map AS SELECT
user.user_id         AS user_id,
user.login           AS login,
"group".group_id     AS group_id,
"group".title        AS "group",
"group".users_limit  AS group_limit,
"group".status       AS group_status,
role.role_id         AS role_id,
role.title           AS role,
role.status          AS role_status,
locate.locate_id     AS locate_id,
locate.build_id      AS build_id,
locate.serial        AS serial,
locate.title         AS locate,
decision.title       AS decision,
build.title          AS build,
decision.decision_id AS decision_id,
decision.project_id  AS project_id,
decision.name        AS decision_name,
project.class        AS project_class,
project.title        AS project,
project.singleton    AS project_singleton,
component.class      AS component_class,
component.title      AS component_title,
config.class         AS config,
component.singleton  AS component_singleton
FROM access
LEFT JOIN role       ON role.role_id          = access.role_id
LEFT JOIN permit     ON permit.role_id        = role.role_id
LEFT JOIN "group"    ON "group".group_id      = permit.group_id
LEFT JOIN team       ON "group".group_id      = team.group_id
RIGHT JOIN user      ON team.user_id          = user.user_id
LEFT JOIN locate     ON access.locate_id      = locate.locate_id
LEFT JOIN build      ON locate.build_id       = build.build_id
LEFT JOIN decision   ON locate.decision_id    = decision.decision_id
LEFT JOIN project    ON decision.project_id   = project.project_id
LEFT JOIN component  ON decision.component_id = component.component_id
LEFT JOIN config     ON component.config_id   = config.config_id;


CREATE VIEW IF NOT EXISTS markups AS SELECT
markup.markup_id      AS id,
markup.markup_id      AS markup_id,
markup.markup         AS markup,
markup_class.class_id AS class_id,
markup_class.class    AS class
FROM markup
LEFT JOIN markup_class ON markup.class_id = markup_class.class_id;


CREATE VIEW IF NOT EXISTS matrix AS SELECT
user.user_id           AS user_id,
user.login             AS login,
"group".group_id       AS group_id,
"group".title          AS "group",
"group".users_limit    AS group_limit,
"group".status         AS group_status,
privilege.privilege_id AS privilege_id,
privilege.locate_id    AS locate_id,
build.build_id         AS build_id,
locate.title           AS locate,
decision.title         AS decision,
build.title            AS build,
project.title          AS project,
event.event_id         AS event_id,
event.name             AS event,
event.title            AS title,
event.access           AS access,
event.nav              AS nav,
role.role_id           AS role_id,
role.title             AS role,
role.status            AS role_status,
component.title        AS component,
component.class        AS class,
config.class           AS config
FROM rule
LEFT JOIN role      ON rule.role_id          = role.role_id
LEFT JOIN permit    ON role.role_id          = permit.role_id
LEFT JOIN "group"   ON permit.group_id       = "group".group_id
LEFT JOIN team      ON "group".group_id      = team.group_id
RIGHT JOIN user     ON team.user_id          = user.user_id
LEFT JOIN privilege ON rule.privilege_id     = privilege.privilege_id
LEFT JOIN event     ON privilege.event_id    = event.event_id
LEFT JOIN locate    ON privilege.locate_id   = locate.locate_id
LEFT JOIN build     ON locate.build_id       = build.build_id
LEFT JOIN decision  ON locate.decision_id    = decision.decision_id
LEFT JOIN project   ON decision.project_id   = project.project_id
LEFT JOIN component ON decision.component_id = component.component_id
LEFT JOIN config    ON component.config_id   = config.config_id;


CREATE VIEW IF NOT EXISTS menus AS SELECT
menu.menu_id           AS id,
menu.menu_id           AS menu_id,
menu.title->>lng.title_path
                       AS title,
menu.active            AS active,
menu.status            AS status,
language.lang_id       AS lang_id,
language.name          AS lang,
language.title         AS language,
markup.markup_id       AS markup_id,
markup.markup          AS markup,
markup_class.class_id  AS class_id,
markup_class.class     AS class
FROM menu
JOIN language          ON language.status = 0
LEFT JOIN markup       ON menu.markup_id  = markup.markup_id
LEFT JOIN markup_class ON markup.class_id = markup_class.class_id;


CREATE VIEW IF NOT EXISTS menu_responsives AS SELECT
menu_responsive.menu_id   AS menu_id,
menu_responsive.for_id    AS for_id,
menu_responsive.markup_id AS markup_id,
"menu".markup             AS menu,
markup.markup             AS markup,
menu_responsive.source    AS source,
menu_responsive.icon      AS icon,
CASE menu_responsive.side
  WHEN 0 THEN 'left'
  ELSE 'right'
END                       AS side,
menu_responsive.displace  AS displace
FROM menu_responsive
LEFT JOIN markup menu ON menu_responsive.for_id    = menu.markup_id
LEFT JOIN markup      ON menu_responsive.markup_id = markup.markup_id;


CREATE VIEW IF NOT EXISTS modifies AS SELECT DISTINCT
modify.project_id      AS modify_id,
modify.class           AS class,
modify.title           AS title,
modify.singleton       AS singleton,
build.build_id         AS build_id,
build.title            AS build,
decision.decision_id   AS decision_id,
decision.project_id    AS project_id,
decision.name          AS name,
decision.title         AS decision,
project.class          AS project_class,
project.title          AS project,
project.singleton      AS project_singleton,
component.component_id AS component_id,
component.class        AS component_class,
component.title        AS component_title,
config.class           AS config,
component.singleton    AS component_singleton,
CASE locate.locate_id
	WHEN NULL THEN 0
	ELSE locate.locate_id
END                    AS locate_id,
locate.locate_id
  IS NOT NULL          AS "exists",
locate.locate_id
  IS NULL              AS not_exists
FROM projectmod
LEFT JOIN project modify ON projectmod.project_id  = modify.project_id
LEFT JOIN build          ON modify.project_id      = build.project_id
LEFT JOIN decision       ON projectmod.decision_id = decision.decision_id
LEFT JOIN component      ON decision.component_id  = component.component_id
LEFT JOIN config         ON component.config_id    = config.config_id
LEFT JOIN locate         ON decision.decision_id   = locate.decision_id
LEFT JOIN project        ON decision.project_id    = project.project_id;


CREATE VIEW IF NOT EXISTS mods AS SELECT DISTINCT
component.component_id AS component_id,
component.class        AS class,
component.cache        AS cache,
config.class           AS config,
language.lang_id       AS lang_id,
language.name          AS lang,
language.title         AS language,
component.title->>lng.title_path
                       AS title,
component.singleton    AS singleton,
CASE
	WHEN decision.decision_id IS NULL THEN 1
	WHEN component.singleton THEN 0
	ELSE 1
END                    AS is_free,
decision.decision_id
  IS NOT NULL          AS is_decision
FROM component
JOIN language      ON language.status        = 0
LEFT JOIN config   ON component.config_id    = config.config_id
LEFT JOIN decision ON component.component_id = decision.component_id;


CREATE VIEW IF NOT EXISTS navs AS SELECT
navigate.locate_id    AS locate_id,
locate.title          AS locate,
navigate.menu_id      AS menu_id,
markup.markup         AS markup,
menu.active           AS active,
menu.title            AS menu,
menu.status           AS status,
locate.decision_id    AS decision_id,
decision.component_id AS component_id,
locate.build_id       AS build_id,
build.project_id      AS project_id,
decision.name         AS name,
decision.title        AS decision,
component.class       AS class,
config.class          AS config,
project.class         AS class_project,
component.title       AS component,
build.title           AS build,
project.title         AS project
FROM navigate
LEFT JOIN menu      ON navigate.menu_id      = menu.menu_id
LEFT JOIN markup    ON menu.markup_id        = markup.markup_id
LEFT JOIN locate    ON navigate.locate_id    = locate.locate_id
LEFT JOIN decision  ON locate.decision_id    = decision.decision_id
LEFT JOIN component ON decision.component_id = component.component_id
LEFT JOIN config    ON component.config_id   = config.config_id
LEFT JOIN build     ON locate.build_id       = build.build_id
LEFT JOIN project   ON build.project_id      = project.project_id;


CREATE VIEW IF NOT EXISTS perms AS SELECT
role.role_id        AS role_id,
role.title->>lng.title_path
                    AS role,
role.status         AS role_status,
role.nocache        AS nocache,
"group".group_id    AS group_id,
"group".title->>lng.title_path
                    AS "group",
"group".users_limit AS group_limit,
"group".status      AS group_status,
user.user_id        AS user_id,
user.login          AS login,
language.lang_id    AS lang_id,
language.name       AS lang,
language.title      AS language
FROM permit
JOIN language     ON language.status  = 0
LEFT JOIN role    ON permit.role_id   = role.role_id
LEFT JOIN "group" ON permit.group_id  = "group".group_id
LEFT JOIN team    ON "group".group_id = team.group_id
RIGHT JOIN user   ON team.user_id     = user.user_id;


CREATE VIEW IF NOT EXISTS plugins AS SELECT
plugin.plugin_id AS id,
plugin.plugin_id AS plugin_id,
plugin.config_id AS config_id,
plugin.title->>lng.title_path
                 AS title,
config.class     AS config,
plugin.class     AS class,
plugin.status    AS status,
language.lang_id AS lang_id,
language.name    AS lang,
language.title   AS language
FROM plugin
JOIN language    ON language.status  = 0
LEFT JOIN config ON plugin.config_id = config.config_id;


CREATE VIEW IF NOT EXISTS privileges AS SELECT
privilege.privilege_id     AS privilege_id,
privilege.event_id         AS event_id,
privilege.locate_id        AS locate_id,
event.name                 AS name,
event.title                AS event,
event.access               AS access,
event.component_id         AS event_component_id,
e_com.title                AS event_component,
e_com.class                AS event_component_class,
e_cfg.class                AS event_component_config,
locate.decision_id         AS decision_id,
locate.serial              AS serial,
l_com.component_id         AS component_id,
locate.build_id            AS build_id,
build.project_id           AS project_id,
decision.name              AS decision_name,
decision.title             AS decision,
locate.title               AS title,
l_com.class                AS class,
l_cfg.class                AS config,
project.class              AS class_project,
l_com.title                AS component,
build.title                AS build,
project.title              AS project,
l_com.singleton            AS singleton
FROM privilege
LEFT JOIN event           ON privilege.event_id    = event.event_id
LEFT JOIN component e_com ON event.component_id    = e_com.component_id
LEFT JOIN config e_cfg    ON e_com.config_id       = e_cfg.config_id
LEFT JOIN locate          ON privilege.locate_id   = locate.locate_id
LEFT JOIN decision        ON locate.decision_id    = decision.decision_id
LEFT JOIN component l_com ON decision.component_id = l_com.component_id
LEFT JOIN config l_cfg    ON l_com.config_id       = l_cfg.config_id
LEFT JOIN build           ON locate.build_id       = build.build_id
LEFT JOIN project         ON build.project_id      = project.project_id;


CREATE VIEW IF NOT EXISTS projects AS SELECT DISTINCT
project.project_id         AS project_id,
project.config_id          AS config_id,
project.code               AS code,
project.class              AS class,
config.class               AS config,
project.title->>lng.title_path
                           AS title,
project.singleton          AS singleton,
project.open               AS open,
build.build_id IS NOT NULL AS is_build,
project.open AND (
  project.singleton OR build.build_id IS NULL
)                          AS is_free,
language.lang_id           AS lang_id,
language.name              AS lang,
language.title             AS language
FROM project
JOIN language    ON language.status    = 0
LEFT JOIN config ON project.config_id  = config.config_id
LEFT JOIN build  ON project.project_id = build.project_id;


CREATE VIEW IF NOT EXISTS "references" AS SELECT
reference.reference_id AS reference_id,
CASE
  WHEN reference.event_id IS NULL THEN 0
  ELSE reference.event_id
END                    AS event_id,
reference.url          AS url,
reference.text->>lng.title_path
                       AS text,
reference.active->>lng.title_path
                       AS active,
reference.title->>lng.title_path
                       AS title,
reference.status       AS status,
locate.locate_id       AS locate_id,
locate.decision_id     AS decision_id,
locate.serial          AS serial,
decision.component_id  AS component_id,
locate.build_id        AS build_id,
build.project_id       AS project_id,
decision.name          AS name,
decision.title->>lng.title_path
                       AS decision,
locate.title->>lng.title_path
                       AS locate,
component.class        AS class,
config.class           AS config,
project.class          AS class_project,
component.title->>lng.title_path
                       AS component,
build.title->>lng.title_path
                       AS build,
project.title->>lng.title_path
                       AS project,
language.lang_id       AS lang_id,
language.name          AS lang,
language.title         AS language
FROM reference
JOIN language       ON language.status       = 0
LEFT JOIN locate    ON reference.locate_id   = locate.locate_id
LEFT JOIN decision  ON locate.decision_id    = decision.decision_id
LEFT JOIN component ON decision.component_id = component.component_id
LEFT JOIN config    ON component.config_id   = config.config_id
LEFT JOIN build     ON locate.build_id       = build.build_id
LEFT JOIN project   ON build.project_id      = project.project_id;


CREATE VIEW IF NOT EXISTS roles AS SELECT
role.role_id     AS role_id,
role.code        AS code,
role.title->>lng.title_path
                 AS title,
role.nocache     AS nocache,
role.status      AS status,
language.lang_id AS lang_id,
language.name    AS lang,
language.title   AS language
FROM role
JOIN language ON language.status = 0;


CREATE VIEW IF NOT EXISTS sample AS SELECT
decision.decision_id   AS decision_id,
decision.project_id    AS project_id,
decision.name          AS name,
decision.title->>lng.title_path
                       AS title,
project.class          AS project_class,
project.title->>lng.title_path
                       AS project,
project.singleton      AS project_singleton,
component.component_id AS component_id,
component.class        AS component_class,
component.title->>lng.title_path
                       AS component_title,
config.class           AS config,
config.title->>lng.title_path
                       AS config_title,
component.singleton    AS component_singleton,
CASE locate.locate_id
  WHEN NULL THEN 0
	ELSE locate.locate_id
END                    AS locate_id,
locate.locate_id
  IS NOT NULL          AS "exists",
locate.locate_id
  IS NULL              AS not_exists,
language.lang_id       AS lang_id,
language.name          AS lang,
language.title         AS language
FROM decision
JOIN language       ON language.status       = 0
LEFT JOIN project   ON decision.project_id   = project.project_id
LEFT JOIN component ON decision.component_id = component.component_id
LEFT JOIN config    ON component.config_id   = config.config_id
LEFT JOIN locate    ON decision.decision_id  = locate.decision_id;


CREATE VIEW IF NOT EXISTS schema AS SELECT
locate.locate_id       AS locate_id,
locate.build_id        AS build_id,
locate.serial          AS serial,
build.title->>lng.title_path
                       AS build,
decision.decision_id   AS decision_id,
decision.project_id    AS project_id,
decision.name          AS name,
decision.title->>lng.title_path
                       AS title,
project.class          AS project_class,
project.title->>lng.title_path
                       AS project,
project.singleton      AS project_singleton,
component.component_id AS component_id,
component.class        AS component_class,
component.title->>lng.title_path
                       AS component_title,
config.class           AS config,
config.title->>lng.title_path
                       AS config_title,
component.singleton    AS component_singleton,
language.lang_id       AS lang_id,
language.name          AS lang,
language.title         AS language
FROM locate
JOIN language       ON language.status       = 0
LEFT JOIN build     ON locate.build_id       = build.build_id
LEFT JOIN decision  ON locate.decision_id    = decision.decision_id
LEFT JOIN project   ON decision.project_id   = project.project_id
LEFT JOIN component ON decision.component_id = component.component_id
LEFT JOIN config    ON component.config_id   = config.config_id;


CREATE VIEW IF NOT EXISTS teams AS SELECT
user.user_id        AS user_id,
user.login          AS login,
"group".group_id    AS group_id,
"group".title->>lng.title_path
                    AS "group",
"group".users_limit AS group_limit,
"group".status      AS group_status,
role.role_id        AS role_id,
role.title->>lng.title_path
                    AS role,
role.status         AS role_status
FROM team
JOIN language     ON language.status  = 0
LEFT JOIN "group" ON team.group_id    = "group".group_id
LEFT JOIN permit  ON "group".group_id = permit.group_id
LEFT JOIN role    ON permit.role_id   = role.role_id
LEFT JOIN user    ON team.user_id     = user.user_id;


CREATE VIEW IF NOT EXISTS users AS SELECT
user.user_id        AS user_id,
user.login          AS login,
user.email          AS email,
user.phone          AS phone,
user.photo          AS photo,
user.status         AS user_status,
"group".group_id    AS group_id,
"group".title->>lng.title_path
                    AS "group",
"group".users_limit AS users_limit,
"group".status      AS group_status,
role.role_id        AS role_id,
role.title->>lng.title_path
                    AS role,
role.status         AS role_status
FROM user
JOIN language      ON language.status  = 0
LEFT JOIN team     ON user.user_id     = team.user_id
LEFT JOIN "group"  ON team.group_id    = "group".group_id
LEFT JOIN permit   ON "group".group_id = permit.group_id
LEFT JOIN role     ON permit.role_id   = role.role_id;


CREATE VIEW IF NOT EXISTS views AS SELECT
view.control_id          AS control_id,
view.target              AS target,
view.locate_id           AS source,
source.title             AS locate,
src_dec.title            AS dec_title,
src_build.title          AS build,
src_dec.name             AS src_name,
src_dec.title            AS src_dec,
src_pro.title            AS src_project,
"group".group_id         AS group_id,
"group".status           AS group_status,
role.status              AS role_status,
control.event_id         AS event_id,
target.build_id          AS build_id,
target.title             AS target_title,
decision.title           AS destination,
control.class            AS class,
event.name               AS event,
event.access             AS access,
control.title            AS title,
decision.name            AS name,
decision.title           AS decision,
project.project_id       AS project_id,
project.class            AS project_class,
project.title            AS project
FROM view
LEFT JOIN control          ON view.control_id     = control.control_id
LEFT JOIN event            ON control.event_id    = event.event_id
LEFT JOIN locate source    ON view.locate_id      = source.locate_id
LEFT JOIN build src_build  ON source.build_id     = src_build.build_id
LEFT JOIN decision src_dec ON source.decision_id  = src_dec.decision_id
LEFT JOIN project src_pro  ON src_dec.project_id  = src_pro.project_id
LEFT JOIN locate target    ON view.target         = target.locate_id
LEFT JOIN build            ON target.build_id     = build.build_id
LEFT JOIN decision         ON target.decision_id  = decision.decision_id
LEFT JOIN project          ON decision.project_id = project.project_id
LEFT JOIN access           ON view.target         = access.locate_id
LEFT JOIN role             ON access.role_id      = role.role_id
LEFT JOIN permit           ON role.role_id        = permit.role_id
LEFT JOIN "group"          ON permit.group_id     = "group".group_id;


CREATE VIEW IF NOT EXISTS rbac_map AS SELECT
locate.locate_id AS locate_id,
CASE locate.name
  WHEN '' THEN CONCAT(decision.name, locate.locate_id)
	ELSE locate.name
END              AS name,
locate.serial    AS serial,
"group".group_id AS group_id,
role.role_id     AS role_id,
"group".status   AS group_status,
role.status      AS role_status
FROM access
LEFT JOIN role     ON access.role_id     = role.role_id
LEFT JOIN permit   ON role.role_id       = permit.role_id
LEFT JOIN "group"  ON permit.group_id    = "group".group_id
LEFT JOIN locate   ON access.locate_id   = locate.locate_id
LEFT JOIN decision ON locate.decision_id = decision.decision_id;


CREATE VIEW IF NOT EXISTS rbac_maps AS SELECT
locate.locate_id       AS locate_id,
component.component_id AS component_id,
locate.serial          AS serial,
"group".group_id       AS group_id,
role.role_id           AS role_id,
"group".status         AS group_status,
role.status            AS role_status
FROM access
LEFT JOIN role      ON access.role_id        = role.role_id
LEFT JOIN permit    ON role.role_id          = permit.role_id
LEFT JOIN "group"   ON permit.group_id       = "group".group_id
LEFT JOIN locate    ON access.locate_id      = locate.locate_id
LEFT JOIN decision  ON locate.decision_id    = decision.decision_id
LEFT JOIN component ON decision.component_id = component.component_id;


CREATE VIEW IF NOT EXISTS rbac_schema AS SELECT
locate.locate_id       AS locate_id,
locate.build_id        AS build_id,
locate.serial          AS serial,
CASE
  WHEN component.cache = 1 AND decision.cache = 1 THEN locate.cache
	ELSE 0
END                    AS cache,
decision.decision_id   AS decision_id,
decision.project_id    AS project_id,
locate.name            AS name,
project.class          AS project_class,
project.config_id      AS project_config_id,
"c1".class             AS project_config,
component.component_id AS component_id,
component.class        AS component_class,
component.config_id    AS config_id,
"c2".class             AS config
FROM locate
LEFT JOIN decision     ON locate.decision_id    = decision.decision_id
LEFT JOIN project      ON decision.project_id   = project.project_id
LEFT JOIN config AS c1 ON project.config_id     = c1.config_id
LEFT JOIN component    ON decision.component_id = component.component_id
LEFT JOIN config AS c2 ON component.config_id   = c2.config_id
LEFT JOIN build        ON locate.build_id       = build.build_id;


CREATE VIEW IF NOT EXISTS rbac_matrix AS SELECT
privilege.locate_id    AS locate_id,
locate.name            AS name,
component.component_id AS component_id,
event.event_id         AS event_id,
event.name             AS event,
config.class           AS config,
event.access           AS access,
"group".group_id       AS group_id,
role.role_id           AS role_id,
"group".status         AS group_status,
role.status            AS role_status
FROM rule
LEFT JOIN role      ON rule.role_id        = role.role_id
LEFT JOIN permit    ON role.role_id        = permit.role_id
LEFT JOIN "group"   ON permit.group_id     = "group".group_id
LEFT JOIN privilege ON rule.privilege_id   = privilege.privilege_id
LEFT JOIN event     ON privilege.event_id  = event.event_id
LEFT JOIN component ON event.component_id  = component.component_id
LEFT JOIN config    ON component.config_id = config.config_id
LEFT JOIN locate    ON privilege.locate_id = locate.locate_id;


CREATE VIEW IF NOT EXISTS rbac_views   AS SELECT
view.control_id       AS control_id,
control.config_id     AS config_id,
decision.component_id AS component_id,
view.target           AS target,
locate.name           AS name,
view.locate_id        AS source,
"group".group_id      AS group_id,
role.role_id          AS role_id,
control.class         AS class,
config.class          AS config,
control.self          AS self,
event.name            AS event,
event.access          AS access,
"group".status        AS group_status,
role.status           AS role_status,
view.serial           AS serial
FROM view
LEFT JOIN control   ON view.control_id    = control.control_id
LEFT JOIN config    ON control.config_id  = config.config_id
LEFT JOIN event     ON control.event_id   = event.event_id
LEFT JOIN access    ON view.target        = access.locate_id
LEFT JOIN role      ON access.role_id     = role.role_id
LEFT JOIN permit    ON role.role_id       = permit.role_id
LEFT JOIN "group"   ON permit.group_id    = "group".group_id
LEFT JOIN locate    ON view.target        = locate.locate_id
LEFT JOIN decision  ON locate.decision_id = decision.decision_id;


CREATE VIEW IF NOT EXISTS rbac_additions AS SELECT
addon.locate_id   AS locate_id,
plugin.plugin_id  AS plugin_id,
plugin.config_id  AS config_id,
"group".group_id  AS group_id,
role.role_id      AS role_id,
"group".status    AS group_status,
role.status       AS role_status,
config.class      AS config,
plugin.class      AS class,
addon.active      AS active,
addon.serial      AS serial		
FROM addon
LEFT JOIN plugin   ON addon.plugin_id  = plugin.plugin_id
LEFT JOIN attach   ON plugin.plugin_id = attach.plugin_id
LEFT JOIN role     ON attach.role_id   = role.role_id
LEFT JOIN permit   ON role.role_id     = permit.role_id
LEFT JOIN "group"  ON permit.group_id  = "group".group_id
LEFT JOIN config   ON plugin.config_id = config.config_id;


CREATE VIEW IF NOT EXISTS rbac_locs AS SELECT
locate.locate_id       AS locate_id,
component.component_id AS component_id,
component.role_id      AS role_id,
locate.decision_id     AS decision_id,
locate.build_id        AS build_id,
build.project_id       AS project_id,
locate.serial          AS serial,
decision.name          AS decision,
config.config_id       AS config_id,		
CASE locate.name
  WHEN '' THEN CONCAT(decision.name, locate.locate_id)
  ELSE locate.name
END                    AS name,
config.class           AS config,		
CASE
  WHEN component.cache = 1 AND decision.cache = 1 THEN locate.cache
  ELSE 0
END                    AS cache,
component.singleton    AS singleton
FROM locate
LEFT JOIN decision  ON locate.decision_id    = decision.decision_id
LEFT JOIN component ON decision.component_id = component.component_id
LEFT JOIN config    ON component.config_id   = config.config_id
LEFT JOIN build     ON locate.build_id       = build.build_id;


CREATE VIEW IF NOT EXISTS rbac_events AS SELECT
locate.locate_id       AS locate_id,
component.component_id AS component_id,
event.event_id         AS event_id,
event.name             AS event,
event.title->>lng.title_path
                       AS title,
event.access           AS access,
event.cache            AS cache,
event.nav              AS nav,
language.lang_id       AS lang_id,
language.name          AS lang,
language.title         AS language
FROM locate
JOIN language       ON language.status        = 0
LEFT JOIN decision  ON locate.decision_id     = decision.decision_id
LEFT JOIN component ON decision.component_id  = component.component_id
RIGHT JOIN event    ON component.component_id = event.component_id;


CREATE VIEW IF NOT EXISTS rbac_navs AS SELECT
navigate.locate_id AS locate_id,
navigate.menu_id   AS menu_id,
markup.markup      AS markup
FROM navigate
LEFT JOIN menu   ON navigate.menu_id = menu.menu_id
LEFT JOIN markup ON menu.markup_id   = markup.markup_id;


CREATE VIEW IF NOT EXISTS rbac_items AS SELECT DISTINCT
menuitem.item_id    AS item_id,
reference.locate_id AS locate_id,
reference.event_id  AS event_id,
CASE
  WHEN reference.locate_id = 0 OR reference.locate_id IS NULL THEN 0
	ELSE "group".group_id
END                 AS group_id,
CASE
	WHEN reference.locate_id = 0 OR reference.locate_id IS NULL THEN 0
	ELSE "group".status
END                 AS group_status,
CASE
	WHEN reference.locate_id = 0 OR reference.locate_id IS NULL THEN 0
	ELSE role.status
END                 AS role_status,
menuitem.menu_id    AS menu_id,
CASE
  WHEN menuitem.role_id IS NULL THEN 0
  ELSE menuitem.role_id
END                 AS role_id,
CASE
  WHEN menuitem.submenu_id IS NULL THEN 0
  ELSE menuitem.submenu_id
END                 AS submenu_id,
menuitem.serial     AS serial,
menuitem.icon       AS icon,
menuitem.empty      AS empty,
menuitem.follow     AS follow,
menuitem.blank      AS blank,
reference.url       AS url,
project.class       AS project,
locate.name         AS locate,
event.name          AS event,
reference.value     AS value,
reference.text      AS text,
reference.active    AS active,
reference.title     AS reference,
event.title         AS event_title,
locate.title        AS locate_title,
reference.status + menuitem.status
                    AS status,
CASE menu.active
  WHEN 1 THEN menuitem.active
	ELSE 0
END                 AS item
FROM menuitem
LEFT JOIN reference ON menuitem.reference_id = reference.reference_id
LEFT JOIN event     ON reference.event_id    = event.event_id
LEFT JOIN locate    ON reference.locate_id   = locate.locate_id
LEFT JOIN build     ON locate.build_id       = build.build_id
LEFT JOIN project   ON build.project_id      = project.project_id
LEFT JOIN access    ON locate.locate_id      = access.locate_id
LEFT JOIN role      ON role.role_id          = access.role_id
LEFT JOIN permit    ON permit.role_id        = role.role_id
LEFT JOIN "group"   ON "group".group_id      = permit.group_id
LEFT JOIN menu      ON menuitem.menu_id      = menu.menu_id;


CREATE VIEW IF NOT EXISTS rbac_modifies AS SELECT DISTINCT
build.build_id AS build_id,
CASE locate.locate_id
  WHEN NULL THEN 0
	ELSE locate.locate_id
END            AS locate_id
FROM projectmod
LEFT JOIN project modify ON projectmod.project_id  = modify.project_id
LEFT JOIN build          ON modify.project_id      = build.project_id
LEFT JOIN decision       ON projectmod.decision_id = decision.decision_id
LEFT JOIN locate         ON decision.decision_id   = locate.decision_id;
