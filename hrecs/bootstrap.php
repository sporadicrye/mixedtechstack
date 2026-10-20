<?php
declare(strict_types=1);

$config = require __DIR__ . '/config.php';

ini_set('display_errors', '0');
ini_set('log_errors', '1');

if (($_SERVER['REQUEST_METHOD'] ?? 'GET') === 'POST') {
    $length = (int) ($_SERVER['CONTENT_LENGTH'] ?? 0);

    if ($length > $config['max_request_bytes']) {
        http_response_code(413);
        exit('Request too large.');
    }
}

session_set_cookie_params([
    'httponly' => true,
    'secure' => !empty($_SERVER['HTTPS'])
        && $_SERVER['HTTPS'] !== 'off',
    'samesite' => 'Strict',
]);

session_start();

$pdo = new PDO(
    $config['dsn'],
    $config['username'],
    $config['password'],
    [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES => false,
    ]
);

function e(?string $value): string
{
    return htmlspecialchars(
        $value ?? '',
        ENT_QUOTES | ENT_SUBSTITUTE,
        'UTF-8'
    );
}

function csrf_token(): string
{
    if (!isset($_SESSION['csrf'])) {
        $_SESSION['csrf'] = bin2hex(random_bytes(32));
    }

    return $_SESSION['csrf'];
}

function verify_csrf(): void
{
    $sent = $_POST['csrf'] ?? '';
    $saved = $_SESSION['csrf'] ?? '';

    if (
        !is_string($sent) ||
        !is_string($saved) ||
        $saved === '' ||
        !hash_equals($saved, $sent)
    ) {
        http_response_code(403);
        exit('Invalid CSRF token.');
    }
}

function post_text(
    string $key,
    int $max,
    bool $required = false,
    bool $allow_html = false
): ?string {
    $value = $_POST[$key] ?? '';

    // (DoS prevention)
    if (!is_string($value) || strlen($value) > $max * 4) {
        throw new InvalidArgumentException("Invalid or oversized field: $key");
    }

    if (!mb_check_encoding($value, 'UTF-8')) {
        throw new InvalidArgumentException("Invalid text encoding: $key");
    }

    // Strip hidden null bytes and non-printable control characters
    $value = preg_replace('/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/u', '', $value);

    $value = trim($value);

    if ($value === '') {
        if ($required) {
            throw new InvalidArgumentException("$key is required.");
        }

        return null;
    }

    // Strip HTML tags (e.g. <img src=PORNimage>) unless explicitly allowed
    if (!$allow_html) {
        $value = strip_tags($value);
    }

    // Enforce strict character length limit (blocks non-terminating character floods)
    if (mb_strlen($value, 'UTF-8') > $max) {
        throw new InvalidArgumentException("$key exceeds $max characters.");
    }

    return $value;
}

function post_choice(string $key): ?string
{
    $value = post_text($key, 1);

    if ($value !== null && !in_array($value, ['Y', 'N'], true)) {
        throw new InvalidArgumentException("Invalid choice: $key");
    }

    return $value;
}

function redirect_with_error(string $message, string $fallback = 'index.php'): never
{
    // Optional: Store error in session to display a flash message on the UI
    $_SESSION['flash_error'] = $message;

    $referer = $_SERVER['HTTP_REFERER'] ?? $fallback;
    
    // Prevent open redirect vulnerabilities by ensuring it's a relative or safe internal link
    if (!str_starts_with($referer, '/') && !str_contains($referer, $_SERVER['HTTP_HOST'] ?? '')) {
        $referer = $fallback;
    }

    header('Location: ' . $referer);
    exit;
}

function applicant_id(mixed $value): int
{
    if (!is_string($value) && !is_int($value)) {
        redirect_with_error('Invalid ID format.');
    }

    $id = filter_var($value, FILTER_VALIDATE_INT);

    if ($id === false || $id < 1) {
        redirect_with_error('Invalid or missing ID.');
    }

    return $id;
}

function not_found(): never
{
    redirect_with_error('Record not found.', 'index.php');
}
