CREATE DATABASE IF NOT EXISTS `symfony_bdd`;
CREATE USER IF NOT EXISTS 'symfony'@'%' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON `symfony_bdd`.* TO 'symfony'@'%';