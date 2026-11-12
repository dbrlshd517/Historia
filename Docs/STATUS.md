# STATUS — Historia

## 지금
- 2026-11-12 **TASK_거시연결 U0·U1 끝** (사람 11-12: U0·U1 만 — U2 부터는 headless 연속이동 N3·땅객체 L3 끝난 뒤).
  - 모듈 `HistoriaCore` = core 손잡이 `FHisMacroCore`(HISTORIACORE_API) 하나만 내보냄 — headless 코드엔 DLL 내보내기 표시가 없어 게임 모듈이 core 를 직접 부를 수 없음. 링크 길은 `Config/HisCore.json` `link_mode`(prebuilt ⓐ / source ⓑ), headless 자리 = 짝 폴더(`../Playheadless{sub}`, 환경 변수 `HISTORIA_HEADLESS` 우선).
  - U1: `UHisMacroSubsystem`(불러오기·날 진행) · 시험 `His.CoreHash`(시드 4471 · 10 년, 같은 빌드의 historia_run 을 돌려 해시 견줌) — **ⓐ·ⓑ 둘 다 해시 같음** `f5e95bdb6e84918a…` (headless 3801268, 그 폴더의 안 올린 변경 포함).
  - 지금 설정 = ⓐ(prebuilt). 처음 한 번 `Tools\his_core_lib.bat` → 언리얼 빌드.
  - 창 없이: `UnrealEditor-Cmd Historia.uproject -nullrhi -unattended -ExecCmds="Automation RunTests His.CoreHash;Quit"`

## U0 링크 길 견줌 (2026-11-12, 같은 PC — 다른 세션 빌드가 같이 돌아 시간은 ±30%)

| | ⓐ 미리 빌드한 lib (`Tools/his_core_lib.bat`) | ⓑ UBT 가 headless 소스 직접 컴파일 (`HistoriaCore` 모듈) |
|---|---|---|
| 처음 빌드 | CMake 설정 21 s + 빌드 297 s(VS 생성기는 파일 단위 병렬 아님) + 언리얼 56 s | 언리얼 57 s (UBA 병렬, 파일 96개) |
| core 한 파일 고친 뒤 | 스크립트 73 s + 언리얼 5 s ≈ **78 s** (사람/세션이 스크립트를 먼저 돌려야 함) | **8 s** (언리얼 빌드만 — 저절로 따라옴) |
| C++20 · 예외·RTTI · /utf-8 · CRT | headless 설정 그대로(core·setting 예외 끔, tools·bake 예외 켬) · Release = /MD = 언리얼 CRT. 맞춤 수고 0 | 모듈 하나라 파일마다 설정 못 함 → 예외 모듈 전체 켬 · RTTI 끔 · 묶음 빌드 끔(파일마다 익명 이름공간) · PCH 끔 · 경고 몇 개 끔. 언리얼 컴파일 옵션으로 돌아도 **해시 같음** |
| 언리얼 기호·매크로와 겹침 | zlib 등 링크 충돌 없음(miniz 는 mz_ 이름). 매크로 `check`·`verify`·`ensure` 가 core 이름과 겹침 → 감싸는 헤더에서 풂(둘 다 같음) | 같음 |
| 디버그 심볼 | core lib 은 Release(심볼 없음) — core 안으로 디버거가 못 들어감(RelWithDebInfo 로 바꾸면 됨) | 언리얼 PDB 에 core 전부 — 언리얼 안에서 core 디버깅 됨 |
| 패키징 | lib 파일만 있으면 됨(headless 폴더 없어도) — 대신 lib 이 어느 커밋인지 `headless_commit.txt` 로만 앎 | 패키징 PC 에 headless 폴더 + FetchContent 바깥 소스(miniz·yyjson·stb — 지금은 ⓐ 의 CMake 설정이 받아 둔 `Intermediate/HisCore/build/_deps`) 필요 |
| headless 를 고친 뒤 따라오는 수고 | 스크립트 한 번 + 언리얼 빌드. 잊으면 **옛 core 로 조용히 돎**(해시 시험이 historia_run 도 같은 옛 빌드라 못 잡음) | 언리얼 빌드만. 새 .cpp 는 CMakeLists 목록을 읽어 저절로 들어감. 새 바깥 라이브러리(예: 연속이동의 Recast)·파일별 컴파일 옵션이 생기면 `HistoriaCore.Build.cs` 를 고쳐야 함 |
| 깨지는 곳 | headless 가 CMake 로 빌드되면 거의 안 깨짐 | 언리얼 매크로·경고·묶음 빌드와 부딪히는 새 코드가 생기면 언리얼 쪽에서만 깨짐(=일찍 알게 됨) |

덧붙여 본 것:
- 두 길 모두 **headless 메인 폴더가 다른 세션 작업 중**이면 그 순간의 소스·`out/`(gamedata_core.json 을 지우고 다시 씀)을 읽는다 — 시험 한 번이 그 사이에 걸려 '파일 못 엶'으로 실패했다(다시 돌리니 통과).
- 링크 길을 바꾸면 UBT 가 두 번 돌아야 한다(처음 한 번은 Gen 폴더를 규칙 실행 전에 읽어 실패 · 두 번째 통과).
- 언리얼 안 틱 = historia_run 과 같은 빠르기(10 년: 14.6 s vs 14.7 s — 같은 core 빌드).

## 판단 필요
- **U0 링크 길**: 추천 **ⓑ** — 0-1 의 '계속 이어진 채로' 비용이 가장 작다(headless 를 고치면 언리얼 빌드 8 s 만으로 따라오고, 잊고 옛 lib 으로 도는 일이 없음 · 언리얼 컴파일 설정과 부딪히는 코드를 headless 세션이 일찍 알게 됨 · core 디버깅). 값: 예외를 모듈 전체에 켬 · 바깥 라이브러리가 늘면 Build.cs 한 줄씩 · 패키징 때 headless 소스가 있어야 함. ⓐ 는 패키징·마지막 합치기 때 다시 볼 만함. 고르면 `Config/HisCore.json` `link_mode` 만 바꿈(지금 ⓐ).
- 거시 전투 창: PIP / 별도 창 (U4 때).
- `his_check` 를 얼마나 자주 돌릴지 (U6 때).
