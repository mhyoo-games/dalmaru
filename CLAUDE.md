# 이 저장소에서 작업할 때 지킬 것

심심풀이(mhyoo-games)의 개인 프로젝트 "달마루 모험기". 사용자는 한국어로 대화합니다. 게임 글자도 한국어.

- 게임 화면·크레딧·README에 실명을 넣지 않는다. 만든 사람은 "심심풀이"로 적는다 (사용자 요청).

## 무엇인가

Godot 4(GDScript)로 만드는 탑다운 액션 RPG. 웹으로 내보내 GitHub Pages(`https://mhyoo-games.github.io/dalmaru/`, 조직 mhyoo-games)에 올린다.

## 지킬 것

- 라이선스 화면: `scripts/licenses.gd`가 Godot 엔진(MIT)과 그 안의 라이브러리(`Engine.get_license_text/get_copyright_info/get_license_info`), 갈무리 글꼴 전문(`assets/fonts/OFL.txt`, 내보내기 `include_filter`에 넣음), 그림 출처를 보여 준다. 처음 화면에서 연다. 상업·무료 상관없이 Godot 배포 조건이라 지우지 않는다. 새 에셋을 쓰면 여기 `credits`에도 적는다.
- 옛 PC RPG·온라인 게임에서 영감을 받았지만 **새로 만든 세계관**이다. 다른 게임의 이름·캐릭터·그림·음악·지도를 쓰지 않고, 다른 회사·게임 이름을 README·화면·이력서에 넣지 않는다.
- **그림·소리·지도는 코드로 만든다.** `tools/art/gen.py`(도트 그림), `tools/sound/gen.py`(효과음·배경음), `tools/maps/gen.py`(지도 → `data/maps.json`). 결과 파일을 직접 고치지 말고 생성기를 고친 뒤 다시 돌린다. 글꼴만 예외(갈무리, OFL, `assets/fonts/LICENSE.txt`).
- 규칙(계산)은 `scripts/rules.gd`에 모으고 `tests/run_tests.gd`에 테스트를 더한다. CI(`ci.yml`)가 생성기 재실행 → 테스트 → 켜지는지 → 웹 내보내기 → Pages 배포까지 한다.
- 예전 주소(`minhyuk94.github.io/…`)에서 옮겨 올 때 저장을 받아 넣는 `carry.js`(예전 주소의 안내 페이지가 `#carry=`로 보냄)를 `export_presets.cfg`의 head_include로 읽는다 (CI가 `tools/web/carry.js`를 `build/web`에 복사). 지우지 않는다.
- 큰 기능이 바뀌면 이력서 저장소(minhyuk94.github.io)의 `games` 카드도 ko/ja/en으로 맞춘다. 소스 코드·저장소 링크는 이력서에 넣지 않는다.

## 이 작업 환경에서 돌려 보기

- npm/pip 설치와 github.io 접속이 막혀 있을 수 있다. Godot 실행 파일·웹 템플릿·글꼴은 `godot-bin` 브랜치에 있다 (`.github/workflows/fetch-godot.yml`이 만든다).
  `git fetch origin godot-bin && git show FETCH_HEAD:godot.zip > g.zip` 처럼 꺼내 쓴다.
- 화면 확인: `xvfb-run godot --rendering-driver opengl3 --audio-driver Dummy -- --dev=village --out=/tmp/x`
  (`scripts/dev.gd`가 정해진 순서로 조작하며 화면을 찍는다. 장면: title, village, field, grove, talk, warp, bridge, combat, full(처음부터 엔딩까지))
- 웹 확인: `godot --headless --export-release "Web" build/web/index.html` 후 로컬 http 서버 + headless Chrome(swiftshader).
