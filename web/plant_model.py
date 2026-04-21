# -*- coding: utf-8 -*-

import os
import json
from io import BytesIO
from datetime import datetime

try:
    from PIL import Image
    import numpy as np
    import joblib
except ImportError:
    Image = None
    np = None
    joblib = None

_BASE_DIR = os.path.dirname(os.path.abspath(__file__))
_MODEL_PATH = os.path.join(_BASE_DIR, 'models', 'plant_rf.joblib')
_NAMES_PATH = os.path.join(_BASE_DIR, 'models', 'class_names.json')
_MAP_PATH = os.path.join(_BASE_DIR, 'data', 'flower_class_map.json')
_ML_BUNDLE = None


def _extract_ml_features(image_bytes):
    if Image is None or np is None:
        return None
    img = Image.open(BytesIO(image_bytes)).convert('RGB').resize((128, 128))
    arr = np.asarray(img, dtype=np.float64) / 255.0
    feats = []
    for c in range(3):
        hist, _ = np.histogram(arr[:, :, c], bins=32, range=(0, 1))
        s = float(hist.sum()) + 1e-9
        feats.extend((hist / s).tolist())
    feats.append(float(np.mean(arr[:, :, 0])))
    feats.append(float(np.mean(arr[:, :, 1])))
    feats.append(float(np.mean(arr[:, :, 2])))
    feats.append(float(np.std(arr[:, :, 0])))
    feats.append(float(np.std(arr[:, :, 1])))
    feats.append(float(np.std(arr[:, :, 2])))
    return np.array(feats, dtype=np.float64).reshape(1, -1)


def _load_flower_map():
    if not os.path.isfile(_MAP_PATH):
        return {}
    with open(_MAP_PATH, 'r', encoding='utf-8') as f:
        return json.load(f)


def _load_ml():
    global _ML_BUNDLE
    if _ML_BUNDLE is not None:
        return _ML_BUNDLE
    if joblib is None or not os.path.isfile(_MODEL_PATH) or not os.path.isfile(_NAMES_PATH):
        _ML_BUNDLE = False
        return _ML_BUNDLE
    try:
        bundle = joblib.load(_MODEL_PATH)
        with open(_NAMES_PATH, 'r', encoding='utf-8') as f:
            class_names = json.load(f)
        _ML_BUNDLE = {'bundle': bundle, 'class_names': class_names}
    except OSError:
        _ML_BUNDLE = False
    return _ML_BUNDLE


def _identify_plant_ml(image_data):
    ml = _load_ml()
    if not ml or ml is False:
        return None
    feat = _extract_ml_features(image_data)
    if feat is None:
        return None
    expected = ml['bundle'].get('feature_dim')
    if expected is not None and feat.shape[1] != expected:
        return None
    clf = ml['bundle']['clf']
    names_en = ml['class_names']
    flower_map = _load_flower_map()
    probs = clf.predict_proba(feat)[0]
    order = np.argsort(probs)[::-1][:5]
    seen = set()
    out = []
    for idx in order:
        en = names_en[int(idx)]
        ar_name = flower_map.get(en, en)
        p = _find_plant_row(ar_name)
        if p is None:
            p = _find_plant_row('صبار')
        if p is None or p['name'] in seen:
            continue
        seen.add(p['name'])
        conf = float(min(0.99, max(0.05, probs[int(idx)])))
        out.append({
            'name': p['name'],
            'type': p['type'],
            'indoor_outdoor': p.get('indoor_outdoor', 'داخلي' if p['type'] == 'داخلي' else 'خارجي'),
            'confidence': round(conf, 2),
            'watering_interval_days': p['watering'],
            'fertilizing_interval_days': p['fertilizing'],
            'model_source': 'sklearn_rf_flower_photos',
        })
    return out if out else None

SAUDI_CITIES = [
    "جدة", "الرياض", "الدمام", "مكة", "المدينة", "الطائف", "أبها", "تبوك",
    "الخبر", "الخرج", "بريدة", "نجران", "جازان", "حائل", "الأحساء", "الجبيل",
    "ينبع", "القريات", "عرعر", "سكاكا", "الباحة", "خميس مشيط", "رابغ", "العلا",
    "الظهران", "القطيف", "الجوف", "الرس", "القصيم",
    "الدرعية", "بيشة", "سيهات", "المجمعة", "الخفج", "رجال ألمع",
]

CITY_REGIONS_META = [
    ("الساحل الغربي والحرمين", ["جدة", "مكة", "المدينة", "ينبع", "رابغ", "العلا"]),
    ("وسط وشمال المملكة", ["الرياض", "الخرج", "بريدة", "القصيم", "الرس", "حائل", "سكاكا", "عرعر", "القريات", "تبوك", "الجوف", "الدرعية", "المجمعة"]),
    ("الجنوب الغربي والجنوب", ["أبها", "خميس مشيط", "الباحة", "نجران", "جازان", "الطائف", "بيشة", "رجال ألمع"]),
    ("المنطقة الشرقية", ["الدمام", "الخبر", "الظهران", "الأحساء", "الجبيل", "القطيف", "سيهات", "الخفج"]),
]
HOME_TYPES = ["شقة", "فيلا", "منزل", "حديقة"]

CITIES_KSA_ALL = SAUDI_CITIES
CITIES_COAST_WEST = ["جدة", "ينبع", "رابغ", "مكة", "المدينة"]
CITIES_CENTRAL_NORTH = ["الرياض", "الخرج", "بريدة", "القصيم", "الرس", "حائل", "سكاكا", "عرعر", "القريات", "تبوك", "الجوف", "العلا"]
CITIES_SOUTH_WEST = ["أبها", "خميس مشيط", "الباحة", "نجران", "جازان", "الطائف"]
CITIES_LAVENDER_ZONE = list(dict.fromkeys(
    CITIES_CENTRAL_NORTH + CITIES_SOUTH_WEST + CITIES_COAST_WEST + ["الدمام", "الخبر", "الظهران", "الأحساء", "ينبع"]
))
CITIES_CYCLAMEN_COOL = list(dict.fromkeys(
    ["الرياض", "الطائف", "أبها", "تبوك", "حائل", "الباحة", "العلا", "مكة", "المدينة", "جدة", "الدمام", "الأحساء", "الخبر", "الظهران", "سكاكا", "خميس مشيط", "بريدة", "الخرج", "القصيم", "عرعر", "القريات"]
))
CITIES_SAGE_ZONE = list(dict.fromkeys(
    ["الرياض", "الطائف", "أبها", "تبوك", "حائل", "مكة", "المدينة", "جدة", "الدمام", "الأحساء", "الخبر", "الظهران", "بريدة", "الخرج", "القصيم", "سكاكا", "عرعر", "القريات", "الباحة", "خميس مشيط", "العلا"]
))

PLANT_DATABASE = [
    {"name": "بوتس ذهبي", "type": "داخلي", "indoor_outdoor": "داخلي", "colors": [100, 150, 80], "watering": 7, "fertilizing": 30, "light": "ظل جزئي", "cities": CITIES_KSA_ALL, "home_types": ["شقة", "فيلا", "منزل"]},
    {"name": "صبار", "type": "داخلي", "indoor_outdoor": "داخلي", "colors": [90, 120, 70], "watering": 14, "fertilizing": 60, "light": "شمس كاملة", "cities": CITIES_KSA_ALL, "home_types": ["شقة", "فيلا", "منزل", "حديقة"]},
    {"name": "نبتة العنكبوت", "type": "داخلي", "indoor_outdoor": "داخلي", "colors": [85, 140, 85], "watering": 7, "fertilizing": 30, "light": "ظل جزئي", "cities": CITIES_KSA_ALL, "home_types": ["شقة", "فيلا", "منزل"]},
    {"name": "زنبق السلام", "type": "داخلي", "indoor_outdoor": "داخلي", "colors": [60, 130, 90], "watering": 7, "fertilizing": 45, "light": "ظل", "cities": CITIES_KSA_ALL, "home_types": ["شقة", "فيلا", "منزل"]},
    {"name": "مونستيرا", "type": "داخلي", "indoor_outdoor": "داخلي", "colors": [65, 125, 80], "watering": 7, "fertilizing": 30, "light": "ظل جزئي", "cities": CITIES_KSA_ALL, "home_types": ["شقة", "فيلا", "منزل"]},
    {"name": "زاميا", "type": "داخلي", "indoor_outdoor": "داخلي", "colors": [50, 95, 55], "watering": 14, "fertilizing": 60, "light": "ظل جزئي", "cities": CITIES_KSA_ALL, "home_types": ["شقة", "فيلا", "منزل"]},
    {"name": "فيلوديندرون", "type": "داخلي", "indoor_outdoor": "داخلي", "colors": [75, 135, 82], "watering": 7, "fertilizing": 30, "light": "ظل جزئي", "cities": CITIES_KSA_ALL, "home_types": ["شقة", "فيلا", "منزل"]},
    {"name": "فيكس مطاطي", "type": "داخلي", "indoor_outdoor": "داخلي", "colors": [55, 120, 70], "watering": 7, "fertilizing": 30, "light": "ظل جزئي", "cities": CITIES_KSA_ALL, "home_types": ["شقة", "فيلا", "منزل"]},
    {"name": "دراسينا", "type": "داخلي", "indoor_outdoor": "داخلي", "colors": [70, 130, 85], "watering": 10, "fertilizing": 45, "light": "ظل جزئي", "cities": CITIES_KSA_ALL, "home_types": ["شقة", "فيلا", "منزل"]},
    {"name": "أغلاونيما", "type": "داخلي", "indoor_outdoor": "داخلي", "colors": [95, 145, 90], "watering": 7, "fertilizing": 30, "light": "ظل", "cities": CITIES_KSA_ALL, "home_types": ["شقة", "فيلا", "منزل"]},
    {"name": "عصارة خضراء", "type": "داخلي", "indoor_outdoor": "داخلي", "colors": [70, 140, 80], "watering": 10, "fertilizing": 45, "light": "شمس جزئية", "cities": CITIES_KSA_ALL, "home_types": ["شقة", "فيلا", "منزل"]},
    {"name": "سرخس بوسطن", "type": "داخلي", "indoor_outdoor": "داخلي", "colors": [55, 120, 90], "watering": 4, "fertilizing": 21, "light": "ظل", "cities": CITIES_KSA_ALL, "home_types": ["شقة", "فيلا", "منزل"]},
    {"name": "ورود", "type": "زينة", "indoor_outdoor": "خارجي", "colors": [200, 80, 100], "watering": 5, "fertilizing": 14, "light": "شمس كاملة", "cities": CITIES_KSA_ALL, "home_types": ["فيلا", "منزل", "حديقة"]},
    {"name": "خزامى", "type": "زينة", "indoor_outdoor": "خارجي", "colors": [130, 100, 160], "watering": 7, "fertilizing": 30, "light": "شمس كاملة", "cities": CITIES_LAVENDER_ZONE, "home_types": ["فيلا", "منزل", "حديقة"]},
    {"name": "إبرة الراعي", "type": "زينة", "indoor_outdoor": "خارجي", "colors": [200, 90, 120], "watering": 5, "fertilizing": 21, "light": "شمس جزئية", "cities": CITIES_KSA_ALL, "home_types": ["شقة", "فيلا", "منزل", "حديقة"]},
    {"name": "بتونيا", "type": "زينة", "indoor_outdoor": "خارجي", "colors": [180, 70, 140], "watering": 2, "fertilizing": 14, "light": "شمس كاملة", "cities": CITIES_KSA_ALL, "home_types": ["فيلا", "منزل", "حديقة"]},
    {"name": "قطيفة", "type": "زينة", "indoor_outdoor": "خارجي", "colors": [230, 140, 50], "watering": 5, "fertilizing": 21, "light": "شمس كاملة", "cities": CITIES_KSA_ALL, "home_types": ["فيلا", "منزل", "حديقة"]},
    {"name": "ياسمين", "type": "زينة", "indoor_outdoor": "خارجي", "colors": [240, 245, 250], "watering": 5, "fertilizing": 28, "light": "شمس جزئية", "cities": CITIES_KSA_ALL, "home_types": ["فيلا", "منزل", "حديقة"]},
    {"name": "خطمي", "type": "زينة", "indoor_outdoor": "خارجي", "colors": [220, 60, 80], "watering": 5, "fertilizing": 21, "light": "شمس كاملة", "cities": CITIES_KSA_ALL, "home_types": ["فيلا", "منزل", "حديقة"]},
    {"name": "بوجنفيلية", "type": "زينة", "indoor_outdoor": "خارجي", "colors": [220, 80, 130], "watering": 7, "fertilizing": 30, "light": "شمس كاملة", "cities": CITIES_KSA_ALL, "home_types": ["فيلا", "منزل", "حديقة"]},
    {"name": "بيغونيا", "type": "زينة", "indoor_outdoor": "خارجي", "colors": [200, 100, 110], "watering": 5, "fertilizing": 21, "light": "ظل جزئي", "cities": CITIES_KSA_ALL, "home_types": ["شقة", "فيلا", "منزل", "حديقة"]},
    {"name": "أوركيد", "type": "زينة", "indoor_outdoor": "داخلي", "colors": [200, 150, 200], "watering": 7, "fertilizing": 30, "light": "ظل جزئي", "cities": CITIES_KSA_ALL, "home_types": ["شقة", "فيلا", "منزل"]},
    {"name": "سيكلامن", "type": "زينة", "indoor_outdoor": "داخلي", "colors": [180, 80, 90], "watering": 5, "fertilizing": 21, "light": "ظل جزئي", "cities": CITIES_CYCLAMEN_COOL, "home_types": ["شقة", "فيلا", "منزل"]},
    {"name": "جربيرا", "type": "زينة", "indoor_outdoor": "خارجي", "colors": [220, 100, 110], "watering": 5, "fertilizing": 21, "light": "شمس جزئية", "cities": CITIES_KSA_ALL, "home_types": ["فيلا", "منزل", "حديقة"]},
    {"name": "كروتون", "type": "زينة", "indoor_outdoor": "خارجي", "colors": [150, 100, 60], "watering": 5, "fertilizing": 28, "light": "شمس جزئية", "cities": CITIES_KSA_ALL, "home_types": ["شقة", "فيلا", "منزل", "حديقة"]},
    {"name": "فيكس بنجامينا", "type": "زينة", "indoor_outdoor": "داخلي", "colors": [65, 135, 75], "watering": 7, "fertilizing": 30, "light": "ظل جزئي", "cities": CITIES_KSA_ALL, "home_types": ["شقة", "فيلا", "منزل"]},
    {"name": "ريحان", "type": "أعشاب", "indoor_outdoor": "خارجي", "colors": [55, 115, 65], "watering": 3, "fertilizing": 14, "light": "شمس جزئية", "cities": CITIES_KSA_ALL, "home_types": ["شقة", "فيلا", "منزل", "حديقة"]},
    {"name": "نعناع", "type": "أعشاب", "indoor_outdoor": "خارجي", "colors": [50, 125, 75], "watering": 3, "fertilizing": 21, "light": "ظل جزئي", "cities": CITIES_KSA_ALL, "home_types": ["شقة", "فيلا", "منزل", "حديقة"]},
    {"name": "إكليل الجبل", "type": "أعشاب", "indoor_outdoor": "خارجي", "colors": [60, 110, 70], "watering": 5, "fertilizing": 30, "light": "شمس كاملة", "cities": CITIES_KSA_ALL, "home_types": ["فيلا", "منزل", "حديقة"]},
    {"name": "زعتر", "type": "أعشاب", "indoor_outdoor": "خارجي", "colors": [55, 105, 65], "watering": 5, "fertilizing": 30, "light": "شمس كاملة", "cities": CITIES_KSA_ALL, "home_types": ["فيلا", "منزل", "حديقة"]},
    {"name": "بقدونس", "type": "أعشاب", "indoor_outdoor": "خارجي", "colors": [45, 110, 60], "watering": 4, "fertilizing": 21, "light": "ظل جزئي", "cities": CITIES_KSA_ALL, "home_types": ["شقة", "فيلا", "منزل", "حديقة"]},
    {"name": "كزبرة", "type": "أعشاب", "indoor_outdoor": "خارجي", "colors": [52, 118, 62], "watering": 3, "fertilizing": 21, "light": "ظل جزئي", "cities": CITIES_KSA_ALL, "home_types": ["شقة", "فيلا", "منزل", "حديقة"]},
    {"name": "أوريجانو", "type": "أعشاب", "indoor_outdoor": "خارجي", "colors": [58, 112, 68], "watering": 5, "fertilizing": 30, "light": "شمس جزئية", "cities": CITIES_KSA_ALL, "home_types": ["فيلا", "منزل", "حديقة"]},
    {"name": "مريمية", "type": "أعشاب", "indoor_outdoor": "خارجي", "colors": [100, 130, 90], "watering": 5, "fertilizing": 30, "light": "شمس كاملة", "cities": CITIES_SAGE_ZONE, "home_types": ["فيلا", "منزل", "حديقة"]},
    {"name": "ثوم معمر", "type": "أعشاب", "indoor_outdoor": "خارجي", "colors": [55, 122, 72], "watering": 3, "fertilizing": 21, "light": "شمس جزئية", "cities": CITIES_KSA_ALL, "home_types": ["شقة", "فيلا", "منزل", "حديقة"]},
    {"name": "بلسم الليمون", "type": "أعشاب", "indoor_outdoor": "خارجي", "colors": [60, 128, 78], "watering": 3, "fertilizing": 21, "light": "ظل جزئي", "cities": CITIES_KSA_ALL, "home_types": ["شقة", "فيلا", "منزل", "حديقة"]},
]

_DB_PATH = os.path.join(os.path.dirname(__file__), 'database.db')
_PLANT_ROWS_CACHE = None


def invalidate_catalog_cache():
    global _PLANT_ROWS_CACHE
    _PLANT_ROWS_CACHE = None


def _db_conn():
    import sqlite3

    conn = sqlite3.connect(_DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def _table_count(conn, table):
    if table not in ('cities', 'catalog_plants'):
        raise ValueError('invalid table')
    c = conn.cursor()
    c.execute('SELECT COUNT(*) FROM ' + table)
    return c.fetchone()[0]


def get_plant_rows():
    """صفوف الكتالوج: من SQLite إن وُجدت، وإلا من PLANT_DATABASE (للتعرف اللوني وML)."""
    global _PLANT_ROWS_CACHE
    if _PLANT_ROWS_CACHE is not None:
        return _PLANT_ROWS_CACHE
    try:
        conn = _db_conn()
        if _table_count(conn, 'catalog_plants') == 0:
            conn.close()
            _PLANT_ROWS_CACHE = []
            for i, p in enumerate(PLANT_DATABASE):
                q = dict(p)
                q['id'] = i + 1
                _PLANT_ROWS_CACHE.append(q)
            return _PLANT_ROWS_CACHE
        c = conn.cursor()
        c.execute(
            '''
            SELECT cp.id, cp.name, cp.type, cp.indoor_outdoor, cp.watering, cp.fertilizing, cp.light,
                   cp.colors_json, cp.home_types_json,
                   GROUP_CONCAT(c.name, '||') AS city_names
            FROM catalog_plants cp
            LEFT JOIN catalog_plant_cities cpc ON cpc.catalog_plant_id = cp.id
            LEFT JOIN cities c ON c.id = cpc.city_id
            GROUP BY cp.id
            ORDER BY cp.id
            '''
        )
        rows_out = []
        for row in c.fetchall():
            d = dict(row)
            raw = d.get('city_names') or ''
            cities = [x for x in raw.split('||') if x]
            if not cities:
                cities = list(SAUDI_CITIES)
            colors = json.loads(d['colors_json'] or '[0,0,0]')
            home_types = json.loads(d['home_types_json'] or '[]')
            rows_out.append(
                {
                    'id': d['id'],
                    'name': d['name'],
                    'type': d['type'],
                    'indoor_outdoor': d['indoor_outdoor']
                    or ('داخلي' if d['type'] == 'داخلي' else 'خارجي'),
                    'colors': colors,
                    'watering': d['watering'],
                    'fertilizing': d['fertilizing'],
                    'light': d['light'] or '',
                    'cities': cities,
                    'home_types': home_types,
                }
            )
        conn.close()
        _PLANT_ROWS_CACHE = rows_out
        return _PLANT_ROWS_CACHE
    except Exception:
        _PLANT_ROWS_CACHE = []
        for i, p in enumerate(PLANT_DATABASE):
            q = dict(p)
            q['id'] = i + 1
            _PLANT_ROWS_CACHE.append(q)
        return _PLANT_ROWS_CACHE


def _find_plant_row(arabic_name):
    for p in get_plant_rows():
        if p['name'] == arabic_name:
            return p
    return None


def _get_dominant_colors(img, n_colors=3):
    if np is None or Image is None:
        return []
    img = img.convert("RGB").resize((50, 50))
    pixels = np.array(img)
    r_avg = int(np.mean(pixels[:, :, 0]))
    g_avg = int(np.mean(pixels[:, :, 1]))
    b_avg = int(np.mean(pixels[:, :, 2]))
    return [r_avg, g_avg, b_avg]


def _color_distance(c1, c2):
    if np is None:
        return sum((a - b) ** 2 for a, b in zip(c1, c2)) ** 0.5
    return float(np.sqrt(np.sum((np.array(c1) - np.array(c2)) ** 2)))


def _identify_plant_color_fallback(image_data):
    if Image is None or np is None:
        return [{"name": "صبار", "type": "داخلي", "indoor_outdoor": "داخلي", "confidence": 0.5, "watering_interval_days": 14, "fertilizing_interval_days": 60}]
    try:
        img = Image.open(BytesIO(image_data))
        colors = _get_dominant_colors(img)
        scores = []
        for plant in get_plant_rows():
            dist = _color_distance(colors, plant["colors"])
            score = max(0, 1 - dist / 150)
            scores.append((score, plant))
        scores.sort(key=lambda x: x[0], reverse=True)
        results = []
        for i, (score, p) in enumerate(scores[:5]):
            results.append({
                "name": p["name"],
                "type": p["type"],
                "indoor_outdoor": p.get("indoor_outdoor", "داخلي" if p["type"] == "داخلي" else "خارجي"),
                "confidence": round(min(0.95, score + 0.1 * (5 - i)), 2),
                "watering_interval_days": p["watering"],
                "fertilizing_interval_days": p["fertilizing"],
                "model_source": "color_prototype",
            })
        return results if results else [{"name": "نبتة منزلية", "type": "داخلي", "indoor_outdoor": "داخلي", "confidence": 0.3, "watering_interval_days": 7, "fertilizing_interval_days": 30, "model_source": "color_prototype"}]
    except Exception:
        return [{"name": "صبار", "type": "داخلي", "indoor_outdoor": "داخلي", "confidence": 0.4, "watering_interval_days": 14, "fertilizing_interval_days": 60, "model_source": "color_prototype"}]


def identify_plant(image_data):
    if Image is None or np is None:
        return [{"name": "صبار", "type": "داخلي", "indoor_outdoor": "داخلي", "confidence": 0.5, "watering_interval_days": 14, "fertilizing_interval_days": 60}]
    try:
        ml_results = _identify_plant_ml(image_data)
        if ml_results:
            return ml_results
    except Exception:
        pass
    return _identify_plant_color_fallback(image_data)


def get_all_plants_arabic():
    return [{"name": p["name"], "type": p["type"]} for p in get_plant_rows()]


GENERAL_TIPS = [
    "راقب لون الأوراق: الاصفرار غالباً ماء زائد أو نقص غذاء.",
    "استخدم ماء بدرجة حرارة الغرفة وليس شديد البرودة على الجذور.",
    "نظّف الغبار عن الأوراق شهرياً لتحسين التمثيل الضوئي.",
    "جرّب إخراج النبات لتهوية قصيرة إذا السماح بالطقس.",
    "قلّص الري في الشتاء إن بطّأ تجفُّ التربة.",
    "لا تُكثر التسميد: الغذاء الزائد يحرق الجذور.",
    "ضع طبقة حصى فوق التربة لتقليل تبخر الماء في الصيف.",
    "سجّل مواعيد الري في التطبيق لتظهر لك التنبيهات في وقتها.",
]


def smart_tip_for_plant(p):
    lt = p.get("light", "")
    w = p["watering"]
    f = p["fertilizing"]
    t = p["type"]
    io = p.get("indoor_outdoor", "")
    return (
        f"نصيحة لـ{p['name']} ({t}، {io}): راعِ {lt}؛ ريّ منظم كل {w} يوم "
        f"وتسميد دوري كل {f} يوم. راقب تصريف الماء من الأصيص."
    )


def get_tip_of_day():
    idx = datetime.now().timetuple().tm_yday % len(GENERAL_TIPS)
    return GENERAL_TIPS[idx]


def _city_regions_for_plant(p):
    plant_cities = set(p.get("cities") or [])
    if not plant_cities:
        return ["جميع مناطق المملكة"]
    labels = []
    for label, rcities in CITY_REGIONS_META:
        if plant_cities & set(rcities):
            labels.append(label)
    if not labels:
        labels = ["مناسب لمدن مختارة (انظر القائمة)"]
    return list(dict.fromkeys(labels))


def _care_level_for_plant(p):
    if p.get("care_level"):
        return p["care_level"]
    w = int(p.get("watering", 7))
    if w <= 4:
        return "سهل"
    if w >= 14:
        return "صعب"
    return "متوسط"


def _catalog_entry(i, p, catalog_id=None):
    cid = catalog_id if catalog_id is not None else i + 1
    cities = p.get("cities", [])
    return {
        "id": cid,
        "name": p["name"],
        "type": p["type"],
        "indoor_outdoor": p.get("indoor_outdoor", "داخلي" if p["type"] == "داخلي" else "خارجي"),
        "watering_days": p["watering"],
        "fertilizing_days": p["fertilizing"],
        "light_requirement": p.get("light", ""),
        "suitable_cities": cities,
        "city_regions": _city_regions_for_plant(p),
        "care_level": _care_level_for_plant(p),
        "suitable_home_types": p.get("home_types", []),
        "smart_tip": smart_tip_for_plant(p),
    }


def get_plant_catalog():
    try:
        conn = _db_conn()
        if _table_count(conn, 'catalog_plants') == 0:
            conn.close()
            return [_catalog_entry(i, p) for i, p in enumerate(PLANT_DATABASE)]
        c = conn.cursor()
        c.execute(
            '''
            SELECT cp.id, cp.name, cp.type, cp.indoor_outdoor, cp.watering, cp.fertilizing, cp.light,
                   cp.home_types_json,
                   GROUP_CONCAT(c.name, '||') AS city_names
            FROM catalog_plants cp
            LEFT JOIN catalog_plant_cities cpc ON cpc.catalog_plant_id = cp.id
            LEFT JOIN cities c ON c.id = cpc.city_id
            GROUP BY cp.id
            ORDER BY cp.id
            '''
        )
        out = []
        for row in c.fetchall():
            d = dict(row)
            raw = d.get('city_names') or ''
            cities = [x for x in raw.split('||') if x]
            if not cities:
                cities = list(SAUDI_CITIES)
            home_types = json.loads(d['home_types_json'] or '[]')
            p = {
                'name': d['name'],
                'type': d['type'],
                'indoor_outdoor': d['indoor_outdoor']
                or ('داخلي' if d['type'] == 'داخلي' else 'خارجي'),
                'watering': d['watering'],
                'fertilizing': d['fertilizing'],
                'light': d['light'] or '',
                'cities': cities,
                'home_types': home_types,
            }
            out.append(_catalog_entry(0, p, catalog_id=d['id']))
        conn.close()
        return out
    except Exception:
        return [_catalog_entry(i, p) for i, p in enumerate(PLANT_DATABASE)]


def get_recommendations(city=None, home_type=None):
    rows = get_plant_rows()
    if not city and not home_type:
        return get_plant_catalog()
    result = []
    for i, p in enumerate(rows):
        cities = p.get('cities', [])
        home_types = p.get('home_types', [])
        city_ok = not city or city in cities or not cities
        home_ok = not home_type or home_type in home_types or not home_types
        if city_ok and home_ok:
            cid = p.get('id', i + 1)
            result.append(_catalog_entry(i, p, catalog_id=cid))
    return result if result else get_plant_catalog()


def get_cities():
    try:
        conn = _db_conn()
        if _table_count(conn, 'cities') == 0:
            conn.close()
            return list(SAUDI_CITIES)
        c = conn.cursor()
        c.execute('SELECT name FROM cities ORDER BY sort_order, id')
        names = [r[0] for r in c.fetchall()]
        conn.close()
        return names if names else list(SAUDI_CITIES)
    except Exception:
        return list(SAUDI_CITIES)


def get_home_types():
    return HOME_TYPES
