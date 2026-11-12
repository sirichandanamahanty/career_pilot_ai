"""Database access for CareerPilot.

Every value that comes from a request is passed as a parameter.
SQL text is fixed in this project; it is never built by concatenating input.
"""

import os
from contextlib import contextmanager
from pathlib import Path

import mysql.connector
from dotenv import load_dotenv

ROOT = Path(__file__).resolve().parent
load_dotenv(ROOT / ".env")


def connection_settings(with_database=True):
    settings = {
        "host": os.getenv("DB_HOST", "localhost"),
        "user": os.getenv("DB_USER", "root"),
        "port": int(os.getenv("DB_PORT", "3306")),
        "password": os.getenv("DB_PASSWORD", ""),
        "autocommit": False,
    }
    if with_database:
        settings["database"] = os.getenv("DB_NAME", "careerpilot")
    return settings


def connect(with_database=True):
    return mysql.connector.connect(**connection_settings(with_database))


@contextmanager
def connection():
    conn = connect()
    try:
        yield conn
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


def fetch_all(sql, params=()):
    with connection() as conn:
        cursor = conn.cursor(dictionary=True)
        if params:
            cursor.execute(sql, params)
        else:
            cursor.execute(sql)
        return cursor.fetchall()


def fetch_one(sql, params=()):
    rows = fetch_all(sql, params)
    return rows[0] if rows else None


def execute(sql, params=()):
    with connection() as conn:
        cursor = conn.cursor()
        cursor.execute(sql, params)
        return cursor.lastrowid


def call_procedure(sql, params):
    """Run a CALL statement and drain any result sets it returns."""
    with connection() as conn:
        cursor = conn.cursor()
        cursor.execute(sql, params)
        while True:
            if cursor.with_rows:
                cursor.fetchall()
            if not cursor.nextset():
                break


def run_select(sql, params=()):
    with connection() as conn:
        cursor = conn.cursor(dictionary=True)
        if params:
            cursor.execute(sql, params)
        else:
            cursor.execute(sql)
        rows = cursor.fetchall()
        columns = [column[0] for column in cursor.description] if cursor.description else []
        return columns, rows
