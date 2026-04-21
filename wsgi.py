# -*- coding: utf-8 -*-
"""نقطة دخول WSGI من جذر المستودع (Render يشغّل غالباً من هنا بدون --chdir web)."""
import os
import sys

_ROOT = os.path.dirname(os.path.abspath(__file__))
_WEB = os.path.join(_ROOT, 'web')
sys.path.insert(0, _WEB)
os.chdir(_WEB)
from app import app as app  # noqa: E402
