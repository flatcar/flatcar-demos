#!/mnt/step

kubelet --version
systemd-sysext status
ls -l /etc/extensions /opt/extensions/kubernetes
journalctl -u systemd-sysupdate --no-pager
sudo systemctl start systemd-sysupdate
journalctl -u systemd-sysupdate --no-pager
ls -l /etc/extensions /opt/extensions/kubernetes
kubelet --version
sudo systemctl reload systemd-sysext
kubelet --version
sudo poweroff
