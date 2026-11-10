#!/usr/bin/env python3
"""يولّد صورة السبلاش: لوجو ورقتي + إضاءة (أزرق/بنفسجي) من ورا + اسم التطبيق.

الاستخدام (من جذر المشروع):
  pip install pillow numpy
  python tools/make_splash.py

الخرج:
  assets/splash/splash_logo.png      (للأندرويد < 12 و iOS: لوجو + إضاءة + الاسم)
  assets/splash/splash_logo_a12.png  (لأندرويد 12+: اللوجو بس، لأن النظام بيقصّه جوه دايرة)
"""
import argparse
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFont

ap = argparse.ArgumentParser()
ap.add_argument("--logo", default="assets/images/logo.png")
ap.add_argument("--font", default="assets/fonts/Cairo-Bold.ttf")
ap.add_argument("--name", default="ورقتي")
ap.add_argument("--out", default="assets/splash")
ap.add_argument("--no-text", action="store_true")
args = ap.parse_args()

CANVAS = 1400          # px  (≈ 350dp على xxxhdpi)
LOGO = 500             # عرض اللوجو px
BLUE = np.array([30, 110, 255], dtype=np.float32)
PURPLE = np.array([140, 60, 255], dtype=np.float32)

os.makedirs(args.out, exist_ok=True)
logo = Image.open(args.logo).convert("RGBA")
logo = logo.resize((LOGO, int(LOGO * logo.height / logo.width)), Image.LANCZOS)

# ── الإضاءة: بقعتين gaussian (أزرق يسار / بنفسجي يمين) فوق خلفية سودا ──
yy, xx = np.mgrid[0:CANVAS, 0:CANVAS].astype(np.float32)
cx, cy = CANVAS / 2, CANVAS / 2 - 40

def blob(dx, dy, sigma):
    d2 = (xx - (cx + dx)) ** 2 + (yy - (cy + dy)) ** 2
    return np.exp(-d2 / (2 * sigma**2))

glow = (
    blob(-110, 40, 230)[..., None] * BLUE * 0.60
    + blob(120, 30, 240)[..., None] * PURPLE * 0.62
    + blob(0, 0, 160)[..., None] * np.array([70, 50, 200], np.float32) * 0.30
)
# تلاشي ناعم عند الأطراف عشان ما يظهرش حد للصورة
edge = np.clip(1 - np.hypot(xx - CANVAS / 2, yy - CANVAS / 2) / (CANVAS / 2), 0, 1)
glow *= (edge ** 0.8)[..., None]
bg = Image.fromarray(np.clip(glow, 0, 255).astype(np.uint8), "RGB").convert("RGBA")

# ── اللوجو + الاسم ──
lx = (CANVAS - logo.width) // 2
ly = int(cy - logo.height / 2)
bg.alpha_composite(logo, (lx, ly))

if not args.no_text:
    font = ImageFont.truetype(args.font, 120)
    d = ImageDraw.Draw(bg)
    d.text((CANVAS / 2, ly + logo.height + 95), args.name, font=font,
           fill=(255, 255, 255, 255), anchor="mm", direction="rtl", language="ar")

bg.convert("RGB").save(os.path.join(args.out, "splash_logo.png"))

# ── أندرويد 12: اللوجو فقط (الدايرة الآمنة ≈ 2/3 من 960) ──
a12 = Image.new("RGBA", (960, 960), (0, 0, 0, 0))
s = 600 / max(logo.size)
l2 = logo.resize((int(logo.width * s), int(logo.height * s)), Image.LANCZOS)
a12.alpha_composite(l2, ((960 - l2.width) // 2, (960 - l2.height) // 2))
a12.save(os.path.join(args.out, "splash_logo_a12.png"))
print("done ->", args.out)
