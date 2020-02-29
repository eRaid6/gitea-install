# gitea-install
Bash script written to automate installing Gitea binary on CentOS 7/8, RHEL 7/8, Fedora 30/31.  `gitea-install.sh` will install gitea go binary in /usr/local/bin/, create a systemd unit file for gitea, create the gitea user.

`gitea-install.sh` is safe to run multiple times, in fact that's how you can use it to upgrade your current installation.  When `gitea-install.sh` updates a installation it takes a backup first to /tmp.

## Installing
Checkout gitea-install to any place you want
```
cd /tmp
git clone <thisrepo>
```
Run the installer
```
/tmp/gitea-install/gitea-install.sh
```
gitea will be running on port 3000 by default.  When going through the web install you can switch it to 443 if you would like and put ssl certs in /etc/gitea/ssl

### Starting/Stopping and Enabling gitea
#### Start
```
sudo systemctl start gitea
```
#### If you want gitea to automatically start on server boot
```
sudo systemctl enable gitea
```

## Uninstalling
`gitea-uninstall.sh` will undo/remove everything `gitea-install.sh` does.
