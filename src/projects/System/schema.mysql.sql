
-- Cult Project Schema for MySQL Server only.
-- Tested on MySQL 8.3.

-- Over time, MySQL and MariaDB servers have lost much of their compatibility,
-- so the MySQL schema does not work on MariaDB servers.
-- This schema is not suitable for deployment on MariaDB servers.

CREATE TABLE IF NOT EXISTS language (
  lang_id tinyint unsigned NOT NULL AUTO_INCREMENT,
  name char(2) NOT NULL,
  title_path char(4) GENERATED ALWAYS AS (CONCAT('$.', name)) STORED NOT NULL,
  title varchar(63) NOT NULL DEFAULT '',
  status tinyint unsigned NOT NULL DEFAULT 0 CHECK (status < 8),
  PRIMARY KEY language_pkey (lang_id),
  UNIQUE KEY language_name (name),
  UNIQUE KEY language_json_path (title_path)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Язык интерфейса';

CREATE TABLE IF NOT EXISTS config (
  config_id smallint unsigned NOT NULL AUTO_INCREMENT,
  class varchar(127) NOT NULL,
  title json NOT NULL CHECK (JSON_VALID(title)),
  PRIMARY KEY config_pkey (config_id),
  UNIQUE KEY config_class (class)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Конфигурация класса';

CREATE TABLE IF NOT EXISTS config_type (
  type_id tinyint unsigned NOT NULL AUTO_INCREMENT,
  type varchar(31) NOT NULL DEFAULT '',
  status tinyint unsigned NOT NULL DEFAULT 0 CHECK (status < 8),
  PRIMARY KEY config_type_pkey (type_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Тип конфигурации';

CREATE TABLE IF NOT EXISTS config_slice (
  slice_id smallint unsigned NOT NULL AUTO_INCREMENT,
  slice varchar(63) NOT NULL DEFAULT '',
  title json NOT NULL CHECK (JSON_VALID(title)),
  serial smallint unsigned NOT NULL DEFAULT 1000,
  PRIMARY KEY config_slice_pkey (slice_id),
  UNIQUE KEY config_slice (slice),
  KEY config_slice_serial (serial)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Срез конфигурации';

CREATE TABLE IF NOT EXISTS role (
  role_id smallint unsigned NOT NULL AUTO_INCREMENT,
  code char(3) NOT NULL COMMENT 'Трехбуквенный код роли',
  title json NOT NULL CHECK (JSON_VALID(title)),
  status tinyint unsigned NOT NULL DEFAULT 0 CHECK (status < 16),
  nocache tinyint unsigned NOT NULL DEFAULT 0 CHECK (nocache < 2),
  PRIMARY KEY role_pkey (role_id),
  UNIQUE KEY role_code (code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Роль.';

CREATE TABLE IF NOT EXISTS config_option (
  option_id smallint unsigned NOT NULL AUTO_INCREMENT,
  config_id smallint unsigned NOT NULL,
  slice_id smallint unsigned NOT NULL,
  type_id tinyint unsigned NOT NULL,
  role_id smallint unsigned NOT NULL,
  title json NOT NULL CHECK (JSON_VALID(title)),
  serial smallint unsigned NOT NULL DEFAULT 1000,
  global tinyint unsigned NOT NULL DEFAULT 0 CHECK (global < 2),
  active tinyint unsigned NOT NULL DEFAULT 1 CHECK (active < 2),
  name varchar(63) NOT NULL DEFAULT '',
  input varchar(63) NOT NULL DEFAULT '',
  output varchar(63) NOT NULL DEFAULT '',
  PRIMARY KEY config_option_pkey (option_id),
  UNIQUE KEY option_config (config_id, name),
  KEY option_name (name),
  KEY option_slice (slice_id),
  KEY option_type (type_id),
  KEY option_role (role_id),
  KEY option_serial (serial),
  FOREIGN KEY option_config_fkey (config_id) REFERENCES config (config_id),
  FOREIGN KEY option_slice_fkey (slice_id) REFERENCES config_slice (slice_id),
  FOREIGN KEY option_type_fkey (type_id) REFERENCES config_type (type_id),
  FOREIGN KEY option_role_fkey (role_id) REFERENCES role (role_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Опция конфигурации';

CREATE TABLE IF NOT EXISTS component (
  component_id smallint unsigned NOT NULL AUTO_INCREMENT COMMENT 'Идентификатор компонента',
  config_id smallint unsigned NOT NULL COMMENT 'Идентификатор класса конфигурации',
  role_id smallint unsigned NOT NULL DEFAULT 0 COMMENT 'Идентификатор роли поумолчанию назначаемой при имплементации компонента',
  class varchar(127) NOT NULL COMMENT 'Класс компонента',
  title json NOT NULL CHECK (JSON_VALID(title)),
  cache tinyint unsigned NOT NULL DEFAULT 1 CHECK (cache < 2),
  singleton tinyint unsigned NOT NULL DEFAULT 1 CHECK (singleton < 2),
  PRIMARY KEY component_pkey (component_id),
  UNIQUE KEY component_class (class),
  UNIQUE KEY component_config (config_id),
  KEY component_role (role_id),
  FOREIGN KEY component_config_fkey (config_id) REFERENCES config (config_id),
  FOREIGN KEY component_role_fkey (role_id) REFERENCES role (role_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Компонент';

CREATE TABLE IF NOT EXISTS event (
  event_id int unsigned NOT NULL AUTO_INCREMENT COMMENT 'Идентификатор события или группы событий с требованием доступа',
  component_id smallint unsigned NOT NULL COMMENT 'Идентификатор компонента',
  role_id smallint unsigned NOT NULL DEFAULT 0 COMMENT 'Идентификатор роли поумолчанию назначаемой при имплементации компонента',
  name varchar(127) NOT NULL DEFAULT '' COMMENT 'Имя события',
  title json NOT NULL CHECK (JSON_VALID(title)),
  cache tinyint unsigned NOT NULL DEFAULT 0 CHECK (cache < 2),
  access tinyint unsigned NOT NULL DEFAULT 0 CHECK (access < 2),
  nav tinyint unsigned NOT NULL DEFAULT 0 CHECK (nav < 2),
  PRIMARY KEY event_pkey (event_id),
  KEY event_component (component_id),
  KEY event_role (role_id),
  FOREIGN KEY event_component_fkey (component_id) REFERENCES component (component_id),
  FOREIGN KEY event_role_fkey (role_id) REFERENCES role (role_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Событие (группа событий) модуля требующее прав доступа';

CREATE TABLE IF NOT EXISTS project (
  project_id smallint unsigned NOT NULL AUTO_INCREMENT COMMENT 'Идентификатор проект (шаблона) приложения',
  config_id smallint unsigned NOT NULL COMMENT 'Идентификатор класса конфигурации',
  code char(3) NOT NULL COMMENT 'Трехбуквенный код шаблона приложения',
  class varchar(127) NOT NULL COMMENT 'Класс проект (шаблона) приложения',
  `schema` varchar(127) NOT NULL DEFAULT '',
  title json NOT NULL CHECK (JSON_VALID(title)),
  singleton tinyint unsigned NOT NULL DEFAULT 0 CHECK (singleton < 2) COMMENT 'Признак шаблона одиночки',
  open tinyint unsigned NOT NULL DEFAULT 0 CHECK (open < 2) COMMENT 'Открыт для создания приложений',
  PRIMARY KEY project_pkey (project_id),
  UNIQUE KEY project_config (config_id),
  UNIQUE KEY project_code (code),
  UNIQUE KEY project_class (class),
  FOREIGN KEY project_config_fkey (config_id) REFERENCES config (config_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Проект (шаблон) приложения';

CREATE TABLE IF NOT EXISTS decision (
  decision_id smallint unsigned NOT NULL AUTO_INCREMENT COMMENT 'Индекс паттерна локации, позиция модуля в шаблоне',
  project_id smallint unsigned NOT NULL COMMENT 'Идентификатор проекта (шаблона) приложения',
  component_id smallint unsigned NOT NULL COMMENT 'Идентификатор шаблона локации, индекс компонента',
  name varchar(31) NOT NULL DEFAULT '',
  title json NOT NULL CHECK (JSON_VALID(title)),
  cache tinyint unsigned NOT NULL DEFAULT 1 CHECK (cache < 2),
  PRIMARY KEY decision_pkey (decision_id),
  KEY decision_project (project_id),
  KEY decision_component (component_id),
  FOREIGN KEY decision_project_fkey (project_id) REFERENCES project (project_id),
  FOREIGN KEY decision_component_fkey (component_id) REFERENCES component (component_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Паттерн локации. Состав неглобальных модулей в шаблоне прило';

CREATE TABLE IF NOT EXISTS projectmod (
  project_id smallint unsigned NOT NULL,
  decision_id smallint unsigned NOT NULL,
  PRIMARY KEY projectmod_pkey (project_id, decision_id),
  KEY projectmod_decision (decision_id),
  FOREIGN KEY projectmod_project_fkey (project_id) REFERENCES project (project_id),
  FOREIGN KEY projectmod_decision_fkey (decision_id) REFERENCES decision (decision_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Автономные модули задействованные проектом';

CREATE TABLE IF NOT EXISTS build (
  build_id smallint unsigned NOT NULL AUTO_INCREMENT COMMENT 'Идентификатор приложения',
  project_id smallint unsigned NOT NULL COMMENT 'Идентификатор проекта (шаблона) приложения',
  code char(3) NOT NULL COMMENT 'Трехбуквенный уникальный код приложения',
  title json NOT NULL CHECK (JSON_VALID(title)),
  PRIMARY KEY build_pkey (build_id),
  UNIQUE KEY build_code (code),
  KEY build_project (project_id),
  FOREIGN KEY build_project_fkey (project_id) REFERENCES project (project_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Приложение';

CREATE TABLE IF NOT EXISTS locate (
  locate_id smallint unsigned NOT NULL AUTO_INCREMENT COMMENT 'Идентификатор локации',
  decision_id smallint unsigned NOT NULL COMMENT 'Идентификатор проектного решения',
  build_id smallint unsigned NOT NULL COMMENT 'Идентификатор приложения',
  name varchar(31) NOT NULL DEFAULT '',
  title json NOT NULL CHECK (JSON_VALID(title)),
  serial smallint unsigned NOT NULL DEFAULT 1 COMMENT 'Статус локации',
  cache tinyint unsigned NOT NULL DEFAULT 1 CHECK (cache < 2),
  clear varchar(127) NOT NULL DEFAULT '',
  PRIMARY KEY locate_pkey (locate_id),
  KEY locate_decision (decision_id),
  KEY locate_build (build_id),
  KEY locate_name (name),
  KEY locate_serial (serial),
  FOREIGN KEY locate_decision_fkey (decision_id) REFERENCES decision (decision_id),
  FOREIGN KEY locate_build_fkey (build_id) REFERENCES build (build_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Локация';

CREATE TABLE IF NOT EXISTS plugin (
  plugin_id smallint unsigned NOT NULL AUTO_INCREMENT,
  config_id smallint unsigned NOT NULL COMMENT 'Идентификатор класса конфигурации',
  class varchar(127) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  title json NOT NULL CHECK (JSON_VALID(title)),
  status tinyint unsigned NOT NULL DEFAULT 0 CHECK (status < 8),
  PRIMARY KEY plugin_pkey (plugin_id),
  UNIQUE KEY plugin_config (config_id),
  UNIQUE KEY plugin_class (class),
  FOREIGN KEY plugin_config_fkey (config_id) REFERENCES config (config_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Плагин';

CREATE TABLE IF NOT EXISTS access (
  locate_id smallint unsigned NOT NULL,
  role_id smallint unsigned NOT NULL,
  PRIMARY KEY access_pkey (locate_id, role_id),
  KEY access_role (role_id),
  FOREIGN KEY access_locate_fkey (locate_id) REFERENCES locate (locate_id),
  FOREIGN KEY access_role_fkey (role_id) REFERENCES role (role_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Локации доступные для роли';

CREATE TABLE IF NOT EXISTS addon (
  locate_id smallint unsigned NOT NULL,
  plugin_id smallint unsigned NOT NULL,
  serial smallint unsigned NOT NULL DEFAULT 1,
  active tinyint unsigned NOT NULL DEFAULT 1 CHECK (active < 2),
  PRIMARY KEY addon_pkey (locate_id, plugin_id),
  KEY addon_plugin (plugin_id),
  FOREIGN KEY addon_locate_fkey (locate_id) REFERENCES locate (locate_id),
  FOREIGN KEY addon_plugin_fkey (plugin_id) REFERENCES plugin (plugin_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Плагины подключенные к локациям';

CREATE TABLE IF NOT EXISTS attach (
  plugin_id smallint unsigned NOT NULL COMMENT 'Идентификатор плагина',
  role_id smallint unsigned NOT NULL COMMENT 'Идентификатор роли',
  PRIMARY KEY attach_pkey (plugin_id, role_id),
  KEY attach_role (role_id),
  FOREIGN KEY attach_plugin_fkey (plugin_id) REFERENCES plugin (plugin_id),
  FOREIGN KEY attach_role_fkey (role_id) REFERENCES role (role_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Доступ к плагинам';

CREATE TABLE IF NOT EXISTS cache (
  locate_id smallint unsigned NOT NULL,
  event_id int unsigned NOT NULL,
  cache tinyint unsigned NOT NULL DEFAULT 1 CHECK (cache < 2),
  PRIMARY KEY cache_pkey (locate_id, event_id),
  KEY cache_event (event_id),
  FOREIGN KEY cache_locate_fkey (locate_id) REFERENCES locate (locate_id),
  FOREIGN KEY cache_event_fkey (event_id) REFERENCES event (event_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Матрица кэшируемых событий';

CREATE TABLE IF NOT EXISTS cheat (
  cheat_id smallint unsigned NOT NULL AUTO_INCREMENT,
  name varchar(31) NOT NULL DEFAULT '',
  class varchar(127) NOT NULL DEFAULT '',
  method varchar(63) NOT NULL DEFAULT '',
  PRIMARY KEY cheat_pkey (cheat_id),
  UNIQUE KEY cheat_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Системные методы вызываемые до поиска активного модуля';

CREATE TABLE IF NOT EXISTS config_data (
  option_id smallint unsigned NOT NULL,
  locate_id smallint unsigned NOT NULL,
  value json NOT NULL CHECK (JSON_VALID(value)),
  mlang tinyint unsigned NOT NULL DEFAULT 0 CHECK (mlang < 2),
  local tinyint unsigned NOT NULL DEFAULT 0 CHECK (local < 2),
  PRIMARY KEY data_pkey (option_id, locate_id),
  KEY data_locate_id (locate_id),
  KEY data_locate (local),
  FOREIGN KEY data_option_fkey (option_id) REFERENCES config_option (option_id),
  FOREIGN KEY data_locate_fkey (locate_id) REFERENCES locate (locate_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Значения опций локации';

CREATE TABLE IF NOT EXISTS config_default (
  option_id smallint unsigned NOT NULL,
  `default` json NOT NULL CHECK (JSON_VALID(`default`)),
  mlang tinyint unsigned NOT NULL DEFAULT 0 CHECK (mlang < 2),
  PRIMARY KEY default_pkey (option_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Значения по умолчанию';

CREATE TABLE IF NOT EXISTS config_enum (
  option_id smallint unsigned NOT NULL,
  valuebykey tinyint unsigned NOT NULL DEFAULT 0 CHECK (valuebykey < 2),
  variants json NOT NULL CHECK (JSON_VALID(variants)),
  mlang tinyint unsigned NOT NULL DEFAULT 0 CHECK (mlang < 2),
  PRIMARY KEY config_enum_pkey (option_id),
  FOREIGN KEY config_enum_option_fkey (option_id) REFERENCES config_option (option_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Перечисляемые значения опций';

CREATE TABLE IF NOT EXISTS control (
  control_id smallint unsigned NOT NULL AUTO_INCREMENT,
  config_id smallint unsigned NOT NULL COMMENT 'Идентификатор класса конфигурации',
  event_id int unsigned NOT NULL COMMENT 'Идентификатор активного события элемента управления',
  class varchar(63) NOT NULL,
  title json NOT NULL CHECK (JSON_VALID(title)),
  self tinyint NOT NULL DEFAULT 0 CHECK (self < 2),
  PRIMARY KEY control_pkey (control_id),
  UNIQUE KEY control_class (class),
  UNIQUE KEY control_config (config_id),
  KEY control_event (event_id),
  FOREIGN KEY control_config_fkey (config_id) REFERENCES config (config_id),
  FOREIGN KEY control_event_fkey (event_id) REFERENCES event (event_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Элемент управления';

CREATE TABLE IF NOT EXISTS view (
  control_id smallint unsigned NOT NULL,
  target smallint unsigned NOT NULL,
  locate_id smallint unsigned NOT NULL,
  serial smallint unsigned NOT NULL DEFAULT 1,
  PRIMARY KEY view_pkey (control_id, target, locate_id),
  KEY view_locate (locate_id),
  KEY view_target (target),
  FOREIGN KEY view_control_fkey (control_id) REFERENCES control (control_id),
  FOREIGN KEY view_target_fkey (target) REFERENCES locate (locate_id),
  FOREIGN KEY view_locate_fkey (locate_id) REFERENCES locate (locate_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Отображения элементов одной локации на страницах другой';

CREATE TABLE IF NOT EXISTS delegate (
  delegate_id smallint unsigned NOT NULL AUTO_INCREMENT,
  class varchar(63) NOT NULL,
  title varchar(255) NOT NULL DEFAULT '',
  PRIMARY KEY delegate_pkey (delegate_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Делегат';

CREATE TABLE IF NOT EXISTS `group` (
  group_id smallint unsigned NOT NULL AUTO_INCREMENT COMMENT 'Идентификатор группы',
  code char(3) NOT NULL COMMENT 'Трехбуквенный код группы',
  title json NOT NULL CHECK (JSON_VALID(title)),
  users_limit tinyint unsigned NOT NULL DEFAULT 0 COMMENT 'Предел пользователей группы, 0 без ограничений',
  need_email tinyint unsigned NOT NULL DEFAULT 0 CHECK (need_email < 2) COMMENT 'В группу можно включать пользователя с подтвержденным адресом электронной почты',
  need_phone tinyint unsigned NOT NULL DEFAULT 0 CHECK (need_phone < 2) COMMENT 'В группу можно включать пользователя с подтвержденным номером телефона',
  status tinyint unsigned NOT NULL DEFAULT 0 CHECK (status < 16) COMMENT 'Статус, битовая маска флагов автоподключения, подключения, удаления',
  PRIMARY KEY group_pkey (group_id),
  UNIQUE KEY group_code (code),
  KEY group_users_limit (users_limit)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Группа пользователей';

CREATE TABLE IF NOT EXISTS icon (
  icon_id smallint unsigned NOT NULL AUTO_INCREMENT,
  name varchar(31) NOT NULL DEFAULT '',
  PRIMARY KEY icon_pkey (icon_id)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Иконка';

CREATE TABLE IF NOT EXISTS markup_class (
  class_id smallint unsigned NOT NULL AUTO_INCREMENT,
  class varchar(127) NOT NULL DEFAULT '',
  title json NOT NULL CHECK (JSON_VALID(title)),
  PRIMARY KEY markup_class_pkey (class_id),
  UNIQUE KEY markup_class (class)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Тип шиблона, фрагмента разметки';

CREATE TABLE IF NOT EXISTS markup (
  markup_id smallint unsigned NOT NULL AUTO_INCREMENT,
  class_id smallint unsigned NOT NULL,
  markup varchar(127) NOT NULL DEFAULT '',
  title json NOT NULL CHECK (JSON_VALID(title)),
  PRIMARY KEY markup_pkey (markup_id),
  KEY markup_class_id (class_id),
  FOREIGN KEY markup_class_fkey (class_id) REFERENCES markup_class (class_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Шаблон';

CREATE TABLE IF NOT EXISTS menu (
  menu_id tinyint unsigned NOT NULL AUTO_INCREMENT,
  markup_id smallint unsigned NOT NULL,
  code char(3) NOT NULL COMMENT 'Трехбуквенный код меню',
  title json NOT NULL CHECK (JSON_VALID(title)),
  active tinyint unsigned NOT NULL DEFAULT 1 CHECK (active < 2),
  status tinyint unsigned NOT NULL DEFAULT 0 CHECK (status < 8),
  PRIMARY KEY menu_pkey (menu_id),
  UNIQUE KEY menu_code (code),
  KEY menu_markup (markup_id),
  FOREIGN KEY menu_markup_fkey (markup_id) REFERENCES markup (markup_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Меню';

CREATE TABLE IF NOT EXISTS menu_responsive (
  menu_id tinyint unsigned NOT NULL AUTO_INCREMENT,
  for_id smallint unsigned NOT NULL,
  markup_id smallint unsigned NOT NULL,
  source varchar(31) NOT NULL DEFAULT '',
  icon varchar(31) NOT NULL DEFAULT '',
  side tinyint unsigned NOT NULL DEFAULT 0 CHECK (side < 2),
  displace tinyint unsigned NOT NULL DEFAULT 1 CHECK (displace < 2),
  PRIMARY KEY menu_responsive_pkey (menu_id),
  UNIQUE KEY menu_responsive_for (for_id),
  UNIQUE KEY menu_responsive_source (source),
  KEY menu_responsive_markup (markup_id),
  FOREIGN KEY menu_responsive_for_fkey (for_id) REFERENCES markup (markup_id),
  FOREIGN KEY menu_responsive_markup_fkey (markup_id) REFERENCES markup (markup_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Адаптивное меню';

CREATE TABLE IF NOT EXISTS navigate (
  locate_id smallint unsigned NOT NULL,
  menu_id tinyint unsigned NOT NULL,
  PRIMARY KEY navigate_pkey (locate_id, menu_id),
  KEY navigate_menu (menu_id),
  FOREIGN KEY navigate_locate_fkey (locate_id) REFERENCES locate (locate_id),
  FOREIGN KEY navigate_menu_fkey (menu_id) REFERENCES menu (menu_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Меню для каждой локации.';

CREATE TABLE IF NOT EXISTS reference (
  reference_id smallint unsigned NOT NULL AUTO_INCREMENT,
  code char(3) NOT NULL COMMENT 'Трехбуквенный код ссылки',
  locate_id smallint unsigned NOT NULL,
  event_id int unsigned DEFAULT NULL,
  value varchar(255) NOT NULL DEFAULT '',
  url varchar(255) NOT NULL DEFAULT '',
  text json NOT NULL CHECK (JSON_VALID(text)),
  active json NOT NULL CHECK (JSON_VALID(active)),
  title json NOT NULL CHECK (JSON_VALID(title)),
  status tinyint unsigned NOT NULL DEFAULT 0 CHECK (status < 8),
  PRIMARY KEY reference_pkey (reference_id),
  UNIQUE KEY reference_code (code),
  KEY reference_locate (locate_id),
  KEY reference_event (event_id),
  FOREIGN KEY reference_locate_fkey (locate_id) REFERENCES locate (locate_id),
  FOREIGN KEY reference_event_fkey (event_id) REFERENCES event (event_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Гиперссылка.';

CREATE TABLE IF NOT EXISTS menuitem (
  item_id smallint unsigned NOT NULL AUTO_INCREMENT,
  menu_id tinyint unsigned NOT NULL,
  submenu_id tinyint unsigned DEFAULT NULL,
  reference_id smallint unsigned NOT NULL,
  role_id smallint unsigned DEFAULT NULL,
  serial smallint unsigned NOT NULL DEFAULT 1,
  active tinyint unsigned NOT NULL DEFAULT 1 CHECK (active < 2),
  icon varchar(63) NOT NULL DEFAULT '',
  `empty` tinyint unsigned NOT NULL DEFAULT 0 CHECK (`empty` < 2),
  follow tinyint unsigned NOT NULL DEFAULT 0 CHECK (follow < 2),
  blank tinyint unsigned NOT NULL DEFAULT 0 CHECK (blank < 2),
  status tinyint unsigned NOT NULL DEFAULT 0 CHECK (status < 8),
  PRIMARY KEY item_pkey (item_id),
  KEY item_menu (menu_id),
  KEY item_reference (reference_id),
  KEY item_role (role_id),
  FOREIGN KEY item_menu_fkey (menu_id) REFERENCES menu (menu_id),
  FOREIGN KEY item_submenu_fkey (submenu_id) REFERENCES menu (menu_id),
  FOREIGN KEY item_reference_fkey (reference_id) REFERENCES reference (reference_id),
  FOREIGN KEY item_role_fkey (role_id) REFERENCES role (role_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Пункт меню';

CREATE TABLE IF NOT EXISTS permit (
  group_id smallint unsigned NOT NULL,
  role_id smallint unsigned NOT NULL,
  PRIMARY KEY permit_pkey (group_id, role_id),
  KEY permit_role (role_id),
  FOREIGN KEY permit_group_fkey (group_id) REFERENCES `group` (group_id),
  FOREIGN KEY permit_role_fkey (role_id) REFERENCES role (role_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Роли для группы';

CREATE TABLE IF NOT EXISTS privilege (
  privilege_id int unsigned NOT NULL AUTO_INCREMENT,
  locate_id smallint unsigned NOT NULL,
  event_id int unsigned NOT NULL,
  PRIMARY KEY privilege_pkey (privilege_id),
  UNIQUE KEY privilege_locate_event (locate_id, event_id),
  KEY privilege_event (event_id),
  FOREIGN KEY privilege_locate_fkey (locate_id) REFERENCES locate (locate_id),
  FOREIGN KEY privilege_event_fkey (event_id) REFERENCES event (event_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Привилегия';

CREATE TABLE IF NOT EXISTS rule (
  role_id smallint unsigned NOT NULL,
  privilege_id int unsigned NOT NULL,
  PRIMARY KEY rule_pkey (role_id, privilege_id),
  KEY rule_privilege (privilege_id),
  FOREIGN KEY rule_role_fkey (role_id) REFERENCES role (role_id),
  FOREIGN KEY rule_privilege_fkey (privilege_id) REFERENCES privilege (privilege_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Правило вхождения привилегии в роль';

CREATE TABLE IF NOT EXISTS site_template (
  template_id tinyint unsigned NOT NULL AUTO_INCREMENT,
  name varchar(31) NOT NULL DEFAULT '',
  status tinyint unsigned NOT NULL DEFAULT 0 CHECK (status < 16),
  PRIMARY KEY template_pkey (template_id),
  UNIQUE KEY template_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Шаблон страницы сайта';

CREATE TABLE IF NOT EXISTS temp (
  temp_id varchar(7) NOT NULL,
  temp_data text NOT NULL,
  temp_ts timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY temp_pkey (temp_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Временное хранилище объектов данных';

CREATE TABLE IF NOT EXISTS `user` (
  user_id int unsigned NOT NULL AUTO_INCREMENT COMMENT 'Идентификатор пользователя',
  parent_id int unsigned NOT NULL DEFAULT 0 COMMENT 'Идентификатор связанных пользователей',
  login varchar(31) NOT NULL DEFAULT '' COMMENT 'Имя учетной записи',
  oauth varchar(31) NOT NULL DEFAULT '' COMMENT 'Идентификатор пользователя у провайдера oAuth',
  team varchar(255) NOT NULL DEFAULT '' COMMENT 'Ожидаемое участие в группах',
  password varchar(128) NOT NULL DEFAULT '' COMMENT 'Пароль',
  email varchar(63) NOT NULL DEFAULT '' COMMENT 'Адрес электронной почты',
  phone varchar(31) NOT NULL DEFAULT '' COMMENT 'Контактный телефон (например для приема СМС)',
  name varchar(31) NOT NULL DEFAULT '' COMMENT 'Отображаемое имя пользователя',
  photo varchar(255) NOT NULL DEFAULT '' COMMENT 'URL фотографии или аватара пользователя',
  `create` datetime NOT NULL COMMENT 'Время регистрации',
  status tinyint unsigned NOT NULL DEFAULT 0 CHECK (status < 8) COMMENT 'Статус, 0 - пользователь активен',
  PRIMARY KEY user_pkey (user_id),
  UNIQUE KEY user_login (login),
  KEY user_parent (parent_id),
  KEY user_oauth (oauth),
  KEY user_email (email),
  KEY user_phone (phone),
  FOREIGN KEY user_parent_fkey (parent_id) REFERENCES `user` (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Учетная запись.';

CREATE TABLE IF NOT EXISTS team (
  user_id int unsigned NOT NULL COMMENT 'Идентификатор пользователя',
  group_id smallint unsigned NOT NULL COMMENT 'Идентификатор группы',
  PRIMARY KEY team_pkey (user_id, group_id),
  KEY team_group (group_id),
  FOREIGN KEY team_user_fkey (user_id) REFERENCES `user` (user_id),
  FOREIGN KEY team_group_fkey (group_id) REFERENCES `group` (group_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Команда. Распределение пользователей по группам';

CREATE TABLE IF NOT EXISTS user_auth (
  user_id int unsigned NOT NULL COMMENT 'Идентификатор пользователя',
  hash varchar(128) NOT NULL DEFAULT '' COMMENT 'Хэш последней успешной авторизации',
  auth datetime NOT NULL COMMENT 'Время последней успешной авторизации',
  PRIMARY KEY user_auth_pkey (user_id, hash),
  KEY auth_hash (hash),
  FOREIGN KEY auth_user_fkey (user_id) REFERENCES `user` (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Параметры последней успешной авторизации.';

CREATE TABLE IF NOT EXISTS user_oauth (
  profile_id int unsigned NOT NULL AUTO_INCREMENT COMMENT 'Идентификатор профиля',
  user_id int unsigned NOT NULL COMMENT 'Систеный идентификатор пользователя',
  network varchar(31) NOT NULL DEFAULT '' COMMENT 'Идентификатор соцсети или oAuth сервиса',
  uid varchar(31) NOT NULL DEFAULT '' COMMENT 'Уникальный идентификатор пользователя в рамках соцсети',
  nickname varchar(31) NOT NULL DEFAULT '' COMMENT 'Псевдоним пользователя',
  email varchar(63) NOT NULL DEFAULT '' COMMENT 'Email пользователя',
  verified_email tinyint NOT NULL DEFAULT 0 CHECK(verified_email <= 1 AND verified_email >= -1) COMMENT 'Флаг верификации email, принимает значения 1 и -1',
  first_name varchar(31) NOT NULL DEFAULT '' COMMENT 'Имя пользователя',
  last_name varchar(31) NOT NULL DEFAULT '' COMMENT 'Фамилия пользователя',
  bdate date NOT NULL DEFAULT '0001-01-01' COMMENT 'Дата рождения',
  sex tinyint unsigned NOT NULL DEFAULT 0 CHECK(sex < 3) COMMENT 'Пол пользователя (0 – не определен, 1 – женский, 2 – мужской)',
  phone varchar(31) NOT NULL DEFAULT '' COMMENT 'Телефон пользователя в цифровом формате без лишних символов',
  identity varchar(255) NOT NULL DEFAULT '' COMMENT 'Глобально уникальный идентификатор oAuth пользователя',
  profile varchar(255) NOT NULL DEFAULT '' COMMENT 'Адрес профиля пользователя (ссылка на его страницу в соцсети)',
  photo varchar(255) NOT NULL DEFAULT '' COMMENT 'Адрес квадратной аватарки (до 100*100)',
  photo_big varchar(255) NOT NULL DEFAULT '' COMMENT 'Адрес самой большой аватарки, выдаваемой соц. сетью',
  city varchar(31) NOT NULL DEFAULT '' COMMENT 'Город',
  country varchar(31) NOT NULL DEFAULT '' COMMENT 'Страна',
  PRIMARY KEY user_oauth_pkey (profile_id),
  UNIQUE KEY oauth_uid (uid, network),
  KEY oauth_network (network),
  KEY oauth_user_id (user_id),
  KEY oauth_nickname (nickname),
  KEY oauth_email (email),
  KEY oauth_sex (sex),
  KEY oauth_phone (phone),
  FOREIGN KEY oauth_user_fkey (user_id) REFERENCES `user` (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='oAuth профиль пользователя';

CREATE TABLE IF NOT EXISTS user_phone (
  user_id int unsigned NOT NULL COMMENT 'Идентификатор пользователя',
  phone varchar(20) NOT NULL DEFAULT '' COMMENT 'Телефон принимающий СМС',
  PRIMARY KEY user_phone_pkey (user_id, phone),
  KEY user_phone (phone),
  FOREIGN KEY user_phone_fkey (user_id) REFERENCES `user` (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Телефон пользователя.';


CREATE OR REPLACE
ALGORITHM=UNDEFINED
DEFINER = CURRENT_USER
SQL SECURITY INVOKER
VIEW additions AS SELECT
addon.plugin_id        AS plugin_id,
`group`.group_id       AS group_id,
`group`.title          AS `group`,
`group`.users_limit    AS group_limit,
`group`.status         AS group_status,
role.role_id           AS role_id,
role.title             AS role,
role.status            AS role_status,
addon.locate_id        AS locate_id,
build.build_id         AS build_id,
locate.title           AS locate,
decision.title         AS decision,
build.title            AS build,
plugin.config_id       AS config_id,
p_cfg.class            AS config_class,
plugin.class           AS class,
plugin.title           AS title,
addon.active           AS active,
plugin.status          AS status,
component.title        AS component,
component.class        AS component_class,
config.class           AS config
FROM addon
LEFT JOIN plugin       ON addon.plugin_id       = plugin.plugin_id
LEFT JOIN attach       ON plugin.plugin_id      = attach.plugin_id
LEFT JOIN role         ON attach.role_id        = role.role_id
LEFT JOIN permit       ON role.role_id          = permit.role_id
LEFT JOIN `group`      ON permit.group_id       = `group`.group_id
LEFT JOIN locate       ON addon.locate_id       = locate.locate_id
LEFT JOIN build        ON locate.build_id       = build.build_id
LEFT JOIN decision     ON locate.decision_id    = decision.decision_id
LEFT JOIN project      ON decision.project_id   = project.project_id
LEFT JOIN component    ON decision.component_id = component.component_id
LEFT JOIN config       ON component.config_id   = config.config_id
LEFT JOIN config p_cfg ON plugin.config_id      = p_cfg.config_id;


CREATE OR REPLACE
ALGORITHM=UNDEFINED
DEFINER = CURRENT_USER
SQL SECURITY INVOKER
VIEW application AS SELECT
build.build_id     AS build_id,
project.project_id AS project_id,
project.config_id  AS config_id,
JSON_UNQUOTE(JSON_EXTRACT(
  build.title,
  language.title_path
))                 AS title,
project.class      AS class,
config.class       AS config,
JSON_UNQUOTE(JSON_EXTRACT(
  project.title,
  language.title_path
))                 AS project,
project.singleton  AS singleton,
language.lang_id   AS lang_id,
language.name      AS lang,
language.title     AS language
FROM build
JOIN language      ON language.status   = 0
LEFT JOIN project  ON build.project_id  = project.project_id
LEFT JOIN config   ON project.config_id = config.config_id;


CREATE OR REPLACE
ALGORITHM=UNDEFINED
DEFINER = CURRENT_USER
SQL SECURITY INVOKER
VIEW attachables AS SELECT
attach.plugin_id    AS plugin_id,
`group`.group_id    AS group_id,
`group`.title       AS `group`,
`group`.users_limit AS group_limit,
`group`.status      AS group_status,
role.role_id        AS role_id,
role.title          AS role,
role.status         AS role_status,
addon.locate_id     AS locate_id,
build.build_id      AS build_id,
locate.title        AS locate,
decision.title      AS decision,
build.title         AS build,
plugin.config_id    AS config_id,
p_cfg.class         AS config_class,
plugin.class        AS class,
plugin.title        AS title,
addon.active        AS active,
plugin.status       AS status,
component.title     AS component,
component.class     AS component_class,
config.class        AS config
FROM attach
LEFT JOIN plugin       ON attach.plugin_id      = plugin.plugin_id
LEFT JOIN role         ON attach.role_id        = role.role_id
LEFT JOIN permit       ON role.role_id          = permit.role_id
LEFT JOIN `group`      ON permit.group_id       = `group`.group_id
LEFT JOIN addon        ON plugin.plugin_id      = addon.plugin_id
LEFT JOIN locate       ON addon.locate_id       = locate.locate_id
LEFT JOIN build        ON locate.build_id       = build.build_id
LEFT JOIN decision     ON locate.decision_id    = decision.decision_id
LEFT JOIN project      ON decision.project_id   = project.project_id
LEFT JOIN component    ON decision.component_id = component.component_id
LEFT JOIN config       ON component.config_id   = config.config_id
LEFT JOIN config p_cfg ON plugin.config_id      = p_cfg.config_id;


CREATE OR REPLACE
ALGORITHM=UNDEFINED
DEFINER = CURRENT_USER
SQL SECURITY INVOKER
VIEW caches AS SELECT DISTINCT
cache.event_id    AS event_id,
cache.locate_id   AS locate_id,
CASE
  WHEN component.cache = 0 THEN 0
  WHEN c.cache       = 0 THEN 0
  WHEN decision.cache  = 0 THEN 0
  WHEN locate.cache    = 0 THEN 0
  ELSE cache.cache
END               AS cache,
CASE
  WHEN component.cache = 0 THEN 0
  WHEN	c.cache      = 0 THEN 0
  WHEN	decision.cache = 0 THEN 0
  WHEN	locate.cache   = 0 THEN 0
  ELSE	event.cache
END               AS cachable,
config.class      AS config,
event.name        AS name,
JSON_UNQUOTE(JSON_EXTRACT(
  event.title,
  language.title_path
))                AS title,
event.access      AS access,
language.lang_id  AS lang_id,
language.name     AS lang,
language.title    AS language
FROM cache
JOIN language         ON language.status       = 0
LEFT JOIN event       ON cache.event_id        = event.event_id
LEFT JOIN component c ON event.component_id    = c.component_id
LEFT JOIN config      ON c.config_id           = config.config_id
LEFT JOIN locate      ON cache.locate_id       = locate.locate_id
LEFT JOIN decision    ON locate.decision_id    = decision.decision_id
LEFT JOIN component   ON decision.component_id = component.component_id;


CREATE OR REPLACE
ALGORITHM=UNDEFINED
DEFINER = CURRENT_USER
SQL SECURITY INVOKER
VIEW components AS SELECT DISTINCT
component.component_id AS component_id,
component.config_id    AS config_id,
JSON_UNQUOTE(JSON_EXTRACT(
  component.title,
  language.title_path
))                     AS title,
component.role_id      AS role_id,
JSON_UNQUOTE(JSON_EXTRACT(
  role.title,
  language.title_path
))                     AS role,
component.class        AS class,
component.cache        AS cache,
config.class           AS config,
JSON_UNQUOTE(JSON_EXTRACT(
  config.title,
  language.title_path
))                     AS config_title,
component.singleton    AS singleton,
CASE
  WHEN decision.decision_id IS NULL THEN 1
  WHEN component.singleton = 1 THEN 0
  ELSE 1
END                    AS is_free,
decision.decision_id
  IS NOT NULL          AS is_decision,
language.lang_id       AS lang_id,
language.name          AS lang,
language.title         AS language
FROM component
JOIN language      ON language.status        = 0
LEFT JOIN config   ON component.config_id    = config.config_id
LEFT JOIN decision ON component.component_id = decision.component_id
LEFT JOIN role     ON component.role_id      = role.role_id;


CREATE OR REPLACE
ALGORITHM=UNDEFINED
DEFINER = CURRENT_USER
SQL SECURITY INVOKER
VIEW configs AS SELECT
config.config_id AS config_id,
config.class     AS class,
JSON_UNQUOTE(JSON_EXTRACT(
  config.title,
  language.title_path
))               AS title,
language.lang_id AS lang_id,
language.name    AS lang,
language.title   AS language
FROM config
JOIN language ON language.status = 0;


CREATE OR REPLACE
ALGORITHM=UNDEFINED
DEFINER = CURRENT_USER
SQL SECURITY INVOKER
VIEW config_options AS SELECT
config_option.option_id  AS option_id,
config_data.locate_id    AS locate_id,
config_option.config_id  AS config_id,
config.class             AS config,
config.title             AS config_title,
config_option.slice_id   AS slice_id,
config_slice.slice       AS slice,
config_slice.title       AS slice_title,
config_option.type_id    AS type_id,
config_type.type         AS type,
config_option.role_id    AS role_id,
config_option.serial     AS serial_number,
config_option.global     AS global,
config_option.active     AS active,
config_option.name       AS name,
config_option.input      AS input,
config_option.output     AS output,
config_option.title      AS title,
config_slice.serial      AS serial,
config_default.`default` AS `default`,
config_data.value        AS value,
config_data.local        AS local,
config_enum.variants     AS variants,
config_enum.valuebykey   AS valuebykey
FROM config_option
LEFT JOIN config         ON config_option.config_id = config.config_id
LEFT JOIN config_type    ON config_option.type_id   = config_type.type_id
LEFT JOIN config_slice   ON config_option.slice_id  = config_slice.slice_id
LEFT JOIN config_enum    ON config_option.option_id = config_enum.option_id
LEFT JOIN config_default ON config_option.option_id = config_default.option_id
LEFT JOIN config_data    ON config_option.option_id = config_data.option_id;

/*
CREATE OR REPLACE
ALGORITHM=UNDEFINED
DEFINER = CURRENT_USER
SQL SECURITY INVOKER
VIEW config_keys AS SELECT
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

CREATE OR REPLACE
ALGORITHM=UNDEFINED
DEFINER = CURRENT_USER
SQL SECURITY INVOKER
VIEW config_kits AS SELECT
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
JSON_UNQUOTE(JSON_EXTRACT(
  config_data.value,
  language.title_path
))                      AS value,
config_enum.valuebykey  AS valuebykey,
config_option.global    AS global,
config_option.active    AS active
FROM config_option
JOIN language         ON language.status         = 0
LEFT JOIN config      ON config_option.config_id = config.config_id
LEFT JOIN config_type ON config_option.type_id   = config_type.type_id
LEFT JOIN config_data ON config_option.option_id = config_data.option_id
LEFT JOIN config_enum ON config_option.option_id = config_enum.option_id;


CREATE OR REPLACE
ALGORITHM=UNDEFINED
DEFINER = CURRENT_USER
SQL SECURITY INVOKER
VIEW controls AS SELECT
control.control_id     AS control_id,
component.component_id AS component_id,
control.config_id      AS config_id,
control.event_id       AS event_id,
locate.locate_id       AS locate_id,
language.lang_id       AS lang_id,
JSON_UNQUOTE(JSON_EXTRACT(
  locate.title,
  language.title_path
))                     AS locate,
language.name          AS lang,
language.title         AS language,
decision.name          AS name,
JSON_UNQUOTE(JSON_EXTRACT(
  decision.title,
  language.title_path
))                     AS decision,
project.project_id     AS project_id,
project.class          AS project_class,
JSON_UNQUOTE(JSON_EXTRACT(
  project.title,
  language.title_path
))                     AS project,
control.class          AS class,
cc.class               AS control,
control.self           AS self,
component.class        AS component,
config.class           AS config,
event.name             AS event,
event.access           AS access,
JSON_UNQUOTE(JSON_EXTRACT(
  control.title,
  language.title_path
))                     AS title
FROM control
JOIN language          ON language.status        = 0
LEFT JOIN config AS cc ON control.config_id      = cc.config_id
LEFT JOIN event        ON control.event_id       = event.event_id
LEFT JOIN component    ON event.component_id     = component.component_id
LEFT JOIN config       ON component.config_id    = config.config_id
LEFT JOIN decision     ON component.component_id = decision.component_id
LEFT JOIN locate       ON decision.decision_id   = locate.decision_id
LEFT JOIN project      ON decision.project_id    = project.project_id;


CREATE OR REPLACE
ALGORITHM=UNDEFINED
DEFINER = CURRENT_USER
SQL SECURITY INVOKER
VIEW decisions AS SELECT
decision.decision_id  AS decision_id,
decision.project_id   AS project_id,
decision.component_id AS component_id,
decision.name         AS name,
JSON_UNQUOTE(JSON_EXTRACT(
  decision.title,
  language.title_path
))                    AS title,
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


CREATE OR REPLACE
ALGORITHM=UNDEFINED
DEFINER = CURRENT_USER
SQL SECURITY INVOKER
VIEW events AS SELECT
event.event_id     AS event_id,
event.name         AS name,
JSON_UNQUOTE(JSON_EXTRACT(
  event.title,
  language.title_path
))                 AS title,
event.component_id AS component_id,
event.role_id      AS role_id,
JSON_UNQUOTE(JSON_EXTRACT(
  role.title,
  language.title_path
))                 AS role,
CASE component.cache
  WHEN 1 THEN event.cache
  ELSE 0
END                AS cache,
event.access       AS access,
event.nav          AS nav,
language.lang_id   AS lang_id,
language.name      AS lang,
language.title     AS language,
JSON_UNQUOTE(JSON_EXTRACT(
  component.title,
  language.title_path
))                 AS component,
component.class    AS class,
config.class       AS config
FROM event
JOIN language       ON language.status     = 0
LEFT JOIN role      ON event.role_id       = role.role_id
LEFT JOIN component ON event.component_id  = component.component_id
LEFT JOIN config    ON component.config_id = config.config_id;


CREATE OR REPLACE
ALGORITHM=UNDEFINED
DEFINER = CURRENT_USER
SQL SECURITY INVOKER
VIEW `groups` AS SELECT
`group`.group_id    AS group_id,
`group`.code        AS code,
JSON_UNQUOTE(JSON_EXTRACT(
  `group`.title,
  language.title_path
))                  AS `group`,
`group`.users_limit AS users_limit,
`group`.need_email  AS need_email,
`group`.need_phone  AS need_phone,
`group`.status      AS group_status,
language.lang_id    AS lang_id,
language.name       AS lang,
language.title      AS language,
`user`.user_id      AS user_id,
`user`.login        AS login,
`user`.email        AS email,
`user`.status       AS user_status,
role.role_id        AS role_id,
JSON_UNQUOTE(JSON_EXTRACT(
  role.title,
  language.title_path
))                  AS role,
role.status         AS role_status
FROM `group`
JOIN language    ON language.status  = 0
LEFT JOIN team   ON `group`.group_id = team.group_id
RIGHT JOIN `user`  ON team.user_id     = `user`.user_id
LEFT JOIN permit ON `group`.group_id = permit.group_id
LEFT JOIN role   ON permit.role_id   = role.role_id;


CREATE OR REPLACE
ALGORITHM=UNDEFINED
DEFINER = CURRENT_USER
SQL SECURITY INVOKER
VIEW items AS SELECT DISTINCT
menuitem.item_id      AS item_id,
reference.locate_id   AS locate_id,
CASE
  WHEN reference.locate_id > 0 THEN `group`.group_id
  ELSE 0
END                   AS group_id,
CASE
  WHEN reference.locate_id > 0 THEN `group`.status
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
reference.status +
menuitem.status       AS status,
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
LEFT JOIN `group`             ON `group`.group_id      = permit.group_id;


CREATE OR REPLACE
ALGORITHM=UNDEFINED
DEFINER = CURRENT_USER
SQL SECURITY INVOKER
VIEW locs AS SELECT
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
JSON_UNQUOTE(JSON_EXTRACT(
  locate.title,
  language.title_path
))                    AS title,
JSON_UNQUOTE(JSON_EXTRACT(
  decision.title,
  language.title_path
))                    AS decision,
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
JSON_UNQUOTE(JSON_EXTRACT(
  component.title,
  language.title_path
))                    AS component,
JSON_UNQUOTE(JSON_EXTRACT(
  build.title,
  language.title_path
))                    AS build,
JSON_UNQUOTE(JSON_EXTRACT(
  project.title,
  language.title_path
))                    AS project,
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


CREATE OR REPLACE
ALGORITHM=UNDEFINED
DEFINER = CURRENT_USER
SQL SECURITY INVOKER
VIEW map AS SELECT
`user`.user_id       AS user_id,
`user`.login         AS login,
`group`.group_id     AS group_id,
`group`.title        AS `group`,
`group`.users_limit  AS group_limit,
`group`.status       AS group_status,
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
LEFT JOIN `group`    ON `group`.group_id      = permit.group_id
LEFT JOIN team       ON `group`.group_id      = team.group_id
RIGHT JOIN `user`      ON team.user_id          = `user`.user_id
LEFT JOIN locate     ON access.locate_id      = locate.locate_id
LEFT JOIN build      ON locate.build_id       = build.build_id
LEFT JOIN decision   ON locate.decision_id    = decision.decision_id
LEFT JOIN project    ON decision.project_id   = project.project_id
LEFT JOIN component  ON decision.component_id = component.component_id
LEFT JOIN config     ON component.config_id   = config.config_id;


CREATE OR REPLACE
ALGORITHM=UNDEFINED
DEFINER = CURRENT_USER
SQL SECURITY INVOKER
VIEW markups AS SELECT
markup.markup_id      AS id,
markup.markup_id      AS markup_id,
markup.markup         AS markup,
markup_class.class_id AS class_id,
markup_class.class    AS class
FROM markup
LEFT JOIN markup_class ON markup.class_id = markup_class.class_id;


CREATE OR REPLACE
ALGORITHM=UNDEFINED
DEFINER = CURRENT_USER
SQL SECURITY INVOKER
VIEW matrix AS SELECT
`user`.user_id           AS user_id,
`user`.login             AS login,
`group`.group_id       AS group_id,
`group`.title          AS `group`,
`group`.users_limit    AS group_limit,
`group`.status         AS group_status,
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
LEFT JOIN `group`   ON permit.group_id       = `group`.group_id
LEFT JOIN team      ON `group`.group_id      = team.group_id
RIGHT JOIN `user`     ON team.user_id          = `user`.user_id
LEFT JOIN privilege ON rule.privilege_id     = privilege.privilege_id
LEFT JOIN event     ON privilege.event_id    = event.event_id
LEFT JOIN locate    ON privilege.locate_id   = locate.locate_id
LEFT JOIN build     ON locate.build_id       = build.build_id
LEFT JOIN decision  ON locate.decision_id    = decision.decision_id
LEFT JOIN project   ON decision.project_id   = project.project_id
LEFT JOIN component ON decision.component_id = component.component_id
LEFT JOIN config    ON component.config_id   = config.config_id;


CREATE OR REPLACE
ALGORITHM=UNDEFINED
DEFINER = CURRENT_USER
SQL SECURITY INVOKER
VIEW menus AS SELECT
menu.menu_id           AS id,
menu.menu_id           AS menu_id,
JSON_UNQUOTE(JSON_EXTRACT(
  menu.title,
  language.title_path
))                     AS title,
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


CREATE OR REPLACE
ALGORITHM=UNDEFINED
DEFINER = CURRENT_USER
SQL SECURITY INVOKER
VIEW menu_responsives AS SELECT
menu_responsive.menu_id   AS menu_id,
menu_responsive.for_id    AS for_id,
menu_responsive.markup_id AS markup_id,
menu.markup               AS menu,
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


CREATE OR REPLACE
ALGORITHM=UNDEFINED
DEFINER = CURRENT_USER
SQL SECURITY INVOKER
VIEW `modifies` AS SELECT DISTINCT
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
  IS NOT NULL          AS `exists`,
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


CREATE OR REPLACE
ALGORITHM=UNDEFINED
DEFINER = CURRENT_USER
SQL SECURITY INVOKER
VIEW mods AS SELECT DISTINCT
component.component_id AS component_id,
component.class        AS class,
component.cache        AS cache,
config.class           AS config,
language.lang_id       AS lang_id,
language.name          AS lang,
language.title         AS language,
JSON_UNQUOTE(JSON_EXTRACT(
  component.title,
  language.title_path
))                     AS title,
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


CREATE OR REPLACE
ALGORITHM=UNDEFINED
DEFINER = CURRENT_USER
SQL SECURITY INVOKER
VIEW navs AS SELECT
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


CREATE OR REPLACE
ALGORITHM=UNDEFINED
DEFINER = CURRENT_USER
SQL SECURITY INVOKER
VIEW perms AS SELECT
role.role_id        AS role_id,
JSON_UNQUOTE(JSON_EXTRACT(
  role.title,
  language.title_path
))                  AS role,
role.status         AS role_status,
role.nocache        AS nocache,
`group`.group_id    AS group_id,
JSON_UNQUOTE(JSON_EXTRACT(
  `group`.title,
  language.title_path
))                  AS `group`,
`group`.users_limit AS group_limit,
`group`.status      AS group_status,
`user`.user_id        AS user_id,
`user`.login          AS login,
language.lang_id    AS lang_id,
language.name       AS lang,
language.title      AS language
FROM permit
JOIN language     ON language.status  = 0
LEFT JOIN role    ON permit.role_id   = role.role_id
LEFT JOIN `group` ON permit.group_id  = `group`.group_id
LEFT JOIN team    ON `group`.group_id = team.group_id
RIGHT JOIN `user`   ON team.user_id     = `user`.user_id;


CREATE OR REPLACE
ALGORITHM=UNDEFINED
DEFINER = CURRENT_USER
SQL SECURITY INVOKER
VIEW plugins AS SELECT
plugin.plugin_id AS id,
plugin.plugin_id AS plugin_id,
plugin.config_id AS config_id,
JSON_UNQUOTE(JSON_EXTRACT(
  plugin.title,
  language.title_path
))               AS title,
config.class     AS config,
plugin.class     AS class,
plugin.status    AS status,
language.lang_id AS lang_id,
language.name    AS lang,
language.title   AS language
FROM plugin
JOIN language    ON language.status  = 0
LEFT JOIN config ON plugin.config_id = config.config_id;


CREATE OR REPLACE
ALGORITHM=UNDEFINED
DEFINER = CURRENT_USER
SQL SECURITY INVOKER
VIEW privileges AS SELECT
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


CREATE OR REPLACE
ALGORITHM=UNDEFINED
DEFINER = CURRENT_USER
SQL SECURITY INVOKER
VIEW projects AS SELECT DISTINCT
project.project_id         AS project_id,
project.config_id          AS config_id,
project.code               AS code,
project.class              AS class,
config.class               AS config,
JSON_UNQUOTE(JSON_EXTRACT(
  project.title,
  language.title_path
))                         AS title,
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


CREATE OR REPLACE
ALGORITHM=UNDEFINED
DEFINER = CURRENT_USER
SQL SECURITY INVOKER
VIEW `references` AS SELECT
reference.reference_id AS reference_id,
CASE
  WHEN reference.event_id IS NULL THEN 0
  ELSE reference.event_id
END                    AS event_id,
reference.url          AS url,
JSON_UNQUOTE(JSON_EXTRACT(
  reference.text,
  language.title_path
))                     AS text,
JSON_UNQUOTE(JSON_EXTRACT(
  reference.active,
  language.title_path
))                     AS active,
JSON_UNQUOTE(JSON_EXTRACT(
  reference.title,
  language.title_path
))                     AS title,
reference.status       AS status,
locate.locate_id       AS locate_id,
locate.decision_id     AS decision_id,
locate.serial          AS serial,
decision.component_id  AS component_id,
locate.build_id        AS build_id,
build.project_id       AS project_id,
decision.name          AS name,
JSON_UNQUOTE(JSON_EXTRACT(
  decision.title,
  language.title_path
))                     AS decision,
JSON_UNQUOTE(JSON_EXTRACT(
  locate.title,
  language.title_path
))                     AS locate,
component.class        AS class,
config.class           AS config,
project.class          AS class_project,
JSON_UNQUOTE(JSON_EXTRACT(
  component.title,
  language.title_path
))                     AS component,
JSON_UNQUOTE(JSON_EXTRACT(
  build.title,
  language.title_path
))                     AS build,
JSON_UNQUOTE(JSON_EXTRACT(
  project.title,
  language.title_path
))                     AS project,
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


CREATE OR REPLACE
ALGORITHM=UNDEFINED
DEFINER = CURRENT_USER
SQL SECURITY INVOKER
VIEW roles AS SELECT
role.role_id     AS role_id,
role.code        AS code,
JSON_UNQUOTE(JSON_EXTRACT(
  role.title,
  language.title_path
))               AS title,
role.nocache     AS nocache,
role.status      AS status,
language.lang_id AS lang_id,
language.name    AS lang,
language.title   AS language
FROM role
JOIN language ON language.status = 0;


CREATE OR REPLACE
ALGORITHM=UNDEFINED
DEFINER = CURRENT_USER
SQL SECURITY INVOKER
VIEW sample AS SELECT
decision.decision_id   AS decision_id,
decision.project_id    AS project_id,
decision.name          AS name,
JSON_UNQUOTE(JSON_EXTRACT(
  decision.title,
  language.title_path
))                     AS title,
project.class          AS project_class,
JSON_UNQUOTE(JSON_EXTRACT(
  project.title,
  language.title_path
))                     AS project,
project.singleton      AS project_singleton,
component.component_id AS component_id,
component.class        AS component_class,
JSON_UNQUOTE(JSON_EXTRACT(
  component.title,
  language.title_path
))                     AS component_title,
config.class           AS config,
JSON_UNQUOTE(JSON_EXTRACT(
  config.title,
  language.title_path
))                     AS config_title,
component.singleton    AS component_singleton,
CASE locate.locate_id
  WHEN NULL THEN 0
	ELSE locate.locate_id
END                    AS locate_id,
locate.locate_id
  IS NOT NULL          AS `exists`,
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


CREATE OR REPLACE
ALGORITHM=UNDEFINED
DEFINER = CURRENT_USER
SQL SECURITY INVOKER
VIEW `schema` AS SELECT
locate.locate_id       AS locate_id,
locate.build_id        AS build_id,
locate.serial          AS serial,
JSON_UNQUOTE(JSON_EXTRACT(
  build.title,
  language.title_path
))                     AS build,
decision.decision_id   AS decision_id,
decision.project_id    AS project_id,
decision.name          AS name,
JSON_UNQUOTE(JSON_EXTRACT(
  decision.title,
  language.title_path
))                     AS title,
project.class          AS project_class,
JSON_UNQUOTE(JSON_EXTRACT(
  project.title,
  language.title_path
))                     AS project,
project.singleton      AS project_singleton,
component.component_id AS component_id,
component.class        AS component_class,
JSON_UNQUOTE(JSON_EXTRACT(
  component.title,
  language.title_path
))                     AS component_title,
config.class           AS config,
JSON_UNQUOTE(JSON_EXTRACT(
  config.title,
  language.title_path
))                     AS config_title,
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


CREATE OR REPLACE
ALGORITHM=UNDEFINED
DEFINER = CURRENT_USER
SQL SECURITY INVOKER
VIEW teams AS SELECT
`user`.user_id        AS user_id,
`user`.login          AS login,
`group`.group_id    AS group_id,
JSON_UNQUOTE(JSON_EXTRACT(
  `group`.title,
  language.title_path
))                  AS `group`,
`group`.users_limit AS group_limit,
`group`.status      AS group_status,
role.role_id        AS role_id,
JSON_UNQUOTE(JSON_EXTRACT(
  role.title,
  language.title_path
))                  AS role,
role.status         AS role_status
FROM team
JOIN language     ON language.status  = 0
LEFT JOIN `group` ON team.group_id    = `group`.group_id
LEFT JOIN permit  ON `group`.group_id = permit.group_id
LEFT JOIN role    ON permit.role_id   = role.role_id
LEFT JOIN `user`    ON team.user_id     = `user`.user_id;


CREATE OR REPLACE
ALGORITHM=UNDEFINED
DEFINER = CURRENT_USER
SQL SECURITY INVOKER
VIEW users AS SELECT
`user`.user_id        AS user_id,
`user`.login          AS login,
`user`.email          AS email,
`user`.phone          AS phone,
`user`.photo          AS photo,
`user`.status         AS user_status,
`group`.group_id    AS group_id,
JSON_UNQUOTE(JSON_EXTRACT(
  `group`.title,
  language.title_path
))                  AS `group`,
`group`.users_limit AS users_limit,
`group`.status      AS group_status,
role.role_id        AS role_id,
JSON_UNQUOTE(JSON_EXTRACT(
  role.title,
  language.title_path
))                  AS role,
role.status         AS role_status
FROM `user`
JOIN language      ON language.status  = 0
LEFT JOIN team     ON `user`.user_id     = team.user_id
LEFT JOIN `group`  ON team.group_id    = `group`.group_id
LEFT JOIN permit   ON `group`.group_id = permit.group_id
LEFT JOIN role     ON permit.role_id   = role.role_id;


CREATE OR REPLACE
ALGORITHM=UNDEFINED
DEFINER = CURRENT_USER
SQL SECURITY INVOKER
VIEW views AS SELECT
view.control_id          AS control_id,
view.target              AS target,
view.locate_id           AS source,
source.title             AS locate,
src_dec.title            AS dec_title,
src_build.title          AS build,
src_dec.name             AS src_name,
src_dec.title            AS src_dec,
src_pro.title            AS src_project,
`group`.group_id         AS group_id,
`group`.status           AS group_status,
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
LEFT JOIN `group`          ON permit.group_id     = `group`.group_id;


CREATE OR REPLACE
ALGORITHM=UNDEFINED
DEFINER = CURRENT_USER
SQL SECURITY INVOKER
VIEW rbac_map AS SELECT
locate.locate_id AS locate_id,
CASE locate.name
  WHEN '' THEN CONCAT(decision.name, locate.locate_id)
	ELSE locate.name
END              AS name,
locate.serial    AS serial,
`group`.group_id AS group_id,
role.role_id     AS role_id,
`group`.status   AS group_status,
role.status      AS role_status
FROM access
LEFT JOIN role     ON access.role_id     = role.role_id
LEFT JOIN permit   ON role.role_id       = permit.role_id
LEFT JOIN `group`  ON permit.group_id    = `group`.group_id
LEFT JOIN locate   ON access.locate_id   = locate.locate_id
LEFT JOIN decision ON locate.decision_id = decision.decision_id;


CREATE OR REPLACE
ALGORITHM=UNDEFINED
DEFINER = CURRENT_USER
SQL SECURITY INVOKER
VIEW rbac_maps AS SELECT
locate.locate_id       AS locate_id,
component.component_id AS component_id,
locate.serial          AS serial,
`group`.group_id       AS group_id,
role.role_id           AS role_id,
`group`.status         AS group_status,
role.status            AS role_status
FROM access
LEFT JOIN role      ON access.role_id        = role.role_id
LEFT JOIN permit    ON role.role_id          = permit.role_id
LEFT JOIN `group`   ON permit.group_id       = `group`.group_id
LEFT JOIN locate    ON access.locate_id      = locate.locate_id
LEFT JOIN decision  ON locate.decision_id    = decision.decision_id
LEFT JOIN component ON decision.component_id = component.component_id;


CREATE OR REPLACE
ALGORITHM=UNDEFINED
DEFINER = CURRENT_USER
SQL SECURITY INVOKER
VIEW rbac_schema AS SELECT
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
c1.class               AS project_config,
component.component_id AS component_id,
component.class        AS component_class,
component.config_id    AS config_id,
c2.class               AS config
FROM locate
LEFT JOIN decision     ON locate.decision_id    = decision.decision_id
LEFT JOIN project      ON decision.project_id   = project.project_id
LEFT JOIN config AS c1 ON project.config_id     = c1.config_id
LEFT JOIN component    ON decision.component_id = component.component_id
LEFT JOIN config AS c2 ON component.config_id   = c2.config_id
LEFT JOIN build        ON locate.build_id       = build.build_id;


CREATE OR REPLACE
ALGORITHM=UNDEFINED
DEFINER = CURRENT_USER
SQL SECURITY INVOKER
VIEW rbac_matrix AS SELECT
privilege.locate_id    AS locate_id,
locate.name            AS name,
component.component_id AS component_id,
event.event_id         AS event_id,
event.name             AS event,
config.class           AS config,
event.access           AS access,
`group`.group_id       AS group_id,
role.role_id           AS role_id,
`group`.status         AS group_status,
role.status            AS role_status
FROM rule
LEFT JOIN role      ON rule.role_id        = role.role_id
LEFT JOIN permit    ON role.role_id        = permit.role_id
LEFT JOIN `group`   ON permit.group_id     = `group`.group_id
LEFT JOIN privilege ON rule.privilege_id   = privilege.privilege_id
LEFT JOIN event     ON privilege.event_id  = event.event_id
LEFT JOIN component ON event.component_id  = component.component_id
LEFT JOIN config    ON component.config_id = config.config_id
LEFT JOIN locate    ON privilege.locate_id = locate.locate_id;


CREATE OR REPLACE
ALGORITHM=UNDEFINED
DEFINER = CURRENT_USER
SQL SECURITY INVOKER
VIEW rbac_views   AS SELECT
view.control_id       AS control_id,
control.config_id     AS config_id,
decision.component_id AS component_id,
view.target           AS target,
locate.name           AS name,
view.locate_id        AS source,
`group`.group_id      AS group_id,
role.role_id          AS role_id,
control.class         AS class,
config.class          AS config,
control.self          AS self,
event.name            AS event,
event.access          AS access,
`group`.status        AS group_status,
role.status           AS role_status,
view.serial           AS serial
FROM view
LEFT JOIN control   ON view.control_id    = control.control_id
LEFT JOIN config    ON control.config_id  = config.config_id
LEFT JOIN event     ON control.event_id   = event.event_id
LEFT JOIN access    ON view.target        = access.locate_id
LEFT JOIN role      ON access.role_id     = role.role_id
LEFT JOIN permit    ON role.role_id       = permit.role_id
LEFT JOIN `group`   ON permit.group_id    = `group`.group_id
LEFT JOIN locate    ON view.target        = locate.locate_id
LEFT JOIN decision  ON locate.decision_id = decision.decision_id;


CREATE OR REPLACE
ALGORITHM=UNDEFINED
DEFINER = CURRENT_USER
SQL SECURITY INVOKER
VIEW rbac_additions AS SELECT
addon.locate_id   AS locate_id,
plugin.plugin_id  AS plugin_id,
plugin.config_id  AS config_id,
`group`.group_id  AS group_id,
role.role_id      AS role_id,
`group`.status    AS group_status,
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
LEFT JOIN `group`  ON permit.group_id  = `group`.group_id
LEFT JOIN config   ON plugin.config_id = config.config_id;


CREATE OR REPLACE
ALGORITHM=UNDEFINED
DEFINER = CURRENT_USER
SQL SECURITY INVOKER
VIEW rbac_locs AS SELECT
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


CREATE OR REPLACE
ALGORITHM=UNDEFINED
DEFINER = CURRENT_USER
SQL SECURITY INVOKER
VIEW rbac_events AS SELECT
locate.locate_id       AS locate_id,
component.component_id AS component_id,
event.event_id         AS event_id,
event.name             AS event,
JSON_UNQUOTE(JSON_EXTRACT(
  event.title,
  language.title_path
))                     AS title,
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


CREATE OR REPLACE
ALGORITHM=UNDEFINED
DEFINER = CURRENT_USER
SQL SECURITY INVOKER
VIEW rbac_navs AS SELECT
navigate.locate_id AS locate_id,
navigate.menu_id   AS menu_id,
markup.markup      AS markup
FROM navigate
LEFT JOIN menu   ON navigate.menu_id = menu.menu_id
LEFT JOIN markup ON menu.markup_id   = markup.markup_id;


CREATE OR REPLACE
ALGORITHM=UNDEFINED
DEFINER = CURRENT_USER
SQL SECURITY INVOKER
VIEW rbac_items AS SELECT DISTINCT
menuitem.item_id    AS item_id,
reference.locate_id AS locate_id,
reference.event_id  AS event_id,
CASE
  WHEN reference.locate_id = 0 OR reference.locate_id IS NULL THEN 0
	ELSE `group`.group_id
END                 AS group_id,
CASE
	WHEN reference.locate_id = 0 OR reference.locate_id IS NULL THEN 0
	ELSE `group`.status
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
menuitem.`empty`      AS `empty`,
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
reference.status +
menuitem.status     AS status,
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
LEFT JOIN `group`   ON `group`.group_id      = permit.group_id
LEFT JOIN menu      ON menuitem.menu_id      = menu.menu_id;


CREATE OR REPLACE
ALGORITHM=UNDEFINED
DEFINER = CURRENT_USER
SQL SECURITY INVOKER
VIEW rbac_modifies AS SELECT DISTINCT
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
