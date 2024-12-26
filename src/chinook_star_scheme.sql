-- Vytvorenie databázy, ak ešte neexistuje
CREATE DATABASE IF NOT EXISTS `chinook_star_scheme`;
USE `chinook_star_scheme`;

-- Vypnutie kontrol unikátnych hodnôt a cudzích kľúčov pre bezpečný import
SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- -----------------------------------------------------
-- Dimenzia Track
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `dim_track` (
  `track_id` INT NOT NULL,
  `name` VARCHAR(200) NOT NULL,
  `album_title` VARCHAR(160) NOT NULL,
  `artist_name` VARCHAR(120) NOT NULL,
  `media_type` VARCHAR(120) NOT NULL,
  `genre` VARCHAR(120) NOT NULL,
  `composer` VARCHAR(220) NOT NULL,
  `milliseconds` INT NOT NULL,
  `bytes` INT NOT NULL,
  `unit_price` DECIMAL(10,2) NOT NULL,
  PRIMARY KEY (`track_id`)
);

-- -----------------------------------------------------
-- Dimenzia Customer
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `dim_customer` (
  `customer_id` INT NOT NULL,
  `first_name` VARCHAR(40) NOT NULL,
  `last_name` VARCHAR(40) NOT NULL,
  `company` VARCHAR(80) NOT NULL,
  `address` VARCHAR(70) NOT NULL,
  `city` VARCHAR(40) NOT NULL,
  `state` VARCHAR(40) NOT NULL,
  `country` VARCHAR(40) NOT NULL,
  `postal_code` VARCHAR(24) NOT NULL,
  `phone` VARCHAR(24) NOT NULL,
  `fax` VARCHAR(24) NOT NULL,
  `email` VARCHAR(60) NOT NULL,
  PRIMARY KEY (`customer_id`)
);

-- -----------------------------------------------------
-- Dimenzia Employee
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `dim_employee` (
  `employee_id` INT NOT NULL,
  `full_name` VARCHAR(50) NOT NULL,
  `title` VARCHAR(30) NOT NULL,
  `supervisor_name` VARCHAR(50) NOT NULL,
  `hire_date` DATE NOT NULL,
  `address` VARCHAR(70) NOT NULL,
  `city` VARCHAR(40) NOT NULL,
  `state` VARCHAR(40) NOT NULL,
  `country` VARCHAR(40) NOT NULL,
  `email` VARCHAR(60) NOT NULL,
  PRIMARY KEY (`employee_id`)
);

-- -----------------------------------------------------
-- Dimenzia Playlist
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `dim_playlist` (
  `playlist_id` INT NOT NULL,
  `name` VARCHAR(120) NOT NULL,
  PRIMARY KEY (`playlist_id`)
);

-- -----------------------------------------------------
-- Dimenzia Date
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `dim_date` (
  `date_id` INT NOT NULL,
  `date` DATE NOT NULL,
  `day` INT NOT NULL,
  `month` INT NOT NULL,
  `year` INT NOT NULL,
  `quarter` INT NOT NULL,
  PRIMARY KEY (`date_id`)
);

-- -----------------------------------------------------
-- Faktová tabuľka Invoice
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `fact_invoice` (
  `fact_id` INT NOT NULL,
  `customer_id` INT NOT NULL,
  `employee_id` INT NOT NULL,
  `date_id` INT NOT NULL,
  `track_id` INT NOT NULL,
  `playlist_id` INT NOT NULL,
  `unit_price` DECIMAL(10,2) NOT NULL,
  `quantity` INT NOT NULL,
  `total` DECIMAL(10,2) NOT NULL,
  PRIMARY KEY (`fact_id`),
  INDEX `idx_customer_id` (`customer_id`),
  INDEX `idx_employee_id` (`employee_id`),
  INDEX `idx_date_id` (`date_id`),
  INDEX `idx_track_id` (`track_id`),
  INDEX `idx_playlist_id` (`playlist_id`),
  CONSTRAINT `fk_fact_customer`
    FOREIGN KEY (`customer_id`)
    REFERENCES `dim_customer` (`customer_id`),
  CONSTRAINT `fk_fact_employee`
    FOREIGN KEY (`employee_id`)
    REFERENCES `dim_employee` (`employee_id`),
  CONSTRAINT `fk_fact_date`
    FOREIGN KEY (`date_id`)
    REFERENCES `dim_date` (`date_id`),
  CONSTRAINT `fk_fact_track`
    FOREIGN KEY (`track_id`)
    REFERENCES `dim_track` (`track_id`),
  CONSTRAINT `fk_fact_playlist`
    FOREIGN KEY (`playlist_id`)
    REFERENCES `dim_playlist` (`playlist_id`)
);

-- Obnovenie pôvodných nastavení
SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
