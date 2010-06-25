-- phpMyAdmin SQL Dump
-- version 3.2.4
-- http://www.phpmyadmin.net
--
-- Host: localhost
-- Erstellungszeit: 25. Juni 2010 um 00:50
-- Server Version: 5.1.41
-- PHP-Version: 5.3.1

SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;

--
-- Datenbank: `try_rakudo`
--

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `messages`
--

CREATE TABLE IF NOT EXISTS `messages` (
  `session_id` bigint(20) unsigned NOT NULL,
  `sequence_number` int(10) unsigned NOT NULL,
  `type` char(1) NOT NULL,
  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `contents` text NOT NULL,
  PRIMARY KEY (`session_id`,`sequence_number`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `ports`
--

CREATE TABLE IF NOT EXISTS `ports` (
  `number` smallint(5) unsigned NOT NULL,
  `state` tinyint(1) NOT NULL,
  UNIQUE KEY `number` (`number`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `sessions`
--

CREATE TABLE IF NOT EXISTS `sessions` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `status` char(1) NOT NULL DEFAULT 'u',
  `creation_time` datetime NOT NULL,
  `last_access` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `id` (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
