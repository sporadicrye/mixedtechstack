<?php
require __DIR__ . '/bootstrap.php';

$id = null;

if (isset($_GET['id'])) {
    $id = applicant_id($_GET['id']);
}

$data = [
    'position' => '', 'salary' => '', 'available_date' => '',
    'last_name' => '', 'first_name' => '', 'middle_name' => '',
    'address' => '', 'city' => '', 'state_region' => '', 'zip_code' => '',
    'home_phone' => '', 'cellphone' => '', 'email' => '',
    'is_citizen' => '', 'is_felony' => '', 'is_employment' => '',
];

$education = [];
$error = '';

if ($id !== null) {
    $stmt = $pdo->prepare('SELECT * FROM applicants WHERE id = ?');
    $stmt->execute([$id]);
    $record = $stmt->fetch();

    if (!$record) {
        not_found();
    }

    $data = $record;

    $stmt = $pdo->prepare(
        'SELECT school_name, location, years_attended,
                degree_required, major
         FROM education
         WHERE applicant_id = ?
         ORDER BY id'
    );
    $stmt->execute([$id]);
    $education = $stmt->fetchAll();
}

if (!$education) {
    $education = [[
        'school_name' => '',
        'location' => '',
        'years_attended' => '',
        'degree_required' => '',
        'major' => '',
    ]];
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    verify_csrf();

    // Use the submitted ID for updates, never a hidden owner or user ID.
    $postedId = $_POST['id'] ?? '';

    if ($id !== null) {
        $updateId = applicant_id($postedId);

        if ($updateId !== $id) {
            http_response_code(400);
            exit('Invalid record ID.');
        }
    } elseif ($postedId !== '') {
        http_response_code(400);
        exit('Unexpected record ID.');
    }

    try {
        $data = [
            'position' => post_text('position', 150, true),
            'last_name' => post_text('last_name', 100, true),
            'first_name' => post_text('first_name', 100, true),
            'middle_name' => post_text('middle_name', 100),
            'address' => post_text('address', 250),
            'city' => post_text('city', 100),
            'state_region' => post_text('state_region', 100),
            'zip_code' => post_text('zip_code', 20),
            'home_phone' => post_text('home_phone', 30),
            'cellphone' => post_text('cellphone', 30),
            'email' => post_text('email', 254),
            'is_citizen' => post_choice('is_citizen'),
            'is_felony' => post_choice('is_felony'),
            'is_employment' => post_choice('is_employment'),
        ];

        $data['salary'] = post_text('salary', 13);
        if ($data['salary'] !== null) {
            if (
                !preg_match('/\A\d{1,10}(?:\.\d{1,2})?\z/', $data['salary']) ||
                (float) $data['salary'] > 9999999999.99
            ) {
                throw new InvalidArgumentException('Invalid salary.');
            }
        }

        if ($data['email'] !== null &&
            !filter_var($data['email'], FILTER_VALIDATE_EMAIL)) {
            throw new InvalidArgumentException('Invalid email address.');
        }

        $data['available_date'] = post_text('available_date', 10);
        if ($data['available_date'] !== null) {
            $date = DateTimeImmutable::createFromFormat(
                '!Y-m-d',
                $data['available_date']
            );
            $dateErrors = DateTimeImmutable::getLastErrors();

            if (
                !$date ||
                ($dateErrors !== false &&
                    ($dateErrors['warning_count'] || $dateErrors['error_count'])) ||
                $date->format('Y-m-d') !== $data['available_date']
            ) {
                throw new InvalidArgumentException('Invalid available date.');
            }
        }

        $educationInput = $_POST['education'] ?? [];

        if (
            !is_array($educationInput) ||
            count($educationInput) > $config['max_education_rows']
        ) {
            throw new InvalidArgumentException('Too many education rows.');
        }

        $education = [];

        foreach ($educationInput as $row) {
            if (!is_array($row)) {
                throw new InvalidArgumentException('Invalid education row.');
            }

            $oldPost = $_POST;
            $_POST = $row;

            try {
                $entry = [
                    'school_name' => post_text('school_name', 200),
                    'location' => post_text('location', 200),
                    'years_attended' => post_text('years_attended', 30),
                    'degree_required' => post_text('degree_required', 150),
                    'major' => post_text('major', 150),
                ];
            } finally {
                $_POST = $oldPost;
            }

            if (!array_filter($entry, fn($v) => $v !== null && $v !== '')) {
                continue;
            }

            if ($entry['school_name'] === null) {
                throw new InvalidArgumentException(
                    'School name is required for each education row.'
                );
            }

            $education[] = $entry;
        }

        $pdo->beginTransaction();

        if ($id === null) {
            $stmt = $pdo->prepare(
                'INSERT INTO applicants (
                    position, salary, available_date,
                    last_name, first_name, middle_name,
                    address, city, state_region, zip_code,
                    home_phone, cellphone, email,
                    is_citizen, is_felony, is_employment
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
            );

            $stmt->execute([
                $data['position'], $data['salary'], $data['available_date'],
                $data['last_name'], $data['first_name'], $data['middle_name'],
                $data['address'], $data['city'], $data['state_region'],
                $data['zip_code'], $data['home_phone'], $data['cellphone'],
                $data['email'], $data['is_citizen'], $data['is_felony'],
                $data['is_employment'],
            ]);

            $id = (int) $pdo->lastInsertId();
        } else {
            $stmt = $pdo->prepare(
                'UPDATE applicants SET
                    position=?, salary=?, available_date=?,
                    last_name=?, first_name=?, middle_name=?,
                    address=?, city=?, state_region=?, zip_code=?,
                    home_phone=?, cellphone=?, email=?,
                    is_citizen=?, is_felony=?, is_employment=?
                 WHERE id=?'
            );

            $stmt->execute([
                $data['position'], $data['salary'], $data['available_date'],
                $data['last_name'], $data['first_name'], $data['middle_name'],
                $data['address'], $data['city'], $data['state_region'],
                $data['zip_code'], $data['home_phone'], $data['cellphone'],
                $data['email'], $data['is_citizen'], $data['is_felony'],
                $data['is_employment'], $id,
            ]);

            $stmt = $pdo->prepare(
                'DELETE FROM education WHERE applicant_id = ?'
            );
            $stmt->execute([$id]);
        }

        $stmt = $pdo->prepare(
            'INSERT INTO education (
                applicant_id, school_name, location, years_attended,
                degree_required, major
            ) VALUES (?, ?, ?, ?, ?, ?)'
        );

        foreach ($education as $row) {
            $stmt->execute([
                $id, $row['school_name'], $row['location'],
                $row['years_attended'], $row['degree_required'],
                $row['major'],
            ]);
        }

        $pdo->commit();

        header('Location: view.php?id=' . $id . '&saved=1', true, 303);
        exit;
    } catch (InvalidArgumentException $ex) {
        if ($pdo->inTransaction()) {
            $pdo->rollBack();
        }
        $error = $ex->getMessage();
    } catch (Throwable $ex) {
        if ($pdo->inTransaction()) {
            $pdo->rollBack();
        }

        error_log('Applicant CRUD save error: ' . $ex->getMessage());
        http_response_code(500);
        $error = 'Unable to save the record. Please check your entries.';
    }
}

function field(array $data, string $key): string
{
    return e(isset($data[$key]) ? (string) $data[$key] : '');
}

function yes_no_options(mixed $current): string
{
    $html = '<option value="">Choose...</option>';

    foreach (['Y' => 'Yes', 'N' => 'No'] as $value => $label) {
        $selected = $current === $value ? ' selected' : '';
        $html .= '<option value="' . $value . '"' . $selected . '>' .
            $label . '</option>';
    }

    return $html;
}
?>
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title><?= $id ? 'Update applicant' : 'Create applicant' ?></title>
<link rel="stylesheet" href="style.css">
<script src="app.js" defer></script>
</head>
<body>
<main class="container">
    <header class="topbar">
        <h1><?= $id ? 'Update applicant' : 'Create applicant' ?></h1>
        <a href="index.php">Back to list</a>
    </header>

    <?php if ($error !== ''): ?>
        <p class="error"><?= e($error) ?></p>
    <?php endif; ?>

    <form method="post">
        <input type="hidden" name="csrf" value="<?= e(csrf_token()) ?>">
        <?php if ($id !== null): ?>
            <input type="hidden" name="id" value="<?= (int) $id ?>">
        <?php endif; ?>

        <fieldset>
            <legend>Application</legend>
            <div class="grid">
                <label>Position *
                    <input name="position" maxlength="150" required
                           value="<?= field($data, 'position') ?>">
                </label>
                <label>Desired salary
                    <input name="salary" inputmode="decimal" maxlength="13"
                           pattern="[0-9]{1,10}([.][0-9]{1,2})?"
                           value="<?= field($data, 'salary') ?>">
                </label>
                <label>Available date
                    <input type="date" name="available_date"
                           value="<?= field($data, 'available_date') ?>">
                </label>
            </div>
        </fieldset>

        <fieldset>
            <legend>Personal information</legend>
            <div class="grid">
                <label>Last name *
                    <input name="last_name" maxlength="100" required
                           value="<?= field($data, 'last_name') ?>">
                </label>
                <label>First name *
                    <input name="first_name" maxlength="100" required
                           value="<?= field($data, 'first_name') ?>">
                </label>
                <label>Middle name
                    <input name="middle_name" maxlength="100"
                           value="<?= field($data, 'middle_name') ?>">
                </label>
                <label>Address
                    <input name="address" maxlength="250"
                           value="<?= field($data, 'address') ?>">
                </label>
                <label>City
                    <input name="city" maxlength="100"
                           value="<?= field($data, 'city') ?>">
                </label>
                <label>State / region
                    <input name="state_region" maxlength="100"
                           value="<?= field($data, 'state_region') ?>">
                </label>
                <label>ZIP / postal code
                    <input name="zip_code" maxlength="20"
                           value="<?= field($data, 'zip_code') ?>">
                </label>
                <label>Home phone
                    <input type="tel" name="home_phone" maxlength="30"
                           value="<?= field($data, 'home_phone') ?>">
                </label>
                <label>Cell phone
                    <input type="tel" name="cellphone" maxlength="30"
                           value="<?= field($data, 'cellphone') ?>">
                </label>
                <label>Email
                    <input type="email" name="email" maxlength="254"
                           value="<?= field($data, 'email') ?>">
                </label>
            </div>
        </fieldset>

        <fieldset>
            <legend>Additional information</legend>
            <div class="grid">
                <label>US citizen?
                    <select name="is_citizen"><?= yes_no_options($data['is_citizen']) ?></select>
                </label>
                <label>Convicted of felony?
                    <select name="is_felony"><?= yes_no_options($data['is_felony']) ?></select>
                </label>
                <label>Willing to undergo screening?
                    <select name="is_employment"><?= yes_no_options($data['is_employment']) ?></select>
                </label>
            </div>
        </fieldset>

        <fieldset>
            <legend>Education</legend>
            <p>Up to 20 entries. School name is required when a row contains data.</p>

            <div id="education-rows">
            <?php foreach ($education as $i => $row): ?>
                <div class="education-row">
                    <h3>Education <span class="row-number"><?= $i + 1 ?></span></h3>
                    <div class="grid">
                        <label>School name
                            <input name="education[<?= $i ?>][school_name]"
                                   data-field="school_name" maxlength="200"
                                   value="<?= e($row['school_name'] ?? '') ?>">
                        </label>
                        <label>Location
                            <input name="education[<?= $i ?>][location]"
                                   data-field="location" maxlength="200"
                                   value="<?= e($row['location'] ?? '') ?>">
                        </label>
                        <label>Years attended
                            <input name="education[<?= $i ?>][years_attended]"
                                   data-field="years_attended" maxlength="30"
                                   value="<?= e($row['years_attended'] ?? '') ?>">
                        </label>
                        <label>Degree
                            <input name="education[<?= $i ?>][degree_required]"
                                   data-field="degree_required" maxlength="150"
                                   value="<?= e($row['degree_required'] ?? '') ?>">
                        </label>
                        <label>Major
                            <input name="education[<?= $i ?>][major]"
                                   data-field="major" maxlength="150"
                                   value="<?= e($row['major'] ?? '') ?>">
                        </label>
                    </div>
                    <button type="button" class="secondary remove-education">
                        Remove row
                    </button>
                </div>
            <?php endforeach; ?>
            </div>

            <button type="button" id="add-education">+ Add education row</button>
        </fieldset>

        <div class="actions">
            <button type="submit"><?= $id ? 'Save changes' : 'Create applicant' ?></button>
            <a class="button secondary" href="index.php">Cancel</a>
        </div>
    </form>
</main>
</body>
</html>
