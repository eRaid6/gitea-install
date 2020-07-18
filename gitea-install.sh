#!/usr/bin/env bash

# Install latest version of gitea on CentOS 7/RHEL 7
# Can also be used to upgrade gitea to latest version if you installed it with this script

# variables
PROG_NAME=$(/bin/basename "$0" | cut -d . -f1)                                  
LOGFACILITY="local7"                                                            
LOGLEVEL="notice"

# Standard logging
logmessage() {                                                                     
    msg="${1}"                                                                     
    logger -p ${LOGFACILITY}.${LOGLEVEL} -t "${PROG_NAME}" "${msg}"                  
    echo "$(date) $(uname -n) ${PROG_NAME}: ${msg}"                                
}

# Debug logging
function debugecho() {                                                             
    [[ $VERBOSE ]] && logmessage "$@"                                              
}                                                                                  

# Help/usage
function usage() {
	echo "usage: ${PROG_NAME} -v"
	exit 1
}

# Command line options
while getopts "hv" o 2>/dev/null; do                                            
    case "${o}" in                                                              
        v)                                                                      
            VERBOSE=1                                                           
            ;;                                                                  
        h)                                                                      
            usage                                                               
            ;;                                                                  
        *)                                                                      
            usage                                                               
            ;;                                                                  
    esac                                                                        
done

# Check current user permissions
# we need root permissions to run this script to set things
# such as file permissions and systemd services etc...
WHOAMI=$(whoami)
# Determine if we are root user or not
if [[ "$WHOAMI" != "root" ]]; then
        logmessage "This script needs to be run as root or with sudo, exiting"
        exit 1
else
        debugecho "current user has correct permissions"
fi

# Create gitea user if it does not exist, which is what gitea will run as
if id gitea >> /dev/null 2>&1; then
  debugecho "gitea user already exists"
else
  debugecho "creating gitea user"
  adduser --system --shell /bin/bash --comment 'Gitea Version Control' --user-group --create-home --home-dir /home/gitea gitea
fi

# Install git, its required for Gitea
if rpm -qa git | grep -q git >> /dev/null 2>&1; then
	debugecho "git already installed"
else
	debugecho "installing git"
	yum install git -y 
fi

# Create custom directory
if [[ -d /var/lib/gitea/custom ]]; then
	debugecho '/var/lib/gitea/custom already exists'
else
	mkdir -p /var/lib/gitea/custom >> /dev/null 2>&1
	chown -R gitea:gitea /var/lib/gitea/custom >> /dev/null 2>&1
	chmod -R 750 /var/lib/gitea/custom >> /dev/null 2>&1
fi

# Create data directory
if [[ -d /var/lib/gitea/data ]]; then
	debugecho '/var/lib/gitea/data already exists'
else
	mkdir -p /var/lib/gitea/data >> /dev/null 2>&1
	chown -R gitea:gitea /var/lib/gitea/data >> /dev/null 2>&1
	chmod -R 750 /var/lib/gitea/data >> /dev/null 2>&1
fi

# Create logging directory
if [[ -d /var/lib/gitea/log ]]; then
	debugecho '/var/lib/gitea/log already exists'
else
	mkdir -p /var/lib/gitea/log >> /dev/null 2>&1
	chown -R gitea:gitea /var/lib/gitea/log >> /dev/null 2>&1
	chmod -R 750 /var/lib/gitea/log >> /dev/null 2>&1
fi

# Create configuration directory
if [[ -d /etc/gitea ]]; then
	debugecho '/etc/gitea already exists'
else
	mkdir -p /etc/gitea >> /dev/null 2>&1
	chown root:gitea /etc/gitea >> /dev/null 2>&1
	chmod 770 /etc/gitea >> /dev/null 2>&1
fi

# Create ssl directory
if [[ -d /etc/gitea/ssl ]]; then
	debugecho '/etc/gitea/ssl already exists'
else
	mkdir -p /etc/gitea/ssl >> /dev/null 2>&1
	chmod 700 /etc/gitea/ssl >> /dev/null 2>&1
	chown gitea:gitea /etc/gitea/ssl >> /dev/null 2>&1
fi

# Download latest version of Gitea and install
# https://docs.gitea.io/en-us/install-from-binary/
GITEA_LATEST_VERSION=$(curl -s https://dl.gitea.io/gitea/ | grep '<a href\=\"\/gitea' | cut -d"/" -f3 | cut -d '"' -f1 | grep '[[:digit:]]' | sort -V | tail -n 1)
cd /tmp >> /dev/null 2>&1
rm gitea gitea.sha256 >> /dev/null 2>&1
# download signature
debugecho 'downloading gitea.sha256 signature'
curl --output gitea.sha256 https://dl.gitea.io/gitea/${GITEA_LATEST_VERSION}/gitea-${GITEA_LATEST_VERSION}-linux-amd64.sha256 >> /dev/null 2>&1
GITEA_LATEST_VERSION_SHA256SUM=$(cut -d' ' -f1 gitea.sha256 | tr -d '\040\011\012\015')
debugecho "GITEA_LATEST_VERSION_SHA256SUM=${GITEA_LATEST_VERSION_SHA256SUM}"
# check to see if we need to update
if [[ -e /usr/local/bin/gitea ]]; then
  GITEA_CURRENT_VERSION_BIN_SHA256SUM=$(sha256sum /usr/local/bin/gitea | cut -d' ' -f1 | tr -d '\040\011\012\015')
  GITEA_INSTALLED=1
  debugecho "GITEA_CURRENT_VERSION_BIN_SHA256SUM=${GITEA_CURRENT_VERSION_BIN_SHA256SUM}"
else
  GITEA_CURRENT_VERSION_BIN_SHA256SUM=$(echo 'notcurrentlyinstalled' | tr -d '\040\011\012\015')
  GITEA_INSTALLED=0
  debugecho "GITEA_CURRENT_VERSION_BIN_SHA256SUM=${GITEA_CURRENT_VERSION_BIN_SHA256SUM}"
fi

if [[ "${GITEA_CURRENT_VERSION_BIN_SHA256SUM}" == "${GITEA_LATEST_VERSION_SHA256SUM}" ]]; then
  debugecho "current binary ${GITEA_CURRENT_VERSION_BIN_SHA256SUM} matches latest binary ${GITEA_LATEST_VERSION_SHA256SUM}, nothing to do since we are on the same version"
  rm gitea.sha256 >> /dev/null 2>&1
else
  debugecho 'downloading gitea binary, this will take a little bit'
  # download binary
  curl --output gitea https://dl.gitea.io/gitea/${GITEA_LATEST_VERSION}/gitea-${GITEA_LATEST_VERSION}-linux-amd64 >> /dev/null 2>&1
  # validate download
  GITEA_LATEST_VERSION_BIN_SHA256SUM=$(sha256sum gitea | cut -d' ' -f1 | tr -d '\040\011\012\015')
  if [[ "${GITEA_LATEST_VERSION_BIN_SHA256SUM}" == "${GITEA_LATEST_VERSION_SHA256SUM}" ]]; then
    if [[ ${GITEA_INSTALLED} -eq 1 ]]; then
      logmessage "about to install new version of gitea, version ${GITEA_LATEST_VERSION}, going to take a backup first"
      su - gitea -c '/usr/local/bin/gitea dump -c /etc/gitea/app.ini'
    fi

    # Stop gitea if running
    if systemctl is-active --quiet gitea; then
      debugecho "stopping gitea"
      systemctl stop gitea
    fi

    logmessage "installing gitea version ${GITEA_LATEST_VERSION}"
    mv gitea /usr/local/bin/gitea >> /dev/null 2>&1
    chmod 777 /usr/local/bin/gitea >> /dev/null 2>&1
    restorecon /usr/local/bin/gitea >> /dev/null 2>&1
    rm gitea.sha256 >> /dev/null 2>&1
  else
    logmessage "gitea download binary sha256sum of ${GITEA_LATEST_VERSION_BIN_SHA256SUM} does not match expected ${GITEA_LATEST_VERSION_SHA256SUM}, not installing"
    rm gitea gitea.sha256 >> /dev/null 2>&1
  fi

fi

cd - >> /dev/null 2>&1

# Install systemd unit file for Gitea
if [[ -e /etc/systemd/system/gitea.service ]]; then
	debugecho 'gitea.service already installed'
else
	debugecho 'installing gitea.service'
	echo '[Unit]
Description=Gitea (Git with a cup of tea)
After=syslog.target
After=network.target

[Service]
RestartSec=15s
Type=simple
User=gitea
Group=gitea
WorkingDirectory=/var/lib/gitea/
ExecStart=/usr/local/bin/gitea web -c /etc/gitea/app.ini
Restart=always
Environment=USER=gitea HOME=/home/gitea GITEA_WORK_DIR=/var/lib/gitea
# We will configure gitea to listen on 443 in the web setup, so let it bind to low ports
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target' > /etc/systemd/system/gitea.service
	chmod 644 /etc/systemd/system/gitea.service
	systemctl daemon-reload >> /dev/null 2>&1
	systemctl enable gitea >> /dev/null 2>&1
fi

# Let users know they need to change permissions after running the first time web configuration
GITEA_ETC_DIR_PERMS=$(stat -c "%a" /etc/gitea)
if echo ${GITEA_ETC_DIR_PERMS} | grep -qE '750'; then
	debugecho '/etc/gitea already exists and permissions are correct, not telling user to change dir permissions'
else
	logmessage 'Install complete, after running the first time web setup run these two commands to lock the config down:
	sudo chmod 750 /etc/gitea
	sudo chmod 640 /etc/gitea/app.ini'
fi

# Start Gitea
systemctl start gitea >> /dev/null 2>&1

# The end
debugecho 'the end'
exit 0
