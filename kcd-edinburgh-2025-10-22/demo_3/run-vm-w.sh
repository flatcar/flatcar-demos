#!/mnt/step

ls -l /opt/extensions/kubernetes /etc/extensions /run/reboot-required
journalctl -u systemd-sysupdate --no-pager
sudo reboot
