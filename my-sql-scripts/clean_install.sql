CREATE TABLE `ck_challenges` (
  `id` int(12) NOT NULL AUTO_INCREMENT,
  `mapname` varchar(32) DEFAULT NULL,
  `StartDate` timestamp(6) NULL DEFAULT NULL,
  `EndDate` timestamp(6) NULL DEFAULT NULL,
  `style` int(12) NOT NULL DEFAULT '0',
  `points` int(12) NOT NULL DEFAULT '0',
  `active` int(12) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
) DEFAULT CHARSET=utf8mb4

CREATE TABLE `ck_challenge_times` (
  `id` int(12) NOT NULL,
  `steamid` varchar(32) NOT NULL,
  `name` varchar(32) DEFAULT NULL,
  `mapname` varchar(32) NOT NULL,
  `runtime` decimal(12,6) NOT NULL DEFAULT '0.000000',
  `style` int(12) NOT NULL DEFAULT '0',
  `Run_Date` TIMESTAMP(6) NOT NULL DEFAULT (UTC_TIMESTAMP(6)), 
  PRIMARY KEY (`id`,`steamid`,`mapname`,`runtime`)
) DEFAULT CHARSET=utf8mb4

CREATE TABLE `ck_challenge_players` (
  `steamid` varchar(32) NOT NULL,
  `name` varchar(32) DEFAULT NULL,
  `style` int(12) NOT NULL DEFAULT '0',
  `points` int(12) NOT NULL DEFAULT '0',
  PRIMARY KEY (`steamid`,`style`)
) DEFAULT CHARSET=utf8mb4

CREATE TABLE `ck_challenges_finished` (
  `id` int(12) NOT NULL,
  `winner` varchar(32) DEFAULT NULL,
  `nr_participants` int(12) NOT NULL DEFAULT '0',
  `mapname` varchar(32) DEFAULT NULL,
  `style` int(12) NOT NULL DEFAULT '0',
  `points` int(12) NOT NULL DEFAULT '0',
  `StartDate` timestamp(6) NULL DEFAULT NULL,
  `EndDate` timestamp(6) NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) DEFAULT CHARSET=utf8mb4