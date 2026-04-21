# -*- coding: utf-8 -*-
# بيانات تجريبية متوافقة مع كتالوج plant_model — من مجلد web: python seed_demo_data.py
import hashlib
import os
import random
import sys
from datetime import datetime, timedelta

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from app import init_db, get_db  # noqa: E402
from plant_model import PLANT_DATABASE, SAUDI_CITIES  # noqa: E402

DEMO_PW = 'DemoUser2026'
HOME_TYPES = ['شقة', 'فيلا', 'منزل', 'حديقة']


def _hash(pw):
    return hashlib.sha256(pw.encode()).hexdigest()


def main():
    init_db()
    random.seed(42)
    conn = get_db()
    cursor = conn.cursor()
    now = datetime.now()
    pw = _hash(DEMO_PW)
    n_cities = len(SAUDI_CITIES)
    n_cat = len(PLANT_DATABASE)

    demo_uids = []
    for i in range(1, 9):
        email = 'demo%d@demo.florabit.local' % i
        city = SAUDI_CITIES[(i - 1) % n_cities]
        home = HOME_TYPES[(i - 1) % len(HOME_TYPES)]
        cursor.execute('SELECT id FROM users WHERE lower(email)=?', (email.lower(),))
        r = cursor.fetchone()
        ts = now.strftime('%Y-%m-%d %H:%M:%S')
        if r:
            uid = r[0]
            cursor.execute(
                'UPDATE users SET city=?, home_type=?, updated_at=? WHERE id=?',
                (city, home, ts, uid),
            )
        else:
            cursor.execute(
                '''INSERT INTO users (name, email, password, city, home_type, created_at, updated_at, role, is_active)
                   VALUES (?, ?, ?, ?, ?, ?, ?, 'user', 1)''',
                ('مستخدم تجريبي %d' % i, email, pw, city, home, ts, ts),
            )
            uid = cursor.lastrowid
        demo_uids.append(uid)

    cursor.execute("SELECT id FROM users WHERE COALESCE(role,'user')='admin' ORDER BY id LIMIT 1")
    ar = cursor.fetchone()
    admin_id = ar[0] if ar else demo_uids[0]
    ts = now.strftime('%Y-%m-%d %H:%M:%S')
    if admin_id not in demo_uids:
        cursor.execute(
            'UPDATE users SET city=?, home_type=?, updated_at=? WHERE id=?',
            (SAUDI_CITIES[8 % n_cities], 'فيلا', ts, admin_id),
        )

    all_user_ids = list(dict.fromkeys(demo_uids + [admin_id]))

    cursor.execute(
        "DELETE FROM care_logs WHERE plant_id IN (SELECT id FROM plants WHERE notes LIKE '[demo]%')"
    )
    cursor.execute("DELETE FROM plants WHERE notes LIKE '[demo]%'")

    for j, uid in enumerate(all_user_ids):
        for k in range(4):
            idx = (j * 4 + k) % n_cat
            p = PLANT_DATABASE[idx]
            catalog_id = idx + 1
            w = int(p['watering'])
            f = int(p['fertilizing'])
            io = p.get('indoor_outdoor', 'داخلي')
            lw_days = min(w - 1, max(0, random.randint(0, w)))
            lf_days = min(f - 1, max(0, random.randint(0, min(f, 25))))
            lw = (now - timedelta(days=lw_days)).strftime('%Y-%m-%d %H:%M:%S')
            lf = (now - timedelta(days=lf_days)).strftime('%Y-%m-%d %H:%M:%S')
            ts = now.strftime('%Y-%m-%d %H:%M:%S')
            notes = '[demo] catalog_id=%d' % catalog_id
            cursor.execute(
                '''INSERT INTO plants (user_id, catalog_id, name, type, indoor_outdoor,
                   watering_interval_days, fertilizing_interval_days, last_watering_date, last_fertilizing_date,
                   notes, created_at, updated_at)
                   VALUES (?,?,?,?,?,?,?,?,?,?,?,?)''',
                (
                    uid, catalog_id, p['name'], p['type'], io, w, f, lw, lf, notes, ts, ts,
                ),
            )

    cursor.execute('SELECT id FROM plants')
    plant_ids = [x[0] for x in cursor.fetchall()]
    if not plant_ids:
        conn.commit()
        conn.close()
        print('لا نباتات')
        return

    cursor.execute('SELECT COUNT(*) FROM care_logs')
    log_n = cursor.fetchone()[0]
    need_logs = max(0, 130 - log_n)
    if need_logs > 0:
        actions = ['watering', 'fertilizing']
        for _ in range(need_logs):
            pid = random.choice(plant_ids)
            act = random.choice(actions)
            days_ago = random.randint(0, 18)
            dt = now - timedelta(days=days_ago, hours=random.randint(0, 10))
            ad = dt.strftime('%Y-%m-%d %H:%M:%S')
            notes = 'تسجيل تجريبي' if random.random() > 0.7 else ''
            cursor.execute(
                'INSERT INTO care_logs (plant_id, action_type, action_date, notes) VALUES (?,?,?,?)',
                (pid, act, ad, notes),
            )

    conn.commit()
    conn.close()
    print('تم: مستخدمون تجريبيون (مدن متنوعة)، نباتات مربوطة بالكتالوج (catalog_id)، سجلات عناية.')


if __name__ == '__main__':
    main()
