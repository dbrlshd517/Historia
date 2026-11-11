# TASK_거시연결 — 거시 core 를 언리얼(Historia 프로젝트)에 붙인다 (3D 거시 화면 · 거시 전투 두 번째 창)

작업 전에 두 저장소(이 저장소 · historia-headless) `git pull` → 이 저장소 `Docs/STATUS.md` · historia-headless `Startsetting/CLAUDE.md`·`Startsetting/STATUS.md` · `playheadless/core.hpp`(Sim 입구) · `playheadless/viewer/runner.*`(시뮬 스레드 + 스냅샷 — 지금 historia_app 이 씀) · `playheadless/CMakeLists.txt`·`Startsetting/CMakeLists.txt`(정적 라이브러리 셋 · FetchContent miniz 3.0.2·yyjson 0.10.0·stb) · `docs/microbattle/LIVE_LINK.md` 를 읽는다. 이 TASK 가 사람의 지시다.

## 0. 결정 (사람 2026-11-11 — 바꾸지 말 것)

1. **계산·시험은 headless 에 남는다.** 거시 규칙·수식·AI·고정 해시 시험은 계속 historia-headless 에서 짜고 돌린다(빌드 몇 초 · 수백 년 대량 실행). 언리얼은 core 를 **부르기만** 한다 — 언리얼 쪽에 거시 규칙을 다시 짜지 않는다(복사·재구현 금지 — headless 규칙 4).
2. **화면은 언리얼로 간다.** 거시 지도·고르기·명령 줄·패널은 앞으로 언리얼에서 만든다. `historia_app`(raylib 2D)은 **디버그 도구로만** 남는다 — 새 화면 기능은 언리얼에. (2D 에 이미 있는 것은 지우지 않음 — 비교·디버그용.)
3. **한 프로세스.** core 를 언리얼 모듈에 라이브러리로 링크한다(바깥 프로세스·TCP 아님). core 는 **제 스레드**에서 틱, 언리얼 게임 스레드는 **스냅샷만** 읽고 명령은 큐로 넣는다 — historia_app 의 Runner 와 같은 모양.
4. **저폴리 3D.** 땅 = 칸 높이로 만든 메시 하나, 성도·부대·떼 = 인스턴스 메시(HISM — 개체마다 액터 금지, 규칙 5). 성도 수백~수천에도 프레임이 버텨야 한다.
5. **거시 전투 = 두 번째 창, 보기만.** 블록 전투(거시 `battle_formation` 자세)를 SceneCapture → 별도 SWindow(또는 같은 창 PIP)로 보여 준다. 조작 없음 · 마우스 올리면 툴팁만. 직접 지휘하고 싶으면 지금처럼 미시로 들어간다.
6. **미시는 따로 둔다 (사람 11-11).** `Historiamicrobattle` 은 거시 없이 미시만 시험하는 실험장 — 이 프로젝트에 미시 코드를 복사하지 않는다. 이번 TASK 에서 교전의 미시 진입은 지금 길(historia_app 처럼 미시를 바깥 프로세스로 띄우고 LIVE_LINK TCP)을 그대로 쓴다. 미시를 나중에 이 게임에 어떻게 넣을지(플러그인으로 둘이 같이 쓰기 등)는 판단으로 남긴다.
7. **결정성은 core 몫.** 같은 시드·같은 명령이면 언리얼 안에서 돈 core 의 해시 = `historia_run` 해시. 언리얼 쪽(그림·입력)은 결정성 안 따짐(규칙 6).

## 1. 단계 (단계마다 빌드 → 고른 시험 → 창 없이 스크린샷 → 커밋·푸시 → STATUS)

**U0 — 링크 길 고르기 (재고 표 먼저, 코드 조금)**: 둘을 실제로 해 보고 표로 비교 → STATUS '판단 필요'에 추천과 함께.
- ⓐ headless CMake 로 미리 빌드한 정적 라이브러리(`historia_corelib`·`historia_setting`·`historia_bakelib` + yyjson)를 `ThirdParty/historia_core/lib/Win64/` 에 넣고 Build.cs `PublicAdditionalLibraries` — 언리얼 빌드가 빠름, 대신 core 를 고칠 때마다 lib 다시 빌드(스크립트 `Tools/hmb_core_lib.bat` — headless 같은 자리 폴더에서 빌드·복사).
- ⓑ headless 소스를 UBT 가 직접 컴파일(별도 모듈 `HistoriaCore` — 소스 경로를 headless 폴더로 가리킴, 복사 안 함).
- 표 칸: 처음·고친 뒤 빌드 시간 · MSVC 설정(C++20 `CppStandard` · 예외·RTTI 끔 = core 와 같음 · `/utf-8`) · miniz(headless 3.0.2 — 언리얼 엔진 안 zlib 과 기호 겹침 없는지) · yyjson · stb(bake 가 씀) 기호 · 디버그 심볼 · 언리얼 패키징.
- **복사본을 만들지 않는다**: ThirdParty/historia 의 공용 헤더 복사(battle_rules 등)처럼 core 소스를 이 저장소에 베끼지 않는다 — 어느 길이든 원본은 headless 하나.

**U1 — core 를 언리얼 안에서 돌림 (화면 없음)**: 서브시스템 `UHisMacroSubsystem`(이름 앞머리 `His`) — `Sim::load(start_state.npz, gamedata_core.json, fields.npz)` → `tick(365×N)` → `content_hash`. 자동 시험 `Macro.CoreHash`: 시드 4471 · 10 년 · 언리얼 안 해시 = `historia_run --seed 4471 --years 10` 해시(같은 컴퓨터, 같은 gamedata). 경로는 설정(Config — historia-headless 자리), 하드코딩 금지. `-nullrhi` 로.

**U2 — 시뮬 스레드 · 스냅샷 (headless 쪽 작업 포함)**: historia_app 의 `viewer/runner.*`(Runner·Snapshot — raylib 을 모름)를 **headless `playheadless/` 로 옮겨 core 의 일부로**(예 `playheadless/runner.*`) — historia_app 과 언리얼이 같은 Runner 를 씀(한 곳에 하나). 언리얼은 `FRunnable`/엔진 스레드로 Runner 를 돌리고 게임 스레드는 버전 번호로 새 스냅샷만 집음. 속도 단계(멈춤 · 1·10·100 일/초 · 최대)·저장·불러오기. headless 쪽: 옮긴 뒤 historia_app 그대로 도는지 · 해시 그대로 · 커밋은 headless 같은 자리 폴더에서(내 파일만).

**U3 — 첫 3D 거시 지도**: `fields.npz` 높이·바다·강 → 땅 메시(ProceduralMesh — 칸 하나 = 꼭짓점 하나부터) · 영토 색(스냅샷 owner — 플레이어 시점이면 view 안개) · 성도·무리·부대·야생 떼 = HISM 인스턴스(크기 = 인구·사람 수) · 성도 이름 글자 · 카메라(끌기·휠·가장자리 — 토탈워 지도식). 새 .uasset 은 최소로(엔진 기본 재질 + 코드로 동적 재질) — 그림 꾸미기는 다음 TASK. 성능 표: 칸 수 · 인스턴스 수 · 프레임 ms · 게임 스레드 스냅샷 복사 ms.

**U4 — 고르기 · 패널 · 명령 줄 (TASK_거시_선택명령 그대로 옮김)**: headless 의 선택 종류·명령 표(종류 → 단추 · `validate` 이유 → 회색 + 툴팁)는 **headless 쪽 표 하나**를 읽는다 — 표가 지금 `viewer/orders_ui.hpp` 에 있으면 core 쪽으로 옮겨 둘 다 씀. 언리얼은 Slate 로 그 표를 그림. 이번 범위: 클릭 고르기(겹친 칸 돌기) · 오른쪽 패널(부대·성도·땅·교전) · 명령 줄 · 우클릭 이동 · 위 막대(날짜·속도·부·식량). 궁정·기술 나무·가문 창 같은 큰 창은 다음 TASK.

**U5 — 거시 전투 두 번째 창 (0-5)**: 교전을 고르면(또는 단추) 두 번째 창 — 그 교전의 양쪽 편제를 블록(방향 있는 상자, 폭 × 깊이)으로 · 내 편/적 색 + 상태 색(교전·동요·패주·정비) · 맞붙은 짝 선 · 사상 깜박임 · hover 툴팁(세력·편제·사람/편성·사기·피로·행동·상대). 데이터 = 스냅샷 교전의 편제 자세(headless A3b 가 더한 것). 창 닫아도 전투는 계속(거시가 계산). 같은 창 PIP 와 별도 SWindow 둘 다 되는지 확인하고 사람에게 스크린샷 둘.

**U6 — 확인**: 창 없이(`-RenderOffscreen`) 대본 — 새 판 → 100 일 → 성도 고르기 → 부대 이동 명령 → 교전 → 두 번째 창 스크린샷 `Shots\macro\<때>\`. 표: 1 년당 ms(언리얼 안 vs historia_run) · 게임 스레드 프레임 ms · 해시 같음. 사람 확인 목록.

## 2. 하지 않는 것
- 거시 규칙을 언리얼 C++ 로 다시 짜기 · core 소스 복사.
- 미시 코드를 이 프로젝트로 가져오기(0-6) · 궁정·나무·가문·외교 큰 창(다음 TASK).
- 거시 전투 창에서 조작(0-5).

## 3. 판단 필요 (끝나면 STATUS 에)
- U0 링크 길 ⓐ/ⓑ 추천.
- 3D 거시 화면 겉모양(땅 색·성도 모양·글자 크기) — 스크린샷 보고 사람이.
- 두 번째 창: PIP / 별도 창.
- historia_app 을 언제까지 유지할지(디버그 창 목록).
- 미시를 이 게임에 넣는 길(0-6) — 미시가 자리 잡은 뒤.
