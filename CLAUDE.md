# 이 저장소에서 작업할 때 지킬 것

유민혁(minhyuk94)의 개인 프로젝트 "달마루 모험기". 사용자는 한국어로 대화합니다. 게임 글자도 한국어.

## 무엇인가

Godot 4(GDScript)로 만드는 탑다운 액션 RPG. 웹으로 내보내 GitHub Pages(`https://minhyuk94.github.io/dalmaru/`)에 올린다.

## 지킬 것

- 옛 PC RPG·온라인 게임에서 영감을 받았지만 **새로 만든 세계관**이다. 다른 게임의 이름·캐릭터·그림·음악·지도를 쓰지 않고, 다른 회사·게임 이름을 README·화면·이력서에 넣지 않는다.
- **그림·소리·지도는 코드로 만든다.** `tools/art/gen.py`(도트 그림), `tools/sound/gen.py`(효과음·배경음), `tools/maps/gen.py`(지도 → `data/maps.json`). 결과 파일을 직접 고치지 말고 생성기를 고친 뒤 다시 돌린다. 글꼴만 예외(갈무리, OFL, `assets/fonts/LICENSE.txt`).
- 규칙(계산)은 `scripts/rules.gd`에 모으고 `tests/run_tests.gd`에 테스트를 더한다. CI(`ci.yml`)가 생성기 재실행 → 테스트 → 켜지는지 → 웹 내보내기 → Pages 배포까지 한다.
- 큰 기능이 바뀌면 이력서 저장소(minhyuk94.github.io)의 `games` 카드도 ko/ja/en으로 맞춘다. 소스 코드·저장소 링크는 이력서에 넣지 않는다.

## 이 작업 환경에서 돌려 보기

- npm/pip 설치와 github.io 접속이 막혀 있을 수 있다. Godot 실행 파일·웹 템플릿·글꼴은 `godot-bin` 브랜치에 있다 (`.github/workflows/fetch-godot.yml`이 만든다).
  `git fetch origin godot-bin && git show FETCH_HEAD:godot.zip > g.zip` 처럼 꺼내 쓴다.
- 화면 확인: `xvfb-run godot --rendering-driver opengl3 --audio-driver Dummy -- --dev=village --out=/tmp/x`
  (`scripts/dev.gd`가 정해진 순서로 조작하며 화면을 찍는다. 장면: title, village, field, grove, talk)
- 웹 확인: `godot --headless --export-release "Web" build/web/index.html` 후 로컬 http 서버 + headless Chrome(swiftshader).
