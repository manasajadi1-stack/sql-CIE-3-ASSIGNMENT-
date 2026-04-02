DROP DATABASE IF EXISTS bank_db;
CREATE DATABASE bank_db;
USE bank_db;

CREATE TABLE accounts (
    account_id INT PRIMARY KEY,
    name VARCHAR(100),
    balance DECIMAL(10,2)
);

CREATE TABLE transactions (
    txn_id INT PRIMARY KEY,
    account_id INT,
    amount DECIMAL(10,2),
    txn_type VARCHAR(10),
    txn_date DATETIME,
    FOREIGN KEY (account_id) REFERENCES accounts(account_id)
);

CREATE TABLE logs (
    log_id INT PRIMARY KEY AUTO_INCREMENT,
    message VARCHAR(255),
    log_time DATETIME
);

DELIMITER $$

CREATE TRIGGER trg_validate_withdrawal
BEFORE INSERT ON transactions
FOR EACH ROW
BEGIN
    DECLARE current_balance DECIMAL(10,2);

    IF NEW.txn_type = 'Withdraw' THEN
        SELECT balance INTO current_balance
        FROM accounts
        WHERE account_id = NEW.account_id;

        IF current_balance < NEW.amount THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Insufficient balance for withdrawal';
        END IF;
    END IF;
END$$

DELIMITER ;

DELIMITER $$

CREATE TRIGGER trg_update_balance
AFTER INSERT ON transactions
FOR EACH ROW
BEGIN
    IF NEW.txn_type = 'Deposit' THEN
        UPDATE accounts
        SET balance = balance + NEW.amount
        WHERE account_id = NEW.account_id;

    ELSEIF NEW.txn_type = 'Withdraw' THEN
        UPDATE accounts
        SET balance = balance - NEW.amount
        WHERE account_id = NEW.account_id;
    END IF;
END$$

DELIMITER ;

DELIMITER $$

CREATE TRIGGER trg_log_transaction
AFTER INSERT ON transactions
FOR EACH ROW
BEGIN
    DECLARE log_msg VARCHAR(255);

    IF NEW.txn_type = 'Deposit' THEN
        SET log_msg = CONCAT('Transaction of ', NEW.amount,
                             ' deposited for Account ', NEW.account_id);
    ELSE
        SET log_msg = CONCAT('Transaction of ', NEW.amount,
                             ' withdrawn from Account ', NEW.account_id);
    END IF;

    INSERT INTO logs(message, log_time)
    VALUES (log_msg, NOW());
END$$

DELIMITER ;

INSERT INTO accounts VALUES (101, 'Manasa', 1000);

INSERT INTO transactions VALUES (1, 101, 500, 'Deposit', NOW());

INSERT INTO transactions VALUES (2, 101, 300, 'Withdraw', NOW());

SELECT * FROM accounts;
SELECT * FROM transactions;
SELECT * FROM logs;
SELECT account_id, name, balance
FROM accounts;

SELECT * 
FROM transactions
WHERE account_id = 101;

SELECT SUM(amount) AS total_deposit
FROM transactions
WHERE txn_type = 'Deposit';

SELECT SUM(amount) AS total_withdraw
FROM transactions
WHERE txn_type = 'Withdraw';

SELECT 
    account_id,
    SUM(CASE 
            WHEN txn_type = 'Deposit' THEN amount 
            ELSE -amount 
        END) AS calculated_balance
FROM transactions
GROUP BY account_id;

SELECT a.account_id, a.name, t.txn_id, t.amount, t.txn_type, t.txn_date
FROM accounts a
JOIN transactions t
ON a.account_id = t.account_id;

SELECT * FROM logs;

SELECT * 
FROM transactions
ORDER BY txn_date DESC;

SELECT account_id, COUNT(*) AS total_transactions
FROM transactions
GROUP BY account_id;

SELECT * 
FROM transactions
WHERE txn_type = 'Deposit';

SELECT * 
FROM transactions
WHERE txn_type = 'Withdraw';

SELECT * 
FROM accounts
WHERE balance < 0;

SELECT t.txn_id, t.amount, t.txn_type, l.message
FROM transactions t
JOIN logs l
ON l.message LIKE CONCAT('%', t.account_id, '%');

SELECT 
    a.account_id,
    a.name,
    a.balance,
    COUNT(t.txn_id) AS total_transactions
FROM accounts a
LEFT JOIN transactions t
ON a.account_id = t.account_id
GROUP BY a.account_id;
