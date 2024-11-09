INSERT OR IGNORE INTO transactions (id,description,transaction_date,transaction_time,transaction_category_uid,transaction_type,with_fee,fee_amount,amount,last_updated,account_uid,
    currency_uid,to_account_uid,my_split,remaining_amount,shared_bill_id,fee_apply_to_from_account,adjusted_amount,not_include_to_report) VALUES
('ff8e9a11-b87a-4311-a7fc-f72559d67d7f','Desc 1', 1727395200000,900, NULL,'transfer',0, 0,10000000,unixepoch() * 1000,'20240923-1601-8716-a430-c762e2b118f8','1','20240923-1557-8406-9654-c89ac03d5d48',0,0,NULL,0,0,0),
('1583d3d3-16a3-4318-a7b5-e1efbc06faa6','Desc 2', 1728172800000,920, NULL,'transfer',0, 0,6489099,unixepoch() * 1000,'20240923-1601-8716-a430-c762e2b118f8','1','20240824-1557-8718-b097-5d9d1c51ff98',0,0,NULL,0,0,0),
('c0fbcb14-1198-4267-bef3-f24799116bbf','', 1728259200000,820, NULL,'transfer',0, 0,1000000,unixepoch() * 1000,'20240823-1529-8009-a864-e7b9299a07f6','1','20240923-1601-8716-a430-c762e2b118f8',0,0,NULL,0,0,0),
('c800133a-c47e-4216-be1f-8b1192e74f9a','', 1728950400000,750,NULL,'transfer',0, 0,500000,unixepoch() * 1000,'20240823-1529-8009-a864-e7b9299a07f6','1','20240923-1601-8716-a430-c762e2b118f8',0,0,NULL,0,0,0),
('0ec72d0f-1cea-4e8f-8c51-9bd05c3a88ab','', 1729382400000,540,NULL,'transfer',1,1100,2000000,unixepoch() * 1000,'20240923-1602-8d34-a574-010bb7471a82','1','20240823-1529-8009-a864-e7b9299a07f6',0,0,NULL,1,0,0);

INSERT OR IGNORE INTO transactions (id,description,transaction_date,transaction_time,transaction_category_uid,transaction_type,with_fee,fee_amount,amount,last_updated,account_uid,
    currency_uid,to_account_uid,my_split,remaining_amount,shared_bill_id,fee_apply_to_from_account,adjusted_amount,not_include_to_report) VALUES
('64191238-c828-4461-9d47-62b84f18caab','', 1730160000000,1140,NULL,'transfer',0, 0,10000,unixepoch() * 1000,'20240923-1557-8406-9654-c89ac03d5d48','1','20240823-1529-8009-a864-e7b9299a07f6',0,0,NULL,0,0,0),
('28717ab4-f41b-4562-8fdd-d41558f4d0ec','', 1730851200000,445,NULL,'transfer',0, 0,4956648,unixepoch() * 1000,'20240923-1601-8716-a430-c762e2b118f8','1','20240824-1557-8718-b097-5d9d1c51ff98',0,0,NULL,0,0,0);