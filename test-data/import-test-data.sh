sqlFile=~/Library/Containers/com.example.incomeExpenseBudgetPlan/Data/.dart_tool/sqflite_common_ffi/databases/main_database.db

sqlite3 "${sqlFile}" ".read ../assets/db_init.sql"
sqlite3 "${sqlFile}" ".read ../assets/db_create_triggers.sql"
sqlite3 "${sqlFile}" ".read 01.add-accounts.sql"
sqlite3 "${sqlFile}" ".read 02.add-expenses.sql"
sqlite3 "${sqlFile}" ".read 03.add-incomes.sql"
sqlite3 "${sqlFile}" ".read 04.add-transfers.sql"
sqlite3 "${sqlFile}" ".read 05.add-shared-bills.sql"
sqlite3 "${sqlFile}" ".read 06.add-bills-return.sql"