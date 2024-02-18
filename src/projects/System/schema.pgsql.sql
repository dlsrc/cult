
-- Cult Project Schema for PostgreSQL Server only.
-- Tested on PostgreSQL 16.2.

CREATE SCHEMA IF NOT EXISTS cult_system AUTHORIZATION CURRENT_USER;

CREATE TABLE IF NOT EXISTS cult_system.language (
  lang_id SMALLSERIAL NOT NULL CHECK (lang_id > 0),
  name char(2) NOT NULL,
  title varchar(63) NOT NULL DEFAULT '',
  status smallint NOT NULL DEFAULT 0 CHECK (status < 16 AND status >= 0),
  CONSTRAINT lang_pkey PRIMARY KEY(lang_id),
  CONSTRAINT lang_name UNIQUE(name)
);

CREATE TABLE IF NOT EXISTS cult_system.config (
  config_id SMALLSERIAL NOT NULL CHECK (config_id > 0),
  class varchar(127) NOT NULL,
  title jsonb NOT NULL,
  CONSTRAINT config_pkey PRIMARY KEY(config_id),
  CONSTRAINT config_class UNIQUE(class)
);

CREATE TABLE IF NOT EXISTS cult_system.role (
  role_id SMALLSERIAL NOT NULL CHECK (role_id > 0),
  code char(3) NOT NULL,             -- Трехбуквенный код роли
  title jsonb NOT NULL,
  status smallint NOT NULL DEFAULT 0 CHECK (status < 16 AND status >= 0),
  nocache boolean NOT NULL DEFAULT FALSE,
  CONSTRAINT role_pkey PRIMARY KEY(role_id),
  CONSTRAINT role_code UNIQUE(code)
);

CREATE TABLE IF NOT EXISTS cult_system.component (
  component_id SMALLSERIAL NOT NULL CHECK (component_id > 0),  -- Идентификатор компонента
  config_id smallint NOT NULL CHECK (config_id > 0),           -- Идентификатор класса конфигурации
  role_id smallint NOT NULL DEFAULT 0 CHECK (role_id > 0),     -- Идентификатор роли поумолчанию назначаемой при имплементации компонента
  class varchar(127) NOT NULL,                                 -- Класс компонента
  title jsonb NOT NULL,
  cache boolean NOT NULL DEFAULT TRUE,
  singleton boolean NOT NULL DEFAULT TRUE,
  CONSTRAINT component_pkey PRIMARY KEY(component_id),
  CONSTRAINT component_config UNIQUE(config_id),
  CONSTRAINT component_class UNIQUE(class),
  FOREIGN KEY (config_id) REFERENCES cult_system.config (config_id),
  FOREIGN KEY (role_id) REFERENCES cult_system.role (role_id)
);

CREATE INDEX IF NOT EXISTS component_role_id ON cult_system.component(role_id);

CREATE TABLE IF NOT EXISTS cult_system.event (
  event_id SERIAL NOT NULL CHECK (event_id > 0),           -- Идентификатор события или группы событий с требованием доступа
  component_id smallint NOT NULL CHECK (component_id > 0), -- Идентификатор компонента
  role_id smallint NOT NULL DEFAULT 0 CHECK (role_id > 0), -- Идентификатор роли поумолчанию назначаемой при имплементации компонента
  name varchar(127) NOT NULL DEFAULT '',                  -- Имя события
  title jsonb NOT NULL,
  cache boolean NOT NULL DEFAULT FALSE,
  access boolean NOT NULL DEFAULT FALSE,
  nav boolean NOT NULL DEFAULT FALSE,
  CONSTRAINT event_pkey PRIMARY KEY(event_id),
  FOREIGN KEY (component_id) REFERENCES cult_system.component (component_id),
  FOREIGN KEY (role_id) REFERENCES cult_system.role (role_id)
);

CREATE INDEX IF NOT EXISTS event_component_id ON cult_system.event(component_id);
CREATE INDEX IF NOT EXISTS event_role_id ON cult_system.event(role_id);

CREATE TABLE IF NOT EXISTS cult_system.project (
  project_id SMALLSERIAL NOT NULL CHECK (project_id > 0), -- Идентификатор проект (шаблона) приложения
  config_id smallint NOT NULL CHECK (config_id > 0),      -- Идентификатор класса конфигурации
  code char(3) NOT NULL,                                 -- Трехбуквенный код шаблона приложения
  class varchar(127) NOT NULL,                           -- Класс проект (шаблона) приложения
  schema varchar(127) NOT NULL DEFAULT '',
  title jsonb NOT NULL,
  singleton boolean NOT NULL DEFAULT FALSE,              -- Признак шаблона одиночки
  open boolean NOT NULL DEFAULT FALSE,                   -- Открыт для создания приложений
  CONSTRAINT project_pkey PRIMARY KEY(project_id),
  CONSTRAINT project_config UNIQUE(config_id),
  CONSTRAINT project_code UNIQUE(code),
  CONSTRAINT project_class UNIQUE(class),
  FOREIGN KEY (config_id) REFERENCES cult_system.config (config_id)
);

CREATE TABLE IF NOT EXISTS cult_system.build (
  build_id SMALLSERIAL NOT NULL CHECK (build_id > 0),  -- Идентификатор приложения
  project_id smallint NOT NULL CHECK (project_id > 0), -- Идентификатор проекта (шаблона) приложения
  code char(3) NOT NULL,                              -- Трехбуквенный уникальный код приложения'
  title jsonb NOT NULL,
  CONSTRAINT build_pkey PRIMARY KEY(build_id),
  CONSTRAINT build_code UNIQUE(code),
  FOREIGN KEY (project_id) REFERENCES cult_system.project (project_id)
);

CREATE INDEX IF NOT EXISTS build_project_id ON cult_system.build(project_id);

CREATE TABLE IF NOT EXISTS cult_system.decision (
  decision_id SMALLSERIAL NOT NULL CHECK (decision_id > 0), -- Индекс паттерна локации, позиция модуля в шаблоне
  project_id smallint NOT NULL CHECK (project_id > 0),      -- Идентификатор проекта (шаблона) приложения
  component_id smallint NOT NULL CHECK (component_id > 0),  -- Идентификатор шаблона локации, индекс компонента
  name varchar(31) NOT NULL DEFAULT '',
  title jsonb NOT NULL,
  cache boolean NOT NULL DEFAULT TRUE,
  CONSTRAINT decision_pkey PRIMARY KEY(decision_id),
  FOREIGN KEY (project_id) REFERENCES cult_system.project (project_id),
  FOREIGN KEY (component_id) REFERENCES cult_system.component (component_id)
);

CREATE INDEX IF NOT EXISTS decision_project_id ON cult_system.decision(project_id);
CREATE INDEX IF NOT EXISTS decision_component_id ON cult_system.decision(component_id);

CREATE TABLE IF NOT EXISTS cult_system.projectmod (
  project_id smallint NOT NULL CHECK (project_id > 0),
  decision_id smallint NOT NULL CHECK (decision_id > 0),
  CONSTRAINT projectmod_pkey PRIMARY KEY (project_id, decision_id),
  FOREIGN KEY (project_id) REFERENCES cult_system.project (project_id),
  FOREIGN KEY (decision_id) REFERENCES cult_system.decision (decision_id)
);

CREATE TABLE IF NOT EXISTS cult_system.locate (
  locate_id SMALLSERIAL NOT NULL CHECK (locate_id > 0),  -- Идентификатор локации
  decision_id smallint NOT NULL CHECK (decision_id > 0), -- Идентификатор проектного решения
  build_id smallint NOT NULL CHECK (build_id > 0),       -- Идентификатор приложения
  name varchar(31) NOT NULL DEFAULT '',
  title jsonb NOT NULL,
  serial smallint NOT NULL DEFAULT 1,                   -- Статус локации
  cache boolean NOT NULL DEFAULT TRUE,
  clear varchar(127) NOT NULL DEFAULT '',
  CONSTRAINT locate_pkey PRIMARY KEY(locate_id),
  FOREIGN KEY (decision_id) REFERENCES cult_system.decision (decision_id),
  FOREIGN KEY (build_id) REFERENCES cult_system.build (build_id)
);

CREATE INDEX IF NOT EXISTS locate_decision_id ON cult_system.locate(decision_id);
CREATE INDEX IF NOT EXISTS locate_build_id ON cult_system.locate(build_id);

CREATE TABLE IF NOT EXISTS cult_system.access (
  locate_id smallint NOT NULL CHECK (locate_id > 0),
  role_id smallint NOT NULL CHECK (role_id > 0),
  CONSTRAINT access_pkey PRIMARY KEY (locate_id, role_id),
  FOREIGN KEY (locate_id) REFERENCES cult_system.locate (locate_id),
  FOREIGN KEY (role_id) REFERENCES cult_system.role (role_id)
);

CREATE TABLE IF NOT EXISTS cult_system.plugin (
  plugin_id SMALLSERIAL NOT NULL CHECK (plugin_id > 0),
  config_id smallint NOT NULL CHECK (config_id > 0),          -- Идентификатор класса конфигурации
  class varchar(127) NOT NULL,
  title jsonb NOT NULL,
  status smallint NOT NULL DEFAULT 0 CHECK (status < 16 AND status >= 0),
  CONSTRAINT plugin_pkey PRIMARY KEY(plugin_id),
  CONSTRAINT plugin_config UNIQUE(config_id),
  CONSTRAINT plugin_class UNIQUE(class),
  FOREIGN KEY (config_id) REFERENCES cult_system.config (config_id)
);

CREATE TABLE IF NOT EXISTS cult_system.addon (
  locate_id smallint NOT NULL CHECK (locate_id > 0),
  plugin_id smallint NOT NULL CHECK (plugin_id > 0),
  serial smallint NOT NULL DEFAULT 100 CHECK (serial > 0),
  active boolean NOT NULL DEFAULT TRUE,
  CONSTRAINT addon_pkey PRIMARY KEY (locate_id, plugin_id),
  FOREIGN KEY (locate_id) REFERENCES cult_system.locate (locate_id),
  FOREIGN KEY (plugin_id) REFERENCES cult_system.plugin (plugin_id)
);

CREATE TABLE IF NOT EXISTS cult_system.attach (
  plugin_id smallint NOT NULL CHECK (plugin_id > 0), -- Идентификатор плагина
  role_id smallint NOT NULL CHECK (role_id > 0),     -- Идентификатор роли
  CONSTRAINT attach_pkey PRIMARY KEY (plugin_id, role_id),
  FOREIGN KEY (plugin_id) REFERENCES cult_system.plugin (plugin_id),
  FOREIGN KEY (role_id) REFERENCES cult_system.role (role_id)
);

CREATE TABLE IF NOT EXISTS cult_system.cache (
  locate_id smallint NOT NULL CHECK (locate_id > 0),
  event_id integer NOT NULL CHECK (event_id > 0),
  cache boolean NOT NULL DEFAULT TRUE,
  CONSTRAINT cache_pkey PRIMARY KEY (locate_id, event_id),
  FOREIGN KEY (locate_id) REFERENCES cult_system.locate (locate_id),
  FOREIGN KEY (event_id) REFERENCES cult_system.event (event_id)
);

CREATE TABLE IF NOT EXISTS cult_system.cheat (
  cheat_id SMALLSERIAL NOT NULL CHECK (cheat_id > 0),
  name varchar(31) NOT NULL DEFAULT '',
  class varchar(127) NOT NULL DEFAULT '',
  method varchar(63) NOT NULL DEFAULT '',
  CONSTRAINT cheat_pkey PRIMARY KEY (cheat_id),
  CONSTRAINT cheat_name UNIQUE (name)
);

CREATE TABLE IF NOT EXISTS cult_system.config_type (
  type_id SMALLSERIAL NOT NULL CHECK (type_id > 0),
  type varchar(31) NOT NULL DEFAULT '',
  status smallint NOT NULL DEFAULT 0 CHECK (status < 16 AND status >= 0),
  CONSTRAINT config_type_pkey PRIMARY KEY (type_id)
);

CREATE TABLE IF NOT EXISTS cult_system.config_slice (
  slice_id SMALLSERIAL NOT NULL CHECK (slice_id > 0),
  slice varchar(63) NOT NULL DEFAULT '',
  title jsonb NOT NULL,
  serial smallint NOT NULL DEFAULT 1000,
  CONSTRAINT config_slice_pkey PRIMARY KEY (slice_id),
  CONSTRAINT config_slice_slice UNIQUE (slice)
);

CREATE TABLE IF NOT EXISTS cult_system.config_option (
  option_id SMALLSERIAL NOT NULL CHECK (option_id > 0),
  config_id smallint NOT NULL CHECK (config_id > 0),
  slice_id smallint NOT NULL CHECK (slice_id > 0),
  type_id smallint NOT NULL CHECK (type_id > 0),
  role_id smallint NOT NULL DEFAULT 0 CHECK (role_id >= 0),
  title jsonb NOT NULL,
  serial smallint NOT NULL DEFAULT 1000,
  global boolean NOT NULL DEFAULT FALSE,
  active boolean NOT NULL DEFAULT TRUE,
  name varchar(63) NOT NULL DEFAULT '',
  input varchar(63) NOT NULL DEFAULT '',
  output varchar(63) NOT NULL DEFAULT '',
  CONSTRAINT config_option_pkey PRIMARY KEY (option_id),
  CONSTRAINT config_option_name UNIQUE (config_id, name),
  FOREIGN KEY (config_id) REFERENCES cult_system.config (config_id),
  FOREIGN KEY (slice_id) REFERENCES cult_system.config_slice (slice_id),
  FOREIGN KEY (type_id) REFERENCES cult_system.config_type (type_id),
  FOREIGN KEY (role_id) REFERENCES cult_system.role (role_id)
);

CREATE TABLE IF NOT EXISTS cult_system.config_data (
  option_id smallint NOT NULL CHECK (option_id > 0),
  locate_id smallint NOT NULL CHECK (locate_id > 0),
  value jsonb NOT NULL,
  mlang boolean NOT NULL DEFAULT FALSE,
  local boolean NOT NULL DEFAULT FALSE,
  CONSTRAINT config_data_pkey PRIMARY KEY (option_id, locate_id),
  FOREIGN KEY (option_id) REFERENCES cult_system.config_option (option_id),
  FOREIGN KEY (locate_id) REFERENCES cult_system.locate (locate_id)
);

CREATE TABLE IF NOT EXISTS cult_system.config_default (
  option_id smallint NOT NULL CHECK (option_id > 0),
  "default" jsonb NOT NULL,
  mlang boolean NOT NULL DEFAULT FALSE,
  CONSTRAINT config_default_pkey PRIMARY KEY (option_id),
  FOREIGN KEY (option_id) REFERENCES cult_system.config_option (option_id)
);

CREATE TABLE IF NOT EXISTS cult_system.config_enum (
  option_id smallint NOT NULL CHECK (option_id > 0),
  valuebykey boolean NOT NULL DEFAULT FALSE,
  variants jsonb NOT NULL,
  mlang boolean NOT NULL DEFAULT FALSE,
  CONSTRAINT config_enum_pkey PRIMARY KEY (option_id),
  FOREIGN KEY (option_id) REFERENCES cult_system.config_option (option_id)
);

CREATE TABLE IF NOT EXISTS cult_system.control (
  control_id SMALLSERIAL NOT NULL CHECK (control_id > 0),
  config_id smallint NOT NULL CHECK (config_id > 0),      -- Идентификатор класса конфигурации
  event_id integer NOT NULL CHECK (event_id > 0),        -- Идентификатор активного события элемента управления
  class varchar(63) NOT NULL,
  title jsonb NOT NULL,
  self boolean NOT NULL DEFAULT FALSE,
  CONSTRAINT control_pkey PRIMARY KEY (control_id),
  CONSTRAINT control_config UNIQUE (config_id),
  CONSTRAINT control_class UNIQUE (class),
  FOREIGN KEY (config_id) REFERENCES cult_system.config (config_id),
  FOREIGN KEY (event_id) REFERENCES cult_system.event (event_id)
);

CREATE TABLE IF NOT EXISTS cult_system.view (
  control_id smallint NOT NULL CHECK (control_id > 0),
  target smallint NOT NULL CHECK (target > 0),
  locate_id smallint NOT NULL CHECK (locate_id > 0),
  serial smallint NOT NULL DEFAULT 1,
  CONSTRAINT view_pkey PRIMARY KEY (control_id, target, locate_id),
  FOREIGN KEY (control_id) REFERENCES cult_system.control (control_id),
  FOREIGN KEY (target) REFERENCES cult_system.locate (locate_id),
  FOREIGN KEY (locate_id) REFERENCES cult_system.locate (locate_id)
);

CREATE TABLE IF NOT EXISTS cult_system.delegate (
  delegate_id SMALLSERIAL NOT NULL CHECK (delegate_id > 0),
  class varchar(63) NOT NULL,
  title varchar(255) NOT NULL DEFAULT '',
  CONSTRAINT delegate_pkey PRIMARY KEY (delegate_id)
);

CREATE TABLE IF NOT EXISTS cult_system.group (
  group_id SMALLSERIAL NOT NULL CHECK (group_id > 0), -- Идентификатор группы
  code char(3) NOT NULL,                             -- Трехбуквенный код группы
  title jsonb NOT NULL,
  users_limit smallint NOT NULL DEFAULT 0,           -- Предел пользователей группы, 0 без ограничений
  need_email boolean NOT NULL DEFAULT FALSE,         -- В группу можно включать пользователя с подтвержденным адресом электронной почты
  need_phone boolean NOT NULL DEFAULT FALSE,         -- В группу можно включать пользователя с подтвержденным номером телефона
  status smallint NOT NULL DEFAULT 0 CHECK (status < 16 AND status >= 0),                -- Статус, битовая маска флагов автоподключения, подключения, удаления
  CONSTRAINT group_pkey PRIMARY KEY (group_id),
  CONSTRAINT group_code UNIQUE (code)
);

CREATE INDEX IF NOT EXISTS group_users_limit ON cult_system.group(users_limit);

CREATE TABLE IF NOT EXISTS cult_system.icon (
  icon_id SMALLSERIAL NOT NULL CHECK (icon_id > 0),
  name varchar(31) NOT NULL DEFAULT '',
  CONSTRAINT icon_pkey PRIMARY KEY (icon_id)
);

CREATE TABLE IF NOT EXISTS cult_system.markup_class (
  class_id SMALLSERIAL NOT NULL CHECK (class_id > 0),
  class varchar(127) NOT NULL DEFAULT '',
  title jsonb NOT NULL,
  CONSTRAINT markup_class_pkey PRIMARY KEY (class_id),
  CONSTRAINT markup_class_class UNIQUE (class)
);

CREATE TABLE IF NOT EXISTS cult_system.markup (
  markup_id SMALLSERIAL NOT NULL CHECK (markup_id > 0),
  class_id smallint NOT NULL CHECK (class_id > 0),
  markup varchar(127) NOT NULL DEFAULT '',
  title jsonb NOT NULL,
  CONSTRAINT markup_pkey PRIMARY KEY (markup_id),
  FOREIGN KEY (class_id) REFERENCES cult_system.markup_class (class_id)
);

CREATE TABLE IF NOT EXISTS cult_system.menu (
  menu_id SMALLSERIAL NOT NULL CHECK (menu_id > 0),
  markup_id smallint NOT NULL CHECK (markup_id > 0),
  code char(3) NOT NULL,                        -- Трехбуквенный код меню
  title jsonb NOT NULL,
  active boolean NOT NULL DEFAULT TRUE,
  status smallint NOT NULL DEFAULT 0 CHECK (status < 16 AND status >= 0),
  CONSTRAINT menu_pkey PRIMARY KEY (menu_id),
  CONSTRAINT menu_code UNIQUE (code),
  FOREIGN KEY (markup_id) REFERENCES cult_system.markup (markup_id)
);

CREATE TABLE IF NOT EXISTS cult_system.menu_responsive (
  menu_id SMALLSERIAL NOT NULL CHECK (menu_id > 0),
  for_id smallint NOT NULL CHECK (for_id > 0),
  markup_id smallint NOT NULL CHECK (markup_id > 0),
  source varchar(31) NOT NULL DEFAULT '',
  icon varchar(31) NOT NULL DEFAULT '',
  side boolean NOT NULL DEFAULT FALSE,
  displace boolean NOT NULL DEFAULT TRUE,
  CONSTRAINT menu_responsive_pkey PRIMARY KEY (menu_id),
  CONSTRAINT menu_responsive_for UNIQUE (for_id),
  CONSTRAINT menu_responsive_source UNIQUE (source),
  FOREIGN KEY (for_id) REFERENCES cult_system.markup (markup_id),
  FOREIGN KEY (markup_id) REFERENCES cult_system.markup (markup_id)
);

CREATE TABLE IF NOT EXISTS cult_system.reference (
  reference_id SMALLSERIAL NOT NULL CHECK (reference_id > 0),
  locate_id smallint NOT NULL CHECK (locate_id > 0),
  event_id integer CHECK (event_id > 0) DEFAULT NULL,
  code char(3) NOT NULL,                                      -- Трехбуквенный код ссылки
  value varchar(255) NOT NULL DEFAULT '',
  url varchar(255) NOT NULL DEFAULT '',
  text jsonb NOT NULL,
  active jsonb NOT NULL,
  title jsonb NOT NULL,
  status smallint NOT NULL DEFAULT 0 CHECK (status < 16 AND status >= 0),
  CONSTRAINT reference_pkey PRIMARY KEY (reference_id),
  CONSTRAINT reference_code UNIQUE (code),
  FOREIGN KEY (locate_id) REFERENCES cult_system.locate (locate_id),
  FOREIGN KEY (event_id) REFERENCES cult_system.event (event_id)
);

CREATE TABLE IF NOT EXISTS cult_system.menuitem (
  item_id SMALLSERIAL NOT NULL CHECK (item_id > 0),
  menu_id smallint NOT NULL CHECK (menu_id > 0),
  submenu_id smallint DEFAULT NULL CHECK (submenu_id > 0),
  reference_id smallint NOT NULL CHECK (reference_id > 0),
  role_id smallint DEFAULT NULL CHECK (role_id > 0),
  serial smallint NOT NULL DEFAULT 1,
  active boolean NOT NULL DEFAULT TRUE,
  icon varchar(63) NOT NULL DEFAULT '',
  empty boolean NOT NULL DEFAULT FALSE,
  follow boolean NOT NULL DEFAULT FALSE,
  blank boolean NOT NULL DEFAULT FALSE,
  status smallint NOT NULL DEFAULT 0 CHECK (status < 16 AND status >= 0),
  CONSTRAINT mainmenu_pkey PRIMARY KEY (item_id),
  FOREIGN KEY (menu_id) REFERENCES cult_system.menu (menu_id),
  FOREIGN KEY (submenu_id) REFERENCES cult_system.menu (menu_id),
  FOREIGN KEY (reference_id) REFERENCES cult_system.reference (reference_id),
  FOREIGN KEY (role_id) REFERENCES cult_system.role (role_id)
);

CREATE TABLE IF NOT EXISTS cult_system.navigate (
  locate_id smallint NOT NULL CHECK (locate_id > 0),
  menu_id smallint NOT NULL CHECK (menu_id >0),
  CONSTRAINT navigate_pkey PRIMARY KEY (locate_id, menu_id),
  FOREIGN KEY (locate_id) REFERENCES cult_system.locate (locate_id),
  FOREIGN KEY (menu_id) REFERENCES cult_system.menu (menu_id)
);

CREATE TABLE IF NOT EXISTS cult_system.permit (
  group_id smallint NOT NULL CHECK (group_id > 0),
  role_id smallint NOT NULL CHECK (role_id > 0),
  CONSTRAINT permit_pkey PRIMARY KEY (group_id, role_id),
  FOREIGN KEY (group_id) REFERENCES cult_system.group (group_id),
  FOREIGN KEY (role_id) REFERENCES cult_system.role (role_id)
);

CREATE TABLE IF NOT EXISTS cult_system.privilege (
  privilege_id SERIAL NOT NULL CHECK (privilege_id > 0),
  locate_id smallint NOT NULL CHECK (locate_id > 0),
  event_id integer NOT NULL CHECK (event_id > 0),
  CONSTRAINT privilege_pkey PRIMARY KEY (privilege_id),
  CONSTRAINT privilege_locate_event UNIQUE (locate_id, event_id),
  FOREIGN KEY (locate_id) REFERENCES cult_system.locate (locate_id),
  FOREIGN KEY (event_id) REFERENCES cult_system.event (event_id)
);

CREATE TABLE IF NOT EXISTS cult_system.rule (
  role_id integer NOT NULL CHECK (role_id > 0),
  privilege_id integer NOT NULL CHECK (privilege_id > 0),
  CONSTRAINT rule_pkey PRIMARY KEY (role_id, privilege_id),
  FOREIGN KEY (role_id) REFERENCES cult_system.role (role_id),
  FOREIGN KEY (privilege_id) REFERENCES cult_system.privilege (privilege_id)
);

CREATE TABLE IF NOT EXISTS cult_system.site_template (
  template_id SMALLSERIAL NOT NULL CHECK (template_id > 0),
  name varchar(31) NOT NULL DEFAULT '',
  status smallint NOT NULL DEFAULT 0 CHECK (status < 16 AND status >= 0),
  CONSTRAINT site_template_pkey PRIMARY KEY (template_id),
  CONSTRAINT site_template_name UNIQUE (name)
);

CREATE TABLE IF NOT EXISTS cult_system.temp (
  temp_id varchar(7) NOT NULL,
  temp_data text NOT NULL,
  temp_ts timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT temp_key UNIQUE (temp_id)
);

CREATE TABLE IF NOT EXISTS cult_system.user (
  user_id SERIAL NOT NULL CHECK (user_id > 0),          -- Идентификатор пользователя
  parent_id integer DEFAULT NULL CHECK (parent_id > 0), -- Идентификатор связанных пользователей
  login varchar(31) NOT NULL DEFAULT '',                -- Имя учетной записи
  oauth varchar(31) NOT NULL DEFAULT '',                -- Идентификатор пользователя у провайдера oAuth
  team varchar(255) NOT NULL DEFAULT '',                -- Ожидаемое участие в группах
  password varchar(128) NOT NULL DEFAULT '',            -- Пароль
  email varchar(63) NOT NULL DEFAULT '',                -- Адрес электронной почты
  phone varchar(31) NOT NULL DEFAULT '',                -- Контактный телефон (например для приема СМС)
  name varchar(31) NOT NULL DEFAULT '',                                    -- Отображаемое имя пользователя
  photo varchar(255) NOT NULL DEFAULT '',                                  -- URL фотографии или аватара пользователя
  "create" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP, -- Время регистрации
  status smallint NOT NULL DEFAULT 0 CHECK (status < 16 AND status >= 0),  -- Статус, 0 - пользователь активен
  CONSTRAINT user_pkey PRIMARY KEY (user_id),
  CONSTRAINT user_login UNIQUE (login),
  CONSTRAINT user_email UNIQUE (email),
  FOREIGN KEY (parent_id) REFERENCES cult_system.user (user_id)
);

CREATE TABLE IF NOT EXISTS cult_system.team (
  user_id integer NOT NULL CHECK (user_id > 0),         -- Идентификатор пользователя
  group_id smallint NOT NULL CHECK (group_id > 0),      -- Идентификатор группы
  CONSTRAINT team_pkey PRIMARY KEY (user_id, group_id),
  FOREIGN KEY (user_id) REFERENCES cult_system.user (user_id),
  FOREIGN KEY (group_id) REFERENCES cult_system.group (group_id)
);

CREATE TABLE IF NOT EXISTS cult_system.user_auth (
  user_id integer NOT NULL CHECK (user_id > 0),  -- Идентификатор пользователя
  hash varchar(128) NOT NULL DEFAULT '',         -- Хэш последней успешной авторизации
  auth timestamp without time zone NOT NULL,     -- Время последней успешной авторизации
  CONSTRAINT user_auth_pkey PRIMARY KEY (user_id, hash),
  FOREIGN KEY (user_id) REFERENCES cult_system.user (user_id)
);

CREATE TABLE IF NOT EXISTS cult_system.user_oauth (
  profile_id SERIAL NOT NULL CHECK (user_id > 0),-- Идентификатор профиля
  user_id integer NOT NULL CHECK (user_id > 0),  -- Систеный идентификатор пользователя
  network varchar(31) NOT NULL DEFAULT '',       -- Идентификатор соцсети или oAuth сервиса
  uid varchar(31) NOT NULL DEFAULT '',           -- Уникальный идентификатор пользователя в рамках соцсети
  nickname varchar(31) NOT NULL DEFAULT '',      -- Псевдоним пользователя
  email varchar(63) NOT NULL DEFAULT '',         -- Email пользователя
  verified_email smallint NOT NULL DEFAULT 0 CHECK (sex >= -1 AND sex <= 1), -- Флаг верификации email, принимает значения 1 и -1
  first_name varchar(31) NOT NULL DEFAULT '',    -- Имя пользователя
  last_name varchar(31) NOT NULL DEFAULT '',     -- Фамилия пользователя
  bdate date NOT NULL DEFAULT '0001-01-01',      -- Дата рождения
  sex smallint NOT NULL DEFAULT 0 CHECK (sex >= 0 AND sex <= 2), -- Пол пользователя (0 – не определен, 1 – женский, 2 – мужской)
  phone varchar(31) NOT NULL DEFAULT '',         -- Телефон пользователя в цифровом формате без лишних символов
  identity varchar(255) NOT NULL DEFAULT '',     -- Глобально уникальный идентификатор oAuth пользователя
  profile varchar(255) NOT NULL DEFAULT '',      -- Адрес профиля пользователя (ссылка на его страницу в соцсети)
  photo varchar(255) NOT NULL DEFAULT '',        -- Адрес квадратной аватарки (до 100*100)
  photo_big varchar(255) NOT NULL DEFAULT '',    -- Адрес самой большой аватарки, выдаваемой соц. сетью
  city varchar(31) NOT NULL DEFAULT '',          -- Город
  country varchar(31) NOT NULL DEFAULT '',       -- Страна
  CONSTRAINT user_oauth_pkey PRIMARY KEY (profile_id),
  CONSTRAINT user_oauth_uid_net UNIQUE (uid, network),
  FOREIGN KEY (user_id) REFERENCES cult_system.user (user_id)
);

CREATE TABLE IF NOT EXISTS cult_system.user_phone (
  user_id integer NOT NULL CHECK (user_id > 0),  -- Идентификатор пользователя
  phone varchar(20) NOT NULL DEFAULT '',         -- Телефон принимающий СМС
  CONSTRAINT user_phone_pkey PRIMARY KEY (user_id),
  FOREIGN KEY (user_id) REFERENCES cult_system.user (user_id)
);


CREATE OR REPLACE VIEW cult_system.additions AS SELECT
cult_system.addon.plugin_id        AS plugin_id,
cult_system.group.group_id         AS group_id,
cult_system.group.title            AS group,
cult_system.group.users_limit      AS group_limit,
cult_system.group.status           AS group_status,
cult_system.role.role_id           AS role_id,
cult_system.role.title             AS role,
cult_system.role.status            AS role_status,
cult_system.addon.locate_id        AS locate_id,
cult_system.build.build_id         AS build_id,
cult_system.locate.title           AS locate,
cult_system.decision.title         AS decision,
cult_system.build.title            AS build,
cult_system.plugin.config_id       AS config_id,
"p_cfg".class                      AS config_class,
cult_system.plugin.class           AS class,
cult_system.plugin.title           AS title,
cult_system.addon.active           AS active,
cult_system.plugin.status          AS status,
cult_system.component.title        AS component,
cult_system.component.class        AS component_class,
cult_system.config.class           AS config
FROM cult_system.addon
LEFT JOIN cult_system.plugin       ON cult_system.addon.plugin_id       = cult_system.plugin.plugin_id
LEFT JOIN cult_system.attach       ON cult_system.plugin.plugin_id      = cult_system.attach.plugin_id
LEFT JOIN cult_system.role         ON cult_system.attach.role_id        = cult_system.role.role_id
LEFT JOIN cult_system.permit       ON cult_system.role.role_id          = cult_system.permit.role_id
LEFT JOIN cult_system.group        ON cult_system.permit.group_id       = cult_system.group.group_id
LEFT JOIN cult_system.locate       ON cult_system.addon.locate_id       = cult_system.locate.locate_id
LEFT JOIN cult_system.build        ON cult_system.locate.build_id       = cult_system.build.build_id
LEFT JOIN cult_system.decision     ON cult_system.locate.decision_id    = cult_system.decision.decision_id
LEFT JOIN cult_system.project      ON cult_system.decision.project_id   = cult_system.project.project_id
LEFT JOIN cult_system.component    ON cult_system.decision.component_id = cult_system.component.component_id
LEFT JOIN cult_system.config       ON cult_system.component.config_id   = cult_system.config.config_id
LEFT JOIN cult_system.config p_cfg ON cult_system.plugin.config_id      = p_cfg.config_id;


CREATE OR REPLACE VIEW cult_system.application AS SELECT
cult_system.build.build_id     AS build_id,
cult_system.project.project_id AS project_id,
cult_system.project.config_id  AS config_id,
cult_system.build.title->>cult_system.language.name   AS title,
cult_system.project.class      AS class,
cult_system.config.class       AS config,
cult_system.project.title->>cult_system.language.name AS project,
cult_system.project.singleton  AS singleton,
cult_system.language.lang_id   AS lang_id,
cult_system.language.name      AS lang,
cult_system.language.title     AS language
FROM cult_system.build
JOIN cult_system.language      ON cult_system.language.status   = 0
LEFT JOIN cult_system.project  ON cult_system.build.project_id  = cult_system.project.project_id
LEFT JOIN cult_system.config   ON cult_system.project.config_id = cult_system.config.config_id;


CREATE OR REPLACE VIEW cult_system.attachables AS SELECT
cult_system.attach.plugin_id    AS plugin_id,
cult_system.group.group_id      AS group_id,
cult_system.group.title         AS group,
cult_system.group.users_limit   AS group_limit,
cult_system.group.status        AS group_status,
cult_system.role.role_id        AS role_id,
cult_system.role.title          AS role,
cult_system.role.status         AS role_status,
cult_system.addon.locate_id     AS locate_id,
cult_system.build.build_id      AS build_id,
cult_system.locate.title        AS locate,
cult_system.decision.title      AS decision,
cult_system.build.title         AS build,
cult_system.plugin.config_id    AS config_id,
"p_cfg".class                   AS config_class,
cult_system.plugin.class        AS class,
cult_system.plugin.title        AS title,
cult_system.addon.active        AS active,
cult_system.plugin.status       AS status,
cult_system.component.title     AS component,
cult_system.component.class     AS component_class,
cult_system.config.class        AS config
FROM cult_system.attach
LEFT JOIN cult_system.plugin       ON cult_system.attach.plugin_id      = cult_system.plugin.plugin_id
LEFT JOIN cult_system.role         ON cult_system.attach.role_id        = cult_system.role.role_id
LEFT JOIN cult_system.permit       ON cult_system.role.role_id          = cult_system.permit.role_id
LEFT JOIN cult_system.group        ON cult_system.permit.group_id       = cult_system.group.group_id
LEFT JOIN cult_system.addon        ON cult_system.plugin.plugin_id      = cult_system.addon.plugin_id
LEFT JOIN cult_system.locate       ON cult_system.addon.locate_id       = cult_system.locate.locate_id
LEFT JOIN cult_system.build        ON cult_system.locate.build_id       = cult_system.build.build_id
LEFT JOIN cult_system.decision     ON cult_system.locate.decision_id    = cult_system.decision.decision_id
LEFT JOIN cult_system.project      ON cult_system.decision.project_id   = cult_system.project.project_id
LEFT JOIN cult_system.component    ON cult_system.decision.component_id = cult_system.component.component_id
LEFT JOIN cult_system.config       ON cult_system.component.config_id   = cult_system.config.config_id
LEFT JOIN cult_system.config p_cfg ON cult_system.plugin.config_id      = p_cfg.config_id;


CREATE OR REPLACE VIEW cult_system.caches AS SELECT DISTINCT
cult_system.cache.event_id        AS event_id,
cult_system.cache.locate_id       AS locate_id,
CASE
  WHEN cult_system.component.cache THEN FALSE
  WHEN "c".cache                   THEN FALSE
  WHEN cult_system.decision.cache  THEN FALSE
  WHEN cult_system.locate.cache    THEN FALSE
  ELSE cult_system.cache.cache
END                               AS cache,
CASE
  WHEN cult_system.component.cache THEN FALSE
  WHEN "c".cache                   THEN FALSE
  WHEN cult_system.decision.cache  THEN FALSE
  WHEN cult_system.locate.cache    THEN FALSE
  ELSE cult_system.event.cache
END                               AS cachable,
cult_system.config.class          AS config,
cult_system.event.name            AS name,
cult_system.event.title->>cult_system.language.name
                                  AS title,
cult_system.event.access          AS access,
cult_system.language.lang_id      AS lang_id,
cult_system.language.name         AS lang,
cult_system.language.title        AS language
FROM cult_system.cache
JOIN cult_system.language         ON cult_system.language.status       = 0
LEFT JOIN cult_system.event       ON cult_system.cache.event_id        = cult_system.event.event_id
LEFT JOIN cult_system.component c ON cult_system.event.component_id    = c.component_id
LEFT JOIN cult_system.config      ON c.config_id                       = cult_system.config.config_id
LEFT JOIN cult_system.locate      ON cult_system.cache.locate_id       = cult_system.locate.locate_id
LEFT JOIN cult_system.decision    ON cult_system.locate.decision_id    = cult_system.decision.decision_id
LEFT JOIN cult_system.component   ON cult_system.decision.component_id = cult_system.component.component_id;


CREATE OR REPLACE VIEW cult_system.components AS SELECT DISTINCT
cult_system.component.component_id AS component_id,
cult_system.component.config_id    AS config_id,
cult_system.component.title->>cult_system.language.name
                                   AS title,
cult_system.component.role_id      AS role_id,
cult_system.role.title->>cult_system.language.name
                                   AS role,
cult_system.component.class        AS class,
cult_system.component.cache        AS cache,
cult_system.config.class           AS config,
cult_system.config.title->>cult_system.language.name
                                   AS config_title,
cult_system.component.singleton    AS singleton,
CASE
  WHEN cult_system.decision.decision_id IS NULL THEN 1
  WHEN cult_system.component.singleton THEN 0
  ELSE 1
END                                AS is_free,
cult_system.decision.decision_id
  IS NOT NULL                      AS is_decision,
cult_system.language.lang_id       AS lang_id,
cult_system.language.name          AS lang,
cult_system.language.title         AS language
FROM cult_system.component
JOIN cult_system.language      ON cult_system.language.status        = 0
LEFT JOIN cult_system.config   ON cult_system.component.config_id    = cult_system.config.config_id
LEFT JOIN cult_system.decision ON cult_system.component.component_id = cult_system.decision.component_id
LEFT JOIN cult_system.role     ON cult_system.component.role_id      = cult_system.role.role_id;


CREATE OR REPLACE VIEW cult_system.configs AS SELECT
cult_system.config.config_id AS config_id,
cult_system.config.class     AS class,
cult_system.config.title->>cult_system.language.name
                             AS title,
cult_system.language.lang_id AS lang_id,
cult_system.language.name    AS lang,
cult_system.language.title   AS language
FROM cult_system.config
JOIN cult_system.language ON cult_system.language.status = 0;


CREATE OR REPLACE VIEW cult_system.config_options AS SELECT
cult_system.config_option.option_id  AS option_id,
cult_system.config_data.locate_id    AS locate_id,
cult_system.config_option.config_id  AS config_id,
cult_system.config.class             AS config,
cult_system.config.title             AS config_title,
cult_system.config_option.slice_id   AS slice_id,
cult_system.config_slice.slice       AS slice,
cult_system.config_slice.title       AS slice_title,
cult_system.config_option.type_id    AS type_id,
cult_system.config_type.type         AS type,
cult_system.config_option.role_id    AS role_id,
cult_system.config_option.serial     AS serial_number,
cult_system.config_option.global     AS global,
cult_system.config_option.active     AS active,
cult_system.config_option.name       AS name,
cult_system.config_option.input      AS input,
cult_system.config_option.output     AS output,
cult_system.config_option.title      AS title,
cult_system.config_slice.serial      AS serial,
cult_system.config_default."default" AS "default",
cult_system.config_data.value        AS value,
cult_system.config_data.local        AS local,
cult_system.config_enum.variants     AS variants,
cult_system.config_enum.valuebykey   AS valuebykey
FROM cult_system.config_option
LEFT JOIN cult_system.config         ON cult_system.config_option.config_id = cult_system.config.config_id
LEFT JOIN cult_system.config_type    ON cult_system.config_option.type_id   = cult_system.config_type.type_id
LEFT JOIN cult_system.config_slice   ON cult_system.config_option.slice_id  = cult_system.config_slice.slice_id
LEFT JOIN cult_system.config_enum    ON cult_system.config_option.option_id = cult_system.config_enum.option_id
LEFT JOIN cult_system.config_default ON cult_system.config_option.option_id = cult_system.config_default.option_id
LEFT JOIN cult_system.config_data    ON cult_system.config_option.option_id = cult_system.config_data.option_id;


CREATE OR REPLACE VIEW cult_system.config_kits AS SELECT
cult_system.config_option.option_id AS option_id,
cult_system.config_option.config_id AS config_id,
cult_system.config_data.locate_id   AS locate_id,
cult_system.language.lang_id        AS lang_id,
cult_system.language.name           AS lang,
cult_system.config_option.type_id   AS type_id,
cult_system.config_option.serial    AS serial_number,
cult_system.config.class            AS config,
cult_system.config_option.name      AS name,
cult_system.config_option.input     AS input,
cult_system.config_option.output    AS output,
cult_system.config_data.value->>cult_system.language.name
                                    AS value,
cult_system.config_enum.valuebykey  AS valuebykey,
cult_system.config_option.global    AS global,
cult_system.config_option.active    AS active
FROM cult_system.config_option
JOIN cult_system.language         ON cult_system.language.status         = 0
LEFT JOIN cult_system.config      ON cult_system.config_option.config_id = cult_system.config.config_id
LEFT JOIN cult_system.config_type ON cult_system.config_option.type_id   = cult_system.config_type.type_id
LEFT JOIN cult_system.config_data ON cult_system.config_option.option_id = cult_system.config_data.option_id
LEFT JOIN cult_system.config_enum ON cult_system.config_option.option_id = cult_system.config_enum.option_id;


CREATE OR REPLACE VIEW cult_system.controls AS SELECT
cult_system.control.control_id     AS control_id,
cult_system.component.component_id AS component_id,
cult_system.control.config_id      AS config_id,
cult_system.control.event_id       AS event_id,
cult_system.locate.locate_id       AS locate_id,
cult_system.language.lang_id       AS lang_id,
cult_system.locate.title->>cult_system.language.name
                                   AS locate,
cult_system.language.name          AS lang,
cult_system.language.title         AS language,
cult_system.decision.name          AS name,
cult_system.decision.title->>cult_system.language.name
                                   AS decision,
cult_system.project.project_id     AS project_id,
cult_system.project.class          AS project_class,
cult_system.project.title->>cult_system.language.name
                                   AS project,
cult_system.control.class          AS class,
"cc".class                         AS control,
cult_system.control.self           AS self,
cult_system.component.class        AS component,
cult_system.config.class           AS config,
cult_system.event.name             AS event,
cult_system.event.access           AS access,
cult_system.control.title->>cult_system.language.name
                                   AS title
FROM cult_system.control
JOIN cult_system.language          ON cult_system.language.status        = 0
LEFT JOIN cult_system.config AS cc ON cult_system.control.config_id      = cc.config_id
LEFT JOIN cult_system.event        ON cult_system.control.event_id       = cult_system.event.event_id
LEFT JOIN cult_system.component    ON cult_system.event.component_id     = cult_system.component.component_id
LEFT JOIN cult_system.config       ON cult_system.component.config_id    = cult_system.config.config_id
LEFT JOIN cult_system.decision     ON cult_system.component.component_id = cult_system.decision.component_id
LEFT JOIN cult_system.locate       ON cult_system.decision.decision_id   = cult_system.locate.decision_id
LEFT JOIN cult_system.project      ON cult_system.decision.project_id    = cult_system.project.project_id;


CREATE OR REPLACE VIEW cult_system.decisions AS SELECT
cult_system.decision.decision_id  AS decision_id,
cult_system.decision.project_id   AS project_id,
cult_system.decision.component_id AS component_id,
cult_system.decision.name         AS name,
cult_system.decision.title->>cult_system.language.name
                                  AS title,
CASE cult_system.component.cache
  WHEN TRUE THEN cult_system.decision.cache
  ELSE FALSE
END                               AS cache,
cult_system.language.lang_id      AS lang_id,
cult_system.language.name         AS lang,
cult_system.language.title        AS language
FROM cult_system.decision
JOIN cult_system.language       ON cult_system.language.status       = 0
LEFT JOIN cult_system.component ON cult_system.decision.component_id = cult_system.component.component_id;


CREATE OR REPLACE VIEW cult_system.events AS SELECT
cult_system.event.event_id     AS event_id,
cult_system.event.name         AS name,
cult_system.event.title->>cult_system.language.name
                               AS title,
cult_system.event.component_id AS component_id,
cult_system.event.role_id      AS role_id,
cult_system.role.title->>cult_system.language.name
                               AS role,
CASE cult_system.component.cache
  WHEN TRUE THEN cult_system.event.cache
  ELSE FALSE
END                            AS cache,
cult_system.event.access       AS access,
cult_system.event.nav          AS nav,
cult_system.language.lang_id   AS lang_id,
cult_system.language.name      AS lang,
cult_system.language.title     AS language,
cult_system.component.title->>cult_system.language.name
                               AS component,
cult_system.component.class    AS class,
cult_system.config.class       AS config
FROM cult_system.event
JOIN cult_system.language       ON cult_system.language.status     = 0
LEFT JOIN cult_system.role      ON cult_system.event.role_id       = cult_system.role.role_id
LEFT JOIN cult_system.component ON cult_system.event.component_id  = cult_system.component.component_id
LEFT JOIN cult_system.config    ON cult_system.component.config_id = cult_system.config.config_id;


CREATE OR REPLACE VIEW cult_system.groups AS SELECT
cult_system.group.group_id      AS group_id,
cult_system.group.code          AS code,
cult_system.group.title->>cult_system.language.name
                                AS group,
cult_system.group.users_limit   AS users_limit,
cult_system.group.need_email    AS need_email,
cult_system.group.need_phone    AS need_phone,
cult_system.group.status        AS group_status,
cult_system.language.lang_id    AS lang_id,
cult_system.language.name       AS lang,
cult_system.language.title      AS language,
cult_system.user.user_id        AS user_id,
cult_system.user.login          AS login,
cult_system.user.email          AS email,
cult_system.user.status         AS user_status,
cult_system.role.role_id        AS role_id,
cult_system.role.title->>cult_system.language.name
                                AS role,
cult_system.role.status         AS role_status
FROM cult_system.group
JOIN cult_system.language    ON cult_system.language.status = 0
LEFT JOIN cult_system.team   ON cult_system.group.group_id  = cult_system.team.group_id
RIGHT JOIN cult_system.user  ON cult_system.team.user_id    = cult_system.user.user_id
LEFT JOIN cult_system.permit ON cult_system.group.group_id  = cult_system.permit.group_id
LEFT JOIN cult_system.role   ON cult_system.permit.role_id  = cult_system.role.role_id;


CREATE OR REPLACE VIEW cult_system.items AS SELECT DISTINCT
cult_system.menuitem.item_id      AS item_id,
cult_system.reference.locate_id   AS locate_id,
CASE
  WHEN cult_system.reference.locate_id > 0 THEN cult_system.group.group_id
  ELSE 0
END                               AS group_id,
CASE
  WHEN cult_system.reference.locate_id > 0 THEN cult_system.group.status
  ELSE 0
END                               AS group_status,
CASE
  WHEN cult_system.reference.locate_id > 0 THEN cult_system.role.status
  ELSE 0
END                               AS role_status,
cult_system.menuitem.menu_id      AS menu_id,
cult_system.menuitem.role_id      AS role_id,
cult_system.menu.title            AS menu_title,
cult_system.role.title            AS role,
cult_system.menu.active           AS menu_active,
cult_system.menu.status           AS menu_status,
cult_system.markup.markup_id      AS markup_id,
cult_system.markup.markup         AS markup,
cult_system.markup_class.class_id AS markup_class_id,
cult_system.markup_class.class    AS markup_class,
cult_system.menuitem.submenu_id   AS submenu_id,
"submenu".title                   AS submenu_title,
"submenu".active                  AS submenu_active,
"submenu".status                  AS submenu_status,
"submarkup".markup_id             AS submarkup_id,
"submarkup".markup                AS submarkup,
"sub_mc".class_id                 AS submarkup_class_id,
"sub_mc".class                    AS submarkup_class,
cult_system.menuitem.reference_id AS reference_id,
cult_system.menuitem.serial       AS serial,
cult_system.menuitem.icon         AS icon,
cult_system.reference.url         AS url,
cult_system.reference.text        AS text,
cult_system.reference.active      AS active,
cult_system.reference.status + menuitem.status
                                  AS status,
CASE cult_system.menu.active
	WHEN TRUE THEN cult_system.menuitem.active
	ELSE FALSE
END                               AS item,
cult_system.locate.decision_id    AS decision_id,
cult_system.locate.serial         AS locate_serial,
cult_system.decision.component_id AS component_id,
cult_system.locate.build_id       AS build_id,
cult_system.build.project_id      AS project_id,
cult_system.decision.name         AS name,
cult_system.locate.name           AS locate,
cult_system.decision.title        AS title,
cult_system.component.class       AS class,
cult_system.config.class          AS config,
cult_system.project.class         AS class_project,
cult_system.component.title       AS component,
cult_system.build.title           AS build,
cult_system.project.title         AS project
FROM cult_system.menuitem
LEFT JOIN cult_system.menu                ON cult_system.menuitem.menu_id      = cult_system.menu.menu_id
LEFT JOIN cult_system.markup              ON cult_system.menu.markup_id        = cult_system.markup.markup_id
LEFT JOIN cult_system.markup_class        ON cult_system.markup.class_id       = cult_system.markup_class.class_id
LEFT JOIN cult_system.menu submenu        ON cult_system.menuitem.submenu_id   = submenu.menu_id
LEFT JOIN cult_system.markup submarkup    ON submenu.markup_id                 = submarkup.markup_id
LEFT JOIN cult_system.markup_class sub_mc ON submarkup.class_id                = sub_mc.class_id
LEFT JOIN cult_system.reference           ON cult_system.menuitem.reference_id = cult_system.reference.reference_id
LEFT JOIN cult_system.event               ON cult_system.reference.event_id    = cult_system.event.event_id
LEFT JOIN cult_system.locate              ON cult_system.reference.locate_id   = cult_system.locate.locate_id
LEFT JOIN cult_system.decision            ON cult_system.locate.decision_id    = cult_system.decision.decision_id
LEFT JOIN cult_system.component           ON cult_system.decision.component_id = cult_system.component.component_id
LEFT JOIN cult_system.config              ON cult_system.component.config_id   = cult_system.config.config_id
LEFT JOIN cult_system.build               ON cult_system.locate.build_id       = cult_system.build.build_id
LEFT JOIN cult_system.project             ON cult_system.build.project_id      = cult_system.project.project_id
LEFT JOIN cult_system.access              ON cult_system.locate.locate_id      = cult_system.access.locate_id
LEFT JOIN cult_system.role                ON cult_system.role.role_id          = cult_system.access.role_id
LEFT JOIN cult_system.permit              ON cult_system.permit.role_id        = cult_system.role.role_id
LEFT JOIN cult_system.group               ON cult_system.group.group_id        = cult_system.permit.group_id;


CREATE OR REPLACE VIEW cult_system.locs AS SELECT
cult_system.locate.locate_id      AS locate_id,
cult_system.locate.decision_id    AS decision_id,
cult_system.locate.serial         AS serial,
cult_system.decision.component_id AS component_id,
cult_system.component.role_id     AS role_id,
cult_system.locate.build_id       AS build_id,
cult_system.build.project_id      AS project_id,
cult_system.config.config_id      AS config_id,
CASE cult_system.locate.name
	WHEN ''
  THEN CONCAT(
    cult_system.decision.name,
    cult_system.locate.locate_id
  )
  ELSE cult_system.locate.name
END                               AS name,
cult_system.locate.title->>cult_system.language.name
                                  AS title,
cult_system.decision.title->>cult_system.language.name
                                  AS decision,
cult_system.component.class       AS class,
CASE
	WHEN cult_system.component.cache
    AND cult_system.decision.cache
  THEN cult_system.locate.cache
	ELSE FALSE
END                               AS cache,
CASE cult_system.component.cache
	WHEN TRUE THEN cult_system.decision.cache
	ELSE FALSE
END                               AS cachable,
cult_system.config.class          AS config,
cult_system.project.class         AS class_project,
cult_system.component.title->>cult_system.language.name
                                  AS component,
cult_system.build.title->>cult_system.language.name
                                  AS build,
cult_system.project.title->>cult_system.language.name
                                  AS project,
cult_system.component.singleton   AS singleton,
cult_system.language.lang_id      AS lang_id,
cult_system.language.name         AS lang,
cult_system.language.title        AS language
FROM cult_system.locate
JOIN cult_system.language         ON cult_system.language.status       = 0
LEFT JOIN cult_system.decision    ON cult_system.locate.decision_id    = cult_system.decision.decision_id
LEFT JOIN cult_system.component   ON cult_system.decision.component_id = cult_system.component.component_id
LEFT JOIN cult_system.config      ON cult_system.component.config_id   = cult_system.config.config_id
LEFT JOIN cult_system.build       ON cult_system.locate.build_id       = cult_system.build.build_id
LEFT JOIN cult_system.project     ON cult_system.build.project_id      = cult_system.project.project_id;


CREATE OR REPLACE VIEW cult_system.map AS SELECT
cult_system.user.user_id         AS user_id,
cult_system.user.login           AS login,
cult_system.group.group_id       AS group_id,
cult_system.group.title          AS group,
cult_system.group.users_limit    AS group_limit,
cult_system.group.status         AS group_status,
cult_system.role.role_id         AS role_id,
cult_system.role.title           AS role,
cult_system.role.status          AS role_status,
cult_system.locate.locate_id     AS locate_id,
cult_system.locate.build_id      AS build_id,
cult_system.locate.serial        AS serial,
cult_system.locate.title         AS locate,
cult_system.decision.title       AS decision,
cult_system.build.title          AS build,
cult_system.decision.decision_id AS decision_id,
cult_system.decision.project_id  AS project_id,
cult_system.decision.name        AS decision_name,
cult_system.project.class        AS project_class,
cult_system.project.title        AS project,
cult_system.project.singleton    AS project_singleton,
cult_system.component.class      AS component_class,
cult_system.component.title      AS component_title,
cult_system.config.class         AS config,
cult_system.component.singleton  AS component_singleton
FROM cult_system.access
LEFT JOIN cult_system.role       ON cult_system.role.role_id          = cult_system.access.role_id
LEFT JOIN cult_system.permit     ON cult_system.permit.role_id        = cult_system.role.role_id
LEFT JOIN cult_system.group      ON cult_system.group.group_id        = cult_system.permit.group_id
LEFT JOIN cult_system.team       ON cult_system.group.group_id        = cult_system.team.group_id
RIGHT JOIN cult_system.user      ON cult_system.team.user_id          = cult_system.user.user_id
LEFT JOIN cult_system.locate     ON cult_system.access.locate_id      = cult_system.locate.locate_id
LEFT JOIN cult_system.build      ON cult_system.locate.build_id       = cult_system.build.build_id
LEFT JOIN cult_system.decision   ON cult_system.locate.decision_id    = cult_system.decision.decision_id
LEFT JOIN cult_system.project    ON cult_system.decision.project_id   = cult_system.project.project_id
LEFT JOIN cult_system.component  ON cult_system.decision.component_id = cult_system.component.component_id
LEFT JOIN cult_system.config     ON cult_system.component.config_id   = cult_system.config.config_id;


CREATE OR REPLACE VIEW cult_system.markups AS SELECT
cult_system.markup.markup_id      AS id,
cult_system.markup.markup_id      AS markup_id,
cult_system.markup.markup         AS markup,
cult_system.markup_class.class_id AS class_id,
cult_system.markup_class.class    AS class
FROM cult_system.markup
LEFT JOIN cult_system.markup_class ON cult_system.markup.class_id = cult_system.markup_class.class_id;


CREATE OR REPLACE VIEW cult_system.matrix AS SELECT
cult_system.user.user_id           AS user_id,
cult_system.user.login             AS login,
cult_system.group.group_id         AS group_id,
cult_system.group.title            AS group,
cult_system.group.users_limit      AS group_limit,
cult_system.group.status           AS group_status,
cult_system.privilege.privilege_id AS privilege_id,
cult_system.privilege.locate_id    AS locate_id,
cult_system.build.build_id         AS build_id,
cult_system.locate.title           AS locate,
cult_system.decision.title         AS decision,
cult_system.build.title            AS build,
cult_system.project.title          AS project,
cult_system.event.event_id         AS event_id,
cult_system.event.name             AS event,
cult_system.event.title            AS title,
cult_system.event.access           AS access,
cult_system.event.nav              AS nav,
cult_system.role.role_id           AS role_id,
cult_system.role.title             AS role,
cult_system.role.status            AS role_status,
cult_system.component.title        AS component,
cult_system.component.class        AS class,
cult_system.config.class           AS config
FROM cult_system.rule
LEFT JOIN cult_system.role         ON cult_system.rule.role_id          = cult_system.role.role_id
LEFT JOIN cult_system.permit       ON cult_system.role.role_id          = cult_system.permit.role_id
LEFT JOIN cult_system.group        ON cult_system.permit.group_id       = cult_system.group.group_id
LEFT JOIN cult_system.team         ON cult_system.group.group_id        = cult_system.team.group_id
RIGHT JOIN cult_system.user        ON cult_system.team.user_id          = cult_system.user.user_id
LEFT JOIN cult_system.privilege    ON cult_system.rule.privilege_id     = cult_system.privilege.privilege_id
LEFT JOIN cult_system.event        ON cult_system.privilege.event_id    = cult_system.event.event_id
LEFT JOIN cult_system.locate       ON cult_system.privilege.locate_id   = cult_system.locate.locate_id
LEFT JOIN cult_system.build        ON cult_system.locate.build_id       = cult_system.build.build_id
LEFT JOIN cult_system.decision     ON cult_system.locate.decision_id    = cult_system.decision.decision_id
LEFT JOIN cult_system.project      ON cult_system.decision.project_id   = cult_system.project.project_id
LEFT JOIN cult_system.component    ON cult_system.decision.component_id = cult_system.component.component_id
LEFT JOIN cult_system.config       ON cult_system.component.config_id   = cult_system.config.config_id;


CREATE OR REPLACE VIEW cult_system.menus AS SELECT
cult_system.menu.menu_id           AS id,
cult_system.menu.menu_id           AS menu_id,
cult_system.menu.title->>cult_system.language.name
                                   AS title,
cult_system.menu.active            AS active,
cult_system.menu.status            AS status,
cult_system.language.lang_id       AS lang_id,
cult_system.language.name          AS lang,
cult_system.language.title         AS language,
cult_system.markup.markup_id       AS markup_id,
cult_system.markup.markup          AS markup,
cult_system.markup_class.class_id  AS class_id,
cult_system.markup_class.class     AS class
FROM cult_system.menu
JOIN cult_system.language          ON cult_system.language.status = 0
LEFT JOIN cult_system.markup       ON cult_system.menu.markup_id  = cult_system.markup.markup_id
LEFT JOIN cult_system.markup_class ON cult_system.markup.class_id = cult_system.markup_class.class_id;


CREATE OR REPLACE VIEW cult_system.menu_responsives AS SELECT
cult_system.menu_responsive.menu_id   AS menu_id,
cult_system.menu_responsive.for_id    AS for_id,
cult_system.menu_responsive.markup_id AS markup_id,
"menu".markup                         AS menu,
cult_system.markup.markup             AS markup,
cult_system.menu_responsive.source    AS source,
cult_system.menu_responsive.icon      AS icon,
CASE cult_system.menu_responsive.side
  WHEN FALSE THEN 'left'
  ELSE 'right'
END                                   AS side,
cult_system.menu_responsive.displace  AS displace
FROM cult_system.menu_responsive
LEFT JOIN cult_system.markup menu ON cult_system.menu_responsive.for_id    = menu.markup_id
LEFT JOIN cult_system.markup      ON cult_system.menu_responsive.markup_id = cult_system.markup.markup_id;


CREATE OR REPLACE VIEW cult_system.modifies AS SELECT DISTINCT
"modify".project_id                  AS modify_id,
"modify".class                       AS class,
"modify".title                       AS title,
"modify".singleton                   AS singleton,
cult_system.build.build_id           AS build_id,
cult_system.build.title              AS build,
cult_system.decision.decision_id     AS decision_id,
cult_system.decision.project_id      AS project_id,
cult_system.decision.name            AS name,
cult_system.decision.title           AS decision,
cult_system.project.class            AS project_class,
cult_system.project.title            AS project,
cult_system.project.singleton        AS project_singleton,
cult_system.component.component_id   AS component_id,
cult_system.component.class          AS component_class,
cult_system.component.title          AS component_title,
cult_system.config.class             AS config,
cult_system.component.singleton      AS component_singleton,
CASE cult_system.locate.locate_id
	WHEN NULL THEN 0
	ELSE cult_system.locate.locate_id
END                                  AS locate_id,
cult_system.locate.locate_id
  IS NOT NULL                        AS "exists",
cult_system.locate.locate_id
  IS NULL                            AS not_exists
FROM cult_system.projectmod
LEFT JOIN cult_system.project modify ON cult_system.projectmod.project_id  = modify.project_id
LEFT JOIN cult_system.build          ON modify.project_id                  = cult_system.build.project_id
LEFT JOIN cult_system.decision       ON cult_system.projectmod.decision_id = cult_system.decision.decision_id
LEFT JOIN cult_system.component      ON cult_system.decision.component_id  = cult_system.component.component_id
LEFT JOIN cult_system.config         ON cult_system.component.config_id    = cult_system.config.config_id
LEFT JOIN cult_system.locate         ON cult_system.decision.decision_id   = cult_system.locate.decision_id
LEFT JOIN cult_system.project        ON cult_system.decision.project_id    = cult_system.project.project_id;


CREATE OR REPLACE VIEW cult_system.mods AS SELECT DISTINCT
cult_system.component.component_id AS component_id,
cult_system.component.class        AS class,
cult_system.component.cache        AS cache,
cult_system.config.class           AS config,
cult_system.language.lang_id       AS lang_id,
cult_system.language.name          AS lang,
cult_system.language.title         AS language,
cult_system.component.title->>cult_system.language.name
                                   AS title,
cult_system.component.singleton    AS singleton,
CASE
	WHEN cult_system.decision.decision_id IS NULL THEN 1
	WHEN cult_system.component.singleton THEN 0
	ELSE 1
END                                AS is_free,
cult_system.decision.decision_id
  IS NOT NULL                      AS is_decision
FROM cult_system.component
JOIN cult_system.language      ON cult_system.language.status        = 0
LEFT JOIN cult_system.config   ON cult_system.component.config_id    = cult_system.config.config_id
LEFT JOIN cult_system.decision ON cult_system.component.component_id = cult_system.decision.component_id;


CREATE OR REPLACE VIEW cult_system.navs AS SELECT
cult_system.navigate.locate_id    AS locate_id,
cult_system.locate.title          AS locate,
cult_system.navigate.menu_id      AS menu_id,
cult_system.markup.markup         AS markup,
cult_system.menu.active           AS active,
cult_system.menu.title            AS menu,
cult_system.menu.status           AS status,
cult_system.locate.decision_id    AS decision_id,
cult_system.decision.component_id AS component_id,
cult_system.locate.build_id       AS build_id,
cult_system.build.project_id      AS project_id,
cult_system.decision.name         AS name,
cult_system.decision.title        AS decision,
cult_system.component.class       AS class,
cult_system.config.class          AS config,
cult_system.project.class         AS class_project,
cult_system.component.title       AS component,
cult_system.build.title           AS build,
cult_system.project.title         AS project
FROM cult_system.navigate
LEFT JOIN cult_system.menu        ON cult_system.navigate.menu_id      = cult_system.menu.menu_id
LEFT JOIN cult_system.markup      ON cult_system.menu.markup_id        = cult_system.markup.markup_id
LEFT JOIN cult_system.locate      ON cult_system.navigate.locate_id    = cult_system.locate.locate_id
LEFT JOIN cult_system.decision    ON cult_system.locate.decision_id    = cult_system.decision.decision_id
LEFT JOIN cult_system.component   ON cult_system.decision.component_id = cult_system.component.component_id
LEFT JOIN cult_system.config      ON cult_system.component.config_id   = cult_system.config.config_id
LEFT JOIN cult_system.build       ON cult_system.locate.build_id       = cult_system.build.build_id
LEFT JOIN cult_system.project     ON cult_system.build.project_id      = cult_system.project.project_id;


CREATE OR REPLACE VIEW cult_system.perms AS SELECT
cult_system.role.role_id        AS role_id,
cult_system.role.title->>cult_system.language.name
                                AS role,
cult_system.role.status         AS role_status,
cult_system.role.nocache        AS nocache,
cult_system.group.group_id      AS group_id,
cult_system.group.title->>cult_system.language.name
                                AS group,
cult_system.group.users_limit   AS group_limit,
cult_system.group.status        AS group_status,
cult_system.user.user_id        AS user_id,
cult_system.user.login          AS login,
cult_system.language.lang_id    AS lang_id,
cult_system.language.name       AS lang,
cult_system.language.title      AS language
FROM cult_system.permit
JOIN cult_system.language     ON cult_system.language.status  = 0
LEFT JOIN cult_system.role    ON cult_system.permit.role_id   = cult_system.role.role_id
LEFT JOIN cult_system.group   ON cult_system.permit.group_id  = cult_system.group.group_id
LEFT JOIN cult_system.team    ON cult_system.group.group_id   = cult_system.team.group_id
RIGHT JOIN cult_system.user   ON cult_system.team.user_id     = cult_system.user.user_id;


CREATE OR REPLACE VIEW cult_system.plugins AS SELECT
cult_system.plugin.plugin_id AS id,
cult_system.plugin.plugin_id AS plugin_id,
cult_system.plugin.config_id AS config_id,
cult_system.plugin.title->>cult_system.language.name
                             AS title,
cult_system.config.class     AS config,
cult_system.plugin.class     AS class,
cult_system.plugin.status    AS status,
cult_system.language.lang_id AS lang_id,
cult_system.language.name    AS lang,
cult_system.language.title   AS language
FROM cult_system.plugin
JOIN cult_system.language    ON cult_system.language.status  = 0
LEFT JOIN cult_system.config ON cult_system.plugin.config_id = cult_system.config.config_id;


CREATE OR REPLACE VIEW cult_system.privileges AS SELECT
cult_system.privilege.privilege_id    AS privilege_id,
cult_system.privilege.event_id        AS event_id,
cult_system.privilege.locate_id       AS locate_id,
cult_system.event.name                AS name,
cult_system.event.title               AS event,
cult_system.event.access              AS access,
cult_system.event.component_id        AS event_component_id,
"e_com".title                         AS event_component,
"e_com".class                         AS event_component_class,
"e_cfg".class                         AS event_component_config,
cult_system.locate.decision_id        AS decision_id,
cult_system.locate.serial             AS serial,
"l_com".component_id                  AS component_id,
cult_system.locate.build_id           AS build_id,
cult_system.build.project_id          AS project_id,
cult_system.decision.name             AS decision_name,
cult_system.decision.title            AS decision,
cult_system.locate.title              AS title,
"l_com".class                         AS class,
"l_cfg".class                         AS config,
cult_system.project.class             AS class_project,
"l_com".title                         AS component,
cult_system.build.title               AS build,
cult_system.project.title             AS project,
"l_com".singleton                     AS singleton
FROM cult_system.privilege
LEFT JOIN cult_system.event           ON cult_system.privilege.event_id    = cult_system.event.event_id
LEFT JOIN cult_system.component e_com ON cult_system.event.component_id    = e_com.component_id
LEFT JOIN cult_system.config e_cfg    ON e_com.config_id                   = e_cfg.config_id
LEFT JOIN cult_system.locate          ON cult_system.privilege.locate_id   = cult_system.locate.locate_id
LEFT JOIN cult_system.decision        ON cult_system.locate.decision_id    = cult_system.decision.decision_id
LEFT JOIN cult_system.component l_com ON cult_system.decision.component_id = l_com.component_id
LEFT JOIN cult_system.config l_cfg    ON l_com.config_id                   = l_cfg.config_id
LEFT JOIN cult_system.build           ON cult_system.locate.build_id       = cult_system.build.build_id
LEFT JOIN cult_system.project         ON cult_system.build.project_id      = cult_system.project.project_id;


CREATE OR REPLACE VIEW cult_system.projects AS SELECT DISTINCT
cult_system.project.project_id         AS project_id,
cult_system.project.config_id          AS config_id,
cult_system.project.code               AS code,
cult_system.project.class              AS class,
cult_system.config.class               AS config,
cult_system.project.title->>cult_system.language.name
                                       AS title,
cult_system.project.singleton          AS singleton,
cult_system.project.open               AS open,
cult_system.build.build_id IS NOT NULL AS is_build,
cult_system.project.open AND (
  cult_system.project.singleton OR cult_system.build.build_id IS NULL
)                                      AS is_free,
cult_system.language.lang_id           AS lang_id,
cult_system.language.name              AS lang,
cult_system.language.title             AS language
FROM cult_system.project
JOIN cult_system.language    ON cult_system.language.status    = 0
LEFT JOIN cult_system.config ON cult_system.project.config_id  = cult_system.config.config_id
LEFT JOIN cult_system.build  ON cult_system.project.project_id = cult_system.build.project_id;


CREATE OR REPLACE VIEW cult_system.references AS SELECT
cult_system.reference.reference_id AS reference_id,
CASE
  WHEN cult_system.reference.event_id IS NULL THEN 0
  ELSE cult_system.reference.event_id
END                                AS event_id,
cult_system.reference.url          AS url,
cult_system.reference.text->>cult_system.language.name
                                   AS text,
cult_system.reference.active->>cult_system.language.name
                                   AS active,
cult_system.reference.title->>cult_system.language.name
                                   AS title,
cult_system.reference.status       AS status,
cult_system.locate.locate_id       AS locate_id,
cult_system.locate.decision_id     AS decision_id,
cult_system.locate.serial          AS serial,
cult_system.decision.component_id  AS component_id,
cult_system.locate.build_id        AS build_id,
cult_system.build.project_id       AS project_id,
cult_system.decision.name          AS name,
cult_system.decision.title->>cult_system.language.name
                                   AS decision,
cult_system.locate.title->>cult_system.language.name
                                   AS locate,
cult_system.component.class        AS class,
cult_system.config.class           AS config,
cult_system.project.class          AS class_project,
cult_system.component.title->>cult_system.language.name
                                   AS component,
cult_system.build.title->>cult_system.language.name
                                   AS build,
cult_system.project.title->>cult_system.language.name
                                   AS project,
cult_system.language.lang_id       AS lang_id,
cult_system.language.name          AS lang,
cult_system.language.title         AS language
FROM cult_system.reference
JOIN cult_system.language          ON cult_system.language.status       = 0
LEFT JOIN cult_system.locate       ON cult_system.reference.locate_id   = cult_system.locate.locate_id
LEFT JOIN cult_system.decision     ON cult_system.locate.decision_id    = cult_system.decision.decision_id
LEFT JOIN cult_system.component    ON cult_system.decision.component_id = cult_system.component.component_id
LEFT JOIN cult_system.config       ON cult_system.component.config_id   = cult_system.config.config_id
LEFT JOIN cult_system.build        ON cult_system.locate.build_id       = cult_system.build.build_id
LEFT JOIN cult_system.project      ON cult_system.build.project_id      = cult_system.project.project_id;


CREATE OR REPLACE VIEW cult_system.roles AS SELECT
cult_system.role.role_id     AS role_id,
cult_system.role.code        AS code,
cult_system.role.title->>cult_system.language.name
                             AS title,
cult_system.role.nocache     AS nocache,
cult_system.role.status      AS status,
cult_system.language.lang_id AS lang_id,
cult_system.language.name    AS lang,
cult_system.language.title   AS language
FROM cult_system.role
JOIN cult_system.language ON cult_system.language.status = 0;


CREATE OR REPLACE VIEW cult_system.sample AS SELECT
cult_system.decision.decision_id   AS decision_id,
cult_system.decision.project_id    AS project_id,
cult_system.decision.name          AS name,
cult_system.decision.title->>cult_system.language.name
                                   AS title,
cult_system.project.class          AS project_class,
cult_system.project.title->>cult_system.language.name
                                   AS project,
cult_system.project.singleton      AS project_singleton,
cult_system.component.component_id AS component_id,
cult_system.component.class        AS component_class,
cult_system.component.title->>cult_system.language.name
                                   AS component_title,
cult_system.config.class           AS config,
cult_system.config.title->>cult_system.language.name
                                   AS config_title,
cult_system.component.singleton    AS component_singleton,
CASE cult_system.locate.locate_id
  WHEN NULL THEN 0
	ELSE cult_system.locate.locate_id
END                                AS locate_id,
cult_system.locate.locate_id
  IS NOT NULL                      AS "exists",
cult_system.locate.locate_id
  IS NULL                          AS not_exists,
cult_system.language.lang_id       AS lang_id,
cult_system.language.name          AS lang,
cult_system.language.title         AS language
FROM cult_system.decision
JOIN cult_system.language       ON cult_system.language.status       = 0
LEFT JOIN cult_system.project   ON cult_system.decision.project_id   = cult_system.project.project_id
LEFT JOIN cult_system.component ON cult_system.decision.component_id = cult_system.component.component_id
LEFT JOIN cult_system.config    ON cult_system.component.config_id   = cult_system.config.config_id
LEFT JOIN cult_system.locate    ON cult_system.decision.decision_id  = cult_system.locate.decision_id;


CREATE OR REPLACE VIEW cult_system.schema AS SELECT
cult_system.locate.locate_id       AS locate_id,
cult_system.locate.build_id        AS build_id,
cult_system.locate.serial          AS serial,
cult_system.build.title->>cult_system.language.name
                                   AS build,
cult_system.decision.decision_id   AS decision_id,
cult_system.decision.project_id    AS project_id,
cult_system.decision.name          AS name,
cult_system.decision.title->>cult_system.language.name
                                   AS title,
cult_system.project.class          AS project_class,
cult_system.project.title->>cult_system.language.name
                                   AS project,
cult_system.project.singleton      AS project_singleton,
cult_system.component.component_id AS component_id,
cult_system.component.class        AS component_class,
cult_system.component.title->>cult_system.language.name
                                   AS component_title,
cult_system.config.class           AS config,
cult_system.config.title->>cult_system.language.name
                                   AS config_title,
cult_system.component.singleton    AS component_singleton,
cult_system.language.lang_id       AS lang_id,
cult_system.language.name          AS lang,
cult_system.language.title         AS language
FROM cult_system.locate
JOIN cult_system.language       ON cult_system.language.status       = 0
LEFT JOIN cult_system.build     ON cult_system.locate.build_id       = cult_system.build.build_id
LEFT JOIN cult_system.decision  ON cult_system.locate.decision_id    = cult_system.decision.decision_id
LEFT JOIN cult_system.project   ON cult_system.decision.project_id   = cult_system.project.project_id
LEFT JOIN cult_system.component ON cult_system.decision.component_id = cult_system.component.component_id
LEFT JOIN cult_system.config    ON cult_system.component.config_id   = cult_system.config.config_id;


CREATE OR REPLACE VIEW cult_system.teams AS SELECT
cult_system.user.user_id        AS user_id,
cult_system.user.login          AS login,
cult_system.group.group_id      AS group_id,
cult_system.group.title->>cult_system.language.name
                                AS group,
cult_system.group.users_limit   AS group_limit,
cult_system.group.status        AS group_status,
cult_system.role.role_id        AS role_id,
cult_system.role.title->>cult_system.language.name
                                AS role,
cult_system.role.status         AS role_status
FROM cult_system.team
JOIN cult_system.language     ON cult_system.language.status  = 0
LEFT JOIN cult_system.group   ON cult_system.team.group_id    = cult_system.group.group_id
LEFT JOIN cult_system.permit  ON cult_system.group.group_id   = cult_system.permit.group_id
LEFT JOIN cult_system.role    ON cult_system.permit.role_id   = cult_system.role.role_id
LEFT JOIN cult_system.user    ON cult_system.team.user_id     = cult_system.user.user_id;


CREATE OR REPLACE VIEW cult_system.users AS SELECT
cult_system.user.user_id        AS user_id,
cult_system.user.login          AS login,
cult_system.user.email          AS email,
cult_system.user.phone          AS phone,
cult_system.user.photo          AS photo,
cult_system.user.status         AS user_status,
cult_system.group.group_id      AS group_id,
cult_system.group.title->>cult_system.language.name
                                AS group,
cult_system.group.users_limit   AS users_limit,
cult_system.group.status        AS group_status,
cult_system.role.role_id        AS role_id,
cult_system.role.title->>cult_system.language.name
                                AS role,
cult_system.role.status         AS role_status
FROM cult_system.user
JOIN cult_system.language      ON cult_system.language.status  = 0
LEFT JOIN cult_system.team     ON cult_system.user.user_id     = cult_system.team.user_id
LEFT JOIN cult_system.group    ON cult_system.team.group_id    = cult_system.group.group_id
LEFT JOIN cult_system.permit   ON cult_system.group.group_id   = cult_system.permit.group_id
LEFT JOIN cult_system.role     ON cult_system.permit.role_id   = cult_system.role.role_id;


CREATE OR REPLACE VIEW cult_system.views AS SELECT
cult_system.view.control_id            AS control_id,
cult_system.view.target                AS target,
cult_system.view.locate_id             AS source,
"source".title                         AS locate,
"src_dec".title                        AS dec_title,
"src_build".title                      AS build,
"src_dec".name                         AS src_name,
"src_dec".title                        AS src_dec,
"src_pro".title                        AS src_project,
cult_system.group.group_id             AS group_id,
cult_system.group.status               AS group_status,
cult_system.role.status                AS role_status,
cult_system.control.event_id           AS event_id,
"target".build_id                      AS build_id,
"target".title                         AS target_title,
cult_system.decision.title             AS destination,
cult_system.control.class              AS class,
cult_system.event.name                 AS event,
cult_system.event.access               AS access,
cult_system.control.title              AS title,
cult_system.decision.name              AS name,
cult_system.decision.title             AS decision,
cult_system.project.project_id         AS project_id,
cult_system.project.class              AS project_class,
cult_system.project.title              AS project
FROM cult_system.view
LEFT JOIN cult_system.control          ON cult_system.view.control_id     = cult_system.control.control_id
LEFT JOIN cult_system.event            ON cult_system.control.event_id    = cult_system.event.event_id
LEFT JOIN cult_system.locate source    ON cult_system.view.locate_id      = source.locate_id
LEFT JOIN cult_system.build src_build  ON source.build_id                 = src_build.build_id
LEFT JOIN cult_system.decision src_dec ON source.decision_id              = src_dec.decision_id
LEFT JOIN cult_system.project src_pro  ON src_dec.project_id              = src_pro.project_id
LEFT JOIN cult_system.locate target    ON cult_system.view.target         = target.locate_id
LEFT JOIN cult_system.build            ON target.build_id                 = cult_system.build.build_id
LEFT JOIN cult_system.decision         ON target.decision_id              = cult_system.decision.decision_id
LEFT JOIN cult_system.project          ON cult_system.decision.project_id = cult_system.project.project_id
LEFT JOIN cult_system.access           ON cult_system.view.target         = cult_system.access.locate_id
LEFT JOIN cult_system.role             ON cult_system.access.role_id      = cult_system.role.role_id
LEFT JOIN cult_system.permit           ON cult_system.role.role_id        = cult_system.permit.role_id
LEFT JOIN cult_system.group            ON cult_system.permit.group_id     = cult_system.group.group_id;


CREATE OR REPLACE VIEW cult_system.rbac_map AS SELECT
cult_system.locate.locate_id   AS locate_id,
CASE cult_system.locate.name
  WHEN '' THEN CONCAT(cult_system.decision.name, cult_system.locate.locate_id)
	ELSE cult_system.locate.name
END                            AS name,
cult_system.locate.serial      AS serial,
cult_system.group.group_id     AS group_id,
cult_system.role.role_id       AS role_id,
cult_system.group.status       AS group_status,
cult_system.role.status        AS role_status
FROM cult_system.access
LEFT JOIN cult_system.role     ON cult_system.access.role_id     = cult_system.role.role_id
LEFT JOIN cult_system.permit   ON cult_system.role.role_id       = cult_system.permit.role_id
LEFT JOIN cult_system.group    ON cult_system.permit.group_id    = cult_system.group.group_id
LEFT JOIN cult_system.locate   ON cult_system.access.locate_id   = cult_system.locate.locate_id
LEFT JOIN cult_system.decision ON cult_system.locate.decision_id = cult_system.decision.decision_id;


CREATE OR REPLACE VIEW cult_system.rbac_maps AS SELECT
cult_system.locate.locate_id       AS locate_id,
cult_system.component.component_id AS component_id,
cult_system.locate.serial          AS serial,
cult_system.group.group_id         AS group_id,
cult_system.role.role_id           AS role_id,
cult_system.group.status           AS group_status,
cult_system.role.status            AS role_status
FROM cult_system.access
LEFT JOIN cult_system.role         ON cult_system.access.role_id        = cult_system.role.role_id
LEFT JOIN cult_system.permit       ON cult_system.role.role_id          = cult_system.permit.role_id
LEFT JOIN cult_system.group        ON cult_system.permit.group_id       = cult_system.group.group_id
LEFT JOIN cult_system.locate       ON cult_system.access.locate_id      = cult_system.locate.locate_id
LEFT JOIN cult_system.decision     ON cult_system.locate.decision_id    = cult_system.decision.decision_id
LEFT JOIN cult_system.component    ON cult_system.decision.component_id = cult_system.component.component_id;


CREATE OR REPLACE VIEW cult_system.rbac_schema AS SELECT
cult_system.locate.locate_id       AS locate_id,
cult_system.locate.build_id        AS build_id,
cult_system.locate.serial          AS serial,
CASE
  WHEN cult_system.component.cache AND cult_system.decision.cache THEN cult_system.locate.cache
	ELSE FALSE
END                                AS cache,
cult_system.decision.decision_id   AS decision_id,
cult_system.decision.project_id    AS project_id,
cult_system.locate.name            AS name,
cult_system.project.class          AS project_class,
cult_system.project.config_id      AS project_config_id,
"c1".class                         AS project_config,
cult_system.component.component_id AS component_id,
cult_system.component.class        AS component_class,
cult_system.component.config_id    AS config_id,
"c2".class                         AS config
FROM cult_system.locate
LEFT JOIN cult_system.decision     ON cult_system.locate.decision_id    = cult_system.decision.decision_id
LEFT JOIN cult_system.project      ON cult_system.decision.project_id   = cult_system.project.project_id
LEFT JOIN cult_system.config AS c1 ON cult_system.project.config_id     = c1.config_id
LEFT JOIN cult_system.component    ON cult_system.decision.component_id = cult_system.component.component_id
LEFT JOIN cult_system.config AS c2 ON cult_system.component.config_id   = c2.config_id
LEFT JOIN cult_system.build        ON cult_system.locate.build_id       = cult_system.build.build_id;


CREATE OR REPLACE VIEW cult_system.rbac_matrix AS SELECT
cult_system.privilege.locate_id    AS locate_id,
cult_system.locate.name            AS name,
cult_system.component.component_id AS component_id,
cult_system.event.event_id         AS event_id,
cult_system.event.name             AS event,
cult_system.config.class           AS config,
cult_system.event.access           AS access,
cult_system.group.group_id         AS group_id,
cult_system.role.role_id           AS role_id,
cult_system.group.status           AS group_status,
cult_system.role.status            AS role_status
FROM cult_system.rule
LEFT JOIN cult_system.role         ON cult_system.rule.role_id        = cult_system.role.role_id
LEFT JOIN cult_system.permit       ON cult_system.role.role_id        = cult_system.permit.role_id
LEFT JOIN cult_system.group        ON cult_system.permit.group_id     = cult_system.group.group_id
LEFT JOIN cult_system.privilege    ON cult_system.rule.privilege_id   = cult_system.privilege.privilege_id
LEFT JOIN cult_system.event        ON cult_system.privilege.event_id  = cult_system.event.event_id
LEFT JOIN cult_system.component    ON cult_system.event.component_id  = cult_system.component.component_id
LEFT JOIN cult_system.config       ON cult_system.component.config_id = cult_system.config.config_id
LEFT JOIN cult_system.locate       ON cult_system.privilege.locate_id = cult_system.locate.locate_id;


CREATE OR REPLACE VIEW cult_system.rbac_views   AS SELECT
cult_system.view.control_id       AS control_id,
cult_system.control.config_id     AS config_id,
cult_system.decision.component_id AS component_id,
cult_system.view.target           AS target,
cult_system.locate.name           AS name,
cult_system.view.locate_id        AS source,
cult_system.group.group_id        AS group_id,
cult_system.role.role_id          AS role_id,
cult_system.control.class         AS class,
cult_system.config.class          AS config,
cult_system.control.self          AS self,
cult_system.event.name            AS event,
cult_system.event.access          AS access,
cult_system.group.status          AS group_status,
cult_system.role.status           AS role_status,
cult_system.view.serial           AS serial
FROM cult_system.view
LEFT JOIN cult_system.control     ON cult_system.view.control_id    = cult_system.control.control_id
LEFT JOIN cult_system.config      ON cult_system.control.config_id  = cult_system.config.config_id
LEFT JOIN cult_system.event       ON cult_system.control.event_id   = cult_system.event.event_id
LEFT JOIN cult_system.access      ON cult_system.view.target        = cult_system.access.locate_id
LEFT JOIN cult_system.role        ON cult_system.access.role_id     = cult_system.role.role_id
LEFT JOIN cult_system.permit      ON cult_system.role.role_id       = cult_system.permit.role_id
LEFT JOIN cult_system.group       ON cult_system.permit.group_id    = cult_system.group.group_id
LEFT JOIN cult_system.locate      ON cult_system.view.target        = cult_system.locate.locate_id
LEFT JOIN cult_system.decision    ON cult_system.locate.decision_id = cult_system.decision.decision_id;


CREATE OR REPLACE VIEW cult_system.rbac_additions AS SELECT
cult_system.addon.locate_id    AS locate_id,
cult_system.plugin.plugin_id   AS plugin_id,
cult_system.plugin.config_id   AS config_id,
cult_system.group.group_id     AS group_id,
cult_system.role.role_id       AS role_id,
cult_system.group.status       AS group_status,
cult_system.role.status        AS role_status,
cult_system.config.class       AS config,
cult_system.plugin.class       AS class,
cult_system.addon.active       AS active,
cult_system.addon.serial       AS serial		
FROM cult_system.addon
LEFT JOIN cult_system.plugin   ON cult_system.addon.plugin_id  = cult_system.plugin.plugin_id
LEFT JOIN cult_system.attach   ON cult_system.plugin.plugin_id = cult_system.attach.plugin_id
LEFT JOIN cult_system.role     ON cult_system.attach.role_id   = cult_system.role.role_id
LEFT JOIN cult_system.permit   ON cult_system.role.role_id     = cult_system.permit.role_id
LEFT JOIN cult_system.group    ON cult_system.permit.group_id  = cult_system.group.group_id
LEFT JOIN cult_system.config   ON cult_system.plugin.config_id = cult_system.config.config_id;


CREATE OR REPLACE VIEW cult_system.rbac_locs AS SELECT
cult_system.locate.locate_id       AS locate_id,
cult_system.component.component_id AS component_id,
cult_system.component.role_id      AS role_id,
cult_system.locate.decision_id     AS decision_id,
cult_system.locate.build_id        AS build_id,
cult_system.build.project_id       AS project_id,
cult_system.locate.serial          AS serial,
cult_system.decision.name          AS decision,
cult_system.config.config_id       AS config_id,		
CASE cult_system.locate.name
  WHEN '' THEN CONCAT(cult_system.decision.name, cult_system.locate.locate_id)
  ELSE cult_system.locate.name
END                                AS name,
cult_system.config.class           AS config,		
CASE
  WHEN cult_system.component.cache AND cult_system.decision.cache THEN cult_system.locate.cache
  ELSE FALSE
END                                AS cache,
cult_system.component.singleton    AS singleton
FROM cult_system.locate
LEFT JOIN cult_system.decision     ON cult_system.locate.decision_id    = cult_system.decision.decision_id
LEFT JOIN cult_system.component    ON cult_system.decision.component_id = cult_system.component.component_id
LEFT JOIN cult_system.config       ON cult_system.component.config_id   = cult_system.config.config_id
LEFT JOIN cult_system.build        ON cult_system.locate.build_id       = cult_system.build.build_id;


CREATE OR REPLACE VIEW cult_system.rbac_events AS SELECT
cult_system.locate.locate_id       AS locate_id,
cult_system.component.component_id AS component_id,
cult_system.event.event_id         AS event_id,
cult_system.event.name             AS event,
cult_system.event.title->>cult_system.language.name
                                   AS title,
cult_system.event.access           AS access,
cult_system.event.cache            AS cache,
cult_system.event.nav              AS nav,
cult_system.language.lang_id       AS lang_id,
cult_system.language.name          AS lang,
cult_system.language.title         AS language
FROM cult_system.locate
JOIN cult_system.language          ON cult_system.language.status        = 0
LEFT JOIN cult_system.decision     ON cult_system.locate.decision_id     = cult_system.decision.decision_id
LEFT JOIN cult_system.component    ON cult_system.decision.component_id  = cult_system.component.component_id
RIGHT JOIN cult_system.event       ON cult_system.component.component_id = cult_system.event.component_id;


CREATE OR REPLACE VIEW cult_system.rbac_navs AS SELECT
cult_system.navigate.locate_id AS locate_id,
cult_system.navigate.menu_id   AS menu_id,
cult_system.markup.markup      AS markup
FROM cult_system.navigate
LEFT JOIN cult_system.menu     ON cult_system.navigate.menu_id = cult_system.menu.menu_id
LEFT JOIN cult_system.markup   ON cult_system.menu.markup_id   = cult_system.markup.markup_id;


CREATE OR REPLACE VIEW cult_system.rbac_items AS SELECT DISTINCT
cult_system.menuitem.item_id    AS item_id,
cult_system.reference.locate_id AS locate_id,
cult_system.reference.event_id  AS event_id,
CASE
  WHEN cult_system.reference.locate_id = 0 OR cult_system.reference.locate_id IS NULL THEN 0
	ELSE cult_system.group.group_id
END                             AS group_id,
CASE
	WHEN cult_system.reference.locate_id = 0 OR cult_system.reference.locate_id IS NULL THEN 0
	ELSE cult_system.group.status
END                             AS group_status,
CASE
	WHEN cult_system.reference.locate_id = 0 OR cult_system.reference.locate_id IS NULL THEN 0
	ELSE cult_system.role.status
END                             AS role_status,
cult_system.menuitem.menu_id    AS menu_id,
CASE
  WHEN cult_system.menuitem.role_id IS NULL THEN 0
  ELSE cult_system.menuitem.role_id
END                             AS role_id,
CASE
  WHEN cult_system.menuitem.submenu_id IS NULL THEN 0
  ELSE cult_system.menuitem.submenu_id
END                             AS submenu_id,
cult_system.menuitem.serial     AS serial,
cult_system.menuitem.icon       AS icon,
cult_system.menuitem.empty      AS empty,
cult_system.menuitem.follow     AS follow,
cult_system.menuitem.blank      AS blank,
cult_system.reference.url       AS url,
cult_system.project.class       AS project,
cult_system.locate.name         AS locate,
cult_system.event.name          AS event,
cult_system.reference.value     AS value,
cult_system.reference.text      AS text,
cult_system.reference.active    AS active,
cult_system.reference.title     AS reference,
cult_system.event.title         AS event_title,
cult_system.locate.title        AS locate_title,
cult_system.reference.status + cult_system.menuitem.status
                                AS status,
CASE cult_system.menu.active
  WHEN TRUE THEN cult_system.menuitem.active
	ELSE FALSE
END                             AS item
FROM cult_system.menuitem
LEFT JOIN cult_system.reference ON cult_system.menuitem.reference_id = cult_system.reference.reference_id
LEFT JOIN cult_system.event     ON cult_system.reference.event_id    = cult_system.event.event_id
LEFT JOIN cult_system.locate    ON cult_system.reference.locate_id   = cult_system.locate.locate_id
LEFT JOIN cult_system.build     ON cult_system.locate.build_id       = cult_system.build.build_id
LEFT JOIN cult_system.project   ON cult_system.build.project_id      = cult_system.project.project_id
LEFT JOIN cult_system.access    ON cult_system.locate.locate_id      = cult_system.access.locate_id
LEFT JOIN cult_system.role      ON cult_system.role.role_id          = cult_system.access.role_id
LEFT JOIN cult_system.permit    ON cult_system.permit.role_id        = cult_system.role.role_id
LEFT JOIN cult_system.group     ON cult_system.group.group_id        = cult_system.permit.group_id
LEFT JOIN cult_system.menu      ON cult_system.menuitem.menu_id      = cult_system.menu.menu_id;


CREATE OR REPLACE VIEW cult_system.rbac_modifies AS SELECT DISTINCT
cult_system.build.build_id           AS build_id,
CASE cult_system.locate.locate_id
  WHEN NULL THEN 0
	ELSE cult_system.locate.locate_id
END                                  AS locate_id
FROM cult_system.projectmod
LEFT JOIN cult_system.project modify ON cult_system.projectmod.project_id  = modify.project_id
LEFT JOIN cult_system.build          ON modify.project_id                  = cult_system.build.project_id
LEFT JOIN cult_system.decision       ON cult_system.projectmod.decision_id = cult_system.decision.decision_id
LEFT JOIN cult_system.locate         ON cult_system.decision.decision_id   = cult_system.locate.decision_id;

/*
CREATE OR REPLACE VIEW cult_system.config_keys AS SELECT
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
FROM cult_system.config_option
LEFT JOIN config_option_ml ON config_option.option_id  = config_option_ml.option_id;
*/