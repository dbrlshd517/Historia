# Claude Code SessionStart 훅 — 세션을 시작하면 git pull (사람 11-08). 메인 폴더·worktree 둘 다 (origin main 으로 rebase).
import sys as _s; _s.stdout.reconfigure(encoding="utf-8", errors="replace"); _s.stderr.reconfigure(encoding="utf-8", errors="replace")
import subprocess, sys
r = subprocess.run(["git", "pull", "--rebase", "--autostash", "origin", "main"], capture_output=True, text=True, encoding="utf-8", errors="replace")
out = (r.stdout + r.stderr).strip().splitlines()
head = subprocess.run(["git", "log", "-1", "--format=%h %s"], capture_output=True, text=True, encoding="utf-8", errors="replace").stdout.strip()
if r.returncode == 0:
    print(f"[git] 시작 pull 됨 — 지금 {head}")
else:
    print("[git] 시작 pull 실패 — 사람에게 알리고 해결 먼저:\n" + "\n".join(out[-8:]))

# worktree 면 SourceArt · Saved\3DLine · Shots 를 메인 폴더 정션으로 (없을 때만 — 사람 11-09: remote-control 이 worktree 를 저절로 만듦)
sys.exit(0)
