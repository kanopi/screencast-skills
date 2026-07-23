#!/usr/bin/env bash
# Fixture setup — run by the harness inside the disposable copy.
# Convention: delete yourself first so the seed commit stays clean.
set -euo pipefail
rm -f setup.sh
git init -q -b main
git add -A
git -c user.email=eval@kanopi.com -c user.name="Behavioral Eval" \
  commit -qm "chore: seed fixture"
