[Unit]
Description=Acdis Key-Value Store
After=network-online.target
Wants=network-online.target systemd-networkd-wait-online.service

[Service]
ExecStart=/opt/acdis/acdis --own {{ ansible_host }} --manager {{ hostvars['acdis1']['ansible_host'] }}

[Install]
WantedBy=multi-user.target
