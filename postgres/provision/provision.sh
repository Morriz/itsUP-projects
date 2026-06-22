#!/usr/bin/env bash
# Reconcile Postgres roles + databases from PG_PROVISION. Idempotent and safe to
# re-run on every container start: existing roles and databases are preserved,
# only missing ones are created, and passwords are kept in sync.
#
# PG_PROVISION: space-separated user:database:password triples.
#   Passwords must not contain ':' (use hex / base64url).
set -uo pipefail

run() { psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -tAc "$1"; }

for triple in ${PG_PROVISION:-}; do
  IFS=: read -r user db pw <<<"$triple"
  if [ -z "${user:-}" ] || [ -z "${db:-}" ] || [ -z "${pw:-}" ]; then
    echo "provision: skip malformed entry '$triple'"
    continue
  fi

  if [ "$(run "SELECT 1 FROM pg_roles WHERE rolname='$user'")" = "1" ]; then
    run "ALTER ROLE \"$user\" WITH LOGIN PASSWORD '$pw'" >/dev/null
    echo "provision: role '$user' synced"
  else
    run "CREATE ROLE \"$user\" WITH LOGIN PASSWORD '$pw'" >/dev/null
    echo "provision: role '$user' created"
  fi

  if [ "$(run "SELECT 1 FROM pg_database WHERE datname='$db'")" = "1" ]; then
    echo "provision: database '$db' present"
  else
    run "CREATE DATABASE \"$db\" OWNER \"$user\"" >/dev/null
    echo "provision: database '$db' created"
  fi
done

echo "provision: complete"
