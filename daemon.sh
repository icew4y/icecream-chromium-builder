#!/bin/bash
set -ex
mkdir -p /data/iceccd/cache
sudo chown -R icecc:icecc /data/iceccd/cache
cat > /etc/default/icecream << EOF
ICECREAM_NETNAME="ICECREAM"
ICECREAM_SCHEDULER_HOST="192.168.0.66"
ICECREAM_MAX_JOBS=""
ICECREAM_ALLOW_REMOTE="yes"
ICECREAM_DEBUG="yes"
ICECREAM_LOG_FILE=/tmp/iceccd.log
ICECREAM_DEBUG="-v"
ICECREAM_CACHE_DIR="/data/iceccd/cache"
EOF
cat > /usr/lib/systemd/system/iceccd.service << EOF
[Unit]
Description=Icecream Distributed Compiler
After=network.target nss-lookup.target
[Service]
Type=simple
Environment=SHELL=/bin/bash
SyslogIdentifier=iceccd
EnvironmentFile=-/etc/default/icecream
ExecStart=/opt/icecream/sbin/iceccd -u icecc -b \${ICECREAM_CACHE_DIR} -n \${ICECREAM_NETNAME} -s \${ICECREAM_SCHEDULER_HOST} \${ICECREAM_DEBUG}
Nice=5
[Install]
WantedBy=multi-user.target
EOF
systemctl enable iceccd.service
systemctl daemon-reload
systemctl restart iceccd.service
