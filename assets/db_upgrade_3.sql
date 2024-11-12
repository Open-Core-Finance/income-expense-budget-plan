DROP TABLE IF EXISTS debug_log;

CREATE TABLE IF NOT EXISTS debug_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    func_name TEXT,
    func_type int NOT NULL DEFAULT 0, -- 0 is trigger, 1 -- coding
    log_level int NOT NULL DEFAULT 0, -- 0 is debug, 1 is info, 2 is error
    message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);