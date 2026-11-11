# Claude Code Stop 훅 — 끝낼 때 안 올린 변경이 있으면 한 번 알려 줌 (사람 11-08). 자동으로 커밋하지 않음(빌드·시험 안 된 것까지 올리지 않게).
import sys as _s; _s.stdout.reconfigure(encoding="utf-8", errors="replace"); _s.stderr.reconfigure(encoding="utf-8", errors="replace")
import json, subprocess, sys
try:
    data = json.load(sys.stdin)
except Exception:
    data = {}
if data.get("stop_hook_active"):
    sys.exit(0)          # 한 번만 — 되풀이 막음
def git(*a):
    return subprocess.run(["git", *a], capture_output=True, text=True, encoding="utf-8", errors="replace").stdout
dirty = [l for l in git("status", "--porcelain", "--untracked-files=no").splitlines() if l.strip()]
ahead = git("rev-list", "--count", "origin/main..HEAD").strip() or "0"
if dirty or ahead != "0":
    sys.stderr.write(
        f"[git] 안 올린 것: 커밋 안 한 파일 {len(dirty)} 개 · push 안 한 커밋 {ahead} 개.\n"
        "이번 단계가 끝났으면(빌드·시험 됨): commit → git pull --rebase origin main → push (worktree 는 git push origin HEAD:main).\n"
        "일부러 안 올리는 거면(중간 · 깨진 빌드 등) 까닭을 사람에게 한 줄로 말하고 끝냄.\n")
    sys.exit(2)
sys.exit(0)
