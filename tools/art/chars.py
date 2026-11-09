"""캐릭터: 주인공 '마루'와 마을 사람들. 글자 그림을 직접 찍고, 걷기·공격·구르기 칸은 다리·몸을 옮겨 만든다."""
from common import *

FW, FH = 16, 22  # 한 칸 크기 (그림은 20줄, 위 여백 2)

def keys(hair=('hr0', 'hr1', 'hr2'), cloth=('n1', 'n2', 'n3'), band='red2', pants=('p0', 'p2'), skin=('sk0', 'sk1', 'sk2')):
    return {
        'o': 'ink', 'k': hair[0], 'h': hair[1], 'H': hair[2],
        's': skin[2], 'S': skin[1], 'm': skin[0], 'e': 'ink', 'r': 'pk1', 'w': 'wht',
        'C': cloth[0], 'c': cloth[1], 'l': cloth[2], 'b': band, 'B': 'red0',
        'P': pants[0], 'p': pants[1], 'f': 'b0', 'F': 'b1', 'y': 'y1',
    }

DOWN = [
    "......ooo.......",
    ".....okHHo......",
    "...ooohhhhooo...",
    "..ohhhhHHhhhho..",
    "..ohhhHHhhhhho..",
    "..obbbbbbbbbbo..",
    "..ohsshsssshho..",
    "..osssssssssso..",
    "..ossessssesso..",
    "..ossessssesso..",
    "..osrssmmssrso..",
    "...oSssssssSo...",
    "...oCwwccwwCo...",
    "..oCcwcllcwcCo..",
    "..osCccccccCso..",
    "...oobbbbbboo...",
    "....oppppppo....",
    "....opPppPpo....",
    "....oPpoopPo....",
    "....offooffo....",
]
UP = [
    "......ooo.......",
    ".....oHHko......",
    "...ooohhhhooo...",
    "..ohhhhHHhhhho..",
    "..ohhhHHhhhhho..",
    "..obbbbbbbbbbo..",
    "..ohhhhhhhhhho..",
    "..ohhhhhhhhhho..",
    "..okhhhhhhhhko..",
    "..okkhhbbhhkko..",
    "...okkhbbhkko...",
    "...oSkkbBkkSo...",
    "...oCcccccccCo..",
    "..oCcccllcccCo..",
    "..osCccccccCso..",
    "...oobbbbbboo...",
    "....oppppppo....",
    "....opPppPpo....",
    "....oPpoopPo....",
    "....offooffo....",
]
SIDE = [  # 오른쪽을 봄
    "......ooo.......",
    ".....okHHo......",
    "....oohhhhoo....",
    "...ohhhhHHhho...",
    "..ohhhhhHHhhho..",
    "bbobbbbbbbbbbo..",
    ".bohhhhhhshsso..",
    "..ohhhhsssssso..",
    "..okhhssssseso..",
    "..okhSssssseso..",
    "...okSsssrssmo..",
    "....oSssssssoo..",
    "....oCccwwco....",
    "....oCcclcco....",
    "....oCcsccco....",
    "....oobbbbbo....",
    ".....opppPo.....",
    ".....oPppPo.....",
    ".....oPpPpo.....",
    ".....offffo.....",
]

def legs_variant(rows, phase, side=False):
    """걷기 칸: phase 0=서기 1=왼발 앞 2=서기 3=오른발 앞."""
    r = list(rows)
    if phase in (0, 2):
        return r, (1 if phase == 2 else 0)
    if not side:
        if phase == 1:
            r[18] = "....oPpo.oPpo..."[:16]
            r[18] = "....oPpooPpo...."
            r[19] = "....offo.oPPo..."
        else:
            r[19] = "...oPPo.offo...."
    else:
        if phase == 1:
            r[17] = "....oPppPPpo...."
            r[18] = "...oPpo..oPpo..."
            r[19] = "...ofo....offo.."
        else:
            r[17] = ".....oPpPpo....."
            r[18] = ".....oPpPo......"
            r[19] = ".....offfo......"
    return r, 1

def frame_from(rows, k, dy=0, ox=0):
    im = ascii_sprite(rows, k)
    c = img(FW, FH)
    c.alpha_composite(im, (ox, FH - im.height - dy))
    return c

def arm_pose(rows, kind, d):
    """공격 자세: 팔을 앞으로. 칼은 게임 쪽 효과(베기 호)와 함께 따로 그린다."""
    r = list(rows)
    if d == 'down' and kind == 1:
        r[14] = "..oCccccccCo...."; r[15] = "...oobbbbbboo..."; r[16] = "....oppppppo...."
    return r

def character(k, down=DOWN, up=UP, side=SIDE):
    """줄: 0 아래, 1 위, 2 옆(오른쪽). 칸: 0~3 걷기, 4~5 공격(휘두르기), 6 구르기 시작, 7 맞음."""
    out = []
    for d, rows in (('down', down), ('up', up), ('side', side)):
        frames = []
        for ph in range(4):
            rr, bob = legs_variant(rows, ph, d == 'side')
            frames.append(frame_from(rr, k, dy=0 if bob else 0, ox=0))
            if bob:  # 걸을 때 머리가 살짝 내려감
                f = frames[-1]
                g = img(FW, FH); g.alpha_composite(f.crop((0, 0, FW, FH - 4)), (0, 1)); g.alpha_composite(f.crop((0, FH - 4, FW, FH)), (0, FH - 4))
                frames[-1] = g
        # 공격 2칸: 몸이 앞으로 기울고(옆) / 납작(앞뒤)
        a1 = frame_from(rows, k)
        if d == 'side':
            a1 = img(FW, FH); a1.alpha_composite(frame_from(rows, k), (1, 0))
        else:
            a1 = img(FW, FH); a1.alpha_composite(frame_from(rows, k).crop((0, 0, FW, FH - 6)), (0, 1 if d == 'down' else 0)); a1.alpha_composite(frame_from(rows, k).crop((0, FH - 6, FW, FH)), (0, FH - 6))
        a2 = frame_from(legs_variant(rows, 1 if d != 'up' else 3, d == 'side')[0], k)
        if d == 'side':
            b = img(FW, FH); b.alpha_composite(a2, (2, 0)); a2 = b
        frames += [a1, a2]
        # 구르기: 몸을 둥글게 (머리+몸통 작은 공)
        ball = img(FW, FH)
        head = ascii_sprite(rows[:12], k)
        ball.alpha_composite(head, (0, FH - 13))
        sq = ascii_sprite(rows[12:16], k).resize((16, 3), 0)
        ball.alpha_composite(sq, (0, FH - 3))
        frames.append(ball)
        # 맞음: 하얗게 번쩍이는 건 셰이더, 그림은 뒤로 젖힘
        hurt = img(FW, FH); hurt.alpha_composite(frame_from(rows, k), (-1 if d == 'side' else 0, -1))
        frames.append(hurt)
        out += frames
    return sheet(out, FW, FH, cols=8)

# 마을 사람들: 같은 틀에 머리·옷 색만 바꾸고, 앞모습만 두 칸(숨쉬기)
GRANNY = [
    "................",
    "......oooo......",
    "....oossssoo....",
    "...osswwwwsso...",
    "..oswwwwwwwwso..",
    "..owwwHHwwwwwo..",
    "..owsssssssswo..",
    "..osssssssssso..",
    "..osseSssSesso..",
    "..osssssssssso..",
    "..osrssmmssrso..",
    "...oSssssssSo...",
    "...occcwwccco...",
    "..occcclccccco..",
    "..osccccccccso..",
    "..occcccccccco..",
    "..occccccccco...",
    "..oCcccccccCo...",
    "..oCCCCCCCCCo...",
    "...ooffooffo....",
]
SMITH = [
    "................",
    "....oooooooo....",
    "...okkkkkkkko...",
    "..okkhhhhhhkko..",
    "..okhhhhhhhhko..",
    "..obbbbbbbbbbo..",
    "..osssssssssso..",
    "..osssssssssso..",
    "..osseSssSesso..",
    "..ossessssesso..",
    "..oskkkmmkkkso..",
    "...okkkkkkkko...",
    "..oSoCccccCoSo..",
    ".oSsoCcllcCosSo.",
    ".osSoCccccCoSso.",
    "..oooobbbboooo..",
    "....oppppppo....",
    "....opPppPpo....",
    "....oPpoopPo....",
    "....offooffo....",
]
KID = [
    "................",
    "................",
    "................",
    ".....oooooo.....",
    "....ohhhhhho....",
    "...ohhHHhhhho...",
    "..obhhhhhhhhbo..",
    "..obhssshsshbo..",
    "..ohsssssssho...",
    "..ossessssesso..",
    "..ossessssesso..",
    "..osrssmmssrso..",
    "...oSssssssSo...",
    "...occwwwwcco...",
    "..oscclllccso...",
    "...occcccccco...",
    "....oppppppo....",
    "....opPppPpo....",
    "....oPpoopPo....",
    "....offooffo....",
]

def npc(rows, k):
    a = frame_from(rows, k)
    b = img(FW, FH); b.alpha_composite(a.crop((0, 0, FW, FH - 6)), (0, 1)); b.alpha_composite(a.crop((0, FH - 6, FW, FH)), (0, FH - 6))
    return sheet([a, b], FW, FH)

def build():
    hero = character(keys())
    granny = npc(GRANNY, keys(hair=('s1', 's3', 's4'), cloth=('v0', 'v1', 'v2'), skin=('sk0', 'sk1', 'sk2')))
    smith = npc(SMITH, keys(hair=('hr0', 'hr1', 'hr2'), cloth=('b0', 'b1', 'b2'), band='s2', skin=('sk0', 'sk0', 'sk1')))
    kid = npc(KID, keys(hair=('hr1', 'hr2', 'b3'), cloth=('red0', 'red1', 'red3'), band='y1'))
    return hero, granny, smith, kid
