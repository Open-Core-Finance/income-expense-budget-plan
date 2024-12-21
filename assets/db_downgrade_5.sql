CREATE TEMPORARY TABLE temp3 AS
SELECT id, description, transaction_date, transaction_time, transaction_category_uid, transaction_type, with_fee,
  fee_amount, amount, last_updated, account_uid, currency_uid, to_account_uid, my_split, remaining_amount,
  shared_bill_id, year_month, fee_apply_to_from_account, adjusted_amount, not_include_to_report, last_sync
FROM transactions;
DROP TABLE transactions;

CREATE TEMPORARY TABLE temp AS
    SELECT uid, icon, name, description, available_amount, loan_amount, credit_limit, payment_limit, currency_uid,
      asset_type, category_uid, localize_names,
      localize_descriptions, position_index, last_updated, last_sync FROM asset;
DROP TABLE asset;

CREATE TABLE IF NOT EXISTS asset(uid TEXT PRIMARY KEY, icon TEXT, name TEXT, description TEXT, available_amount REAL DEFAULT 0.0,
    loan_amount REAL DEFAULT 0.0, credit_limit REAL DEFAULT 0.0, payment_limit REAL DEFAULT 0.0, currency_uid TEXT,
    asset_type TEXT, category_uid TEXT, localize_names TEXT, localize_descriptions TEXT, position_index Integer DEFAULT 0 NOT NULL,
    last_updated Integer DEFAULT 0, last_sync Integer NULL, soft_deleted Integer NULL,
    FOREIGN KEY (category_uid) REFERENCES asset_category (uid), FOREIGN KEY (currency_uid) REFERENCES currency (uid));
INSERT INTO asset (uid, icon, name, description, available_amount, loan_amount, credit_limit, payment_limit,
  currency_uid, asset_type, category_uid, localize_names, localize_descriptions, position_index, last_updated, last_sync,
  soft_deleted) SELECT uid, icon, name, description, available_amount, loan_amount, credit_limit, payment_limit, currency_uid,
    asset_type, category_uid, localize_names, localize_descriptions, position_index, last_updated, last_sync, soft_deleted
  FROM temp;
DROP TABLE temp;

CREATE TABLE IF NOT EXISTS transactions(id TEXT PRIMARY KEY, description TEXT, transaction_date Integer DEFAULT 0, transaction_time Integer DEFAULT 0, transaction_category_uid TEXT, transaction_type TEXT,
    with_fee integer NOT NULL DEFAULT 0, fee_amount REAL NOT NULL DEFAULT 0.0, amount REAL NOT NULL DEFAULT 0.0, last_updated Integer NOT NULL DEFAULT 0, account_uid TEXT,
    currency_uid TEXT NOT NULL, to_account_uid TEXT, my_split REAL NOT NULL default 0.0, remaining_amount REAL NOT NULL default 0.0, shared_bill_id TEXT,
    year_month INTEGER NOT NULL DEFAULT 22800, fee_apply_to_from_account INTEGER NOT NULL DEFAULT 0, adjusted_amount REAL NOT NULL default 0.0,
    not_include_to_report Integer DEFAULT 0, last_sync Integer NULL,
    FOREIGN KEY (transaction_category_uid) REFERENCES transaction_category (uid),
    FOREIGN KEY (account_uid) REFERENCES asset (uid),
    FOREIGN KEY (currency_uid) REFERENCES currency (uid));
INSERT INTO transactions (id, description, transaction_date, transaction_time, transaction_category_uid, transaction_type,
  with_fee, fee_amount, amount, last_updated, account_uid, currency_uid, to_account_uid, my_split, remaining_amount,
  shared_bill_id, year_month, fee_apply_to_from_account, adjusted_amount, not_include_to_report, last_sync)
  SELECT id, description, transaction_date, transaction_time, transaction_category_uid, transaction_type,
      with_fee, fee_amount, amount, last_updated, account_uid, currency_uid, to_account_uid, my_split, remaining_amount,
      shared_bill_id, year_month, fee_apply_to_from_account, adjusted_amount,
      not_include_to_report, last_sync FROM temp3;
DROP TABLE temp3;
