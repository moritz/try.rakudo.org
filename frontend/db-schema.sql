-- phpMyAdmin SQL Dump
-- version 3.2.4
-- http://www.phpmyadmin.net
--
-- Host: localhost
-- Generation Time: Jun 25, 2010 at 07:34 PM
-- Server version: 5.1.41
-- PHP Version: 5.3.1



/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;

--
-- Database: `try_rakudo`
--

-- --------------------------------------------------------

--
-- Table structure for table `messages`
--

CREATE TABLE IF NOT EXISTS "messages" (
  "session_id" bigint(20) unsigned NOT NULL,
  "sequence_number" int(10) unsigned NOT NULL,
  "type" char(1) NOT NULL,
  "timestamp" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "contents" text NOT NULL,
  PRIMARY KEY ("session_id","sequence_number")
);

-- --------------------------------------------------------

--
-- Table structure for table `ports`
--

CREATE TABLE IF NOT EXISTS "ports" (
  "number" smallint(5) unsigned NOT NULL,
  "state" tinyint(1) NOT NULL,
  UNIQUE KEY "number" ("number")
);

-- --------------------------------------------------------

--
-- Table structure for table `sessions`
--

CREATE TABLE IF NOT EXISTS "sessions" (
  "id" bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  "status" char(1) NOT NULL DEFAULT 'u',
  "creation_time" datetime NOT NULL,
  "last_access" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY "id" ("id")
) AUTO_INCREMENT=1 ;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
