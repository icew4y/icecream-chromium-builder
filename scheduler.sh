#!/bin/bash
set -ex
cat > /etc/default/icecc-scheduler << EOF
ICECREAM_NETNAME="ICECREAM"
ICECREAM_SCHEDULER_HOST="192.168.0.66"
ICECREAM_MAX_JOBS=""
ICECREAM_ALLOW_REMOTE="yes"
# ICECREAM_SCHEDULER_DEBUG="-vvv"
ICECREAM_SCHEDULER_DEBUG="-v"
EOF
cat > /usr/lib/systemd/system/icecc-scheduler.service << EOF
[Unit]
Description=Icecream distributed compiler scheduler
[Service]
Type=simple
User=icecc
Group=icecc
SyslogIdentifier=icecc-scheduler
EnvironmentFile=-/etc/default/icecc-scheduler
ExecStart=/opt/icecream/sbin/icecc-scheduler -n \${ICECREAM_NETNAME} --persistent-client-connection \${ICECREAM_SCHEDULER_DEBUG}
[Install]
WantedBy=multi-user.target
EOF
systemctl enable icecc-scheduler.service
systemctl daemon-reload
systemctl restart icecc-scheduler.service
