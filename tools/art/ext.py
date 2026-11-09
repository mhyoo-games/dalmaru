"""2~4장과 주인공 셋을 위한 그림: 소리·돌쇠, 지역별 색 바꾸기, 말뚝·장승·이정표, 새 적과 대왕들."""
import math, random
from common import *
from objects import shade_blob
import chars as C
import mobs as M

# ── 주인공 둘 더 ──
def sori():
    """활을 쓰는 소리: 긴 머리 꼬리, 초록 저고리."""
    down = list(C.DOWN); up = list(C.UP); side = list(C.SIDE)
    down[1] = "......oHHo......"; up[1] = "......oHHo......"
    up[10] = "...okkhhhhkko..."; up[11] = "...oSkkhhkkSo..."
    side[5] = "..obbbbbbbbbbo.."; side[6] = "hhohhhhhhshsso.."; side[7] = ".hhhhhhsssssso.."
    k = C.keys(hair=('hr1', 'hr2', 'b2'), cloth=('g0', 'g1', 'g3'), band='pk1', pants=('p0', 'p1'))
    return C.character(k, down, up, side)

def dolsoe():
    """방망이를 쓰는 돌쇠: 짧은 머리, 노란 띠, 갈색 옷, 몸집이 크다."""
    down = list(C.DOWN); up = list(C.UP); side = list(C.SIDE)
    down[0] = down[1] = "................"; up[0] = up[1] = "................"; side[0] = side[1] = "................"
    down[13] = ".oCcwcllcwcCo..."[:0] + "..oCcwcllcwcCo.."
    down[14] = ".osCccccccccCso."[:16]
    k = C.keys(hair=('hr0', 'hr0', 'hr1'), cloth=('b0', 'b1', 'b2'), band='y1', pants=('d1', 'd2'), skin=('sk0', 'sk0', 'sk1'))
    return C.character(k, down, up, side)

# ── 지역별 색 바꾸기 ──
THEMES = {
    'swamp': {'g0': 'o0', 'g1': 'o1', 'g2': 'o2', 'g3': 'o3', 'g4': 'o4', 'g5': 'o5',
              'w0': 'm0', 'w1': 'm1', 'w2': 'm2', 'w3': 'm3', 'w4': 'm4',
              'd1': 'b0', 'd2': 'b1', 'd3': 'b2', 'd4': 'b3', 'red2': 'v2', 'or1': 'v1', 'or2': 'v2', 'y1': 'v3'},
    'snow': {'g0': 's1', 'g1': 's2', 'g2': 's3', 'g3': 's4', 'g4': 'wht', 'g5': 'wht',
             'd1': 's1', 'd2': 'n3', 'd3': 's3', 'd4': 's4', 'w1': 'n1', 'w2': 'n3', 'w3': 'f2', 'w4': 'f3',
             'red0': 's1', 'red1': 's2', 'red2': 's3', 'or1': 's3', 'or2': 's4', 'y1': 'wht', 'y2': 'wht'},
    'night': {'g0': 'ink', 'g1': 'r0', 'g2': 'r1', 'g3': 'r2', 'g4': 'r3', 'g5': 's2',
              'd1': 's0', 'd2': 's1', 'd3': 's2', 'd4': 's3', 'w0': 'ink', 'w1': 'v0', 'w2': 'v1', 'w3': 'v2', 'w4': 'v3',
              'red0': 'v0', 'red1': 'v1', 'red2': 'v2', 'or1': 'v2', 'or2': 'v3', 'y1': 'f2', 'y2': 'f3'},
}

def remap(im, theme):
    m = {PAL[a][:3]: PAL[b] for a, b in THEMES[theme].items()}
    out = im.copy(); px = out.load()
    for y in range(out.height):
        for x in range(out.width):
            c = px[x, y]
            if c[3] and c[:3] in m: px[x, y] = m[c[:3]][:3] + (c[3],)
    return out

def snowcap(im):
    """나무 위쪽에 눈을 얹는다."""
    out = im.copy(); px = out.load()
    for x in range(out.width):
        for y in range(out.height):
            if px[x, y][3] and px[x, y][:3] != PAL['ink2'][:3]:
                for k in range(3):
                    if y + k < out.height and px[x, y + k][3] and px[x, y + k][:3] != PAL['ink2'][:3]:
                        px[x, y + k] = PAL['wht'] if k < 2 else PAL['s4']
                break
    return out

# ── 소품 ──
def post():
    """갈고리 말뚝: 쇠고리가 달린 나무 기둥."""
    im = img(16, 24)
    for x in range(4, 12): put(im, x, 23, 'shadow')
    for y in range(6, 23):
        for x in range(6, 10): put(im, x, y, ('b3', 'b2', 'b2', 'b1')[x - 6])
    for x in range(5, 11): put(im, x, 6, 'b4'); put(im, x, 7, 'b2')
    for (x, y) in ((7, 1), (8, 1), (6, 2), (9, 2), (6, 3), (9, 3), (7, 4), (8, 4)): put(im, x, y, 's3')
    put(im, 7, 5, 's2'); put(im, 8, 5, 's2')
    for y in (11, 16): 
        for x in range(6, 10): put(im, x, y, 'b0')
    return outline(im)

def jangseung(kind=0):
    """장승: 마을 어귀를 지키는 나무 기둥 얼굴."""
    im = img(16, 34)
    for x in range(3, 13): put(im, x, 33, 'shadow')
    for y in range(2, 33):
        for x in range(4, 12):
            c = ('b3', 'b3', 'b2', 'b2', 'b2', 'b2', 'b1', 'b1')[x - 4]
            put(im, x, y, c)
    for x in range(3, 13): put(im, x, 2, 'r1' if kind == 0 else 'red1'); put(im, x, 3, 'r2' if kind == 0 else 'red2')
    for x in range(5, 11): put(im, x, 1, 'r1' if kind == 0 else 'red1')
    for (x, y) in ((5, 8), (6, 8), (9, 8), (10, 8), (6, 10), (9, 10)): put(im, x, y, 'ink')
    put(im, 5, 7, 'ink'); put(im, 10, 7, 'ink')
    for x in range(7, 9):
        for y in range(10, 14): put(im, x, y, 'b4' if x == 7 else 'b3')
    for x in range(5, 11): put(im, x, 16, 'ink')
    for x in (6, 8, 10): put(im, x, 17, 'wht')
    for y in range(20, 31, 2):
        for x in range(6, 10): put(im, x, y, 'b1')
    return outline(im)

def waystone():
    """달빛 이정표: 열어 둔 곳으로 데려다주는 돌."""
    im = img(16, 26)
    for x in range(2, 14): put(im, x, 25, 'shadow')
    b = shade_blob(16, 25, [(8, 15, 6.5), (8, 9, 5)], ['s0', 's1', 's2', 's3'], 4)
    for (x, y) in ((7, 9), (8, 9), (9, 10), (9, 11), (9, 12), (8, 13), (7, 13), (8, 10), (8, 12)): put(b, x, y, 'y2')
    im.alpha_composite(outline(b))
    return im

def pillar():
    """무너진 돌기둥 (성터)."""
    im = img(16, 32)
    for x in range(2, 14): put(im, x, 31, 'shadow')
    for y in range(8, 31):
        for x in range(4, 12): put(im, x, y, ('s3', 's2', 's2', 's2', 's2', 's1', 's1', 's0')[x - 4])
    for x in range(3, 13): put(im, x, 28, 's3'); put(im, x, 29, 's1'); put(im, x, 30, 's1')
    for (x, y) in ((4, 8), (5, 7), (6, 8), (7, 6), (8, 7), (9, 5), (10, 7), (11, 8)): put(im, x, y, 's3')
    for (x, y) in ((6, 14), (7, 15), (7, 16), (8, 17), (9, 21), (9, 22)): put(im, x, y, 's0')
    for (x, y) in ((5, 12), (5, 13), (10, 19), (10, 20)): put(im, x, y, 'g2')
    return outline(im)

# ── 새 적 ──
def toad(phase):
    W, H = 16, 16
    im = img(W, H)
    for x in range(3, 13): put(im, x, 15, 'shadow')
    sy = {0: 1.0, 1: 0.92, 2: 0.78, 3: 1.12}[phase]
    b = shade_blob(W, H, [(8, 15 - 5 * sy, 6 * (2 - sy) * 0.55), (8, 15 - 3.5 * sy, 6.5)], ['g0', 'g1', 'g2', 'g3'], 3)
    px = b.load()
    for y in range(H):
        for x in range(W):
            if px[x, y][3] and y > 15 - 3 * sy: px[x, y] = PAL['y1'] if 4 < x < 12 else px[x, y]
    ey = int(15 - 8 * sy)
    for ex in (4, 11):
        for dx in (0, 1):
            put(b, ex + dx - (1 if ex > 8 else 0), ey, 'wht'); put(b, ex + dx - (1 if ex > 8 else 0), ey - 1, 'g3')
        put(b, ex - (0 if ex < 8 else 1) + (1 if ex < 8 else 0), ey, 'ink')
    for x in range(6, 10): put(b, x, ey + 3, 'g0')
    for (x, y) in ((5, ey + 5), (10, ey + 4)): put(b, x, y, 'g4')
    im.alpha_composite(outline(b))
    return im

def snowimp(phase):
    W, H = 16, 20
    im = img(W, H)
    for x in range(4, 12): put(im, x, 19, 'shadow')
    bob = [0, 1, 0, -1][phase]
    b = shade_blob(W, H, [(8, 12 + bob, 5.5), (8, 8 + bob, 4.5)], ['s2', 's3', 's4', 'wht'], 8)
    # 뿔
    for k in range(4): put(b, 8, 3 + bob - k + 1, 'f2' if k < 3 else 'f3')
    put(b, 7, 4 + bob, 'f1')
    for ex in (6, 10): put(b, ex, 9 + bob, 'n0'); put(b, ex, 10 + bob, 'n0')
    put(b, 7, 12 + bob, 'red1'); put(b, 8, 12 + bob, 'red1'); put(b, 9, 12 + bob, 'red1')
    put(b, 8, 13 + bob, 'wht')
    for (x, y) in ((3, 12), (12, 12)): put(b, x, y + bob + (1 if phase % 2 else 0), 's3')
    im.alpha_composite(outline(b, 'n0'))
    return im

def frostblob(phase):
    W, H = 16, 16
    im = img(W, H)
    for x in range(3, 13): put(im, x, 15, 'shadow')
    sy = [1.0, 0.9, 0.8, 1.1][phase]
    b = shade_blob(W, H, [(8, 15 - 5 * sy, 6.5 / sy ** 0.5)], ['n1', 'n2', 'n3', 'f2', 'f3'], 5)
    ey = int(15 - 6 * sy)
    for ex in (6, 10): put(b, ex, ey, 'n0'); put(b, ex, ey + 1, 'n0')
    put(b, 5, ey - 2, 'wht'); put(b, 6, ey - 3, 'wht')
    im.alpha_composite(outline(b, 'n0'))
    return im

def shade(phase):
    """그림자 도깨비: 보랏빛 몸에 노란 눈, 뿔 둘."""
    W, H = 16, 22
    im = img(W, H)
    for x in range(4, 12): put(im, x, 21, (20, 10, 30, 110))
    b = img(W, H)
    t = phase * math.pi / 2
    for y in range(4, 21):
        for x in range(W):
            u = (x + 0.5 - 8) / 5.5; v = (y + 0.5 - 12) / 8
            wob = math.sin(y * 0.8 + t) * 0.12 if y > 15 else 0
            if u * u * (1.2 if y > 15 else 1) + v * v < 1 and abs(u + wob) < 1:
                if y > 18 and (x + phase) % 3 == 0: continue
                put(b, x, y, 'v0' if u > 0.4 else ('v1' if u > -0.3 else 'v2'))
    for (hx, s) in ((5, -1), (11, 1)):
        put(b, hx, 4, 'p2'); put(b, hx + s, 3, 'p2'); put(b, hx + s, 2, 'p3')
    for ex in (6, 10): put(b, ex, 10, 'y1'); put(b, ex, 11, 'y2')
    for x in range(6, 11): put(b, x, 14, 'ink')
    put(b, 7, 15, 'wht'); put(b, 9, 15, 'wht')
    im.alpha_composite(outline(b, 'ink'))
    return im

def ball(kind, phase):
    im = img(8, 8)
    pal = {'snow': ['s3', 's4', 'wht'], 'water': ['w1', 'w3', 'w4'], 'dark': ['v0', 'v2', 'v3']}[kind]
    for y in range(8):
        for x in range(8):
            d = math.hypot(x + 0.5 - 4, y + 0.5 - 4)
            if d < 3.4 - phase * 0.4: put(im, x, y, pal[2] if d < 1.3 else (pal[1] if d < 2.4 else pal[0]))
    return im

# ── 대왕들 ──
def serpent_head(phase):
    """이무기 머리 (오른쪽을 봄). phase 1은 입을 벌림."""
    W, H = 36, 30
    im = img(W, H)
    b = shade_blob(W, H, [(16, 15, 11), (25, 16, 8), (30, 17, 5)], ['n0', 'w1', 'w2', 'w3'], 7)
    px = b.load()
    for y in range(H):
        for x in range(W):
            if px[x, y][3] and y > 18: px[x, y] = PAL['p2'] if (x + y) % 3 else PAL['p1']
    if phase == 1:
        for y in range(19, 25):
            for x in range(22, 35):
                if (x - 22) > (y - 19) * 1.5: put(b, x, y, 'red0' if y > 20 else 'red1')
        for x in range(24, 34, 3): put(b, x, 19, 'wht'); put(b, x, 24, 'wht')
    # 눈과 수염, 작은 뿔
    put(b, 24, 11, 'y2'); put(b, 25, 11, 'y1'); put(b, 24, 12, 'ink'); put(b, 25, 12, 'ink')
    for k in range(6): put(b, 30 + k, 21 + k // 2, 'y1')
    for k in range(5): put(b, 14 - k, 5 - k // 2, 'p3'); put(b, 19 - k, 4 - k // 2, 'p2')
    for (x, y) in ((10, 12), (14, 9), (8, 17), (13, 15)): put(b, x, y, 'f2')
    im.alpha_composite(outline(b, 'ink'))
    return im

def serpent_body(phase):
    W = 20
    im = img(W, W)
    b = shade_blob(W, W, [(10, 10, 8.5)], ['n0', 'w1', 'w2', 'w3'], 2 + phase)
    px = b.load()
    for y in range(W):
        for x in range(W):
            if px[x, y][3] and y > 13: px[x, y] = PAL['p1']
    put(b, 7, 6, 'f2'); put(b, 12, 8, 'f2')
    for x in range(6, 15, 4): put(b, x, 3, 'n3')
    im.alpha_composite(outline(b, 'ink'))
    return im

def bear(phase):
    """서리곰: 0,1 걷기 / 2 일어섬 / 3 내리침"""
    W, H = 52, 48
    im = img(W, H)
    for y in range(43, 48):
        for x in range(6, 46):
            if ((x - 26) / 20) ** 2 + ((y - 45.5) / 2.4) ** 2 < 1: put(im, x, y, 'shadow')
    lift = {0: 0, 1: 1, 2: 8, 3: -2}[phase]
    pal = ['s1', 's2', 's3', 's4', 'wht']
    b = img(W, H)
    for (lx, o) in ((14, 0), (20, 1), (32, 1), (38, 0)):
        off = (1 if (o + phase) % 2 else -1) if phase < 2 else 0
        for y in range(34, 45):
            for x in range(lx + off, lx + off + 6): put(b, x, y, 's2' if x < lx + off + 3 else 's1')
        for x in range(lx + off, lx + off + 6): put(b, x, 44, 'n0')
    body = shade_blob(W, H, [(26, 28 - lift * 0.5, 15), (18, 30, 10), (34, 30, 10)], pal, 6)
    b.alpha_composite(body)
    head = shade_blob(W, H, [(40, 20 - lift, 9), (46, 23 - lift, 5)], pal, 9)
    b.alpha_composite(head)
    for (ex, ey) in ((35, 11 - lift), (43, 12 - lift)):
        for dx in range(-2, 3):
            for dy in range(-2, 2):
                if dx * dx + dy * dy < 5: put(b, ex + dx, ey + dy, 's3' if dy < 0 else 's2')
        put(b, ex, ey, 'n2')
    put(b, 49, 22 - lift, 'n0'); put(b, 50, 22 - lift, 'n0')
    put(b, 41, 18 - lift, 'f2'); put(b, 42, 18 - lift, 'n0')
    if phase == 3:
        for x in range(46, 51): put(b, x, 26 - lift, 'red1')
    # 등의 얼음 가시
    for i, x in enumerate(range(14, 34, 5)):
        for k in range(5 + i % 2 * 2):
            put(b, x + k // 3, 14 - k - lift // 2 + (i % 2), 'f2' if k < 4 else 'f3')
    im.alpha_composite(outline(b, 'n0'))
    return im

def king(phase):
    """달그림자 도깨비왕: 큰 뿔, 금빛 눈, 방망이. 0,1 숨 / 2 방망이 듦 / 3 내리침"""
    W, H = 48, 56
    im = img(W, H)
    for y in range(51, 56):
        for x in range(8, 40):
            if ((x - 24) / 16) ** 2 + ((y - 53.5) / 2.4) ** 2 < 1: put(im, x, y, 'shadow')
    b = img(W, H)
    bob = [0, 1, 0, 2][phase]
    # 다리
    for lx in (16, 27):
        for y in range(42, 53):
            for x in range(lx, lx + 6): put(b, x, y, 'v1' if x < lx + 3 else 'v0')
        for x in range(lx - 1, lx + 7): put(b, x, 52, 'ink')
    # 호랑이 무늬 허리띠와 몸
    body = shade_blob(W, H, [(24, 32 + bob, 13), (24, 24 + bob, 11)], ['v0', 'v1', 'v2', 'v3'], 12)
    b.alpha_composite(body)
    for x in range(12, 37):
        for y in range(38 + bob, 43 + bob):
            if b.getpixel((x, y))[3]: put(b, x, y, 'y1' if (x // 3 + y) % 3 else 'ink')
    head = shade_blob(W, H, [(24, 14 + bob, 9)], ['v0', 'v1', 'v2', 'v3'], 3)
    b.alpha_composite(head)
    for (hx, s) in ((17, -1), (31, 1)):
        for k in range(8):
            put(b, hx + s * (k // 2), 7 + bob - k, 'p3' if k > 4 else 'p2')
            put(b, hx + s * (k // 2) + s, 7 + bob - k, 'p1')
    for ex in (20, 28):
        put(b, ex, 13 + bob, 'y2'); put(b, ex + 1, 13 + bob, 'y1'); put(b, ex, 14 + bob, 'y1'); put(b, ex + 1, 14 + bob, 'or1')
    put(b, 19, 11 + bob, 'ink'); put(b, 20, 11 + bob, 'ink'); put(b, 28, 11 + bob, 'ink'); put(b, 29, 11 + bob, 'ink')
    for x in range(20, 29): put(b, x, 18 + bob, 'ink')
    for x in (21, 27): put(b, x, 19 + bob, 'wht'); put(b, x, 20 + bob, 'wht')
    # 팔과 방망이
    arm_y = {0: 28, 1: 28, 2: 12, 3: 38}[phase] + bob
    for k in range(9):
        put(b, 37 + k // 3, 26 + bob + (arm_y - 26 - bob) * k // 9, 'v2'); put(b, 38 + k // 3, 26 + bob + (arm_y - 26 - bob) * k // 9, 'v1')
    cx, cy = 41, arm_y
    for dy in range(-10, 3) if phase != 3 else range(-2, 11):
        w = 2 + (abs(dy) // 4 if phase != 3 else dy // 4)
        for dx in range(-w, w + 1):
            put(b, cx + dx, cy + dy, 'b2' if dx < 0 else 'b1')
    for k in range(3):
        put(b, cx - 2 + k * 2, cy + (-8 if phase != 3 else 8), 's3')
    im.alpha_composite(outline(b, 'ink'))
    return im
