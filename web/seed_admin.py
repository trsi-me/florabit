# -*- coding: utf-8 -*-
# seed: من مجلد web — python seed_admin.py
import hashlib
import os
import sys
from datetime import datetime

# يضمن إنشاء الجداول
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from app import init_db, get_db  # noqa: E402

ADMIN_EMAIL = 'admin@florabit.local'
ADMIN_PASSWORD = 'FlorabitAdmin2026'
ADMIN_NAME = 'مسؤول النظام'


def main():
    init_db()
    pw_hash = hashlib.sha256(ADMIN_PASSWORD.encode()).hexdigest()
    now = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute('SELECT id FROM users WHERE lower(email) = ?', (ADMIN_EMAIL.lower(),))
    row = cursor.fetchone()
    if row:
        uid = row[0]
        cursor.execute(
            '''UPDATE users SET name = ?, password = ?, role = 'admin', is_active = 1,
               updated_at = ?, suspended_until = NULL WHERE id = ?''',
            (ADMIN_NAME, pw_hash, now, uid),
        )
        print('تم تحديث المسؤول الموجود id=%s' % uid)
    else:
        cursor.execute(
            '''INSERT INTO users (name, email, password, city, home_type, created_at, updated_at, role, is_active)
               VALUES (?, ?, ?, '', '', ?, ?, 'admin', 1)''',
            (ADMIN_NAME, ADMIN_EMAIL, pw_hash, now, now),
        )
        print('تم إنشاء مسؤول جديد id=%s' % cursor.lastrowid)
    conn.commit()
    conn.close()
    print('البريد:', ADMIN_EMAIL)
    print('كلمة المرور:', ADMIN_PASSWORD)


if __name__ == '__main__':
    main()
