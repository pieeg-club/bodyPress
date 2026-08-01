"""Generate Android notification small icons.

Android renders notification small icons as a monochrome silhouette using the
alpha channel only (colour is ignored and system-tinted). A full-colour
launcher icon therefore shows up as a plain white square. This produces a
transparent-background, white 'B' at the correct densities.
"""

import os
from PIL import Image, ImageDraw, ImageFont

FONT_CANDIDATES = [
    r"C:\Windows\Fonts\garabd.ttf",
    r"C:\Windows\Fonts\timesbd.ttf",
    r"C:\Windows\Fonts\georgiab.ttf",
    r"C:\Windows\Fonts\georgia.ttf",
    r"C:\Windows\Fonts\times.ttf",
]

# Notification icon densities (dp base = 24)
NOTIF_ICONS = {
    r"android\app\src\main\res\drawable-mdpi\ic_notification.png":    24,
    r"android\app\src\main\res\drawable-hdpi\ic_notification.png":    36,
    r"android\app\src\main\res\drawable-xhdpi\ic_notification.png":   48,
    r"android\app\src\main\res\drawable-xxhdpi\ic_notification.png":  72,
    r"android\app\src\main\res\drawable-xxxhdpi\ic_notification.png": 96,
}

PADDING = 0.08  # keep the glyph inside the safe area
BASE_DIR = os.path.dirname(os.path.abspath(__file__))


def load_font(size: int) -> ImageFont.FreeTypeFont:
    for path in FONT_CANDIDATES:
        if os.path.exists(path):
            try:
                return ImageFont.truetype(path, size)
            except Exception:
                continue
    return ImageFont.load_default()


def make_notif_icon(px: int) -> Image.Image:
    """White 'B' silhouette on a fully transparent background."""
    img = Image.new("RGBA", (px, px), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    target = px * (1.0 - PADDING * 2)
    font_size = int(target * 1.05)
    font = load_font(font_size)

    for _ in range(40):
        bbox = draw.textbbox((0, 0), "B", font=font)
        w = bbox[2] - bbox[0]
        h = bbox[3] - bbox[1]
        if w <= target and h <= target:
            break
        font_size = int(font_size * 0.96)
        font = load_font(font_size)

    bbox = draw.textbbox((0, 0), "B", font=font)
    w = bbox[2] - bbox[0]
    h = bbox[3] - bbox[1]
    x = (px - w) / 2 - bbox[0]
    y = (px - h) / 2 - bbox[1]

    # Pure white; Android uses only the alpha channel and tints the rest.
    draw.text((x, y), "B", fill=(255, 255, 255, 255), font=font)
    return img


def generate_all():
    for rel_path, size in NOTIF_ICONS.items():
        full_path = os.path.join(BASE_DIR, rel_path)
        os.makedirs(os.path.dirname(full_path), exist_ok=True)
        make_notif_icon(size).save(full_path, "PNG")
        print(f"  ✓  {size:>3}px  {rel_path}")
    print("\nNotification icons generated.")


if __name__ == "__main__":
    generate_all()
