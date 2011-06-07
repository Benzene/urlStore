CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, username TEXT, hashed_pass TEXT, email TEXT);

CREATE TABLE IF NOT EXISTS urls (id INTEGER PRIMARY KEY, url TEXT, title TEXT, description TEXT, date INTEGER, category TEXT, read INTEGER, added_by TEXT);

CREATE TABLE IF NOT EXISTS categories (id INTEGER PRIMARY KEY, shortname TEXT, title TEXT, description TEXT, belongs_to TEXT);

