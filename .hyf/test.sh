#!/usr/bin/env bash
# Week 5 autograder: static analysis only (no Docker or Azure required in CI).
# Each level adds points toward 100; passing score is 60.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=.hyf/grader_lib.sh
source "$SCRIPT_DIR/grader_lib.sh"

score=0
# grader_lib aliases for the level-based scoring pattern used in this file
details() { printf '%s\n' "${_grader_details[@]}"; }
pass() { _grader_details+=("PASS: $1"); }
fail() { _grader_details+=("FAIL: $1"); }
warn() { _grader_details+=("WARN: $1"); }

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


# ── Level 2 (15 pts): Dockerfile correctness ────────────────────────────────
l2=0
df="$REPO_ROOT/Dockerfile"
if [[ -f "$df" ]]; then
  if grep -qE "^FROM\s+python:3\.11-slim" "$df"; then
    ((l2 += 5)); pass "Dockerfile uses python:3.11-slim base image"
  else
    fail "Dockerfile does not use python:3.11-slim base image"
  fi

  # Dependency copy must appear before source copy (cache-friendly order)
  req_line=$(grep -n "COPY.*requirements" "$df" | head -1 | cut -d: -f1 || echo 0)
  src_line=$(grep -n "COPY.*src" "$df" | head -1 | cut -d: -f1 || echo 9999)
  if [[ "$req_line" -gt 0 && "$src_line" -lt 9999 && "$req_line" -lt "$src_line" ]]; then
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

# ── Level 3 (10 pts): unit tests ─────────────────────────────────────────────
l3=0
test_file="$REPO_ROOT/tests/test_pipeline.py"
if [[ -f "$test_file" ]]; then
  test_count=$(grep -cE "^[[:space:]]*def test_" "$test_file" || true)
  if [[ "$test_count" -ge 2 ]]; then
    ((l3 += 7)); pass "tests/test_pipeline.py has $test_count test functions (≥2 required)"
  else
    fail "tests/test_pipeline.py has only $test_count test function(s) — at least 2 required"
  fi
  if ! grep -q "NotImplementedError" "$test_file"; then
    ((l3 += 3)); pass "tests/test_pipeline.py has no NotImplementedError stubs remaining"
  else
    fail "tests/test_pipeline.py still contains NotImplementedError stubs"
  fi
fi
((score += l3))
pass "Level 3: unit tests ($l3/10 pts)"

# ── Level 4 (10 pts): pinned dependencies ───────────────────────────────────
l4=0
if [[ -f "$REPO_ROOT/requirements.txt" ]]; then
  pinned=$(grep -cE "^[a-zA-Z].*==" "$REPO_ROOT/requirements.txt" || true)
  if [[ "$pinned" -ge 1 ]]; then
    ((l4 += 7)); pass "requirements.txt has $pinned pinned package(s)"
  else
    fail "requirements.txt has no pinned packages (use package==version)"
  fi
fi
if [[ -f "$REPO_ROOT/uv.lock" ]]; then
  ((l4 += 3)); pass "uv.lock present (full dependency tree pinned)"
elif [[ "$l4" -ge 7 ]]; then
  ((l4 += 3)); pass "requirements.txt pins satisfied (no uv.lock needed)"
fi
((score += l4))
pass "Level 4: pinned dependencies ($l4/10 pts)"

# ── Level 5 (20 pts): CI workflow ────────────────────────────────────────────
l5=0
ci_file=$(ls "$REPO_ROOT/.github/workflows/"*.yml 2>/dev/null | head -1 || true)
if [[ -n "$ci_file" ]]; then
  grep -q "pull_request" "$ci_file" && { ((l5 += 4)); pass "ci.yml triggers on pull_request"; } || fail "ci.yml missing pull_request trigger"
  grep -qE '\bmain\b' "$ci_file" && { ((l5 += 4)); pass "ci.yml triggers on push to main"; } || fail "ci.yml missing push to main trigger"
  grep -q "ruff check" "$ci_file" && { ((l5 += 3)); pass "ci.yml runs ruff check (lint)"; } || fail "ci.yml missing ruff check step"
  grep -q "ruff format" "$ci_file" && { ((l5 += 3)); pass "ci.yml runs ruff format (format check)"; } || fail "ci.yml missing ruff format step"
  grep -q "pytest" "$ci_file" && { ((l5 += 3)); pass "ci.yml runs pytest"; } || fail "ci.yml missing pytest step"
  grep -q "docker build" "$ci_file" && { ((l5 += 3)); pass "ci.yml runs docker build"; } || fail "ci.yml missing docker build step"
fi
((score += l5))
pass "Level 5: CI workflow ($l5/20 pts)"

# ── Level 6 (15 pts): env-var configuration ──────────────────────────────────
l6=0
py="$REPO_ROOT/src/pipeline.py"
if [[ -f "$py" ]]; then
  if grep -qE "os\.(environ|getenv)|from os import (environ|getenv)" "$py"; then
    ((l6 += 10)); pass "pipeline.py reads config from os.environ/os.getenv"
  else
    fail "pipeline.py does not read from os.environ or os.getenv"
  fi
  if ! grep -q "NotImplementedError" "$py"; then
    ((l6 += 5)); pass "pipeline.py has no NotImplementedError stubs remaining"
  else
    fail "pipeline.py still contains NotImplementedError"
  fi
fi
((score += l6))
pass "Level 6: env-var config ($l6/15 pts)"

# ── Level 7 (10 pts): ACR screenshot ────────────────────────────────────────
l7=0
screenshot="$REPO_ROOT/assets/acr_push_week5.png"
if [[ -f "$screenshot" ]]; then
  size=$(wc -c < "$screenshot")
  if [[ "$size" -gt 1024 ]]; then
    ((l7 += 10)); pass "assets/acr_push_week5.png present and non-trivial (${size} bytes)"
  else
    fail "assets/acr_push_week5.png exists but looks empty (${size} bytes)"
  fi
else
  fail "assets/acr_push_week5.png missing (Task 6 deliverable)"
fi
((score += l7))
pass "Level 7: ACR screenshot ($l7/10 pts)"

# ── Level 8 (5 pts): AI_ASSIST.md content ───────────────────────────────────
l8=0
ai="$REPO_ROOT/AI_ASSIST.md"
if [[ -f "$ai" ]]; then
  chars=$(wc -c < "$ai")
  has_prompt=$(grep -c "## The prompt" "$ai" || true)
  has_code=$(grep -c "## The code" "$ai" || true)
  has_changed=$(grep -c "## What I changed" "$ai" || true)
  has_todo=$(grep -c "^TODO:" "$ai" || true)

  if [[ "$has_prompt" -ge 1 && "$has_code" -ge 1 && "$has_changed" -ge 1 ]]; then
    ((l8 += 3)); pass "AI_ASSIST.md has all three required sections"
  else
    fail "AI_ASSIST.md missing one or more required sections"
  fi
  if [[ "$chars" -gt 500 && "$has_todo" -eq 0 ]]; then
    ((l8 += 2)); pass "AI_ASSIST.md is filled in (${chars} chars, no TODO placeholders)"
  else
    fail "AI_ASSIST.md still contains TODO placeholders or is too short (${chars} chars)"
  fi
fi
((score += l8))
pass "Level 8: AI report ($l8/5 pts)"

# ── Code hygiene (warnings from grader_lib) ──────────────────────────────────
check_no_print_statements "$REPO_ROOT/src" "src/"
check_gitignore_python "$REPO_ROOT/.gitignore"

# ── Final result ─────────────────────────────────────────────────────────────
passing_score=60
print_results "Week 5 Autograder"
write_score "$score" "$passing_score" "$SCRIPT_DIR/score.json"
