sqlite3 ..\.dart_tool\sqflite_common_ffi\databases\main_database.db ".read ..\assets\db_init.sql"
sqlite3 ..\.dart_tool\sqflite_common_ffi\databases\main_database.db ".read ..\assets\db_create_triggers.sql"
sqlite3 ..\.dart_tool\sqflite_common_ffi\databases\main_database.db ".read 01.add-accounts.sql"
sqlite3 ..\.dart_tool\sqflite_common_ffi\databases\main_database.db ".read 02.add-expenses.sql"