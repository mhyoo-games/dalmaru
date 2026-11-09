"""assets/sprites/*.png 를 전부 다시 만든다: python3 tools/art/gen.py"""
import os, sys
sys.path.insert(0, os.path.dirname(__file__))
from common import *
import tiles, objects as O, chars, mobs as M, ext as X

OUT = os.path.join(os.path.dirname(__file__), '..', '..', 'assets', 'sprites')
os.makedirs(OUT, exist_ok=True)

def save(name, im):
    im.save(os.path.join(OUT, name + '.png'))

def strip(frames):
    w = max(f.width for f in frames); h = max(f.height for f in frames)
    return sheet([pad(f, w, h) for f in frames], w, h)

def main():
    save('tiles', tiles.build())
    hero, granny, smith, kid = chars.build()
    save('hero', hero); save('npc_granny', granny); save('npc_smith', smith); save('npc_kid', kid)
    save('tree_round', O.tree(1)); save('tree_round2', O.tree(4)); save('tree_maple', O.tree(2, 'maple')); save('tree_pine', O.tree(3, 'pine'))
    save('rock', O.rock(1)); save('rock_big', O.rock(2, True)); save('bush', O.bush(1)); save('bush_berry', O.bush(2, True))
    save('fence_h', O.fence('h')); save('fence_post', O.fence('post')); save('fence_v', O.fence('v'))
    save('sign', O.sign()); save('well', O.well()); save('lantern', O.lantern())
    save('bridge', O.bridge()); save('jar', O.jar(0)); save('jar_red', O.jar(1)); save('crate', O.crate())
    save('hanok', O.hanok(72)); save('hanok_big', O.hanok(96, 2))
    save('mushroom', strip([M.mushroom(i) for i in range(4)]))
    save('wisp', strip([M.wisp(i) for i in range(4)]))
    save('boar', strip([M.boar(i) for i in range(4)]))
    save('boss', strip([M.boar(i, 1.8) for i in range(4)]))
    save('spark', strip([M.spark(i) for i in range(4)]))
    save('puff', strip([M.puff(i) for i in range(5)]))
    save('dust', strip([M.dust(i) for i in range(4)]))
    save('coin', strip([M.coin(i) for i in range(4)]))
    save('hearts', strip([M.heart(i) for i in range(3)]))
    save('fireball', strip([M.fireball(i) for i in range(2)]))
    save('moonshard', M.moonshard()); save('ui_box', M.ui_box())
    # 주인공 둘 더
    save('hero_sori', X.sori()); save('hero_dolsoe', X.dolsoe())
    save('npc_ferry', chars.npc(chars.SMITH, chars.keys(hair=('s1', 's2', 's3'), cloth=('n0', 'n1', 'n2'), band='p1', skin=('sk0', 'sk1', 'sk2'))))
    save('npc_ranger', chars.npc(chars.GRANNY, chars.keys(hair=('s2', 's3', 's4'), cloth=('g0', 'g1', 'g2'), skin=('sk0', 'sk0', 'sk1'))))
    save('npc_moon', chars.npc(chars.KID, chars.keys(hair=('y1', 'y2', 'wht'), cloth=('v1', 'v2', 'v3'), band='f2', skin=('sk1', 'sk2', 'sk3'))))
    # 소품·적·대왕
    save('post', X.post()); save('jangseung', X.jangseung(0)); save('jangseung2', X.jangseung(1)); save('waystone', X.waystone()); save('pillar', X.pillar())
    save('toad', strip([X.toad(i) for i in range(4)])); save('snowimp', strip([X.snowimp(i) for i in range(4)]))
    save('frostblob', strip([X.frostblob(i) for i in range(4)])); save('shade', strip([X.shade(i) for i in range(4)]))
    save('snowball', strip([X.ball('snow', i) for i in range(2)])); save('waterball', strip([X.ball('water', i) for i in range(2)])); save('darkball', strip([X.ball('dark', i) for i in range(2)]))
    save('serpent_head', strip([X.serpent_head(i) for i in range(2)])); save('serpent_body', X.serpent_body(0))
    save('bear', strip([X.bear(i) for i in range(4)])); save('king', strip([X.king(i) for i in range(4)]))
    # 장마다 모으는 물건 아이콘: 달빛 조각 색만 바꿈
    ms = M.moonshard()
    for n, m in (('pearl', {'y2': 'f3', 'y1': 'w3', 'or2': 'w2'}), ('ember', {'y2': 'y2', 'y1': 'or2', 'or2': 'red1'}), ('gloom', {'y2': 'v3', 'y1': 'v2', 'or2': 'v1'})):
        X.THEMES['_' + n] = m
        save('item_' + n, X.remap(ms, '_' + n))
        del X.THEMES['_' + n]
    # 지역별 색 (늪·눈·밤)
    base = {'tree_round': O.tree(1), 'tree_round2': O.tree(4), 'tree_maple': O.tree(2, 'maple'), 'tree_pine': O.tree(3, 'pine'),
            'rock': O.rock(1), 'rock_big': O.rock(2, True), 'bush': O.bush(1), 'bush_berry': O.bush(2, True), 'lantern': O.lantern()}
    for th in X.THEMES:
        save('tiles_' + th, X.remap(tiles.build(), th))
        for n, im in base.items():
            r = X.remap(im, th)
            if th == 'snow' and n.startswith('tree'): r = X.snowcap(r)
            save(n + '_' + th, r)
    print('ok', len(os.listdir(OUT)), 'files')

if __name__ == '__main__':
    main()
