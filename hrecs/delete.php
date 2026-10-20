<?php
require __DIR__ . '/bootstrap.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    header('Allow: POST');
    http_response_code(405);
    exit('Method not allowed.');
}

verify_csrf();

$id = applicant_id($_POST['id'] ?? null);

$stmt = $pdo->prepare('DELETE FROM applicants WHERE id = ?');
$stmt->execute([$id]);

if ($stmt->rowCount() !== 1) {
    not_found();
}

// Related education rows are deleted by the foreign key.
header('Location: index.php', true, 303);
exit;
