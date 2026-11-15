"""Saca el emblema del logo (sin el texto), le quita el fondo claro y lo deja cuadrado.
Uso: python hacer_icono.py <logo> <icono.png> <muestra.png>"""
import sys
from collections import deque

from PIL import Image, ImageDraw, ImageFilter

ORIGEN, DESTINO, MUESTRA = sys.argv[1], sys.argv[2], sys.argv[3]
FONDO = (247, 247, 247)
TAM = 512

im = Image.open(ORIGEN).convert("RGBA")
w, h = im.size
px = im.load()


def dif(p):
    return max(abs(p[0] - FONDO[0]), abs(p[1] - FONDO[1]), abs(p[2] - FONDO[2]))


def oscuro(p):
    return p[0] + p[1] + p[2] < 200


# 1) Dónde empieza la franja del texto: la primera fila con una línea oscura continua muy larga.
corte = None
for y in range(620, 720):
    mejor = actual = 0
    for x in range(w):
        actual = actual + 1 if oscuro(px[x, y]) else 0
        mejor = max(mejor, actual)
    if y % 2 == 0 and 640 <= y <= 670:
        print("fila", y, "línea oscura más larga", mejor)
    if mejor > 150 and corte is None:
        corte = y
print("franja del texto desde la fila", corte)

# 2) El fondo: lo claro conectado con el borde de la imagen (relleno desde los bordes).
fondo = bytearray(w * h)
cola = deque((x, y) for x in range(w) for y in (0, h - 1))
cola.extend((x, y) for y in range(h) for x in (0, w - 1))
while cola:
    x, y = cola.popleft()
    i = y * w + x
    if fondo[i] or dif(px[x, y]) > 10:
        continue
    fondo[i] = 1
    if x > 0:
        cola.append((x - 1, y))
    if x < w - 1:
        cola.append((x + 1, y))
    if y > 0:
        cola.append((x, y - 1))
    if y < h - 1:
        cola.append((x, y + 1))

# 3) Fondo transparente, y borde suave: lo que toca el fondo es mezcla de fondo y dibujo.
mascara = Image.frombytes("L", (w, h), bytes(v * 255 for v in fondo))
cerca = mascara.filter(ImageFilter.MaxFilter(5)).load()
for y in range(h):
    for x in range(w):
        if fondo[y * w + x]:
            px[x, y] = (0, 0, 0, 0)
        elif cerca[x, y]:
            p = px[x, y]
            a = min(1.0, dif(p) / 160.0)
            if a <= 0.02:
                px[x, y] = (0, 0, 0, 0)
                continue
            color = [max(0, min(255, round((p[c] - (1 - a) * FONDO[c]) / a))) for c in range(3)]
            px[x, y] = (color[0], color[1], color[2], round(a * 255))

# 4) Solo el emblema (lo de arriba de la franja), cuadrado y con un poco de margen.
emblema = im.crop((0, 0, w, corte))
caja = emblema.getbbox()
print("emblema en", caja)
emblema = emblema.crop(caja)
lado = max(emblema.size)
margen = round(lado * 0.04)
cuadro = Image.new("RGBA", (lado + 2 * margen, lado + 2 * margen), (0, 0, 0, 0))
cuadro.paste(emblema, ((cuadro.width - emblema.width) // 2, (cuadro.height - emblema.height) // 2))
icono = cuadro.resize((TAM, TAM), Image.LANCZOS)
icono.save(DESTINO, optimize=True)
print("guardado", DESTINO, icono.size)

# 5) Muestra: el ícono sobre una pestaña oscura y una clara, a 16, 32, 64 y 180 px.
muestra = Image.new("RGBA", (900, 520), (255, 255, 255, 255))
dibujo = ImageDraw.Draw(muestra)
for fila, color in enumerate([(32, 33, 36, 255), (241, 243, 244, 255)]):
    dibujo.rectangle((0, fila * 260, 900, fila * 260 + 259), fill=color)
    x = 20
    for t in (16, 32, 64, 180):
        chico = icono.resize((t, t), Image.LANCZOS)
        muestra.alpha_composite(chico, (x, fila * 260 + 40))
        x += t + 40
muestra.alpha_composite(icono.resize((240, 240), Image.LANCZOS), (640, 10))
muestra.save(MUESTRA)
print("muestra", MUESTRA)
