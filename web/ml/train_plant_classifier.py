# -*- coding: utf-8 -*-
# Trains RandomForest on image features from the TensorFlow flower_photos dataset
# (Google-hosted archive used in official TensorFlow tutorials — real labeled images).

import os
import sys
import json
import tarfile
import urllib.request
from io import BytesIO

import numpy as np
from PIL import Image
from sklearn.ensemble import RandomForestClassifier
import joblib

WEB_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_DIR = os.path.join(WEB_ROOT, 'data', 'flower_photos_cache')
MODEL_DIR = os.path.join(WEB_ROOT, 'models')
ARCHIVE_URL = (
    'https://storage.googleapis.com/download.tensorflow.org/example_images/flower_photos.tgz'
)
ARCHIVE_PATH = os.path.join(DATA_DIR, 'flower_photos.tgz')
MODEL_PATH = os.path.join(MODEL_DIR, 'plant_rf.joblib')
NAMES_PATH = os.path.join(MODEL_DIR, 'class_names.json')
MAP_PATH = os.path.join(WEB_ROOT, 'data', 'flower_class_map.json')


def extract_features_from_pil(img):
    img = img.convert('RGB').resize((128, 128))
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
    return np.array(feats, dtype=np.float64)


def ensure_dataset():
    os.makedirs(DATA_DIR, exist_ok=True)
    if not os.path.isfile(ARCHIVE_PATH):
        print('Downloading flower_photos.tgz ...')
        urllib.request.urlretrieve(ARCHIVE_URL, ARCHIVE_PATH)
    extract_root = os.path.join(DATA_DIR, 'flower_photos')
    if not os.path.isdir(extract_root):
        print('Extracting archive ...')
        with tarfile.open(ARCHIVE_PATH, 'r:gz') as tf:
            tf.extractall(DATA_DIR)
    return extract_root


def load_samples(root, max_per_class=400):
    X_list = []
    y_list = []
    class_names = sorted(
        d for d in os.listdir(root)
        if os.path.isdir(os.path.join(root, d)) and not d.startswith('.')
    )
    for label_idx, folder in enumerate(class_names):
        folder_path = os.path.join(root, folder)
        files = [
            f for f in os.listdir(folder_path)
            if f.lower().endswith(('.jpg', '.jpeg', '.png'))
        ]
        for fname in files[:max_per_class]:
            path = os.path.join(folder_path, fname)
            try:
                with Image.open(path) as im:
                    X_list.append(extract_features_from_pil(im))
                    y_list.append(label_idx)
            except OSError:
                continue
    return np.vstack(X_list), np.array(y_list), class_names


def main():
    os.makedirs(MODEL_DIR, exist_ok=True)
    root = ensure_dataset()
    print('Loading images and computing features ...')
    X, y, class_names = load_samples(root)
    if len(X) < 50:
        print('Not enough training samples.', file=sys.stderr)
        sys.exit(1)
    clf = RandomForestClassifier(
        n_estimators=200,
        max_depth=24,
        min_samples_leaf=2,
        class_weight='balanced_subsample',
        random_state=42,
        n_jobs=-1,
    )
    clf.fit(X, y)
    joblib.dump({'clf': clf, 'feature_dim': X.shape[1]}, MODEL_PATH, compress=3)
    with open(NAMES_PATH, 'w', encoding='utf-8') as f:
        json.dump(class_names, f, ensure_ascii=False)
    default_map = {
        'daisy': 'إبرة الراعي',
        'dandelion': 'بتونيا',
        'roses': 'ورود',
        'sunflowers': 'قطيفة',
        'tulips': 'جربيرا',
    }
    if not os.path.isfile(MAP_PATH):
        with open(MAP_PATH, 'w', encoding='utf-8') as f:
            json.dump(default_map, f, ensure_ascii=False, indent=2)
    print('Saved:', MODEL_PATH)
    print('Classes:', class_names)


if __name__ == '__main__':
    main()
