#!/usr/bin/env bash
set -euo pipefail

SITES_FILE=/opt/erpnext/sites.json

wait-for-it -t 120 erpnext-db:3306
wait-for-it -t 120 erpnext-redis-cache:6379
wait-for-it -t 120 erpnext-redis-queue:6379

start=$(date +%s)
until [[ -n $(grep -hs ^ sites/common_site_config.json | jq -r '.db_host // empty') ]] &&
  [[ -n $(grep -hs ^ sites/common_site_config.json | jq -r '.redis_cache // empty') ]] &&
  [[ -n $(grep -hs ^ sites/common_site_config.json | jq -r '.redis_queue // empty') ]]; do
  echo "Waiting for sites/common_site_config.json to be created"
  sleep 5
  if (($(date +%s) - start > 120)); then
    echo "could not find sites/common_site_config.json with required keys"
    exit 1
  fi
done
echo "sites/common_site_config.json found"

SITE_COUNT=$(jq -r 'length' "$SITES_FILE")
if ((SITE_COUNT < 1)); then
  echo "sites.json must declare at least one site"
  exit 1
fi
jq -e '([.[].name] | length) == ([.[].name] | unique | length)' "$SITES_FILE" >/dev/null

jq -c '.[]' "$SITES_FILE" | while IFS= read -r site; do
  SITE_NAME=$(echo "$site" | jq -r '.name // empty')
  ADMIN_PASSWORD_ENV=$(echo "$site" | jq -r '.admin_password_env // empty')
  if [[ -z $SITE_NAME || -z $ADMIN_PASSWORD_ENV ]]; then
    echo "each sites.json entry requires name and admin_password_env"
    exit 1
  fi
  if [[ ! $ADMIN_PASSWORD_ENV =~ ^[A-Z][A-Z0-9_]*$ ]]; then
    echo "invalid admin password variable name for site '$SITE_NAME'"
    exit 1
  fi
  ADMIN_PASSWORD=$(printenv "$ADMIN_PASSWORD_ENV" || true)
  if [[ -z $ADMIN_PASSWORD ]]; then
    echo "missing admin password variable '$ADMIN_PASSWORD_ENV' for site '$SITE_NAME'"
    exit 1
  fi
  if [ -d "sites/$SITE_NAME" ]; then
    echo "site '$SITE_NAME' already exists - skipping create (idempotent re-apply)"
  else
    bench new-site --mariadb-user-host-login-scope='%' --admin-password="$ADMIN_PASSWORD" \
      --db-root-username=root --db-root-password="$DB_ROOT_PASSWORD" --install-app erpnext "$SITE_NAME"
  fi
  bench --site "$SITE_NAME" set-config host_name "https://$SITE_NAME"
done
