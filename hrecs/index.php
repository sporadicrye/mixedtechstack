<?php
require __DIR__ . '/bootstrap.php';

$stmt = $pdo->query(
    'SELECT id, position, first_name, last_name, email
     FROM applicants
     ORDER BY id DESC
     LIMIT 200'
);

$rows = $stmt->fetchAll();
?>
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Applicants</title>
<link rel="stylesheet" href="style.css">
</head>
<body>
<main class="container">
    <header class="topbar">
        <h1>Applicants</h1>
        <a class="button" href="form.php">+ Add applicant</a>
    </header>

    <?php if (isset($_GET['saved'])): ?>
        <p class="success">Record saved.</p>
    <?php endif; ?>

    <?php if (!$rows): ?>
        <section class="card">No applicants found.</section>
    <?php endif; ?>

    <?php foreach ($rows as $row): ?>
        <article class="card">
            <div>
                <h2><?= e($row['last_name'] . ', ' . $row['first_name']) ?></h2>
                <p><?= e($row['position']) ?></p>
                <p><?= e($row['email']) ?></p>
                <small>Record #<?= (int) $row['id'] ?></small>
            </div>

            <nav class="actions">
                <a href="view.php?id=<?= (int) $row['id'] ?>">View</a>
                <a href="form.php?id=<?= (int) $row['id'] ?>">Update</a>

                <form method="post" action="delete.php"
                      onsubmit="return confirm('Delete this applicant and all education records?')">
                    <input type="hidden" name="csrf"
                           value="<?= e(csrf_token()) ?>">
                    <input type="hidden" name="id"
                           value="<?= (int) $row['id'] ?>">
                    <button class="danger" type="submit">Delete</button>
                </form>
            </nav>
        </article>
    <?php endforeach; ?>
</main>
</body>
</html>
