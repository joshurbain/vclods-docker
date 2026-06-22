#!/bin/bash
set -e

if [ "$1" = 'vclods' ]; then
    # Write /etc/vclods from environment variables so settings can be
    # injected at runtime with: docker run -e VCLOD_HOST=... -e VCLOD_PASSWORD=...
    cat > /etc/vclods <<EOF
VCLOD_USE_CGROUP=0
VCLOD_LOCK_DIR=/dev/shm/
VCLOD_ERR_DIR=/dev/shm/
LOG_BASE_DIR=/tmp/
VCLOD_ENGINE=${VCLOD_ENGINE}
VCLOD_HOST=${VCLOD_HOST}
VCLOD_USER=${VCLOD_USER}
VCLOD_PASSWORD=${VCLOD_PASSWORD}
VCLOD_DB=${VCLOD_DB}
OPERATIONS_EMAIL=${OPERATIONS_EMAIL}
EOF

    touch /etc/rsyslog.conf
    rsyslogd || true

    /bin/bash
else
    exec "$@"
fi
