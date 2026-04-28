# -*- coding: utf-8 -*-

import json
import sqlite3
from datetime import datetime


def create_catalog_tables(cursor):
    cursor.execute(
        '''
        CREATE TABLE IF NOT EXISTS cities (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            sort_order INTEGER NOT NULL DEFAULT 0
        )
        '''
    )
    cursor.execute(
        '''
        CREATE TABLE IF NOT EXISTS catalog_plants (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            type TEXT NOT NULL,
            indoor_outdoor TEXT,
            watering INTEGER NOT NULL,
            fertilizing INTEGER NOT NULL,
            light TEXT,
            colors_json TEXT NOT NULL,
            home_types_json TEXT NOT NULL
        )
        '''
    )
    cursor.execute(
        '''
        CREATE TABLE IF NOT EXISTS catalog_plant_cities (
            catalog_plant_id INTEGER NOT NULL,
            city_id INTEGER NOT NULL,
            PRIMARY KEY (catalog_plant_id, city_id),
            FOREIGN KEY (catalog_plant_id) REFERENCES catalog_plants(id) ON DELETE CASCADE,
            FOREIGN KEY (city_id) REFERENCES cities(id) ON DELETE CASCADE
        )
        '''
    )


def migrate_catalog_plant_columns(cursor):
    for col, typ in [
        ('name_en', 'TEXT'),
        ('scientific_name', 'TEXT'),
        ('description', 'TEXT'),
        ('care_level', 'TEXT'),
        ('created_at', 'TEXT'),
        ('updated_at', 'TEXT'),
    ]:
        try:
            cursor.execute(f'ALTER TABLE catalog_plants ADD COLUMN {col} {typ}')
        except sqlite3.OperationalError:
            pass


def migrate_after_plants_and_care_logs(cursor):
    cursor.execute(
        '''
        CREATE TABLE IF NOT EXISTS reminders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            plant_id INTEGER NOT NULL,
            reminder_type TEXT NOT NULL,
            due_date TEXT NOT NULL,
            is_sent INTEGER NOT NULL DEFAULT 0,
            notes TEXT,
            created_at TEXT,
            updated_at TEXT,
            FOREIGN KEY (plant_id) REFERENCES plants(id) ON DELETE CASCADE
        )
        '''
    )
    for col, typ in [('created_at', 'TEXT'), ('updated_at', 'TEXT')]:
        try:
            cursor.execute(f'ALTER TABLE care_logs ADD COLUMN {col} {typ}')
        except sqlite3.OperationalError:
            pass
    try:
        cursor.execute(
            'CREATE UNIQUE INDEX IF NOT EXISTS idx_plants_user_name_unique ON plants(user_id, name)'
        )
    except sqlite3.OperationalError:
        pass
    try:
        cursor.execute('DROP VIEW IF EXISTS plant_catalog')
        cursor.execute(
            '''
            CREATE VIEW plant_catalog AS
            SELECT
                id,
                name AS name_ar,
                name_en,
                scientific_name,
                type,
                watering AS watering_days,
                fertilizing AS fertilizing_days,
                light AS light_requirement,
                care_level,
                description,
                indoor_outdoor,
                colors_json,
                home_types_json,
                created_at,
                updated_at
            FROM catalog_plants
            '''
        )
    except sqlite3.OperationalError:
        pass


def seed_cities_and_catalog_if_empty(conn):
    from plant_model import PLANT_DATABASE, SAUDI_CITIES, _care_level_for_plant

    cursor = conn.cursor()
    cursor.execute('SELECT COUNT(*) FROM catalog_plants')
    if cursor.fetchone()[0] > 0:
        return

    for i, name in enumerate(SAUDI_CITIES):
        cursor.execute(
            'INSERT OR IGNORE INTO cities (name, sort_order) VALUES (?, ?)',
            (name, i),
        )
    conn.commit()

    cursor.execute('SELECT id, name FROM cities')
    city_map = {row[1]: row[0] for row in cursor.fetchall()}

    for p in PLANT_DATABASE:
        cursor.execute(
            '''INSERT INTO catalog_plants (name, type, indoor_outdoor, watering, fertilizing, light, colors_json, home_types_json)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?)''',
            (
                p['name'],
                p['type'],
                p.get('indoor_outdoor'),
                int(p['watering']),
                int(p['fertilizing']),
                p.get('light') or '',
                json.dumps(p['colors'], ensure_ascii=False),
                json.dumps(p.get('home_types', []), ensure_ascii=False),
            ),
        )
        pid = cursor.lastrowid
        for cn in p.get('cities') or []:
            cid = city_map.get(cn)
            if cid:
                cursor.execute(
                    'INSERT OR IGNORE INTO catalog_plant_cities (catalog_plant_id, city_id) VALUES (?, ?)',
                    (pid, cid),
                )
        ts = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        cl = _care_level_for_plant(p)
        cursor.execute(
            '''UPDATE catalog_plants SET care_level = ?, created_at = ?, updated_at = ? WHERE id = ?''',
            (cl, ts, ts, pid),
        )
    conn.commit()


def migrate_users_city_id(conn):
    # يربط users.city النصي بـ city_id عند وجود تطابق اسم.
    try:
        cursor = conn.cursor()
        cursor.execute('PRAGMA table_info(users)')
        cols = {row[1] for row in cursor.fetchall()}
        if 'city_id' not in cols:
            return
        cursor.execute(
            '''
            SELECT u.id, u.city FROM users u
            WHERE u.city IS NOT NULL AND trim(u.city) != ''
              AND (u.city_id IS NULL)
            '''
        )
        for uid, cname in cursor.fetchall():
            cursor.execute(
                'SELECT id FROM cities WHERE name = ?',
                (cname.strip(),),
            )
            r = cursor.fetchone()
            if r:
                cursor.execute(
                    'UPDATE users SET city_id = ? WHERE id = ?',
                    (r[0], uid),
                )
        conn.commit()
    except sqlite3.OperationalError:
        pass


def resolve_city_id(cursor, city_name):
    if not city_name or not str(city_name).strip():
        return None
    cursor.execute(
        'SELECT id FROM cities WHERE name = ?',
        (str(city_name).strip(),),
    )
    r = cursor.fetchone()
    return r[0] if r else None


def backfill_catalog_plant_fields(conn):
    # يملأ care_level والطوابع لصفوف كتالوج قديمة بعد إضافة الأعمدة.
    try:
        from plant_model import PLANT_DATABASE, _care_level_for_plant

        cursor = conn.cursor()
        cursor.execute('PRAGMA table_info(catalog_plants)')
        if 'care_level' not in {r[1] for r in cursor.fetchall()}:
            return
        ts = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        for p in PLANT_DATABASE:
            cursor.execute('SELECT id FROM catalog_plants WHERE name = ?', (p['name'],))
            row = cursor.fetchone()
            if not row:
                continue
            pid = row[0]
            cl = _care_level_for_plant(p)
            cursor.execute(
                '''UPDATE catalog_plants SET
                    care_level = COALESCE(care_level, ?),
                    created_at = COALESCE(created_at, ?),
                    updated_at = COALESCE(updated_at, ?)
                   WHERE id = ?''',
                (cl, ts, ts, pid),
            )
        conn.commit()
    except Exception:
        pass
