INSERT OR IGNORE INTO transactions (id,description,transaction_date,transaction_time,transaction_category_uid,transaction_type,with_fee,fee_amount,amount,last_updated,account_uid,currency_uid,to_account_uid,my_split,remaining_amount,shared_bill_id) VALUES
	 ('20240925-0739-8a13-a146-3e0fbf0098d9','',1726851600000,1260,'20240818-1133-8506-a906-05c3ae338143','expense',0.0,0.0,200000.0,unixepoch() * 1000,'20240823-1529-8009-a864-e7b9299a07f6','1',NULL,0.0,0.0,NULL),
	 ('20240925-0806-8036-8285-94b151d8c60c','',1726851600000,1375,'20240925-0755-8557-9160-80ccca9d75f0','expense',0.0,0.0,177400.0,unixepoch() * 1000,'20240824-1557-8718-b097-5d9d1c51ff98','1',NULL,0.0,0.0,NULL);