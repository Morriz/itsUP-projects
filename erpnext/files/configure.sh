#!/usr/bin/env bash
set -euo pipefail

[ -f sites/common_site_config.json ] || echo '{}' >sites/common_site_config.json
ls -1 apps >sites/apps.txt
bench set-config -g db_host "$DB_HOST"
bench set-config -gp db_port "$DB_PORT"
bench set-config -g redis_cache "redis://$REDIS_CACHE"
bench set-config -g redis_queue "redis://$REDIS_QUEUE"
bench set-config -g redis_socketio "redis://$REDIS_QUEUE"
bench set-config -gp socketio_port "$SOCKETIO_PORT"

if [ -n "${SMTP_HOST:-}" ]; then
  bench set-config -g mail_server "$SMTP_HOST"
  bench set-config -gp mail_port "${SMTP_PORT:-587}"
  bench set-config -g mail_login "${SMTP_USER:-}"
  bench set-config -g mail_password "${SMTP_PASSWORD:-}"
  bench set-config -g auto_email_id "${SMTP_FROM:-}"
  bench set-config -g email_sender_name "${SMTP_SENDER_NAME:-}"
  if [ "${SMTP_PORT:-587}" = "465" ]; then
    bench set-config -gp use_ssl 1
  else
    bench set-config -gp use_tls 1
  fi
  bench set-config -gp always_use_account_email_id_as_sender 1
fi
