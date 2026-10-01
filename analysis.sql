-- =============================================================
-- Multi-Bank Banking Database: Analysis Queries
-- Each query answers one business question.
-- Run in DB Browser for SQLite (Execute SQL tab) against bank.db.
-- Amounts are stored in cents; queries divide by 100.0 for dollars.
-- =============================================================


-- -------------------------------------------------------------
-- Q1. Which customers have no accounts?
-- Concept: anti-join (LEFT JOIN + IS NULL)
-- -------------------------------------------------------------
SELECT
    c.first_name,
    c.last_name
FROM customers c
LEFT JOIN accounts a ON c.customer_id = a.customer_id
WHERE a.account_id IS NULL;


-- -------------------------------------------------------------
-- Q2. LEFT JOIN: filtering in WHERE vs in ON
-- Concept: where a condition on the right-hand table goes
-- -------------------------------------------------------------

-- Filter in WHERE: only customers with a checking account (5 rows)
SELECT c.first_name, c.last_name, a.account_number, a.account_type, a.balance_cents
FROM customers c
LEFT JOIN accounts a ON c.customer_id = a.customer_id
WHERE a.account_type = 'Checking';

-- Filter in ON: every customer, with NULLs where there's no checking account (12 rows)
SELECT c.first_name, c.last_name, a.account_number, a.account_type, a.balance_cents
FROM customers c
LEFT JOIN accounts a
    ON c.customer_id = a.customer_id
   AND a.account_type = 'Checking';


-- -------------------------------------------------------------
-- Q3. Which customers have an address in New York?
-- Concept: pattern matching with LIKE and %
-- Note: '%New York%' alone misses Brooklyn, NY; the second
-- pattern catches it. Separate city/state columns would be exact.
-- -------------------------------------------------------------
SELECT *
FROM customers
WHERE address LIKE '%New York%'
   OR address LIKE '%, NY';


-- -------------------------------------------------------------
-- Q4. Which customers have a savings account?
-- Concept: DISTINCT (list customers, not accounts)
-- -------------------------------------------------------------
SELECT DISTINCT c.first_name, c.last_name
FROM customers c
JOIN accounts a ON c.customer_id = a.customer_id
WHERE a.account_type = 'Savings';


-- -------------------------------------------------------------
-- Q5. How many transactions are in the table?
-- Concept: COUNT(*), COUNT(column), COUNT(DISTINCT column)
-- -------------------------------------------------------------
SELECT
    COUNT(*)                   AS total_rows,
    COUNT(description)         AS rows_with_description,
    COUNT(DISTINCT account_id) AS accounts_with_transactions
FROM transactions;


-- -------------------------------------------------------------
-- Q6. What is total spending by category, largest first?
-- Concept: SUM + GROUP BY + ORDER BY ... DESC
-- Transfers to investment accounts are excluded: moved, not spent.
-- -------------------------------------------------------------
SELECT
    category,
    SUM(transaction_amount_cents) / 100.0 AS total_spent
FROM transactions
WHERE transaction_type = 'Debit'
  AND category <> 'Transfer'
GROUP BY category
ORDER BY total_spent DESC;


-- -------------------------------------------------------------
-- Q7. What is total spending per month?
-- Concept: grouping by part of a date with strftime
-- -------------------------------------------------------------
SELECT
    strftime('%Y-%m', transaction_date) AS month,
    SUM(transaction_amount_cents) / 100.0 AS total_spent
FROM transactions
WHERE transaction_type = 'Debit'
  AND category <> 'Transfer'
GROUP BY month
ORDER BY month;

-- Drill-down: travel spending by month (explains the March and August spikes)
SELECT
    strftime('%Y-%m', transaction_date) AS month,
    SUM(transaction_amount_cents) / 100.0 AS total_spent
FROM transactions
WHERE transaction_type = 'Debit'
  AND category = 'Travel'
GROUP BY month
ORDER BY month;


-- -------------------------------------------------------------
-- Q8. Who are the biggest spenders?
-- Concept: joining through a middle table, then aggregating
-- transactions -> accounts -> customers
-- -------------------------------------------------------------
SELECT
    c.first_name,
    c.last_name,
    SUM(t.transaction_amount_cents) / 100.0 AS total_spent
FROM transactions t
JOIN accounts a ON t.account_id = a.account_id
JOIN customers c ON a.customer_id = c.customer_id
WHERE t.transaction_type = 'Debit'
  AND t.category <> 'Transfer'
GROUP BY c.customer_id
ORDER BY total_spent DESC;


-- -------------------------------------------------------------
-- Q9. How much money sits at each bank?
-- Concept: one join + GROUP BY, then explaining an outlier
-- -------------------------------------------------------------
SELECT
    b.bank_name,
    SUM(a.balance_cents) / 100.0 AS total_balance
FROM banks b
JOIN accounts a ON b.bank_id = a.bank_id
GROUP BY b.bank_name
ORDER BY total_balance DESC;

-- Drill-down: what's behind the American Express total?
SELECT *
FROM account_summary
WHERE bank_name = 'American Express';
