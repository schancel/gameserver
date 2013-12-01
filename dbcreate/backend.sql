SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL,ALLOW_INVALID_DATES';

CREATE SCHEMA IF NOT EXISTS `sujigo` DEFAULT CHARACTER SET utf8 ;
USE `sujigo` ;

-- -----------------------------------------------------
-- Table `sujigo`.`accounts`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `sujigo`.`accounts` (
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

CREATE UNIQUE INDEX `USERNAME` ON `sujigo`.`accounts` (`username` ASC);


-- -----------------------------------------------------
-- Table `sujigo`.`titles`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `sujigo`.`titles` (
  `title_id` INT(11) NOT NULL,
  `title_text` VARCHAR(64) NULL DEFAULT NULL,
  `unique` TINYINT(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`title_id`))
ENGINE = InnoDB
DEFAULT CHARACTER SET = latin1;


-- -----------------------------------------------------
-- Table `sujigo`.`awarded_titles`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `sujigo`.`awarded_titles` (
  `accounts_id` INT(11) NOT NULL,
  `title_id` INT(11) NOT NULL,
  PRIMARY KEY (`accounts_id`, `title_id`),
  CONSTRAINT `USERID`
    FOREIGN KEY (`accounts_id`)
    REFERENCES `sujigo`.`accounts` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `TITLEID`
    FOREIGN KEY (`title_id`)
    REFERENCES `sujigo`.`titles` (`title_id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = latin1;

CREATE INDEX `TITLEID_idx` ON `sujigo`.`awarded_titles` (`title_id` ASC);


-- -----------------------------------------------------
-- Table `sujigo`.`relationships`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `sujigo`.`relationships` (
  `accounts_id` INT(11) NOT NULL,
  `buddy_id` INT(11) NOT NULL,
  `type` INT(11) NOT NULL,
  PRIMARY KEY (`accounts_id`, `buddy_id`),
  CONSTRAINT `fk_accounts_has_accounts_accounts1`
    FOREIGN KEY (`accounts_id`)
    REFERENCES `sujigo`.`accounts` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_accounts_has_accounts_accounts2`
    FOREIGN KEY (`buddy_id`)
    REFERENCES `sujigo`.`accounts` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = latin1;

CREATE INDEX `fk_accounts_has_accounts_accounts2_idx` ON `sujigo`.`relationships` (`buddy_id` ASC);

CREATE INDEX `fk_accounts_has_accounts_accounts1_idx` ON `sujigo`.`relationships` (`accounts_id` ASC);


-- -----------------------------------------------------
-- Table `sujigo`.`user_messages`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `sujigo`.`user_messages` (
  `accounts_id` INT(11) NOT NULL,
  `sender_id` INT(11) NOT NULL,
  `message_type` TINYINT(3) NULL DEFAULT NULL,
  `message` VARCHAR(256) NULL DEFAULT NULL,
  PRIMARY KEY (`accounts_id`),
  CONSTRAINT `fk_user_messages_accounts1`
    FOREIGN KEY (`sender_id`)
    REFERENCES `sujigo`.`accounts` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_user_messages_accounts2`
    FOREIGN KEY (`accounts_id`)
    REFERENCES `sujigo`.`accounts` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8;

CREATE INDEX `fk_user_messages_accounts2_idx` ON `sujigo`.`user_messages` (`accounts_id` ASC);

CREATE INDEX `fk_user_messages_accounts1` ON `sujigo`.`user_messages` (`sender_id` ASC);

USE `sujigo` ;

-- -----------------------------------------------------
-- function auth_account
-- -----------------------------------------------------

DELIMITER $$
USE `sujigo`$$
CREATE DEFINER=`root`@`localhost` FUNCTION `auth_account`(p_user VARCHAR(16), p_pass VARCHAR(256)) RETURNS tinyint(1)
BEGIN
	DECLARE v_USER BOOLEAN;
	SELECT true FROM accounts WHERE UPPER(USERNAME) = UPPER(p_user) and pass = SHA2(CONCAT(p_pass, salt), 256) INTO v_USER;
	IF v_USER IS null THEN
		RETURN false;
	ELSE
		RETURN true;
	END IF;
END$$

DELIMITER ;

-- -----------------------------------------------------
-- procedure create_account
-- -----------------------------------------------------

DELIMITER $$
USE `sujigo`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `create_account`(P_username varchar(16), P_passw varchar(256))
BEGIN
	DECLARE V_SALT VARCHAR(256);
	DECLARE V_PASS VARCHAR(256);
	SET V_SALT = UUID();
	SET V_PASS = SHA2(CONCAT(P_passw, V_SALT), 256);

	INSERT INTO accounts (username, pass, salt)
		VALUES (P_username, V_PASS, V_SALT);
END$$

DELIMITER ;

SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
