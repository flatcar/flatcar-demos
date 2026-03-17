#!/mnt/step

ls -l /etc/extensions /opt/extensions/kubernetes
systemd-sysext list --no-pager
sudo ln -sfv /opt/extensions/kubernetes/kubernetes-v1.33.0-x86-64.raw /etc/extensions/kubernetes.raw
systemd-sysext list --no-pager
systemd-sysext status
ls /usr/bin/ku*
systemctl status kubelet --no-pager
sudo systemd-sysext refresh
ls /usr/bin/ku*
systemctl status kubelet --no-pager
kubelet --version
sudo poweroff
