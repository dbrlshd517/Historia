# TASK_거시연결 — 거시 core 를 언리얼에 이어 두고, 계속 이어진 채로 둔다

작업 전에 두 저장소(이 저장소 · historia-headless) `git pull` → 이 저장소 `Docs/STATUS.md` · historia-headless `Startsetting/CLAUDE.md`·`Startsetting/STATUS.md` · `playheadless/core.hpp`(Sim 입구) · `playheadless/viewer/runner.*`(시뮬 스레드 + 스냅샷) · `playheadless/viewer/orders_ui.hpp`(명령 표) · `playheadless/CMakeLists.txt`·`Startsetting/CMakeLists.txt`(정적 라이브러리 셋 · FetchContent miniz 3.0.2·yyjson 0.10.0·stb) 를 읽는다. 이 TASK 가 사람의 지시다.

## 0. 결정 (사람 2026-11-11 — 바꾸지 말 것)

1. **목적 = 연결 길을 지금 뚫어 두는 것. 합치기는 마지막.** 거시(historia-headless)와 미시(Historiamicrobattle)는 **각자 따로 완성**한다 — 시험은 완성본에서 하면 느리고 불리하다. 하지만 거시를 언리얼에 지금 안 이어 두면, 거시가 2D·한 스레드·화면 코드에 기대는 쪽으로 자라서 나중에 붙이기가 어려워진다. 그래서 이 TASK 는 **"거시가 언제든 언리얼에서 돈다"는 것을 지금 증명하고, 그 상태를 계속 지키는 길**을 만든다. 게임 화면을 다 만드는 TASK 가 아니다.
2. **거시 개발·시험은 지금처럼 headless + historia_app(2D)**. 빠른 시험·고정 해시·대량 실행은 거기서. 이 프로젝트는 그것을 대신하지 않는다.
3. **이 프로젝트는 얇게**: core 링크 · core 를 제 스레드에서 돌림 · 스냅샷으로 3D 보기(지도·성도·부대·**거시 전투** — 2D 로는 잘 안 보이는 것) · 최소 조작(속도·멈춤·클릭으로 정보 보기). 고르기·명령 줄·궁정·나무 같은 큰 화면은 **만들지 않는다**(마지막 합치기 때).
4. **거시 규칙을 여기서 다시 짜지 않는다 · core 소스를 복사하지 않는다.** 원본은 headless 하나. 이 프로젝트에 필요한 것(스냅샷 필드 등)이 core 에 없으면 headless 쪽에 더한다.
5. **한 프로세스 · core 는 제 스레드 · 게임 스레드는 스냅샷만**(historia_app Runner 와 같은 모양). 성도·부대·떼 = 인스턴스 메시(HISM).
6. **미시는 이 프로젝트에 안 넣는다.** 미시 진입이 필요하면 지금 길(바깥 프로세스 + LIVE_LINK) — 이번 범위에선 안 해도 됨.
7. **결정성은 core 몫** — 언리얼 안에서 돈 core 의 해시 = `historia_run` 해시(같은 컴퓨터·같은 gamedata).

## 1. 단계 (단계마다 빌드 → 고른 시험 → 창 없이 스크린샷 → 커밋·푸시 → STATUS)

**U0 — 링크 길 고르기**: 둘을 실제로 해 보고 표로 비교 → STATUS '판단 필요'에 추천과 함께. 여기서 멈추고 보고.
- ⓐ headless CMake(MSVC)로 미리 빌드한 정적 라이브러리(`historia_corelib`·`historia_setting`·`historia_bakelib`·yyjson·miniz)를 `ThirdParty/historia_core/lib/Win64/`(git 밖)에 · Build.cs `PublicAdditionalLibraries` · 스크립트 `Tools/his_core_lib.bat`(headless 짝 폴더에서 빌드 → 복사).
- ⓑ UBT 가 headless 소스를 직접 컴파일(별도 모듈 `HistoriaCore` — 소스 경로는 설정으로 headless 폴더를 가리킴, 복사 안 함).
- 표 칸: 처음·core 한 파일 고친 뒤 빌드 시간 · 설정 맞춤(C++20 · 예외·RTTI 끔 · `/utf-8` · Debug/Release CRT 맞춤) · 언리얼 엔진 안 zlib·기타 기호와 겹침 · 디버그 심볼 · 패키징 · **headless 를 고친 뒤 이 프로젝트가 따라오는 수고**(0-1 의 '계속 이어진 채로' 비용).

**U1 — core 를 언리얼 안에서 돌림 (화면 없음)**: 서브시스템 `UHisMacroSubsystem` — `Sim::load(start_state.npz, gamedata_core.json, fields.npz)` → `tick` → `content_hash`. 경로는 설정(`Config` — headless 폴더 자리, 하드코딩 금지). 자동 시험 `His.CoreHash`: 시드 4471 · 10 년 · 해시 = `historia_run --seed 4471 --years 10`. `-nullrhi`.

**U2 — 시뮬 스레드 · 스냅샷 (headless 쪽 고침)**: `playheadless/viewer/runner.*`(Runner·Snapshot — raylib 을 모름)를 headless `playheadless/` 로 옮겨 core 의 일부로 — historia_app 과 언리얼이 같은 Runner 를 씀. headless 쪽: 옮긴 뒤 historia_app 그대로 · C3 해시 그대로 · 짝 폴더(headless 메인)에서 내 파일만 커밋. 언리얼: Runner 를 돌리고 게임 스레드는 버전 번호로 새 스냅샷만 · 속도(멈춤 · 1·10·100 일/초 · 최대).

**U3 — 3D 보기**: `fields.npz` 높이·바다·강 → 땅 메시 · 영토 색 · 성도·무리·부대·야생 떼 = HISM(크기 = 인구·사람 수) · 성도 이름 글자 · 카메라(끌기·휠·가장자리) · 클릭 = 그것의 정보 칸(읽기만). 에셋은 엔진 기본 + 코드 동적 재질 — 꾸미기 안 함. 성능 표: 칸 수 · 인스턴스 수 · 프레임 ms · 스냅샷 복사 ms.

**U4 — 거시 전투 보기 (두 번째 창)**: 교전을 클릭하면 두 번째 창 — 양쪽 편제를 방향 있는 상자(폭 × 깊이, 스냅샷의 편제 자세)로 · 내 편/적 색 + 상태 색(교전·동요·패주·정비) · 맞붙은 짝 선 · 사상 깜박임 · hover 툴팁. 보기만. 별도 SWindow 와 같은 창 PIP 둘 다 스크린샷 → 사람이 고름.

**U5 — 이어진 채로 지키기 (이 TASK 의 끝)**:
- 대본 `-HisCheck`(창 없이): headless 최신을 빌드·링크 → 새 판 100 일 → 해시 = historia_run → 3D 스크린샷 하나 → 교전 있으면 전투 창 스크린샷 → 표(1 년당 ms 언리얼 안 vs historia_run · 프레임 ms). 실패하면 어디서(링크·불러오기·해시·스냅샷) 깨졌는지 한 줄.
- 도구 `Tools/his_check.bat` — 사람이나 세션이 headless 를 크게 고친 뒤 한 번 돌림.
- headless 에 남길 것: **언리얼이 쓰는 core 입구 목록**(`core.hpp` Sim · Runner/Snapshot · 이 프로젝트가 읽는 스냅샷 필드)을 headless `docs/UNREAL_LINK.md` 한 장으로 — headless 세션이 이것을 바꾸면 STATUS '언리얼 연결' 에 적게(headless CLAUDE.md 에 사람이 넣은 규칙).

## 2. 하지 않는 것
- 거시 규칙을 언리얼 C++ 로 다시 짜기 · core 소스 복사.
- 고르기·명령 줄·패널·궁정·나무·가문 화면 (마지막 합치기 때).
- 미시 코드를 이 프로젝트로 가져오기.
- 그림 꾸미기(재질·나무·건물 모양).

## 3. 판단 필요 (끝나면 STATUS 에)
- U0 링크 길 ⓐ/ⓑ 추천.
- 거시 전투 창: PIP / 별도 창.
- `his_check` 를 얼마나 자주 돌릴지(사람이 / headless 세션이 TASK 끝마다).
