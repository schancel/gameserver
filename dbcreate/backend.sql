SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL,ALLOW_INVALID_DATES';

SHOW WARNINGS;
DROP SCHEMA IF EXISTS `sujigo` ;
CREATE SCHEMA IF NOT EXISTS `sujigo` DEFAULT CHARACTER SET utf8 ;
SHOW WARNINGS;
USE `sujigo` ;

-- -----------------------------------------------------
-- Table `accounts`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `accounts` ;

SHOW WARNINGS;
CREATE TABLE IF NOT EXISTS `accounts` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `username` VARCHAR(16) NOT NULL,
  `pass` VARCHAR(256) NOT NULL DEFAULT '',
  `salt` VARCHAR(45) NULL DEFAULT 'UUID()',
  `admin_level` INT(11) NULL DEFAULT NULL,
  `email` VARCHAR(40) NULL DEFAULT 'none',
  `title` INT(11) NULL DEFAULT NULL,
  `rank` INT(11) NULL DEFAULT NULL,
  `icon` INT(11) NULL DEFAULT NULL,
  `username_color` INT(11) NULL DEFAULT NULL,
  PRIMARY KEY (`id`))
ENGINE = InnoDB
AUTO_INCREMENT = 4
DEFAULT CHARACTER SET = latin1;

SHOW WARNINGS;
CREATE UNIQUE INDEX `USERNAME` ON `accounts` (`username` ASC);

SHOW WARNINGS;

-- -----------------------------------------------------
-- Table `titles`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `titles` ;

SHOW WARNINGS;
CREATE TABLE IF NOT EXISTS `titles` (
  `title_id` INT(11) NOT NULL,
  `title_text` VARCHAR(64) NULL DEFAULT NULL,
  `unique` TINYINT(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`title_id`))
ENGINE = InnoDB
DEFAULT CHARACTER SET = latin1;

SHOW WARNINGS;

-- -----------------------------------------------------
-- Table `awarded_titles`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `awarded_titles` ;

SHOW WARNINGS;
CREATE TABLE IF NOT EXISTS `awarded_titles` (
  `accounts_id` INT(11) NOT NULL,
  `title_id` INT(11) NOT NULL,
  PRIMARY KEY (`accounts_id`, `title_id`))
ENGINE = InnoDB
DEFAULT CHARACTER SET = latin1;

SHOW WARNINGS;

-- -----------------------------------------------------
-- Table `relationships`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `relationships` ;

SHOW WARNINGS;
CREATE TABLE IF NOT EXISTS `relationships` (
  `accounts_id` INT(11) NOT NULL,
  `buddy_id` INT(11) NOT NULL,
  `type` INT(11) NOT NULL,
  PRIMARY KEY (`accounts_id`, `buddy_id`))
ENGINE = InnoDB
DEFAULT CHARACTER SET = latin1;

SHOW WARNINGS;
CREATE INDEX `fk_accounts_has_accounts_accounts1_idx` ON `relationships` (`accounts_id` ASC);

SHOW WARNINGS;

-- -----------------------------------------------------
-- Table `user_messages`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `user_messages` ;

SHOW WARNINGS;
CREATE TABLE IF NOT EXISTS `user_messages` (
  `accounts_id` INT(11) NOT NULL,
  `sender_id` INT(11) NOT NULL,
  `message_type` TINYINT(3) NULL DEFAULT NULL,
  `message` VARCHAR(256) NULL DEFAULT NULL,
  PRIMARY KEY (`accounts_id`))
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8;

SHOW WARNINGS;
CREATE INDEX `fk_user_messages_accounts2_idx` ON `user_messages` (`accounts_id` ASC);

SHOW WARNINGS;
USE `sujigo` ;

-- -----------------------------------------------------
-- function auth_account
-- -----------------------------------------------------

USE `sujigo`;
DROP function IF EXISTS `auth_account`;
SHOW WARNINGS;

DELIMITER $$
USE `sujigo`$$
CREATE DEFINER=`root`@`localhost` FUNCTION `auth_account`(p_user VARCHAR(16), p_pass VARCHAR(256)) RETURNS varchar(16) CHARSET utf8
BEGIN
	SELECT USERNAME FROM accounts WHERE username = p_user and pass = SHA2(CONCAT(p_pass, salt), 256) INTO @v_user;

	RETURN @v_user;
RETURN 1;
END$$
SHOW WARNINGS;

-- -----------------------------------------------------
-- procedure create_account
-- -----------------------------------------------------

USE `sujigo`;
DROP procedure IF EXISTS `create_account`;
SHOW WARNINGS;

DELIMITER $$
USE `sujigo`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `create_account`(P_username varchar(16), P_passw varchar(256))
BEGIN
	SET @V_SALT = UUID();
	SET @V_PASS = SHA2(CONCAT(P_PASSW, @V_SALT), 256);

	INSERT INTO accounts (username, pass, salt)
		VALUES (P_username, @V_PASS, @V_SALT);
END$$
SHOW WARNINGS;

SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
