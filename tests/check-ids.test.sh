#!/usr/bin/env bash
# skills/assumption-ledger/check-ids.sh against fixture .hordev directories.
set -uo pipefail
. "$(dirname "$0")/lib.sh"

C="$REPO/skills/assumption-ledger/check-ids.sh"

ledger_entry() {  # ledger_entry <ID> <title>
  printf '## %s: %s\n\nDecided: x\n\nRationale: x\n\nRejected: x\n\nBlast radius: Small\n\nFalsified by: x\n\nStatus: open\n\n---\n\n' "$1" "$2"
}

# The shape the product run actually had: the spec cites only written IDs, and
# the phantom lives in a dispatch prompt.
T=$(scratch)
H="$T/.hordev"
mkdir -p "$H/specs" "$H/dispatch"
{ ledger_entry A-017 "sign-in gates messaging"; ledger_entry A-019 "messaging ships"; } > "$H/assumptions.md"
printf '# Spec\n\nSee A-017 and A-019.\n' > "$H/specs/coach.md"
printf 'TASK: build portal\n\nOPEN ASSUMPTIONS (do not contradict):\n- A-020: No payments and no commission in v1.\n' > "$H/dispatch/build-portal.md"

# A spec-only check would have called this ledger clean.
mv "$H/dispatch" "$T/dispatch.aside"
out=$(bash "$C" "$H"); status=$?
assert_status "specs alone look clean (the gap saved prompts close)" "$status" 0
mv "$T/dispatch.aside" "$H/dispatch"

out=$(bash "$C" "$H"); status=$?
assert_status "a saved dispatch prompt citing an unwritten ID fails" "$status" 1
assert_contains "and names the file, line and ID" "$out" "dispatch/build-portal.md:4: A-020 is cited but has no entry"

ledger_entry A-020 "no payments in v1" >> "$H/assumptions.md"
out=$(bash "$C" "$H"); status=$?
assert_status "the same prompt passes once the entry is written" "$status" 0

# A run's first phantom has a prefix the ledger has never seen.
printf 'Per PK-001, passkeys only.\n' > "$H/specs/passkeys.md"
out=$(bash "$C" "$H"); status=$?
assert_status "a phantom with an unseen prefix still fails" "$status" 1
assert_contains "and is named" "$out" "PK-001"
rm "$H/specs/passkeys.md"

# Things that look like IDs and are not.
printf 'Hash with SHA-256, dates as ISO-8601, see RFC-822 and CVE-2024-1234.\nModel claude-opus-5 and X-123 header. Not a match: A-01, AB-12x, lower-001.\n' > "$H/specs/noise.md"
out=$(bash "$C" "$H"); status=$?
assert_status "hashes, standards and short numbers are not citations" "$status" 0

printf 'The ZZ-900 widget.\n' >> "$H/specs/noise.md"
out=$(HORDEV_ID_IGNORE="ZZ" bash "$C" "$H"); status=$?
assert_status "HORDEV_ID_IGNORE extends the ignore list" "$status" 0

# The run log and proposals may name IDs freely; they are not decisions.
printf 'EVENT: A-099 was cited and never written.\n' > "$H/run-log.md"
out=$(HORDEV_ID_IGNORE="ZZ" bash "$C" "$H"); status=$?
assert_status "run-log.md is not scanned for citations" "$status" 0

out=$(bash "$C" "$T/nope" 2>&1); status=$?
assert_status "a missing directory is a usage error" "$status" 2

rm -rf "$T"
finish
