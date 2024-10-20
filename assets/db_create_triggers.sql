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
    UPDATE transactions SET remaining_amount = remaining_amount - NEW.fee_amount
    where transaction_type = 'shareBill' AND id=NEW.shared_bill_id AND NEW.transaction_type = 'shareBillReturn';

    -- Set shared bill return category id by shared bill category id
    UPDATE transactions SET transaction_category_uid = (select transaction_category_uid from transactions WHERE id=NEW.shared_bill_id) where transaction_type = 'shareBillReturn' AND id=NEW.id;

    -- Income & transfer in & shared bill returned
    update asset set available_amount = available_amount + NEW.amount - CASE
                                                                            WHEN (NEW.transaction_type <> 'transfer' OR (NEW.transaction_type = 'transfer' AND NEW.fee_apply_to_from_account <> 0)) THEN NEW.fee_amount
                                                                            ELSE 0
                                                                        END
       WHERE ((uid = NEW.account_uid and (NEW.transaction_type = 'income' or NEW.transaction_type = 'shareBillReturn')) or (uid = NEW.to_account_uid and NEW.transaction_type = 'transfer'))
       and asset_type <> 'loan';
    update asset set loan_amount = loan_amount - NEW.amount + CASE
                                                                  WHEN (NEW.transaction_type <> 'transfer' OR (NEW.transaction_type = 'transfer' AND NEW.fee_apply_to_from_account <> 0)) THEN NEW.fee_amount
                                                                  ELSE 0
                                                              END
       WHERE ((uid = NEW.account_uid and (NEW.transaction_type = 'income' or NEW.transaction_type = 'shareBillReturn')) or (uid = NEW.to_account_uid and NEW.transaction_type = 'transfer'))
       and asset_type = 'loan';

    -- Expense & transfer out & Shared bill paid
    update asset set available_amount = available_amount - NEW.amount - CASE
                                                                            WHEN (NEW.transaction_type <> 'transfer' OR (NEW.transaction_type = 'transfer' AND NEW.fee_apply_to_from_account <> 0)) THEN NEW.fee_amount
                                                                            ELSE 0
                                                                        END
       WHERE uid = NEW.account_uid and (NEW.transaction_type = 'expense' or NEW.transaction_type = 'transfer' or NEW.transaction_type = 'shareBill') and asset_type <> 'loan';
    update asset set loan_amount = loan_amount + NEW.amount + CASE
                                                                  WHEN (NEW.transaction_type <> 'transfer' OR (NEW.transaction_type = 'transfer' AND NEW.fee_apply_to_from_account <> 0)) THEN NEW.fee_amount
                                                                  ELSE 0
                                                              END
       WHERE uid = NEW.account_uid and (NEW.transaction_type = 'expense' or NEW.transaction_type = 'transfer' or NEW.transaction_type = 'shareBill') and asset_type = 'loan';

    -- Adjustment
    update asset set available_amount = NEW.amount WHERE uid = NEW.account_uid and NEW.transaction_type = 'adjustment' and asset_type <> 'loan';
    update asset set loan_amount = NEW.amount WHERE uid = NEW.account_uid and NEW.transaction_type = 'adjustment' and asset_type = 'loan';

--    INSERT INTO debug_log (message) VALUES (
--        'Inserted a new transaction with ID: ' || NEW.id || ' and datetime ' || NEW.transaction_date || ' with year value ' || ((CAST(strftime('%Y', datetime(NEW.transaction_date / 1000, 'unixepoch')) AS INTEGER) * 12) +
--         CAST(strftime('%m', datetime(NEW.transaction_date / 1000, 'unixepoch')) AS INTEGER))
--    );

    -- Insert statistic if not existed
    INSERT OR IGNORE INTO resource_statistic_daily (resource_type, resource_uid, stat_year,
        stat_month, stat_day,
        currency_uid, last_updated) VALUES
        ('account', NEW.account_uid, CAST(strftime('%Y', datetime(NEW.transaction_date / 1000, 'unixepoch')) AS INTEGER),
        CAST(strftime('%m', datetime(NEW.transaction_date / 1000, 'unixepoch')) AS INTEGER), CAST(strftime('%d', datetime(NEW.transaction_date / 1000, 'unixepoch')) AS INTEGER),
        NEW.currency_uid, unixepoch() * 1000);
    INSERT OR IGNORE INTO resource_statistic_daily (resource_type, resource_uid, stat_year,
        stat_month, stat_day,
        currency_uid, last_updated) VALUES
        ('category',CASE
                      WHEN NEW.transaction_category_uid IS NOT NULL THEN NEW.transaction_category_uid
                      ELSE NEW.transaction_type
                    END, CAST(strftime('%Y', datetime(NEW.transaction_date / 1000, 'unixepoch')) AS INTEGER),
        CAST(strftime('%m', datetime(NEW.transaction_date / 1000, 'unixepoch')) AS INTEGER), CAST(strftime('%d', datetime(NEW.transaction_date / 1000, 'unixepoch')) AS INTEGER),
        NEW.currency_uid, unixepoch() * 1000);

    -- Update statistic for Income
    UPDATE resource_statistic_daily set last_updated = unixepoch() * 1000, total_income = total_income + NEW.amount,
        total_fee_paid = total_fee_paid + NEW.fee_amount
    WHERE stat_year = CAST(strftime('%Y', datetime(NEW.transaction_date / 1000, 'unixepoch')) AS INTEGER) AND
        stat_month = CAST(strftime('%m', datetime(NEW.transaction_date / 1000, 'unixepoch')) AS INTEGER) AND
        stat_day = CAST(strftime('%d', datetime(NEW.transaction_date / 1000, 'unixepoch')) AS INTEGER) AND
        ((resource_type = 'account' AND resource_uid = NEW.account_uid) OR (resource_type = 'category' AND resource_uid = NEW.transaction_category_uid)) AND
        currency_uid = NEW.currency_uid AND NEW.transaction_type = 'income' AND NEW.not_include_to_report = 0;

    -- Update statistic for Expense
    UPDATE resource_statistic_daily set last_updated = unixepoch() * 1000, total_expense = total_expense + NEW.amount,
        total_fee_paid = total_fee_paid + NEW.fee_amount
    WHERE stat_year = CAST(strftime('%Y', datetime(NEW.transaction_date / 1000, 'unixepoch')) AS INTEGER) AND
        stat_month = CAST(strftime('%m', datetime(NEW.transaction_date / 1000, 'unixepoch')) AS INTEGER) AND
        stat_day = CAST(strftime('%d', datetime(NEW.transaction_date / 1000, 'unixepoch')) AS INTEGER) AND
        ((resource_type = 'account' AND resource_uid = NEW.account_uid) OR (resource_type = 'category' AND resource_uid = NEW.transaction_category_uid)) AND
        currency_uid = NEW.currency_uid AND NEW.transaction_type = 'expense' AND NEW.not_include_to_report = 0;

    -- Update statistic for Transfer
    UPDATE resource_statistic_daily set last_updated = unixepoch() * 1000, total_transfer_out = total_transfer_out + NEW.amount,
        total_fee_paid = total_fee_paid + CASE
                                            WHEN (NEW.fee_apply_to_from_account <> 0) THEN NEW.fee_amount
                                            ELSE 0
                                          END
    WHERE resource_type = 'account' AND stat_year = CAST(strftime('%Y', datetime(NEW.transaction_date / 1000, 'unixepoch')) AS INTEGER) AND
        stat_month = CAST(strftime('%m', datetime(NEW.transaction_date / 1000, 'unixepoch')) AS INTEGER) AND
        stat_day = CAST(strftime('%d', datetime(NEW.transaction_date / 1000, 'unixepoch')) AS INTEGER) AND
        currency_uid = NEW.currency_uid AND resource_type = 'account' AND
        NEW.transaction_type = 'transfer' AND resource_uid = NEW.account_uid AND NEW.not_include_to_report = 0;

    UPDATE resource_statistic_daily set last_updated = unixepoch() * 1000, total_transfer_in = total_transfer_in + NEW.amount,
        total_fee_paid = total_fee_paid + CASE
                                            WHEN (NEW.fee_apply_to_from_account = 0) THEN NEW.fee_amount
                                            ELSE 0
                                          END
    WHERE resource_type = 'account' AND stat_year = CAST(strftime('%Y', datetime(NEW.transaction_date / 1000, 'unixepoch')) AS INTEGER) AND
        stat_month = CAST(strftime('%m', datetime(NEW.transaction_date / 1000, 'unixepoch')) AS INTEGER) AND
        stat_day = CAST(strftime('%d', datetime(NEW.transaction_date / 1000, 'unixepoch')) AS INTEGER) AND
        currency_uid = NEW.currency_uid AND resource_type = 'account' AND
        NEW.transaction_type = 'transfer' AND resource_uid = NEW.to_account_uid AND NEW.not_include_to_report = 0;

    UPDATE resource_statistic_daily set last_updated = unixepoch() * 1000, total_transfer = total_transfer + NEW.amount,
        total_fee_paid = total_fee_paid + NEW.fee_amount
    WHERE resource_type = 'category' AND stat_year = CAST(strftime('%Y', datetime(NEW.transaction_date / 1000, 'unixepoch')) AS INTEGER) AND
        stat_month = CAST(strftime('%m', datetime(NEW.transaction_date / 1000, 'unixepoch')) AS INTEGER) AND
        stat_day = CAST(strftime('%d', datetime(NEW.transaction_date / 1000, 'unixepoch')) AS INTEGER) AND NEW.transaction_type = 'transfer' AND
        resource_uid = NEW.transaction_category_uid AND
        currency_uid = NEW.currency_uid AND NEW.not_include_to_report = 0;

    -- Update statistic for Shared bill paid
    UPDATE resource_statistic_daily set last_updated = unixepoch() * 1000, total_expense = total_expense + NEW.my_split,
        total_fee_paid = total_fee_paid + NEW.fee_amount
    WHERE stat_year = CAST(strftime('%Y', datetime(NEW.transaction_date / 1000, 'unixepoch')) AS INTEGER) AND
        stat_month = CAST(strftime('%m', datetime(NEW.transaction_date / 1000, 'unixepoch')) AS INTEGER) AND
        stat_day = CAST(strftime('%d', datetime(NEW.transaction_date / 1000, 'unixepoch')) AS INTEGER) AND
        ((resource_type = 'account' AND resource_uid = NEW.account_uid) OR (resource_type = 'category' AND resource_uid = NEW.transaction_category_uid)) AND
        currency_uid = NEW.currency_uid AND NEW.transaction_type = 'shareBill' AND NEW.not_include_to_report = 0;

    -- Update statistic for Shared bill return
    UPDATE resource_statistic_daily set last_updated = unixepoch() * 1000,
        total_fee_paid = total_fee_paid - NEW.fee_amount
    WHERE stat_year = CAST(strftime('%Y', datetime(NEW.transaction_date / 1000, 'unixepoch')) AS INTEGER) AND
        stat_month = CAST(strftime('%m', datetime(NEW.transaction_date / 1000, 'unixepoch')) AS INTEGER) AND
        stat_day = CAST(strftime('%d', datetime(NEW.transaction_date / 1000, 'unixepoch')) AS INTEGER) AND
        ((resource_type = 'account' AND resource_uid = NEW.account_uid) OR (resource_type = 'category' AND resource_uid = NEW.transaction_category_uid)) AND
        currency_uid = NEW.currency_uid AND NEW.transaction_type = 'shareBillReturn' AND NEW.not_include_to_report = 0;
END;

CREATE TRIGGER transaction_year_month_update
AFTER UPDATE OF transaction_date ON transactions
FOR EACH ROW
BEGIN
    UPDATE transactions SET year_month =
        (CAST(strftime('%Y', datetime(NEW.transaction_date / 1000, 'unixepoch')) AS INTEGER) * 12) +
         CAST(strftime('%m', datetime(NEW.transaction_date / 1000, 'unixepoch')) AS INTEGER)
    WHERE id = NEW.id;

    -- Not support to update other attributes. For update we call delete and then insert.
    INSERT INTO debug_log (message) VALUES (
        'Update a transaction with ID: ' || NEW.id || ' and datetime ' || NEW.transaction_date || ' with year value ' || ((CAST(strftime('%Y', datetime(NEW.transaction_date / 1000, 'unixepoch')) AS INTEGER) * 12) +
         CAST(strftime('%m', datetime(NEW.transaction_date / 1000, 'unixepoch')) AS INTEGER))
    );
END;

CREATE TRIGGER transaction_deleted
AFTER DELETE ON transactions
FOR EACH ROW
BEGIN
    -- Income & transfer in & shared bill returned
    update asset set available_amount = available_amount - OLD.amount + OLD.fee_amount
      WHERE ((uid = OLD.account_uid and (OLD.transaction_type = 'income' or OLD.transaction_type = 'shareBillReturn')) or (uid = OLD.to_account_uid and OLD.transaction_type = 'transfer'))
      and asset_type <> 'loan';
    update asset set loan_amount = loan_amount + OLD.amount - OLD.fee_amount
      WHERE ((uid = OLD.account_uid and (OLD.transaction_type = 'income' or OLD.transaction_type = 'shareBillReturn')) or (uid = OLD.to_account_uid and OLD.transaction_type = 'transfer'))
      and asset_type = 'loan';

    -- Expense & transfer out & Shared bill paid
    update asset set available_amount = available_amount + OLD.amount + OLD.fee_amount
      WHERE uid = OLD.account_uid and (OLD.transaction_type = 'expense' or OLD.transaction_type = 'transfer' or OLD.transaction_type = 'shareBill') and asset_type <> 'loan';
    update asset set loan_amount = loan_amount - OLD.amount - OLD.fee_amount
      WHERE uid = OLD.account_uid and (OLD.transaction_type = 'expense' or OLD.transaction_type = 'transfer' or OLD.transaction_type = 'shareBill') and asset_type = 'loan';

    -- Adjustment
    update asset set available_amount = available_amount + OLD.adjusted_amount WHERE uid = OLD.account_uid and OLD.transaction_type = 'adjustment' and asset_type <> 'loan';
    update asset set loan_amount = loan_amount + OLD.adjusted_amount WHERE uid = OLD.account_uid and OLD.transaction_type = 'adjustment' and asset_type = 'loan';

    -- Update statistic for Income
    UPDATE resource_statistic_daily set last_updated = unixepoch() * 1000, total_income = total_income - OLD.amount, total_fee_paid = total_fee_paid - OLD.fee_amount
    WHERE stat_year = CAST(strftime('%Y', datetime(OLD.transaction_date / 1000, 'unixepoch')) AS INTEGER) AND
       stat_month = CAST(strftime('%m', datetime(OLD.transaction_date / 1000, 'unixepoch')) AS INTEGER) AND
       stat_day = CAST(strftime('%d', datetime(OLD.transaction_date / 1000, 'unixepoch')) AS INTEGER) AND
       ((resource_type = 'account' AND resource_uid = OLD.account_uid) OR (resource_type = 'category' AND resource_uid = OLD.transaction_category_uid)) AND
       currency_uid = OLD.currency_uid AND OLD.transaction_type = 'income' AND OLD.not_include_to_report = 0;

    -- Update statistic for Expense
    UPDATE resource_statistic_daily set last_updated = unixepoch() * 1000, total_expense = total_expense - OLD.amount, total_fee_paid = total_fee_paid - OLD.fee_amount
    WHERE stat_year = CAST(strftime('%Y', datetime(OLD.transaction_date / 1000, 'unixepoch')) AS INTEGER) AND
       stat_month = CAST(strftime('%m', datetime(OLD.transaction_date / 1000, 'unixepoch')) AS INTEGER) AND
       stat_day = CAST(strftime('%d', datetime(OLD.transaction_date / 1000, 'unixepoch')) AS INTEGER) AND
       ((resource_type = 'account' AND resource_uid = OLD.account_uid) OR (resource_type = 'category' AND resource_uid = OLD.transaction_category_uid)) AND
       currency_uid = OLD.currency_uid AND OLD.transaction_type = 'expense' AND OLD.not_include_to_report = 0;

    -- Update statistic for Transfer
    UPDATE resource_statistic_daily set last_updated = unixepoch() * 1000, total_transfer_out = total_transfer_out - OLD.amount,
       total_fee_paid = total_fee_paid - CASE
                                           WHEN (OLD.fee_apply_to_from_account <> 0) THEN OLD.fee_amount
                                           ELSE 0
                                         END
    WHERE resource_type = 'account' AND stat_year = CAST(strftime('%Y', datetime(OLD.transaction_date / 1000, 'unixepoch')) AS INTEGER) AND
       stat_month = CAST(strftime('%m', datetime(OLD.transaction_date / 1000, 'unixepoch')) AS INTEGER) AND
       stat_day = CAST(strftime('%d', datetime(OLD.transaction_date / 1000, 'unixepoch')) AS INTEGER) AND
       currency_uid = OLD.currency_uid AND OLD.transaction_type = 'transfer' AND resource_type = 'account' AND resource_uid = OLD.account_uid AND OLD.not_include_to_report = 0;

    UPDATE resource_statistic_daily set last_updated = unixepoch() * 1000, total_transfer_in = total_transfer_in - OLD.amount,
       total_fee_paid = total_fee_paid - CASE
                                           WHEN (OLD.fee_apply_to_from_account = 0) THEN OLD.fee_amount
                                           ELSE 0
                                         END
    WHERE resource_type = 'account' AND stat_year = CAST(strftime('%Y', datetime(OLD.transaction_date / 1000, 'unixepoch')) AS INTEGER) AND
       stat_month = CAST(strftime('%m', datetime(OLD.transaction_date / 1000, 'unixepoch')) AS INTEGER) AND
       stat_day = CAST(strftime('%d', datetime(OLD.transaction_date / 1000, 'unixepoch')) AS INTEGER) AND
       currency_uid = OLD.currency_uid AND OLD.transaction_type = 'transfer' AND resource_type = 'account' AND resource_uid = OLD.to_account_uid AND OLD.not_include_to_report = 0;

    UPDATE resource_statistic_daily set last_updated = unixepoch() * 1000, total_transfer = total_transfer - OLD.amount, total_fee_paid = total_fee_paid - OLD.fee_amount
    WHERE resource_type = 'category' AND stat_year = CAST(strftime('%Y', datetime(OLD.transaction_date / 1000, 'unixepoch')) AS INTEGER) AND
       stat_month = CAST(strftime('%m', datetime(OLD.transaction_date / 1000, 'unixepoch')) AS INTEGER) AND
       stat_day = CAST(strftime('%d', datetime(OLD.transaction_date / 1000, 'unixepoch')) AS INTEGER) AND OLD.transaction_type = 'transfer' AND
       resource_uid = NEW.transaction_category_uid AND
       currency_uid = OLD.currency_uid AND OLD.not_include_to_report = 0;

    -- Update statistic for Shared bill paid
    UPDATE resource_statistic_daily set last_updated = unixepoch() * 1000, total_expense = total_expense - OLD.my_split, total_fee_paid = total_fee_paid - OLD.fee_amount
    WHERE stat_year = CAST(strftime('%Y', datetime(OLD.transaction_date / 1000, 'unixepoch')) AS INTEGER) AND
       stat_month = CAST(strftime('%m', datetime(OLD.transaction_date / 1000, 'unixepoch')) AS INTEGER) AND
       stat_day = CAST(strftime('%d', datetime(OLD.transaction_date / 1000, 'unixepoch')) AS INTEGER) AND
       ((resource_type = 'account' AND resource_uid = OLD.account_uid) OR (resource_type = 'category' AND resource_uid = OLD.transaction_category_uid)) AND
       currency_uid = OLD.currency_uid AND OLD.transaction_type = 'shareBill' AND OLD.not_include_to_report = 0;

    -- Update statistic for Shared bill return
    UPDATE resource_statistic_daily set last_updated = unixepoch() * 1000, total_fee_paid = total_fee_paid + OLD.fee_amount
    WHERE stat_year = CAST(strftime('%Y', datetime(OLD.transaction_date / 1000, 'unixepoch')) AS INTEGER) AND
       stat_month = CAST(strftime('%m', datetime(OLD.transaction_date / 1000, 'unixepoch')) AS INTEGER) AND
       stat_day = CAST(strftime('%d', datetime(OLD.transaction_date / 1000, 'unixepoch')) AS INTEGER) AND
       ((resource_type = 'account' AND resource_uid = OLD.account_uid) OR (resource_type = 'category' AND resource_uid = OLD.transaction_category_uid)) AND
       currency_uid = OLD.currency_uid AND OLD.transaction_type = 'shareBillReturn' AND OLD.not_include_to_report = 0;

END;

CREATE TRIGGER resource_statistic_daily_after_update
AFTER UPDATE ON resource_statistic_daily
FOR EACH ROW
BEGIN
   INSERT INTO debug_log (message) VALUES ('Updated resource_statistic_daily("resource_type" = ' || NEW.resource_type || ', "resource_uid" = ' || NEW.resource_uid ||
       ', "stat_year" = ' || NEW.stat_year || ', "stat_month" = ' || NEW.stat_month || ', "stat_day" = ' || NEW.stat_day || ', "currency_uid" = ' || NEW.currency_uid ||
       ') with total_income += ' || (NEW.total_income - OLD.total_income) || ', total_expense += ' || (NEW.total_expense - OLD.total_expense) ||
       ', total_transfer_out += ' || (NEW.total_transfer_out - OLD.total_transfer_out) || ', total_transfer_in += ' || (NEW.total_transfer_in - OLD.total_transfer_in) ||
       ', total_transfer += ' || (NEW.total_transfer - OLD.total_transfer) || ', total_fee_paid += ' || (NEW.total_fee_paid - OLD.total_fee_paid) ||
       ', total_lend += ' || (NEW.total_lend - OLD.total_lend) || ', total_borrow += ' || (NEW.total_borrow - OLD.total_borrow));
END;

CREATE TRIGGER resource_statistic_daily_after_delete
AFTER DELETE ON resource_statistic_daily
FOR EACH ROW
BEGIN
    INSERT INTO debug_log (message) VALUES ('Deleted resource_statistic_daily resource_type =' || OLD.resource_type || ' AND resource_uid = ' || OLD.resource_uid || ' AND stat_year = ' ||
       OLD.stat_year || ' AND stat_month = ' || OLD.stat_month || ' AND stat_day = ' || OLD.stat_day);
END;

CREATE TRIGGER debug_log_after_insert
AFTER INSERT ON debug_log
FOR EACH ROW
BEGIN
   -- Only keep 1000 records and clean the old one.
   DELETE FROM debug_log WHERE id NOT IN ( SELECT id FROM debug_log ORDER BY id DESC LIMIT 500);
END;