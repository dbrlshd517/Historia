# STATUS — Historia

## 지금
- 2026-11-12 **TASK_거시연결 U2 앞 정리 끝 (사람 11-12 지시)**: 링크 길 = **ⓑ**(UBT 가 headless 소스를 모듈 `HistoriaCore` 안에서 직접 컴파일) · headless 를 **고정 커밋 worktree** 로 봄. U2 본 작업(Runner·스냅샷)은 headless 연속이동 N3·땅객체 L3 끝난 뒤.
  - 모듈 `HistoriaCore` = core 손잡이 `FHisMacroCore`(HISTORIACORE_API) 하나만 내보냄 — headless 코드엔 DLL 내보내기 표시가 없어 게임 모듈이 core 를 직접 부를 수 없음.
  - U1: `UHisMacroSubsystem`(불러오기·날 진행) · 시험 `His.CoreHash`(시드 4471 · 10 년) = 같은 고정 커밋의 historia_run 해시 + HisCore.json 기준 해시 둘 다와 견줌.

## 거시 core 고정 (Config/HisCore.json)
- headless 자리 = `E:\Historia\headless-pinned` (`../headless-pinned` — headless 저장소의 worktree, 분리된 HEAD, 사람 11-12 지시로 만듦). headless 메인 폴더(다른 세션 작업 중)는 보지 않음. `Historia_sub*` 도 같은 worktree 를 봄.
- **고정 커밋 `ac1b1eb8cf1c6b24ce411907b276d46d089f6572`** (2026-11-12 headless origin/main — 판단 705 값 pen_crew_kill_chance).
- **기준 해시** (`check_hash`) = `80d4d1f375e1d1a6bb347f17855938b99e4b62edd8c7f2d61b34a765bb04aa83` — headless `ac1b1eb` · 시드 4471 · 10 년(3650 일) · historia_run(MSVC Release) = 언리얼 His.CoreHash(-nullrhi, ⓑ) **같음**. gamedata = 그 커밋 엑셀에서 `historia_import --all --no-log --no-view`.
  - 옛 값 `f5e95bdb…`(U0·U1, headless 메인 폴더 3801268 + 안 올린 변경) = **임시 — 버림**(다시 만들 수 없는 소스).
- 빌드 시간 (같은 PC, 다른 세션 빌드와 같이 돎): `Tools\his_core_build.bat` 처음 370 s(CMake 설정 + historia_run·historia_import + gamedata 변환) · 언리얼 ⓑ 처음부터(Intermediate·Binaries·Gen 지움, Intermediate\HisCore 는 둠) 341 s 한 번에 통과 · 바뀐 것 없을 때 UBT 2 s(0 동작) · headless 파일 하나 touch 뒤 9 s(그 파일만 컴파일) · `Tools\his_build.bat`(바뀐 것 없을 때 빌드 + 해시 시험) 114 s · 해시 시험만 ≈ 90 s · core 한 파일 고친 뒤 언리얼 8 s(U0).

**쓰는 법**
- 처음(또는 고정 커밋을 바꾼 뒤): `Tools\his_core_build.bat` — 고정 worktree 를 CMake 로 빌드(historia_run = 해시 기준, FetchContent 바깥 소스 miniz·yyjson·stb = ⓑ 가 컴파일), gamedata 없으면 만듦. 빌드 폴더 `Intermediate\HisCore\build`.
- 빌드 + 해시 시험 한 줄: `Tools\his_build.bat` (에디터 닫고) — 언리얼 빌드 → `Tools\his_core_hash.bat`.
- Gen(`Source/HistoriaCore/Private/Gen`, git 밖) = `Tools\his_core_gen.bat`(→ `his_core_gen.ps1`)가 headless CMakeLists 목록에서 만듦 — `Historia.uproject` PreBuildSteps(Win64)가 UBT 소스 훑기 전에 부름(UBT 는 그 뒤 폴더 기억을 지움 → 첫 빌드부터 들어감). 내용이 같으면 안 씀 · 실패 = 끝 코드 1. UBT 는 모듈 규칙(Build.cs)을 미리 빌드 단계보다 **먼저** 돌리므로 Build.cs 는 'Gen 이 비었고 PreBuildSteps 도 없음'일 때만 오류. 빌드 로그에 같은 his_core_gen 줄이 두 번 보이면 두 번째는 makefile 에 저장된 옛 로그를 다시 찍은 것(실제로 돈 것 아님). 해시 시험만: `Tools\his_core_hash.bat` (끝 코드 0 = 같음 · 로그 `Saved\Logs\his_corehash.log`).

**고정 커밋 올리는 법**
1. `git -C E:\Historia\headless-pinned fetch origin` → `git -C E:\Historia\headless-pinned checkout --detach <새 커밋>`
2. `del E:\Historia\headless-pinned\Startsetting\out\gamedata_core.json` (엑셀이 바뀌었을 수 있음) → `Tools\his_core_build.bat`
3. `Intermediate\HisCore\build\playheadless\Release\historia_run.exe --root E:\Historia\headless-pinned --seed 4471 --years 10 --no-save --out Intermediate\HisCore\base10` → 해시
4. `Config/HisCore.json` 의 `headless_commit`·`check_hash` 를 새 값으로 → `Tools\his_build.bat` → 같음이면 커밋(STATUS 의 위 두 줄도).
- 새 바깥 라이브러리(예: 연속이동의 Recast)나 파일별 컴파일 옵션이 headless 에 생기면 `Source/HistoriaCore/HistoriaCore.Build.cs` 를 고쳐야 함.

**ⓑ 설정이 HistoriaCore 안에서만인지 (확인 2026-11-12, UBT 응답 파일)**
- 묶음 빌드 끔 · PCH 끔 · 경고 끔 · 예외 켬 = `HistoriaCore.Build.cs` 의 ModuleRules — 모듈 하나에만 걸림. 실제: `Historia` 는 공유 PCH(`SharedPCH.UnrealEd…`)를 씀 · `HistoriaCore` 는 PCH 없음 · RTTI 는 둘 다 `/GR-`.
- 예외 `/EHsc` 는 에디터 빌드에선 **모든 모듈에** 켜짐 — 엔진 규칙(`UEBuildTarget.cs:6184` `bEnableExceptions = bForceEnableExceptions || bCompileAgainstEditor`)이지 HistoriaCore 때문이 아님. 게임(에디터 아닌) 빌드에서는 HistoriaCore 만 켜짐(`Result.bEnableExceptions |= Rules.bEnableExceptions`, 모듈별).
## U0 링크 길 견줌 — 기록 (2026-11-12, ⓑ 로 정함 · 같은 PC — 다른 세션 빌드가 같이 돌아 시간은 ±30%)

| | ⓐ 미리 빌드한 lib (그때 `Tools/his_core_lib.bat` — 지금은 `his_core_build.bat` 로 바뀌어 lib 복사 안 함) | ⓑ UBT 가 headless 소스 직접 컴파일 (`HistoriaCore` 모듈) |
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
- 거시 전투 창: PIP / 별도 창 (U4 때).
- `his_check` 를 얼마나 자주 돌릴지 (U6 때).
