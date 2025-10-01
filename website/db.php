<?php
/**
 * PostgreSQL Database Driver for WordPress
 * This file replaces the default MySQL database functions with PostgreSQL equivalents
 */

if (!defined('ABSPATH')) {
    exit;
}

// Override database connection
if (!function_exists('wp_db_connect')) {
    function wp_db_connect() {
        global $wpdb;

        $host = DB_HOST;
        $dbname = DB_NAME;
        $user = DB_USER;
        $password = DB_PASSWORD;

        try {
            $dsn = "pgsql:host=$host;dbname=$dbname";
            $pdo = new PDO($dsn, $user, $password, array(
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC
            ));

            return $pdo;
        } catch (PDOException $e) {
            wp_die('Database connection error: ' . $e->getMessage());
        }
    }
}

// Basic PostgreSQL query adapter
class WP_PostgreSQL_DB {
    private $pdo;

    public function __construct() {
        $this->pdo = wp_db_connect();
    }

    public function query($sql) {
        try {
            return $this->pdo->query($sql);
        } catch (PDOException $e) {
            return false;
        }
    }

    public function get_results($sql) {
        try {
            $stmt = $this->pdo->query($sql);
            return $stmt->fetchAll(PDO::FETCH_OBJ);
        } catch (PDOException $e) {
            return array();
        }
    }
}

// Initialize if WordPress is loaded
if (class_exists('wpdb')) {
    global $wpdb;
    $wpdb = new WP_PostgreSQL_DB();
}
?>