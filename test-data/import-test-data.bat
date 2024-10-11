set dataFile=..\.dart_tool\sqflite_common_ffi\databases\main_database.db
sqlite3 %dataFile% ".read ..\assets\db_init.sql"
sqlite3 %dataFile% ".read ..\assets\db_create_triggers.sql"
sqlite3 %dataFile% ".read 01.add-accounts.sql"
sqlite3 %dataFile% ".read 02.add-expenses.sql"
sqlite3 %dataFile% ".read 03.add-incomes.sql"
sqlite3 %dataFile% ".read 04.add-transfers.sql"
sqlite3 %dataFile% ".read 05.add-shared-bills.sql"
sqlite3 %dataFile% ".read 06.add-bills-return.sql"