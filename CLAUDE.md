# CLAUDE.md — Historia (언리얼 5.8 게임 본체)

실시간 대전략 게임(픽션 세계, 500년)의 **게임 본체** 언리얼 프로젝트다. 거시 계산은 다른 저장소 `historia-headless`(C++ core — 규칙·AI·시험은 거기서 짜고 돌린다)이고, 이 프로젝트는 그 core 를 **불러서 3D 화면에 그리고 명령을 넣기만** 한다.
미시 전투 실험장은 또 다른 저장소 `Historiamicrobattle` — 거기와 섞지 않는다(사람 11-11: 미시는 거시 없이 시험하려고 일부러 떼어 둠).
**지금 이 프로젝트의 몫 (사람 11-11)**: 거시·미시는 각자 따로 완성하고 마지막에 합친다. 그때까지 여기는 **얇은 연결판** — 거시 core 가 언리얼 안에서 돈다는 것을 증명하고 그 상태를 지킨다(링크 · 스레드 · 스냅샷 3D 보기 · 거시 전투 보기 · `his_check`). 큰 게임 화면은 만들지 않는다.
**작업 전에 먼저 `git pull`(이 저장소와 historia-headless) — 그다음 `Docs/STATUS.md` 와 지금 TASK(`Docs/TASK_*.md`)를 읽는다. TASK 가 사람의 지시다.** 보고는 한국어로.

## 규칙
1. **거시 규칙을 여기서 다시 짜지 않는다.** 계산은 전부 historia-headless core(`playheadless/core.hpp` Sim 입구). core 소스를 이 저장소에 복사하지 않는다 — 원본은 headless 하나. core 에 필요한 것(조회·스냅샷 필드·명령 표)이 없으면 headless 쪽에 더한다(그 저장소 규칙대로).
2. **코드는 전부 C++ 텍스트** `Source/Historia/`. 화면도 C++(Slate) — 블루프린트에 로직을 두지 않는다. `Content/` 에는 에셋만.
3. **데이터·계수 하드코딩 금지.** 설계 데이터는 headless `Startsetting/out/gamedata_core.json`(엑셀이 원본), 화면 설정은 `Config/*.json`. ID·이름·목록 크기를 코드에 박지 않는다.
4. **core 는 제 스레드, 화면은 스냅샷만.** 게임 스레드에서 Sim 을 직접 만지지 않는다 — 명령은 큐, 그림은 버전 번호 스냅샷.
5. **개체마다 액터 금지.** 성도·부대·떼는 인스턴스 메시(HISM)로 한 번에.
6. **결정성은 core 몫** — 같은 시드·명령이면 해시 = `historia_run`. 화면 쪽은 결정성 안 따짐.
7. 밸런스·설계 판단은 혼자 정하지 않는다 — STATUS '판단 필요'.

## 작업 방식
- **보고 첫 줄** `[<작업 폴더 이름> · <지금 TASK·단계>]`.
- **브랜치·PR 안 만듦. main 에 바로.** 시작 = `git pull --rebase --autostash origin main`(훅이 저절로) · 단계 끝(빌드·시험 됨) = commit → `git pull --rebase origin main` → push. 새 worktree·복사 폴더를 스스로 만들지 않는다.
- headless 를 고칠 때: 사람이 정한 짝 폴더(이 저장소 메인 ↔ headless 메인 `Playheadless`)에서, **내가 고친 파일만** add → commit → `pull --rebase --autostash` → push. headless 의 시험(C3 고정 해시 등)이 그대로인지 확인.
- **시험·대본·스크린샷은 창 없이**(`-RenderOffscreen` · 숫자만은 `-nullrhi`). 찍은 것은 `Shots\<대본>\<때>\`(git 밖) — Claude 는 지우지 않음.
- 빌드: `E:\Epic\UE_5.8\Engine\Build\BatchFiles\Build.bat HistoriaEditor Win64 Development -Project=<절대경로>\Historia.uproject -WaitMutex`. 에디터가 열려 있으면 닫아 달라고 말한다.
- md 는 지금 하는 일만 — TASK 가 끝나면 STATUS 에 한 줄 남기고 TASK 파일은 지움.

## 파일 지도
| 경로 | 역할 |
|---|---|
| `Source/Historia/` | C++ 전부 |
| `Config/` | 엔진 설정 · 화면 설정 json |
| `Content/` | 에셋만 (LFS) |
| `Tools/hooks/` | git 시작·끝 훅 |
| `Docs/STATUS.md` · `Docs/TASK_*.md` | 현황 · 사람의 지시 (지금: `TASK_거시연결.md`) |
