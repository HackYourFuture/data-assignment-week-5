#!/usr/bin/env bash
# Week 5 autograder: static analysis only (no Docker or Azure required in CI).
# Each level adds points toward 100; passing score is 60.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
score=0
details=()

pass() { details+=("PASS: $1"); }
fail() { details+=("FAIL: $1"); }
warn() { details+=("WARN: $1"); }

# ── Level 1 (15 pts): required files exist ──────────────────────────────────
l1=0
for f in Dockerfile "src/pipeline.py" "tests/test_pipeline.py" "AI_ASSIST.md"; do
  if [[ -f "$REPO_ROOT/$f" ]]; then
    ((l1 += 3))
  else
    fail "missing $f"
  fi
done
# ci.yml
if ls "$REPO_ROOT/.github/workflows/"*.yml 2>/dev/null | grep -q .; then
  ((l1 += 2))
else
  fail "missing .github/workflows/*.yml"
fi
# requirements.txt or pyproject.toml
if [[ -f "$REPO_ROOT/requirements.txt" ]] || [[ -f "$REPO_ROOT/pyproject.toml" ]]; then
  ((l1 += 1))
else
  fail "missing requirements.txt or pyproject.toml"
fi
((score += l1))
pass "Level 1: required files ($l1/15 pts)"

# ── .gitignore hygiene (0 pts, warnings only) ────────────────────────────────
gi="$REPO_ROOT/.gitignore"
if [[ ! -f "$gi" ]]; then
  warn ".gitignore is missing — add one so __pycache__/ and *.pyc are not committed"
else
  if ! grep -q "__pycache__" "$gi"; then
    warn ".gitignore is missing __pycache__/ — Python cache dirs should not be committed"
  fi
  if ! grep -q "\*.pyc" "$gi"; then
    warn ".gitignore is missing *.pyc — compiled Python files should not be committed"
  fi
  if ! grep -q "\.env" "$gi"; then
    warn ".gitignore is missing .env — secret files should not be committed"
  fi
  if grep -qE "^__pycache__/$" "$gi" && grep -qE "^\*\.pyc$" "$gi" && grep -qE "^\.env$" "$gi"; then
    pass ".gitignore correctly excludes __pycache__/, *.pyc, and .env"
  fi
fi

# ── Level 2 (15 pts): Dockerfile correctness ────────────────────────────────
l2=0
df="$REPO_ROOT/Dockerfile"
if [[ -f "$df" ]]; then
  if grep -qiE "^FROM\s+python:3\.11" "$df"; then
    ((l2 += 5)); pass "Dockerfile uses python:3.11 base image"
  else
    fail "Dockerfile does not use python:3.11-slim base image"
  fi

  # Dependency copy must appear before source copy (cache-friendly order)
  req_line=$(grep -n "COPY.*requirements" "$df" | head -1 | cut -d: -f1 || echo 0)
  src_line=$(grep -n "COPY.*src" "$df" | head -1 | cut -d: -f1 || echo 9999)
  if [[ "$req_line" -gt 0 && "$req_line" -lt "$src_line" ]]; then
    ((l2 += 7)); pass "Dockerfile copies requirements before source (cache-friendly)"
  else
    fail "Dockerfile does not copy requirements before source code"
  fi

  if grep -qE "^CMD" "$df"; then
    ((l2 += 3)); pass "Dockerfile has a CMD instruction"
  else
    fail "Dockerfile missing CMD instruction"
  fi
fi
((score += l2))
pass "Level 2: Dockerfile ($l2/15 pts)"

# ── Level 3 (15 pts): pinned dependencies ───────────────────────────────────
l3=0
if [[ -f "$REPO_ROOT/requirements.txt" ]]; then
  pinned=$(grep -cE "^[a-zA-Z].*==" "$REPO_ROOT/requirements.txt" || true)
  if [[ "$pinned" -ge 1 ]]; then
    ((l3 += 10)); pass "requirements.txt has $pinned pinned package(s)"
  else
    fail "requirements.txt has no pinned packages (use package==version)"
  fi
fi
if [[ -f "$REPO_ROOT/uv.lock" ]]; then
  ((l3 += 5)); pass "uv.lock present (full dependency tree pinned)"
elif [[ "$l3" -ge 10 ]]; then
  ((l3 += 5)); pass "requirements.txt pins satisfied (no uv.lock needed)"
fi
((score += l3))
pass "Level 3: pinned dependencies ($l3/15 pts)"

# ── Level 4 (20 pts): CI workflow ────────────────────────────────────────────
l4=0
ci_file=$(ls "$REPO_ROOT/.github/workflows/"*.yml 2>/dev/null | head -1 || true)
if [[ -n "$ci_file" ]]; then
  grep -q "pull_request" "$ci_file" && { ((l4 += 4)); pass "ci.yml triggers on pull_request"; } || fail "ci.yml missing pull_request trigger"
  grep -q '"main"' "$ci_file" && { ((l4 += 4)); pass "ci.yml triggers on push to main"; } || fail "ci.yml missing push to main trigger"
  grep -q "ruff check" "$ci_file" && { ((l4 += 3)); pass "ci.yml runs ruff check (lint)"; } || fail "ci.yml missing ruff check step"
  grep -q "ruff format" "$ci_file" && { ((l4 += 3)); pass "ci.yml runs ruff format (format check)"; } || fail "ci.yml missing ruff format step"
  grep -q "pytest" "$ci_file" && { ((l4 += 3)); pass "ci.yml runs pytest"; } || fail "ci.yml missing pytest step"
  grep -q "docker build" "$ci_file" && { ((l4 += 3)); pass "ci.yml runs docker build"; } || fail "ci.yml missing docker build step"
fi
((score += l4))
pass "Level 4: CI workflow ($l4/20 pts)"

# ── Level 5 (15 pts): env-var configuration ──────────────────────────────────
l5=0
py="$REPO_ROOT/src/pipeline.py"
if [[ -f "$py" ]]; then
  if grep -qE "os\.(environ|getenv)" "$py"; then
    ((l5 += 10)); pass "pipeline.py reads config from os.environ/os.getenv"
  else
    fail "pipeline.py does not read from os.environ or os.getenv"
  fi
  if ! grep -q "NotImplementedError" "$py"; then
    ((l5 += 5)); pass "pipeline.py has no NotImplementedError stubs remaining"
  else
    fail "pipeline.py still contains NotImplementedError"
  fi
fi
((score += l5))
pass "Level 5: env-var config ($l5/15 pts)"

# ── Level 6 (10 pts): ACR screenshot ────────────────────────────────────────
l6=0
screenshot="$REPO_ROOT/assets/acr_push_week5.png"
if [[ -f "$screenshot" ]]; then
  size=$(wc -c < "$screenshot")
  if [[ "$size" -gt 1024 ]]; then
    ((l6 += 10)); pass "assets/acr_push_week5.png present and non-trivial (${size} bytes)"
  else
    fail "assets/acr_push_week5.png exists but looks empty (${size} bytes)"
  fi
else
  fail "assets/acr_push_week5.png missing (Task 6 deliverable)"
fi
((score += l6))
pass "Level 6: ACR screenshot ($l6/10 pts)"

# ── Level 7 (10 pts): AI_ASSIST.md content ──────────────────────────────────
l7=0
ai="$REPO_ROOT/AI_ASSIST.md"
if [[ -f "$ai" ]]; then
  chars=$(wc -c < "$ai")
  has_prompt=$(grep -c "## The prompt" "$ai" || true)
  has_code=$(grep -c "## The code" "$ai" || true)
  has_changed=$(grep -c "## What I changed" "$ai" || true)
  has_todo=$(grep -c "^TODO:" "$ai" || true)

  if [[ "$has_prompt" -ge 1 && "$has_code" -ge 1 && "$has_changed" -ge 1 ]]; then
    ((l7 += 5)); pass "AI_ASSIST.md has all three required sections"
  else
    fail "AI_ASSIST.md missing one or more required sections"
  fi
  if [[ "$chars" -gt 500 && "$has_todo" -eq 0 ]]; then
    ((l7 += 5)); pass "AI_ASSIST.md is filled in (${chars} chars, no TODO placeholders)"
  else
    fail "AI_ASSIST.md still contains TODO placeholders or is too short (${chars} chars)"
  fi
fi
((score += l7))
pass "Level 7: AI report ($l7/10 pts)"

# ── Final result ─────────────────────────────────────────────────────────────
passing_score=60
pass_flag="false"
[[ "$score" -ge "$passing_score" ]] && pass_flag="true"

echo ""
echo "=== Week 5 Autograder Results ==="
for line in "${details[@]}"; do echo "  $line"; done
echo ""
echo "Score: $score / 100  (passing: $passing_score)"
echo "Pass: $pass_flag"

cat > "$(dirname "$0")/score.json" << JSON
{
  "score": $score,
  "pass": $pass_flag,
  "passingScore": $passing_score
}
JSON
