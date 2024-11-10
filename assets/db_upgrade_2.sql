ALTER TABLE currency ADD COLUMN last_sync Integer NULL;
ALTER TABLE asset_category ADD COLUMN last_sync Integer NULL;
ALTER TABLE asset ADD COLUMN last_sync Integer NULL;
ALTER TABLE transaction_category ADD COLUMN last_sync Integer NULL;
ALTER TABLE transactions ADD COLUMN last_sync Integer NULL;