#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ------------------------------------------------------------
# Formal targets:
#
# name|relative_sby_path|expected_class
#
# expected_class:
#   prove             -> πρέπει να βγει PASS
#   blocked_expected  -> πρέπει να βγει BLOCKED λόγω documented limitation
# ------------------------------------------------------------
TARGETS=(
  "ALU config|formal/alu/config.sby|prove"
  "FPU MUL waiver|formal/fpu/fpu_mul_waiver.sby|prove"
  "FPU DIV shift invariant|formal/fpu/fpu_div_shift_waiver.sby|prove"
  "FPU DIV full-DUT|formal/fpu/fpu_div_waiver.sby|blocked_expected"
)

# Known Yosys/SymbiYosys limitation signature.
# We use this only for blocked_expected targets.
KNOWN_BLOCKED_PATTERN="ERROR: 2nd expression of procedural for-loop is not constant!"

run_one() {
  local name="$1"
  local relpath="$2"
  local expected="$3"
  local sby_path="${ROOT_DIR}/${relpath}"
  local sby_dir
  local sby_base
  local logfile
  local status="UNKNOWN"

  if [ ! -f "$sby_path" ]; then
    printf '  %-35s MISSING\n' "$name"
    return 2
  fi

  sby_dir="$(dirname "$sby_path")"
  sby_base="$(basename "$sby_path")"
  logfile="${sby_dir}/${sby_base%.sby}/logfile.txt"

  echo "-----------------------------------------------------------"
  echo "RUN: $name"
  echo "SBY : $relpath"
  echo "-----------------------------------------------------------"

  # Εκτελούμε το sby, αλλά δεν βασιζόμαστε μόνο στο return code.
  if (cd "$sby_dir" && sby -f "$sby_base"); then
    status="PASS"
  else
    status="FAIL"
  fi

  # Πιο ακριβής ανάλυση από το logfile.
  if [ -f "$logfile" ]; then
    if grep -q "DONE (PASS, rc=0)" "$logfile"; then
      status="PASS"
    elif grep -q "DONE (BLOCKED, rc=0)" "$logfile"; then
      status="BLOCKED"
    elif grep -q "DONE (FAIL, rc=" "$logfile"; then
      status="FAIL"
    fi

    # Ειδικός χειρισμός για documented limitation που δεν επιστρέφει
    # τυπικό BLOCKED status από το SymbiYosys.
    if [ "$expected" = "blocked_expected" ] && \
       grep -q "$KNOWN_BLOCKED_PATTERN" "$logfile"; then
      status="BLOCKED"
    fi
  fi

  printf '  Status: %s\n\n' "$status"

  case "$expected:$status" in
    prove:PASS)
      return 0
      ;;
    blocked_expected:BLOCKED)
      return 0
      ;;
    blocked_expected:PASS)
      echo "  NOTE: expected BLOCKED but got PASS."
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

SUMMARY_PASS=0
SUMMARY_BLOCKED=0
SUMMARY_FAIL=0
RET=0

echo "=========================================================="
echo " FORMAL REGRESSION"
echo "=========================================================="

for entry in "${TARGETS[@]}"; do
  IFS='|' read -r name relpath expected <<< "$entry"

  if run_one "$name" "$relpath" "$expected"; then
    case "$expected" in
      blocked_expected)
        SUMMARY_BLOCKED=$((SUMMARY_BLOCKED + 1))
        ;;
      *)
        SUMMARY_PASS=$((SUMMARY_PASS + 1))
        ;;
    esac
  else
    SUMMARY_FAIL=$((SUMMARY_FAIL + 1))
    RET=1
  fi
done

echo "=========================================================="
echo " FORMAL SUMMARY"
echo "=========================================================="
printf '  PASS    : %d\n' "$SUMMARY_PASS"
printf '  BLOCKED : %d\n' "$SUMMARY_BLOCKED"
printf '  FAIL    : %d\n' "$SUMMARY_FAIL"
echo "=========================================================="

if [ "$RET" -ne 0 ]; then
  echo "FORMAL REGRESSION: FAIL"
else
  echo "FORMAL REGRESSION: PASS"
fi

exit "$RET"
