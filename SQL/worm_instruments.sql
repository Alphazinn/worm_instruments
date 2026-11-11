-- worm_instruments: run by the resource itself on every start (Server/Database.lua), so nobody needs to run it by
-- hand; every statement is CREATE TABLE IF NOT EXISTS, so the rows already there are kept. Two tables, read into memory
-- when the resource starts (PLAN section 7): nothing else outlives a restart.

-- A character banned from every instrument. ends_at is unix seconds; 0 is for ever. A ban past its end is ignored
-- when read and deleted at the next start.
CREATE TABLE IF NOT EXISTS `worm_instruments_bans` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `identifier` VARCHAR(64) NOT NULL,
    `player_name` VARCHAR(64) NOT NULL,
    `reason` VARCHAR(120) NOT NULL,
    `banned_by` VARCHAR(64) NOT NULL,
    `created_at` INT NOT NULL,
    `ends_at` INT NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`),
    INDEX `identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- A no-playing zone an admin added in game (the zones of Config.Zones are never stored).
CREATE TABLE IF NOT EXISTS `worm_instruments_zones` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(48) NOT NULL,
    `x` FLOAT NOT NULL,
    `y` FLOAT NOT NULL,
    `z` FLOAT NOT NULL,
    `radius` FLOAT NOT NULL,
    `added_by` VARCHAR(64) NOT NULL,
    `created_at` INT NOT NULL,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
