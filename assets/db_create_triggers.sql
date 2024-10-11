CREATE TRIGGER transaction_after_insert
AFTER INSERT ON transactions
FOR EACH ROW
BEGIN

    UPDATE transactions SET year_month =
        (CAST(strftime('%Y', datetime(NEW.transaction_date / 1000, 'unixepoch')) AS INTEGER) * 12) +
         CAST(strftime('%m', datetime(NEW.transaction_date / 1000, 'unixepoch')) AS INTEGER)
    WHERE id = NEW.id;

    -- Set initial value of remaining_amount for shared bill
    UPDATE transactions SET remaining_amount = amount - my_split where NEW.transaction_type = 'shareBill' AND id=NEW.id;

    -- Reduce shared bill remaining amount by the amount returned
    UPDATE transactions SET remaining_amount = remaining_amount - NEW.amount where transaction_type = 'shareBill' AND id=NEW.shared_bill_id AND NEW.transaction_type = 'shareBillReturn';

    -- Set shared bill return category id by shared bill category id
    UPDATE transactions SET transaction_category_uid = (select transaction_category_uid from transactions WHERE id=NEW.shared_bill_id) where transaction_type = 'shareBillReturn' AND id=NEW.id;

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

    -- TODO Update shared bill remaining amount by the amount updated
    -- TODO update shared bill return category id by shared bill category id updated
--    INSERT INTO debug_log (message) VALUES (
--        'Update a transaction with ID: ' || NEW.id || ' and datetime ' || NEW.transaction_date || ' with year value ' || ((CAST(strftime('%Y', datetime(NEW.transaction_date / 1000, 'unixepoch')) AS INTEGER) * 12) +
--         CAST(strftime('%m', datetime(NEW.transaction_date / 1000, 'unixepoch')) AS INTEGER))
--    );
END;