/*
SQLyog Ultimate v10.00 Beta1
MySQL - 5.6.12-log : Database - suji_auth
*********************************************************************
*/

/*!40101 SET NAMES utf8 */;

/*!40101 SET SQL_MODE=''*/;

/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
CREATE DATABASE /*!32312 IF NOT EXISTS*/`suji_auth` /*!40100 DEFAULT CHARACTER SET utf8 */;

USE `suji_auth`;

/*Table structure for table `accounts` */

DROP TABLE IF EXISTS `accounts`;

CREATE TABLE `accounts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(16) NOT NULL,
  `sha_userpass_hash` varchar(40) NOT NULL DEFAULT '',
  `admin_level` int(11) DEFAULT NULL,
  `email` varchar(40) NOT NULL DEFAULT 'none',
  `title` int(11) DEFAULT NULL,
  `rank` int(11) DEFAULT NULL,
  `icon` int(11) DEFAULT NULL,
  `username_color` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`,`username`,`sha_userpass_hash`,`email`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=latin1;

/*Table structure for table `awarded_titles` */

DROP TABLE IF EXISTS `awarded_titles`;

CREATE TABLE `awarded_titles` (
  `user_id` int(11) NOT NULL,
  `title_id` int(11) NOT NULL,
  PRIMARY KEY (`user_id`,`title_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*Table structure for table `group_members` */

DROP TABLE IF EXISTS `group_members`;

CREATE TABLE `group_members` (
  `group_id` int(10) NOT NULL,
  `user_id` int(10) NOT NULL,
  `member_level` smallint(6) DEFAULT '0',
  PRIMARY KEY (`group_id`,`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*Table structure for table `groups` */

DROP TABLE IF EXISTS `groups`;

CREATE TABLE `groups` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `name` varchar(32) NOT NULL,
  `accessType` tinyint(3) DEFAULT NULL,
  `owner` int(11) DEFAULT NULL,
  `motd` varchar(1024) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=latin1;

/*Table structure for table `titles` */

DROP TABLE IF EXISTS `titles`;

CREATE TABLE `titles` (
  `title_id` int(11) NOT NULL,
  `title_text` varchar(64) DEFAULT NULL,
  `unique` tinyint(4) NOT NULL DEFAULT '0',
  PRIMARY KEY (`title_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*Table structure for table `user_messages` */

DROP TABLE IF EXISTS `user_messages`;

CREATE TABLE `user_messages` (
  `sender_id` int(10) DEFAULT NULL,
  `receiver_id` int(10) DEFAULT NULL,
  `message_type` tinyint(3) DEFAULT NULL,
  `message` varchar(256) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*Table structure for table `user_relations` */

DROP TABLE IF EXISTS `user_relations`;

CREATE TABLE `user_relations` (
  `user_id` int(10) unsigned NOT NULL,
  `user2_id` int(10) NOT NULL,
  `relation_type` tinyint(4) DEFAULT NULL,
  PRIMARY KEY (`user_id`,`user2_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;
