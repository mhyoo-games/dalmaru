"""지도를 코드로 짓는다 → data/maps.json
땅(ground): . 풀  P 흙길  S 돌바닥  W 물  D 물 위 나무다리
소품(objects): T 둥근나무 t 둥근나무2 M 단풍 N 소나무 r 바위 R 큰바위 b 덤불(벨 수 있음) B 열매덤불
               g 긴풀(벨 수 있음) w 꽃무더기 O 갈고리 말뚝 Y Z 장승 I 돌기둥 f 울타리 F 울타리기둥 v 세로울타리 l 석등 j 항아리 J 붉은항아리 c 상자 # 막힘
python3 tools/maps/gen.py
"""
import json, math, os, random

class Map:
    def __init__(self, key, name, w, h, music, tint=(1, 1, 1), seed=1, theme=''):
        self.key, self.name, self.w, self.h, self.music, self.tint, self.theme = key, name, w, h, music, tint, theme
        self.g = [['.'] * w for _ in range(h)]
        self.o = [[' '] * w for _ in range(h)]
        self.e = []; self.r = random.Random(seed)
    def fill(self, layer, x0, y0, x1, y1, ch):
        L = self.g if layer == 'g' else self.o
        for y in range(max(0, y0), min(self.h, y1 + 1)):
            for x in range(max(0, x0), min(self.w, x1 + 1)):
                L[y][x] = ch
    def blob(self, layer, cx, cy, rx, ry, ch, jag=0.15):
        L = self.g if layer == 'g' else self.o
        for y in range(self.h):
            for x in range(self.w):
                d = ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2
                if d < 1 - jag * self.r.random(): L[y][x] = ch
    def line(self, layer, pts, ch, width=2):
        for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
            n = max(abs(x1 - x0), abs(y1 - y0))
            for i in range(n + 1):
                x = round(x0 + (x1 - x0) * i / max(1, n)); y = round(y0 + (y1 - y0) * i / max(1, n))
                self.fill(layer, x, y, x + width - 1, y + width - 1, ch)
    def obj(self, x, y, ch, force=False):
        if 0 <= x < self.w and 0 <= y < self.h and (force or (self.o[y][x] == ' ' and self.g[y][x] == '.')):
            self.o[y][x] = ch
    def border(self, kinds='TtN', depth=2, gaps=()):
        for y in range(self.h):
            for x in range(self.w):
                d = min(x, y, self.w - 1 - x, self.h - 1 - y)
                if any(gx0 <= x <= gx1 and gy0 <= y <= gy1 for (gx0, gy0, gx1, gy1) in gaps): continue
                if d < depth:
                    self.o[y][x] = '#' if d == 0 else ' '
                    if (x + y) % 2 == d % 2 or d == 0 and (x + y) % 2:
                        self.o[y][x] = kinds[self.r.randrange(len(kinds))] if d >= 0 else '#'
        for y in range(self.h):
            for x in range(self.w):
                d = min(x, y, self.w - 1 - x, self.h - 1 - y)
                if d == 0 and self.o[y][x] == ' ' and not any(gx0 <= x <= gx1 and gy0 <= y <= gy1 for (gx0, gy0, gx1, gy1) in gaps):
                    self.o[y][x] = '#'
    def scatter(self, ch, n, area=None, near=None):
        x0, y0, x1, y1 = area or (2, 2, self.w - 3, self.h - 3)
        for _ in range(n * 4):
            if n <= 0: break
            x, y = self.r.randint(x0, x1), self.r.randint(y0, y1)
            if self.o[y][x] == ' ' and self.g[y][x] == '.' and not self.near_entity(x, y):
                self.o[y][x] = ch; n -= 1
    def near_entity(self, x, y, d=2):
        for e in self.e:
            ex, ey = e['x'], e['y']; fw = e.get('fw', 1); fh = e.get('fh', 1)
            if ex - d <= x <= ex + fw - 1 + d and ey - fh + 1 - d <= y <= ey + d: return True
        return False
    def ent(self, **kw):
        self.e.append(kw); return kw
    def clear(self, x0, y0, x1, y1):
        self.fill('o', x0, y0, x1, y1, ' ')
    def out(self):
        return {'name': self.name, 'theme': self.theme, 'w': self.w, 'h': self.h, 'music': self.music, 'tint': list(self.tint),
                'ground': [''.join(r) for r in self.g], 'objects': [''.join(r) for r in self.o], 'entities': self.e}

def village():
    m = Map('village', '달마루 마을', 44, 30, 'village', (1.0, 0.92, 0.86), seed=3)
    # 길과 마당
    m.blob('g', 21, 15, 5, 3.6, 'S', 0.05)
    m.line('g', [(21, 8), (21, 12)], 'P')
    m.line('g', [(9, 9), (21, 9)], 'P'); m.line('g', [(9, 8), (9, 9)], 'P')
    m.line('g', [(30, 8), (30, 12)], 'P'); m.line('g', [(21, 9), (30, 9)], 'P')
    m.line('g', [(27, 15), (43, 15)], 'P')
    m.line('g', [(9, 21), (21, 21), (21, 18)], 'P'); m.line('g', [(9, 20), (9, 21)], 'P')
    m.blob('g', 34, 23, 5.5, 3.5, 'W', 0.1)
    m.border('TtNTM', 3, gaps=[(41, 14, 43, 17)])
    # 집 (x,y = 왼쪽 아래 칸, fw/fh = 차지하는 칸)
    m.ent(type='house', sprite='hanok_big', x=6, y=7, fw=6, fh=4, door=[9, 7], name='촌장 댁')
    m.ent(type='house', sprite='hanok', x=28, y=7, fw=5, fh=4, door=[30, 7], name='대장간')
    m.ent(type='house', sprite='hanok', x=7, y=19, fw=5, fh=4, door=[9, 19], name='마루네 집')
    m.ent(type='well', x=21, y=15, fw=2, fh=2)
    m.ent(type='sign', x=38, y=13, text='→ 솔바람 들판\n달샘이 마른 뒤로 도깨비불이 자주 보인다. 조심!')
    m.ent(type='sign', x=13, y=20, text='마루네 집')
    m.ent(type='npc', id='granny', sprite='npc_granny', x=13, y=10, name='촌장 할머니')
    m.ent(type='npc', id='smith', sprite='npc_smith', x=33, y=10, name='대장장이 쇠돌')
    m.ent(type='npc', id='kid', sprite='npc_kid', x=25, y=18, name='꼬마 별이', wander=3)
    m.ent(type='player', x=10, y=21)
    m.ent(type='waystone', x=24, y=19)
    m.ent(type='warp', x=43, y=14, w=1, h=3, to='field', tx=2, ty=21)
    for (x, y) in ((16, 12), (26, 12), (16, 18), (26, 18)): m.obj(x, y, 'l', True)
    for (x, y, c) in ((13, 7, 'j'), (14, 7, 'J'), (27, 7, 'c'), (26, 7, 'c'), (34, 7, 'j'), (12, 19, 'J'), (6, 20, 'c')):
        m.obj(x, y, c, True)
    # 밭과 울타리
    m.fill('o', 4, 24, 14, 24, 'f'); m.obj(4, 24, 'F', True); m.obj(14, 24, 'F', True)
    for x in range(5, 14, 2): m.obj(x, 26, 'g', True)
    for _ in range(14): m.obj(m.r.randint(4, 40), m.r.randint(4, 26), 'w')
    m.scatter('B', 4, (4, 11, 18, 17)); m.scatter('b', 8); m.scatter('g', 10); m.scatter('M', 3, (28, 18, 40, 27)); m.scatter('r', 4)
    return m

def field():
    m = Map('field', '솔바람 들판', 64, 44, 'field', (1, 1, 1), seed=7)
    m.line('g', [(0, 21), (14, 21), (22, 16), (36, 16), (46, 22), (56, 22)], 'P', 2)
    m.line('g', [(22, 16), (22, 6), (30, 4)], 'P', 2)
    m.line('g', [(36, 16), (40, 30), (34, 38)], 'P', 2)
    m.line('g', [(56, 22), (62, 22)], 'P', 2)
    m.blob('g', 13, 33, 8, 6, 'W', 0.12); m.blob('g', 48, 8, 6, 4, 'W', 0.1)
    m.blob('g', 13, 33, 2.2, 1.6, '.', 0)  # 연못 가운데 작은 섬
    m.border('NTtN', 3, gaps=[(0, 20, 2, 23), (61, 20, 63, 24)])
    # 바위 담과 숲 덩어리
    for (cx, cy, rx, ry, ch) in ((30, 28, 4, 3, 'N'), (52, 34, 5, 4, 'T'), (8, 8, 4, 3, 't'), (40, 6, 3, 2, 'N')):
        for y in range(cy - ry, cy + ry + 1):
            for x in range(cx - rx, cx + rx + 1):
                if ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 < 1 and (x + y) % 2 == 0: m.obj(x, y, ch)
    m.ent(type='warp', x=0, y=20, w=1, h=4, to='village', tx=42, ty=15)
    m.ent(type='warp', x=63, y=20, w=1, h=5, to='grove', tx=2, ty=12, need='shards')
    m.ent(type='sign', x=58, y=20, text='→ 숲지기의 빈터\n달빛 조각 셋이 모여야 길이 열린다고 한다.')
    m.ent(type='sign', x=4, y=19, text='← 달마루 마을')
    m.ent(type='waystone', x=5, y=24)
    # 섬으로 가는 말뚝 (다리 말고 밧줄로도)
    m.obj(12, 32, 'O', True); m.obj(13, 27, 'O', True)
    # 달빛 조각 셋: 상자 / 도깨비불 무리 / 연못 섬
    m.ent(type='chest', id='chest_n', x=30, y=3, item='shard')
    m.ent(type='chest', id='chest_coin', x=8, y=12, item='coins20')
    m.ent(type='shard', id='shard_island', x=13, y=33)
    m.ent(type='camp', id='camp_wisp', x=48, y=30, kinds=['wisp', 'wisp', 'wisp', 'mushroom'], reward='shard')
    # 적
    for (x, y, k) in ((18, 24, 'mushroom'), (26, 22, 'mushroom'), (28, 12, 'mushroom'), (35, 10, 'wisp'), (44, 18, 'boar'),
                      (52, 14, 'mushroom'), (24, 34, 'boar'), (40, 36, 'mushroom'), (56, 28, 'wisp'), (16, 12, 'mushroom'), (8, 26, 'mushroom')):
        m.ent(type='enemy', kind=k, x=x, y=y)
    for (cx, cy, rx, ry) in ((26, 26, 4, 2.5), (44, 12, 3, 2), (8, 30, 3, 3), (54, 40, 4, 2), (36, 34, 3, 2)):
        for y in range(int(cy - ry), int(cy + ry) + 1):
            for x in range(int(cx - rx), int(cx + rx) + 1):
                if ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 < 1 and m.r.random() < 0.7: m.obj(x, y, 'g' if (x * 3 + y) % 4 else 'w')
    for (cx, cy) in ((18, 10), (40, 26), (50, 18), (10, 40), (30, 40)):
        for _ in range(9): m.obj(cx + m.r.randint(-3, 3), cy + m.r.randint(-2, 2), 'w')
    m.scatter('g', 40); m.scatter('b', 26); m.scatter('B', 6); m.scatter('r', 14); m.scatter('R', 5); m.scatter('M', 6); m.scatter('T', 10)
    m.clear(12, 32, 14, 34)
    # 연못 섬으로 건너가는 나무다리 (D: 물 위 다리, 지나갈 수 있음)
    for x in range(14, m.w):
        if m.g[33][x] == 'W': m.g[33][x] = 'D'; m.o[33][x] = ' '
        elif x > 16: break
    for x in range(22, 25): m.o[33][x] = ' '
    return m

def grove():
    m = Map('grove', '숲지기의 빈터', 32, 24, 'boss', (0.86, 0.9, 1.0), seed=11)
    m.blob('g', 17, 12, 10, 7, 'P', 0.08)
    m.blob('g', 17, 12, 3, 2, 'S', 0)
    m.line('g', [(0, 12), (8, 12)], 'P', 2)
    m.line('g', [(24, 12), (31, 12)], 'P', 2)
    m.border('NNTt', 4, gaps=[(0, 11, 4, 14), (27, 11, 31, 14)])
    m.ent(type='warp', x=0, y=11, w=1, h=4, to='field', tx=61, ty=22)
    m.ent(type='warp', x=31, y=11, w=1, h=4, to='ferry', tx=2, ty=18, need='flag:boss_down')
    m.ent(type='boss', kind='boar', x=22, y=12)
    m.ent(type='spring', x=17, y=12, boss='boar')
    m.scatter('g', 6, (6, 4, 28, 20)); m.scatter('r', 4, (6, 4, 28, 20))
    return m

def river_cross(m, x0, x1, y, mid):
    """강(x0~x1)을 말뚝으로 건너게: 양쪽 물가와 가운데 섬에 말뚝."""
    m.fill('g', mid - 1, y - 1, mid + 1, y + 1, '.'); m.clear(mid - 1, y - 1, mid + 1, y + 1)
    m.obj(x0 - 1, y, 'O', True); m.obj(mid, y, 'O', True); m.obj(x1 + 1, y, 'O', True)
    for x in (x0 - 2, x0 - 1, x1 + 1, x1 + 2):
        m.fill('g', x, y - 1, x, y + 1, '.')
    m.clear(x0 - 2, y - 1, x0 - 2, y + 1); m.clear(x1 + 2, y - 1, x1 + 2, y + 1)

def ferry():
    m = Map('ferry', '물안개 나루', 64, 40, 'ferry', (0.9, 1.0, 0.92), seed=21, theme='swamp')
    m.line('g', [(0, 18), (16, 18)], 'P', 2); m.line('g', [(31, 18), (44, 14), (56, 19), (63, 19)], 'P', 2)
    m.fill('g', 20, 0, 27, m.h - 1, 'W')
    for y in range(m.h):
        if (y * 7) % 5 == 0: m.g[y][20] = '.'; m.g[y][27] = '.'
    m.blob('g', 34, 6, 5, 3.5, 'W', 0.1); m.blob('g', 34, 6, 1.6, 1.2, '.', 0)
    m.blob('g', 50, 32, 6, 3, 'W', 0.1)
    m.border('NTtN', 3, gaps=[(0, 17, 2, 20), (61, 18, 63, 21)])
    river_cross(m, 20, 27, 18, 23)
    river_cross(m, 20, 27, 31, 24)
    m.ent(type='warp', x=0, y=17, w=1, h=4, to='grove', tx=29, ty=12)
    m.ent(type='warp', x=63, y=18, w=1, h=4, to='lake', tx=2, ty=13, need='item:pearl')
    m.ent(type='waystone', x=5, y=15)
    m.ent(type='npc', id='ferry', sprite='npc_ferry', x=9, y=16, name='뱃사공 노인')
    m.ent(type='sign', x=17, y=16, text='→ 강 건너기\n옛 말뚝이 박혀 있다. 밧줄(C)을 던져 보자.')
    m.ent(type='sign', x=58, y=17, text='→ 이무기 소\n물방울 구슬 셋을 가져온 이만 지나가라.')
    m.ent(type='pearl', id='pearl_reeds', x=40, y=28)
    m.ent(type='pearl', id='pearl_rock', x=35, y=6)
    m.ent(type='camp', id='camp_toad', x=46, y=8, kinds=['toad', 'toad', 'toad', 'wisp'], reward='pearl')
    for (x, y, k) in ((10, 26, 'toad'), (12, 10, 'mushroom'), (34, 22, 'toad'), (40, 14, 'wisp'), (52, 24, 'toad'), (30, 34, 'mushroom'), (56, 12, 'boar'), (8, 32, 'toad')):
        m.ent(type='enemy', kind=k, x=x, y=y)
    for (x0, y0) in ((36, 26), (42, 30), (30, 12)):
        for _ in range(12): m.obj(x0 + m.r.randint(-3, 3), y0 + m.r.randint(-2, 2), 'g')
    m.scatter('g', 40); m.scatter('b', 20); m.scatter('r', 10); m.scatter('T', 12); m.scatter('w', 10)
    m.clear(39, 27, 41, 29); m.clear(33, 5, 35, 7)
    m.obj(34, 6, 'O', True); m.fill('g', 33, 11, 35, 11, '.'); m.clear(33, 11, 35, 12); m.obj(34, 11, 'O', True)  # 바위섬 말뚝
    return m

def lake():
    m = Map('lake', '이무기 소', 36, 26, 'boss', (0.85, 0.95, 0.9), seed=23, theme='swamp')
    m.blob('g', 18, 13, 9.5, 6.5, 'W', 0.06)
    m.line('g', [(0, 13), (5, 13)], 'P', 2); m.line('g', [(30, 13), (35, 13)], 'P', 2)
    m.border('NTt', 3, gaps=[(0, 12, 3, 15), (32, 12, 35, 15)])
    m.ent(type='warp', x=0, y=12, w=1, h=4, to='ferry', tx=61, ty=19)
    m.ent(type='warp', x=35, y=12, w=1, h=4, to='peak', tx=2, ty=30, need='flag:boss_serpent')
    m.ent(type='boss', kind='serpent', x=18, y=13, lake=[9, 7, 19, 13])
    m.scatter('g', 8, (3, 3, 32, 22)); m.scatter('r', 4, (3, 3, 32, 22))
    return m

def peak():
    m = Map('peak', '서리봉 고개', 64, 44, 'peak', (0.92, 0.96, 1.05), seed=31, theme='snow')
    m.line('g', [(0, 30), (14, 30), (20, 22), (34, 22), (42, 12), (54, 12), (63, 12)], 'P', 2)
    m.line('g', [(34, 22), (40, 34), (50, 36)], 'P', 2)
    # 얼음 틈 (물): 북서쪽 낭떠러지
    m.fill('g', 3, 1, 32, 10, 'W')
    m.fill('g', 12, 3, 20, 5, '.')
    m.border('NNN', 3, gaps=[(0, 29, 2, 32), (61, 11, 63, 14)])
    m.clear(3, 1, 32, 10)
    m.fill('g', 15, 11, 17, 12, '.'); m.clear(15, 11, 17, 12); m.obj(16, 11, 'O', True); m.obj(16, 5, 'O', True)
    m.ent(type='warp', x=0, y=29, w=1, h=4, to='lake', tx=33, ty=13)
    m.ent(type='warp', x=63, y=11, w=1, h=4, to='cave', tx=2, ty=12, need='item:ember')
    m.ent(type='waystone', x=5, y=33)
    m.ent(type='npc', id='ranger', sprite='npc_ranger', x=9, y=28, name='산지기 할아범')
    m.ent(type='sign', x=58, y=10, text='→ 얼음굴\n불씨 돌 셋이 없으면 얼어 버린다.')
    m.ent(type='ember', id='ember_cliff', x=16, y=4)
    m.ent(type='camp', id='camp_imp', x=48, y=34, kinds=['snowimp', 'snowimp', 'frostblob', 'frostblob'], reward='ember')
    for x in range(52, 60, 2): m.obj(x, 24, 'Y' if x % 4 else 'Z', True)
    m.ent(type='chest', id='chest_jang', x=56, y=22, item='ember')
    for (x, y, k) in ((20, 26, 'frostblob'), (28, 18, 'snowimp'), (38, 26, 'frostblob'), (46, 16, 'snowimp'), (10, 36, 'frostblob'), (30, 36, 'boar'), (56, 30, 'frostblob')):
        m.ent(type='enemy', kind=k, x=x, y=y)
    m.scatter('N', 30); m.scatter('r', 16); m.scatter('R', 6); m.scatter('b', 10)
    m.clear(55, 21, 57, 23)
    return m

def cave():
    m = Map('cave', '얼음굴', 34, 24, 'boss', (0.85, 0.9, 1.05), seed=33, theme='snow')
    m.blob('g', 17, 12, 11, 7.5, 'S', 0.08)
    m.line('g', [(0, 12), (6, 12)], 'P', 2); m.line('g', [(28, 12), (33, 12)], 'P', 2)
    m.border('rRN', 4, gaps=[(0, 11, 4, 14), (30, 11, 33, 14)])
    m.ent(type='warp', x=0, y=11, w=1, h=4, to='peak', tx=61, ty=12)
    m.ent(type='warp', x=33, y=11, w=1, h=4, to='ruins', tx=2, ty=20, need='flag:boss_bear')
    m.ent(type='boss', kind='bear', x=21, y=12)
    m.scatter('r', 5, (6, 5, 28, 19))
    return m

def ruins():
    m = Map('ruins', '달그림자 성터', 64, 42, 'ruins', (0.82, 0.8, 1.0), seed=41, theme='night')
    m.line('g', [(0, 20), (16, 20), (24, 14), (40, 14), (48, 22), (63, 22)], 'P', 2)
    m.line('g', [(24, 14), (24, 32), (40, 34)], 'P', 2)
    m.blob('g', 21, 25, 8, 6, 'S', 0.1); m.blob('g', 46, 32, 7, 5, 'S', 0.1)
    # 해자 (물) + 무너진 다리 → 말뚝
    m.fill('g', 30, 1, 50, 11, 'W')
    m.border('TtN', 3, gaps=[(0, 19, 2, 22), (61, 21, 63, 24)])
    m.clear(30, 1, 50, 11)
    m.fill('g', 38, 5, 46, 8, '.'); m.fill('g', 32, 5, 34, 7, '.')
    m.fill('g', 26, 5, 29, 7, '.'); m.clear(26, 5, 29, 7)
    m.obj(28, 6, 'O', True); m.obj(33, 6, 'O', True); m.obj(38, 6, 'O', True)
    m.ent(type='warp', x=0, y=19, w=1, h=4, to='cave', tx=31, ty=12)
    m.ent(type='warp', x=63, y=21, w=1, h=4, to='throne', tx=2, ty=13, need='item:gloom')
    m.ent(type='waystone', x=5, y=23)
    m.ent(type='npc', id='moon', sprite='npc_moon', x=9, y=18, name='달님 아씨')
    m.ent(type='gloom', id='gloom_bridge', x=42, y=6)
    m.ent(type='camp', id='camp_shade', x=46, y=32, kinds=['shade', 'shade', 'wisp', 'wisp'], reward='gloom')
    m.ent(type='chest', id='chest_ruin', x=12, y=34, item='gloom')
    for x in (10, 14): m.obj(x, 33, 'Y' if x == 10 else 'Z', True)
    for (x, y) in ((16, 22), (26, 22), (16, 28), (26, 28), (40, 30), (52, 30), (40, 36), (52, 36)):
        m.obj(x, y, 'I' if (x + y) % 3 else 'l', True)
    for (x, y, k) in ((20, 10, 'shade'), (30, 18, 'wisp'), (44, 18, 'shade'), (12, 28, 'wisp'), (34, 30, 'shade'), (56, 14, 'boar'), (54, 28, 'wisp')):
        m.ent(type='enemy', kind=k, x=x, y=y)
    m.scatter('I', 10); m.scatter('r', 10); m.scatter('g', 20); m.scatter('T', 8)
    m.clear(11, 33, 13, 35); m.obj(10, 33, 'Y', True); m.obj(14, 33, 'Z', True)
    return m

def throne():
    m = Map('throne', '옛 궁터', 36, 26, 'boss', (0.8, 0.78, 1.0), seed=43, theme='night')
    m.blob('g', 18, 13, 12, 8, 'S', 0.05)
    m.line('g', [(0, 13), (6, 13)], 'P', 2)
    m.border('ItN', 4, gaps=[(0, 12, 4, 15)])
    for (x, y) in ((9, 8), (27, 8), (9, 18), (27, 18)): m.obj(x, y, 'l', True)
    m.ent(type='warp', x=0, y=12, w=1, h=4, to='ruins', tx=61, ty=22)
    m.ent(type='boss', kind='king', x=24, y=13)
    m.ent(type='npc', id='moon', sprite='npc_moon', x=6, y=10, name='달님 아씨')
    return m

if __name__ == '__main__':
    data = {mm.key: mm.out() for mm in (village(), field(), grove(), ferry(), lake(), peak(), cave(), ruins(), throne())}
    p = os.path.join(os.path.dirname(__file__), '..', '..', 'data', 'maps.json')
    json.dump(data, open(p, 'w'), ensure_ascii=False, indent=1)
    for k, v in data.items():
        print(k); print('\n'.join(a + '  ' + b for a, b in zip(v['ground'], v['objects'])))
