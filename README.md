# Multi-Bank Banking Database: Design and Analysis in SQLite

A Multi-bank banking database, built in SQLite, that tracks customers and their accounts across different banks, similar to the functions of aggregators such as Plaid or Mint. This database allows you to look at multiple transactions and accounts across different banks for multiple customers. This database contains 400+ sample transactions that I was able to write multiple analysis queries on. It contains transaction and account information of 5 different banks (American Express, Chase Bank, Bank of America, TD Bank and Citizens Bank) amongst 11 customers.

## Why I Built This

I built this because I wanted to learn how to design a database and analyze it from start to finish. I have always been interested in financial services/banking ever since I was in college. My first role out of college was at a Federal Savings Bank which was a Mortgage Lender. I have been looking for a way to get back into the industry and am keen on learning more. I created this project to learn more about transaction analysis and how money moves from one account to another. This was a great way to learn to identify discrepancies without looking through 424 separate lines of transactions to identify the one or two discrepancies in the entire dataset. 

## Database Design

This database has four tables linked by foreign keys:
- **Customers.** One row per customer;  customer_id is the Primary Key (PK), first_name, last_name, address, email
- **Banks**. One row per bank; bank_id (PK), bank_name
- **Accounts**. One row per bank account; account_id (PK), customer_id is one of the Foreign Keys (FK), bank_id (FK), account_number, account_type, balance
- **Transactions**. One row per transaction; transaction_id (PK), account_id (FK), transaction_date, category, transaction_type, transaction_amount_cents, description

One customer can have many accounts, one bank can hold many accounts, and one account can have many transactions.

'''
customers -< accounts >- banks
                |
                ^
            transactions
'''

## Key Design Decisions

- **Money is stored in cents as 'INTEGER'.** Decimal numbers can round incorrectly ('0.1 + 0.2' gives '0.300000000004'), so $1,523.75 is stored as '152375'. Queries devide by '100.0' only when displaying in dollars.
- **Account numbers are 'TEXT".** They are labels, not numbers, so leading zeros like '0001' are kept and no math is implied. 
- **An account number is unique within its bank, not across banks.** UNIQUE (bank_id, account_number)' ;ets acount '0001' exists at four different banks while blocking a duplicate at the same bank.. 
- **Bank names are unique.** A duplicae bank slipped in during testing, so I removed it and added a unique index ('idx_bank_name') to block repeats.
- **Transactions link to the account only.** The customer and account type are reached by joining through 'accounts', so each fac is stored in one place and can't fall out of sync.
- **Amounts are always positive, with a 'transaction_type' column.** ('Debit' or 'Credit') saying whether money went out or came in.
- **Dates are stored as 'YYYY-MM-DD' text (ISO 8601).** Alphabetical order matches chronologial order so sorting and date ranges work correctly. 

## Analysis and Findings

The queries live in 'analysis.sql'

| Question | SQL Concepts | Finding |
|---|---|---|
| Which customers have no accounts? | 'LEFT JOIN', IS NULL'(anti-join) | 6 of 11 customers have no accounts yet |
| Does filtering a 'LEFT JOIN' in 'WHERE' vs 'ON' change the result | 'LEFT JOIN', filter placement | Same condition: 5 rows in 'WHERE', 12 rows in 'ON' |
| Which customers live in New York? | 'LIKE', '%' wildcard | 6 found, but a Brooklyn address was missed because it never says "New York": a data-quality issue, not a query bug |
| Which customers have a savings account? | 'JOIN', 'DISTINCT' | 4 customers (5 rows without 'DISTINCT'), since one customer has two savings accounts |
| Did all the transactions load | 'COUNT(*)', 'COUNT(DISTINCT)' | 424 rows across 10 accounts matching the source CSV | 
| What is total spending by category? | 'SUM', 'GROUP BY', 'ORDER BY' | About $208K of true spending once transfers are excluded; rent is about 84% of it |
| How does spending change from month to month | 'strftime', 'GROUP BY' | Steady baseline of about $21,900 a month, with spikes in March ($25.5K) and August ($26.6K) both driven by travel | 
| Who are the biggest spenders? | Three-table join, 'GROUP BY' | Michael Ross leads at $92.8K followed by Donna Paulsen at $52.5K |
| How much money sits at each bank? | 'JOIN', 'SUM', 'GROUP BY' | American express holds $6.0M, but 99.9% of it is one customer's savings account: a concentration risk a real bank would definitely flag |

A few judgment calls behind these numbers:

- **Spending means debits only.** Adding every row mixed money in amd money out into a meaningless total
- **Transfers are excluded from spending.** Two large brokerage transfers aren't consumer spending and would distort the category ranking.
- **Spikes get a drill-down.** When a month stands out, I break it down by category to find the cause rather than stopping at the total. 



## Automation

- **Account Summary View:** joins customers, banks and accounts into one readable table, with balances shown in dollars. It reruns every time, so new accounts appear automatically.
- **Balance Triggers:** two triggers ('trg_debit_balance_update' and 'trg_credit_balance_update') update an account's balance whwnever a transaction is inserted. Debits subtract and credits add. I tested this by inserting a $50 grocery debit and confirming the balance dropped from $2,470.00 to $2,420.00 without touching the 'accounts' table.

## How to Run It

1. Download or clone this repository
2. Open 'bank.db' in [DB Browser for SQLite] (https://sqlitebrowser.org/) (free, Mac and Windows).
3. Go to the **Execute SQL** tab, paste a query from 'analysis.sql', and run it.

Or from the command line:

'''
sqlite3 bank.db < analysis.sql
'''

## Project Files

| File| What it is|
|---|---|
| 'bank.db' | The SQLite database with all four tables, the view and the triggers |
| 'analysis.sql' | The analysis queries, each commented with the question it answers |
| 'transactions.csv' | The 424 sample transactions imported into the trenasctions table

## What I Learnt

- **Leetcode Practice.** This was a great way to practice Leetcode from scratch. I was able to create my own dataset and practice Leetcode with it. 
- **Knowing my own data made my queries trustworthy**. By creating my own dataset, I was able to understand my own data, which allowed me to verify whether the queries I wrote yielded the correct results. 
- **Testing Rules By Breaking Them.** I inserted bad data on purpose to see certain errors to check if my rules were working. 
- **Reading Error Messages.** Most errors pointed just after the real mistake. Many of my mistakes were simple ones such as missing a comma, adding an extra comma somewhere, extra/missed parentheses, closing the query off with a semicolon. 
- **Business judgement matters as much as syntax.** Deciding what counts as spending, excluding transfers, and noticing that a text search missed a Brooklyn address changed the answers more than any single SQL keyword. 

## What I Would Add Next

- Split 'address' into 'street', 'city', 'state', and 'zip' so location filters are more exact
- A calendar table so months with no activity show as $0 instead of disappearing.
- A dashboard on top of the queries. 




