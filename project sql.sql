CREATE DATABASE Customers_transactions;
UPDATE customers SET Gender = NULL WHERE Gender = '';
UPDATE customers SET Age = NULL WHERE Age = '';
ALTER TABLE customers MODIFY Age INT NULL;

SELECT * FROM customers;

CREATE TABLE transactions
(Date_new DATE,
Id_check INT,
ID_client INT,
Count_products DECIMAL(10,3),
Sum_payment DECIMAL(10,2));

LOAD DATA INFILE "C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\transactions_info.xlsx ok.csv"
INTO TABLE transactions
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SHOW VARIABLES LIKE 'secure_file_priv';
SELECT * FROM transactions;

#Задание1

WITH monthly_ops AS (
  SELECT
    ID_client,
    DATE_FORMAT(Date_new, '%Y-%m') AS ym,
    COUNT(*) AS ops_month,
    SUM(Sum_payment) AS revenue_month
  FROM transactions
  WHERE Date_new BETWEEN '2015-06-01' AND '2016-05-31'
  GROUP BY ID_client, ym
),
continuous_clients AS (
  SELECT ID_client
  FROM monthly_ops
  GROUP BY ID_client
  HAVING COUNT(DISTINCT ym) = 12
)

#Задание2
#a
SELECT
    DATE_FORMAT(date_new, '%Y-%m') AS month,
    SUM(Sum_payment) / COUNT(Id_check) AS avg_check
FROM transactions
GROUP BY month
ORDER BY month;

#b
SELECT
    DATE_FORMAT(date_new, '%Y-%m') AS month,
    COUNT(Id_check) AS operations
FROM transactions
GROUP BY month
ORDER BY month;

#c
SELECT
    AVG(cnt_clients) AS avg_clients_per_month
FROM (
    SELECT 
        DATE_FORMAT(date_new, '%Y-%m') AS month,
        COUNT(DISTINCT ID_client) AS cnt_clients
    FROM transactions
    GROUP BY month
) m;

#d
WITH monthly AS (
    SELECT
        DATE_FORMAT(date_new, '%Y-%m') AS month,
        COUNT(Id_check) AS ops_month,
        SUM(Sum_payment) AS sum_month
    FROM transactions
    GROUP BY month
),
yearly AS (
    SELECT 
        COUNT(Id_check) AS ops_year,
        SUM(Sum_payment) AS sum_year
    FROM transactions
)
SELECT
    m.month,
    m.ops_month,
    m.sum_month,
    m.ops_month / y.ops_year AS share_ops_year,
    m.sum_month / y.sum_year AS share_sum_year
FROM monthly m
CROSS JOIN yearly y
ORDER BY m.month;

#e
SELECT
    DATE_FORMAT(t.date_new, '%Y-%m') AS month,
    c.Gender,
    COUNT(*) AS ops_count,
    SUM(t.Sum_payment) AS total_sum,
    COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY DATE_FORMAT(t.date_new, '%Y-%m')) AS gender_share_ops,
    SUM(t.Sum_payment) / SUM(SUM(t.Sum_payment)) OVER (PARTITION BY DATE_FORMAT(t.date_new, '%Y-%m')) AS gender_share_sum
FROM transactions t
JOIN customers c ON c.Id_client = t.ID_client
GROUP BY month, c.Gender
ORDER BY month, c.Gender;

#Задание3
WITH base AS (
    SELECT
        t.ID_client,
        t.Sum_payment,
        t.Id_check,
        t.date_new,
        c.Age,
        CASE
            WHEN c.Age IS NULL THEN 'NA'
            ELSE CONCAT(FLOOR(c.Age / 10) * 10, '-', FLOOR(c.Age / 10) * 10 + 9)
        END AS age_group
    FROM transactions t
    LEFT JOIN customers c ON t.ID_client = c.Id_client
    WHERE t.date_new >= '2015-06-01'
      AND t.date_new <  '2016-06-01'
),

quarters AS (
    SELECT
        age_group,
        QUARTER(date_new) AS quarter,
        SUM(Sum_payment) AS amount_q,
        COUNT(Id_check) AS ops_q,
        COUNT(DISTINCT ID_client) AS clients_q
    FROM base
    GROUP BY age_group, quarter
),

total AS (
    SELECT
        age_group,
        SUM(Sum_payment) AS total_amount,
        COUNT(Id_check) AS total_ops
    FROM base
    GROUP BY age_group
)

SELECT
    q.age_group,
    q.quarter,
    q.amount_q,
    q.ops_q,
    q.clients_q,
    
    /* средние квартальные показатели */
    q.amount_q / q.clients_q AS avg_amount_per_client_q,
    q.ops_q / q.clients_q AS avg_ops_per_client_q,

    /* % от общего для группы */
    q.amount_q / t.total_amount AS amount_pct_group,
    q.ops_q / t.total_ops AS ops_pct_group
FROM quarters q
JOIN total t USING (age_group)
ORDER BY age_group, quarter;