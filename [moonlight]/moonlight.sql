-- --------------------------------------------------------
-- PROJEKT: MOONLIGHT RPG (Hard RP / Economy)
-- SPECYFIKACJA: v5.0
-- --------------------------------------------------------

-- 1. KONTA (Logowanie i Administracja)
CREATE TABLE IF NOT EXISTS `accounts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(32) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `salt` varchar(64) DEFAULT NULL, -- Opcjonalne przy bcrypt, ale zgodne ze specyfikacją
  `serial` varchar(32) NOT NULL,
  `register_date` timestamp NOT NULL DEFAULT current_timestamp(),
  `last_login` timestamp NULL DEFAULT NULL,
  `admin_level` tinyint(3) unsigned NOT NULL DEFAULT 0,
  `discord_id` varchar(32) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. POSTACIE (Biologia i Pozycja)
CREATE TABLE IF NOT EXISTS `characters` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `account_id` int(11) NOT NULL,
  `firstname` varchar(32) NOT NULL,
  `lastname` varchar(32) NOT NULL,
  `age` int(11) NOT NULL DEFAULT 21,
  `skin_id` int(11) NOT NULL DEFAULT 0,
  
  -- Finanse
  `money` bigint(20) NOT NULL DEFAULT 0,
  `bank_money` bigint(20) NOT NULL DEFAULT 0,
  
  -- Statusy Biologiczne (0-100)
  `health` float NOT NULL DEFAULT 100,
  `hunger` float NOT NULL DEFAULT 100,
  `thirst` float NOT NULL DEFAULT 100,
  `stamina` float NOT NULL DEFAULT 100,
  
  -- Pozycja i Spawn
  `pos_x` float NOT NULL DEFAULT 0,
  `pos_y` float NOT NULL DEFAULT 0,
  `pos_z` float NOT NULL DEFAULT 0,
  `rotation` float NOT NULL DEFAULT 0,
  `dimension` int(11) NOT NULL DEFAULT 0,
  `interior` int(11) NOT NULL DEFAULT 0,
  
  -- Śmierć i BW
  `is_dead` tinyint(1) NOT NULL DEFAULT 0,
  `bw_time_left` int(11) NOT NULL DEFAULT 0, -- sekundy
  
  -- Praca i Frakcja
  `job_id` varchar(50) DEFAULT NULL, -- np. 'courier', 'warehouse'
  `faction_id` int(11) DEFAULT NULL, -- 0 lub NULL = brak
  `faction_rank` int(11) DEFAULT 0,
  
  `play_time` int(11) NOT NULL DEFAULT 0, -- minuty/godziny
  
  PRIMARY KEY (`id`),
  KEY `account_id` (`account_id`),
  CONSTRAINT `fk_char_account` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. POJAZDY (Persistence & Wear System)
CREATE TABLE IF NOT EXISTS `vehicles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `model` int(11) NOT NULL,
  `owner_id` int(11) NOT NULL, -- ID postaci (character_id), nie konta!
  
  -- Persistence (Pozycja zapisu)
  `pos_x` float NOT NULL DEFAULT 0,
  `pos_y` float NOT NULL DEFAULT 0,
  `pos_z` float NOT NULL DEFAULT 0,
  `rot_x` float NOT NULL DEFAULT 0,
  `rot_y` float NOT NULL DEFAULT 0,
  `rot_z` float NOT NULL DEFAULT 0,
  
  `parking_id` int(11) NOT NULL DEFAULT 0, -- 0=Na mapie, 1=Przechowalnia
  
  -- Fizyka i Zużycie (Hard Economy)
  `health` float NOT NULL DEFAULT 1000,
  `engine_condition` float NOT NULL DEFAULT 100.0, -- Stan silnika niezależny od HP (zacieranie)
  `oil_level` float NOT NULL DEFAULT 10.0, -- Litry oleju
  `battery_voltage` float NOT NULL DEFAULT 12.6, -- Volty
  `fuel_amount` float NOT NULL DEFAULT 50.0,
  `fuel_type` enum('petrol','diesel','lpg','electric') NOT NULL DEFAULT 'petrol',
  `mileage` float NOT NULL DEFAULT 0.0, -- Kilometry
  
  -- Wizualne
  `plate` varchar(8) NOT NULL,
  `color_json` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`color_json`)),
  `tuning_json` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`tuning_json`)),
  
  PRIMARY KEY (`id`),
  KEY `owner_id` (`owner_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. NIERUCHOMOŚCI (Podatki i Lokalizacja)
CREATE TABLE IF NOT EXISTS `properties` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `owner_id` int(11) NOT NULL DEFAULT 0, -- 0 = Do kupienia
  `cost` int(11) NOT NULL DEFAULT 0,
  
  -- Lokalizacja
  `enter_x` float NOT NULL,
  `enter_y` float NOT NULL,
  `enter_z` float NOT NULL,
  `exit_x` float NOT NULL,
  `exit_y` float NOT NULL,
  `exit_z` float NOT NULL,
  `interior_id` int(11) NOT NULL DEFAULT 0,
  `dimension_id` int(11) NOT NULL DEFAULT 0,
  
  -- System Podatkowy
  `tax_paid_until` timestamp NULL DEFAULT NULL, -- Data wygaśnięcia opłaty
  `locked` tinyint(1) NOT NULL DEFAULT 1,
  
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. EKWIPUNEK (Items)
CREATE TABLE IF NOT EXISTS `items` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `owner_id` int(11) NOT NULL, -- character_id
  `item_id` int(11) NOT NULL, -- ID definicji przedmiotu (np. 1 = telefon)
  `item_value` text DEFAULT NULL, -- Metadane (np. numer telefonu, ilość amunicji)
  `slot` int(11) NOT NULL DEFAULT 0, -- Slot w GUI
  `count` int(11) NOT NULL DEFAULT 1,
  
  PRIMARY KEY (`id`),
  KEY `owner_id` (`owner_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 6. GROUND ITEMS (Przedmioty na ziemi - Persistence)
CREATE TABLE IF NOT EXISTS `ground_items` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `item_id` int(11) NOT NULL,
  `item_value` text DEFAULT NULL,
  `count` int(11) NOT NULL DEFAULT 1,
  
  -- Pozycja
  `pos_x` float NOT NULL,
  `pos_y` float NOT NULL,
  `pos_z` float NOT NULL,
  `dimension` int(11) NOT NULL DEFAULT 0,
  `interior` int(11) NOT NULL DEFAULT 0,
  
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 7. LOGI (System CEO)
CREATE TABLE IF NOT EXISTS `server_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `category` varchar(50) NOT NULL, -- CHAT, ECONOMY, ADMIN, ITEMS
  `content` text NOT NULL,
  `account_id` int(11) DEFAULT NULL, -- Kto wykonał akcję
  `target_id` int(11) DEFAULT NULL,  -- Na kim/czym
  `date` timestamp NOT NULL DEFAULT current_timestamp(),
  
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;