<?php
declare(strict_types=1);

// Optional: Parse physical .env from parent folder if not injected by Docker
$envFile = __DIR__ . '/../.env';
if (file_exists($envFile)) {
    $lines = file($envFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    foreach ($lines as $line) {
        if (str_starts_with(trim($line), '#')) continue;
        [$name, $value] = explode('=', $line, 2) + [1 => ''];
        $name = trim($name);
        $value = trim($value, "\"' ");
        if (!array_key_exists($name, $_SERVER) && !array_key_exists($name, $_ENV)) {
            putenv("{$name}={$value}");
            $_ENV[$name] = $value;
        }
    }
}

// Fetch from environment with safe Docker defaults
$dbHost = getenv('DB_HOST')     ?: 'mariadb118';
$dbName = getenv('DB_NAME')     ?: '';
$dbUser = getenv('DB_USER')     ?: '';
$dbPass = getenv('DB_PASSWORD') ?: '';

return [
    'dsn' => "mysql:host={$dbHost};dbname={$dbName};charset=utf8mb4",
    'username' => $dbUser,
    'password' => $dbPass,
    'max_request_bytes' => 131072,
    'max_education_rows' => 20,
];
