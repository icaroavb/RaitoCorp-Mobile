"""Gera o ícone do app RaitoCorp (lâmpada com glow âmbar) via PIL.
Saídas: assets/icons/app_icon.png (com fundo) e app_icon_fg.png (foreground transparente).
Rodar: python tool/gen_icon.py
"""
import math
from PIL import Image, ImageDraw, ImageFilter

S = 1024            # tamanho base
SS = S * 3          # supersampling para bordas suaves
CX = SS // 2

AMBER = (255, 193, 64)      # amber400
AMBER_HI = (255, 224, 150)  # destaque claro
AMBER_DK = (214, 158, 38)   # âmbar escuro
GLASS = (255, 240, 200)     # vidro do bulbo
OBSIDIAN = (17, 17, 17)     # fundo
OBSIDIAN_2 = (38, 34, 24)   # fundo com leve calor


def radial_bg(size, inner, outer):
    """Fundo com gradiente radial (vinheta quente no centro)."""
    img = Image.new("RGB", (size, size), outer)
    px = img.load()
    cx = cy = size / 2
    maxd = math.hypot(cx, cy)
    for y in range(size):
        for x in range(size):
            d = math.hypot(x - cx, y - cy) / maxd
            t = min(1.0, d * 1.15)
            px[x, y] = tuple(int(inner[i] + (outer[i] - inner[i]) * t) for i in range(3))
    return img


def vertical_grad(w, h, top, bottom):
    """Faixa com gradiente vertical (usada pra preencher o bulbo via máscara)."""
    grad = Image.new("RGB", (1, h))
    for y in range(h):
        t = y / max(1, h - 1)
        grad.putpixel((0, y), tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3)))
    return grad.resize((w, h))


def draw_bulb(draw, layer):
    """Desenha a lâmpada (bulbo + base + raios) na layer RGBA."""
    # raios de luz ao redor (8 raios, comprimento variável)
    ray_color = AMBER
    n = 8
    r_in = int(SS * 0.40)
    r_out = int(SS * 0.485)
    for k in range(n):
        ang = math.radians(k * (360 / n) - 90)
        x1 = CX + r_in * math.cos(ang)
        y1 = int(SS * 0.46) + r_in * math.sin(ang)
        x2 = CX + r_out * math.cos(ang)
        y2 = int(SS * 0.46) + r_out * math.sin(ang)
        draw.line([(x1, y1), (x2, y2)], fill=ray_color + (255,), width=int(SS * 0.022))


def main():
    # --- fundo ---
    bg = radial_bg(SS, OBSIDIAN_2, OBSIDIAN).convert("RGBA")

    # --- glow atrás do bulbo ---
    glow = Image.new("RGBA", (SS, SS), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    bulb_cy = int(SS * 0.46)
    gr = int(SS * 0.32)
    gd.ellipse([CX - gr, bulb_cy - gr, CX + gr, bulb_cy + gr], fill=AMBER + (180,))
    glow = glow.filter(ImageFilter.GaussianBlur(SS * 0.06))

    # --- camada da lâmpada ---
    fg = Image.new("RGBA", (SS, SS), (0, 0, 0, 0))
    d = ImageDraw.Draw(fg)

    # raios
    draw_bulb(d, fg)

    # bulbo (círculo) com aro âmbar
    br = int(SS * 0.235)
    d.ellipse([CX - br, bulb_cy - br, CX + br, bulb_cy + br], fill=AMBER + (255,))
    # vidro interno com gradiente vertical
    inner_r = int(br * 0.86)
    glass_box = (CX - inner_r, bulb_cy - inner_r, CX + inner_r, bulb_cy + inner_r)
    grad = vertical_grad(inner_r * 2, inner_r * 2, AMBER_HI, GLASS).convert("RGBA")
    mask = Image.new("L", (inner_r * 2, inner_r * 2), 0)
    ImageDraw.Draw(mask).ellipse([0, 0, inner_r * 2 - 1, inner_r * 2 - 1], fill=255)
    fg.paste(grad, (glass_box[0], glass_box[1]), mask)

    # brilho especular (canto superior esquerdo do vidro)
    sh = Image.new("RGBA", (SS, SS), (0, 0, 0, 0))
    shd = ImageDraw.Draw(sh)
    sr = int(inner_r * 0.45)
    sx, sy = CX - int(inner_r * 0.35), bulb_cy - int(inner_r * 0.4)
    shd.ellipse([sx - sr, sy - sr, sx + sr, sy + sr], fill=(255, 255, 255, 120))
    sh = sh.filter(ImageFilter.GaussianBlur(SS * 0.02))
    fg = Image.alpha_composite(fg, sh)
    d = ImageDraw.Draw(fg)

    # filamento em "R" estilizado (linhas)
    fw = int(SS * 0.018)
    fil = AMBER_DK + (255,)
    rx = CX - int(inner_r * 0.32)
    ry0 = bulb_cy - int(inner_r * 0.42)
    ry1 = bulb_cy + int(inner_r * 0.42)
    rw = int(inner_r * 0.5)
    # haste vertical
    d.line([(rx, ry0), (rx, ry1)], fill=fil, width=fw)
    # arco superior do R
    d.arc([rx, ry0, rx + rw, ry0 + int(inner_r * 0.5)], -90, 90, fill=fil, width=fw)
    # perna do R
    d.line([(rx + int(rw * 0.15), bulb_cy), (rx + rw, ry1)], fill=fil, width=fw)

    # rosca/base da lâmpada
    base_w = int(br * 0.62)
    base_x0 = CX - base_w // 2
    base_y = bulb_cy + br - int(SS * 0.01)
    seg_h = int(SS * 0.035)
    cols = [AMBER, AMBER_DK, (150, 110, 30)]
    for i, c in enumerate(cols):
        yy = base_y + i * (seg_h + int(SS * 0.012))
        d.rounded_rectangle([base_x0, yy, base_x0 + base_w, yy + seg_h],
                            radius=int(seg_h * 0.35), fill=c + (255,))

    # --- compõe tudo ---
    full = Image.alpha_composite(bg, glow)
    full = Image.alpha_composite(full, fg)
    full = full.resize((S, S), Image.LANCZOS)
    full.convert("RGB").save("assets/icons/app_icon.png")

    # foreground transparente (pro adaptive icon) — só a lâmpada, sem fundo,
    # um pouco menor pra caber na zona segura do adaptive icon
    fg_only = Image.alpha_composite(glow, fg)
    fg_only = fg_only.resize((S, S), Image.LANCZOS)
    canvas = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    scaled = fg_only.resize((int(S * 0.72), int(S * 0.72)), Image.LANCZOS)
    off = (S - scaled.width) // 2
    canvas.paste(scaled, (off, off), scaled)
    canvas.save("assets/icons/app_icon_fg.png")
    print("OK: app_icon.png e app_icon_fg.png gerados")


if __name__ == "__main__":
    main()
