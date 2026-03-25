#!/usr/bin/env bash
set -euo pipefail

# === CONFIG ===
SITE_NAME="rebelwithlinux.com"
WEB_ROOT="/var/www/${SITE_NAME}"
DB_NAME="learning_platform"
DB_USER="webuser"
DB_PASS="webpass"
# === END CONFIG ===

echo "Installing PHP + MySQL extension for Apache..."
sudo apt update
sudo apt install -y php libapache2-mod-php php-mysql

echo "Restarting Apache..."
sudo systemctl restart apache2

echo "Creating database, user, and tables..."
sudo mysql <<SQL
CREATE DATABASE IF NOT EXISTS ${DB_NAME};
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;

USE ${DB_NAME};

CREATE TABLE IF NOT EXISTS users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS login_events (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  logged_in_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS progress (
  user_id INT NOT NULL,
  course VARCHAR(64) NOT NULL,
  lesson_id INT NOT NULL,
  completed TINYINT(1) DEFAULT 0,
  quiz_score INT DEFAULT 0,
  completed_at TIMESTAMP NULL,
  PRIMARY KEY (user_id, course, lesson_id),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
SQL

echo "Done. Quick check:"
echo "  curl -i http://localhost/api/auth.php?action=check"
