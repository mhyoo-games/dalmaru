"""assets/sprites/*.png 를 전부 다시 만든다: python3 tools/art/gen.py"""
import os, sys
sys.path.insert(0, os.path.dirname(__file__))
from common import *
import tiles, objects as O, chars, mobs as M

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
    print('ok', len(os.listdir(OUT)), 'files')

if __name__ == '__main__':
    main()
