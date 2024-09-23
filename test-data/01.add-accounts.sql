INSERT OR IGNORE INTO setting (id,locale,dark_mode,default_currency_uid,last_transaction_account_uid) VALUES
	 (1,'vi',0,'1',NULL);

UPDATE asset SET currency_uid='1', last_updated = unixepoch() * 1000, available_amount = 19223000 WHERE uid='20240823-1529-8009-a864-e7b9299a07f6' and currency_uid='3';

UPDATE asset SET currency_uid='1', last_updated = unixepoch() * 1000, name = 'KBank Cashback', description = 'KBank Credit Card Platinum Cashback',
   localize_names= '', localize_descriptions = '', available_amount = 6239535, credit_limit = 199561111 WHERE uid='20240824-1557-8718-b097-5d9d1c51ff98' and currency_uid='3';

UPDATE asset SET last_updated = unixepoch() * 1000, name = 'ACB Point', description = 'ACB Loyalty Point',
   localize_names= '{"en":"ACB Point","vi":"Điểm thưởng ACB"}', localize_descriptions = '{"en":"ACB Loyalty Points","vi":"Điểm thưởng ACB của tôi"}',
   available_amount = 9880 WHERE uid='20240923-1658-8307-9686-bc5528febb04';

INSERT OR IGNORE INTO asset(uid,icon,name,description,available_amount,loan_amount,deposit_amount,credit_limit, payment_limit,currency_uid,asset_type,category_uid,localize_names,
   localize_descriptions,position_index,last_updated) VALUES ('20240923-1551-8745-a167-ef1ab27a221c',
   '{"codePoint":62999,"fontFamily":"CupertinoIcons","fontPackage":"cupertino_icons","matchTextDirection":false}','UOB Cashback','UOB Cashback Credit Card',
   300000000,0.0,0.0,300000000,0.0,'1','creditCard','20240814-1025-8e05-9011-a6fed676958f','{}','{}',2,1727106705186);

INSERT OR IGNORE INTO asset(uid,icon,name,description,available_amount,loan_amount,deposit_amount,credit_limit, payment_limit,currency_uid,asset_type,category_uid,localize_names,
   localize_descriptions,position_index,last_updated) VALUES ('20240923-1554-8b47-9102-55c61f9ea489',
   '{"codePoint":57408,"fontFamily":"MaterialIcons","fontPackage":null,"matchTextDirection":false}','Vietinbank','Vietinbank CASA Account',
   25.0,0.0,0.0,0.0,0.0,'1','bankCasa','20240814-1016-8412-a943-a2e9d6ba37c9','{}','{}',3,1727106887103);

INSERT OR IGNORE INTO asset(uid,icon,name,description,available_amount,loan_amount,deposit_amount,credit_limit, payment_limit,currency_uid,asset_type,category_uid,localize_names,
   localize_descriptions,position_index,last_updated) VALUES ('20240923-1557-8406-9654-c89ac03d5d48',
   '{"codePoint":57547,"fontFamily":"MaterialIcons","fontPackage":null,"matchTextDirection":false}','Techcombank','Techcombank CASA Account',
   25028720,0.0,0.0,0.0,0.0,'1','bankCasa','20240814-1016-8412-a943-a2e9d6ba37c9','{}','{}',4,1727107026654);

INSERT OR IGNORE INTO asset(uid,icon,name,description,available_amount,loan_amount,deposit_amount,credit_limit, payment_limit,currency_uid,asset_type,category_uid,localize_names,
   localize_descriptions,position_index,last_updated) VALUES ('20240923-1559-8209-b117-207b9fb61dd4',
   '{"codePoint":57409,"fontFamily":"MaterialIcons","fontPackage":null,"matchTextDirection":false}','ACB','ACB CASA Account',
   1393.0,0.0,0.0,0.0,0.0,'1','bankCasa','20240814-1016-8412-a943-a2e9d6ba37c9','{}','{}',5,1727107161432);

INSERT OR IGNORE INTO asset(uid,icon,name,description,available_amount,loan_amount,deposit_amount,credit_limit, payment_limit,currency_uid,asset_type,category_uid,localize_names,
  localize_descriptions,position_index,last_updated) VALUES ('20240923-1601-8716-a430-c762e2b118f8',
  '{"codePoint":57547,"fontFamily":"MaterialIcons","fontPackage":null,"matchTextDirection":false}','K+ Account','KBank mobile account',
  3986132.0,0.0,0.0,0.0,0.0,'1','bankCasa','20240814-1016-8412-a943-a2e9d6ba37c9','{}','{}',6,1727107276430);

INSERT OR IGNORE INTO asset(uid,icon,name,description,available_amount,loan_amount,deposit_amount,credit_limit, payment_limit,currency_uid,asset_type,category_uid,localize_names,
  localize_descriptions,position_index,last_updated) VALUES ('20240923-1602-8d34-a574-010bb7471a82',
  '{"codePoint":57408,"fontFamily":"MaterialIcons","fontPackage":null,"matchTextDirection":false}','Vietcombank','Vietcombank CASA Account',
  21455347,0.0,0.0,0.0,0.0,'1','bankCasa','20240814-1016-8412-a943-a2e9d6ba37c9','{}','{}',7,1727107354574);

INSERT OR IGNORE INTO asset(uid,icon,name,description,available_amount,loan_amount,deposit_amount,credit_limit,payment_limit,currency_uid,asset_type,category_uid,localize_names,
    localize_descriptions,position_index,last_updated) VALUES ('20240923-1613-8e14-b775-7416222fe76b',
    '{"codePoint":63723,"fontFamily":"CupertinoIcons","fontPackage":"cupertino_icons","matchTextDirection":false}','Techcombank MyCash','Tài khoản trả trước Techcombank MyCash',
    0.0,0.0,0.0,0.0,0.0,'1','payLaterAccount','20240814-1027-8317-9580-ef12a94c7312','{}','{}',8,1727107994775);

INSERT OR IGNORE INTO asset(uid,icon,name,description,available_amount,loan_amount,deposit_amount,credit_limit,payment_limit,currency_uid,asset_type,category_uid,localize_names,
    localize_descriptions,position_index,last_updated) VALUES ('20240923-1630-8b52-a380-8e7dc5aef337',
    '{"codePoint":63723,"fontFamily":"CupertinoIcons","fontPackage":"cupertino_icons","matchTextDirection":false}','Momo','Momo e-wallet',
    499598.0,0.0,0.0,0.0,0.0,'1','eWallet','20240823-0515-8322-8813-46af221b06bc','{}','{}',9,1727109068287);

INSERT OR IGNORE INTO asset (uid,icon,name,description,available_amount,loan_amount,deposit_amount,credit_limit,payment_limit,currency_uid,asset_type,category_uid,localize_names,
    localize_descriptions,position_index,last_updated) VALUES ('20240923-1632-8f38-b935-25a461ea4a1e',
    '{"codePoint":58778,"fontFamily":"MaterialIcons","fontPackage":null,"matchTextDirection":false}','ZaloPay','ZaloPay E-Wallet',
    0.0,0.0,0.0,0.0,0.0,'1','eWallet','20240823-0515-8322-8813-46af221b06bc','{}','{}',10,1727109181232);

INSERT OR IGNORE INTO asset (uid,icon,name,description,available_amount,loan_amount,deposit_amount,credit_limit,payment_limit,currency_uid,asset_type,category_uid,localize_names,
    localize_descriptions,position_index,last_updated) VALUES ('20240923-1644-8a38-8576-f042f8feb0e6',
    '{"codePoint":57409,"fontFamily":"MaterialIcons","fontPackage":null,"matchTextDirection":false}','Viettel Money','Viettel Money E-Wallet',
    6933.0,0.0,0.0,0.0,0.0,'1','eWallet','20240823-0515-8322-8813-46af221b06bc','{}','{}',11,1727109878586);

INSERT OR IGNORE INTO asset (uid,icon,name,description,available_amount,loan_amount,deposit_amount,credit_limit,payment_limit,currency_uid,asset_type,category_uid,localize_names,
    localize_descriptions,position_index,last_updated) VALUES ('20240923-1648-8226-8047-80d5e424608e',
    '{"codePoint":57421,"fontFamily":"MaterialIcons","fontPackage":null,"matchTextDirection":false}','Viettel Tiền di động','Viettel Tiền di động',
    679.0,0.0,0.0,0.0,0.0,'1','cash','20240814-1027-8317-9580-ef12a94c7312','{}','{}',12,1727110119488);

INSERT OR IGNORE INTO asset (uid,icon,name,description,available_amount,loan_amount,deposit_amount,credit_limit,payment_limit,currency_uid,asset_type,category_uid,localize_names,
    localize_descriptions,position_index,last_updated) VALUES ('20240923-1649-8043-a311-4fe253850fb6',
    '{"codePoint":58498,"fontFamily":"MaterialIcons","fontPackage":null,"matchTextDirection":false}','Shopee Pay','Shopee Pay E-Wallet',
    0.0,0.0,0.0,0.0,0.0,'1','eWallet','20240823-0515-8322-8813-46af221b06bc','{}','{}',13,1727110183311);

INSERT OR IGNORE INTO asset (uid,icon,name,description,available_amount,loan_amount,deposit_amount,credit_limit,payment_limit,currency_uid,asset_type,category_uid,localize_names,
    localize_descriptions,position_index,last_updated) VALUES ('20240923-1651-8e18-8983-a0bf3f786ced',
    '{"codePoint":59113,"fontFamily":"MaterialIcons","fontPackage":null,"matchTextDirection":false}','Viettel','Viettel telecome account',
    185933.0,0.0,0.0,0.0,0.0,'1','cash','20240814-1027-8317-9580-ef12a94c7312','{}','{}',14,1727110300816);

INSERT OR IGNORE INTO asset (uid,icon,name,description,available_amount,loan_amount,deposit_amount,credit_limit,payment_limit,currency_uid,asset_type,category_uid,localize_names,
    localize_descriptions,position_index,last_updated) VALUES ('20240923-1706-8b25-8280-6e29ddb6238b',
    '{"codePoint":57408,"fontFamily":"MaterialIcons","fontPackage":null,"matchTextDirection":false}','City cashback','City cashback money',
    62919.0,0.0,0.0,0.0,0.0,'1','cash','20240814-1027-8317-9580-ef12a94c7312','{"en":"City cashback","vi":"City cashback"}',
    '{"en":"City cashback money","vi":"Tiền City bank cashback"}',16,1727111185293);

INSERT INTO asset (uid,icon,name,description,available_amount,loan_amount,deposit_amount,credit_limit,payment_limit,currency_uid,asset_type,category_uid,localize_names,
    localize_descriptions,position_index,last_updated) VALUES ('20240923-1707-8544-a439-185350d8af92',
    '{"codePoint":58348,"fontFamily":"MaterialIcons","fontPackage":null,"matchTextDirection":false}','Viettel++','Viettel++',
    8485.0,0.0,0.0,0.0,0.0,'1','cash','20240814-1027-8317-9580-ef12a94c7312','{}','{}',17,1727111272560);
