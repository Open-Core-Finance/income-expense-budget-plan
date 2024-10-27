INSERT OR IGNORE INTO transactions (id,description,transaction_date,transaction_time,transaction_category_uid,transaction_type,with_fee,fee_amount,amount,last_updated,account_uid,
    currency_uid,to_account_uid,my_split,remaining_amount,shared_bill_id,fee_apply_to_from_account,adjusted_amount,not_include_to_report) VALUES
('2024092705','', 1727395200000,300,'20240818-0942-8e52-9433-76bb751e54b1','shareBill',0, 0,100000,unixepoch() * 1000,'20240823-1529-8009-a864-e7b9299a07f6','1',NULL,50000,0,NULL,1,0,0),
('2024100112','', 1727740800000,720,'20240818-0942-8b07-b193-83fea7f607da','shareBill',0, 0,242000,unixepoch() * 1000,'20240823-1529-8009-a864-e7b9299a07f6','1',NULL,50000,0,NULL,1,0,0),
('2024100113','', 1727740800000,780,'20240818-0940-8043-b324-6067248730d1','shareBill',0, 0,150000,unixepoch() * 1000,'20240823-1529-8009-a864-e7b9299a07f6','1',NULL,16000,0,NULL,1,0,0),
('2024100223','', 1727827200000,1410,'20240818-0942-8b07-b193-83fea7f607da','shareBill',0, 0,375000,unixepoch() * 1000,'20240823-1529-8009-a864-e7b9299a07f6','1',NULL,76000,0,NULL,1,0,0),
('2024100713','', 1728259200000,780,'20240818-0942-8b07-b193-83fea7f607da','shareBill',0, 0,508000,unixepoch() * 1000,'20240823-1529-8009-a864-e7b9299a07f6','1',NULL,73000,0,NULL,1,0,0),
('2024100813','Shared Desc 2', 1728345600000,780,'20240818-0942-8b07-b193-83fea7f607da','shareBill',0, 0,192000,unixepoch() * 1000,'20240823-1529-8009-a864-e7b9299a07f6','1',NULL,64000,0,NULL,1,0,0),
('2024100815','Shared Desc 1', 1728345600000,900,'20240818-0940-8043-b324-6067248730d1','shareBill',0, 0,45000,unixepoch() * 1000,'20240823-1529-8009-a864-e7b9299a07f6','1',NULL,15000,0,NULL,1,0,0),
('2024102112','', 1729468800000,750,'20240818-0942-8b07-b193-83fea7f607da','shareBill',0, 0,452000,unixepoch() * 1000,'20240923-1601-8716-a430-c762e2b118f8','1',NULL,66000,0,NULL,1,0,0),
('2024102212','', 1729555200000,720,'20240818-0942-8b07-b193-83fea7f607da','shareBill',0, 0,195000,unixepoch() * 1000,'20240823-1529-8009-a864-e7b9299a07f6','1',NULL,40000,0,NULL,1,0,0);