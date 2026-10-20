-- Run: mysql -u root -p mypoc_proofofconceptv1 < schema.sql

CREATE DATABASE IF NOT EXISTS mypoc_proofofconceptv1
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE mypoc_proofofconceptv1;

-- ─────────────────────────────────────────────
-- LOOKUP TABLES (maintained by CSV watcher)
-- ─────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS categories (
    category_id   INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL,
    description   TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS suppliers (
    supplier_id   INT AUTO_INCREMENT PRIMARY KEY,
    company_name  VARCHAR(100) NOT NULL,
    contact_name  VARCHAR(100),
    country       VARCHAR(50)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS shippers (
    shipper_id    INT AUTO_INCREMENT PRIMARY KEY,
    company_name  VARCHAR(100) NOT NULL,
    phone         VARCHAR(30)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS employees (
    employee_id   INT AUTO_INCREMENT PRIMARY KEY,
    last_name     VARCHAR(50)  NOT NULL,
    first_name    VARCHAR(50)  NOT NULL,
    title         VARCHAR(100),
    hire_date     DATE,
    country       VARCHAR(50)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS customers (
    customer_id   VARCHAR(10)  PRIMARY KEY,
    company_name  VARCHAR(100) NOT NULL,
    contact_name  VARCHAR(100),
    country       VARCHAR(50),
    city          VARCHAR(50),
    phone         VARCHAR(30)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS products (
    product_id        INT AUTO_INCREMENT PRIMARY KEY,
    product_name      VARCHAR(150) NOT NULL,
    supplier_id       INT,
    category_id       INT,
    quantity_per_unit VARCHAR(50),
    unit_price        DECIMAL(10,2) DEFAULT 0,
    units_in_stock    INT          DEFAULT 0,
    units_on_order    INT          DEFAULT 0,
    reorder_level     INT          DEFAULT 0,
    discontinued      TINYINT(1)   DEFAULT 0,
    FOREIGN KEY (supplier_id)  REFERENCES suppliers(supplier_id),
    FOREIGN KEY (category_id)  REFERENCES categories(category_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS orders (
    order_id      INT AUTO_INCREMENT PRIMARY KEY,
    customer_id   VARCHAR(10),
    employee_id   INT,
    order_date    DATE,
    required_date DATE,
    shipped_date  DATE,
    ship_via      INT,
    freight       DECIMAL(10,2) DEFAULT 0,
    ship_name     VARCHAR(100),
    ship_country  VARCHAR(50),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id),
    FOREIGN KEY (ship_via)    REFERENCES shippers(shipper_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS order_details (
    order_id   INT,
    product_id INT,
    unit_price DECIMAL(10,2) NOT NULL,
    quantity   INT           NOT NULL,
    discount   FLOAT         DEFAULT 0,
    PRIMARY KEY (order_id, product_id),
    FOREIGN KEY (order_id)   REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────────────
-- AI INSIGHTS TABLE
-- Stores Claude responses with semantic cache
-- question_hash dedupes identical/similar questions
-- avoiding repeat Claude API calls (cost saver)
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS ai_insights (
    id             INT AUTO_INCREMENT PRIMARY KEY,
    question_hash  VARCHAR(64)  NOT NULL,           -- SHA256 of normalized question
    question_text  TEXT         NOT NULL,            -- original question asked
    insight_type   VARCHAR(50)  NOT NULL,            -- e.g. top_customer, recommendation
    insight_text   TEXT         NOT NULL,            -- Claude's response
    sql_context    TEXT,                             -- SQL data sent to Claude (for audit)
    tokens_used    INT          DEFAULT 0,           -- track API cost
    created_at     TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    expires_at     TIMESTAMP    NULL,                -- NULL = never expires
    INDEX idx_question_hash (question_hash),
    INDEX idx_insight_type  (insight_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────────────
-- HREC PHP8.4 SPECIFIC TABLES (to prove PHP8.4 works with modern React/Python tech stack)
-- ─────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS applicants (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    position VARCHAR(150) NOT NULL,
    salary DECIMAL(12,2) NULL,
    available_date DATE NULL,
    last_name VARCHAR(100) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    middle_name VARCHAR(100) NULL,
    address VARCHAR(250) NULL,
    city VARCHAR(100) NULL,
    state_region VARCHAR(100) NULL,
    zip_code VARCHAR(20) NULL,
    home_phone VARCHAR(30) NULL,
    cellphone VARCHAR(30) NULL,
    email VARCHAR(254) NULL,
    is_citizen ENUM('Y','N') NULL,
    is_felony ENUM('Y','N') NULL,
    is_employment ENUM('Y','N') NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS education (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    applicant_id BIGINT UNSIGNED NOT NULL,
    school_name VARCHAR(200) NOT NULL,
    location VARCHAR(200) NULL,
    years_attended VARCHAR(30) NULL,
    degree_required VARCHAR(150) NULL,
    major VARCHAR(150) NULL,
    CONSTRAINT fk_education_applicant
        FOREIGN KEY (applicant_id)
        REFERENCES applicants(id)
        ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ─────────────────────────────────────────────
-- SEED DATA
-- ─────────────────────────────────────────────

INSERT IGNORE INTO categories (category_id, category_name, description) VALUES
(1,  'Beverages',       'Soft drinks, coffees, teas, beers, and ales'),
(2,  'Condiments',      'Sweet and savory sauces, relishes, spreads'),
(3,  'Confections',     'Desserts, candies, and sweet breads'),
(4,  'Dairy Products',  'Cheeses'),
(5,  'Grains/Cereals',  'Breads, crackers, pasta, and cereal'),
(6,  'Meat/Poultry',    'Prepared meats'),
(7,  'Produce',         'Dried fruit and bean curd'),
(8,  'Seafood',         'Seaweed and fish');

INSERT IGNORE INTO suppliers (supplier_id, company_name, contact_name, country) VALUES
(1,  'Exotic Liquids',              'Charlotte Cooper',  'UK'),
(2,  'New Orleans Cajun Delights',  'Shelley Burke',     'USA'),
(3,  'Grandma Kellys Homestead',    'Regina Murphy',     'USA'),
(4,  'Tokyo Traders',               'Yoshi Nagase',      'Japan'),
(5,  'Cooperativa de Quesos',       'Antonio del Valle', 'Spain'),
(6,  'Mayumis',                     'Mayumi Ohna',       'Japan'),
(7,  'Pavlova Ltd',                 'Ian Devling',       'Australia'),
(8,  'Specialty Biscuits Ltd',      'Peter Wilson',      'UK'),
(9,  'PB Knackebrod AB',            'Lars Peterson',     'Sweden'),
(10, 'Refrescos Americanas',        'Carlos Diaz',       'Brazil'),
(11, 'Heli Susswaren GmbH',         'Petra Winkler',     'Germany'),
(12, 'Plutzer Lebensmittel',        'Martin Bein',       'Germany'),
(13, 'Nord-Ost-Fisch Handelsges',   'Sven Petersen',     'Germany'),
(14, 'Formaggi Fortini s.r.l.',     'Elio Rossi',        'Italy'),
(15, 'Norske Meierier',             'Beate Vileid',      'Norway'),
(16, 'Bigfoot Breweries',           'Cheryl Saylor',     'USA'),
(17, 'Svensk Sjofoda AB',           'Michael Bjorn',     'Sweden'),
(18, 'Aux joyeux ecclesiastiques',  'Guylaine Nodier',   'France'),
(19, 'New England Seafood Cannery', 'Robb Merchant',     'USA'),
(20, 'Leka Trading',                'Chandra Leka',      'Singapore'),
(21, 'Lyngbysild',                  'Niels Petersen',    'Denmark'),
(22, 'Zaanse Snoepfabriek',         'Dirk Luchte',       'Netherlands'),
(23, 'Karkki Oy',                   'Anne Heikkonen',    'Finland'),
(24, 'G-Traditions',                'Jean-Pierre Citeaux','France'),
(25, 'Ma Maison',                   'Laurence Lebihan',  'France'),
(26, 'Pasta Buttini s.r.l.',        'Giovanni Giudici',  'Italy'),
(27, 'Escargots Nouveaux',          'Marie Delamare',    'France'),
(28, 'Gai paturage',                'Eliane Noz',        'France'),
(29, 'Forêts d''Erables',           'Chantal Goulet',    'Canada');

INSERT IGNORE INTO shippers (shipper_id, company_name, phone) VALUES
(1, 'Speedy Express',    '(503) 555-9831'),
(2, 'United Package',    '(503) 555-3199'),
(3, 'Federal Shipping',  '(503) 555-9931'),
(4, '2GO',               '1-800-222-0451'),
(5, 'Asendya',           '1-800-782-7892'),
(6, 'AliGroup',          '1-800-225-5345');

INSERT IGNORE INTO employees (employee_id, last_name, first_name, title, hire_date, country) VALUES
(1, 'Davolio',   'Nancy',   'Sales Representative',      '1992-05-01', 'USA'),
(2, 'Fuller',    'Andrew',  'Vice President Sales',      '1992-08-14', 'USA'),
(3, 'Leverling', 'Janet',   'Sales Representative',      '1992-04-01', 'USA'),
(4, 'Peacock',   'Margaret','Sales Representative',      '1993-05-03', 'USA'),
(5, 'Buchanan',  'Steven',  'Sales Manager',             '1993-10-17', 'UK'),
(6, 'Suyama',    'Michael', 'Sales Representative',      '1993-10-17', 'UK'),
(7, 'King',      'Robert',  'Sales Representative',      '1994-01-02', 'UK'),
(8, 'Callahan',  'Laura',   'Inside Sales Coordinator',  '1994-03-05', 'USA'),
(9, 'Dodsworth', 'Anne',    'Sales Representative',      '1994-11-15', 'UK');


INSERT IGNORE INTO customers VALUES
('ALFKI', 'Alfreds Futterkiste',       'Maria Anders',    'Germany',  'Berlin',    '030-0074321'),
('ANATR', 'Ana Trujillo Emparedados',  'Ana Trujillo',    'Mexico',   'Mexico D.F.','(5) 555-4729'),
('ANTON', 'Antonio Moreno Taqueria',   'Antonio Moreno',  'Mexico',   'Mexico D.F.','(5) 555-3932'),
('AROUT', 'Around the Horn',           'Thomas Hardy',    'UK',       'London',    '(171) 555-7788'),
('BERGS', 'Berglunds snabbkop',        'Christina Berglund','Sweden', 'Lulea',     '0921-12 34 65'),
('BLAUS', 'Blauer See Delikatessen',   'Hanna Moos',      'Germany',  'Mannheim',  '0621-08460'),
('BOLID', 'Bolido Comidas preparadas', 'Martin Sommer',   'Spain',    'Madrid',    '(91) 555 22 82'),
('BONAP', 'Bon app',                   'Laurence Lebihan','France',   'Marseille', '91.24.45.40'),
('BOTTM', 'Bottom-Dollar Markets',     'Elizabeth Lincoln','Canada',  'Tsawassen', '(604) 555-4729'),
('BSBEV', 'B-s Beverages',            'Victoria Ashworth','UK',      'London',    '(171) 555-1212'),
('CACTU', 'Cactus Comidas para llevar','Patricio Simpson','Argentina','Buenos Aires','(1) 135-5555'),
('CENTC', 'Centro comercial Moctezuma','Francisco Chang', 'Mexico',   'Mexico D.F.','(5) 555-3392'),
('CHOPS', 'Chop-suey Chinese',         'Yang Wang',       'Switzerland','Bern',    '0452-076545'),
('COMMI', 'Comercio Mineiro',          'Pedro Afonso',    'Brazil',   'Sao Paulo', '(11) 555-7647'),
('CONSH', 'Consolidated Holdings',     'Elizabeth Brown', 'UK',       'London',    '(171) 555-2282'),
('DRACD', 'Drachenblut Delikatessen',  'Sven Ottlieb',    'Germany',  'Aachen',    '0241-039123'),
('DUMON', 'Du monde entier',           'Janine Labrune',  'France',   'Nantes',    '40.67.88.88'),
('EASTC', 'Eastern Connection',        'Ann Devon',       'UK',       'London',    '(171) 555-0297'),
('ERNSH', 'Ernst Handel',              'Roland Mendel',   'Austria',  'Graz',      '7675-3425'),
('FAMIA', 'Familia Arquibaldo',        'Aria Cruz',       'Brazil',   'Sao Paulo', '(11) 555-9857');

INSERT IGNORE INTO products
    (product_id, product_name, supplier_id, category_id, quantity_per_unit, unit_price, units_in_stock, units_on_order, reorder_level, discontinued)
VALUES
(1,  'Chai',                        1,  1, '10 boxes x 20 bags',   18.00,  39,  0,  10, 0),
(2,  'Chang',                       1,  1, '24 - 12 oz bottles',   19.00,  17,  40, 25, 0),
(3,  'Aniseed Syrup',               1,  2, '12 - 550 ml bottles',  10.00,  13,  70, 25, 0),
(4,  'Chef Antons Cajun Seasoning', 2,  2, '48 - 6 oz jars',       22.00,  53,  0,  0,  0),
(5,  'Chef Antons Gumbo Mix',       2,  2, '36 boxes',             21.35,  0,   0,  0,  1),
(6,  'Grandmas Boysenberry Spread', 3,  2, '12 - 8 oz jars',       25.00,  120, 0,  25, 0),
(7,  'Uncle Bobs Organic Dried Pears',  3,  7, '12 - 1 lb pkgs.',       30.00,  15,  0,   10, 0),
(8,  'Northwoods Cranberry Sauce',      3,  2, '12 - 12 oz jars',       40.00,  6,   0,   0,  0),
(9,  'Mishi Kobe Niku',                 4,  6, '18 - 500 g pkgs.',      97.00,  29,  0,   0,  1),
(10, 'Ikura',                           4,  8, '12 - 200 ml jars',      31.00,  31,  0,   0,  0),
(11, 'Queso Cabrales',                  5,  4, '1 kg pkg.',             21.00,  22,  30,  30, 0),
(12, 'Queso Manchego La Pastora',       5,  4, '10 - 500 g pkgs.',      38.00,  86,  0,   0,  0),
(13, 'Konbu',                           6,  8, '2 kg box',               6.00,  24,  0,   5,  0),
(14, 'Tofu',                            6,  7, '40 - 100 g pkgs.',      23.25,  35,  0,   0,  0),
(15, 'Genen Shouyu',                    6,  2, '24 - 250 ml bottles',   15.50,  39,  0,   5,  0),
(16, 'Pavlova',                         7,  3, '32 - 500 g boxes',      17.45,  29,  0,   10, 0),
(17, 'Alice Mutton',                    7,  6, '20 - 1 kg tins',        39.00,  0,   0,   0,  1),
(18, 'Carnarvon Tigers',                7,  8, '16 kg pkg.',            62.50,  42,  0,   0,  0),
(19, 'Teatime Chocolate Biscuits',      8,  3, '10 boxes x 12 pieces',   9.20,  25,  0,   5,  0),
(20, 'Sir Rodneys Marmalade',           8,  3, '30 gift boxes',         81.00,  40,  0,   0,  0),
(21, 'Sir Rodneys Scones',             8,  3, '24 pkgs. x 4 pieces',   10.00,  3,   40,  5,  0),
(22, 'Gustafs Knackebrod',             9,  5, '24 - 500 g pkgs.',      21.00,  104, 0,   25, 0),
(23, 'Tunnbrod',                        9,  5, '12 - 250 g pkgs.',       9.00,  61,  0,   25, 0),
(24, 'Guarana Fantastica',             10,  1, '12 - 355 ml cans',       4.50,  20,  0,   0,  1),
(25, 'NuNuCa Nuss-Nougat-Creme',      11,  3, '20 - 450 g glasses',    14.00,  76,  0,   30, 0),
(26, 'Gumbar Gummibarchen',           11,  3, '100 - 250 g bags',      31.23,  15,  0,   0,  0),
(27, 'Schoggi Schokolade',            11,  3, '100 - 100 g pieces',    43.90,  49,  0,   30, 0),
(28, 'Rossle Sauerkraut',             12,  7, '25 - 825 g cans',       45.60,  26,  0,   0,  1),
(29, 'Thuringer Rostbratwurst',       12,  6, '50 bags x 30 sausgs.',  123.79, 0,   0,   0,  1),
(30, 'Nord-Ost Matjeshering',         13,  8, '10 - 200 g glasses',    25.89,  10,  0,   15, 0),
(31, 'Gorgonzola Telino',             14,  4, '12 - 100 g pkgs',       12.50,  0,   70,  20, 0),
(32, 'Mascarpone Fabioli',            14,  4, '24 - 200 g pkgs.',      32.00,  9,   40,  25, 0),
(33, 'Geitost',                       15,  4, '500 g',                  2.50,  112, 0,   20, 0),
(34, 'Sasquatch Ale',                 16,  1, '24 - 12 oz bottles',    14.00,  111, 0,   15, 0),
(35, 'Steeleye Stout',                16,  1, '24 - 12 oz bottles',    18.00,  20,  0,   15, 0),
(36, 'Inlagd Sill',                   17,  8, '24 - 250 g jars',       19.00,  112, 0,   20, 0),
(37, 'Gravad lax',                    17,  8, '12 - 500 g pkgs.',      26.00,  11,  50,  25, 0),
(38, 'Cote de Blaye',                 18,  1, '12 - 75 cl bottles',   263.50,  17,  0,   15, 0),
(39, 'Chartreuse verte',              18,  1, '750 cc per bottle',      18.00,  69,  0,   5,  0),
(40, 'Boston Crab Meat',              19,  8, '24 - 4 oz tins',        18.40,  123, 0,   30, 0),
(41, 'Jacks New England Clam Chowder',19, 8, '12 - 12 oz cans',        9.65,  85,  0,   10, 0),
(42, 'Singaporean Hokkien Fried Mee', 20,  5, '32 - 1 kg pkgs.',       14.00,  26,  0,   0,  1),
(43, 'Ipoh Coffee',                   20,  1, '16 - 500 g tins',       46.00,  17,  10,  25, 0),
(44, 'Gula Malacca',                  20,  2, '20 - 2 kg bags',        19.45,  27,  0,   15, 0),
(45, 'Rogede sild',                   21,  8, '1k pkg.',                9.50,  5,   70,  15, 0),
(46, 'Spegesild',                     21,  8, '4 - 450 g glasses',     12.00,  95,  0,   0,  0),
(47, 'Zaanse koeken',                 22,  3, '10 - 4 oz boxes',        9.50,  36,  0,   0,  0),
(48, 'Chocolade',                     22,  3, '10 pkgs.',              12.75,  15,  70,  25, 0),
(49, 'Maxilaku',                      23,  3, '24 - 50 g pkgs.',       20.00,  10,  60,  15, 0),
(50, 'Valkoinen suklaa',              23,  3, '12 - 100 g bars',       16.25,  65,  0,   30, 0),
(51, 'Manjimup Dried Apples',          7,  7, '50 - 300 g pkgs.',      53.00,  20,  0,   10, 0),
(52, 'Filo Mix',                      24,  5, '16 - 2 kg boxes',        7.00,  38,  0,   25, 0),
(53, 'Perth Pasties',                  7,  6, '48 pieces',             32.80,  0,   0,   0,  1),
(54, 'Tourtieres',                    25,  6, '16 pies',               7.45,  21,  0,   10, 0),
(55, 'Pate chinois',                  25,  6, '24 boxes x 2 pies',     24.00,  115, 0,   20, 0),
(56, 'Gnocchi di nonna Alice',        26,  5, '24 - 250 g pkgs.',      38.00,  21,  10,  30, 0),
(57, 'Ravioli Angelo',                26,  5, '24 - 250 g pkgs.',      19.50,  36,  0,   20, 0),
(58, 'Escargots de Bourgogne',        27,  8, '24 pieces',             13.25,  62,  0,   20, 0),
(59, 'Raclette Courdavault',          28,  4, '5 kg pkg.',             55.00,  79,  0,   0,  0),
(60, 'Camembert Pierrot',             28,  4, '15 - 300 g rounds',     34.00,  19,  0,   0,  0),
(61, 'Sirop d erable',                29,  2, '24 - 500 ml bottles',   28.50,  113, 0,   25, 0),
(62, 'Tarte au sucre',                29,  3, '48 pies',               49.30,  17,  0,   0,  0),
(63, 'Vegie-spread',                   7,  2, '15 - 625 g jars',       43.90,  24,  0,   5,  0),
(64, 'Wimmers gute Semmelknodel',     12,  5, '20 bags x 4 pieces',    33.25,  22,  80,  30, 0),
(65, 'Louisiana Fiery Hot Pepper Sauce',2, 2, '32 - 8 oz bottles',    21.05,  76,  0,   0,  0),
(66, 'Louisiana Hot Spiced Okra',      2,  2, '24 - 8 oz jars',       17.00,  4,   100, 20, 0),
(67, 'Laughing Lumberjack Lager',     16,  1, '24 - 12 oz bottles',   14.00,  52,  0,   10, 0),
(68, 'Scottish Longbreads',            8,  3, '10 boxes x 8 pieces',   12.50,  6,   10,  15, 0),
(69, 'Gudbrandsdalsost',              15,  4, '10 kg pkg.',            36.00,  26,  0,   15, 0),
(70, 'Outback Lager',                  7,  1, '24 - 355 ml bottles',   15.00,  15,  10,  30, 0),
(71, 'Flotemysost',                   15,  4, '10 - 500 g pkgs.',      21.50,  26,  0,   0,  0),
(72, 'Mozzarella di Giovanni',        14,  4, '24 - 200 g pkgs.',      34.80,  14,  0,   0,  0),
(73, 'Rod Kaviar',                    17,  8, '24 - 150 g jars',       15.00,  101, 0,   5,  0),
(74, 'Longlife Tofu',                  4,  7, '5 kg pkg.',             10.00,  4,   20,  5,  0),
(75, 'Rhonbrau Klosterbier',          12,  1, '24 - 0.5 l bottles',    7.75,  125, 0,   25, 0),
(76, 'Lakkalikoori',                  23,  1, '500 ml',               18.00,  57,  0,   20, 0),
(77, 'Original Frankfurter',          12,  2, '12 boxes',             13.00,  32,  0,   15, 0),
(78, 'Nagaraya',                      17,  8, '24 - 150 g jars',      15.00,  101, 0,   5,  0),
(79, 'Fundador',                       4,  7, '5 kg pkg.',            10.00,  4,   20,  5,  0),
(80, 'Pilsner',                       12,  1, '24 - 0.5 l bottles',    7.75,  125, 0,   25, 0),
(81, 'Atomic Wine',                   23,  1, '500 ml',               18.00,  57,  0,   20, 0),
(82, 'Yamazaki',                      12,  2, '12 boxes',             13.00,  32,  0,   15, 0);

-- Sample orders
INSERT IGNORE INTO orders
    (order_id, customer_id, employee_id, order_date, required_date, shipped_date, ship_via, freight, ship_name, ship_country)
VALUES
(10248, 'ALFKI', 5, '2024-07-04', '2024-08-01', '2024-07-16', 3, 32.38,  'Alfreds Futterkiste',      'Germany'),
(10249, 'ANATR', 6, '2024-07-05', '2024-08-16', '2024-07-10', 1, 11.61,  'Ana Trujillo Emparedados', 'Mexico'),
(10250, 'ANTON', 4, '2024-07-08', '2024-08-05', '2024-07-12', 2, 65.83,  'Antonio Moreno Taqueria',  'Mexico'),
(10251, 'AROUT', 3, '2024-07-08', '2024-08-05', '2024-07-15', 1, 41.34,  'Around the Horn',          'UK'),
(10252, 'BERGS', 4, '2024-07-09', '2024-08-06', '2024-07-11', 2, 51.30,  'Berglunds snabbkop',       'Sweden'),
(10253, 'BLAUS', 3, '2024-07-10', '2024-07-24', '2024-07-16', 2, 58.17,  'Blauer See Delikatessen',  'Germany'),
(10254, 'BOLID', 5, '2024-07-11', '2024-08-08', '2024-07-23', 2, 22.98,  'Bolido Comidas preparadas','Spain'),
(10255, 'BONAP', 9, '2024-07-12', '2024-08-09', '2024-07-15', 3, 148.33, 'Bon app',                  'France'),
(10256, 'BOTTM', 3, '2024-07-15', '2024-08-12', '2024-07-17', 2, 13.97,  'Bottom-Dollar Markets',    'Canada'),
(10257, 'BSBEV', 4, '2024-07-16', '2024-08-13', '2024-07-22', 3, 81.91,  'B-s Beverages',            'UK'),
(10258, 'CACTU', 1, '2024-07-17', '2024-08-14', '2024-07-23', 1, 140.51, 'Cactus Comidas para llevar','Argentina'),
(10259, 'CENTC', 4, '2024-07-18', '2024-08-15', '2024-07-25', 3, 3.25,   'Centro comercial Moctezuma','Mexico'),
(10260, 'CHOPS', 4, '2024-07-19', '2024-08-16', '2024-07-29', 1, 55.09,  'Chop-suey Chinese',        'Switzerland'),
(10261, 'COMMI', 4, '2024-07-19', '2024-08-16', '2024-07-30', 2, 3.05,   'Comercio Mineiro',         'Brazil'),
(10262, 'CONSH', 8, '2024-07-22', '2024-08-19', '2024-07-25', 3, 48.29,  'Consolidated Holdings',    'UK'),
(10263, 'DRACD', 9, '2024-07-23', '2024-08-20', '2024-07-31', 3, 146.06, 'Drachenblut Delikatessen', 'Germany'),
(10264, 'DUMON', 6, '2024-07-24', '2024-08-21', '2024-08-23', 3, 3.67,   'Du monde entier',          'France'),
(10265, 'EASTC', 2, '2024-07-25', '2024-08-22', '2024-08-12', 1, 55.28,  'Eastern Connection',       'UK'),
(10266, 'ERNSH', 3, '2024-07-26', '2024-09-06', '2024-07-31', 3, 25.73,  'Ernst Handel',             'Austria'),
(10267, 'FAMIA', 4, '2024-07-29', '2024-08-26', '2024-08-06', 1, 208.58, 'Familia Arquibaldo',       'Brazil'),
(10268, 'ALFKI', 8, '2024-07-30', '2024-08-27', '2024-08-02', 3, 66.29,  'Alfreds Futterkiste',      'Germany'),
(10269, 'ANATR', 5, '2024-07-31', '2024-08-14', '2024-08-09', 1, 4.56,   'Ana Trujillo Emparedados', 'Mexico'),
(10270, 'ANTON', 1, '2024-08-01', '2024-08-29', '2024-08-02', 1, 136.54, 'Antonio Moreno Taqueria',  'Mexico'),
(10271, 'AROUT', 6, '2024-08-01', '2024-08-29', '2024-08-30', 2, 4.54,   'Around the Horn',          'UK'),
(10272, 'BERGS', 6, '2024-08-02', '2024-08-30', '2024-08-06', 2, 98.03,  'Berglunds snabbkop',       'Sweden'),
(10273, 'BLAUS', 3, '2024-08-05', '2024-09-02', '2024-08-12', 3, 76.07,  'Blauer See Delikatessen',  'Germany'),
(10274, 'BOLID', 6, '2024-08-06', '2024-09-03', '2024-08-16', 1, 6.01,   'Bolido Comidas preparadas','Spain'),
(10275, 'BONAP', 1, '2024-08-07', '2024-09-04', '2024-08-09', 1, 26.78,  'Bon app',                  'France'),
(10276, 'BOTTM', 8, '2024-08-08', '2024-08-22', '2024-08-14', 3, 13.84,  'Bottom-Dollar Markets',    'Canada'),
(10277, 'BSBEV', 2, '2024-08-09', '2024-09-06', '2024-08-13', 3, 125.77, 'B-s Beverages',            'UK'),
(10278, 'CACTU', 8, '2024-08-12', '2024-09-09', '2024-08-16', 2, 92.69,  'Cactus Comidas para llevar','Argentina'),
(10279, 'CENTC', 8, '2024-08-13', '2024-09-10', '2024-08-16', 2, 25.83,  'Centro comercial Moctezuma','Mexico'),
(10280, 'CHOPS', 2, '2024-08-14', '2024-09-11', '2024-09-12', 1, 8.98,   'Chop-suey Chinese',        'Switzerland'),
(10281, 'COMMI', 4, '2024-08-14', '2024-08-28', '2024-08-21', 2, 2.94,   'Comercio Mineiro',         'Brazil'),
(10282, 'CONSH', 4, '2024-08-15', '2024-09-12', '2024-08-21', 3, 12.69,  'Consolidated Holdings',    'UK'),
(10283, 'DRACD', 3, '2024-08-16', '2024-09-13', '2024-08-23', 3, 84.81,  'Drachenblut Delikatessen', 'Germany'),
(10284, 'DUMON', 4, '2024-08-19', '2024-09-16', '2024-08-27', 3, 76.56,  'Du monde entier',          'France'),
(10285, 'EASTC', 1, '2024-08-20', '2024-09-17', '2024-08-26', 2, 76.83,  'Eastern Connection',       'UK'),
(10286, 'ERNSH', 8, '2024-08-21', '2024-09-18', '2024-08-30', 3, 229.24, 'Ernst Handel',             'Austria'),
(10287, 'FAMIA', 8, '2024-08-22', '2024-09-19', '2024-08-28', 3, 12.76,  'Familia Arquibaldo',       'Brazil'),
(10288, 'ALFKI', 4, '2024-08-23', '2024-09-20', '2024-09-03', 1, 7.45,   'Alfreds Futterkiste',      'Germany'),
(10289, 'ANATR', 7, '2024-08-26', '2024-09-23', '2024-08-28', 3, 22.77,  'Ana Trujillo Emparedados', 'Mexico'),
(10290, 'ANTON', 8, '2024-08-27', '2024-09-24', '2024-09-03', 1, 79.70,  'Antonio Moreno Taqueria',  'Mexico'),
(10291, 'AROUT', 6, '2024-08-27', '2024-09-24', '2024-09-04', 2, 6.40,   'Around the Horn',          'UK'),
(10292, 'BERGS', 1, '2024-08-28', '2024-09-25', '2024-09-02', 2, 1.35,   'Berglunds snabbkop',       'Sweden'),
(10293, 'BLAUS', 1, '2024-08-29', '2024-09-26', '2024-09-11', 3, 21.18,  'Blauer See Delikatessen',  'Germany'),
(10294, 'BOLID', 4, '2024-08-30', '2024-09-27', '2024-09-05', 2, 147.26, 'Bolido Comidas preparadas','Spain'),
(10295, 'BONAP', 2, '2024-09-02', '2024-09-30', '2024-09-10', 2, 1.15,   'Bon app',                  'France'),
(10296, 'BOTTM', 6, '2024-09-03', '2024-10-01', '2024-09-11', 1, 0.12,   'Bottom-Dollar Markets',    'Canada'),
(10297, 'BSBEV', 5, '2024-09-04', '2024-10-16', '2024-09-10', 2, 5.74,   'B-s Beverages',            'UK'),
(10298, 'CACTU', 6, '2024-09-05', '2024-10-03', '2024-09-11', 2, 168.22, 'Cactus Comidas para llevar','Argentina'),
(10299, 'CENTC', 4, '2024-09-06', '2024-10-04', '2024-09-13', 2, 29.76,  'Centro comercial Moctezuma','Mexico'),
(10300, 'CHOPS', 2, '2024-09-09', '2024-10-07', '2024-09-18', 2, 17.68,  'Chop-suey Chinese',        'Switzerland');

-- Sample order_details
INSERT IGNORE INTO order_details (order_id, product_id, unit_price, quantity, discount) VALUES
(10248, 11,  14.00, 12, 0.00),
(10248, 42,  9.80,  10, 0.00),
(10248, 72,  34.80, 5,  0.00),
(10249, 14,  18.60, 9,  0.00),
(10249, 51,  42.40, 40, 0.00),
(10250, 41,  7.70,  10, 0.00),
(10250, 51,  42.40, 35, 0.15),
(10250, 65,  16.80, 15, 0.15),
(10251, 22,  16.80, 6,  0.05),
(10251, 57,  15.60, 15, 0.05),
(10251, 65,  16.80, 20, 0.00),
(10252, 20,  64.80, 40, 0.05),
(10252, 33,  2.00,  25, 0.05),
(10252, 60,  27.20, 40, 0.00),
(10253, 31,  10.00, 20, 0.00),
(10253, 39,  14.40, 42, 0.00),
(10253, 49,  16.00, 40, 0.00),
(10254, 24,  3.60,  15, 0.15),
(10254, 55,  19.20, 21, 0.15),
(10254, 74,  8.00,  21, 0.00),
(10255, 2,   15.20, 20, 0.00),
(10255, 16,  13.96, 35, 0.00),
(10255, 36,  15.20, 25, 0.00),
(10255, 59,  44.00, 30, 0.00),
(10256, 53,  26.24, 15, 0.00),
(10256, 77,  10.40, 12, 0.00),
(10257, 27,  35.12, 25, 0.00),
(10257, 39,  14.40, 6,  0.25),
(10257, 77,  10.40, 15, 0.00),
(10258, 2,   15.20, 50, 0.20),
(10258, 5,   17.08, 65, 0.20),
(10258, 32,  25.60, 6,  0.20),
(10259, 21,  8.00,  10, 0.00),
(10259, 37,  20.80, 1,  0.00),
(10260, 41,  7.70,  16, 0.25),
(10260, 57,  15.60, 50, 0.00),
(10260, 62,  39.44, 15, 0.25),
(10260, 70,  12.00, 21, 0.25),
(10261, 21,  8.00,  20, 0.00),
(10261, 35,  14.40, 20, 0.00),
(10262, 5,   17.08, 12, 0.20),
(10262, 7,   24.00, 15, 0.00),
(10262, 56,  30.40, 2,  0.00),
(10263, 16,  13.96, 60, 0.25),
(10263, 24,  3.60,  28, 0.00),
(10263, 30,  20.72, 60, 0.25),
(10263, 74,  8.00,  36, 0.25),
(10264, 2,   15.20, 35, 0.00),
(10264, 41,  7.70,  25, 0.15),
(10265, 17,  31.20, 30, 0.00),
(10265, 70,  12.00, 20, 0.00),
(10266, 12,  30.40, 12, 0.05),
(10267, 40,  14.72, 50, 0.00),
(10267, 59,  44.00, 70, 0.15),
(10267, 76,  14.40, 15, 0.15),
(10268, 29,  99.03, 10, 0.00),
(10268, 72,  27.84, 4,  0.00),
(10269, 33,  2.00,  60, 0.05),
(10269, 72,  27.84, 20, 0.00),
(10270, 36,  15.20, 30, 0.00),
(10270, 43,  36.80, 25, 0.00),
(10271, 33,  2.00,  24, 0.00),
(10272, 20,  64.80, 6,  0.00),
(10272, 31,  10.00, 40, 0.00),
(10272, 72,  27.84, 24, 0.00),
(10273, 10,  24.80, 24, 0.05),
(10273, 31,  10.00, 15, 0.05),
(10273, 33,  2.00,  20, 0.00),
(10273, 40,  14.72, 60, 0.05),
(10273, 76,  14.40, 33, 0.05),
(10274, 71,  17.20, 20, 0.00),
(10274, 72,  27.84, 7,  0.00),
(10275, 24,  3.60,  12, 0.00),
(10275, 29,  99.03, 6,  0.00),
(10275, 33,  2.00,  24, 0.00),
(10276, 10,  24.80, 15, 0.00),
(10276, 13,  4.80,  10, 0.00),
(10277, 28,  36.48, 20, 0.00),
(10277, 62,  39.44, 12, 0.00),
(10278, 44,  15.56, 16, 0.00),
(10278, 59,  44.00, 15, 0.00),
(10278, 63,  35.12, 8,  0.00),
(10278, 73,  12.00, 25, 0.00),
(10279, 17,  31.20, 15, 0.25),
(10279, 78,  15.00, 10, 0.00),
(10280, 24,  3.60,  12, 0.00),
(10280, 55,  19.20, 20, 0.00),
(10280, 75,  6.20,  30, 0.00),
(10281, 19,  7.36,  9,  0.00),
(10281, 35,  14.40, 4,  0.00),
(10282, 30,  20.72, 6,  0.00),
(10282, 57,  15.60, 2,  0.00),
(10283, 15,  12.40, 20, 0.00),
(10283, 19,  7.36,  18, 0.00),
(10283, 60,  27.20, 35, 0.00),
(10283, 72,  27.84, 3,  0.00),
(10284, 27,  35.12, 15, 0.25),
(10284, 44,  15.56, 21, 0.00),
(10284, 60,  27.20, 20, 0.25),
(10284, 67,  11.20, 5,  0.25),
(10285, 1,   14.40, 45, 0.20),
(10285, 40,  14.72, 40, 0.20),
(10285, 53,  26.24, 36, 0.20),
(10286, 35,  14.40, 100,0.00),
(10286, 62,  39.44, 40, 0.00),
(10287, 16,  13.96, 40, 0.15),
(10287, 34,  11.20, 20, 0.00),
(10287, 46,  9.60,  15, 0.15),
(10288, 54,  5.96,  10, 0.10),
(10288, 68,  10.00, 3,  0.10),
(10289, 3,   8.00,  30, 0.00),
(10289, 64,  26.60, 9,  0.00),
(10290, 5,   17.08, 20, 0.00),
(10290, 29,  99.03, 15, 0.00),
(10290, 49,  16.00, 15, 0.00),
(10290, 77,  10.40, 10, 0.00),
(10291, 13,  4.80,  20, 0.10),
(10291, 44,  15.56, 24, 0.10),
(10291, 51,  42.40, 2,  0.10),
(10292, 20,  64.80, 20, 0.00),
(10292, 42,  14.00, 15, 0.00),
(10293, 18,  50.00, 12, 0.00),
(10293, 24,  3.60,  10, 0.00),
(10293, 63,  35.12, 5,  0.00),
(10293, 75,  6.20,  6,  0.00),
(10293, 80,  7.75,  15, 0.00),
(10294, 1,   14.40, 18, 0.00),
(10294, 17,  31.20, 15, 0.00),
(10294, 43,  36.80, 15, 0.00),
(10294, 60,  27.20, 21, 0.00),
(10294, 75,  6.20,  6,  0.00),
(10295, 56,  30.40, 4,  0.00),
(10295, 67,  11.20, 1,  0.00),
(10296, 11,  16.80, 12, 0.00),
(10296, 16,  13.96, 30, 0.00),
(10296, 69,  28.80, 15, 0.00),
(10297, 39,  14.40, 60, 0.00),
(10297, 72,  27.84, 20, 0.00),
(10298, 2,   15.20, 40, 0.00),
(10298, 36,  15.20, 40, 0.25),
(10298, 59,  44.00, 30, 0.25),
(10298, 62,  39.44, 15, 0.00),
(10298, 78,  15.00, 10, 0.00),
(10299, 19,  7.36,  15, 0.00),
(10299, 70,  12.00, 20, 0.00),
(10299, 42,  14.00, 8,  0.00),
(10300, 66,  13.60, 30, 0.00),
(10300, 68,  10.00, 20, 0.00),
(10300, 42,  14.00, 4,  0.00);
