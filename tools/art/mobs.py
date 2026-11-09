"""적: 버섯돌이, 도깨비불, 멧돼지, 숲지기 대왕멧돼지. 효과·아이콘도 여기서."""
import math, random
from common import *
from objects import shade_blob

def eyes(im, pts, angry=True, col='ink'):
    for (x, y) in pts:
        put(im, x, y, col); put(im, x, y + 1, col)
        put(im, x, y - 1, 'wht') if False else None
    if angry:
        (x1, y1), (x2, y2) = pts[0], pts[-1]
        put(im, x1 - 1, y1 - 2, col); put(im, x1, y1 - 1, col)
        put(im, x2 + 1, y2 - 2, col); put(im, x2, y2 - 1, col)

def mushroom(phase):
    """phase 0,1 숨쉬기 / 2 웅크림 / 3 뜀(늘어남) / 4 맞음"""
    sy = {0: 1.0, 1: 0.94, 2: 0.8, 3: 1.15, 4: 1.0}[phase]
    sx = {0: 1.0, 1: 1.04, 2: 1.15, 3: 0.88, 4: 1.0}[phase]
    W, H = 16, 18
    im = img(W, H)
    for x in range(3, 13): put(im, x, 17, 'shadow')
    if phase != 3: put(im, 2, 17, 'shadow'); put(im, 13, 17, 'shadow')
    body = img(W, H)
    base = 16 if phase != 3 else 14
    # 자루
    sh = int(6 * sy)
    for y in range(base - sh, base + 1):
        for x in range(5, 11):
            put(body, x, y, 'p3' if x < 7 else ('p2' if x < 10 else 'p1'))
    eyes(body, [(6, base - sh + 2), (9, base - sh + 2)])
    put(body, 7, base - sh + 5, 'red1'); put(body, 8, base - sh + 5, 'red1')
    # 갓
    cap_y = base - sh
    cw, ch = 7.2 * sx, 6.5 * sy
    cap = shade_blob(W, H, [(8, cap_y + 0.5, 0)], ['or1'], 1)
    for y in range(H):
        for x in range(W):
            nx = (x + 0.5 - 8) / cw; ny = (y + 0.5 - cap_y) / ch
            if ny < 0.15 and nx * nx + ny * ny < 1:
                lit = -nx * 0.5 - ny * 0.6
                c = 'red1' if lit < -0.15 else ('red2' if lit < 0.35 else 'red3')
                if ny > -0.05: c = 'red0'
                put(cap, x, y, c)
    # 점무늬 대신 달무늬(초승달) 두 개
    for (dx, dy) in ((-3, -3), (2, -4)):
        cx, cy = int(8 + dx * sx), int(cap_y + dy * sy)
        put(cap, cx, cy, 'y2'); put(cap, cx + 1, cy, 'y2'); put(cap, cx, cy + 1, 'y1')
    body.alpha_composite(cap)
    if phase == 4:
        px = body.load()
        for y in range(H):
            for x in range(W):
                if px[x, y][3]: px[x, y] = PAL['wht']
    im.alpha_composite(outline(body))
    return im

def wisp(phase):
    W, H = 16, 20
    im = img(W, H)
    for x in range(5, 11): put(im, x, 19, (20, 40, 60, 70))
    b = img(W, H)
    t = phase * math.pi / 2
    for y in range(H - 2):
        for x in range(W):
            u = (x + 0.5 - 8) / 5.6
            v = (y + 0.5 - 11) / 6
            # 아래는 둥글고 위는 흔들리는 꼬리
            if v > 0:
                inside = u * u + v * v < 1
            else:
                sway = math.sin(-v * 2.6 + t) * 0.35 * (-v)
                w = (1 + v * 0.72)
                inside = abs(u - sway) < max(0, w) and v > -1.45
            if not inside: continue
            d = math.hypot(u * 0.9, v * 0.8 + 0.25)
            c = 'f3' if d < 0.35 else ('f2' if d < 0.62 else ('f1' if d < 0.9 else 'f0'))
            put(b, x, y, c)
    eyes(b, [(6, 11), (9, 11)], angry=False, col='v0')
    put(b, 7, 14, 'v0'); put(b, 8, 14, 'v0')
    im.alpha_composite(outline(b, 'v0'))
    return im

def boar(phase, scale=1.0):
    """오른쪽을 봄. phase 0,1 걷기 / 2,3 돌진 / 4 맞음"""
    W, H = int(28 * scale), int(22 * scale)
    s = scale
    im = img(W, H)
    for y in range(H - 3, H):
        for x in range(int(3 * s), int(W - 3 * s)):
            if ((x - W / 2) / (W / 2 - 3 * s)) ** 2 + ((y - (H - 1.5)) / 1.8) ** 2 < 1: put(im, x, y, 'shadow')
    b = img(W, H)
    lift = (1 if phase in (1, 3) else 0)
    # 다리
    leg = ['b0', 'b1']
    lp = [(7, 0), (11, 1), (17, 0), (21, 1)]
    for i, (lx, o) in enumerate(lp):
        off = (1 if (i + phase) % 2 else -1) if phase < 4 else 0
        if phase in (2, 3): off *= 2
        for y in range(int(15 * s), int(20 * s)):
            for x in range(int((lx + off * 0.5) * s), int((lx + 2.5 + off * 0.5) * s)):
                put(b, x, y - (lift if i % 2 else 0), leg[o])
        put(b, int((lx + off * 0.5) * s), int(20 * s) - 1, 'ink')
    # 몸통
    circles = [(13 * s, 11 * s, 8 * s), (8 * s, 12 * s, 6 * s), (18 * s, 11.5 * s, 6.5 * s)]
    body = shade_blob(W, H, circles, ['b0', 'b1', 'b2', 'b3'], 5)
    b.alpha_composite(body)
    # 등갈기
    for x in range(int(6 * s), int(19 * s)):
        top = 0
        for y in range(H):
            if b.getpixel((x, y))[3]: top = y; break
        put(b, x, top, 'b0'); put(b, x, top + 1, 'b1' if x % 2 else 'b0')
        if x % 2 == 0: put(b, x, top - 1, 'b0')
    # 머리
    hc = [(22 * s, 12 * s, 5 * s), (25 * s, 14 * s, 3.2 * s)]
    head = shade_blob(W, H, hc, ['b1', 'b2', 'b3', 'b4'], 9)
    b.alpha_composite(head)
    # 코
    for y in range(int(13 * s), int(16 * s)):
        for x in range(int(26 * s), int(28 * s)):
            put(b, x, y, 'pk1' if y < 15 * s else 'red1')
    put(b, int(27 * s) - 1, int(14 * s), 'red0')
    # 엄니
    tx, ty = int(24 * s), int(16 * s)
    put(b, tx, ty, 'wht'); put(b, tx + 1, ty, 'wht'); put(b, tx + 1, ty - 1, 'wht')
    if s > 1.2: put(b, tx + 2, ty - 1, 'wht'); put(b, tx + 2, ty - 2, 'wht'); put(b, tx, ty + 1, 'p2')
    # 눈 (화나면 빨강)
    ex, ey = int(22 * s), int(10 * s)
    put(b, ex, ey, 'red2' if phase in (2, 3) else 'ink'); put(b, ex + 1, ey, 'ink')
    put(b, ex - 1, ey - 1, 'ink'); put(b, ex, ey - 1, 'ink')
    # 귀
    put(b, int(20 * s), int(6 * s), 'b1'); put(b, int(21 * s), int(5 * s), 'b0'); put(b, int(20 * s), int(7 * s), 'b2')
    # 꼬리
    put(b, int(3 * s), int(9 * s), 'b1'); put(b, int(2 * s), int(8 * s), 'b1')
    if phase == 4:
        px = b.load()
        for y in range(H):
            for x in range(W):
                if px[x, y][3]: px[x, y] = PAL['wht']
    if s > 1.2:  # 대왕: 이마의 달 무늬와 이끼 등
        for (x, y) in ((22, 8), (23, 8), (22, 9)):
            put(b, int(x * s), int(y * s), 'y2')
        for x in range(int(8 * s), int(17 * s), 3):
            put(b, x, int(4.5 * s), 'g3'); put(b, x + 1, int(4.5 * s) - 1, 'g4')
    im.alpha_composite(outline(b))
    return im

def slash(phase):
    """오른쪽으로 휘두르는 호. 32×32, 가운데가 캐릭터."""
    W = 32
    im = img(W, W)
    a0, a1 = {0: (-100, -40), 1: (-80, 40), 2: (-20, 80)}[phase]
    for y in range(W):
        for x in range(W):
            dx, dy = x + 0.5 - 16, y + 0.5 - 16
            r = math.hypot(dx, dy); a = math.degrees(math.atan2(dy, dx))
            if a0 <= a <= a1 and 8 < r < 15:
                t = (a - a0) / (a1 - a0)
                edge = r > 13 - t * 2
                c = 'wht' if (edge and t > 0.3) else ('y2' if t > 0.55 else ('f2' if t > 0.25 else None))
                if r < 10 and t < 0.6: c = None
                if c: put(im, x, y, c)
    return im

def spark(phase):
    im = img(16, 16)
    L = [3, 6, 5, 2][phase]
    for k in range(-L, L + 1):
        c = 'wht' if abs(k) < 2 else 'y2'
        put(im, 8 + k, 8, c); put(im, 8, 8 + k, c)
        if phase > 0 and abs(k) < L - 1: put(im, 8 + k, 8 + k, 'y1') if abs(k) % 2 else None; put(im, 8 + k, 8 - k, 'y1') if abs(k) % 2 else None
    return im

def puff(phase):
    im = img(16, 16)
    r = [3, 5, 6, 6.5, 6][phase]
    for y in range(16):
        for x in range(16):
            d = math.hypot(x + 0.5 - 8, y + 0.5 - 8)
            if r - 2.2 < d < r and (x * 3 + y * 5 + phase) % (2 + phase) != 0:
                put(im, x, y, 's4' if d < r - 1 else 's3')
    return im

def dust(phase):
    im = img(8, 8)
    r = [1.5, 2.5, 3, 2][phase]
    for y in range(8):
        for x in range(8):
            if math.hypot(x + 0.5 - 4, y + 0.5 - 5) < r: put(im, x, y, 'd4' if y < 5 else 'd3')
    return im if phase < 3 else im

def coin(phase):
    im = img(8, 8)
    w = [3, 2, 1, 2][phase]
    for y in range(1, 7):
        for x in range(4 - w, 4 + w):
            c = 'y1' if x < 4 else 'or2'
            if y == 1 or x == 4 - w: c = 'y2'
            if y == 6: c = 'or1'
            put(im, x, y, c)
    if w == 3:
        put(im, 3, 3, 'b1'); put(im, 4, 3, 'b1'); put(im, 3, 4, 'b1'); put(im, 4, 4, 'b1')  # 엽전 구멍
    return outline(im)

def heart(kind):
    """kind 0 가득 / 1 반 / 2 빈칸 (UI) — 9×8"""
    rows = [".oo.oo..", "orrorro.", "orrrrro.", "orrrrro.", ".orrro..", "..oro...", "...o...."]
    im = img(9, 8)
    for y, r in enumerate(rows):
        for x, ch in enumerate(r):
            if ch == 'o': put(im, x, y, 'ink')
            elif ch == 'r':
                full = kind == 0 or (kind == 1 and x < 4)
                put(im, x, y, ('red2' if not (y == 1 and x in (1, 4)) else 'red3') if full else 'ink2')
    return im

def fireball(phase):
    im = img(8, 8)
    for y in range(8):
        for x in range(8):
            d = math.hypot(x + 0.5 - 4, y + 0.5 - 4)
            if d < 3.4 - phase * 0.4:
                put(im, x, y, 'f3' if d < 1.3 else ('f2' if d < 2.4 else 'f1'))
    return im

def moonshard():
    """달빛 조각(퀘스트 물건)."""
    im = img(12, 12)
    for y in range(12):
        for x in range(12):
            u, v = x + 0.5 - 6, y + 0.5 - 6
            if abs(u) + abs(v) * 0.7 < 4.5:
                put(im, x, y, 'y2' if u + v < -1 else ('y1' if u + v < 2 else 'or2'))
    put(im, 4, 4, 'wht')
    return outline(im)

def ui_box():
    """대화창 9조각 (24×24, 가장자리 8)."""
    im = img(24, 24)
    for y in range(24):
        for x in range(24):
            e = min(x, y, 23 - x, 23 - y)
            if e == 0 and (x in (0, 23)) and (y in (0, 23)): continue
            c = 'ink' if e == 0 else ('p3' if e == 1 else ('p1' if e == 2 else 'p2'))
            if e >= 3: c = 'p3' if (x + y) % 2 else 'p2'
            if e >= 3: c = 'p3'
            put(im, x, y, c)
    for (x, y) in ((2, 2), (21, 2), (2, 21), (21, 21)): put(im, x, y, 'red1')
    return im
