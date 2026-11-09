"""효과음·배경음을 코드로 합성해 assets/sfx, assets/music 에 wav로 쓴다.
python3 tools/sound/gen.py   (외부 음원 없음, numpy 없이 표준 라이브러리만)
"""
import math, os, random, struct, wave, array

SR = 22050
ROOT = os.path.join(os.path.dirname(__file__), '..', '..', 'assets')

def write(path, data, sr=SR):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    peak = max(1e-6, max(abs(x) for x in data))
    g = 0.9 / peak if peak > 0.9 else 1.0
    a = array.array('h', (int(max(-1, min(1, x * g)) * 32000) for x in data))
    with wave.open(path, 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(sr); w.writeframes(a.tobytes())

def env(t, a, d, s, r, dur):
    if t < a: return t / a
    if t < a + d: return 1 - (1 - s) * (t - a) / d
    if t < dur - r: return s
    return max(0, s * (dur - t) / r)

def osc(kind, ph):
    p = ph % 1.0
    if kind == 'sin': return math.sin(2 * math.pi * p)
    if kind == 'tri': return 4 * abs(p - 0.5) - 1
    if kind == 'sq': return 1 if p < 0.5 else -1
    if kind == 'pul': return 1 if p < 0.25 else -1
    if kind == 'saw': return 2 * p - 1
    return 0

def tone(dur, f0, f1=None, kind='sq', vol=0.5, a=0.005, d=0.05, s=0.6, r=0.05, vib=0, noise=0):
    n = int(dur * SR); out = []; ph = 0; f1 = f1 or f0; rnd = random.Random(int(f0))
    for i in range(n):
        t = i / SR; k = t / dur
        f = f0 * (f1 / f0) ** k
        if vib: f *= 1 + 0.01 * vib * math.sin(2 * math.pi * 6 * t)
        ph += f / SR
        v = osc(kind, ph) * (1 - noise) + (rnd.random() * 2 - 1) * noise
        out.append(v * vol * env(t, a, d, s, r, dur))
    return out

def noise(dur, vol=0.5, lp=0.5, a=0.002, r=0.1, f_end=None):
    n = int(dur * SR); out = []; y = 0; rnd = random.Random(7)
    for i in range(n):
        t = i / SR
        k = lp if f_end is None else lp + (f_end - lp) * t / dur
        y += (rnd.random() * 2 - 1 - y) * k
        out.append(y * vol * env(t, a, 0.01, 1, r, dur))
    return out

def mix(*parts, offs=None):
    offs = offs or [0] * len(parts)
    n = max(int(o * SR) + len(p) for p, o in zip(parts, offs))
    out = [0.0] * n
    for p, o in zip(parts, offs):
        s = int(o * SR)
        for i, v in enumerate(p): out[s + i] += v
    return out

def seq(notes, kind='sq', vol=0.4, gap=0.0):
    out = []
    for (f, d) in notes:
        out += tone(d, f, kind=kind, vol=vol, r=min(0.05, d * 0.5)) if f else [0.0] * int(d * SR)
    return out

def N(name):
    """음 이름 → 주파수. 예: 'A4', 'C#5'"""
    names = {'C': -9, 'D': -7, 'E': -5, 'F': -4, 'G': -2, 'A': 0, 'B': 2}
    n = names[name[0]]; i = 1
    if name[i] == '#': n += 1; i += 1
    elif name[i] == 'b': n -= 1; i += 1
    o = int(name[i:])
    return 440 * 2 ** ((n + (o - 4) * 12) / 12)

def sfx():
    S = lambda n, d: write(os.path.join(ROOT, 'sfx', n + '.wav'), d)
    S('swing', noise(0.14, 0.5, 0.08, r=0.1, f_end=0.5))
    S('hit', mix(tone(0.09, 220, 80, 'sq', 0.5, r=0.06), noise(0.08, 0.6, 0.6, r=0.06)))
    S('enemy_die', mix(tone(0.28, 600, 90, 'sq', 0.35, r=0.2), noise(0.3, 0.4, 0.3, r=0.25), offs=[0, 0.05]))
    S('coin', mix(tone(0.06, N('B5'), kind='sq', vol=0.3), tone(0.16, N('E6'), kind='sq', vol=0.3, r=0.12), offs=[0, 0.06]))
    S('hurt', mix(tone(0.25, 330, 110, 'saw', 0.5, r=0.15), noise(0.12, 0.3, 0.5)))
    S('roll', noise(0.18, 0.35, 0.05, r=0.12, f_end=0.15))
    S('talk', tone(0.035, 660, 620, 'tri', 0.35, r=0.02))
    S('chest', mix(*[tone(0.12, N(n), kind='pul', vol=0.3, r=0.08) for n in ('C5', 'E5', 'G5', 'C6')], offs=[0, 0.08, 0.16, 0.24]))
    S('shard', mix(*[tone(0.5, N(n), kind='tri', vol=0.35, r=0.4, vib=2) for n in ('E5', 'A5', 'C#6', 'E6', 'A6')], offs=[0, 0.1, 0.2, 0.3, 0.42]))
    S('roar', mix(tone(0.9, 140, 60, 'saw', 0.5, a=0.05, r=0.4, vib=6, noise=0.3), noise(0.9, 0.4, 0.15, a=0.05, r=0.5)))
    S('stomp', mix(tone(0.35, 90, 35, 'sin', 0.9, r=0.3), noise(0.3, 0.6, 0.2, r=0.25)))
    S('warp', tone(0.35, 300, 900, 'tri', 0.35, r=0.2))
    S('select', tone(0.07, 880, kind='sq', vol=0.25, r=0.04))
    S('heal', mix(*[tone(0.15, N(n), kind='tri', vol=0.3, r=0.1) for n in ('G5', 'B5', 'D6')], offs=[0, 0.07, 0.14]))
    S('cut', noise(0.1, 0.4, 0.5, r=0.08, f_end=0.2))
    S('fire', mix(tone(0.2, 500, 900, 'tri', 0.25, r=0.15), noise(0.2, 0.2, 0.3)))
    S('hop', tone(0.08, 200, 400, 'sq', 0.2, r=0.05))

# ── 배경음: 5음계(궁·상·각·치·우) 위주의 짧은 반복곡 ──
def song(bpm, bars, melody, bass, drums, lead='pul', pad=None):
    beat = 60 / bpm; total = bars * 4 * beat
    n = int(total * SR); out = [0.0] * n
    def place(part, at):
        s = int(at * SR)
        for i, v in enumerate(part):
            if s + i < n: out[s + i] += v
            else: out[(s + i) % n] += v  # 반복 이음매가 자연스럽게
    t = 0
    for (f, d) in melody:
        if f: place(tone(d * beat * 0.95, N(f), kind=lead, vol=0.22, a=0.01, d=0.08, s=0.55, r=0.08, vib=1.5), t)
        t += d * beat
    t = 0
    for (f, d) in bass:
        if f: place(tone(d * beat * 0.9, N(f), kind='tri', vol=0.35, r=0.05), t)
        t += d * beat
    if pad:
        t = 0
        for (fs, d) in pad:
            for f in fs: place(tone(d * beat, N(f), kind='sin', vol=0.06, a=0.3, d=0.2, s=0.8, r=0.4), t)
            t += d * beat
    steps = int(total / (beat / 2))
    for i in range(steps):
        ch = drums[i % len(drums)]
        at = i * beat / 2
        if ch == 'k': place(tone(0.12, 120, 45, 'sin', 0.5, r=0.08), at)
        elif ch == 's': place(noise(0.1, 0.22, 0.5, r=0.08), at)
        elif ch == 'h': place(noise(0.03, 0.08, 0.9, r=0.02), at)
    return out

def music():
    M = lambda n, d: write(os.path.join(ROOT, 'music', n + '.wav'), d)
    # 마을: 느긋하고 따뜻하게 (D 궁조)
    mel = [('A4', 1), ('B4', .5), ('D5', .5), ('E5', 1), ('D5', 1), ('B4', 1), ('A4', .5), ('B4', .5), ('A4', 2),
           ('F#4', 1), ('A4', 1), ('B4', 1.5), ('A4', .5), ('F#4', 1), ('E4', 1), ('D4', 2),
           ('A4', 1), ('B4', .5), ('D5', .5), ('E5', 1), ('F#5', 1), ('E5', 1), ('D5', .5), ('B4', .5), ('D5', 2),
           ('E5', 1), ('D5', .5), ('B4', .5), ('A4', 1), ('B4', 1), ('A4', 1), ('F#4', 1), ('D4', 2)]
    bass = [(n, 2) for n in ('D3', 'A2', 'G2', 'A2', 'D3', 'B2', 'G2', 'A2') * 2]
    pad = [(c, 4) for c in (('D4', 'F#4', 'A4'), ('G3', 'B3', 'D4'), ('B3', 'D4', 'F#4'), ('A3', 'D4', 'E4'))] * 2
    M('village', song(84, 8, mel, bass, 'k.h.s.h.k.h.s.hh', lead='tri', pad=pad))
    # 들판: 경쾌하게
    mel = [('E5', .5), ('G5', .5), ('A5', 1), ('G5', .5), ('E5', .5), ('D5', 1), ('E5', .5), ('D5', .5), ('C5', .5), ('A4', .5), ('C5', 2),
           ('D5', .5), ('E5', .5), ('G5', 1), ('E5', .5), ('D5', .5), ('C5', 1), ('D5', .5), ('C5', .5), ('A4', .5), ('G4', .5), ('A4', 2),
           ('E5', .5), ('G5', .5), ('A5', 1), ('C6', .5), ('A5', .5), ('G5', 1), ('A5', .5), ('G5', .5), ('E5', .5), ('D5', .5), ('E5', 2),
           ('G5', 1), ('E5', .5), ('D5', .5), ('C5', 1), ('D5', .5), ('E5', .5), ('A4', 1), ('C5', 1), ('A4', 2)]
    bass = []
    for root in ('A2', 'F2', 'C3', 'G2') * 2:
        bass += [(root, .5), (None, .5), (root, .5), (root, .5)] * 2
    M('field', song(120, 8, mel, bass, 'k.hsk.hsk.hsk.ss', lead='pul'))
    # 대왕: 긴박하게
    mel = [('A4', .5), ('A4', .5), ('C5', .5), ('A4', .5), ('D5', .5), ('C5', .5), ('A4', .5), ('G4', .5)] * 2 + \
          [('E5', 1), ('D5', .5), ('C5', .5), ('D5', 1), ('A4', 1), ('C5', .5), ('D5', .5), ('E5', .5), ('G5', .5), ('A5', 2)] + \
          [('A5', .5), ('G5', .5), ('E5', .5), ('D5', .5), ('E5', .5), ('D5', .5), ('C5', .5), ('A4', .5), ('C5', 1), ('D5', 1), ('A4', 2)]
    bass = []
    for root in ('A2', 'A2', 'F2', 'G2') * 2:
        bass += [(root, .25), (root, .25), (None, .25), (root, .25)] * 4
    M('boss', song(144, 8, mel, bass, 'kskskkskkskskkss', lead='saw'))
    # 나루: 안개 낀 느린 곡 (E 우조 느낌)
    mel = [('E4', 1.5), ('G4', .5), ('A4', 1), ('B4', 1), ('A4', 1.5), ('G4', .5), ('E4', 2),
           ('D4', 1), ('E4', 1), ('G4', 1.5), ('A4', .5), ('G4', 1), ('E4', 1), ('D4', 2),
           ('E4', 1.5), ('G4', .5), ('A4', 1), ('D5', 1), ('B4', 1.5), ('A4', .5), ('G4', 2),
           ('A4', 1), ('G4', .5), ('E4', .5), ('D4', 1), ('E4', 1), ('E4', 4)]
    bass = [(n, 4) for n in ('E2', 'C3', 'D3', 'E2') * 2]
    pad = [(c, 4) for c in (('E3', 'B3', 'G4'), ('C3', 'G3', 'E4'), ('D3', 'A3', 'F#4'), ('E3', 'B3', 'E4'))] * 2
    M('ferry', song(72, 8, mel, bass, 'k...h...k...h.h.', lead='tri', pad=pad))
    # 서리봉: 맑고 차가운 곡
    mel = [('B4', .5), ('D5', .5), ('E5', 1), ('D5', .5), ('B4', .5), ('A4', 1), ('B4', .5), ('A4', .5), ('F#4', .5), ('E4', .5), ('F#4', 2),
           ('A4', .5), ('B4', .5), ('D5', 1), ('E5', .5), ('F#5', .5), ('E5', 1), ('D5', .5), ('B4', .5), ('A4', .5), ('B4', .5), ('B4', 2)] * 2
    bass = []
    for root in ('B2', 'G2', 'D3', 'A2') * 2:
        bass += [(root, 1), (None, .5), (root, .5)] * 2
    M('peak', song(104, 8, mel, bass, 'k.h.s.h.k.hhs.h.', lead='sq'))
    # 성터: 어둡고 낮은 곡
    mel = [('A3', 1), ('C4', 1), ('B3', .5), ('A3', .5), ('E4', 2), ('D4', 1), ('C4', 1), ('B3', 2),
           ('A3', 1), ('C4', 1), ('D4', .5), ('E4', .5), ('F4', 2), ('E4', 1), ('D#4', 1), ('E4', 2)] * 2
    bass = [(n, 2) for n in ('A1', 'A1', 'F1', 'E1') * 4]
    pad = [(c, 4) for c in (('A2', 'E3', 'C4'), ('F2', 'C3', 'A3'), ('D2', 'A2', 'F3'), ('E2', 'B2', 'G#3'))] * 2
    M('ruins', song(80, 8, mel, bass, 'k..hs..hk.k.s..h', lead='saw', pad=pad))
    # 승리 짧은 곡
    write(os.path.join(ROOT, 'music', 'victory.wav'),
          seq([(N('C5'), .15), (N('E5'), .15), (N('G5'), .15), (N('C6'), .45), (N('A5'), .15), (N('C6'), .7)], kind='pul', vol=0.35))

if __name__ == '__main__':
    sfx(); music(); print('ok')
