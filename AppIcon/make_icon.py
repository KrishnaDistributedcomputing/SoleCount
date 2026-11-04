"""Sunrise app icon. Drawn here. No logos and no outside art."""
from PIL import Image, ImageDraw

S = 1024
img = Image.new("RGB", (S, S))
draw = ImageDraw.Draw(img)
# Coral, gold, then mint. One line per row is enough.
stops = [
    (0.00, (244, 122, 98)),
    (0.48, (247, 176, 102)),
    (1.00, (140, 196, 168)),
]
for y in range(S):
    t = y / (S - 1)
    for i in range(len(stops) - 1):
        left, right = stops[i], stops[i + 1]
        if left[0] <= t <= right[0] or i == len(stops) - 2:
            span = 0 if right[0] == left[0] else (t - left[0]) / (right[0] - left[0])
            span = max(0, min(1, span))
            rgb = tuple(int(left[1][c] + (right[1][c] - left[1][c]) * span) for c in range(3))
            draw.line([(0, y), (S, y)], fill=rgb)
            break

cream = (255, 250, 245)
ink = (61, 31, 20)
coral = (196, 84, 64)
# A soft sun.
draw.ellipse([128, 96, 360, 328], fill=(255, 228, 170))
draw.ellipse([168, 136, 320, 288], fill=(255, 244, 214))
# A simple sneaker facing right. Shapes only, not a brand.
shoe = [
    (210, 690), (230, 520), (310, 470), (420, 500), (520, 560),
    (640, 600), (760, 620), (860, 660), (890, 730), (210, 730),
]
draw.polygon(shoe, fill=cream)
draw.rounded_rectangle([180, 700, 900, 790], radius=40, fill=ink)
# Three short lace marks.
for x in (380, 470, 560):
    draw.line([(x, 530), (x + 70, 590)], fill=coral, width=16)
# A small heart, so the icon feels warm.
draw.polygon([(760, 210), (800, 170), (840, 210), (800, 260)], fill=cream)
draw.ellipse([748, 168, 804, 224], fill=cream)
draw.ellipse([796, 168, 852, 224], fill=cream)

img.save("AppIcon/AppIcon-1024.png")
print(img.mode, img.size)
