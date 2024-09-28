CREATE TRIGGER transaction_year_month_insert
AFTER INSERT ON transactions
FOR EACH ROW
BEGIN

    UPDATE transactions SET year_month =
        (CAST(strftime('%Y', datetime(NEW.transaction_date / 1000, 'unixepoch')) AS INTEGER) * 12) +
         CAST(strftime('%m', datetime(NEW.transaction_date / 1000, 'unixepoch')) AS INTEGER)
    WHERE id = NEW.id;

--    INSERT INTO debug_log (message) VALUES (
--        'Inserted a new transaction with ID: ' || NEW.id || ' and datetime ' || NEW.transaction_date || ' with year value ' || ((CAST(strftime('%Y', datetime(NEW.transaction_date / 1000, 'unixepoch')) AS INTEGER) * 12) +
--         CAST(strftime('%m', datetime(NEW.transaction_date / 1000, 'unixepoch')) AS INTEGER))
--    );
END;

CREATE TRIGGER transaction_year_month_update
AFTER UPDATE OF transaction_date ON transactions
FOR EACH ROW
BEGIN
    UPDATE transactions SET year_month =
        (CAST(strftime('%Y', datetime(NEW.transaction_date / 1000, 'unixepoch')) AS INTEGER) * 12) +
         CAST(strftime('%m', datetime(NEW.transaction_date / 1000, 'unixepoch')) AS INTEGER)
    WHERE id = NEW.id;
--    INSERT INTO debug_log (message) VALUES (
--        'Update a transaction with ID: ' || NEW.id || ' and datetime ' || NEW.transaction_date || ' with year value ' || ((CAST(strftime('%Y', datetime(NEW.transaction_date / 1000, 'unixepoch')) AS INTEGER) * 12) +
--         CAST(strftime('%m', datetime(NEW.transaction_date / 1000, 'unixepoch')) AS INTEGER))
--    );
END;