#!/bin/bash
set -e

if [ "$1" = 'vclods' ]; then
    # Ensure rsyslog is running
    rsyslogd || exit 0

    /bin/bash
else
    exec "$@"
fi

