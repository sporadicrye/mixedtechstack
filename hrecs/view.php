<?php
require __DIR__ . '/bootstrap.php';

$id = applicant_id($_GET['id'] ?? null);

$stmt = $pdo->prepare('SELECT * FROM applicants WHERE id = ?');
$stmt->execute([$id]);
$a = $stmt->fetch();

if (!$a) {
    not_found();
}

$stmt = $pdo->prepare(
    'SELECT school_name, location, years_attended,
            degree_required, major
     FROM education
     WHERE applicant_id = ?
     ORDER BY id'
);
$stmt->execute([$id]);
$education = $stmt->fetchAll();

function detail(string $label, mixed $value): void
{
    echo '<div class="detail"><strong>' . e($label) . '</strong><div>' .
        nl2br(e($value === null ? '' : (string) $value)) .
        '</div></div>';
}
?>
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Applicant details</title>
<link rel="stylesheet" href="style.css">
</head>
<body>
<main class="container">
    <header class="topbar">
        <h1>Applicant #<?= (int) $a['id'] ?></h1>
        <nav class="actions">
            <a href="index.php">Back</a>
            <a class="button" href="form.php?id=<?= (int) $a['id'] ?>">Update</a>
        </nav>
    </header>

    <?php if (isset($_GET['saved'])): ?>
        <p class="success">Record saved successfully.</p>
    <?php endif; ?>

    <section class="card">
        <h2>Application and personal information</h2>
        <div class="detail-grid">
            <?php
            detail('Position', $a['position']);
            detail('Desired salary', $a['salary']);
            detail('Available date', $a['available_date']);
            detail('Last name', $a['last_name']);
            detail('First name', $a['first_name']);
            detail('Middle name', $a['middle_name']);
            detail('Address', $a['address']);
            detail('City', $a['city']);
            detail('State / region', $a['state_region']);
            detail('ZIP / postal code', $a['zip_code']);
            detail('Home phone', $a['home_phone']);
            detail('Cell phone', $a['cellphone']);
            detail('Email', $a['email']);
            detail('US citizen', $a['is_citizen']);
            detail('Felony conviction', $a['is_felony']);
            detail('Screening consent', $a['is_employment']);
            ?>
        </div>
    </section>

    <section class="card">
        <h2>Education history</h2>

        <?php if (!$education): ?>
            <p>No education records.</p>
        <?php endif; ?>

        <?php foreach ($education as $i => $row): ?>
            <article class="education-row">
                <h3>Education <?= $i + 1 ?></h3>
                <div class="detail-grid">
                    <?php
                    detail('School name', $row['school_name']);
                    detail('Location', $row['location']);
                    detail('Years attended', $row['years_attended']);
                    detail('Degree', $row['degree_required']);
                    detail('Major', $row['major']);
                    ?>
                </div>
            </article>
        <?php endforeach; ?>
    </section>
</main>
</body>
</html>
