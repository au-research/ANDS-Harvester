CREATE TABLE `dbs_harvester`.`harvest` (
  `harvest_id` varchar(256) NOT NULL,
  `provider_id` int(11) DEFAULT NULL,
  `response_url` varchar(256) DEFAULT NULL,
  `method` varchar(32) DEFAULT NULL,
  `mode` varchar(32) DEFAULT NULL,
  `date_started` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `date_completed` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `date_from` varchar(20) DEFAULT NULL,
  `date_until` varchar(20) DEFAULT NULL,
  `set` varchar(128) DEFAULT NULL,
  `resumption_token` varchar(1024) DEFAULT NULL,
  `metadata_prefix` varchar(32) DEFAULT NULL,
  `status` int(11) DEFAULT NULL,
  `advanced_harvesting_mode` varchar(45) DEFAULT NULL,
  PRIMARY KEY (`harvest_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `dbs_harvester`.`schedule` (
  `harvest_id` varchar(256) NOT NULL,
  `last_run` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `next_run` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `frequency` varchar(16) DEFAULT NULL,
  PRIMARY KEY (`harvest_id`),
  KEY `fk_schedule_1_idx` (`harvest_id`),
  CONSTRAINT `fk_schedule_1` FOREIGN KEY (`harvest_id`) REFERENCES `harvest` (`harvest_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `dbs_harvester`.`fragment` (
  `fragment_id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `harvest_id` varchar(256) DEFAULT NULL,
  `request_id` int(11) DEFAULT NULL,
  `date_stored` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `text` longblob,
  PRIMARY KEY (`fragment_id`),
  UNIQUE KEY `fragment_id` (`fragment_id`),
  KEY `fk_fragment_1_idx` (`harvest_id`),
  CONSTRAINT `fk_fragment_1` FOREIGN KEY (`harvest_id`) REFERENCES `harvest` (`harvest_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=78298 DEFAULT CHARSET=latin1;


CREATE TABLE `dbs_harvester`.`harvest_parameter` (
  `harvest_id` varchar(256) NOT NULL DEFAULT '',
  `name` varchar(64) DEFAULT NULL,
  `value` varchar(256) NOT NULL DEFAULT '',
  PRIMARY KEY (`value`,`harvest_id`),
  KEY `fk_harvest_parameter_1_idx` (`harvest_id`),
  CONSTRAINT `fk_harvest_parameter_1` FOREIGN KEY (`harvest_id`) REFERENCES `harvest` (`harvest_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `dbs_harvester`.`provider` (
  `provider_id` int(11) NOT NULL AUTO_INCREMENT,
  `source_url` varchar(256) DEFAULT NULL,
  PRIMARY KEY (`provider_id`)
) ENGINE=InnoDB AUTO_INCREMENT=2013 DEFAULT CHARSET=latin1;

CREATE TABLE `dbs_harvester`.`request` (
  `request_id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `request` varchar(24) DEFAULT NULL,
  PRIMARY KEY (`request_id`),
  UNIQUE KEY `request_id` (`request_id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=latin1;