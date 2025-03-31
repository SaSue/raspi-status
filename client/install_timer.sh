cp etc/systemd/system/* /etc/systemd/system/
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable --now raspi-client-upload.timer
