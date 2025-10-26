#!/usr/bin/env python3
"""
Safely renumber users.user_id to a contiguous sequence starting at 1.

Warning: this script will alter primary keys and foreign keys. It drops and
recreates FK constraints referencing `users`. Make sure a backup exists.

Usage: run this from the `python_service` folder where the app's Config is
available or set DATABASE_URL env var. Example:
  set DATABASE_URL=postgresql://postgres:1234@localhost:5432/truthliesdetector
  python migrate_renumber_users.py

It will:
  - find FK constraints referencing users
  - drop those FK constraints
  - create a new users_new table with user_id = row_number() over order by user_id
  - update all child tables to point to the new user ids (matched by account)
  - drop the old users table and rename users_new to users
  - recreate FK constraints and a sequence for users.user_id

This script assumes `account` is unique on `users` (as in your models).
"""
import os
import sys
import psycopg2
from psycopg2 import sql


def get_database_url():
    # Prefer environment variable, fallback to config default
    url = os.environ.get('DATABASE_URL')
    if url:
        return url
    # try to import config from project
    try:
        sys.path.insert(0, os.path.abspath(os.path.dirname(__file__)))
        from config import Config
        return Config.SQLALCHEMY_DATABASE_URI
    except Exception:
        raise RuntimeError('DATABASE_URL not set and config import failed')


def split_regclass(name):
    # regclass text may be 'schema.table' or 'table'
    if '.' in name:
        schema, table = name.split('.', 1)
        return schema, table
    return None, name


def ident_from_regclass(name):
    schema, table = split_regclass(name)
    if schema:
        return sql.Identifier(schema, table)
    else:
        return sql.Identifier(name)


def main():
    dsn = get_database_url()
    print('Connecting to', dsn)
    conn = psycopg2.connect(dsn)
    conn.autocommit = False
    cur = conn.cursor()

    try:
        # 1) find FK constraints referencing users
        cur.execute("""
        SELECT con.oid, con.conname, con.conrelid::regclass::text as child_table,
               pg_get_constraintdef(con.oid) as constraint_def
        FROM pg_constraint con
        WHERE con.confrelid = 'users'::regclass AND con.contype = 'f'
        ORDER BY con.conname
        """)
        fks = cur.fetchall()
        print('Found FK constraints referencing users:')
        for oid, conname, child_table, constraint_def in fks:
            print(' -', conname, 'on', child_table, 'def=', constraint_def)

        # 2) Drop FK constraints (store definitions for recreation)
        for oid, conname, child_table, constraint_def in fks:
            print('Dropping', conname, 'on', child_table)
            # child_table may be schema.table
            schema, table = split_regclass(child_table)
            if schema:
                cur.execute(sql.SQL('ALTER TABLE {}.{} DROP CONSTRAINT {}')
                            .format(sql.Identifier(schema), sql.Identifier(table), sql.Identifier(conname)))
            else:
                cur.execute(sql.SQL('ALTER TABLE {} DROP CONSTRAINT {}')
                            .format(sql.Identifier(child_table), sql.Identifier(conname)))
        conn.commit()

        # 3) Create users_new with new contiguous ids (1..N) using account ordering by user_id
        print('Creating users_new with new ids (row_number over ORDER BY user_id)')
        cur.execute("""
        CREATE TABLE users_new AS
        SELECT ROW_NUMBER() OVER (ORDER BY user_id) AS user_id,
               account, username, password, email, phone
        FROM users
        ORDER BY user_id;
        """)
        cur.execute('ALTER TABLE users_new ADD PRIMARY KEY (user_id)')
        # preserve unique constraint on account if any
        cur.execute("SELECT count(*) FROM pg_indexes WHERE tablename='users' AND indexname LIKE 'users_account%'")
        # ensure commit to make users_new visible
        conn.commit()

        # 4) Update child tables to point to new ids using account as join key
        print('Updating child tables to reference new user ids')
        for oid, conname, child_table, constraint_def in fks:
            print('Updating', child_table)
            schema, table = split_regclass(child_table)
            if schema:
                child_ident = sql.Identifier(schema, table)
            else:
                child_ident = sql.Identifier(table)
            # Execute update: UPDATE child SET user_id = un.user_id FROM users u_old JOIN users_new un ON un.account = u_old.account WHERE child.user_id = u_old.user_id
            cur.execute(sql.SQL("""
            UPDATE {child} ct
            SET user_id = un.user_id
            FROM users u_old
            JOIN users_new un ON un.account = u_old.account
            WHERE ct.user_id = u_old.user_id
            """).format(child=child_ident))
        conn.commit()

        # 5) Drop old users table and rename users_new -> users
        print('Dropping old users table and renaming users_new to users')
        cur.execute('DROP TABLE users')
        cur.execute('ALTER TABLE users_new RENAME TO users')
        conn.commit()

        # 6) Recreate FK constraints using previously captured definitions
        print('Recreating FK constraints')
        for oid, conname, child_table, constraint_def in fks:
            print('Recreating', conname, 'on', child_table)
            schema, table = split_regclass(child_table)
            if schema:
                cur.execute(sql.SQL('ALTER TABLE {}.{} ADD CONSTRAINT {} {}')
                            .format(sql.Identifier(schema), sql.Identifier(table), sql.Identifier(conname), sql.SQL(constraint_def)))
            else:
                cur.execute(sql.SQL('ALTER TABLE {} ADD CONSTRAINT {} {}')
                            .format(sql.Identifier(table), sql.Identifier(conname), sql.SQL(constraint_def)))
        conn.commit()

        # 7) Create a sequence for users.user_id and set default
        print('Creating sequence for users.user_id and setting default')
        cur.execute('SELECT COALESCE(MAX(user_id),0) FROM users')
        maxid = cur.fetchone()[0]
        seqname = 'users_user_id_seq'
        cur.execute(sql.SQL("CREATE SEQUENCE IF NOT EXISTS {} START WITH %s").format(sql.Identifier(seqname)), [maxid + 1])
        cur.execute(sql.SQL("ALTER TABLE users ALTER COLUMN user_id SET DEFAULT nextval(%s)"), [seqname])
        cur.execute(sql.SQL("ALTER SEQUENCE {} OWNED BY users.user_id").format(sql.Identifier(seqname)))
        conn.commit()

        print('Migration completed successfully. New users ids should start at 1.')

    except Exception as e:
        print('Error during migration:', e)
        conn.rollback()
        raise
    finally:
        cur.close()
        conn.close()


if __name__ == '__main__':
    main()
