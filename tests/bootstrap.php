<?php

declare(strict_types=1);

// Bootstrap file for test environment setup.
// Loads environment variables and configures debug mode.

use Symfony\Component\Dotenv\Dotenv;

require dirname(__DIR__).'/vendor/autoload.php';

// Load environment variables from .env file
if (method_exists(Dotenv::class, 'bootEnv')) {
    (new Dotenv())->bootEnv(dirname(__DIR__).'/.env');
}

// Set file permissions and error reporting based on APP_DEBUG value
if ($_SERVER['APP_DEBUG']) {
    umask(0000);
}
