#!/usr/bin/env bash
set -euo pipefail
OWNER=${TICKET_GITHUB_OWNER:-taymaz1987}
REPO=${TICKET_GITHUB_REPO:-Ticket}
REF=${TICKET_GITHUB_REF:-v1.4.0}
MODE=install
PASS_ARGS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --owner) OWNER=$2; PASS_ARGS+=(--owner "$2"); shift 2;;
    --repo) REPO=$2; PASS_ARGS+=(--repo "$2"); shift 2;;
    --ref) REF=$2; PASS_ARGS+=(--ref "$2"); shift 2;;
    --plan) MODE=plan; PASS_ARGS+=(--plan); shift;;
    --self-test) MODE=self-test; PASS_ARGS+=(--self-test); shift;;
    *) printf 'ERROR: unknown argument: %s\n' "$1" >&2; exit 2;;
  esac
done
if [ "$MODE" = install ] && [ "$(id -u)" -ne 0 ]; then
  printf 'ERROR: run launcher with sudo/root for installation.\n' >&2; exit 2
fi
TTY=/dev/tty
[ -r "$TTY" ] && [ -w "$TTY" ] || { printf 'ERROR: interactive TTY is required.\n' >&2; exit 2; }
command -v curl >/dev/null 2>&1 || { printf 'ERROR: curl is required.\n' >&2; exit 1; }

printf '\nTicket online launcher\n'
printf 'Private repository: %s/%s\nRef:                %s\n\n' "$OWNER" "$REPO" "$REF"
printf 'GitHub token (Contents: read; not stored): ' >"$TTY"
IFS= read -r -s TOKEN <"$TTY"
printf '\n' >"$TTY"
[ -n "$TOKEN" ] || { printf 'ERROR: token is empty.\n' >&2; exit 1; }
[[ "$TOKEN" != *$'\n'* && "$TOKEN" != *$'\r'* ]] || { printf 'ERROR: invalid token characters.\n' >&2; exit 1; }

TMP=$(mktemp /tmp/ticket-public-launcher.XXXXXX)
cleanup(){ rm -f "$TMP"; TOKEN=''; }
trap cleanup EXIT
URL="https://api.github.com/repos/${OWNER}/${REPO}/contents/bootstrap/install-from-github-api.sh?ref=${REF}"

# Authorization is supplied over curl config stdin, never in process argv.
printf 'header = "Authorization: Bearer %s"\nheader = "Accept: application/vnd.github.raw+json"\nurl = "%s"\n' "$TOKEN" "$URL" \
  | curl --fail --silent --show-error --location --config - --output "$TMP" \
  || { printf 'ERROR: cannot download private bootstrap.\n' >&2; exit 1; }

head -1 "$TMP" | grep -q '^#!/usr/bin/env bash' || { printf 'ERROR: downloaded bootstrap is not a Bash script.\n' >&2; exit 1; }
bash -n "$TMP" || { printf 'ERROR: downloaded bootstrap failed syntax validation.\n' >&2; exit 1; }
chmod 700 "$TMP"

# Pass the token through FD 3 so it is not in argv, env or a credential file.
bash "$TMP" "${PASS_ARGS[@]}" --token-fd 3 3<<<"$TOKEN"
