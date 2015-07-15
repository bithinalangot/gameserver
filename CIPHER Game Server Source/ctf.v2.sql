-- MySQL dump 10.10
--
-- Host: localhost    Database: ctf
-- ------------------------------------------------------
-- Server version	5.0.27

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Current Database: `ctf`
--

/*!40000 DROP DATABASE IF EXISTS `ctf`*/;

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `ctf` /*!40100 DEFAULT CHARACTER SET latin1 */;

USE `ctf`;

DROP TABLE IF EXISTS `advisory`;
CREATE TABLE `advisory` (
	`id` int(11) NOT NULL auto_increment,
	`fi_team` int(11) NOT NULL,
	`fi_service` int(11) default NULL,
	`advisory` blob,
	`exploit` blob,
	`patch` blob,
	`score` int(11) default NULL,
	`submittime` int(11) default NULL,
	`publishtime` int(11) default NULL,
	`judge` varchar(255) default NULL,
	`judgecomment` blob,
	PRIMARY KEY  (`id`),
	KEY `fi_team` (`fi_team`),
	KEY `fi_service` (`fi_service`),
	CONSTRAINT `advisory_ibfk_2` FOREIGN KEY (`fi_team`) REFERENCES `team` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT `advisory_ibfk_3` FOREIGN KEY (`fi_service`) REFERENCES `service` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


--
-- Table structure for table `announce`
--

DROP TABLE IF EXISTS `announce`;
CREATE TABLE `announce` (
  `id` int(11) NOT NULL auto_increment,
  `fi_game` int(11) NOT NULL,
  `timestamp` datetime default NULL,
  `message` blob,
  PRIMARY KEY  (`id`),
  KEY `fi_game` (`fi_game`),
  CONSTRAINT `announce_ibfk_1` FOREIGN KEY (`fi_game`) REFERENCES `game` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `announce`
--

LOCK TABLES `announce` WRITE;
/*!40000 ALTER TABLE `announce` DISABLE KEYS */;
/*!40000 ALTER TABLE `announce` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `config`
--

DROP TABLE IF EXISTS `config`;
CREATE TABLE `config` (
  `fi_game` int(11) default NULL COMMENT 'if NULL is taken as standard for all games, unless overwritten by specified value',
  `name` varchar(255) default NULL,
  `value` varchar(255) default NULL,
  `comment` blob,
  KEY `fi_game` (`fi_game`),
  KEY `key_name` (`name`),
  CONSTRAINT `config_ibfk_1` FOREIGN KEY (`fi_game`) REFERENCES `game` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `config`
--

LOCK TABLES `config` WRITE;
/*!40000 ALTER TABLE `config` DISABLE KEYS */;
INSERT INTO `config` VALUES (NULL,'debug','4','debug level (used for logging event to DB and stdout)'),(NULL,'flag_id_len','8','length of flag-id in bytes'),(NULL,'flag_len','16','length of flag in bytes'),(NULL,'script_delay','15','seconds that are allowed for each script. script is killed otherwise'),(NULL,'display_fresh_scores','600','ss_flags / team_service split the display into \"fresh\" and \"stale\" flags; this determines how many seconds a score is still \"fresh\"'),(NULL,'stale_drones','120','seconds a drone is considered stale if not sending heartbeats'),(NULL,'kill_zombies','0','set to 1, if monitor should kill zombies. if set to 0, zombies are only reported, but not killed.'),(NULL,'store_performance','0','set to 1 in order to store measurements on performance of gameserver-scripts'),(NULL,'foul_timeout','240','number of seconds a service is forced down, if a foul is detected. set to 0 to disable');
/*!40000 ALTER TABLE `config` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `drone`
--

DROP TABLE IF EXISTS `drone`;
CREATE TABLE `drone` (
  `id` int(11) NOT NULL auto_increment,
  `heartbeat` datetime default NULL,
  `host` varchar(255) NOT NULL default '',
  `pid` int(11) NOT NULL,
  `status` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `drone`
--

LOCK TABLES `drone` WRITE;
/*!40000 ALTER TABLE `drone` DISABLE KEYS */;
/*!40000 ALTER TABLE `drone` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `event`
--

DROP TABLE IF EXISTS `event`;
CREATE TABLE `event` (
  `id` int(11) NOT NULL auto_increment,
  `fi_game` int(11) default NULL,
  `fi_service` int(11) default NULL,
  `fi_team` int(11) default NULL,
  `timestamp` datetime default NULL,
  `level` int(11) default '0',
  `message` blob,
  PRIMARY KEY  (`id`),
  KEY `fi_game` (`fi_game`),
  KEY `fi_team` (`fi_team`),
  KEY `fi_service` (`fi_service`),
  CONSTRAINT `event_ibfk_1` FOREIGN KEY (`fi_game`) REFERENCES `game` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `event_ibfk_2` FOREIGN KEY (`fi_team`) REFERENCES `team` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `event_ibfk_3` FOREIGN KEY (`fi_service`) REFERENCES `service` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `event`
--

LOCK TABLES `event` WRITE;
/*!40000 ALTER TABLE `event` DISABLE KEYS */;
/*!40000 ALTER TABLE `event` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `flag`
--

DROP TABLE IF EXISTS `flag`;
CREATE TABLE `flag` (
  `id` int(11) NOT NULL auto_increment,
  `fi_game` int(11) NOT NULL,
  `fi_service` int(11) NOT NULL,
  `fi_team` int(11) NOT NULL,
  `valid_from` datetime default NULL COMMENT 'time when flag was placed on target system (or: should have been placed)',
  `valid_until` datetime default NULL COMMENT 'time when flag will be checked by gameserver',
  `valid_expires` datetime default NULL COMMENT 'time until which the flag will result in offensive scores, if submitted by other team',
  `flag_id` varchar(255) NOT NULL,
  `flag` varchar(255) NOT NULL,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `fi_game` (`fi_game`,`flag`),
  KEY `fi_game_2` (`fi_game`,`fi_service`,`fi_team`),
  KEY `fi_team` (`fi_team`),
  KEY `fi_service` (`fi_service`),
  CONSTRAINT `flag_ibfk_1` FOREIGN KEY (`fi_game`) REFERENCES `game` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `flag_ibfk_2` FOREIGN KEY (`fi_team`) REFERENCES `team` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `flag_ibfk_3` FOREIGN KEY (`fi_service`) REFERENCES `service` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `flag`
--

LOCK TABLES `flag` WRITE;
/*!40000 ALTER TABLE `flag` DISABLE KEYS */;
/*!40000 ALTER TABLE `flag` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `game_x_service`
--

DROP TABLE IF EXISTS `game_x_service`;
CREATE TABLE `game_x_service` (
  `fi_game` int(11) NOT NULL default '0',
  `fi_service` int(11) NOT NULL default '0',
  `server_ip` varchar(255) default NULL,
  `store` varchar(255) NOT NULL COMMENT 'path to external script (usually equals "retrieve")',
  `retrieve` varchar(255) NOT NULL COMMENT 'path to external script (usually equals "store")',
  `flags_interval` int(11) NOT NULL default '60' COMMENT 'number of seconds in which interval flags are placed for this service',
  `flags_expire` int(11) NOT NULL default '600' COMMENT 'number of seconds, flags are valid for offensive scoring (relative to being placed), if submitted by different team',
  `score_offensive` int(11) NOT NULL default '10' COMMENT 'offensive scores given for team submitting this flag',
  `score_defensive` int(11) NOT NULL default '10' COMMENT 'defensive scores given to team, if no other team submitted this flag and flag can be re-read by gameserver',
  `score_uptime` int(11) NOT NULL default '10' COMMENT 'defensive scores given to team, if no other team submitted this flag',
  `info` blob COMMENT 'place for comments on this service',
  PRIMARY KEY  (`fi_game`,`fi_service`),
  KEY `fi_game` (`fi_game`),
  KEY `fi_service` (`fi_service`),
  CONSTRAINT `game_x_service_ibfk_1` FOREIGN KEY (`fi_game`) REFERENCES `game` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `game_x_service_ibfk_2` FOREIGN KEY (`fi_service`) REFERENCES `service` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `game_x_service`
--

LOCK TABLES `game_x_service` WRITE;
/*!40000 ALTER TABLE `game_x_service` DISABLE KEYS */;
INSERT INTO `game_x_service` VALUES (1,1,NULL,'testservices/false.sh','testservices/false.sh',10,600,1,1,1,NULL),(1,2,NULL,'testservices/random.sh','testservices/random.sh',10,600,1,1,1,NULL),(1,3,NULL,'testservices/test.sh','testservices/test.sh',10,600,1,1,1,NULL),(1,4,NULL,'testservices/true.sh','testservices/true.sh',10,600,1,1,1,NULL);
/*!40000 ALTER TABLE `game_x_service` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `game_x_team`
--

DROP TABLE IF EXISTS `game_x_team`;
CREATE TABLE `game_x_team` (
  `fi_game` int(11) NOT NULL default '0',
  `fi_team` int(11) NOT NULL default '0',
  `server_ip` varchar(255) NOT NULL COMMENT 'ip of team''s server. ',
  `local_ip` varchar(255) default NULL COMMENT 'local ip-range of members (x.x.x.x/n notation) [probably crrently unused?] ',
  `score_extra` int(11) NOT NULL default '10' COMMENT 'any additional scores. can be used e.g. for ethical behaviour, advisories, ...',
  `info` blob COMMENT 'place for comments',
  PRIMARY KEY  (`fi_game`,`fi_team`),
  KEY `fi_game` (`fi_game`),
  KEY `fi_team` (`fi_team`),
  CONSTRAINT `game_x_team_ibfk_1` FOREIGN KEY (`fi_game`) REFERENCES `game` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `game_x_team_ibfk_2` FOREIGN KEY (`fi_team`) REFERENCES `team` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `game_x_team`
--

LOCK TABLES `game_x_team` WRITE;
/*!40000 ALTER TABLE `game_x_team` DISABLE KEYS */;
INSERT INTO `game_x_team` VALUES (1,1,'127.0.0.1','127.0.0.1/24',0,NULL),(1,2,'127.0.1.1','127.0.1.1/24',0,NULL);
/*!40000 ALTER TABLE `game_x_team` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `game`
--

DROP TABLE IF EXISTS `game`;
CREATE TABLE `game` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(255) NOT NULL,
  `start` datetime NOT NULL,
  `stop` datetime NOT NULL,
  `master` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `webpage` varchar(255) NOT NULL,
  `info` blob,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `game`
--

LOCK TABLES `game` WRITE;
/*!40000 ALTER TABLE `game` DISABLE KEYS */;
INSERT INTO `game` VALUES (1,'Testgame','2005-08-02 11:25:59','2010-12-31 23:59:59','Lexi Pimenidis','i4@pimenidis.org','http://www.nets.rwth-aachen.de/~lexi/cipher.php','Test game that uses teh dummy scripts to test the game server.');
/*!40000 ALTER TABLE `game` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `performance`
--

DROP TABLE IF EXISTS `performance`;
CREATE TABLE `performance` (
  `fi_game` int(11) NOT NULL default '0',
  `fi_service` int(11) NOT NULL default '0',
  `fi_team` int(11) NOT NULL default '0',
  `time` datetime default NULL COMMENT 'timestamp, this record was added',
  `seconds` float(11,3) NOT NULL default '0' COMMENT 'seconds used to handle this run for this service',
	`result` int(11) default NULL COMMENT 'return code of external script',
	`store_public` blob,
	`store_internal` blob,
	`retrieve_public` blob,
	`retrieve_internal` blob,
  KEY `fi_game` (`fi_game`),
  KEY `fi_team` (`fi_team`),
  KEY `fi_service` (`fi_service`),
  CONSTRAINT `performance_ibfk_1` FOREIGN KEY (`fi_game`) REFERENCES `game` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `performance_ibfk_2` FOREIGN KEY (`fi_team`) REFERENCES `team` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `performance_ibfk_3` FOREIGN KEY (`fi_service`) REFERENCES `service` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `performance`
--

LOCK TABLES `performance` WRITE;
/*!40000 ALTER TABLE `performance` DISABLE KEYS */;
/*!40000 ALTER TABLE `performance` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `scores`
--

DROP TABLE IF EXISTS `scores`;
CREATE TABLE `scores` (
  `fi_game` int(11) NOT NULL default '0',
  `fi_service` int(11) NOT NULL default '0',
  `fi_flag` int(11) NOT NULL default '0',
  `fi_team` int(11) NOT NULL default '0',
  `fi_event` int(11) default NULL COMMENT 'reference to a more detailed description',
  `multiplier` int(11) NOT NULL default '0' COMMENT 'if =0, score is defensive score, if >0 score is offensive score',
  `time` datetime default NULL COMMENT 'time, when score was given',
  `score` float NOT NULL default '0' COMMENT 'amount of scores',
  PRIMARY KEY  (`fi_game`,`fi_flag`,`fi_service`,`fi_team`),
  KEY `fi_flag` (`fi_flag`,`fi_team`,`fi_game`),
  KEY `fi_team` (`fi_team`),
  KEY `fi_service` (`fi_service`),
  KEY `fi_event` (`fi_event`),
  CONSTRAINT `scores_ibfk_1` FOREIGN KEY (`fi_game`) REFERENCES `game` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `scores_ibfk_2` FOREIGN KEY (`fi_team`) REFERENCES `team` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `scores_ibfk_3` FOREIGN KEY (`fi_service`) REFERENCES `service` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `scores_ibfk_4` FOREIGN KEY (`fi_event`) REFERENCES `event` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `scores_ibfk_5` FOREIGN KEY (`fi_flag`) REFERENCES `flag` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `scores`
--

LOCK TABLES `scores` WRITE;
/*!40000 ALTER TABLE `scores` DISABLE KEYS */;
/*!40000 ALTER TABLE `scores` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `service`
--

DROP TABLE IF EXISTS `service`;
CREATE TABLE `service` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(255) NOT NULL,
  `creator` varchar(255) default NULL,
  `info` blob,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `service`
--

LOCK TABLES `service` WRITE;
/*!40000 ALTER TABLE `service` DISABLE KEYS */;
INSERT INTO `service` VALUES (1,'false','Lexi Pimenidis',NULL),(2,'random','Lexi Pimenidis',NULL),(3,'test','Lexi Pimenidis',NULL),(4,'true','Lexi Pimenidis',NULL);
/*!40000 ALTER TABLE `service` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `service_status`
--

DROP TABLE IF EXISTS `service_status`;
CREATE TABLE `service_status` (
  `fi_game` int(10) NOT NULL default '0',
  `fi_service` int(10) NOT NULL default '0',
  `fi_team` int(10) NOT NULL default '0',
  `fi_flag` int(10) default NULL,
  `fi_drone` int(10) default NULL COMMENT 'if not NULL, this drone works on this service',
  `ip` varchar(100) default NULL COMMENT 'caches IP of server, where service runs',
  `status` int(11) default NULL COMMENT 'as returned from gameserver script',
  `last_change` datetime default NULL COMMENT 'timestamp of last change in fi_drone, i.e. when check was ready or was started',
	`info` BLOB default NULL COMMENT 'stores the last PUBLIC comment about this, ie stuff that may be made visible to the players',
	`debug` BLOB default NULL COMMENT 'stores the last CONFIDENTIAL comment about this, may not be made visible to players',
  PRIMARY KEY  (`fi_game`,`fi_service`,`fi_team`),
  KEY `fi_game_fi_team` (`fi_game`,`fi_team`),
  KEY `fi_team` (`fi_team`),
  KEY `fi_service` (`fi_service`),
  KEY `fi_flag` (`fi_flag`),
  KEY `fi_drone` (`fi_drone`),
  CONSTRAINT `service_status_ibfk_1` FOREIGN KEY (`fi_game`) REFERENCES `game` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `service_status_ibfk_2` FOREIGN KEY (`fi_team`) REFERENCES `team` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `service_status_ibfk_3` FOREIGN KEY (`fi_service`) REFERENCES `service` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `service_status_ibfk_4` FOREIGN KEY (`fi_flag`) REFERENCES `flag` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `service_status_ibfk_5` FOREIGN KEY (`fi_drone`) REFERENCES `drone` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `service_status`
--

LOCK TABLES `service_status` WRITE;
/*!40000 ALTER TABLE `service_status` DISABLE KEYS */;
/*!40000 ALTER TABLE `service_status` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `team`
--

DROP TABLE IF EXISTS `team`;
CREATE TABLE `team` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(255) NOT NULL,
  `location` varchar(255) default NULL,
  `contact` varchar(255) default NULL,
  `email` varchar(255) default NULL,
  `webpage` varchar(255) default NULL,
  `members` blob,
  `info` blob,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `team`
--

LOCK TABLES `team` WRITE;
/*!40000 ALTER TABLE `team` DISABLE KEYS */;
INSERT INTO `team` VALUES (1,'team 1',NULL,NULL,NULL,NULL,NULL,NULL),(2,'team 2',NULL,NULL,NULL,NULL,NULL,NULL);
/*!40000 ALTER TABLE `team` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2008-06-17 11:01:14
